#!/usr/bin/env bash
set -euo pipefail

dir=$(cd -- "$(dirname -- "$0")" && pwd)
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT

"$dir/run.sh" petta "$dir/example.metta" > "$scratch/actual"
cat > "$scratch/expected" <<'EOF'
[()]
[(later)]
[11, 11, 12]
[]
[()]
EOF
diff -u "$scratch/expected" "$scratch/actual"

cat > "$scratch/reader.metta" <<'EOF'
! "caf\u00e9, \u03BB \uD83D\uDE00\n\"\\"
! "\u0000"
! -9223372036854775808
! 9223372036854775807
EOF
"$dir/run.sh" he "$scratch/reader.metta" > "$scratch/actual"
cat > "$scratch/expected" <<'EOF'
["café, λ 😀\n\"\\"]
["\u0000"]
[-9223372036854775808]
[9223372036854775807]
EOF
diff -u "$scratch/expected" "$scratch/actual"

for source in '! (a' '! 9223372036854775808' '! 1.25' '! "\uD800"'; do
    printf '%s\n' "$source" > "$scratch/bad.metta"
    if "$dir/run.sh" petta "$scratch/bad.metta" > "$scratch/actual" 2> "$scratch/error"; then
        printf 'Accepted malformed or unsupported source %s\n' "$source" >&2
        exit 1
    fi
    test ! -s "$scratch/actual"
    grep -q '^MeTTa reader error' "$scratch/error"
done
printf 'MeTTa example and reader checks passed\n'
