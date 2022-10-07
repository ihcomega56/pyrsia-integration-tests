#!/usr/bin/env bash

# common setup
COMMON_SETUP='common-setup'
# docker compose file
DOCKER_COMPOSE_DIR="$REPO_DIR/bats/tests/resources/docker/docker-compose_auth_nodes.yml"
# docker mapping id
BUILD_SERVICE_DOCKER_MAPPING_ID="alpine:3.16"

setup_file() {
  load $COMMON_SETUP
  _common_setup_file "$DOCKER_COMPOSE_DIR"
}

teardown_file() {
  load $COMMON_SETUP
  _common_teardown_file
}

setup() {
    load $COMMON_SETUP
    _common_setup
    PYRSIA_CLI="$PYRSIA_TARGET_DIR/pyrsia"
}

@test "Testing the build service, docker (build docker image, inspect-log)." {
  # the build image request should fail on the non existing maven mapping ID
#  run "$PYRSIA_CLI" build docker --image "FAKE_IMAGE_NAME"
#  refute_output --partial  "successfully"
#
#  # confirm the artifact is not already added to pyrsia node
#  run "$PYRSIA_CLI" inspect-log docker --image $BUILD_SERVICE_DOCKER_MAPPING_ID
#  refute_output --partial $BUILD_SERVICE_DOCKER_MAPPING_ID
  # add authorize node
  _set_node_as_authorized "localhost:7889"

  # init the build
  run "$PYRSIA_CLI" build docker --image $BUILD_SERVICE_DOCKER_MAPPING_ID
  assert_output --partial "successfully"

  # waiting until the build is done => inspect logs available
  echo -e "\t- Building docker image $BUILD_SERVICE_DOCKER_MAPPING_ID - [$PYRSIA_CLI build docker --image $BUILD_SERVICE_DOCKER_MAPPING_ID], it might take a while..." >&3
  # shellcheck disable=SC2034
  for i in {0..40}
  do
    inspect_log=$($PYRSIA_CLI inspect-log docker --image $BUILD_SERVICE_DOCKER_MAPPING_ID)
    if [[ "$inspect_log" == *"$BUILD_SERVICE_DOCKER_MAPPING_ID"* ]]; then
      break
    fi
    sleep 5
  done

  #check if the logs contains the artifact info
  run echo "$inspect_log"
  assert_output --partial $BUILD_SERVICE_DOCKER_MAPPING_ID
  echo -e "\t- Docker image built successfully - $BUILD_SERVICE_DOCKER_MAPPING_ID" >&3
}