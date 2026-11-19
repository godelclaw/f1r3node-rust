#!/usr/bin/env bash
set -euo pipefail

if [[ $# != 2 || ( $1 != petta && $1 != he ) ]]; then
    printf 'Usage: %s petta|he FILE.metta\n' "$0" >&2
    exit 2
fi

dialect=$1
document=$2
cli=${RHOLANG_CLI:-rholang-cli}
directory=$(cd -- "$(dirname -- "$0")" && pwd)
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT

{
    cat "$directory/reader.rho"
    printf '\n|\n'
    cat "$directory/evaluator.rho"
    printf '\n|\n'
    cat "$directory/render.rho"
    printf '\n| @"__METTA_SOURCE"!("'
    LC_ALL=C od -An -v -tx1 < "$document" | tr -d '[:space:]'
    printf '", "%s")\n' "$dialect"
} > "$scratch/program.rho"

if ! "$cli" --unmatched-sends-only --data-dir "$scratch/store" "$scratch/program.rho" > "$scratch/reply"; then
    tail -n 30 "$scratch/reply" >&2
    exit 1
fi

awk '
    /^Errors received during evaluation:/ { runtime_error = 1 }
    /^Storage Contents:/ { storage = 1 }
    !storage { next }
    /^"__METTA_ERROR"!/ {
        print "MeTTa reader error (byte offset and message) " $0 > "/dev/stderr"
        error = 1
    }
    /^"__METTA_DONE"!\([0-9]+\)( \|)?$/ {
        line = $0
        sub(/^"__METTA_DONE"!\(/, "", line)
        sub(/\).*/, "", line)
        count = line + 0
        completions++
    }
    /^"__METTA_OUT"!\([0-9]+, "[0-9a-f]+"\)( \|)?$/ {
        line = $0
        sub(/^"__METTA_OUT"!\(/, "", line)
        split(line, columns, /, "/)
        index_no = columns[1] + 0
        sub(/"\).*/, "", columns[2])
        if (index_no in frames || length(columns[2]) % 2 != 0) {
            error = 1
        }
        frames[index_no] = columns[2]
        replies++
    }
    END {
        if (error) exit 1
        if (runtime_error || completions != 1 || replies != count) {
            print "Rholang did not return a complete set of MeTTa replies" > "/dev/stderr"
            exit 1
        }
        for (i = 0; i < count; i++) {
            if (!(i in frames)) {
                print "Missing MeTTa reply " i > "/dev/stderr"
                exit 1
            }
        }
        for (i = 0; i < count; i++) print frames[i] "0a"
    }
' "$scratch/reply" > "$scratch/frames.hex"
xxd -r -p "$scratch/frames.hex"
