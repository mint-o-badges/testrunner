#!/bin/bash

# Returns the string in the format `, "attachments": [<attachments>]`

result=""
while IFS='' read -r file || [ -n "$file" ]; do
	if [ -n "$file" ]; then
		if [ "$result" == "" ]; then
			result=', "attachments": [';
		else
			result="$result, "
		fi

		url=`./uploadImage.sh $file`
		result="$result{\"text\": \"$file\", \"image_url\": \"$url\"}"
	fi
done < /dev/stdin

[ "$result" != "" ] && result="$result]"
echo $result
