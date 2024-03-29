#   Copyright 2015, CERN.
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
# == Class: magnum::params
#
# these parameters need to be accessed from several locations and
# should be considered to be constant
#
# === Parameters:
#
class magnum::params (
) {

  if $::osfamily == 'Debian' {
    # TODO:

  } elsif($::osfamily == 'RedHat') {

    $package_name       = 'openstack-magnum-common'
    $client_package     = 'python-magnumclient'
    $api_package        = 'openstack-magnum-api'
    $api_service        = 'openstack-magnum-api'
    $conductor_package  = 'openstack-magnum-conductor'
    $conductor_service  = 'openstack-magnum-conductor'
    $db_sync_command    = 'magnum-db-manage upgrade'

  }

}
