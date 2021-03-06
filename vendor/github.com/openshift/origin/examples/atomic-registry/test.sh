#!/bin/bash

###
# basic install and run test for atomic registry quickstart image
# run with "uninstall" argument to test tear down after test
###

# $1 is optional hostname override

set -o errexit
set -o pipefail
set -x

TEST_IMAGE=atomic-registry-quickstart

# we're going to use this for testing
# node ports aren't working with boxes default hostname localdomain.localhost
LOCALHOST=${1:-`hostname`}
CMD="docker exec -it origin"

USER=mary
PROJ=mary-project

function test_push() {
  # login as $USER and do a basic docker workflow
  $CMD oc login -u ${USER} -p test
  $CMD oc new-project ${PROJ}
  TOKEN=$($CMD oc whoami -t)
  docker login -p ${TOKEN} -u unused -e test@example.com ${LOCALHOST}:5000
  docker pull busybox
  docker tag busybox ${LOCALHOST}:5000/${PROJ}/busybox
  docker push ${LOCALHOST}:5000/${PROJ}/busybox
  docker rmi busybox ${LOCALHOST}:5000/${PROJ}/busybox
  docker logout
}

function test_cannot_push() {
  # in shared mode...
  # we pull $USERS's image, tag and try to push
  # bob shouldn't be able to push
  $CMD oc login -u bob -p test
  TOKEN=$($CMD oc whoami -t)
  docker login -p ${TOKEN} -u unused -e test@example.com ${LOCALHOST}:5000
  docker pull ${LOCALHOST}:5000/${PROJ}/busybox
  docker tag ${LOCALHOST}:5000/${PROJ}/busybox ${LOCALHOST}:5000/${PROJ}/busybox:evil
  if docker push ${LOCALHOST}:5000/${PROJ}/busybox:evil; then
    echo "registry-viewer user should not have been able to push to repo"
    docker logout
    exit 1
  fi
  docker rmi ${LOCALHOST}:5000/${PROJ}/busybox ${LOCALHOST}:5000/${PROJ}/busybox:evil
  docker logout
}

# first we need to patch for the vagrant port mapping 443 -> 1443
$CMD oc login -u system:admin
$CMD oc patch oauthclient cockpit-oauth-client -p  '{ "redirectURIs": [ "https://'"${LOCALHOST}"':1443" ] }'

test_push
test_cannot_push
