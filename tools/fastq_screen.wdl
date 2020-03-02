version 1.0

task build_db {
    input {
        String filename = "fastq-screen-db"
        Int? max_retries = 1
    }

    String tar_filename = filename + ".tar.gz"

    command {
        fastq_screen --get_genomes 
        mv FastQ_Screen_Genomes/ ${filename}/
        tar -czf ${tar_filename} ${filename}/
    }
 
    runtime {
        disk: "30 GB"
        docker: "fastq_screen:1.0.0-alpha"
        maxRetries: max_retries
    }

    output {
        File db = tar_filename
    }

    meta {
        author: "Clay McLeod"
        email: "clay.mcleod@STJUDE.org"
        description: ""
    }

    parameter_meta {}
} 

task fastq_screen {
    input {
        File read1
        File read2
        File db
        String? format = "illumina"
        Int? num_reads = 100000
        Int? max_retries = 1
    }

    read1_outfilename = basename(read1, ".fastq") + "_screen.txt"
    read2_outfilename = basename(read1, ".fastq") + "_screen.txt"

    command {
        tar -xsf ${db}
        cat ${db}/fastq_screen.conf
        fastq_screen --conf ${db}/fastq_screen.conf --illumina1_3 ${read1} ${read2}
    }
 
    runtime {
        docker: "fastq_screen:1.0.0-alpha"
        maxRetries: max_retries
    }

    output {
        File read1_outfile = read1_outfilename
        File read2_outfile = read2_outfilename
    }
}