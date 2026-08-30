# Provenance of the production runs

This deposit is a single snapshot of the source tree. The figures in the
manuscript were not all produced by that one snapshot: four successive states of
the code were used over the campaign. This file records which states those were,
how they differ, and what each produced.

## The four states

| label | date | commit message | commit in `macro_dr` (as originally recorded) |
|---|---|---|---|
| `433ed13` | 2026-06-17 | fig3: adaptive Gauss-Newton tolerance (tight 1e-8 first N iters, then relaxed 1e-4) | `433ed13f19…` |
| `1c2ae6f` | 2026-07-05 | gaussian also for corrected covariance | `1c2ae6f579…` |
| `87889e6` | 2026-07-11 | claude script. minor modification .gitignore | `87889e62a3…` |
| `0ffbda7` | 2026-07-21 | fix: legacy call sites for the new variance_form template parameter | `0ffbda76a3…` |

Those commit identifiers no longer resolve in the `macro_dr` repository. Its
history was rewritten on 2026-08-29 to remove a file that should never have been
committed, which changed every commit hash from 2026-06-04 onward. The labels are
kept because the run output directories on disk are named after them and the
analysis scripts hard-code those names.

The snapshot in the root of this deposit is the `0ffbda7` state. Its `include/`,
`src/` and `tests/` trees are byte-identical to that commit.

## How the four states differ

Across all four, only three files change. Everything else is identical.

```
provenance/<label>/likelihood.h            (include/macrodr/cmd/likelihood.h)
provenance/<label>/command_manager.cpp     (src/cli/command_manager.cpp)
provenance/<label>/likelihood.cpp          (src/core/likelihood.cpp)
```

Content identity across the four, by file:

| file | 433ed13 | 1c2ae6f | 87889e6 | 0ffbda7 |
|---|---|---|---|---|
| `likelihood.h` | A | B | B | C |
| `command_manager.cpp` | A | B | B | C |
| `likelihood.cpp` | A | B | C | D |

The step from `433ed13` to `1c2ae6f` adds 720 lines across the three files and is
the Gaussian treatment of the corrected covariance. `1c2ae6f` to `87889e6` is 51
lines in `likelihood.cpp` alone. `87889e6` to `0ffbda7` is a refactor introducing
the `variance_form` template parameter, 266 insertions and 125 deletions, which
touches legacy call sites.

To rebuild any earlier state, copy the three files from its `provenance/`
directory over the corresponding paths in the snapshot and rebuild.

## Which state produced which output

The run outputs live in directories named after the code state that wrote them.
Line 1 of every output CSV carries the build's git hash, and the directory names
match those stamps. The manuscript figures read five such directories:

| directory | what it holds |
|---|---|
| `1c2ae6f` | the NR, R, MR and IR batteries at `nch_100_nsim_10000_noise_0.1`, and the `nch_10_nsim_10000` IR pool |
| `87889e6` | batteries feeding the Figure 4 and Figure 7 sets |
| `0ffbda7` | the ILSE arm, the VR arm, and the `nch_10_nsim_100000` IR cloud |
| `1f7138b` | the INR arm |
| `a202e03` | the LSE arm and the differenced-Fisher lane |
| `433ed13` | the numeric anchor: the same grid computed against the numerical Fisher information rather than the Gaussian one |

The first five are what `figure_2.Rmd` calls the *gaussian* anchor, and they are
the search path for the published figures. `433ed13` is the *numeric* anchor, the
alternative branch of the same notebook (`ANCHOR == "numeric"`). It holds no `_G`
files, so it necessarily uses the numerical Fisher information at the simulation
parameters. The two anchors agree in shape and magnitude, and the comparison is
discussed in the Figure 5 caption. Both are in the data record.

Note that a directory name is a scratch grouping, not the provenance record. The
dispatcher isolates output per engine commit, so an algorithm added later lands
in its own directory; what identifies the code that wrote a given result is the
git hash stamped in row 1 of the CSV itself.

Two directories carry a caveat. `a202e03` mixes an `nsim_8` VR smoke run in with
real cells, so it must not be globbed indiscriminately. And `82b956f`, which the
IR-reliability producers read, is not recorded in any provenance document and its
origin is unestablished; its outputs are included here as tracked digests, but the
chain that produced them cannot be re-run from this deposit alone.

## Reproducibility of the runs themselves

Most of the campaign cannot be reproduced bit for bit, and this is a property of
the runs, not of the deposit.

`figure_3_mle_G.macroir` and `figure_4.macroir` pass `seed = 0`. In this codebase
that value is a sentinel meaning "draw from `std::random_device`"
(`legacy/mcmc.h:37-45`). The drawn value is written to no output file and to no
run ledger, so it is gone. The four directories `1c2ae6f`, `87889e6`, `0ffbda7`
and `1f7138b` were produced this way.

Two lanes do carry explicit seeds and can be re-run to the same numbers:
`figure_3_time.macroir` (seed 20260722) and the differenced-Fisher lane that
produced `a202e03` (`SIM_SEED = 20260814`).

This is why the companion data record exists. For the unseeded directories it is
not a convenience, it is the only copy.

## Run ledgers

`projects/eLife_2025/runs/` holds one directory per launched run, each with the
`script.macroir` as executed and a `meta.json`. These are the only surviving
record of the `--key=value` bindings injected on the command line, which do not
appear anywhere in the scripts themselves. The `cwd` field records the working
directory the run was launched from, which matters because the scripts write
their output relative to it.

Compute cost was not recorded. No Slurm accounting output was kept, so there is
no figure for how long the campaign took or on which cluster each directory was
produced.
