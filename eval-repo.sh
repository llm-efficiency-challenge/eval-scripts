#!/usr/bin/env bash

source ./utils.sh

cleanup() {
  local llm_eval_container
  llm_eval_container="$(cat "$PID_DIR/llm_docker.name")"
  docker stop "$llm_eval_container"

  local sub_name
  sub_name="$(cat "$PID_DIR/submission_docker.name")"
  docker stop "$sub_name"

  kill -15 "$(cat "$PID_DIR/submission_log.pid")"
  sleep 10

  docker rmi "$sub_name"
}

trap cleanup EXIT
trap cleanup SIGINT

submission_name() {
  echo "${1//\//_}" | tr '-' '_' | tr '[:upper:]' '[:lower:]'
}

gaurentee_dirs() {
  mkdir -p "$PID_DIR"
  mkdir -p "$BASE_SUB_DIR"
  mkdir -p "$OUT_DIR"
}

build_submission() {
  local hardware_track="$1"
  local submission="$2"

  local sub_name
  sub_name=$(submission_name "$submission")

  enter "$BASE_SUB_DIR/$hardware_track/$submission"

  docker build -t "$sub_name" . 2>&1     \
    | tee "$OUT_DIR/$sub_name-build.log" \
    || die "Could not build $sub_name"

  leave
}

healthcheck() {
  local port="$1"

  local max_retries=10      # Maximum number of retries
  local retry_delay=120     # Delay between retries in seconds

  local url="http://localhost:$port/process"
  local data='{"prompt": "The capital of France is "}'
  local accept='Content-Type: application/json'

  for ((i = 0; i < max_retries; i++)); do
    sleep $retry_delay
    if curl -q -X POST -H "$accept"  -d "$data" "$url" ; then
      return 0
    else
      echo "Retrying healthcheck (Attempt $i)..."
    fi
  done

  die "Could not healthcheck after $max_retries retries"
}

run_submission() {
  local submission="$1"
  local isolation="$2"
  local gpus="$3"

  local network
  local sub_name

  network="llm_eval_$isolation"
  sub_name=$(submission_name "$submission")

  local port="808$isolation"

  docker run             \
    -d                   \
    --rm                 \
    --name "$sub_name"   \
    --network "$network" \
    --runtime=nvidia     \
    --gpus "$gpus"       \
    -p "$port:80"        \
    "$sub_name" || die "Could not run $sub_name"

  echo "$sub_name" > "$PID_DIR/submission_docker.name"

  ( docker logs -f "$sub_name" > "$OUT_DIR/$sub_name-run.log" 2>&1 ) > /dev/null &
  echo "$!" > "$PID_DIR/submission_log.pid"

  healthcheck "$port"
}

get_ip() {
  docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$1"
}

run_helm() {
  local submission="$1"
  local isolation="$2"
  local config="$3"

  local sub_name
  local ip
  local llm_eval_name="llm_eval_${isolation}"

  sub_name=$(submission_name "$submission")
  ip="$(get_ip "$sub_name")"

  echo "$llm_eval_name" > "$PID_DIR/llm_docker.name"

  docker run                                    \
    --rm                                        \
    --name "$llm_eval_name"                     \
    --env HELM_HTTP_MODEL_BASE_URL="http://$ip" \
    --network "$llm_eval_name"                  \
    -v "$OUT_DIR:/results"                      \
    llm-eval                                    \
    /helm/do-run.sh "$config" "$sub_name" || die "Could not run helm"
}

main() {
  local gpus="$1"
  local isolation="$2"
  local hardware_track="$3"
  local config="$4"
  local submission="$5"

  # Isolate for specific runs on multi-gpus
  export PID_DIR="$EVAL_ROOT/state/$isolation"

  if [[ $# != 5 ]]; then
    echo "Usage $0: gpu-spec isolation hardware-track config repo submission"
    exit 1
  fi

  gaurentee_dirs

  build_submission "$hardware_track" "$submission"
  run_submission "$submission" "$isolation" "$gpus" 
  run_helm "$submission" "$isolation" "$config"
}

main "$@"