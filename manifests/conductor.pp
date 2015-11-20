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
# == Class: magnum::conductor
#
# Manages the Magnum conductor package and service
#
# === Parameters:
#
# [*enabled*]
#   (optional) Whether to enable the magnum-conductor service
#   Defaults to false
#
# [*manage_service*]
#   (optional) Whether to start/stop the service
#   Defaults to true
#
# [*ensure_package*]
#   (optional) The state of the magnum conductor package
#   Defaults to 'present'
#
class magnum::conductor(
  $enabled        = false,
  $manage_service = true,
  $ensure_package = 'present',
) {

  include ::magnum::params

  if $::magnum::params::conductor_package {
    package { 'magnum-conductor':
      ensure => $package_ensure,
      name   => $::magnum::params::conductor_package,
      tag    => 'magnum',
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

  service { 'magnum-conductor':
    ensure    => $ensure,
    name      => $::magnum::params::conductor_service,
    enable    => $enabled,
    hasstatus => true,
    require   => Package['magnum-conductor'],
  }

}
