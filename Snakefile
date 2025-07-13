rule convert_chain:
    input:
        "data_{species1}_{species2}/chain.gz"
    output:
        "data_{species1}_{species2}/{species1}_block.bed",
        "data_{species1}_{species2}/{species2}_block.bed"
    shadow: "shallow"
    shell:
        "python3 scripts/convertToBed.py {input} {output} trashed"

rule get_chain_size:
    input:
        "data_{species1}_{species2}/chain.gz"
    output:
        "data_{species1}_{species2}/{species1}_full_chain.bed",
        "data_{species1}_{species2}/{species2}_full_chain.bed",
        "data_{species1}_{species2}/{species1}.{species2}.gaps_chains.csv"
    shell:
        "python3 scripts/getFullChainSize.py {input} {output}"

rule convert_exemple:
    input:
        "data_{species1}_{species2}/{species}_full_chain.bed"
    output:
        "data_{species1}_{species2}/{species}_full_chain.aoe"
    shell:
        """
        Rscript scripts/bedToAOE.R {input} {output}
        """

rule count_niebs:
    input:
        chains = "data_{species1}_{species2}/{species}_full_chain.aoe",
        niebs = "data_{species1}_{species2}/niebs_{species}.bed",
    output:
        counts = "data_{species1}_{species2}/count_niebs_along_chains_{species}.tsv"
    shell:
        "scripts/countFeatures.bin +a {input.chains} +b {input.niebs} +o {output.counts} +d +k source +p mid"

rule get_gc_chain:
    input:
        fasta = "data_{species1}_{species2}/{species}.fa",
        chain = "data_{species1}_{species2}/{species}_full_chain.bed"
    output:
        "data_{species1}_{species2}/{species}_gc_chain.tsv"
    shadow: "shallow"
    shell:
        """
        bedtools getfasta -fi {input.fasta} -bed {input.chain} -fo tmp.fa -name
        python3 scripts/get_gc_by_bed_id.py tmp.fa {output}
        """

rule getTotalBlock:
    input:
        "data_{species1}_{species2}/{species1}_block.bed"
    output:
        "data_{species1}_{species2}/total_block_size.tsv"
    shell:
        "python3 scripts/agg_block_chain.py {input} {output}"

rule intersect:
    input:
        "data_{species1}_{species2}/{species}_full_chain.bed",
        "data_{species1}_{species2}/niebs_{species}.bed"
    output:
        "data_{species1}_{species2}/{species}_chains_niebs_intersect.bed"
    shell:
        "bedtools intersect -a {input[0]} -b {input[1]} > {output}"

rule plot_density:
    input:
        "data_{species1}_{species2}/{species1}_chains_niebs_intersect.bed",
        "data_{species1}_{species2}/{species2}_chains_niebs_intersect.bed",
        "data_{species1}_{species2}/{species1}_full_chain.bed",
        "data_{species1}_{species2}/{species2}_full_chain.bed"
    output:
        "data_{species1}_{species2}/density_plot.svg"
    params:
        xlab = "\"*{species1}* coverage\"",
        ylab = "\"*{species2}* coverage\""
    shell:
        "Rscript scripts/plot_density.R {input} {output} {params}"

rule plot_signal:
    input:
        "data_{species1}_{species2}/count_niebs_along_chains_{species1}.tsv",
        "data_{species1}_{species2}/count_niebs_along_chains_{species2}.tsv"
    output:
        "data_{species1}_{species2}/plot_signal_{min}_{max}.svg"
    params:
        "{min}",
        "{max}",
        "\"{species1}\"",
        "\"{species2}\""
    shell:
        "Rscript scripts/plot_signal.R {input} {output} {params}"

# bedtools intersect -a hg38_full_chain.bed -b niebs.bed > niebs_hg38_full_chain_intersect.bed
# bedtools intersect -a panTro5_full_chain.bed -b NIEBs_pan.sorted.bed > niebs_panTro5_full_chain_intersect.bed
# python3 ../scripts/agg_block_chain.py hg38_block.bed total_size_hg38.tsv
# Rscript ../../scripts/fixIdentifiers.R mm39_full_chain.bed ../../features/seq_report_mus.tsv mm39_full_chain_fixed.bed 6 12
# bedtools getfasta -fi ../../palanchrom/data/panTro5.fa -bed panTro5_full_chain.bed -fo panTro5_full_chain.fa -name
# python3 ../scripts/get_gc_by_bed_id.py hg38_full_chain.fa gc_chains_hg38.tsv
# python3 ../scripts/get_gc_by_bed_id.py panTro5_full_chain.fa gc_chains_panTro5.tsv