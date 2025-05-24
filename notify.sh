#!/bin/bash

# The first parameter is the attachmentsString (see attachImages.sh)
set -e

source secret

cat /dev/stdin > message

# If '> test' is contained in the message,
# it is assumed to be test output log
if grep --quiet -e '> test' message; then
	# Filter out irrelevant messages from log
	grep -A1000 -m1 -e '> test' message > filtered
	# Normalize message to be sent
	echo -e '```\n' > message
	sed 's/"/\\"/g' filtered | sed -e 's/[^[:print:]]//g' >> message
	echo -e '\n```\n' >> message
	rm filtered
fi


input="$(< message)"

curl -X POST \
	-H 'Content-Type: application/json' \
	-d '{"text": "'"$input"'"'"$1"'}' \
	"$mattermostUrl"

echo

rm message
