#!/bin/bash
#

if [[ $(whereis "xinput" | grep ":$") ]]; then
	echo "Package xinput is not installed. Install it and try again:"
	echo "    sudo apt install xinput"
	exit -1
fi

MOUSE_NAME=$( xinput list --name-only | grep -i mouse )
if [[ $MOUSE_NAME == "" ]]; then
        echo "No mouse detected."
        exit -1
fi

MOUSE_ID=$( xinput --list | grep -i "$MOUSE_NAME" | sed -e "s/.\+id=\([0-9]\+\).\+/\1/" )
if [[ "$MOUSE_ID" == "" ]]; then
        echo "No id detected for mouse '$MOUSE_NAME'."
        exit -1
fi

echo "* Detected mouse $MOUSE_NAME (id $MOUSE_ID)"


INITIAL_CURSOR_SCALE=$( gsettings get com.canonical.Unity.Interface cursor-scale-factor )
if [[ "$INITIAL_CURSOR_SCALE" == "" ]]; then
        INITIAL_CURSOR_SCALE=1
fi

MIN_DIFF=40
MAX_CURSOR_SCALE=3      # Max cursor scales for Unity. No more than 3 :(
LITTLE_WHILE=1          # in seconds

echo "* If anything goes wrong, you can later reset your cursor size with:"
echo "      gsettings set com.canonical.Unity.Interface cursor-scale-factor $INITIAL_CURSOR_SCALE"

NEW_POS_X=$( xinput query-state 9 | grep "valuator\[0\]" | sed 's/.\+=\([0-9]\+\)/\1/' )
NEW_POS_Y=$( xinput query-state 9 | grep "valuator\[1\]" | sed 's/.\+=\([0-9]\+\)/\1/' )

while [[ 1 ]]; do
        POS_X=$NEW_POS_X
        POS_Y=$NEW_POS_Y
        NEW_POS_X=$( xinput query-state 9 | grep "valuator\[0\]" | sed 's/.\+=\([0-9]\+\)/\1/' )
        NEW_POS_Y=$( xinput query-state 9 | grep "valuator\[1\]" | sed 's/.\+=\([0-9]\+\)/\1/' )

        let DIST=$(( ($NEW_POS_X - $POS_X)**2 + ($NEW_POS_Y - $POS_Y)**2 ))
        if [[ $DIST -gt 0 ]]; then
                let DIST=$( echo "sqrt($DIST)" | bc )
                if [[ $DIST -gt $MIN_DIFF ]]; then
                        #echo $DIST
                        gsettings set com.canonical.Unity.Interface cursor-scale-factor $MAX_CURSOR_SCALE
                        sleep $LITTLE_WHILE
                        gsettings set com.canonical.Unity.Interface cursor-scale-factor $INITIAL_CURSOR_SCALE
                        NEW_POS_X=$( xinput query-state 9 | grep "valuator\[0\]" | sed 's/.\+=\([0-9]\+\)/\1/' )
			NEW_POS_Y=$( xinput query-state 9 | grep "valuator\[1\]" | sed 's/.\+=\([0-9]\+\)/\1/' )
                fi
        fi
done;

