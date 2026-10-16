#!/usr/bin/env bash

declare -A versions

env="$1"

if [[ -z "$env" ]]; then
    echo "Usage: $0 <staging|production>"
    exit 1
fi

echo "$(date)"

while read -r line; do
    if [[ "$line" =~ /vulpes/ngi/${env}/([^/]+)/.*arteria- ]]; then
        version="${BASH_REMATCH[1]}"
        ((versions["$version"]++))
    fi
done < <(ps -ef)

for version in "${!versions[@]}"; do
    echo "Env version: $version"
done

if [[ ${#versions[@]} -eq 1 ]]; then
    echo "OK: all arteria services run from the same env"
elif [[ ${#versions[@]} -gt 1 ]]; then
    echo "WARNING: processes started from multiple envs"
else
    echo "WARNING: no arteria processes found for env ${env}"
fi

