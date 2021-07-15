set -o errexit
set -o pipefail
# set -o noclobber

set -o xtrace
# Must use single quote to prevent variable expansion.
# For example, if double quotes were used, ${LINENO} would take on the value of the current line,
# instead of its value when PS4 is used later in the script
# https://stackoverflow.com/a/6697845/6674256
# ${FOO:+val}    val if $FOO is set
# ${FOO[0]}   element #0 of the FOO array
# https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html
PS4='+ (${BASH_SOURCE[0]##*/} @ ${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

export RED='\033[0;31m'
export CYAN='\033[0;36m'
export NO_COLOR='\033[0m' 

# https://dcc.icgc.org/releases/PCAWG/reference_data/pcawg-bwa-mem
# https://www.cureffi.org/2013/02/01/the-decoy-genome/

url="https://dcc.icgc.org/api/v1/download?fn=/PCAWG/reference_data/pcawg-bwa-mem"
root="/scratch/ucgd/lustre-work/quinlan/u6018199/constraint-tools"
path="${root}/data/reference/grch37"

mkdir --parents ${path}

download_file_with_suffix () {
  local suffix_=$1
  wget ${url}/genome.${suffix_} --output-document=${path}/genome.${suffix_}  
}

echo -e "${CYAN}Downloading GRCH37 reference plus decoy sequences...${NO_COLOR}\n"
wget ${url}/README.txt --output-document=${path}/README.txt
download_file_with_suffix "fa.gz"

check_digest () { 
  local suffix_=$1
  local expected_digest_=$2
  observed_digest_=$(md5sum ${path}/genome.${suffix_} | awk '{ print $1 }')
  if [[ ${observed_digest_} == ${expected_digest_} ]]; then 
    echo -e "${CYAN}${path}/genome.${suffix_}: digest check passed${NO_COLOR}"
  else
    echo -e "${RED}${path}/genome.${suffix_}: digest check failed${NO_COLOR}"
  fi 
}

check_digest "fa.gz" "a07c7647c4f2e78977068e9a4a31af15"

echo -e "${CYAN}Decompressing reference file...${NO_COLOR}\n"
# https://unix.stackexchange.com/a/158538/406037
set +o errexit
gzip --decompress ${path}/genome.fa.gz 
set -o errexit

echo -e "${CYAN}Block compressing reference file...${NO_COLOR}\n"
bgzip --stdout ${path}/genome.fa > ${path}/genome.fa.gz

echo -e "${CYAN}Indexing block-compressed fasta file....${NO_COLOR}"
samtools faidx ${path}/genome.fa.gz

# the index produced by "samtools faidx" is compatible with pyfaidx: 
# "FASTA index files generated by samtools, the faidx utility, and the pyfaidx module are compatible and interchangeable"
# from: https://peerj.com/preprints/970/
# HOWEVER, I encountered this error when using pyfaidx: 
# https://github.com/mdshw5/pyfaidx/issues/124

# A better option is pysam.FastaFile
# The "samtools faidx" index is also compatible with pysam.FastaFile: 
# https://pysam.readthedocs.io/en/latest/api.html?highlight=fasta#pysam.FastaFile

echo -e "${CYAN}Removing uncompressed fasta file ... ${NO_COLOR}"
rm ${path}/genome.fa





