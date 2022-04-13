#!/bin/bash

# This hook is called with the following parameters:
#
# $1 -- Name of the remote to which the push is being done
# $2 -- URL to which the push is being done
#
# If pushing without using a named remote those arguments will be equal.
#
# Information about the commits which are being pushed is supplied as lines to
# the standard input in the form:
#
#   <local ref> <local sha1> <remote ref> <remote sha1>

changed_files=$(git diff --name-status master | awk '{print $2;}')
linters=()
# Printf '%s\n' "$var" is necessary because printf '%s' "$var" on a
# variable that doesn't end with a newline then the while loop will
# completely miss the last line of the variable.
while IFS= read -r filename
do
  if [ "${filename: -4}" == ".yml" ] || [ "${filename: -4}" == ".yaml" ]; then
    linters+=("lint-yaml")
  fi

  if [ "${filename: -3}" == ".sh" ]; then
    linters+=("lint-shell")
  fi

  if [ "${filename: -3}" == ".rb" ] || [ "${filename}" == "Vagrantfile" ]; then
    linters+=("lint-ruby")
  fi

  if [ "${filename: -3}" == ".py" ]; then
    linters+=("lint-python")
  fi

  if [[ "${filename}" =~ ansible ]]; then
    linters+=("lint-ansible")
  fi

  if [[ "${filename}" =~ helm_charts ]]; then
    linters+=("lint-helm")
  fi
done < <(printf '%s\n' "$changed_files")

# shellcheck disable=SC2207
sorted_unique_linters=($(echo "${linters[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

if [ ${#sorted_unique_linters[@]} -gt 0 ]; then
  echo "Going to run the following linters:" "${sorted_unique_linters[@]}"
  make "${sorted_unique_linters[@]}"
fi
