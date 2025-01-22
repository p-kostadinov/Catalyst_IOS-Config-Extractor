#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo ""
    echo "pass 'm' flag for mass import from ./configs/"
    echo "or pass input file as only argument"
    echo "Make sure file ends in '!'"
    echo ""
    exit 1
fi

makeDir() {
    if [ ! -d ./interfaces ]; then
        mkdir ./interfaces/
    fi
}

findObj() {
    matchVar=$(awk -v line="$readLineNumber" -v obj="$1" 'NR==line{print $obj}' "$sourceFile" )
}

readFile() {
    fileName="$1" ; fileName=$(basename "${fileName%.*}")
    grep -n '^!' "$1" | awk -F':' '{print $1}' > ./Array.txt ; mapfile -t chopArray < ./Array.txt ; rm -f ./Array.txt
    cutStart="0"
    echo "Creating interface array now"
    for i in $(seq 0 $((${#chopArray[@]} - 1 )) ); do
        cutEnd=${chopArray[$i]}
        awk -v startVar="$cutStart" -v endVar="$cutEnd" 'NR >= startVar && NR <= endVar' "$1" > ./interfaces/int_"${i}".txt
        cutStart=$(( cutEnd + 1 ))
    done
    echo "Interface array for switch $fileName complete"
    echo "Creating interface csv now"
    echo "interface,description,userVlan,voipVlan" >> ./"$fileName".csv
    for i in $(seq 0 $((${#chopArray[@]} - 1 )) ); do
        sourceFile="./interfaces/int_${i}.txt"
        readLineNumber="2"
        interface["$i"]=$(awk 'NR==1{print $2}' "$sourceFile" )
        findObj "1"
        if [ "$matchVar" = "description" ]; then
            description["$i"]=$(awk 'NR==2{$1=""; print $0}' "$sourceFile" )
        else
            description["$i"]=""
        fi
        while true ; do
            if [ "$readLineNumber" = 5 ]; then
                break
            fi
            findObj "3"
            if [ "$matchVar" = "vlan" ]; then
                userVlan["$i"]=$(awk 'NR==3{print $4}' "$sourceFile" )
                readLineNumber=$(( readLineNumber + 2 ))
                break
            elif [ "$matchVar" = "allowed" ]; then
                userVlan["$i"]="'$(awk 'NR==3{print $5}' "$sourceFile" )'"
                readLineNumber=$(( readLineNumber - 1 ))
                break
            else
                readLineNumber=$(( readLineNumber + 1 ))
            fi
        done
        findObj "3"
        if [ "$matchVar" = "vlan" ]; then
            voipVlan["$i"]=$(awk 'NR==5{print $4}' "$sourceFile" )
#        elif [ "$matchVar" = "native" ]; then
#           voipVlan["$i"]=$(awk 'NR==5{print $5}' "$sourceFile" )
        else
            voipVlan["$i"]=""
        fi
        echo "${interface[$i]},${description[$i]},${userVlan[$i]},${voipVlan[$i]}" >> ./"$fileName".csv
        rm "$sourceFile"
    done
    echo "Interface csv for switch $fileName complete"
}

if [ "$1" = "m" ]; then
    if [ ! -d ./configs ]; then
        echo "no configs directory"
        exit 1
    fi
    makeDir
    for i in ./configs/*; do
        readFile "$i"
    done
else
    makeDir
    readFile "$1"
fi

rm -fr ./interfaces/
