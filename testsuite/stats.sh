#!/bin/sh

# see the 'check' script for the meaning of the categories.
# You can tune the order of the categories to have all improvement in the
# upper right or lower left corner of the table.
types="IGN OK OK2 WOK1 WOK2 WOK3 PBS WDIFF"

if [ "$#" != "2" ] ; then
    echo "\
Compare two executions of the 'check' script, and display the results in a
table.

Usage: $0 <directory1> <directory2>
Were both directories contain the results (LISTE.* files) of two 'check'
executions.

The categories are configurable at the beginning of $0.

$0 creates, in the stats_work directory, files named cat1_cat2, which
indicate which man pages changed from the cat1 category to the cat2 one.
"
    exit 0
fi

old=$1
new=$2
[ -d stats_work ] || mkdir stats_work

# copy the LISTE.* files in stats_work
for i in $types
do
        sort $old/LISTE.$i > stats_work/old_$i
        sort $new/LISTE.$i > stats_work/new_$i
done

# create the cat1_cat2 files which contain the common lines of two
# categories.
for i in $types
do
        for j in $types
        do
                cat stats_work/old_$i stats_work/new_$j | sort | uniq -d > stats_work/"$i"_"$j"
        done
done

# display the report
echo "dir1:$old"
echo "dir2:$new"
echo
echo -n "dir1\\dir2"
for i in $types
do
        printf "% 6s" $i
done
echo
for i in $types
do
        printf "% 9s" $i
        for j in $types
        do
                printf "% 6d" $(wc -l stats_work/"$i"_"$j"|cut -d" " -f1)
        done
        echo
done
echo -n "total: " $(for i in $types; do cat stats_work/old_$i; done | wc -l)
echo    " |"      $(for i in $types; do cat stats_work/new_$i; done | wc -l)
