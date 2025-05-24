#!/bin/bash

# All lines that contain an indication of an error
failingLines=`grep -E -n "^    [0-9]+)" test_output.log`

# For all the errors, find the appropriate screenshot
while IFS= read -r line || [[ -n $line ]]; do
	if [ `echo "$line" | grep -c 'all" hook'` -eq 0 ]; then
		# Get the line number of the error indication; this is needed to find the batch
		number=`echo "$line" | cut -f1 -d:`
		# Get the text of the failed test
		text=`echo "$line" | sed -E "s/^[0-9]+: +[0-9]+\) (.*)$/\1/"`
		# Get the batch of the failed test; this is the last batch text before this test text
		batch=`head -n "$number" test_output.log | grep -Ei "^  [a-zA-Z]+ test" | tail -n 1 | xargs`
		# Construct the file name
		appended="$batch $text"
		lower=`echo "$appended" | tr '[:upper:]' '[:lower:]'`
		underscored=`echo "$lower" | sed "s/ /_/g"`
		filename="$underscored.png"
		path="oeb-test/screenshots/$filename"
		# Only output the path if it actually exists
		ls "$path"
	fi
done < <(printf '%s' "$failingLines")

