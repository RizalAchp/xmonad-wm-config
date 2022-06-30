#!/bin/bash

function run {
  if ! pgrep $1 ;
  then
    $@&
  fi
}

#Set your native resolution IF it does not exist in xrandr
#More info in the script
#run $HOME/.xmonad/scripts/set-screen-resolution-in-virtualbox.sh

#Find out your monitor name with xrandr or arandr (save and you get this line)
# xrandr --auto --output DVI-0 --mode 1440x900 --right-of DVI-1
#xrandr --output VGA-1 --primary --mode 1360x768 --pos 0x0 --rotate normal
#xrandr --output DP2 --primary --mode 1920x1080 --rate 60.00 --output LVDS1 --off &
#xrandr --output LVDS1 --mode 1366x768 --output DP3 --mode 1920x1080 --right-of LVDS1
#xrandr --output HDMI2 --mode 1920x1080 --pos 1920x0 --rotate normal --output HDMI1 --primary --mode 1920x1080 --pos 0x0 --rotate normal --output VIRTUAL1 --off

#starting user applications at boot time
# run eww daemon
xsetroot -cursor_name left_ptr &
xbacklight -set 80 &
~/.fehbg &

run dunst
run lock.sh
# (sleep 2; run $HOME/.config/polybar/launch.sh) &
# run picom --experimental-backends daemon
run inhibit_activate
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
# pcmanfm -d &
# /usr/bin/emacs --daemon
# sleep 2 && trayer --edge top --align right --widthtype request --padding 6 --SetDockType true --SetPartialStrut true --expand true --monitor 1 --transparent true --alpha 0 0x212121--height 20

#Some ways to set your wallpaper besides variety or nitrogen
#feh --bg-fill /usr/share/backgrounds/arcolinux/arco-wallpaper.jpg &
#start the conky to learn the shortcuts
#(conky -c $HOME/.xmonad/scripts/system-overview) &

#starting utility applications at boot time
#run variety &
# run nm-applet &
# run pamac-tray &
# run volumeicon &
#blueberry-tray &
# urxvtd -q -o -f &
# run trayer --edge top --align right --widthtype request --padding 6 --SetDockType true --SetPartialStrut true --expand true --monitor 1 --transparent true --alpha 0 --tint 0x282c34  --height 20 &
# /usr/lib/xfce4/notifyd/xfce4-notifyd &
# lxpolkit &


