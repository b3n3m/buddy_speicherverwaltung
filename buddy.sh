#!/bin/bash

#############################################################################################
#                                                                                           #
# This shell script represents a simulation of a Budyy Allocation System.                   #
# Authors: Benedikt Möller (benedikt.moeller@stud.fra-uas.de)                               #
#          Florijan Ajvazi (florian.ajvazi@stud.fra-uas.de)                                 #
#          Supported by lyrahgames (https://github.com/lyrahgames)                          #
#                                                                                           #
# Copyright (c) 2020-2020 Benedikt Möller, Florijan Ajvazi  All Rights Reserved. 			#
#                                                                                           #
#############################################################################################


##########################################################################
# allocation function
allocate(){

size=$1
# check next higher fitting dual power
size_exp=$(echo "l($size)/l(2)" | bc -l)
(( size_exp = ${size_exp%.*}+1 ))

message="Try to allocate $size Byte"
# check request details
if [[ $size -le 0 ]]; then
	message+=" --> Error: Request must be an Integer > 0"
	return
fi
if [[ $max_exp -lt $size_exp ]]; then
	message+=" --> Error: Request is overlarge"
	return
fi
if [[ $size_exp -lt $min_exp ]]; then
	size_exp=$min_exp
fi
# define exponent in arr
(( index = $size_exp - $min_exp ))
split_index=-1
# check if buddy in requested size exist
for (( i = ${index}; i <= ${max_exp}-${min_exp}; ++i )); do
	if [[ ${fb_arr[$i]} != -1 ]]; then
		split_index=$i
		break
	fi
done
# check if enough space left to perform request
if [[ ${split_index} == -1 ]]; then
	message+=" --> Error: Not enough Space available"
	return
fi

# result = content fb_arr -> shows start index for requested size
# maintaining consistency of "Linked List" for split
result=${fb_arr[${split_index}]}
fb_arr[${split_index}]=${mem_arr[$result]}

# next lower exponent -> split
for (( i = ${split_index}-1; $i >= $index; --i )); do
	fb_arr[${i}]=$(( ${result} + $(( 1 << $(( ${min_exp} + ${i} )) )) ))
	mem_arr[${fb_arr[i]}]=-1
done
# safe Bucketsize in Header = Startaddress Bucket 
mem_arr[$result]=$index
# Bucket Startaddress, real stored request
(( result+=1 ))
# safe result in request_arr and set return message
request_arr=("${request_arr[@]}" $result)
(( size_real = 1 << size_exp))
(( actual_mem-=size_real ))
message="Startaddress: $result | Requested size: $size | Used size: $size_real"

if [[ $action == "s" ]]; then view; fi
}


##########################################################################
# buddy checking fuction
is_buddy(){

	# $1=compare Startaddress 1 / $2=compare Startaddress 2 / $3=size freed buddy
	local addr_1=$1
	local addr_2=$2
	local buddy_exp=$3
	# shift to the left to get Bit which is allowed to be different = mask
	(( mask = (1 << buddy_exp) ))

	# compare possible buddys with Bitwise OR
	(( test_1 = mask | addr_1 ))
	(( test_2 = mask | addr_2 ))

	# 0=!Buddys, false / 1=Buddys, true
	if [[ $test_1 == $test_2 ]]; then
		echo 1
	else
		echo 0
	fi
	
}


##########################################################################
# deallocation function
free(){

# $1=Startaddress of real stored request, not real Bucket size with Header
addr=$(( $1 - 1 ))
# index = Header information (size)
index=${mem_arr[$addr]}
(( curr_exp = index + min_exp ))

# check if requested deallocation Startaddress is already allocated
message="Try to free space from Startaddress: $1 on"
    allo_check=-1
	for i in "${request_arr[@]}"; do
    	if [[ $i == $1 ]]; then
    		allo_check=0
    		message+=" --> $(( 1 << curr_exp )) Byte successfully deallocated"
    		(( actual_mem += (1 << curr_exp) ))
    		delete=($1)
    		for target in "${delete[@]}"; do
  				for i in "${!request_arr[@]}"; do
    			if [[ ${request_arr[i]} = $target ]]; then
      				unset 'request_arr[i]'
    			fi
  				done
			done
    		break
    	fi
   	done 
   	if [[ $allo_check != 0 ]]; then
   		message+=" --> Error: Wrong Startaddress, nothing has been freed"
   		return
   	fi

# merge process and deallocate 
while [[ true ]]; do

	# pointer to an element which iterates over "linked List"
	iterator=${fb_arr[$index]}
	# address to evtl. merging buddys
	merge_buddy=-1
	# used for removing element at "linked List" in the middle, auxciliary variable, 
	# points to the previous element with respect to iterator if existent
	prev=-1
	# check all elements in "linked List" for merge buddies
	while [[ $iterator != -1 ]]; do
		if [[ $(is_buddy $addr $iterator $curr_exp) == 1 ]]; then
			merge_buddy=$iterator
			break
		fi
		# change of "linked list" variables to iterate till the end of the List
		prev=$iterator
		iterator=${mem_arr[$iterator]}
	done

	# if no merge buddy is available
	if [[ $merge_buddy == -1 ]]; then
		# move "pointer" (linked list") vom free pointer auf neuen größeren Buddy, 
		# index der startadress in metadaten
		mem_arr[$addr]=${fb_arr[$index]}
		# new free start index in metadata
		fb_arr[$index]=$addr
		break
	fi
	# if size addr = shift size curr_exp -> addr=0 else addr=addr
	# if freed buddy is on the right side, ever to smaler address
	(( addr &= (~(1 << curr_exp)) ))
	# if there is no/does not exist a previous element
	if [[ $prev == -1 ]]; then
		fb_arr[$index]=${mem_arr[$merge_buddy]}
	else
		mem_arr[$prev]=${mem_arr[$merge_buddy]}
	fi
	# check for Multimerge
	(( index+=1 ))
	(( curr_exp+=1 ))
	view

done

view
}


# output function with logging option
view(){

echo -e "\033[7mInfo  \033[0m  \c" 
# check if logging optin is enabled
if [[ $1 == "-l" ]]; then
	echo -e "$message" | tee -a log
else 
	echo -e "$message"
fi
	
	echo -e "_____________________________"

	printf "\033[1mSize\t| Free Startaddresses (-1 = no free Block)\033[0m\n"
	for (( i = 0; i < $max_exp-$min_exp+1; i++ )); do

		(( vsize = (i + min_exp) ))
		(( vsize = (1 << vsize) ))

		printf "%d\t" $vsize
		value=${fb_arr[i]}
		printf "| %d\t" $value
    	while [[ $value != -1 ]]; do
    		value=${mem_arr[$value]}
    		printf "| %d\t" $value
    	done
    	printf "\n"
    	
    done 

echo -e "_____________________________\nChart (#-used Space // I-Splitpoint)\n"
chart
echo -e "\nActual summerized free Space: $actual_mem\n\n"
}


##########################################################################
# chart function
chart(){
	chart_arr[64]="|"
	for (( i = 0; i < 64; i++ )); do
		chart_arr[i]="\033[7m \033[0m"
	done
	# show used space
	for i in "${request_arr[@]}"; do
		(( start = i - 1 ))
		(( size_exp = ${mem_arr[$start]} + $min_exp ))
		# size = elements proportional to total_mem scale to 64 chars
		(( size = 1 << size_exp))
		(( size = size >> (max_exp - 6) ))
		(( start = start >> (max_exp - 6) ))

		chart_arr[$start]="|"
   		(( start+=1 ))

   		for (( j = 1; j < $size; j++ )); do
   			chart_arr[$start]="\033[7m#\033[0m"
   			(( start+=1 ))
   		done
   	done
   	for (( i = 0; i < $max_exp-$min_exp+1; i++ )); do
   		start_addr=${fb_arr[$i]}
   		while [[ $start_addr != -1 ]]; do
			(( sp = start_addr >> (max_exp - 6) ))
			chart_arr[$sp]="|"
	   		start_addr=${mem_arr[$start_addr]}
   		done
    done 

   	chart_arr[0]="["
   	chart_arr[64]="]"
   	for i in "${chart_arr[@]}"; do
   		printf "$i"
   	done
#   	unset size
}


##########################################################################
# initialize / Reset all Array Information
init_arrays(){
# delte variables/arrs
unset fb_arr
unset mem_arr
unset request_arr

actual_mem=$total_mem
for (( i = 0; i < max_exp-min_exp; i++ )); do
	# fb_arr= Free Buddy Meta Data Array
	# fill with invlaid value "-1"; invalid = not free
	fb_arr=("${fb_arr[@]}" -1)
done
	# set basepointer
	fb_arr=("${fb_arr[@]}" 0)
	# "Virtual Memory" as Array
	# set basepointer in Array(Free Address = Total mem) 
	mem_arr[0]=-1
if [[ $action == "r" ]]; then

message="Reset: Total Memory $total_mem Byte - Date $(date '+%Y-%m-%d %H:%M:%S')"
else
message="Init: Total Memory $total_mem Byte - Date $(date '+%Y-%m-%d %H:%M:%S')"
fi
}

##########################################################################
##########################################################################
# "MAIN FUNCTION" - Simulation

# Basic Initialzation 
# cause design, total mem should not > 8000000 (8MB)
if [[ -z $1 ]]; then
	total_mem=1024
else total_mem=$1 
fi

min_exp=6
# check next higher fitting dual power for total mem
(( total_mem = total_mem - 1 ))
max_exp=$(echo "l($total_mem)/l(2)" | bc -l)
(( max_exp=${max_exp%.*}+1 ))
(( total_mem = (1 << max_exp) ))

clear
init_arrays

while [[ true ]]; do
if [[ $action != "s" ]]; then
  view -l
 else view
fi

	echo -e "Do you want to allocate (\033[7ma\033[0m), free (\033[7mf\033[0m) or use a sample (\033[7ms\033[0m)"
	echo -e "Other Options: Exit (\033[7me\033[0m), return allocated List (\033[7ml\033[0m), reset actual status (\033[7mr\033[0m)"
	read action
	if [[ $action == "a" ]]; then
		echo "How much space should allocated?"
		read request
		allocate $request
	
	elif [[ $action == "f" ]]; then
		echo "Which Startaddress should be freed?"
		read request
		free $request
	
	elif [[ $action == "s" ]]; then
		echo "####################################"
		echo "############## Sample ##############"
		echo "####################################"
		allocate 230
		echo -e "==============================================================================\n"
		allocate 127
		echo -e "==============================================================================\n"
		allocate 128
		echo -e "==============================================================================\n"
		free 257
		echo -e "==============================================================================\n"
		free 513
		echo -e "==============================================================================\n"
		free 1
		echo -e "==============================================================================\n"
		read -p "Press enter to continue"
		init_arrays
	
	elif [[ $action == "l" ]]; then
		echo -e "_____________________________"
		echo -e "Size\t Startaddress"
		for i in "${request_arr[@]}"; do
		(( var = i - 1 ))
		(( var = ${mem_arr[$var]} + $min_exp ))
		(( var = 1 << var))
   		echo -e "$var\t| $i"
   		done
   		echo -e "_____________________________"
   		read -p "Press enter to continue"
   	
   	elif [[ $action == "r" ]]; then
   		message="Reset will be performed ..."
   		clear
   		view
   		sleep 2
   		init_arrays
   		main
   
   	elif [[ $action == "e" ]]; then
   		exit 0
	
	else
		message="No possible option choosen"
	fi
clear
done
##########################################################################