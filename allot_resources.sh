# This is a script that expects 2 arguments
# argument 1 - The user to limit - This is the username (as recognized by the OS) of a user who is
#	to be limited in the scope of their running processes
# argument 2 - The limiting Factor - This is the factor by which the user will be limited. They will
# recieve 1/x(available resources), where X is the available resources

#! /bin/bash/

user=$(getent passwd | grep $1)
currentmem=$(ulimit -v)
if [ $currentmem == "unlimited" ]; then
	currentmem=0
fi

if [ $? -eq 0 ]; then
	#echo "User has been found"
	if [ $2 -gt 0 ]; then
		#echo "You have selected a limiting factor of $2"
		memtot=$(awk '/MemTotal/ {printf "%.3f \n", $2/1024/1024}' /proc/meminfo)
		memAva=$(awk '/MemAvailable/ {printf "%.3f \n", $2/1024/1024}' /proc/meminfo)
		memact=$(awk '/Active:/ {printf "%.3f \n", $2/1024/1024}' /proc/meminfo)
		mempctAct=$(echo $memact / $memtot | bc -l)
		memforty=$(echo $memtot \* 40 / 100 | bc -l)
		if [ $(echo $mempctAct '<' $memforty | bc -l) ]; then
			memAva=$(echo " $memtot * 60 / 100" | bc -l)
			#echo $memAva
			usermem=$(echo "$memAva/$2*1000000" | bc -l)
			roundedmem=$(printf "%.0f\n" $usermem)
			userreplace=$(echo @$1 hard as $roundedmem)
			userline=$(cat /etc/security/limits.conf | grep -n $1 | wc -l)
			if [ $userline -eq 0 ]; then
				echo "$userreplace" >> /etc/security/limits.conf
				echo "You will be logged out in 5 minutes" | write $1
				echo "skill -kill -u $1" | at now + 5 minutes
			else
				userline=$(cat /etc/security/limits.conf | grep -n $1)
				userlineno=${userline%%:*}
				#echo $userlineno = user line
				linetoreplace=$(sudo sed "${userlineno}q;d" /etc/security/limits.conf)
				#echo linetoreplace = $linetoreplace
				sudo sed -i "s/$linetoreplace/$userreplace/" /etc/security/limits.conf
				#if you had unlimited resources
				# or
				# if your prev resources are more than your newly allotted
				if [ $currentmem == 0 ] || [ $currentmem > $roundedmem]; then
					echo "Your memory allotement has changed, please sign off and back on as soon as possible for changes to take effect" | write $1
					#==============================================================================
					#==============================================================================
					#uncomment the following 3 lines in order to force user logout when allotment decreases
					#to uncomment, simply delete the '#' character at the beginning of the line
					# ********************** BEGIN UNCOMMENTING HERE ******************************
					#
					#echo "You will be logged out in 5 minutes" | write $1
					#echo "echo \"you will be logged out in 1 minute\" | write $1" | at now + 4 minutes
					#echo "skill -kill -u $1" | at now + 5 minutes
					#
					# ****************** DO NOT UNCOMMENT FURTHER THAN HERE ***********************
					#==============================================================================
					#=============================================================================
				fi
			fi
		fi
		exit
	else

		exit
	fi
else
	#echo "User is not found, abort execution"
	exit
fi
