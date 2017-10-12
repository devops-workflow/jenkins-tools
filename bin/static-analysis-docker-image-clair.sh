#!/bin/bash
#
# Docker image testing
#

tmpdir=tmp
#dockerDir=.
#dockerFile=${dockerDir}/Dockerfile
imageDir=output-images
reportsDir=reports
versionFile=${tmpdir}/version
GIT_URL="${GIT_URL%.git}"

mkdir -p ${tmpdir} ${reportsDir}

###
### Clair
###
# Install
#  use docker-compose or manual and can have central Clair server
if [ $(docker ps --format '{{.ID}}' --filter name=clair_postgres | wc -l) -eq 0 ]; then
  ###
  ### Create postgres container
  ###
  #docker pull postgres:latest
  docker run -d --name clair_postgres -e POSTGRES_PASSWORD=password postgres:latest
fi

if [ $(docker ps --format '{{.ID}}' --filter name=clair_clair | wc -l) -eq 0 ]; then
  ###
  ### Create Clair container
  ###
  # Do not try to use latest with config from master
  clair_version=v1.2.3
  clair_config_dir="${WORKSPACE%%/workspace*}/clair_config"
  TMPDIR=
  mkdir -p ${clair_config_dir}
  curl -L https://raw.githubusercontent.com/coreos/clair/${clair_version}/config.example.yaml -o ${clair_config_dir}/config.yaml
  sed -i '/ source:/ s#:.*#: postgresql://postgres:password@postgres:5432?sslmode=disable#' ${clair_config_dir}/config.yaml
  #docker pull quay.io/coreos/clair:${clair_version}
  docker run -d --name clair_clair -p 6060-6061:6060-6061 --link clair_postgres:postgres -v /tmp:/tmp -v ${clair_config_dir}:/config quay.io/coreos/clair:${clair_version} -config=/config/config.yaml
fi

install_dir="${WORKSPACE%%/workspace*}/bin"
if [ ! -x ${install_dir}/hyperclair ]; then
  ###
  ### Install hyperclair
  ###
  # write code to determine and get latest
  # Could eventually change to clairctl in clair
  hyperclair_version=0.5.2
  mkdir -p ${install_dir}
  # sudo curl -L -o ${install_dir}/hyperclair  https://github.com/wemanity-belgium/hyperclair/releases/download/0.5.0/hyperclair-{OS}-{ARCH}
  curl -L -o ${install_dir}/hyperclair  https://github.com/wemanity-belgium/hyperclair/releases/download/${hyperclair_version}/hyperclair-linux-amd64
  chmod +x ${install_dir}/hyperclair
  # Create config file (optional)
#  cat <<HYPERCLAIR > ${install_dir}/../.hyperclair.yml
#clair:
#  port: 6060
#  healthPort: 6061
#  uri: http://127.0.0.1
#  priority: Low
#  report:
#    path: ./reports
#    format: html
#HYPERCLAIR
fi
# Run hyperclair - analyse image and generate report - Have jenkins consume report (formats?)
# Config file setup ??
${install_dir}/hyperclair version
${install_dir}/hyperclair health
# If clair is NOT healthy, wait for a while
#${install_dir}/hyperclair -h
echo
printf "=%.s" {1..3}
echo -e "Running Clair CLI hyperclair...\n"
echo "CMD: hyperclair push|analyse|report ${dockerImage} --local"
${install_dir}/hyperclair push ${dockerImage} --local
${install_dir}/hyperclair analyse ${dockerImage} --local
${install_dir}/hyperclair report ${dockerImage} --local --format html
# Create json output and parse to get into Jenkins GUI
${install_dir}/hyperclair report ${dockerImage} --local --format json
# Report at reports/html/analyse-<image name>-<tag|latest>.html
#--config ${install_dir}/../.hyperclair.yml
# Can query json with jq
# Number of vulnerabilities found. List of all the CVEs
#jq '.Layers[].Layer.Features[].Vulnerabilities[].Name' analysis-intel-fenix-0.0-636-3edcab1.json 2>/dev/null | sort -u | wc -l
#jq '.Layers[].Layer.Features[].Vulnerabilities[].Severity' analysis-intel-fenix-0.0-636-3edcab1.json 2>/dev/null | wc -l
# List of all package names
#jq '.Layers[].Layer.Features[].Name' | sort -u

# Create jq parser for creating Jenkins Warning plugin output
parserFile=parse-hyperclair.jq
cat <<"PARSER" >${tmpdir}/${parserFile}
#
# jq filter for parsing hyperclair output into 1 liners that Jenkins Warning plugin can parse
#
# Written for jq 1.5
# Author: Steven Nemetz
#
# Output format:
#  filename;line number;category;type;priority;message
#
# Set to variable, then reference after if
# Got lost because of piping a lower level
#.filename = "\(.ImageName):\(.Tag)"
# | (.Layers[].Layer.Features[]
#
# First line is bad. So pipe to
# Will create duplicate and bad lines
# Need to pipe output to cleanup or figure out better way to do this
# | sort -u | tail -n+2
"\(.ImageName):\(.Tag);0;" +
(.Layers[].Layer.Features[]
  | if .Vulnerabilities then
      "\(.Name) - \(.Version);" +
      (.Vulnerabilities[] | "\(.Name);\(.Severity);" +
      if .Message then
        "\(.Message) "
      else
        ""
      end +
      "Reference: \(.Link)")
    else
      ""
    end
 )
PARSER
# reformat dockerImage - x/y:ver -> x-y-ver - s/[/:]/-/g
filenameBase="analysis-$(echo ${dockerImage} | sed 's#[/:]#-#g')"
jq -f ${tmpdir}/${parserFile} ${reportsDir}/json/${filenameBase}.json | sort -u | tail -n+2 > ${reportsDir}/${filenameBase}.warnings
if [ ! -s ${reportsDir}/${filenameBase}.warnings ]; then
  rm -f ${reportsDir}/${filenameBase}.warnings
fi

#export GODIR="${WORKSPACE%%/workspace*}/go"
#export GOPATH=$GODIR:/usr/lib/go-1.6
#if [ ! -x ${GODIR}/bin/analyze-local-images ]; then
#  ###
#  ### Install analyze-local-images
#  ###
#  #export GOBIN=
#  /usr/lib/go-1.6/bin/go get -u github.com/coreos/clair/contrib/analyze-local-images
#  $GODIR/bin/analyze-local-images -h || true
#fi
## Run analyze-local-images
#echo
#printf "=%.s" {1..3}
#echo -e "Running Clair CLI analyze-local-images...\n"
#echo "CMD: analyze-local-images ${dockerImage}"
#$GODIR/bin/analyze-local-images ${dockerImage}
## Write Jenkins Warning parser for output if decide to continue with this cli tool

# Can also write own tool to talk with Clair API
