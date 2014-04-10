#!/bin/sh


PID=/var/run/auto_syslogd

auto_package=/mnt/usb/install/auto_package
auto_package_done=/mnt/usb/install/auto_package_done

# Initiates the log facility and starts the installation
if  [ -e /mnt/usb/install/auto_package ] ||  !  /etc/init.d/ext enabled  ; then
	start-stop-daemon -b -S -m -p $PID -x syslogd -- -n -L -R 192.168.1.2:9999
	/bin/box_installer.sh 2>&1 | logger 
	# create the file always


	#Count containing lines, and only shift first to "done"
	package_lines=`cat $auto_package | wc -l`
	if [ "$package_lines" -gt "1" ] ; then
		logger "Multiple line auto_package found. Shifting 1st line to auto_package_done"
		head -n 1 $auto_package  >> $auto_package_done
		tail -n +2 $auto_package > /tmp/auto_install_new
		mv /tmp/auto_install_new $auto_package
	else
  		mv $auto_package  $auto_package_done
	fi

	logger "Initiating reboot after installation"
	reboot
else
	echo "Does not run because /mnt/usb/install/auto_package  does not exists"
fi

