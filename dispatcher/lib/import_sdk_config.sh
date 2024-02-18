#!/bin/sh -e
# This script is only to be used internally in docker and not by
# the customer directly.
# It imitates the application of the layer structures as it
# happens on cloud production systems.
# Requires at least dispatcher-publish version 2.0.110

source /usr/lib/dispatcher-sdk/configuration_reloading.sh

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "Please run this script within Linux!"
  echo "This script is not meant to be run alone but only via docker_run.sh!"
else
  rm -rf "${RUNNING_BASE}"
  build_configuration "${RUNNING_BASE}"
  # As new docroots could have been introduced by the client configuration
  # they have to be created again.
  APACHE_PREFIX="${RUNNING_BASE}" . /docker_entrypoint.d/20-create-docroots.sh
  APACHE_PREFIX="${RUNNING_BASE}" . /docker_entrypoint.d/40-generate-allowed-clients.sh
  if [ "$SKIP_CONFIG_TESTING" != "true" ]; then
    test_configuration "${RUNNING_BASE}" "${CUSTOMER_CONF}"
  fi
fi
