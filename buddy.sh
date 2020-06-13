#!/bin/bash

# output with logging option
view(){

echo -e "Info |  \c" 
# check if logging optin is enabled
if [[ $1 == "-l" ]]; then
	echo -e "$message" | tee -a log
else 
	echo -e "$message"
fi
	#printf "\n"
	echo -e "_____________________________"

	printf "Size\t| Free Startaddresses (-1 = no free Block)\n"
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
echo -e "\n\n"
}

chart(){
	chart_arr[0]="["
	chart_arr[100]="]"
	for (( i = 1; i < 100; i++ )); do
		chart_arr[i]=" "
	done
	# show used space
	for i in "${request_arr[@]}"; do
		(( var = i - 1 ))
		(( var = ${mem_arr[$var]} + $min_exp ))
		# size = elements proportional to total_mem
		(( size = 1 << var))
		size=$(echo "100/$total_mem*$size" | bc -l)
		(( size = ${size%.*} ))
		# var = startpoint in Chart
		var=$(echo "$i/$total_mem*100" | bc -l)
		(( var = ${var%.*}+1 ))

   		for (( j = 1; j < $size; j++ )); do
   			#echo "i=$i  j=$j  var=$var   size:$size"
   			chart_arr[$var]="#"
   			(( var+=1 ))
   		done
   	done

   	for (( i = 0; i < $max_exp-$min_exp+1; i++ )); do

   		var=${fb_arr[i]}
   		if [[ $var -gt 0 ]]; then
   		var=$(echo "$var/$total_mem*100" | bc -l)
		(( var = ${var%.*}+1 ))

			if [[ $var -gt 0 ]]; then
			chart_arr[$var]="I"
			fi
   		fi

    done 

   	for i in "${chart_arr[@]}"; do
   		printf "$i"
   	done
   	unset size
}


#allocation function
allocate(){

size=$1
size_exp=$(echo "l($size)/l(2)" | bc -l)
(( size_exp = ${size_exp%.*}+1 ))

message="Try to allocate $size Byte"
# check request details
if [[ $size == 0 ]]; then
	message+=" --> Error: Request must be > 0"
	return
fi
if [[ $size_exp -lt $min_exp ]]; then
	size_exp=$min_exp
fi
if [[ $max_exp -lt $size_exp ]]; then
	message+=" --> Error: Request is overlarge"
	return
fi
# define exponent in arr
(( index = $size_exp - $min_exp ))
split_index=0
# check if buddy in requested size exist
for (( i = ${index}; i <= ${max_exp}-${min_exp}; ++i )); do
	if [[ ${fb_arr[$i]} != -1 ]]; then
		split_index=$i
		break
	fi
	# check if enough space left, if size_exp = min_exp
	if [[ $i == $(( max_exp - min_exp )) && ${fb_arr[$i]} == -1 ]]; then
		message+=" --> Error: Not enough Space available"
		return
	fi
done
# check if enough space left to perform request (> min_exp)
if [[ $split_index != $index && ${split_index} == 0 ]]; then
	message+=" --> Error: Not enough Space available"
	return
fi
# speichern des pointers auf ersten value und verschieben des möglicherweise vorherigen ersten wertes in memory adresse 
# safe pointer at first value, move evtl. previous first value into memory address
result=${fb_arr[${split_index}]}
fb_arr[${split_index}]=${mem_arr[$result]}

# next lower exponent -> split
for (( i = ${split_index}-1; $i >= $index; --i )); do
	fb_arr[${i}]=$(( ${result} + $(( 1 << $(( ${min_exp} + ${i} )) )) ))
	mem_arr[${fb_arr[i]}]=-1
done
# safe Bucketsize in Header (1 Byte) = Startaddress Buddy 
mem_arr[$result]=$index
# Bucket Startaddress, real stored request
(( result+=1 ))
# safe result in request_arr and set return message
request_arr=("${request_arr[@]}" $result)
(( size_real = 1 << size_exp))
message="Startaddress: $result | Requested size: $size | Used size: $size_real"
if [[ $action == "s" ]]; then view; fi
}


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

free(){

# $1=Start_Adress after Header
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

	# element which iterates over "linked List"
	iterator=${fb_arr[$index]}
	# adresse zu evtl. zu mergenden buddys
	merge_buddy=-1
	# element um eins zurückgesetzt falls rechter Buddy deallocated und linker frei
	# used for removing element at "linked List", auxciliary variable
	prev=-1
	# check all elements in "Linked List" 
	while [[ $iterator != -1 ]]; do
#		echo "addr=$addr    iterator=$iterator    curr_xp=$curr_exp"
#		is_buddy $addr $iterator $curr_exp
		if [[ $(is_buddy $addr $iterator $curr_exp) == 1 ]]; then
			merge_buddy=$iterator
			break
		fi
		prev=$iterator
		iterator=${mem_arr[$iterator]}
	done

	# if no merge buddy is available
	if [[ $merge_buddy == -1 ]]; then
		#verschieben vom free pointer auf neuen größeren Buddy, index der startadress in metadaten
		mem_arr[$addr]=${fb_arr[$index]}
		#new free start index in metadata
		fb_arr[$index]=$addr
		break
	fi
	# if size addr = shift size curr_exp -> addr=0 else addr=addr
	# if freed buddy is on the right side, 
	(( addr &= (~(1 << curr_exp)) ))
#	echo $addr
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

# Basic Initialzation 
# cause design, total mem should not > 8000000 (8MB)
total_mem=1000
min_exp=6
# calculate next higher power of two 
(( total_mem = total_mem - 1 ))
max_exp=$(echo "l($total_mem)/l(2)" | bc -l)
(( max_exp=${max_exp%.*}+1 ))
(( total_mem = (1 << max_exp) ))

# initialize / Reset all Array Information
init_arrays(){

unset fb_arr
unset mem_arr
unset request_arr
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

message="Init: Total Memory $total_mem Byte - Date $(date '+%Y-%m-%d %H:%M:%S')"
#view -l
#clear
}

clear
init_arrays

#MAIN FUNCTION
while [[ true ]]; do
if [[ $action != "s" || $action != "r" ]]; then
  view -l
 else view
fi

	echo "Do you want to allocate (a), free (f) or use a sample (s)"
	echo "Other Options: Exit (e), return actul allocated List (l), reset (r) actual status"
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
   		view -l
   		sleep 2
   		init_arrays
   
   	elif [[ $action == "e" ]]; then
   		exit 0
	
	else
		message="No possible option choosen"
	fi
#clear
done