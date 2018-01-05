#!/bin/bash

github_org=$1
github_repo=$2
build_num=$3
if [ -z "${CIRCLE_API_TOKEN}" ]; then
  echo "CIRCLE_API_TOKEN not set"
  exit 1
fi
circle_token="?circle-token=${CIRCLE_API_TOKEN}"

dir='reports'
file_urls='artifacts.txt'
script='renamer.sh'
### Get artifact URLs
curl https://circleci.com/api/v1.1/project/github/${github_org}/${github_repo}/${build_num}/artifacts${circle_token} | grep -o 'https://[^"]*' > ${file_urls}
### Filter artifact URLs

### Download artifacts
<${file_urls} xargs -P4 -I % wget -xnH -P ${dir} --cut-dirs=1 %${circle_token}
### Clean ?circle-token= off filename ends
# TODO: change path to /bin/bash after testing on Mac
cat <<"RENAME" >${script}
#!/usr/local/bin/bash
file_old=$1
file_new="${file_old%%\?*}"
echo "CMD: mv ${file_old} ${file_new}"
mv ${file_old} ${file_new}
RENAME
chmod +x ${script}
find ${dir} -name '*\?circle-token=*' -print0 | xargs -0tn1 ./${script}
rm -f ${script} ${file_urls}
