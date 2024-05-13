#!/bin/bash 

Rscript bin/plot_SV_and_gene_exp.R

printf "DELs with TE or gene\n"

bedtools intersect -a ./364.DELSV.bed -b ~/Database/Pmillet/sequence/LTR_Gypsy.final.bed -wa |sort -u|wc -l # 133
bedtools intersect -a ./364.DELSV.bed -b ~/Database/Pmillet/sequence/LTR_Copia.final.bed -wa |sort -u|wc -l # 83
bedtools intersect -a ./364.DELSV.bed -b ~/Database/Pmillet/Backup/PI537069.te2.bed -wa |sort -u|wc -l # 221
annotatePeaks.pl ./364.DELSV.bed Pmillet 1>result/delsv/364.anno 2>result/delsv/364.log

printf "DELs plot\n"
awk '{print $1"\t"$2-5000"\t"$3+5000}' result/combination/364.DELSV.bed > result/combination/364.DELSV.ext5k.bed
cat result/combination/364.DELSV.ext5k.bed |while read -r -a line;do
    pyGenomeTracks --tracks ../plot_cov/conf/allinfo.ini --region ${line[0]}:${line[1]}-${line[2]} -o result/plot/${line[0]}_${line[1]}_${line[2]}.png

done


printf "GWAS plot\n"
bedtools intersect -a $hmmout -b ${gwasdir}/input/DEL_GWAS.signal.allbed -wa -wb |sort -u > ${gwasdir}/result/gwas/DEL_GWAS.signal.with.hmm.bed
awk '{print $8"\t"$9"\t"$10-50000"\t"$11+50000"\t"$12}' ${gwasdir}/result/gwas/DEL_GWAS.signal.with.hmm.bed > ${gwasdir}/result/gwas/DEL_GWAS.signal.with.hmm.tmp
cat ${gwasdir}/result/gwas/DEL_GWAS.signal.with.hmm.tmp |while read -r -a line;do

    pyGenomeTracks --tracks  /wrk/jjxiao/Project/Pmillet/result/plot_cov/conf/allinfo.ini --region ${line[1]}:${line[2]}-${line[3]} -o plot/${line[0]}_${line[4]}_${line[1]}_${line[2]}.pdf
    # /wrk/jjxiao/Project/Pmillet/result/GWAS/result/gwas
done



