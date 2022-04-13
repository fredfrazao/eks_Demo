#!/bin/bash

if [[ -z "$1" ]]; then
  echo "Provide tool name to check"
  exit 1
fi

cmd_out=$(command -v "${1}")
if [[ -z ${cmd_out} ]]; then
  echo "Tool [${1}] is not found"
  exit 1
fi
echo "Tool [${1}] path: ${cmd_out}"
