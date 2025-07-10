#!/bin/bash

# All lines that contain an indication of an error
failingLines=`grep -E -n "^ +[0-9]+) should" test_output.log`

# For all the errors, find the appropriate screenshot
while IFS= read -r line || [ -n "$line" ]; do
	# There are no screenshots of hooks
	notHook=`echo "$line" | grep --quiet 'all" hook' && echo "notHook"`
	if [ -z "$notHook" ]; then
		# Get the line number of the error indication; this is needed to find the batch
		number=`echo "$line" | cut -f1 -d:`
		withoutNumber=`echo "$line" | sed -E "s/^[0-9]+:(.*)$/\1/"`
		# Get the indentation count to figure out how nested the test is
		indentation=`echo "$withoutNumber" | sed -E "s/^( *).*/\1/" | tr -d '\n' | wc -c`
		# Get the text of the failed test
		text=`echo "$withoutNumber" | sed -E "s/^ +[0-9]+\) (.*)$/\1/"`
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

