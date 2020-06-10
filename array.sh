#!/bin/bash

  #block_arr=(1024 512 256 128 64 32)
  #echo "${block_arr[2]}"

  size=1024
  arr=(1)
  echo -e "Memory Size = ${size} kB\n\nFree Blocks with 1"
  #fil array list
  while [[ ${size} -gt 4 ]]; do
  	size=$(( ${size}/2 ))
  	arr=(0 "${arr[@]}")
  done


  for i in "${arr[@]}"
  do
    echo $i
   done 

  echo -e "___________________\n\n"


#check for block 2^n

	search=1024

	while [[ $search/2 -ge 4 ]]; do
		search=$(( $search/2 ))
		(( temp++ ))
		
	done

	echo "Potenz: $(( $temp+2 ))"
	echo "Frei: ${arr[${temp}]}"

	#read -sdr -p "Whats your name?\n"

  #test_arr["markus"]="jena"
  #test_arr["bene"]="ffm"

  test_arr=( ["markus"]="jena" ["bene"]="ffm")

  for i in "${test_arr[@]}"
  do
    echo $i
   done 

   echo "${test_arr["markus"]}"
