#!/bin/bash
#
# Download build artifacts from CircleCI for builds from github repos
#
# CircleCI access API token (CIRCLE_API_TOKEN) must be set before running script
#
github_org=$1
github_repo=$2
# Build number that has the artifacts
build_num=$3
if [ -z "${CIRCLE_API_TOKEN}" ]; then
  echo "CIRCLE_API_TOKEN not set"
  exit 1
fi
circle_token="?circle-token=${CIRCLE_API_TOKEN}"

# Directory to put artifacts in
dir='reports'
file_urls='artifacts.txt'
script='renamer.sh'
### Get artifact URLs
curl https://circleci.com/api/v1.1/project/github/${github_org}/${github_repo}/${build_num}/artifacts${circle_token} | grep -o 'https://[^"]*' > ${file_urls}
### Filter artifact URLs

### Download artifacts
<${file_urls} xargs -P4 -I % wget -nv -xnH -P ${dir} --cut-dirs=1 %${circle_token}
### Clean ?circle-token= off filename ends
# TODO: change path to /bin/bash after testing on Mac
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
rm -f ${script} ${file_urls}
