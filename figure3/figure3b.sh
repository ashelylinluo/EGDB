#!/bin/bash 


python bin/bam2140.subset.py --bam data/MNase_1.q20.unique.bam --outbam subset/MNase_1.bam
python bin/bam2140.subset.py --bam data/MNase_2.q20.unique.bam --outbam subset/MNase_2.bam

sambamba merge -t 10 result/mergedbam/MNase.merged.bam subset/MNase_1.bam subset/MNase_2.bam

python ~/Biosoft/Prog/DANPOS3/danpos.py dpos input/MNase.dedup.bam -m 1 -o NOC -f 1 -s 1 -n F -a 1 -p 1e-5 -t 1e-5

# profile
python ~/Biosoft/Prog/DANPOS3/danpos.py profile MNase.smooth.wig --genefile_paths ~/Database/Pmillet/sequence/Pmillet.gene.bed --genomic_sites TSS


Rscript bin/plot_dinucleosides.R



