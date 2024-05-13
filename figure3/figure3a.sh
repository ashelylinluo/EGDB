#!/bin/bash 


bedtools intersect -a ${peakdir}/data/DNase.peak -b ${peakdir}/data/H3K4me3.peak -wa -wb > ${dnasedir}/result/classification/activeDHS.bed

bedtools intersect -a ${peakdir}/data/DNase.peak -b $genebed -wa -wb > ${dnasedir}/result/classification/Dnase.genic.bed
bedtools intersect -a ${dnasedir}/result/classification/Dnase.genic.bed -b $promoterbed -v > ${dnasedir}/result/classification/Dnase.geniconly.bed
bedtools intersect -a ${peakdir}/data/DNase.peak -b $genebed -v > ${dnasedir}/result/classification/Dnase.intergenic.bed
bedtools intersect -a ${peakdir}/data/DNase.peak -b $promoterbed -wa -wb > ${dnasedir}/result/classification/Dnase.promoter.bed
bedtools intersect -a ${dnasedir}/result/classification/Dnase.promoter.bed -b $genebed -v > ${dnasedir}/result/classification/Dnase.promoteronly.bed
bedtools intersect -a ${dnasedir}/result/classification/Dnase.promoter.bed -b ${peakdir}/data/H3K4me3.peak -wa > ${dnasedir}/result/classification/Dnase.promoter.active.bed
bedtools intersect -a ${peakdir}/data/DNase.peak -b $genebed -v |bedtools intersect -a - -b $promoterbed -v > ${dnasedir}/result/classification/Dnase.intergeniconly.bed

bedtools intersect -a ${dnasedir}/result/classification/Dnase.intergeniconly.bed -b ${peakdir}/data/H3K27ac.peak -wa -wb > ${dnasedir}/result/classification/Dnase.enhancer.bed


rgt-hint footprinting --dnase-seq ../bam/DNase.sorted.bam data/DNase.bed --output-location ~/Project/Pmillet/result/dnase/result/hint_footprints --output-prefix pm --bias-correction --bias-type DH --organism pm

annotatePeaks.pl pm.bed Pmillet 1>pm.bed.annotation.xls 2>pm.bed.annotation.log

python ./homer2meme.py --output_file db.meme --max_pval 1e-1  db/*motif

