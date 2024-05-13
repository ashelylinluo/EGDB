#!/bin/bash 


for hm in DNase H3K4me3 H3K9ac H3K14ac H3K27ac H3K27me3 H3K36me3 H3K4me1;do
    for TE in LTR_Copia  LTR_Gypsy LTR_other Helitron DNA_EnSpm DNA_Ginger DNA_hAT DNA_MuLE_MuDR DNA_PIF DNA_TcMar LINE;do
        DirExists ./${TE}
        echo "TE annotation with $TE  and $hm"
        bedtools intersect -a ${seqdir}/${TE}.bed -b ${datadir}/${hm}.peak -wao > ./${TE}/${TE}.${hm}.bed
        bedtools intersect -a ${seqdir}/${TE}.final.bed -b ${datadir}/${hm}.peak -wa |cut -f 1-3 |sort -u > ./${TE}/${TE}.${hm}.final.bed
        annotatePeaks.pl ./${TE}/${TE}.${hm}.final.bed Pmillet 1>./${TE}/${TE}.${hm}.annotation.xls 2>./${TE}/${TE}.${hm}.annotation.log
        wc -l ./${TE}/${TE}.${hm}.final.bed| awk -v T=$TE -v H=$hm '{print T"\t"H"\t"$1}' >> ./TE_annotation.xls
        awk -F "\t" -v S="." '{if($11!=S) print $0}' ./${TE}/${TE}.${hm}.bed|cut -f 1-3 |sort -u|wc -l |awk -v T=$TE -v H=$hm '{print T"\t"H"\t"$1}' >> ./TE_annotation.xls
    done
done

