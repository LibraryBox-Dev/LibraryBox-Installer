#!/bin/sh


PID=/var/run/auto_syslogd

auto_package=/mnt/usb/install/auto_package
auto_package_done=/mnt/usb/install/auto_package_done
logfile=/mnt/usb/install.log

stopfile=/mnt/usb/stop.txt

start_log(){
##Central function for logging;
##  only start logging if not already online
	if [ ! -e $PID ]  ; then
		[ -e $logfile ] && echo "---------------------------------------------" >> $logfile
		start-stop-daemon -b -S -m -p $PID -x syslogd -- -n -L -R 192.168.1.2:9999 
	fi
}

finish_log(){
	## Copy log to USB disc
	echo "$0 : Logging install log to USB-Stick"
	cat /var/log/messages >>  $logfile
}

if [ -e $stopfile ] ; then
	start_log
	logger "$0 : Stop file detected. Ending processing"
	rm  $stopfile   2>&1 | logger 
	logger "$0 : Stop file removed."
	finish_log
	exit 0
fi

if ! /etc/init.d/ext enabled  ; then
	start_log

	logger "$0 : Doing extendRoot initilization"

	/bin/box_installer.sh -e 2>&1 | logger

	RC=$?
	if [ "$RC" -gt "0" ] ; then
		logger "$0 : An error occured - Stopping process here ; $RC"
		finish_log
		exit $RC
	fi

	finish_log
fi


# Initiates the log facility and starts the installation
if  [ -e /mnt/usb/install/auto_package ]; then

	start_log

	/bin/box_installer.sh -p 2>&1 | logger 


	# Always move the first line only
	head -n 1 $auto_package  >> $auto_package_done

	#Count containing lines, and only shift first to "done"
	package_lines=`cat $auto_package | wc -l`
	if [ "$package_lines" -gt "1" ] ; then
		logger "$0 : Multiple line auto_package found. Shifting 1st line to auto_package_done"
		tail -n +2 $auto_package > /tmp/auto_install_new
		mv /tmp/auto_install_new $auto_package
	else
		rm $auto_package
	fi


	logger "$0 : Initiating reboot after installation"
	finish_log
	sync && reboot
else
	echo "Does not run because /mnt/usb/install/auto_package  does not exists"
fi


