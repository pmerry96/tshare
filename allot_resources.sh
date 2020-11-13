# This is a script that expects 2 arguments
# argument 1 - The user to limit - This is the username (as recognized by the OS) of a user who is
#	to be limited in the scope of their running processes
# argument 2 - The limiting Factor - This is the factor by which the user will be limited. They will
# recieve 1/x(available resources), where X is the available resources

#! /bin/bash/

user=$(getent passwd | grep $1)

if [ $? -eq 0 ]; then
	echo "User has been found"
	if [ $2 -gt 0 ]; then
		echo "You have selected a limiting factor of $2"
		memtot=$(awk '/MemTotal/ {printf "%.3f \n", $2/1024/1024}' /proc/meminfo)
		memAva=$(awk '/MemAvailable/ {printf "%.3f \n", $2/1024/1024}' /proc/meminfo)
		memact=$(awk '/Active:/ {printf "%.3f \n", $2/1024/1024}' /proc/meminfo)
		#echo Total Memory = $memtot 
		#echo Available Memory = $memAva
		#echo Active Memory = $memact
		#echo $memtot - $memAva | bc -l
		mempctAct=$(echo $memact / $memtot | bc -l)
		memforty=$(echo $memtot \* 40 / 100 | bc -l)
		if [ $(echo $mempctAct '<' $memforty | bc -l) ]; then
			#echo "beat"
			#echo "beat"
			memAva=$(echo " $memtot * 60 / 100" | bc -l)
			echo $memAva
			usermem=$(echo "$memAva/$2*1000000" | bc -l)
			#userline=$(cat /etc/security/limits.conf | grep -n $1) # | cut -f1 -d:)
			#echo exit code = $?
			roundedmem=$(printf "%.0f\n" $usermem)
			#echo roundedmem = $roundedmem
			userreplace=$(echo @$1 hard as $roundedmem)
			#echo Usermem = $userreplace
			#first, remove any lines changing the AS limit
			#echo userline = $userline
			#echo beat
			userline=$(cat /etc/security/limits.conf | grep -n $1 | wc -l)
			if [ $userline -eq 0 ]; then
				echo "$userreplace" >> /etc/security/limits.conf
			else
				userline=$(cat /etc/security/limits.conf | grep -n $1)
				userlineno=${userline%%:*}
				#echo $? = question
				#case for exit code 0, means user was found in the file
				# therefore time to replace the line, not cat to the file
				#echo $userline = user line
				echo $userlineno = user line
				linetoreplace=$(sudo sed "${userlineno}q;d" /etc/security/limits.conf)
				#echo beat
				echo linetoreplace = $linetoreplace
				sudo sed -i "s/$linetoreplace/$userreplace/" /etc/security/limits.conf
				
				#echo "$userreplace" >> /etc/security/limits.conf
			fi
		fi
		exit
	else
		echo "Cannot allot resources to user with limiting factor of $2"
		exit
	fi
else
	echo "User is not found, abort execution"
	exit
fi
