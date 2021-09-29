rule rgi_bwt:
	input:
		"../readbox/{sample}_1_trimP.fastq.gz",
		"../readbox/{sample}_2_trimP.fastq.gz"
	output:
		"{sample}_bwt.allele_mapping_data.txt"
	shell:
		"""
#		rgi bwt -1 {input[0]} -2 {input[1]} -a bowtie2 -n 25 --clean --include_wildcard -o {wildcards.sample}_bwt --local
		"""

rule trimmomatic:
	input:
		"../readbox/{sample}_1.fastq.gz",
		"../readbox/{sample}_2.fastq.gz"
	output:
		"../readbox/{sample}_1_trimP.fastq.gz",
		"../readbox/{sample}_1_trimS.fastq.gz",
		"../readbox/{sample}_2_trimP.fastq.gz",
		"../readbox/{sample}_2_trimS.fastq.gz",
	shell:
		"""
		java -jar ../Trimmomatic-0.39/trimmomatic-0.39.jar PE -threads 18 -phred33 -trimlog ../readbox/logs/trimlog.txt {input} {output} ILLUMINACLIP:../Trimmomatic-0.39/adapters/TruSeq3-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
		"""
