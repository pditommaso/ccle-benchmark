/* 
 * See 
 *   https://osf.io/vb2t6/
 *   http://biorxiv.org/content/early/2016/07/12/063552
 */
 
 
params.index = "$baseDir/test/transcripts.idx"
params.samples = "$baseDir/test/*.bam"


Channel.fromPath(params.samples).set { samples }


process bam_sort {
  input: file 'sample.bam' from samples
  output: file 'sorted.bam' into sorted_bam 
  
  """
  sambamba sort -n -p -t ${task.cpus} --tmpdir tmp/ -o sorted.bam sample.bam
  """
}

process to_fastq {
  input: file 'sorted.bam' from sorted_bam 
  output: file 'fastq_untrimmed' into untrimmed  

  """
  mkdir fastq_untrimmed
  picard SamToFastq I=sorted.bam OUTPUT_PER_RG=TRUE OUTPUT_DIR=fastq_untrimmed/ 
  """
}

process trim_galore {
  input: file 'fastq_untrimmed' from untrimmed   
  output: file 'fastq_trimmed/*.fq' into trimmed 
  
  shell:
  '''
  for f1 in fastq_untrimmed/*_1.fastq; do
	  f2=${f1/_1\\.fastq/_2.fastq}
	  echo "trim_galore --paired $f1 $f2 --length 35 -o fastq_trimmed/" >> task_file
  done

  mkdir fastq_trimmed
  chmod +x task_file
  parallel -a task_file --ungroup --max-procs !{task.cpus}
  '''

}

process kallisto {
  input:
  file index from file(params.index)
  file reads from trimmed
  
  output: 
  file 'output' 
  
  """
  kallisto quant -i ${params.index} -b 30 -t ${task.cpus} --bias -o output/ $reads
  """

}