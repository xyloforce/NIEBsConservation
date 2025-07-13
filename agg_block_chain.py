import sys
import re

output = open(sys.argv[2], 'w')

total_len = dict()
for line in open(sys.argv[1]):
    line = line.strip().split('\t')
    size = int(line[2]) - int(line[1])
    id = re.findall("(\\w+)-", line[3])[0]
    if id not in total_len:
        total_len[id] = size
    else:
        total_len[id] += size
    
for key in total_len:
    output.write(key + "\t" + str(total_len[key]) + "\n")