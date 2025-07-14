#!/bin/bash
grep '== Check: Global' check_sponge.txt | cut -d'd' -f2 | cut -d'=' -f2 > test_sponge.txt

exit 0
