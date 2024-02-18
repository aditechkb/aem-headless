#!/bin/sh
#

usage() {
    cat <<EOF >& 1
Usage: $0 immutable-file-list config-folder [mode: {check|extract}]

Examples:
  # Use "immutable.files.txt" list file and config folder "src" (assuming default "check" mode)
  $0 immutable.files.txt src
  or explicitly giving the "check" mode
  $0 immutable.filex.txt src check
  # Use "immutable.files.txt" list file to extract immutable files into "src" config folder
  $0 immutable.filex.txt src extract

EOF
    exit 1
}

error() {
    echo >&2 "** error: $1"
    exit 2
}

warn() {
    echo >&2 "** warning: $1"
}

[ $# -eq 2 ] || [ $# -eq 3 ] || usage

listFile=$1
shift

actualConfigFolder=$1
shift

mode=$1

if [ "$mode" == "" ]; then
	echo "empty mode param, assuming mode = 'check'"
	mode="check"
else
	if [ "$mode" != "check" ] && [ "$mode" != "extract" ]; then
		error "mode '$mode' is neither 'check' nor 'extract'"
	fi
fi

echo "running in '${mode}' mode"

expectedConfigFolder="/etc/httpd"
immutableFilesChanges=0

[ -f "$listFile" ] || error "immutable file list not found: ${listFile}"
[ -d "$expectedConfigFolder" ] || error "original config folder not found: ${expectedConfigFolder}"
[ -d "$actualConfigFolder" ] || error "config folder not found: ${actualConfigFolder}"

echo "reading immutable file list from ${listFile}"


immutableFiles=$(cat "${listFile}")
for file in ${immutableFiles}
do
    if [ "$mode" == "extract" ] || [ -f "${actualConfigFolder}"/"${file}" ]; then

        if [ "$mode" == "check" ]; then
            echo "checking '${file}' immutability (if present)"
        else
            echo "preparing '${file}' immutable file extraction"
        fi

        # align legacy layout includes for backward compatibility
        case ${file} in
        conf.d/dispatcher_vhost.conf)
            echo "replacing include directive in '${file}' before proceeding"
            sed -i 's#Include conf.d/enabled_vhosts/vhosts.conf#Include conf.d/enabled_vhosts/\*.vhost#' "${expectedConfigFolder}"/"${file}"
            ;;
        conf.dispatcher.d/dispatcher.any)
            echo "replacing include directive in '${file}' before proceeding"
            sed -Ei "s#(.*)[\$]include [\"]enabled_farms/farms.any[\"]#\1\$include \"enabled_farms/*.farm\"#" "${expectedConfigFolder}"/"${file}"
            ;;
        conf.dispatcher.d/cache/default_invalidate.any)
            if [ "$mode" == "check" ]; then
                echo "replacing '${file}' content as it gets overridden on startup anyway"
                cp -f "${actualConfigFolder}"/"${file}" "${expectedConfigFolder}"/"${file}"
            fi
            ;;
        esac

        if [ "$mode" == "check" ]; then
            echo "checking existing '${file}' for changes"
            diff -b -q "${expectedConfigFolder}"/"${file}" "${actualConfigFolder}"/"${file}" > /dev/null || {
                echo "immutable file '${file}' has been changed:"
                diff "${expectedConfigFolder}"/"${file}" "${actualConfigFolder}"/"${file}"
                warn "immutable file '${file}' has been changed!"
                immutableFilesChanges=$(( immutableFilesChanges + 1 ))
            }
        else
            echo "force-copying '${file} into config directory (creating parent dirs if not present)"
            mkdir -v -p $(dirname "${actualConfigFolder}"/"${file}")
            cp --verbose --force  "${expectedConfigFolder}"/"${file}" "${actualConfigFolder}"/"${file}"
        fi
    else
        if [ "$mode" == "extract" ]; then
            echo "immutable file '${file}' not present, skipping"
        fi
    fi
done

if [ "$mode" == "check" ]; then
    [ ${immutableFilesChanges} -ne 0 ] && {
        error "${immutableFilesChanges} immutable files changed";
    } || {
        echo "no immutable file has been changed - check is SUCCESSFUL";
        exit 0;
    }
else
    echo "immutable files extraction COMPLETE"
fi
