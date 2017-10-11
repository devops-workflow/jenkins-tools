
# Designed to run under Jenkins. Depends on environment variables that Jenkins sets.
# Optional ENV vars:
#   dockerfilePath  Specifies where the Dockerfile is
#   namespace       Namespace for the docker image

#for D in customer_catalog_service customer_imports_service customer_matching_service extraction-scheduler extraction_service image-resize-service product-catalog-service product-matching-service quad-matching; do
#  pushd $D 2>&1 >/dev/null
### Find Dockerfile
dockerDirs="infrastructure/docker docker . docker/production"
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
pwd
if [ -z "${dockerFile}" ]; then
  echo "ERROR: Dockerfile NOT found"
  #exit 1
else
  echo "Dockerfile: ${dockerFile}"
fi
dockerDir="${dockerFile%/Dockerfile}"
#popd 2>&1 >/dev/null
#done

echo "Creating docker build arguments..."
### Setup variables
BUILD_DATE=$(date --utc +%Y-%m-%dT%H:%M:%S.%NZ)
TAG_DATE=$(date --utc +%Y-%m-%d)
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
gitRepo="${GIT_URL##*/}"
gitOrg="${GIT_URL##*.com/}"
gitOrg="${gitOrg%%/*}"
if [ -n "${namespace}" ]; then
  repository="${namespace}/${gitRepo}"
else
  repository="${gitOrg}/${gitRepo}"
fi
REPOSITORY=${repository}
## Determine image name
#suffix="${dockerFile##*Dockerfile}"
#if [ -n "${suffix}" ]; then
#  imageName="${suffix##-}"
#else
  # Must be lowercase
  imageName="${repository,,}"
#fi
## Build command line for ARG variable assignments
cmdArgs=''
for A in $(grep ^ARG ${dockerFile} | cut -d\  -f2 | cut -d= -f1); do
  cmdArgs="${cmdArgs} --build-arg ${A}=${!A}"
done
echo "DEBUG: Args=${cmdArgs}"
#echo "${cmdArgs}" > ${dockerBuildArgs}

## Build command line for addition tags from Dockerfile
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
#buildTagsOnly="${VERSION} ${BUILD_NUMBER} ${buildTagsOnly}"
#docker build
#buildTags=
cmdTags="-t ${imageName}:${VERSION} -t ${imageName}:${BUILD_NUMBER} -t ${imageName}:${TAG_DATE} -t ${imageName}:latest ${cmdTags}"
#cmdTags="-t ${imageName}:latest"
echo "DEBUG: list Tags=${buildTags}"
echo "DEBUG: build command Tags=${cmdTags}"
#echo "#${BUILD_NUMBER} ${buildTags}" > ${buildName}
#echo "${buildTags}" > ${dockerTags}
#echo "${buildTagsOnly}" > ${dockerTagsOnly}
#echo "${cmdTags}" >> ${dockerBuildArgs}

### Build: docker image
cd ${dockerDir}
docker build ${cmdTags} .

### Tag and Push Docker image
aws_login=$(aws ecr get-login --region $AWS_REGION)
aws_url="${aws_login##*https://}"
${aws_login}
# FIX no basic auth cred, need docker login. Above not handle ??
for T in ${buildTags}; do
  target=${aws_url}/${T}
  docker tag ${T} ${target}
  docker push ${target}
done
