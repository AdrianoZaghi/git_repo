configfile: "config.yaml"

rule comparison:
	input:
		"../rgi_bwt/{sample}_bwt.allele_mapping_data.json",
		"../rgi_main/{sample}_main.json"
	output:
		"ho_fatto_{sample}.txt"
#	script:
#		"comparison.py"
	shell:
		"touch ho_fatto_{wildcards.sample}.txt"

rule rgi_bwt:
	input:
		"../readbox/{sample}_1_trimP.fastq.gz",
		"../readbox/{sample}_2_trimP.fastq.gz"
	output:
		"../rgi_bwt/{sample}_bwt.allele_mapping_data.txt",
		"../rgi_bwt/{sample}_bwt.allele_mapping_data.json"
	conda:
		"required_env.yaml"
	shell:
		"""
		cd ../rgi_bwt
		rgi bwt -1 {input[0]} -2 {input[1]} -a bowtie2 -n {config[threads]} --clean --include_wildcard -o {wildcards.sample}_bwt --local
		cd ../git_repo
		"""
rule rgi_main:
	input:
		"../readbox/{sample}_assembly/contigs.fasta"
	output:
		"../rgi_main/{sample}_main.txt",
		"../rgi_main/{sample}_main.json"
	conda:
		"required_env.yaml"
	shell:
		"""
		cd ../rgi_main
		rgi main -i ../readbox/{wildcards.sample}_assembly/contigs.fasta -o {wildcards.sample}_main -t contig -a {config[rgi_main_alignment_tool]} --clean -n {config[threads]} -d wgs --split_prodigal_jobs --local
		cd ../git_repo
		"""
rule spades:
	input:
		"../readbox/{sample}_1_trimP.fastq.gz",
		"../readbox/{sample}_2_trimP.fastq.gz"
	output:
		"../readbox/{sample}_assembly/contigs.fasta"
	shell:
		"../SPAdes-3.15.2/spades.py -1 {input[0]} -2 {input[1]} -t {config[threads]} -m {config[ram]} -k {config[assembly_k_parameter]} -o ../readbox/{wildcards.sample}_assembly --meta"
rule trimmomatic:
	"""
	trimming rule
	in questa parte del workflow vengono rimossi gli adapter dalle reads
	Come prerequisito è necessario aver installato trimmomatic in una repo esterna alla cartella in cui si lavora, sarebbe da automatizzare
	"""
	input:
		"../Trimmomatic-0.39/trimmomatic-0.39.jar",
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
		java -jar ../Trimmomatic-0.39/trimmomatic-0.39.jar PE -threads {config[threads]} -phred33 -trimlog ../readbox/logs/trimlog.txt {input} {output} ILLUMINACLIP:../Trimmomatic-0.39/adapters/TruSeq3-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
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
rule FastQC:
	input:
		"../readbox/{read}.fastq.gz"
	output:
		"../FastQC_output/{read}_fastqc/Images/per_base_quality.png"
	shell:
		"""
		./../FastQC/fastqc {input} --outdir=../FastQC_output
		unzip {read}_fastqc.zip
		rm {read}_fastqc.zip
		"""

rule quast:
	input:
		"../readbox/ERR2241642_assembly/contigs.fasta"
	output:
		"uso_quast.txt"
	conda:
		"quast_env.yaml"
	shell:
		"""
		quast -o ../quast_report --threads {config[threads]} {input}
		touch uso_quast.txt
		"""
rule report:
	input:
		"../FastQC_output/{sample}_1_fastqc/Images/per_base_quality.png",
		"../FastQC_output/{sample}_2_fastqc/Images/per_base_quality.png",
		"../FastQC_output/{sample}_1_trimP_fastqc/Images/per_base_quality.png",
		"../FastQC_output/{sample}_2_trimP_fastqc/Images/per_base_quality.png"
	output:
		report("{input[0]}", category="Original data"),
		report("{input[1]}", category="Original data"),
		report("{input[2]}", category="Trimmed data"),
		report("{input[3]}", category="Trimmed data")

#includi lo script per terminare l'analisi
#	modificalo in modo da utilizzare i json fle invece dei txt
#comporre il report con:
#	risultato dello script
#	quality reports

#dovrei mettere rules accessorie per scaricare i programmi che non sono in anaconda come ho fatto con get_trimmomatic
#per ora l'ordinamento delle cartelle nella pipeline è riferita a quella sul mio server, sarebbe meglio mettere tutto in una sola
#devo fare una rule per preparare le cartelle in cui eseguire rgi_main e _bwt qualora non fossero già predisposte
