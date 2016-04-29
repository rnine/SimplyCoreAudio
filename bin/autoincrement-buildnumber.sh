#!/bin/sh

#  autoincrement-buildnumber.sh
#  AudioMate
#
#  Created by Ruben Nine on 4/29/16.
#  Copyright © 2016 Ruben Nine. All rights reserved.

exec > ~/Desktop/post_build_log.txt 2>&1

infoplist="$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"
buildnum=$(git --git-dir="$SRCROOT/.git" log --oneline | wc -l | tr -d '[:space:]')

if [ -z "$buildnum" ]; then
    echo "Failed to set buildNum."
    exit 1
fi

buildnumplus=$(expr $buildnum + 1)
/usr/libexec/Plistbuddy -c "Set CFBundleVersion $buildnumplus" "$infoplist"
