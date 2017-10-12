#!/bin/bash
#
# Docker image testing
#

echo "Starting Docker Image testing..."

tmpdir=tmp
dockerDir=.
dockerFile=${dockerDir}/Dockerfile
imageDir=output-images
reportsDir=reports
versionFile=${tmpdir}/version
GIT_URL="${GIT_URL%.git}"

mkdir -p ${tmpdir} ${reportsDir}

#repository=$(grep org.label-schema.name= ${dockerFile} | sed 's/.*="//;s/".*//')
#if [ -z "${repository}" ]; then
  gitRepo="${GIT_URL##*/}"
  gitOrg="${GIT_URL##*.com/}"
  gitOrg="${gitOrg%%/*}"
  #echo "ERROR: No image name found in Dockerfile. Using: ${repository}"
#fi
if [ -n "${namespace}" ]; then
  repository="${namespace}/${gitRepo}"
else
  repository="${gitOrg}/${gitRepo}"
fi

VERSION=$(cat ${versionFile})
dockerImage="${repository,,}:${VERSION}"
dockerImageID=$(docker images --format '{{.ID}}' ${dockerImage})

# Save image to file for scanning tools
echo "Saving Docker Image..."
imageFilename="${repository//\//-}-${VERSION}.tar"
imageFile="${imageDir}/${imageFilename}"
mkdir -p ${imageDir}
docker save -o ${imageFile} ${repository}

###
### Image Scanning
###
printf "=%.s" {1..30}
echo -e "\n\nStarting Audit Scanning...\n"
printf "=%.s" {1..30}
echo

#static-analysis-docker-image-clair.sh
static-analysis-docker-image-lint.sh
static-analysis-docker-image-lynis.sh

printf "=%.s" {1..30}
echo -e "\nFinished Docker Image testing."
printf "=%.s" {1..30}
echo
