/* 
 * See 
 *   https://osf.io/vb2t6/
 *   http://biorxiv.org/content/early/2016/07/12/063552
 * 
 * GenCode24 Transcript
 *   ftp://ftp.sanger.ac.uk/pub/gencode/Gencode_human/release_24/gencode.v24.transcripts.fa.gz
 *
 */
 
 
params.index = "$baseDir/test/transcripts.idx"
params.samples = "$baseDir/test/*.bam"


Channel
	.fromPath(params.samples)
	.map { file -> tuple(file.baseName, file) }
	.set { samples }


process bam_sort {
  tag "sample: $sample_id"
  
  input: 
    set val(sample_id), file('sample.bam') from samples
  output: 
    set val(sample_id), file('sorted.bam') into sorted_bam 
  
  """
  sambamba sort -n -p -t ${task.cpus} --tmpdir tmp/ -o sorted.bam sample.bam
  """
}

process to_fastq {
  tag "sample: $sample_id"
  
  input: 
  set val(sample_id), file('sorted.bam') from sorted_bam 
  output: 
  set val(sample_id), file('fastq_untrimmed/*.fastq') into untrimmed  

  """
  mkdir fastq_untrimmed
  picard SamToFastq I=sorted.bam OUTPUT_PER_RG=TRUE OUTPUT_DIR=fastq_untrimmed/ 
  """
}

untrimmed
  .map { sample, files -> tuple( sample, files[0].name.replaceAll(/_1.fastq/,'') , files) }
  .set { untrimmed_pairs } 

process trim_galore {
  tag "sample: $sample_id - reads: $pair_id"
  
  input: 
    set val(sample_id), val(pair_id), file(fastq) from untrimmed_pairs   
  output: 
    set val(sample_id), val(pair_id), file('fastq_trimmed/*.fq') into trimmed 
  
  """
  mkdir fastq_trimmed
  trim_galore --paired $fastq --length 35 -o fastq_trimmed/
  """

}

process kallisto {
  tag "sample: $sample_id - reads: $pair_id"
  
  input:
  file index from file(params.index)
  set val(sample_id), val(pair_id), file(reads) from trimmed
  
  output: 
  file 'output' 
  
  """
  kallisto quant -i ${params.index} -b 30 -t ${task.cpus} --bias -o output/ $reads
  """

}