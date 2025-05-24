#!/bin/bash

# This script is run via a systemd timer. The service and timer files lie in /lib/systemd/system
# (and are called testrunner.service and testrunner.timer, respectively).
# This script is not intended to be run manually.

# Don't run twice
if [ -f ~/test/mutex ]; then
	echo "Mutex exists already!"
	# This is disabled for now, since systemd *should* already ensure this doesn't run twice.
	# If this case occurs then, probably something went wrong with the mutex. If the test is
	# ever run outside of systemd timers, this becomes relevant again.
	#exit 0
fi
touch ~/test/mutex

# Check status of badgr-ui
cd ~/docker/badgr-ui
uiNew=`docker compose exec ui ls newVersion 2> /dev/null`
if [ -n "$uiNew" ]; then
	uiTime=`docker compose exec -T ui stat -c"%Z" newVersion`
else
	uiTime=0
fi

# Check status of badgr-server
cd ~/docker/badgr-server
serverNew=`docker compose exec -T api ls newVersion 2> /dev/null`
if [ -n "$serverNew" ]; then
	serverTime=`docker compose exec -T api stat -c "%Z" newVersion`
else
	serverTime=0
fi

if [ -z "$uiNew" ]; then
	if [ -z "$serverNew" ]; then
		echo "Nothing new!"
		rm ~/test/mutex
		exit 0
	fi
fi

echo "Something is new!"


newestTime=`echo -e "$serverTime\n$uiTime" | sort -n | tail -1`
currentTime=`date +%s`
elapsed=$((currentTime - newestTime))
echo "Elapsed time: $elapsed"

# Wait 60s after update to give the application time to settle
if [ $elapsed -lt 60 ]; then
	rm ~/test/mutex
	exit 0
fi

# Delete newVersion indicator in containers
if [ -n "$uiNew" ]; then
	cd ~/docker/badgr-ui
	docker compose exec ui rm newVersion
fi
if [ -n "$serverNew" ]; then
	cd ~/docker/badgr-server
	docker compose exec api rm newVersion
fi

echo "Initiating tests!"
cd ~/test/oeb-test

# Updating test repository
git pull

# Preserve exit code
set -o pipefail
timeout 30m docker compose run node 2>&1 | tee ~/test/test_output.log
exitCode=$?

echo "Exit code is $exitCode"

cd ~/test
attachmentString=`./failingScreenshots.sh | ./attachImages.sh`
if [ "$exitCode" -eq "0" ]; then
	echo "Successful!"
	# Only notify if the last test failed
	if [ -f lastFailed ]; then
		echo "Fixed! All tests successful again." | ./notify.sh
		rm lastFailed
	fi
elif [ "$exitCode" -eq "124" ]; then
	echo "Timeout!"
	if [ "$attachmentString" == "" ]; then
		echo "Tests timed out! No errors were detected though. Log:" | ./notify.sh
		./notify.sh < test_output.log
	else
		echo "Tests timed out! They seem to have failed. Log:" | ./notify.sh
		./notify.sh "$attachmentString" < test_output.log
		touch lastFailed
	fi
else
	echo "Failed!"
	echo "Tests failed! Note that there are screenshots in /home/ubuntu/test/oeb-test/screenshots. Log:" | ./notify.sh
	./notify.sh "$attachmentString" < test_output.log
	touch lastFailed
fi

rm ~/test/mutex
