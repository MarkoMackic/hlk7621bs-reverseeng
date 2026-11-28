#!/usr/bin/python

import sys
import os
import itertools

assert len(sys.argv) > 3, "must be output dir + 2 inputs at least"

output=sys.argv[1] if sys.argv[1][-1] == '/' else f"{sys.argv[1]}/"
files=sys.argv[2:]

assert os.path.isdir(output), "output must be a dir"

assert all([os.path.exists(f) for f in files]), "all files must exist" 

def get_name_from_path(p):
    return os.path.basename(p).split("-")[0]

for (first,second) in itertools.combinations(files,2):
    os.system(f"bash -c \"diff <(cat {first} | base64 --decode | xxd) <(cat {second} | base64 --decode | xxd) > {output}{get_name_from_path(first)}_{get_name_from_path(second)}.diff\"")

#print(output)
#print(len(list(itertools.combinations(files,2))))
