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
# == Class: magnum::api
#
# Setup and configure the Magnum API endpoint.
#
# === Parameters
#
# [*keystone_password*]
#   The password to use for authentication (keystone)
#
# [*keystone_enabled*]
#   (optional) Use keystone for authentification
#   Defaults to true
#
# [*keystone_tenant*]
#   (optional) The tenant of the auth user
#   Defaults to services
#
# [*keystone_user*]
#   (optional) The name of the auth user
#   Defaults to magnum
#
# [*auth_uri*]
#   (optional) Public Identity API endpoint.
#   Defaults to 'false'.
#
# [*identity_uri*]
#   (optional) Complete admin Identity API endpoint.
#   Defaults to: false
#
# [*service_workers*]
#   (optional) Number of magnum-api workers
#   Defaults to $::processorcount
#
# [*package_ensure*]
#   (optional) The state of the package
#   Defaults to present
#
# [*bind_host*]
#   (optional) The magnum api bind address
#   Defaults to 0.0.0.0
#
# [*enabled*]
#   (optional) The state of the service
#   Defaults to true
#
# [*manage_service*]
#   (optional) Whether to start/stop the service
#   Defaults to true
#
# [*sync_db*]
#   (Optional) Run db sync on the node.
#   Defaults to true
#
class magnum::api (
  $keystone_password,
  $keystone_enabled           = true,
  $keystone_tenant            = 'services',
  $keystone_user              = 'magnum',
  $auth_uri                   = false,
  $identity_uri               = false,
  $service_workers            = $::processorcount,
  $package_ensure             = 'present',
  $bind_host                  = '0.0.0.0',
  $enabled                    = true,
  $manage_service             = true,
  $sync_db                    = true,
) {

  include ::magnum::params

  if $::magnum::params::api_package {
    package { 'magnum-api':
      ensure => $package_ensure,
      name   => $::magnum::params::api_package,
      tag    => 'magnum',
    }
  }
  Magnum_config<||> ~> Service['magnum-api']

  if $sync_db {
    Magnum_config<||> ~> Exec['magnum-manage db_sync']

    exec { 'magnum-manage db_sync':
      command     => $::magnum::params::db_sync_command,
      path        => '/usr/bin',
      user        => 'magnum',
      refreshonly => true,
      logoutput   => 'on_failure',
      subscribe   => Package['magnum-api'],
      before      => Service['magnum-api'],
    }
  }

  if $enabled {
    if $manage_service {
      $ensure = 'running'
    }
  } else {
    if $manage_service {
      $ensure = 'stopped'
    }
  }

  service { 'magnum-api':
    ensure    => $ensure,
    name      => $::magnum::params::api_service,
    enable    => $enabled,
    hasstatus => true,
    require   => Package['magnum-api'],
  }

  magnum_config {
    'DEFAULT/osapi_volume_listen':  value => $bind_host;
    'DEFAULT/osapi_volume_workers': value => $service_workers;
  }

  if $keystone_enabled {
    magnum_config {
      'DEFAULT/auth_strategy':                value => 'keystone';
      'keystone_authtoken/admin_tenant_name': value => $keystone_tenant;
      'keystone_authtoken/admin_user':        value => $keystone_user;
      'keystone_authtoken/admin_password':    value => $keystone_password;
      'keystone_authtoken/auth_uri':          value => $auth_uri;
      'keystone_authtoken/identity_uri':      value => $identity_uri;
    }

  }

}
