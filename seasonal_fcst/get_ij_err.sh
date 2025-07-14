#!/bin/sh 
# 
# Get I, J indices where negative ice thickness occured from err log file
#
set -u

WD=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/work/NEP_irlx_test

cd "$WD" || exit 1
pwd

fij=ijerr.txt
touch $fij
/bin/rm $fij

# Extract I and J --> temp files
grep 'Negative ice thickness at' err | awk '{print $9}' > i_vals.txt
grep 'Negative ice thickness at' err | awk '{print $10}' > j_vals.txt

# Write I values with commas
echo "I:" > "$fij"
n=$(wc -l < i_vals.txt)
echo "$n error points, ---> $fij"
i=1
while read -r val; do
  if [ "$i" -lt "$n" ]; then
    echo "${val}," >> "$fij"
  else
    echo "$val" >> "$fij"
  fi
  i=$((i + 1))
done < i_vals.txt

# Write J values with commas
echo "J:" >> "$fij"
n=$(wc -l < j_vals.txt)
i=1
while read -r val; do
  if [ "$i" -lt "$n" ]; then
    echo "${val}," >> "$fij"
  else
    echo "$val" >> "$fij"
  fi
  i=$((i + 1))
done < j_vals.txt

# Clean up
rm -f i_vals.txt j_vals.txt


exit 0

