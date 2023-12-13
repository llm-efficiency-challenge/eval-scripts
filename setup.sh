#!/usr/bin/env bash

source ./utils.sh

git_clone() {
  git clone "$1"
}

setup_docker_network() {
  local num_gpus="$1"
  for isolation in $(seq 1 "$num_gpus"); do
    if ! docker network inspect "llm_eval_$isolation" > /dev/null 2>&1 ; then
      docker network create "llm_eval_$isolation" || die "Unable to create llm-eval docker network"
    fi
  done
}

main() {
  if [[ $# -ne 1 ]]; then
      die "Usage $0: [number-gpus]"
  fi

  check_cmd curl
  check_cmd docker
  check_cmd git

  git_clone "git@github.com:llm-efficiency-challenge/private-helm.git"

  enter private-helm
  git checkout neurips_eval
  leave

  ./build-eval-container.sh || die "Cannot build the eval container"
  setup_docker_network "$2"

  echo "Make sure submissions are present in submissons"
}

main "$@"
