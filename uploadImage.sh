#!/bin/bash

filename="$1.$EPOCHREALTIME.png"
echo "Uploading file $1 -> filename: $filename"
source secret
curl "https://cloud.opensenselab.org/remote.php/dav/files/oeb/Shared/$filename" \
	--user "$nextcloudCredentials" -X PUT --upload-file "$1"

sizeX=`file "$1" -b | sed -E "s/^.* ([0-9]+) x ([0-9]+).*$/\1/g"`
sizeY=`file "$1" -b | sed -E "s/^.* ([0-9]+) x ([0-9]+).*$/\2/g"`
url="https://cloud.opensenselab.org/apps/files_sharing/publicpreview/$sharingKey?file=/$filename&x=$sizeX&y=$sizeY"
echo "$url"
