#!/bin/sh

old=$1
new=$2
[ -d stats_work ] || mkdir stats_work

types="IGN OK OK2 WOK1 WOK2 WOK3 PBS WDIFF"

for i in $types
do
        sort $old/LISTE.$i > stats_work/old_$i
        sort $new/LISTE.$i > stats_work/new_$i
done

for i in $types
do
        for j in $types
        do
                cat stats_work/old_$i stats_work/new_$j | sort | uniq -d > stats_work/"$i"_"$j"
        done
done

echo -n "     "
for i in $types
do
        printf "% 6s" $i
done
echo
for i in $types
do
        printf "% 5s" $i
        for j in $types
        do
                printf "% 6d" $(wc -l stats_work/"$i"_"$j"|cut -d" " -f1)
        done
        echo
done
echo -n "total: " $(for i in $types; do cat stats_work/old_$i; done | wc -l)
echo    " |"      $(for i in $types; do cat stats_work/new_$i; done | wc -l)
