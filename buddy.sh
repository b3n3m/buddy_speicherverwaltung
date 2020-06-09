#!/bin/bash

total_mem=1000000000
min_exp=6
(( temp_mem = total_mem - 1 ))
max_exp=$(echo "l($temp_mem)/l(2)" | bc -l)
(( max_exp=${max_exp%.*}+1 ))
(( total_mem = (1 << max_exp) ))
echo "Benutzter Speicher:" $total_mem

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


#allocation function
allocate(){
if [[ $1 = help ]]; then
	echo "allocate alozierender_Speicher"
fi

size=$1

if [[ $size = 0 ]]; then
	echo "Speicher darf nicht Null sein"
fi

size_exp=$(echo "l($size)/l(2)" | bc -l)
(( size_exp=${size_exp%.*}+1 ))

if [[ $size_exp < $min_exp ]]; then
	size_exp=$min_exp
fi
#check if requested size is larger than adressable space
if [[ ${max_exp} -lt $size_exp ]]; then
	echo "Speicheranforderung zu groß."
fi
#define exponent in arr
index=$(( $size_exp - ${min_exp} ))
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
	echo "No Space left"
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
(( result+=1 ))
echo $result " - result"
view_2

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
#$1=Start_Adress nach Header
addr=$(( $1 - 1 ))
index=${mem_arr[$addr]}
curr_exp=$index+$min_exp


while [[ true ]]; do
	# dings was über meine einfach verkettete liste iteriert
	iterator=${fb_arr[$index]}
	#adresse zu evtl. zu mergenden buddys
	merge_buddy=-1
	#element um eins zurückgesetzt falls rechter Buddy deallocated und linker frei
	#used for removing element bei einfach verketteten listen
	prev=-1
	while [[ $iterator != -1 ]]; do

		if [[ $(is_buddy $addr $iterator $curr_exp) == 1 ]]; then
			merge_buddy=$iterator
			break
		fi
		prev=$iterator
		iterator=${mem_arr[$iterator]}
	done
# 	wenn kein merge buddy gefunden
	if [[ $merge_buddy == -1 ]]; then
		#verschieben vom free pointer auf neuen größeren Buddy, index der startadress in metadaten
		mem_arr[$addr]=${fb_arr[$index]}
		#neuer free start index in metadaten
		fb_arr[$index]=$addr
		break
	fi

	(( addr &= (~(1 << curr_exp)) ))
	# wenn kein previous element existiert
	if [[ $prev == -1 ]]; then
		fb_arr[$index]=${mem_arr[$merge_buddy]}
	else
		mem_arr[$prev]=${mem_arr[$merge_buddy]}
	fi

	# für mehrfachmerge
	(( index+=1 ))

done

view_2
}

#MAIN FUNCTION
#initialize Meta Free Buddy Meta Array
for (( i = 0; i < max_exp-min_exp; i++ )); do
	#fb_arr= Free Buddy Meta Data Array
	#fill with invlaid value "-1"; invalid = not free
	fb_arr=("${fb_arr[@]}" -1)
done
	#set basepointer
	fb_arr=("${fb_arr[@]}" 0)
#	"Virtual Memory" as Array
	#set basepointer in 
	mem_arr[0]=-1


view_2

allocate 230

allocate 127

allocate 128

free 257