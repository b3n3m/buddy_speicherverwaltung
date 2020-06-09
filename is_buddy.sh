#!/bin/bash



is_buddy(){

	local addr_1=$1
	local addr_2=$2
	local buddy_exp=$3
	#typeset -i buddy_exp addr_1 addr_2

#	shift to the left um auf korretes bit zu kommen welches unterschiedlich sein darf
	mask=$[ (1 << $buddy_exp) ]
	echo $mask

	(( test_1 = mask | addr_1 ))
#	echo $test_1

	(( test_2 = mask | addr_2 ))
#	echo $test_2

	if [[ $test_1 == $test_2 ]]; then
		echo "they are buddys"
	else
		echo "FALSE"
	fi
	
}



is_buddy 4 6 1

is_buddy 256 768 8

is_buddy 256 384 7