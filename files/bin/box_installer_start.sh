#!/bin/sh


PID=/var/run/auto_syslogd

auto_package=/mnt/usb/install/auto_package
auto_package_done=/mnt/usb/install/auto_package_done
logfile=/mnt/usb/install.log

new_image_location=/mnt/usb/auto_flash

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


if [ ls -1  "${new_image_location}"/openwrt-*.bin >> /dev/null 2>&1  ]  ; then
	## Found image(s) at the download location

	### get system var uci get box-installer.
	model_type=""

	found_images=$( ls  ${new_image_location}/openwrt-*${model_type}*.bin | wc -w )

	if [ "$found_images" -eq 1 ] ; then
		cnt=$( ls $new_image_location/openwrt-${model_type}*.bin.* )
		image_path=$( ls -1 ${new_image_location}/openwrt-${model_type}*.bin )
		logger "$0 : Creating backup of image file"
		mv -v $image_path     "${$image_path}.${cnt}" | logger 
		sysupgrade -n  "${$image_path}.${cnt}" 2>&1  | logger
	else
		logger "$0 : More than one image found fitting to: "
		logger "$0 :      modeltype: ${model_type} "
		ls  ${new_image_location}/openwrt-${model_type}*.bin | logger
	fi
fi

if ! /etc/init.d/ext enabled ; then
	start_log

	logger "Doing extendRoot initilization"

	/bin/box_installer.sh -e 2>&1 | logger

	RC=$?
	if [ "$RC" -gt "0" ] ; then
		logger "An error occured - Stopping process here ; $RC"
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
		logger "Multiple line auto_package found. Shifting 1st line to auto_package_done"
		tail -n +2 $auto_package > /tmp/auto_install_new
		mv /tmp/auto_install_new $auto_package
	else
		rm $auto_package
	fi


	logger "Initiating reboot after installation"
	finish_log
	sync && reboot
else
	echo "Does not run because /mnt/usb/install/auto_package  does not exists"
fi


