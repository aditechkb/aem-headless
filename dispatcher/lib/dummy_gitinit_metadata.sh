#!/bin/sh
# Creates a dummy gitinit metadata file to test /gitinit-status endpoint


mkdir -p ${APACHE_PREFIX}/metadata
OUTPUT_FILE=${APACHE_PREFIX}/metadata/gitinit-status.json

cat << EOF > ${OUTPUT_FILE}
{
	"status": "ok",
	"reason": "exit code: 1 (started: 2022-11-09T10:30:20+00:00 finished: 2022-11-09T10:30:26+00:00)",
	"time": "2022-11-09 10:30:26",
	"httpdConfigUrl":"https://localhost/dummyconfig.zip"
}
EOF
