## Description:
##
## This WDL tool includes custom scripts to parse and reformat 
## task output as part of a workflow. 

version 1.0

task get_read_groups {
    input {
        File bam
    }
    Float bam_size = size(bam, "GiB")
    Int disk_size = ceil((bam_size * 2) + 10)

    command {
        samtools view -H ${bam} | grep "@RG" > stdout.txt
    }

    runtime {
        disk: disk_size + " GB"
        docker: 'stjudecloud/bioinformatics-base:bleeding-edge'
    }

   output { 
       String out = read_string("stdout.txt")
   }
    meta {
        author: "Andrew Thrasher"
        email: "andrew.thrasher@stjude.org"
        author: "Andrew Frantz"
        email: "andrew.frantz@stjude.org"
        description: "This WDL tool is a utility to get read group information from a BAM file and write it out to as a string" 
    }
    parameter_meta {
        bam: "Input BAM format file to generate coverage for"
    }
}

task prepare_read_groups_for_star {
    input {
        String read_groups
    }

    command <<<
        echo "~{read_groups}" | cut -f 2- | sed -e 's/\t/ /g' | awk '{print}' ORS=' , '| sed 's/ , $//' > stdout.txt
    >>>

    runtime {
        docker: 'stjudecloud/bioinformatics-base:bleeding-edge'
    }

<<<<<<< HEAD
   output { 
       String out = read_string("stdout.txt")
   }
    meta {
        author: "Andrew Thrasher"
        email: "andrew.thrasher@stjude.org"
        author: "Andrew Frantz"
        email: "andrew.frantz@stjude.org"
        description: "This WDL tool is a utility to reformat read group information from a BAM file into a format that can be passed in to the STAR aligner."
    }
    parameter_meta {
        read_groups: "The read group portion of a BAM header as a string"
=======
    output {
        String out = read_string("stdout.txt")
>>>>>>> jobin/rnaseq_v2_azure
    }
}
