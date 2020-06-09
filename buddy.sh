#!/bin/bash

readonly total_mem=1024
readonly min_exp=6
readonly max_exp=10

view(){
for i in "${fb_arr[@]}"
	do
    	printf "%d\t" $i
    done 

  echo -e "\n_____________________________\n"
}

#allocation function
allocate(){

echo "$1"

if [[ $1 = help ]]; then
	echo "allocate alozierender_Speicher"
fi
#check if requested size is bigger or lower then min/max adressable space
if [[ ${max_exp} -lt $1 || $1 -lt ${min_exp} ]]; then
	echo "Speicheranforderung zu groß oder zu klein"
fi
#define exponent in arr
index=$(( $1 - ${min_exp} ))
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

result=${fb_arr[${split_index}]}
fb_arr[${split_index}]=-1

#nächst niedriger exponent, split
for (( i = ${split_index}-1; $i >= $index; --i )); do
#1+2⁹, shift nach links (bsp. 0011 -> 0110)
	fb_arr[${i}]=$(( ${result} + $(( 1 << $(( ${min_exp} + ${i} )) )) ))
done

view

}

free(){
#$1=Start_Adress; $2=size/expo
index=$(( $2 - ${min_exp} ))
while [[ true ]]; do
	#comparable value for buddys
	buddy_mask=$(( << $(($index+$min_exp)) ))

	for (( i = ${fb_arr[${index}]}; i < 10; i++ )); do
		echo "Hello Wprld"
	done


done


}

#MAIN FUNCTION
#initialize Meta Free Buddy Meta Array
for (( i = 0; i < max_exp-min_exp; ++i )); do
	#fb_arr= Free Buddy Meta Data Array
	#fill with invlaid value "-1"; invalid = not free
	fb_arr=("${fb_arr[@]}" -1)
done
	#set basepointer
	fb_arr=("${fb_arr[@]}" 0)

view

allocate 8
echo $result " -result"

allocate 7
echo $result " - result"

printf "%011d\n" $(echo "obase=2; 256" | bc )


#free 256 128


