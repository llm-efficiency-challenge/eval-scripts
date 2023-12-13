#!/usr/bin/env bash

cd private-helm || exit
docker build -t llm-eval .