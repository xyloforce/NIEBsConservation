# python3 ../scripts/getFullChainSize.py hg38ToPanTro5.over.chain.gz hg38.panTro5.full_size_chains.bed panTro5.hg38.full_size_chains.bed hg38.panTro5.gaps_chains.csv
import sys
import gzip

full_chain = open(sys.argv[2], 'w')
full_chain2 = open(sys.argv[3], 'w')
gap_sizes = open(sys.argv[4], 'w')
chainid = ""

for line in gzip.open(sys.argv[1], "rt"):
    chain = False
    total_size = 0
    last = False
    root_name = ""
    if not line.startswith("#") and not line.startswith("\n"):
        if line.startswith("chain"):
            line = line.strip().split(" ")
            chainid = line[-1]
            chr = line[2]
            start = line[5]
            end = line[6]
            strand = line[4]
            full_chain.write(chr + "\t" + start + "\t" + end + "\t" + chainid + "\t1000\t" + strand + "\n")
            chr2 = line[7]
            start2 = line[10]
            end2 = line[11]
            strand2 = line[9]
            if strand2 == "-": # negative chains are defined starting from the end !!!!
                max_size = int(line[8])
                start2 = str(max_size - int(start2))
                end2 = str(max_size - int(end2))
                tmp = end2
                end2 = start2
                start2 = tmp
            
            full_chain2.write(chr2 + "\t" + start2 + "\t" + end2 + "\t" + chainid + "\t1000\t" + strand2 + "\n")

        else:
            line = line.strip().split("\t")
            if(len(line) > 1): # skip last line that has only ungapped alignement size for last block
                total_size += int(line[0])
                if chainid != "":
                    gap_sizes.write(chainid + ",ref," + line[1] + "\n")
                    gap_sizes.write(chainid + ",query," + line[2] + "\n")
                else:
                    raise Exception("Gap in a undefined chain")