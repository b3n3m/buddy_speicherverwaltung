#!/bin/bash

view(){
for i in "${fb_arr[@]}"
	do
    	printf "%d\t" $i
    done 

  echo -e "\n_____________________________\n"
}

view_2(){
for i in "${fb_arr[@]}"
	do
    	printf "%d:\t" $i
    	value=$i
    	while [[ $value != -1 ]]; do
    		value=${mem_arr[$value]}
    		printf "%d\t" $value
    	done
    	printf "\n"
    	
    done 

  echo -e "\n_____________________________\n"
}

view_3(){
	#if [[ ! -z $result ]]; then
	#	echo -e "Startadress $result for requested size $size \n"
	#	unset result
	#fi

	echo -e "Info: $message \n" | tee -a log
	unset message

	printf "Size\t| Free Startadrresses (-1= Block is not free)\n"
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

echo -e "_____________________________\n\n"

}


#allocation function
allocate(){
size=$1

if [[ $size == 0 ]]; then
	message="Speicher darf nicht Null sein"
	return
fi

size_exp=$(echo "l($size)/l(2)" | bc -l)
(( size_exp=${size_exp%.*}+1 ))

if [[ $size_exp -lt $min_exp ]]; then
	size_exp=$min_exp
fi
#check if requested size is larger than adressable space
if [[ $max_exp -lt $size_exp ]]; then
	echo "max_exp: $max_exp   size_exp: $size_exp"
	message="Speicheranforderung zu groß."
	return
fi
#define exponent in arr
(( index = $size_exp - $min_exp ))
split_index=0
#ist buddy in der entsprechenden Größe vorhanden
for (( i = ${index}; i <= ${max_exp}-${min_exp}; ++i )); do
	if [[ ${fb_arr[i]} != -1 ]]; then
		split_index=$i
		break
	fi
done
#prüfen ob genug Speicher Verfügbar
if [[ ${split_index} == 0 ]]; then
	message="No Space left, request can not stored!"
	return
fi

# speichern des pointers auf ersten value und verschieben des möglicherweise vorherigen ersten wertes in memory adresse 
result=${fb_arr[${split_index}]}
fb_arr[${split_index}]=${mem_arr[$result]}

#nächst niedriger exponent, split
for (( i = ${split_index}-1; $i >= $index; --i )); do
#1+2⁹, shift nach links (bsp. 0011 -> 0110)
	fb_arr[${i}]=$(( ${result} + $(( 1 << $(( ${min_exp} + ${i} )) )) ))
	mem_arr[${fb_arr[i]}]=-1
done
#header größe des speicher + position tatsächlicher start buddy
mem_arr[$result]=$index
#return value with Header
(( result+=1 ))
#safe result
request_arr=("${request_arr[@]}" $result)
#result for view
(( size_real = 1 << size_exp))
message="Startaddress: $result | Requested size: $size | Used size: $size_real"

}


is_buddy(){

	local addr_1=$1
	local addr_2=$2
	local buddy_exp=$3
	#typeset -i buddy_exp addr_1 addr_2

#	shift to the left um auf korretes bit zu kommen welches unterschiedlich sein darf
	(( mask = (1 << buddy_exp) ))

	(( test_1 = mask | addr_1 ))
#	echo $test_1

	(( test_2 = mask | addr_2 ))
#	echo $test_2

	if [[ $test_1 == $test_2 ]]; then
		#echo "they are buddys"
		echo 1
	else
		#echo "FALSE"
		echo 0
	fi
	
}

free(){
#check if already allocated
echo -e "Try to free space from Adress: $1 on"
    allo_check=-1
	for i in "${request_arr[@]}"; do
    	if [[ $i == $1 ]]; then
    		allo_check=0
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
   		message="Falsche Startadresse, kein gespeicherter Bucket"
   		return
   	fi
#$1=Start_Adress nach Header
addr=$(( $1 - 1 ))
index=${mem_arr[$addr]}
(( curr_exp = index + min_exp ))

while [[ true ]]; do

	# Element which iterates over "linked List"
	iterator=${fb_arr[$index]}
	#adresse zu evtl. zu mergenden buddys
	merge_buddy=-1
	#element um eins zurückgesetzt falls rechter Buddy deallocated und linker frei
	#used for removing element at "linked List", auxciliary variable
	prev=-1
	while [[ $iterator != -1 ]]; do
		echo "addr: $addr Iterator: $iterator curr_exp: $curr_exp"

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
		#neuer free start index in metadaten
		fb_arr[$index]=$addr
		break
	fi

	(( addr &= (~(1 << curr_exp)) ))
	# if there is no/does not exist a previous element
	if [[ $prev == -1 ]]; then
		fb_arr[$index]=${mem_arr[$merge_buddy]}
	else
		mem_arr[$prev]=${mem_arr[$merge_buddy]}
	fi
	# Multimerge
	(( index+=1 ))
	(( curr_exp+=1 ))
	view_3

done

view_3
}
#Basic Initialzation 
#cause design total mem not > 8000000 (8MB)
total_mem=1000
min_exp=6
#calculate next higher power of two 
(( temp_mem = total_mem - 1 ))
max_exp=$(echo "l($temp_mem)/l(2)" | bc -l)
(( max_exp=${max_exp%.*}+1 ))
(( total_mem = (1 << max_exp) ))

#initialize / Reset Meta Free Buddy Meta Array
init_arrays(){
unset fb_arr
unset mem_arr
unset request_arr
for (( i = 0; i < max_exp-min_exp; i++ )); do
	#fb_arr= Free Buddy Meta Data Array
	#fill with invlaid value "-1"; invalid = not free
	fb_arr=("${fb_arr[@]}" -1)
done
	#set basepointer
	fb_arr=("${fb_arr[@]}" 0)
#	"Virtual Memory" as Array
	#set basepointer in Array(Free Address = Total mem) 
	mem_arr[0]=-1

}
clear
init_arrays
echo -e "Totaler Speicher: $total_mem Byte\n"

#MAIN FUNCTION
while [[ true ]]; do
view_3
	echo "Do you want to allocate (a), free (f), use a sample (s) or return (r) actual allocated List"
	echo "Other Options: Exit (e), return actul allocated List (l), reset (r) actual status"
	read action
	if [[ $action == "a" ]]; then
		echo "How much space should allocated?"
		read request
		allocate $request
	elif [[ $action == "f" ]]; then
		echo "Welche Startspeicheradresse soll freigegeben werden?"
		read request
		free $request

	elif [[ $action == "s" ]]; then
	clear
		allocate 230
		allocate 127
		allocate 128
		free 257
		free 500
		free 1
		read -p "Press enter to continue"
		init_arrays
	elif [[ $action == "l" ]]; then
		for i in "${request_arr[@]}"; do

   		echo $i
   		done 
   		read -p "Press enter to continue"
   	elif [[ $action == "r" ]]; then
   		init_arrays
   		echo "Reset will performed ..."
   		sleep 3
   	elif [[ $action == "e" ]]; then
   		exit 0
	else
		echo "No possible option choosen"
		read -p "Press enter to continue"
	fi

clear

done