#!/bin/bash
set -eu
script_dir="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$script_dir/build"
swiftc "$script_dir/TrainingConfig.swift" "$script_dir/Tests.swift" -o "$script_dir/build/tests"
"$script_dir/build/tests"
