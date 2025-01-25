#!/usr/bin/env bash

#Cleans up running config output from 'show run | i interfaces'
#Dump log file (rename to .txt) into ./imports directory and run script to clean up file and prepare for extractor.
#You will want to modify the second pass and its target. Modify which column awk uses and the term to find 
#so the script can terminate the list of interfaces(lines 26/29)

if [ ! -d ./configs ]; then
    mkdir ./configs
fi

mapConfig() {
    mapfile -t -O 0 findList < ./find.txt ; rm -f ./find.txt
}

for file in ./import/*; do
    awk '{print $1}' "$file" > ./find.txt
    mapConfig
    for i in $(seq 0 ${#findList[@]} ); do
        if [ "${findList["$i"]}" = "interface" ]; then
            chopAmount=$i
            break
        fi
    done
    sed -i '' "1,${chopAmount}d" "${file}"
    awk '{print $2}' "$file" > ./find.txt
    mapConfig
    for i in $(seq 0 ${#findList[@]} ); do
        if [ "${findList["$i"]}" = "http" ]; then
            chopAmount=$((i + 1))
            break
        fi
    done
    sed -i '' "${chopAmount},${#findList[@]}d" "${file}"
    sed -i '' 's/interface/!\ninterface/g' "$file"
    echo "!" >> "$file"
    fileName="$file" ; fileName=$(basename "${fileName}")
    tr -d "\r" < "$file" > ./configs/"$fileName"
done
