#!/bin/bash 


$JAVA -mx50G -jar $ChromHMM BinarizeBam -gzip -f 2 -b 200 ${genomesize} ${bamdir} ${hmmdir}/sample/hmm.sample.txt ${hmmdir}/result/Binarization

for i in {6..20};do
    $JAVA -mx50G -jar $ChromHMM LearnModel -gzip -d 0.001 -color 0,0,255 -b 200 -i pm ${hmmdir}/result/Binarization ${hmmdir}/result/learnmodel_${i} $i pm
done

awk '{print $0"\t0\t.\t"$2"\t"$3"\t"$4}' pm_15_pm_segments.bed |sed "s/E15$/192,192,192/g"|sed "s/E14$/142,199,142/g"|sed "s/E13$/128,128,128/g"|sed "s/E12$/73,159,73/g"|sed "s/E11$/0,100,0/g"|sed "s/E10$/214,135,0/g"|sed "s/E9$/71,45,0/g"|sed "s/E8$/139,0,0/g"| sed "s/E7$/192,86,64/g"|sed "s/E6$/140,135,2/g"|sed "s/E5$/210,203,3/g"|sed "s/E4$/193,64,61/g"|sed "s/E3$/86,56,56/g" |sed "s/E2$/142,90,0/g"|sed "s/E1$/70,67,1/g"> pm_15_pm_segments.bed9

