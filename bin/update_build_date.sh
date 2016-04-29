#!/bin/sh

#  update_build_date.sh
#  AudioMate
#
#  Created by Ruben Nine on 4/29/16.
#  Copyright © 2016 Ruben Nine. All rights reserved.

exec > ~/Desktop/post_build_log.txt 2>&1

infoplist="$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"
builddate=`date`

if [[ -n "$builddate" ]]; then
    /usr/libexec/PlistBuddy -c "Add :BuildDate string $builddate" ${infoplist}
    /usr/libexec/PlistBuddy -c "Set :BuildDate $builddate" ${infoplist}
fi
