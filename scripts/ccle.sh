#!/bin/bash

#
# Copied from https://osf.io/vb2t6/
# See http://biorxiv.org/content/early/2016/07/12/063552
#
# Copyright PJ Tatlow, Stephen R Piccolo
# 

echo -e "Starting\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" > time.txt
logSar &
cd working

cpu=$(getNumCPU)

mem=$(free -h | gawk  '/Mem:/{print $2}')

echo "You have $cpu cores and $mem GB of memory" >> out.txt

mkdir -p output
mkdir -p fastq_untrimmed
mkdir -p fastq_trimmed
mkdir tmp
echo -e "Sorting\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> time.txt
echo "SORTING"
/working/sambamba sort -m $mem -o $1.sorted.bam -n -p -t 4 --tmpdir tmp/ $1.bam &>> out.txt
echo -e "Finished Sorting:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> time.txt
echo -e "Removing old .bam:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> time.txt
rm $1.bam
echo -e "Finished Removing old .bam:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> time.txt
echo -e "Converting to Fastq\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> time.txt
echo "CONVERTING TO FASTQ"
java -jar /working/picardtools/picard.jar SamToFastq I=$1.sorted.bam OUTPUT_PER_RG=TRUE OUTPUT_DIR=fastq_untrimmed/ &>> out.txt
echo -e "Finished Converting to Fastq\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> time.txt
echo -e "Removing sorted .bam:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> time.txt
rm $1.sorted.bam
echo -e "Finished Removing sorted .bam:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> time.txt

echo -e "Trimming Fastq:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> time.txt
taskFile=/tmp/gdsc_parallel_tasks
rm -f $taskFile

for f1 in fastq_untrimmed/*_1.fastq
do
  f2=${f1/_1\.fastq/_2.fastq}

  echo "trim_galore --paired $f1 $f2 --length 35 -o fastq_trimmed/" >> $taskFile
done

chmod 777 $taskFile
parallel -a $taskFile --ungroup --max-procs $cpu &>> out.txt
rm -f $taskFile

untrimmed=$(ls fastq_untrimmed/*.fastq | wc -l)
trimmed=$(ls fastq_trimmed/*.fq | wc -l)

if [ $untrimmed != $trimmed ]; then
  echo "Not all fastq files trimmed" &>> out.txt
  exit 1;
fi


kallisto_option=""
paired=$(ls fastq_untrimmed/*_2.fastq | wc -l)
if [ $paired == "0" ]
then
    kallisto_option="--single"
fi
echo "KALLISTO"
rm -rf fastq_untrimmed

# trim_galore $(ls -d -1 fastq_untrimmed/*) -o fastq_trimmed/
echo -e "Finished Trimming Fastq:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> time.txt
echo -e "Running Kallisto:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> time.txt

kallisto quant -i gencode.v24.transcripts.idx -b 30 -t $cpu --bias $kalliso_option -o output/ $(ls -d -1 fastq_trimmed/*.fq) &>> out.txt
echo -e "Taring output\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> time.txt
tar -zcvf $1.tar.gz output
sar -A > sar.txt
# tar -zcvf $1.fastq.tar.gz fastq_untrimmed/*
tar -zcvf $1.logs.tar.gz *.txt
echo -e "Finished Taring output\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> time.txt
echo "DONE"
