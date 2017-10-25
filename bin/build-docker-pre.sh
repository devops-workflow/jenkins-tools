#!/bin/bash
#
# Setup everything for building a docker image
# Create the command line with variable assignments for all the ARG and TAG fields found in the Dockerfile
#
# Designed to run under Jenkins. Depends on environment variables that Jenkins sets.
# Optional ENV vars:
#   dockerfilePath  Specifies where the Dockerfile is
#   namespace       Namespace for the docker image

echo "Creating docker build arguments..."

### Find Dockerfile
dockerDirs="infrastructure/docker docker ."
if [ -n "${dockerfilePath}" ]; then
  # Support passing in Dockerfile path by env variable
  dockerFile=${dockerfilePath}
else
  for DF in ${dockerDirs}; do
    if [ -f "${DF}/Dockerfile" ]; then
      dockerFile=${DF}/Dockerfile
      break
    fi
  done
fi
if [ -z "${dockerFile}" ]; then
  echo "ERROR: Dockerfile NOT found"
  #exit 1
else
  echo "Dockerfile: ${dockerFile}"
fi
dockerDir="${dockerFile%/Dockerfile}"

tmpdir=${WORKSPACE}/tmp
buildName=${tmpdir}/buildName
dockerBuildArgs=${tmpdir}/dockerBuildArgs
dockerBuildArgsTags=${tmpdir}/dockerBuildArgsTags
dockerBuildArgsVars=${tmpdir}/dockerBuildArgsVars
dockerImageId=${tmpdir}/dockerImageId
dockerImageName=${tmpdir}/dockerImageName
dockerTags=${tmpdir}/dockerTags
dockerTagsOnly=${tmpdir}/dockerTagsOnly
versionFile=${tmpdir}/version
imageDir=output-images

mkdir -p ${tmpdir}

echo "Creating docker build arguments..."
### Setup variables
echo "${dockerDir}" > ${tmpdir}/dockerDir
BUILD_DATE=$(date --utc +%Y-%m-%dT%H:%M:%S.%NZ)
TAG_DATE=$(date --utc +%Y-%m-%d_%H_%M_%S)
GIT_URL="${GIT_URL%.git}"
# VERSION - need to be read in from a file and/or git
# Commit: git rev-parse --short HEAD
# USE THIS? Latest tag in current branch with info past tag: git describe --tags
# Can this be made to add difference of current commit to the tag?
# Latest tag across all branchs: git describe --tags $(git rev-list --tags --max-count=1)
if [ -n "$(git tag)" ]; then
  VERSION=$(git describe --tags)
else
  VERSION="0.0.0-$(git rev-list HEAD --count)-$(git rev-parse --short HEAD)"
fi
echo "${VERSION}" > ${versionFile}
#repository=$(grep org.label-schema.name= ${dockerFile} | sed 's/.*="//;s/".*//')
#if [ -z "${repository}" ]; then
  # Create repository name if not in Dockerfile
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
REPOSITORY=${repository}

## Determine image name - Must be lowercase
#suffix="${dockerFile##*Dockerfile}"
#if [ -n "${suffix}" ]; then
#  imageName="${suffix##-}"
#else
  imageName="${repository,,}"
#fi
echo "${imageName}" > ${dockerImageName}

### Cleanup old artifacts
echo "Starting cleanup of old artifacts..."
# Clean host of old image files in job
if [ -d ${imageDir} ]; then
 rm -rf ${imageDir}/*
fi
# Clean host of old images in Docker
echo "Removing images for: ${imageName}..."
for I in $(docker images --format "{{.ID}}" ${imageName} | sort -u); do
  docker rmi -f $I
done
# TODO: Improve and remove all untagged images.
# DANGEROUS: This will only work if ONLY 1 container job exists. Otherwise could be removing layers of other images.
# Needed due to lack of disk space. But better cleanup is needed
echo "Removing untagged images..."
for I in $(docker images -a --format "{{.ID}} {{.Tag}}" | grep '<none>' | cut -d\  -f1 | sort -u); do
  docker rmi -f $I
done

# if no labels in file, add them
grep '^# METADATA Section' ${dockerFile}
if [ $? -ne 0 ]; then
  echo "Adding LABEL definitions to Dockerfile"
  cat <<LABELS >>${dockerFile}
# METADATA Section
###
### Setup both static and dynamic build time metadata
###
# ARG variables must match build environment variables or variables created in build script
# ARG variables must have default values so developers are not required to set via cli
# All built time environment variables are accessible
# Build script currently creates: BUILD_DATE, REPOSITORY, TAG_DATE, VERSION
# Labels definitions/suggestions at:
#   http://label-schema.org
#   https://github.com/projectatomic/ContainerApplicationGenericLabels/

ARG BUILD_DATE=2000-01-01
ARG BUILD_NUMBER=1
ARG BUILD_TAG=dev
ARG BUILD_URL=dev
ARG GIT_COMMIT=dev
ARG GIT_URL=dev
ARG JOB_NAME=dev
ARG REPOSITORY=dev/proj
ARG VERSION=0.0.1
LABEL org.label-schema.build-date="\${BUILD_DATE}" \
 org.label-schema.name="\${REPOSITORY}" \
 org.label-schema.description="${gitRepo}" \
 org.label-schema.vendor="Wiser Solutions" \
 org.label-schema.version="\${VERSION}" \
 org.label-schema.vcs-ref="\${GIT_COMMIT}" \
 org.label-schema.vcs-url="\${GIT_URL}" \
 org.label-schema.schema-version="1.0" \
 com.wiser.jenkins-job="\${JOB_NAME}" \
 com.wiser.jenkins-build="\${BUILD_NUMBER}" \
 com.wiser.jenkins-build-tag="\${BUILD_TAG}" \
 com.wiser.jenkins-build-url="\${BUILD_URL}"
LABELS
fi

### Build command line for ARG variable assignments
cmdArgs=''
for A in $(grep ^ARG ${dockerFile} | cut -d\  -f2 | cut -d= -f1); do
  cmdArgs="${cmdArgs} --build-arg ${A}=${!A}"
done
echo "DEBUG: Args=${cmdArgs}"
echo "${cmdArgs}" > ${dockerBuildArgs}
echo "${cmdArgs}" > ${dockerBuildArgsVars}

### Build command line for addition tags from Dockerfile
cmdTags=''
buildTags=''
#buildTagsOnly=''
#for T in $(grep -E '[ #]TAG=' ${dockerFile} | sed 's/^.*TAG=//'); do
#  buildTags="${buildTags} ${T}"
#  buildTagsOnly="${buildTagsOnly} ${T}"
#  cmdTags="${cmdTags} -t ${T}"
#done
# Add standard build tags
# remove latest if use plugin
# docker tag
#tagList=
buildTags="${imageName}:${VERSION} ${imageName}:${BUILD_NUMBER} ${imageName}:${TAG_DATE} ${imageName}:latest ${buildTags}"
#buildTagsOnly="${VERSION} ${BUILD_NUMBER} ${TAG_DATE} ${buildTagsOnly}"
#for T in ${buildTags}; do
#  cmdTags="${cmdTags} -t ${T}"
#done
#docker build
#buildTags=
cmdTags="-t ${imageName}:${VERSION} -t ${imageName}:${BUILD_NUMBER} -t ${imageName}:${TAG_DATE} -t ${imageName}:latest ${cmdTags}"
echo "DEBUG: list Tags=${buildTags}"
echo "DEBUG: build command Tags=${cmdTags}"
#echo "#${BUILD_NUMBER} ${buildTags}" > ${buildName}
echo "${buildTags}" > ${dockerTags}
#echo "${buildTagsOnly}" > ${dockerTagsOnly}
echo "${cmdTags}" >> ${dockerBuildArgs}
echo "${cmdTags}" > ${dockerBuildArgsTags}

echo "Finished creating docker build arguments."
