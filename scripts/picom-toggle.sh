#!/usr/bin/bash

if pgrep -x "picom" > /dev/null
then
	killall picom
else
	picom --experimental-backends --daemon --config $HOME/.xmonad/scripts/picom.conf &
fi
