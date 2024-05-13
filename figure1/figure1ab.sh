#!/bin/bash 


if [ ! -f ./cor/plot/${SampleID}.done ];then
  bin/multiBamSummary bins --bamfiles ./bam/${rep1}.q20.unique.bam ./bam/${rep2}.q20.unique.bam --binSize 1000 -o ./cor/data/${SampleID}.results.npz
  bin/plotCorrelation -in ./cor/data/${SampleID}.results.npz --corMethod pearson --skipZeros --whatToPlot heatmap --colorMap RdYlBu --plotNumbers -o ./cor/plot/${SampleID}_PearsonCorr.png --outFileCorMatrix ./cor/plot/${SampleID}_PearsonCorr.tab
  touch ./cor/plot/${SampleID}.done
fi
if [ ! -f ./cov/${SampleID}.done ];then
  bin/sambamba merge -t 10 ./bam/${SampleID}.merged.bam ./bam/${rep1}.q20.unique.bam ./bam/${rep2}.q20.unique.bam
  bin/sambamba markdup -r -t 10 ./bam/${SampleID}.merged.bam ./bam/${SampleID}.bam
  samtools sort -@ 20 -o ./bam/${SampleID}.sorted.bam ./bam/${SampleID}.bam
  samtools index ./bam/${SampleID}.sorted.bam
  bin/bamCoverage --bam ./bam/${SampleID}.bam --outFileName ./cov/${SampleID}.10k.bw --binSize 10000
  bin/bamCoverage --bam ./bam/${SampleID}.bam --outFileName ./cov/${SampleID}.10CPM.bw --normalizeUsing CPM --numberOfProcessors 10
  bin/bedtools bamtobed -i ./bam/${SampleID}.bam >./bam/${SampleID}.bed
  touch ./cov/${SampleID}.done
fi

if [ ! -f ./cor/plot/all.done ];then
  bin/multiBigwigSummary bins -b ./cov/*1kCPM.bw -o ./cor/data/all.results.npz
  bin/plotCorrelation -in ./cor/data/all.results.npz --corMethod pearson --skipZeros --whatToPlot heatmap --colorMap RdYlBu --plotNumbers -o ./cor/plot/all_PearsonCorr.pdf
  touch ./cor/plot/all.done
fi


if [ ! -f ./peak/peak/${SampleID}.done ];then
  if [[ $SampleID == *"Dnase"* ]];then
    bin/macs2 callpeak -t ./bam/${SampleID}.bam -q 0.05 -f BAMPE -g 1.99e9 -n ${SampleID} --keep-dup all -B 2>./peak/log/${InputID}_${SampleID}_Npeak.log
    bin/macs2 callpeak -c ./bam/${InputID}.bam -t ./bam/${SampleID}.bam -q 0.05 -f BAMPE -g 1.99e9 -n ${InputID}_${SampleID} --keep-dup all --nomodel --shift -100 --extsize 200 --broad --broad-cutoff 0.2 -B 2>./peak/log/${InputID}_${SampleID}_Bpeak.log
  else
    bin/macs2 callpeak -c ./bam/${InputID}.bam -t ./bam/${SampleID}.bam -q 0.05 -f BAMPE -g 1.99e9 -n ${InputID}_${SampleID} --keep-dup all -B 2>./peak/log/${InputID}_${SampleID}_Npeak.log
    bin/macs2 callpeak -c ./bam/${InputID}.bam -t ./bam/${SampleID}.bam -q 0.05 -f BAMPE -g 1.99e9 -n ${InputID}_${SampleID} --nomodel --broad --broad-cutoff 0.1 -B 2>./peak/log/${InputID}_${SampleID}_Bpeak.log
  fi
  Rscript bin/peakannotation.R -d $genometxdb -s peak/data/${hm}.peak -o peak/result/annotation -p ${SampleID}
fi

