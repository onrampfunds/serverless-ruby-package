set -euo pipefail

pushd __tests__/demo_service

function test_version() {
  local version="${1}"

  echo "## BUILD PACKAGE FPOR RUBY ${version}"
  cp "serverless.${version}.yml" serverless.yml
  npx serverless package
  rm serverless.yml

  echo
  echo "## EXAMINE PACKAGE FOR RUBY ${version}"
  unzip -l .serverless/demo.zip

  echo "## VERIFY RUBY ${version} FUNCTION CAN LOAD DEPENDENCIES"
  #RUBY_IMAGE="amazon/aws-lambda-ruby:3.2" ./invoke-service.sh
  result=$(docker run --rm \
             --volume $(pwd):/var/task \
             --env RUBYLIB=/var/task \
             --entrypoint '/var/lang/bin/ruby' \
             "amazon/aws-lambda-ruby:${version}" \
             '-e require "handler"; puts hello(event:{},context:{})' )
  echo "${result}"
  local status_code=$(echo "${result}" | cut -c 15-17)
  echo "status_code: ${status_code}"

  if [ "${status_code}" != "200" ]; then
    echo "ERROR: status code was '${status_code} for ruby ${version}"
    exit 1
  fi

  rm .serverless/demo.zip
}

test_version "3.2"
test_version "2.7"
