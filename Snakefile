rule rgi_bwt:
	input:
		"../readbox/{sample}_1_trimP.fastq.gz",
		"../readbox/{sample}_2_trimP.fastq.gz"
	output:
		"../rgi_bwt/{sample}_bwt.allele_mapping_data.txt"
	conda:
		"required_env.yaml"
	shell:
		"""
		cd ../rgi_bwt
		rgi bwt -1 {input[0]} -2 {input[1]} -a bowtie2 -n 25 --clean --include_wildcard -o {wildcards.sample}_bwt --local
		cd ../git_repo
		"""
rule rgi_main:
	input:
		"../readbox/{sample}_assembly/contigs.fasta"
	output:
		"../rgi_main/{sample}_main.txt"
	shell:
		"""
		cd ../rgi_main
		rgi main -i ../readbox/{wildcards.sample}_assembly/contigs.fasta -o {wildcards.sample}_main -t contig -a BLAST --clean -n 30 -d wgs --split_prodigal_jobs --local
		cd ../git_repo
		"""

rule spades:
	input:
		"../readbox/{sample}_1_trimP.fastq.gz",
		"../readbox/{sample}_2_trimP.fastq.gz"
	output:
		"../readbox/{sample}_assembly/contigs.fasta"
	shell:	
		"../SPAdes-3.15.2/spades.py -1 {input[0]} -2 {input[1]} -t 20 -m 100 -k 55 -o ../readbox/{wildcards.sample}_assembly --meta"

rule trimmomatic:
	"""
	trimming rule
	in questa parte del workflow vengono rimossi gli adapter dalle reads
	Come prerequisito è necessario aver installato trimmomatic in una repo esterna alla cartella in cui si lavora, sarebbe da automatizzare
	"""

	input:
		"../Trimmomatic-0.39/trimmomatic-0.39.jar"
		"../readbox/{sample}_1.fastq.gz",
		"../readbox/{sample}_2.fastq.gz"
	output:
		"../readbox/{sample}_1_trimP.fastq.gz",
		"../readbox/{sample}_1_trimS.fastq.gz",
		"../readbox/{sample}_2_trimP.fastq.gz",
		"../readbox/{sample}_2_trimS.fastq.gz",
	conda:
		"required_env.yaml"
	shell:
		"""
		java -jar ../Trimmomatic-0.39/trimmomatic-0.39.jar PE -threads 18 -phred33 -trimlog ../readbox/logs/trimlog.txt {input} {output} ILLUMINACLIP:../Trimmomatic-0.39/adapters/TruSeq3-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
		"""

rule get_trimmomatic:
	output:
		"../Trimmomatic-0.39/trimmomatic-0.39.jar"
	shell:
		"""
		cd ..
		wget http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.39.zip
		gzip -d Trimmomatic-0.39.zip
		cd git_repo
		"""
		
#manca il quality control sugli steps
#per ora l'ordinamento delle cartelle nella pipeline è riferita a quella sul mio server, sarebbe meglio mettere tutto in una sola
#devo fare una rule per preparare le cartelle in cui eseguire rgi_main e _bwt qualora non fossero già predisposte
