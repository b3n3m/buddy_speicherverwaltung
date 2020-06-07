#!/bin/bash
total_mem=1024
largest_mem=$total_mem
temp_mem=$total_mem

counter=0

while [ $counter -lt 1 ]; do

    #request=$(($RANDOM % ${total_mem}))
    request=$1
    echo "$request - request_$counter"

    if [[ $request -gt $total_mem ]]; then
      echo "Fehler, kein Speicher Verfügbar"
      exit 1
    fi

#create Table unsed blocks
  block_arr=(1024 512 256 128 64 32)
  echo "${block_arr[2]}"
  for i in "${block_arr[@]}"
  do
    echo $i
   done 


#Check for next higher power
    power=2
    while [[ $request -ge $power ]]; do

    power=$(( $power*2 ))
    done
    echo "Nächst höhere 2er Potenz ist $power"

#Search for current splitted blocks


#Split and Check needed Blocksize if not existing    
    while [[ $temp_mem/2 -ge $request ]]; do
      temp_mem=$(( $temp_mem/2 ))
    done

    echo  "größt möglicher speichblock nach zuweisung $largest_mem"


    echo "$request wurden in einen Block $temp_mem abgelegt"

    (( counter++ ))

done
