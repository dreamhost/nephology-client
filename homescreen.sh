#!/bin/bash
cd /home/bootstrap
cat splash
eval `for ITEM in $(cat /proc/cmdline); do echo $ITEM | grep BOOTIF; done`
eval `for ITEM in $(cat /proc/cmdline); do echo $ITEM | grep NEPHOLOGY_SERVER; done`
RESCUE_MODE=0
eval `for ITEM in $(cat /proc/cmdline); do echo $ITEM | grep RESCUE_MODE; done`
if [ -e /dev/ipmi0 ]; then
  echo "Turning off locator light"
  sudo ipmitool chassis identify 0
fi
echo "Boot Ethernet Interface is $BOOTIF"
echo "Nephology Server is $NEPHOLOGY_SERVER"
echo -n "Waiting for Nephology Server to become ready..."
nephology_ready=0
while [ ${nephology_ready} != 1 ]
  do
  ping -c 5 -q -w 10 -n $NEPHOLOGY_SERVER > /dev/null
  if [ $? == 0 ]
    then
      echo "ready!"
      nephology_ready=1
    else
      echo -n "."
      sleep 60
  fi
done
tmux new-window -t $USER -a -n shell 'sudo bash'; tmux select-window -t $USER:0
sleep 1
tmux new-window -t $USER -a -n top 'sudo top'; tmux select-window -t $USER:0
sleep 1
tmux new-window -t $USER -a -n iotop 'sudo iotop'; tmux select-window -t $USER:0
sleep 1
echo
echo
cat <<EOF


Things should be happening in other windows now.  You can also get this
by logging in over SSH or via a Serial Console using the following
credentials:
  username = bootstrap
  password = vaporware
You will automatically attach to this screen session.  This will reboot
once the install is complete, and nephology should take care of the
rest.  Contact an Admin if you have questions.

If the locator light starts blinking, it means the installer found a problem.
Check the other windows in this screen for more details.

EOF
if [ $RESCUE_MODE == 1 ]
  then
    echo "Now in rescue mode, do your maintenance."
    echo "The nephology installer will not start."
  else
    sleep 5
    tmux new-window -t $USER -a -n nephology "/home/bootstrap/nephology-client.pl -s $NEPHOLOGY_SERVER -m $BOOTIF"
fi
while [ 1 ]
  do 
    sleep 10
    if [ ! -f /home/bootstrap/incomplete ]
      then sudo reboot
    fi
done
