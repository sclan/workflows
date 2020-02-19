version 1.0

import "../rnaseq/rnaseq-standard.wdl" as rnav2
import "../../tools/util.wdl"
import "../../tools/tsne.wdl"
import "../../tools/tar.wdl"
import "../../tools/gzip.wdl"
import "../../tools/wget.wdl"

workflow interactive_tsne {
    input { 
        Array[File] in_bams
        File gencode_gtf
        File? stardb_tar_gz
        File? reference_counts
        File? covariates_file
        String tissue_type
        String? output_filename
    }
    
    String blacklist_url = "https://athrashe.blob.core.windows.net/tsne-test/gene.blacklist.tsv"
    String outfile = select_first([output_filename, "output.html"])
    
    if (! defined(stardb_tar_gz)){
        String star_url = "https://athrashe.blob.core.windows.net/tsne-test/STARDB.tar.gz"
        call wget.download as star_download { input: url=star_url, outfilename="STARDB.tar.gz" }
    }
    File stardb = select_first([stardb_tar_gz, star_download.outfile])

    call tsne.validate_tissue_type { input: tissue_type=tissue_type }

    call wget.download as blacklist_download { input: url=blacklist_url, outfilename="blacklist.txt" }

    call gzip.unzip as uncompress_gencode { input: infile=gencode_gtf }
    scatter (bam in in_bams) {
        call rnav2.rnaseq_standard { input: gencode_gtf=uncompress_gencode.outfile, input_bam=bam, stardb_tar_gz=stardb }
    }

    if (! defined(reference_counts)){
        # Based on tissue type selection we can provide reference data
        String reference_url = if (tissue_type == 'blood') then "https://athrashe.blob.core.windows.net/tsne-test/counts.tar.gz" else
                               if (tissue_type == 'brain') then "https://athrashe.blob.core.windows.net/tsne-test/counts.tar.gz" else
                               if (tissue_type == 'solid') then "https://athrashe.blob.core.windows.net/tsne-test/counts.tar.gz"
                               else "" 
        call wget.download as reference_counts_download { input: url=reference_url, outfilename="counts.tar.gz"}

        String covariates_url = if (tissue_type == 'blood') then "https://athrashe.blob.core.windows.net/tsne-test/covariates.test.tsv" else
                               if (tissue_type == 'brain') then "https://athrashe.blob.core.windows.net/tsne-test/covariates.test.tsv" else
                               if (tissue_type == 'solid') then "https://athrashe.blob.core.windows.net/tsne-test/covariates.test.tsv"
                               else "" 
        call wget.download as covariates_download { input: url=covariates_url, outfilename="covariates.tsv" }
    }

    File reference_file = select_first([reference_counts, reference_counts_download.outfile])
    File covariates_input = select_first([covariates_file, covariates_download.outfile])

    call gzip.unzip { input: infile=reference_file }
    call tar.untar { input: infile=unzip.outfile }

    scatter (bam in in_bams){
        call util.file_basename { input: in_file=bam, suffix=".bam" }
    }

    # generate covariates information for input samples and add to covariates file.
    call tsne.append_input { input: inputs=file_basename.out, covariates_infile=covariates_input}
    
    call tsne.plot {
        input:
            counts=untar.outfiles,
            inputs=file_basename.out,
            input_counts=rnaseq_standard.gene_counts,
            blacklist=blacklist_download.outfile,
            covariates=append_input.covariates_outfile,
            gencode_gtf=gencode_gtf,
            outfile=outfile
    }
     
}
