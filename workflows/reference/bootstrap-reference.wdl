## Description: 
##
## This WDL workflow downloads all of the default reference files used in St. Jude Cloud pipelines.
##
## Inputs: 
##
## None.
##
## Output: 
##
## reference_fa - Gzipped reference FASTA file (check `inputs.json` for default reference genome used).
## gencode_gtf - Gzipped gencode GTF file (check `inputs.json` for default gene model used).
## stardb - Built STAR database based on the FASTA and GTF above.
##
## LICENSING :
## MIT License
##
## Copyright 2019 St. Jude Children's Research Hospital
##
## Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
##
##The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
##
##THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import "https://raw.githubusercontent.com/stjudecloud/workflows/master/tools/gzip.wdl"
import "https://raw.githubusercontent.com/stjudecloud/workflows/master/tools/star.wdl"
import "https://raw.githubusercontent.com/stjudecloud/workflows/master/tools/wget.wdl"

workflow bootstrap_reference {
    String reference_fa_url
    String gencode_gtf_url

    call wget.download as reference_download { input: url=reference_fa_url, outfilename="GRCh38_no_alt.fa.gz" }
    call gzip.unzip as reference_unzip { input: infile=reference_download.outfile }
    call wget.download as gencode_download { input: url=gencode_gtf_url, outfilename="gencode.v31.gtf.gz" }
    call gzip.unzip as gencode_unzip { input: infile=gencode_download.outfile }
    call star.build_db as star_db_build {
        input:
            reference_fasta=reference_unzip.outfile,
            gencode_gtf=gencode_unzip.outfile,
            stardb_dir_name="STARDB",
            ncpu=4,
            ram_limit="10000000000"
    }

    output {
      File reference_fa = reference_unzip.outfile
      File gencode_gtf = gencode_unzip.outfile
      File stardb_tar_gz = star_db_build.stardb_out
    }
}
