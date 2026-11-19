# MeTTa on `rholang-cli`

This example reads MeTTa source and evaluates a reflective PeTTa or MeTTa HE fragment in Rholang. It uses the local `rholang-cli` and a fresh tuple space for each file.

## Run the example

From the repository root, build with the repository toolchain. The launcher uses Bash, standard Unix utilities, and `xxd`.

```sh
cargo build --locked --release -p rholang --bin rholang-cli
RHOLANG_CLI=./target/release/rholang-cli \
  ./rholang/examples/metta/run.sh petta ./rholang/examples/metta/example.metta
```

The launcher defaults to `rholang-cli` on `PATH`. Pass `he` in place of `petta` to select HE evaluation rules.

The example returns one answer bag per directive in source order.

```text
[()]
[(later)]
[11, 11, 12]
[]
[()]
```

The first query sees an empty Space. The second sees the declared fact. The fourth directive completes with zero answers. The last directive returns one empty tuple.

## Implementation and scope

- [`reader.rho`](reader.rho) reads UTF-8 bytes, parses MeTTa terms, and lowers each top-level form to a declaration or query.
- [`evaluator.rho`](evaluator.rho) handles ordered declarations, rule evaluation, unification, branch multiplicity, and Space operations.
- [`render.rho`](render.rho) writes the answer bags. [`run.sh`](run.sh) passes the source and replies as hex so quotes, escapes, and newlines survive transport through the CLI.

The PeTTa and HE modes share the evaluator and use distinct staging, removal, and error rules. The tested fragment includes recursive equations, conjunctive Space queries, and state operations. The reader accepts signed 64-bit integer literals and reports an error for floating-point literals. This is a reflective example for a subset of each dialect.

Run the local smoke checks after building the CLI.

```sh
RHOLANG_CLI=./target/release/rholang-cli ./rholang/examples/metta/check.sh
```
