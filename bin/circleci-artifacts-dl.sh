#!/bin/bash
#
# Download build artifacts from CircleCI for builds from github repos
#
# CircleCI access API token (CIRCLE_API_TOKEN) must be set before running script
#
github_org=$1
github_repo=$2
# Build numbers that have the artifacts
build_nums=$3
if [ -z "${CIRCLE_API_TOKEN}" ]; then
  echo "CIRCLE_API_TOKEN not set"
  exit 1
fi
circle_token="?circle-token=${CIRCLE_API_TOKEN}"

# Directory tat artifacts are in and will be copied
dir='reports'
script='renamer.sh'

### Get artifact URLs and download
oldIFS=$IFS
IFS=','
for build in ${build_nums}; do
  file_urls="artifacts-${build}.txt"
  # Get artifact URLs
  curl https://circleci.com/api/v1.1/project/github/${github_org}/${github_repo}/${build}/artifacts${circle_token} | grep -o 'https://[^"]*' > ${file_urls}
  # Filter artifact URLs
  # TODO: filter to dl only files under ${dir}
  #
  # Download artifacts
  # <${file_urls} xargs -P4 -I % wget -nv -xnH -P ${dir} --cut-dirs=1 %${circle_token}
  IFS=$oldIFS
  <${file_urls} xargs -P4 -I % wget -nv -xnH --cut-dirs=1 %${circle_token}
  IFS=','
done
IFS=$oldIFS

### Clean ?circle-token= off filename ends
cat <<"RENAME" >${script}
#!/bin/bash
file_old=$1
file_new="${file_old%%\?*}"
#echo "CMD: mv ${file_old} ${file_new}"
mv ${file_old} ${file_new}
RENAME
chmod +x ${script}
# -t for debug output
find ${dir} -name '*\?circle-token=*' -print0 | xargs -0n1 ./${script}

### Cleanup files
rm -f ${script} artifacts-*.txt
