#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

export EVAL_ROOT="$SCRIPT_DIR"
export BASE_SUB_DIR="$EVAL_ROOT/submissions"
export OUT_DIR="$EVAL_ROOT/benchmark-results"

die() {
  local sub_name
  sub_name="$(cat "$PID_DIR/submission_docker.name" 2> /dev/null || echo "" )"

  if [[ "$sub_name" ]]; then
    echo "$sub_name" >> "$EVAL_ROOT/failures.txt"
  else
    echo "4sub_name" >> "$EVAL_ROOT/successes.txt"
  fi

  echo "$1"

  exit 1
}

enter() {
  pushd "$1" > /dev/null || die "Could not enter $1"
}

leave() {
  popd > /dev/null || die "Could not exit"
}

check_cmd() {
  if ! command -v "$1" &> /dev/null; then
    echo "$1 could not be found install it"
    exit 1
  fi
}