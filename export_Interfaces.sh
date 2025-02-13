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
    if [ ! -d "$1" ]; then
        mkdir "$1"
    fi
}

createDirs() {
    makeDir "./interfaces"
    makeDir "./interfacesCSV"
    makeDir "./interfacesCSV_c"
}

findObj() {
    matchVar=$(awk -v line="$readLineNumber" -v obj="$1" 'NR==line{print $obj}' "$sourceFile" )
}

makeCSV() {
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
    echo "interface,description,userVlan,voipVlan" >> ./interfacesCSV/"$fileName".csv
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
        echo "${interface[$i]},${description[$i]},${userVlan[$i]},${voipVlan[$i]}" >> ./interfacesCSV/"$fileName".csv
        rm "$sourceFile"
    done
    echo "Interface csv for switch $fileName complete"
}

cleanCSV() {
    echo "interface,description,userVlan,voipVlan" >> ./interfacesCSV_c/"$fileName".csv
    for i in $(seq 1 ${#userVlan[@]} ); do
        if [ -n "${userVlan[$i]}" ]; then
            echo "${interface[$i]},${description[$i]},${userVlan[$i]},${voipVlan[$i]}" >> ./interfacesCSV_c/"$fileName".csv
        fi
    done
    echo "Cleaned up interface csv for switch $fileName complete"
}

if [ "$1" = "m" ]; then
    if [ ! -d ./configs ]; then
        echo "no configs directory"
        exit 1
    fi
    createDirs
    for i in ./configs/*; do
        makeCSV "$i"
        cleanCSV
    done
else
    createDirs
    makeCSV "$1"
    cleanCSV
fi

rm -fr ./interfaces/
