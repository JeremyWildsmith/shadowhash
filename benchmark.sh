#!/bin/bash

FULL_PATH_TO_SCRIPT="$(realpath "${BASH_SOURCE[-1]}")"
SCRIPT_DIRECTORY="$(dirname "$FULL_PATH_TO_SCRIPT")"

mkdir -p $SCRIPT_DIRECTORY/benchmark

rm $SCRIPT_DIRECTORY/benchmark/*.dat
rm $SCRIPT_DIRECTORY/benchmark/*.png

thread_count="1,2,3,4"

algos="yescrypt,gost-yescrypt,scrypt,bcrypt,bcrypt-a,sha512crypt,sha256crypt,sunmd5,md5crypt,descrypt,nt"
IFS=',' read -r -a algo_array <<< "$algos"
IFS=',' read -r -a thread_array <<< "$thread_count"

for algo in "${algo_array[@]}"; do
    for t in "${thread_array[@]}"; do
        echo "Benchmarking Thread Performance for: $algo and $t threads"
        a=$(mix shadow_hash --password $(mkpasswd -m $algo tp) --workers $t | sed -nE 's/.*Password cracked for command_line_entry in ([0-9\.]+) seconds.*/\1/p')
        echo $t $a >> $SCRIPT_DIRECTORY/benchmark/$algo.dat
    done
done

(cd $SCRIPT_DIRECTORY/benchmark && gnuplot plot.gp)
cp $SCRIPT_DIRECTORY/benchmark/output.png benchmark_graph.png