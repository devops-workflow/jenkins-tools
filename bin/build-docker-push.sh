#!/bin/bash
#
tmpdir=${WORKSPACE}/tmp
dockerTags=$(cat ${tmpdir}/dockerTags)

### Tag and Push Docker image
aws_login=$(aws ecr get-login --region $AWS_REGION)
aws_url="${aws_login##*https://}"
${aws_login}
for T in ${dockerTags}; do
  target=${aws_url}/${T}
  docker tag ${T} ${target}
  docker push ${target}
done
