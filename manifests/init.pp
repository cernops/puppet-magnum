#   Copyright (C) 2015 CERN.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# Author: Ricardo Rocha <ricardo.rocha@cern.ch>
#
# == Class: magnum
#
# init takes care of installing/configuring the common dependencies across classes
# it also takes care of the global configuration values
#
# === Parameters:
#
class magnum (
  $database_connection         = 'sqlite:////var/lib/magnum/magnum.sqlite',
  $database_idle_timeout       = '3600',
  $database_min_pool_size      = '1',
  $database_max_pool_size      = undef,
  $database_max_retries        = '10',
  $database_retry_interval     = '10',
  $database_max_overflow       = undef,
  $control_exchange            = 'openstack',
  $rpc_backend                 = 'rabbit',
  $rabbit_host                 = '127.0.0.1',
  $rabbit_port                 = 5672,
  $rabbit_hosts                = false,
  $rabbit_virtual_host         = '/',
  $rabbit_userid               = 'guest',
  $rabbit_password             = false,
  $rabbit_use_ssl              = false,
  $kombu_ssl_ca_certs          = undef,
  $kombu_ssl_certfile          = undef,
  $kombu_ssl_keyfile           = undef,
  $kombu_ssl_version           = 'TLSv1',
  $amqp_durable_queues         = false,
  $qpid_hostname               = 'localhost',
  $qpid_port                   = '5672',
  $qpid_username               = 'guest',
  $qpid_password               = false,
  $qpid_sasl_mechanisms        = false,
  $qpid_reconnect              = true,
  $qpid_reconnect_timeout      = 0,
  $qpid_reconnect_limit        = 0,
  $qpid_reconnect_interval_min = 0,
  $qpid_reconnect_interval_max = 0,
  $qpid_reconnect_interval     = 0,
  $qpid_heartbeat              = 60,
  $qpid_protocol               = 'tcp',
  $qpid_tcp_nodelay            = true,
  $package_ensure              = 'present',
  $use_ssl                     = false,
  $ca_file                     = false,
  $cert_file                   = false,
  $key_file                    = false,
  $use_syslog                  = false,
  $log_facility                = 'LOG_USER',
  $log_dir                     = '/var/log/magnum',
  $verbose                     = false,
  $debug                       = false,
) {

  include ::magnum::params

  if $ensure !~ /(absent|purged)/ {
    # Make sure magnum is installed before managing the configuration
    Package<| tag == 'magnum' |> -> Magnum_Config<| |>
  }

  if $use_ssl {
    if !$cert_file {
      fail('The cert_file parameter is required when use_ssl is set to true')
    }
    if !$key_file {
      fail('The key_file parameter is required when use_ssl is set to true')
    }
  }

  package { 'magnum':
    ensure  => $package_ensure,
    name    => $::magnum::params::package_name,
    tag     => 'magnum',
  }

  if $rpc_backend == 'rabbit' {

    if ! $rabbit_password {
      fail('Please specify a rabbit_password parameter.')
    }

    magnum_config {
      'oslo_messaging_rabbit/rabbit_password':     value => $rabbit_password;
      'oslo_messaging_rabbit/rabbit_userid':       value => $rabbit_userid;
      'oslo_messaging_rabbit/rabbit_virtual_host': value => $rabbit_virtual_host;
      'oslo_messaging_rabbit/rabbit_use_ssl':      value => $rabbit_use_ssl;
      'oslo_messaging_rabbit/control_exchange':    value => $control_exchange;
      'oslo_messaging_rabbit/amqp_durable_queues': value => $amqp_durable_queues;
    }

    if $rabbit_hosts {
      magnum_config { 'oslo_messaging_rabbit/rabbit_hosts':     value => join($rabbit_hosts, ',') }
      magnum_config { 'oslo_messaging_rabbit/rabbit_ha_queues': value => true }
      magnum_config { 'oslo_messaging_rabbit/rabbit_host':      ensure => absent }
      magnum_config { 'oslo_messaging_rabbit/rabbit_port':      ensure => absent }
    } else {
      magnum_config { 'oslo_messaging_rabbit/rabbit_host':      value => $rabbit_host }
      magnum_config { 'oslo_messaging_rabbit/rabbit_port':      value => $rabbit_port }
      magnum_config { 'oslo_messaging_rabbit/rabbit_hosts':     value => "${rabbit_host}:${rabbit_port}" }
      magnum_config { 'oslo_messaging_rabbit/rabbit_ha_queues': value => false }
    }

    if $rabbit_use_ssl {
      magnum_config { 'oslo_messaging_rabbit/kombu_ssl_version': value => $kombu_ssl_version }

      if $kombu_ssl_ca_certs {
        magnum_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs': value => $kombu_ssl_ca_certs }
      } else {
        magnum_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs': ensure => absent}
      }

      if $kombu_ssl_certfile {
        magnum_config { 'oslo_messaging_rabbit/kombu_ssl_certfile': value => $kombu_ssl_certfile }
      } else {
        magnum_config { 'oslo_messaging_rabbit/kombu_ssl_certfile': ensure => absent}
      }

      if $kombu_ssl_keyfile {
        magnum_config { 'oslo_messaging_rabbit/kombu_ssl_keyfile': value => $kombu_ssl_keyfile }
      } else {
        magnum_config { 'oslo_messaging_rabbit/kombu_ssl_keyfile': ensure => absent}
      }
    } else {
      magnum_config {
        'oslo_messaging_rabbit/kombu_ssl_ca_certs': ensure => absent;
        'oslo_messaging_rabbit/kombu_ssl_certfile': ensure => absent;
        'oslo_messaging_rabbit/kombu_ssl_keyfile':  ensure => absent;
        'oslo_messaging_rabbit/kombu_ssl_version':  ensure => absent;
      }
    }

  }

  if $rpc_backend == 'qpid' {

    if ! $qpid_password {
      fail('Please specify a qpid_password parameter.')
    }

    magnum_config {
      'oslo_messaging_qpid/qpid_hostname':               value => $qpid_hostname;
      'oslo_messaging_qpid/qpid_port':                   value => $qpid_port;
      'oslo_messaging_qpid/qpid_username':               value => $qpid_username;
      'oslo_messaging_qpid/qpid_password':               value => $qpid_password;
      'oslo_messaging_qpid/qpid_reconnect':              value => $qpid_reconnect;
      'oslo_messaging_qpid/qpid_reconnect_timeout':      value => $qpid_reconnect_timeout;
      'oslo_messaging_qpid/qpid_reconnect_limit':        value => $qpid_reconnect_limit;
      'oslo_messaging_qpid/qpid_reconnect_interval_min': value => $qpid_reconnect_interval_min;
      'oslo_messaging_qpid/qpid_reconnect_interval_max': value => $qpid_reconnect_interval_max;
      'oslo_messaging_qpid/qpid_reconnect_interval':     value => $qpid_reconnect_interval;
      'oslo_messaging_qpid/qpid_heartbeat':              value => $qpid_heartbeat;
      'oslo_messaging_qpid/qpid_protocol':               value => $qpid_protocol;
      'oslo_messaging_qpid/qpid_tcp_nodelay':            value => $qpid_tcp_nodelay;
      'oslo_messaging_qpid/amqp_durable_queues':         value => $amqp_durable_queues;
    }

    if is_array($qpid_sasl_mechanisms) {
      magnum_config {
        'oslo_messaging_qpid/qpid_sasl_mechanisms': value => join($qpid_sasl_mechanisms, ' ');
      }
    } elsif $qpid_sasl_mechanisms {
      magnum_config {
        'oslo_messaging_qpid/qpid_sasl_mechanisms': value => $qpid_sasl_mechanisms;
      }
    } else {
      magnum_config {
        'oslo_messaging_qpid/qpid_sasl_mechanisms': ensure => absent;
      }
    }
  }

  magnum_config {
    'database/connection':               value => $database_connection;
    'database/idle_timeout':             value => $database_idle_timeout;
    'database/min_pool_size':            value => $database_min_pool_size;
    'database/max_retries':              value => $database_max_retries;
    'database/retry_interval':           value => $database_retry_interval;
    'DEFAULT/verbose':                   value => $verbose;
    'DEFAULT/debug':                     value => $debug;
    'DEFAULT/api_paste_config':          value => $api_paste_config;
    'DEFAULT/rpc_backend':               value => $rpc_backend;
  }

  if $database_max_pool_size {
    magnum_config {
      'database/max_pool_size': value => $database_max_pool_size;
    }
  } else {
    magnum_config {
      'database/max_pool_size': ensure => absent;
    }
  }

  if $database_max_overflow {
    magnum_config {
      'database/max_overflow': value => $database_max_overflow;
    }
  } else {
    magnum_config {
      'database/max_overflow': ensure => absent;
    }
  }

  if $log_dir {
    magnum_config {
      'DEFAULT/log_dir': value => $log_dir;
    }
  } else {
    magnum_config {
      'DEFAULT/log_dir': ensure => absent;
    }
  }

  # SSL Options
  if $use_ssl {
    magnum_config {
      'DEFAULT/ssl_cert_file' : value => $cert_file;
      'DEFAULT/ssl_key_file' :  value => $key_file;
    }
    if $ca_file {
      magnum_config { 'DEFAULT/ssl_ca_file' :
        value => $ca_file,
      }
    } else {
      magnum_config { 'DEFAULT/ssl_ca_file' :
        ensure => absent,
      }
    }
  } else {
    magnum_config {
      'DEFAULT/ssl_cert_file' : ensure => absent;
      'DEFAULT/ssl_key_file' :  ensure => absent;
      'DEFAULT/ssl_ca_file' :   ensure => absent;
    }
  }

  if $use_syslog {
    magnum_config {
      'DEFAULT/use_syslog':           value => true;
      'DEFAULT/syslog_log_facility':  value => $log_facility;
    }
  } else {
    magnum_config {
      'DEFAULT/use_syslog':           value => false;
    }
  }

}
