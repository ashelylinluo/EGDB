#!/bin/bash 


printf "Step1:Process $SampleID with QC\n"
if [ ! -f ./qc/${SampleID}.qc.done ];then
    bin/fastp -i datadir/${SampleID}.R1.fq.gz -I datadir/${SampleID}.R2.fq.gz -o ./qc/${SampleID}_1.fq.gz -O ./qc/${SampleID}_2.fq.gz -W 5 -M 20 -5 -3 -l 50 -w ${Threads} -j ./qc/${SampleID}.json -h ./qc/${SampleID}.html > ./log/${SampleID}.qc.log 2>&1 && touch ./qc/${SampleID}.qc.done
fi

printf "${lineep}\nStep2:Align reads to reference genome withth $SampleID at `date`\n"
if [ ! -f ./bam/${SampleID}.bam.done ];then
    bin/bowtie2 -p $Threads --local -x ${genomeB2index} -1 ./qc/${SampleID}_1.fq.gz -2 ./qc/${SampleID}_2.fq.gz | bin/samtools sort -o ./bam/${SampleID}.bam
    bin/sambamba flagstat ./bam/${SampleID}.bam > ./bam/${SampleID}.flag
    bin/samtools view -f 2 -q 20 -O BAM -o ./bam/${SampleID}.q20.bam ./bam/${SampleID}.bam
    bin/sambamba markdup -r  ./bam/${SampleID}.q20.bam ./bam/${SampleID}.q20.dedup.bam
    bin/samtools index ./bam/${SampleID}.q20.dedup.bam
    rm -rf ./bam/${SampleID}.bam
    python3 bin/subsetBam.py --bam ./bam/${SampleID}.q20.dedup.bam --outbam ./bam/${SampleID}.q20.unique.bam --mulbam ./bam/${SampleID}.q20.m.bam
    bin/samtools index ./bam/${SampleID}.q20.unique.bam
    bin/bedtools bamtobed -i ./bam/${SampleID}.q20.unique.bam > ./bam/${SampleID}.q20.unique.bed
    touch ./bam/${SampleID}.bam.done
fi
printf "${lineep}\nStep3:plot1\n"
if [ ! -f ./bam/${SampleID}.stats.done ];then
    printf "stats\n"
    rawreads=`less ./qc/${SampleID}.json |grep -i total_reads|head -n 1|cut -f 2 -d ":"|sed "s/,//g"`
    qcreads=`less ./qc/${SampleID}.json |grep -i total_reads|sed -n 2p|cut -f 2 -d ":"|sed "s/,//g"`
    alignedreads=`head -n 1 ./bam/${SampleID}.flag |sed "s/ .*//g"`
    preads=`less ./bam/${SampleID}.flag |grep -i properly |sed "s/ .*//g"`
    NoPCRreads=`bin/samtools flagstat ./bam/${SampleID}.q20.dedup.bam |head -n1 |cut -f 1 -d " "`
    unireads=`bin/samtools flagstat ./bam/${SampleID}.q20.unique.bam|head -n1 |cut -f 1 -d " "`
    echo "$rawreads $alignedreads $preads $NoPCRreads $unireads"  > ./bam/${SampleID}.stats
    Rscript bin/Plot_basic_stats.R -d ./bam/${SampleID}.stats -o ./plot/stats -p ${SampleID}_basic_stats.pdf
    bin/samtools view ./bam/${SampleID}.q20.unique.bam |awk '{print $9}' > ./bam/${SampleID}.q20.unique.len
    touch ./bam/${SampleID}.stats.done
fi

##########
printf "${lineep}\nStep4: BAM2BW\n"
if [ ! -f ./cov/${SampleID}.done ];then
    bin/bamCoverage --bam ./bam/${SampleID}.q20.unique.bam --outFileName ./cov/${SampleID}.10kCPM.bw --binSize 10000 --normalizeUsing CPM --numberOfProcessors ${Threads}
    bin/bamCoverage --bam ./bam/${SampleID}.q20.unique.bam --outFileName ./cov/${SampleID}.10CPM.bw --binSize 10 --normalizeUsing CPM --numberOfProcessors ${Threads}
    bin/bamCoverage --bam ./bam/${SampleID}.q20.unique.bam --outFileName ./cov/${SampleID}.1kCPM.bw --binSize 1000 --normalizeUsing CPM --numberOfProcessors ${Threads}
    bin/bedtools coverage -a ${genome100K} -b ./bam/${SampleID}.q20.unique.bam > ./cov/${SampleID}.100k.bed
    cd ./scc
    Rscript bin/run_spp.R -c=./bam/${SampleID}.q20.unique.bam -rf -p=10 -savp=${SampleID}.scc.plot.pdf -out=${SampleID}.scc.score.txt > ${SampleID}_phantomQC.log 2>&1
    touch ./cov/${SampleID}.done
fi

cd .
printf "${lineep}\nStep5: Generate Coverage for TSS\n"
if [ ! -f ./plot/${SampleID}.done ];then
# # ${Rscript} ${Adddir}/coverage_around_TSS.R -b ${Align}/${SampleID}.rawsort.q20.dedup.bam -g ${gff} -o ./${Prefix}/Plot/TSS -p ${SampleID}_TSS.pdf
    bin/computeMatrix reference-point -p 10 --referencePoint TSS -b 3000 -a 3000 -R $TSSbed -S ./cov/${SampleID}.10CPM.bw  --skipZeros -out ./plot/tss/${SampleID}.TSS.gz --outFileSortedRegions ./plot/tss/${SampleID}.TSS.tab
    bin/plotProfile -m ./plot/tss/${SampleID}.TSS.gz -out ./plot/tss/${SampleID}.TSS.pdf
    bin/computeMatrix scale-regions -p 10 -R ${genebed} -S ./cov/${SampleID}.10CPM.bw --beforeRegionStartLength 3000 --regionBodyLength 5000 --afterRegionStartLength 3000 --skipZeros -o ./plot/tss/${SampleID}.gene.mat.gz
    bin/plotProfile -m ./plot/tss/${SampleID}.gene.mat.gz -out ./plot/tss/${SampleID}.gene.mat.pdf
fi

