# This is a script that expects 2 arguments
# argument 1 - The user to limit - This is the username (as recognized by the OS) of a user who is
#	to be limited in the scope of their running processes
# argument 2 - The limiting Factor - This is the factor by which the user will be limited. They will
# recieve 1/x(available resources), where X is the avialable resources

#! /bin/bash/

user=$(getent passwd | grep $1)

if [ $? -eq 0 ]; then
	echo "User has been found"
	if [ $2 -gt 0 ]; then
		echo "You have selected a limiting factor of $2"
		./do_cgroups
		exit
	else
		echo "Cannot allot resources to user with limiting factor of $2"
		exit
	fi
else
	echo "User is not found, abort execution"
	exit
fi
