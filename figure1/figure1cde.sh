#!/bin/bash 



for hm in DNase H3K14ac H3K27ac H3K27me3 H3K36me3 H3K4me1 H3K4me3 H3K9ac;do
    printf "process with $hm\n"
    if [ ! -f ./data/${hm}.sorted.bam.bai ];then
        samtools sort -o ./data/${hm}.sorted.bam ./${hm}.bam
        samtools index ./data/${hm}.sorted.bam
    fi
    bedtools coverage -sorted -a $chrgeneextendedbed -b ${genehmdir}/data/${hm}.sorted.bam > ${genehmdir}/result/geneextendedbed/${hm}.count

done


Rscript bin/merge_genehmcount_and_norm.R 

Rscript bin/kmeans_analysis.R
