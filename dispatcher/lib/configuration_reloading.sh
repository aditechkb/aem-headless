#!/bin/sh
# 
# This is a collection of bash functions evolving around configuration reloading

# Test directory where configurations are compiled for tests
TESTING_BASE=/tmp/test/etc/httpd

# Running configurations that contains the tested configuration that is run with httpd
RUNNING_BASE=/etc/httpd

# Previous configuration
PREVIOUS_BASE=/etc/httpd-prev

# Where customer configuration is mounted
MOUNT_SOURCE=/mnt/dev/src

# Copy of customer configuration to compare changes to
SOURCE_COPY=/tmp/dev
SOURCE_BASE=${SOURCE_COPY}/etc/httpd

CUSTOMER_CONF=/mnt/dev/src

# Layer folder that contains the base layers
LAYERS_CONF=/etc/httpd-overlay

LOG_APACHE_INFO=""
DUMP_CONFIG_INFO="-D DUMP_RUN_CFG -D DUMP_ANY"

function log_warn {
    message=$*
	echo "WARN $(date): ${message}"
}

function log_info {
    message=$*
	echo "INFO $(date): ${message}"
}

function log_debug {
    if [ -n "${VERBOSE_DEBUG}" ]; then
        message=$*
	    echo "DEBUG $(date): ${message}"
    fi
}

function check_configuration_changed {
    REFERENCE_CONF=${1}
    NEW_CONF="${2}"
    # check for change in configuration, return 
    set +e
    echo diff -r ${REFERENCE_CONF} ${NEW_CONF}
    diff -r  ${REFERENCE_CONF} ${NEW_CONF}
    if [ $? -ne 0 ]
    then 
        set -e
        return 1
    fi
    set -e
    return 0
}

function build_configuration {
  target="${1}"
  immutable_check=${2-false}
  mkdir -p ${target}

  log_debug "Copying base configuration from layer 0 ..."
  cp -R "${LAYERS_CONF}/layer0-defaults"/* "${target}/"
  log_debug "Copied layer 0 files."

  if [[ ! -L "${target}/logs" ]]; then
	log_debug "layer0: create symlink to /var/log/apache2"
	ln -s /var/log/apache2 "${target}/logs"
  fi

  if [[ ! -L "${target}/modules" ]]; then
    log_debug "layer0: create symlink to /usr/lib/apache2"
    ln -s /usr/lib/apache2 "${target}/modules"
  fi

  log_debug "Copying customer configuration..."
  for relativeSubfolder in "conf.d" "conf.dispatcher.d"
  do
      log_debug "processing configuration subfolder: $relativeSubfolder"
      subfolder="${CUSTOMER_CONF}/${relativeSubfolder}"
      [ -d "${subfolder}" ] || error "${relativeSubfolder} configuration subfolder not found in: ${CUSTOMER_CONF}"
      for file in $(find "${subfolder}" -type f -or -type l | grep -Ev '/.git' | grep -Ev '.DS_Store')
      do
          resolved="$(cd -P "$(dirname "$file")" && pwd -P)"
          fullpath=${resolved}/$(basename "${file}")
          relativepath=${relativeSubfolder}/${fullpath#*/${relativeSubfolder}/}
          targetfiledir="$(dirname "${target}/${relativepath}")"
          mkdir -p "${targetfiledir}"
          cp -d "${fullpath}" "${target}/${relativepath}"
      done

      # Process symlinks for windows (pseudo symlinks)
      # Files start with ../ should be translated to symlinks
      log_debug "Fixing symlinks for: ${target}/${relativeSubfolder}"
      grep -Ril "${target}/${relativeSubfolder}" -e '^\.\.\/' | while read -r line ; do
        content=$(cat $line)
        folder=$(dirname "$line")
        if [ -f "$folder/$content" ]; then
            rm "$line"
            ln -s "$content" "$line"
        else
            log_warn "Pseudo symlink ${relativeSubfolder} seems to point to a non-existing file!"
        fi
      done
  done
  log_info "Copied customer configuration to ${target}."

  if [[ "${immutable_check}" == "check" ]]; then
    # Check if immutable files have changed.
    for file in $(find /etc/httpd-overlay/layer2-immutable -type f)
    do
        relative_file="${file#/etc/httpd-overlay/layer2-immutable/}"
        diff -b -q "${target}/${relative_file}" "${file}" &> /dev/null || {
            log_warn "Immutable file ${relative_file} has been changed and will be overwritten!"
            if [[ -n "${VERBOSE_DEBUG}" ]]; then
                diff -b "${target}/${relative_file}" "${file}" || true
            fi
        }
    done
  fi

  log_debug "Copying immutable files from layer 2 ..."
  cp -R "${LAYERS_CONF}/layer2-immutable"/* "${target}/"
  log_debug "Copied layer 2 files."
}

function test_configuration {
    target="${1}"
    user_config="${2}"

    if [ -f /usr/sbin/envvars ]; then
        . /usr/sbin/envvars
    fi

    # Test user configuration with validator
    log_info "Start testing"
    set +e

    if [ "$HOST_OS" = "windows" ]; then
        log_info "Not running validator on windows!"
    else
        if [ -f /usr/local/bin/validator ]; then
            if [ -f "${user_config}"/opt-in/USE_SOURCES_DIRECTLY ]; then
                /usr/local/bin/validator full -relaxed "${user_config}"
                if [ $? -ne 0 ]; then 
                    echo " "
                    echo "ERROR $(date) Configuration invalid, please fix and retry, "
                    echo "              Line numbers reported are correct for your configuration files."
                    echo " "
                    set -e
                    return 1
                fi
            else
                log_info "Not running validator as flexible mode is not active!"
            fi
        else
            log_info "Validator binary not found!"
        fi
    fi

    source /usr/sbin/httpd-arguments
    cleanup_arguments

    log_info "Testing with fresh base configuration files."
    if [ -z "${LOG_APACHE_INFO}" ]
    then
        LOG_APACHE_INFO="done"
        log_info "Apache httpd information"
        echo " "
        su-exec "${APACHE_USER}:${APACHE_GROUP}" httpd -V -S -d ${target} -f ${target}/conf/httpd.conf
        echo " "
        echo su-exec "${APACHE_USER}:${APACHE_GROUP}" httpd  -d ${target} -f ${target}/conf/httpd.conf ${ARGS} -t ${DUMP_CONFIG_INFO}
        echo " "
        echo " "
    fi

    sed -i "s#ServerRoot [\"]/etc/httpd[\"]#ServerRoot \"${target}\"#" "${target}/conf/httpd.conf"

    APACHE_PREFIX=${target} su-exec "${APACHE_USER}:${APACHE_GROUP}" httpd -d ${target} -f ${target}/conf/httpd.conf -d ${target} ${ARGS} -t ${DUMP_CONFIG_INFO}
    if [ $? -ne 0 ]
    then 
        echo " "
        echo "ERROR $(date) Configuration invalid, please fix and retry, "
        echo "              Line numbers reported are correct for your configuration files."
        echo "              replace ${target} with src/ for your local path. "
        echo " "
        set -e
        return 1
    fi
    
    # only dump on the first time, more than that gets annoying.
    DUMP_CONFIG_INFO=""

    set -e
    return 0
}
