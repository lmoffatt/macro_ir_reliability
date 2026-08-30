# macro_ir_reliability

Code and analysis pipeline behind

> **Likelihood approximations distort the ion channel kinetic information in
> macroscopic currents**
> Luciano Moffatt

This record: <https://doi.org/10.5281/zenodo.22168409>
(all versions: <https://doi.org/10.5281/zenodo.22168408>)

It contains the C++20 engine that computes the likelihood of a macroscopic
patch-clamp recording under the MacroIR family of algorithms, the run scripts
that drove the simulation campaign, and the R notebooks that turn the campaign
output into the manuscript figures.

The raw and intermediate data are too large to live here. They are deposited
separately, and you need them to rebuild the figures:

> **Data record: <https://doi.org/10.5281/zenodo.22167744>**

See "Getting the data" below.

Software heritage: MacroIR was introduced in Moffatt & Pierdominici-Sottile,
*Bayesian inference of functional asymmetry in the homotrimeric ligand-gated ion
channel P2X2*, Communications Biology (2025), whose code deposit is
`github.com/lmoffatt/macro_dr_submission`. This deposit supersedes it for the
present manuscript.

## Layout

| path | what it is |
|---|---|
| `include/`, `src/` | the program: public headers and translation units |
| `legacy/` | header-only, and where most of the numerics live. It is part of the build |
| `tests/`, `third_party/catch2/` | test suite and its vendored framework |
| `CMakeLists.txt`, `cmake/`, `tools/` | build system |
| `projects/eLife_2025/ops/` | the `.macroir` run programs and the dispatchers that launch them |
| `projects/eLife_2025/figures/paper_both/` | the R notebooks that draw every figure, and the rendered figures themselves |
| `projects/eLife_2025/runs/` | one ledger per launched run: the script as executed, plus its metadata |
| `provenance/` | the four code states used across the campaign, and what each produced |

`legacy/` is not dead code. `CMakeLists.txt` globs `legacy/*.h` into the core
target and puts it on the include path, so removing it breaks the build silently
rather than loudly.

## Dependencies

```
sudo apt-get install -y build-essential cmake ninja-build libblas-dev liblapack-dev libgsl-dev
```

- A C++20 compiler. Concepts are used throughout; C++23 is not required. Verified
  toolchains: GCC 14.3, 15.1 and 15.3. No lower bound has been tested, so if you
  are on GCC 11 or 12 expect to find out something we did not.
- CMake 3.25 or newer if you use the presets, because `CMakePresets.json`
  declares preset format version 6. The preset-free route below works with 3.18.
- BLAS and LAPACK. Reference netlib is fine. Only the libraries are needed, not
  their headers: the Fortran symbols are declared directly in
  `legacy/lapack_headers.h`. The vendor is selectable through `BLA_VENDOR`.
- GSL, headers included, for `gsl_integration_qagi`.
- Catch2 is vendored, amalgamated, and needs no network.

For the figures, R with `tidyverse`, `patchwork`, `data.table`, `scales`,
`knitr`, `rmarkdown`, and Cairo (three notebooks render through `cairo_pdf`).
Nothing pins versions and there is no `renv.lock`. The machine of record ran
R 4.6.1, ggplot2 4.0.3, patchwork 1.3.2, data.table 1.18.4, rmarkdown 2.30.

## Build

Use the preset-free route. `CMakePresets.json` hard-codes `/usr/bin/gcc` and
`/usr/bin/g++`, so the presets fail on any toolchain supplied by environment
modules or Homebrew.

```
cmake -S . -B build/gcc-release -G Ninja -DCMAKE_BUILD_TYPE=Release
```

```
cmake --build build/gcc-release -j 2
```

```
ctest --test-dir build/gcc-release -V
```

The `-j 2` is deliberate. `src/core/likelihood.cpp` and
`src/cli/command_manager.cpp` are heavy template translation units that peak near
16 GB of resident memory each, and they take three to five minutes apiece on a
current server core. Building with the default job count will exhaust a 16 GB
machine. If you only want the binary and not the tests:

```
cmake -S . -B build/gcc-release -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF
```

The executable is `build/gcc-release/macrodr_cli`.

One rough edge we did not want to paper over: the install rule uses
`CMAKE_INSTALL_INCLUDEDIR` before `GNUInstallDirs` is included, so
`cmake --install` tries to write to an absolute path at the filesystem root.
Build in place instead of installing.

This tree has been checked to configure from scratch, on its own, with nothing
but the packages listed above. It compiles the same 23 translation units and sees
the same 69 `legacy/` headers as the working repository it was taken from.

## Running the program

The program takes `.macroir` files. A `.macroir` is not a configuration file, it
is a small typed program executed top to bottom. Calls such as `axis(...)` and
`indexed_*_by(...)` lift a computation over a Cartesian grid and become columns
in the output CSVs. Each script begins with a header naming the bindings it
expects.

Bindings are injected on the command line as `--key=value`, and they **must come
before the script path** or they are silently ignored. `projects/eLife_2025/ops/README.md`
has the full grammar.

A worked example, chosen because it is one of the two lanes with an explicit seed
and therefore actually reproducible. The working directory matters, since the
script writes its output relative to it:

```
cd projects/eLife_2025
```

```
../../build/gcc-release/macrodr_cli ops/local/figure_3_time.macroir
```

This writes ten per-step dumps of about 1 GB each into `figures/data/`, and
snapshots what it ran into `runs/<timestamp>/`. Note that a comment inside the
script itself suggests invoking from the repository root; that is wrong, and the
run ledgers are the authority on where each run was actually launched.

The grid lanes are cluster jobs. `ops/slurm/` holds the dispatchers, and
`ops/local/run_figure_3_G_local.sh` is a no-Slurm twin for a smoke test.

## Getting the data

Download the companion data record, <https://doi.org/10.5281/zenodo.22167744>
(ten archives, 529 MB compressed, 7.3 GB unpacked). Its archives carry their own
paths, so unpacking them all into `projects/eLife_2025/figures/` reconstructs the
layout the notebooks expect:

```
cd projects/eLife_2025/figures
```

```
for z in /path/to/data_record/*.zip; do unzip -q -n "$z"; done
```

That gives you `data/1c2ae6f/`, `data/87889e6/`, `data/0ffbda7/`, `data/1f7138b/`,
`data/a202e03/`, `data/433ed13/`, `data/82b956f/`, `data/digest/` and
`figure_4_source_data/`. Do not rename them: every notebook hard-codes those
names. They are the git hashes of the code state that wrote each set, and row 1
of every CSV carries the same stamp. The first five are the *gaussian* anchor and
are what the published figures read; `433ed13` is the *numeric* anchor that
`figure_2.Rmd` switches to when `ANCHOR == "numeric"`.

Regenerating the data instead of downloading it is not an option for most of it.
Four of the five directories were produced with `seed = 0`, which in this
codebase means "draw from the system entropy source", and the drawn value was
never recorded. `provenance/PROVENANCE.md` sets this out in full.

## Rebuilding the figures

There is no driver script. `render_figure_4_set.sh` exists but is stale; several
of the notebooks it names no longer exist. Run the notebooks by hand, from
`projects/eLife_2025/figures/paper_both/`, in this order.

First the Figure 3 digests, which reduce 10.9 GB of per-step dumps to about
107 MB of intermediate objects:

```
Rscript figure_3_digest.R LSE LSE_av0 LSE_g NR INR R MR VR IR
```

Then the notebooks:

```
Rscript -e 'rmarkdown::render("figure_1.Rmd")'
```

and likewise `figure_2.Rmd`, `figure_2_S1.Rmd`, `figure_3.Rmd`,
`figure_3_S1_S2.Rmd`, `figure_3_S3.Rmd`, then the Figure 4 set (`figure_4.Rmd`
and `figure_4_S1.Rmd` through `figure_4_S4.Rmd`), then `figure_5.Rmd`,
`figure_5_S1.Rmd`, `figure_5_S2.Rmd`, then `figure_7.Rmd`, then `figure_6.Rmd`,
and finally:

```
Rscript figure_6_S1.R
```

**The order is load-bearing and Figure 6 must come after Figure 5.** The Figure 4
and Figure 5 sets share an intermediate cache under
`projects/eLife_2025/figures/figure_4_source_data/`. The Figure 4 notebooks write
that cache from five data directories at four channel counts. `figure_6.Rmd`
rewrites the same files from three directories at eleven channel counts. The
Figure 5 notebooks read those CSVs directly, without sourcing the module that
checks the cache stamp, so they will silently draw whatever the last writer left
behind. Render Figure 6 out of order and Figure 5 is wrong without warning.

### One edit you have to make first

The scripts under `projects/eLife_2025/figures/in_progress/ir_reliability_20260828/`
address their inputs by absolute path. The author's home directory has been
replaced with a placeholder, so point it at your own checkout before running them:

```
grep -rl /PATH/TO/DEPOSIT . | xargs sed -i "s|/PATH/TO/DEPOSIT|$(pwd)|g"
```

Run that from the root of this repository. The notebooks under `paper_both/` do
not need it; they use relative paths and are run from their own directory.

## Which script draws which figure

| figure | notebook | main input |
|---|---|---|
| 1 | `figure_1.Rmd` | 9 loose CSVs in `data/` |
| 2 | `figure_2.Rmd` | 24 CSVs across all five data directories, one per member |
| 2-S1 | `figure_2_S1.Rmd` | two hard-coded IR files at `noise_0.05` |
| 3 | `figure_3.Rmd` | 8 digests from `data/digest/` |
| 3-S1, 3-S2 | `figure_3_S1_S2.Rmd` | 7 digests. One notebook, two outputs |
| 3-S3 | `figure_3_S3.Rmd` | 7 digests |
| 4, 4-S1..S4 | `figure_4*.Rmd` | the shared cache, built from ~3.3 GB of batteries |
| 5, 5-S1, 5-S2 | `figure_5*.Rmd` | the shared cache, read directly |
| 6 | `figure_6.Rmd` | the shared cache, rebuilt on a wider channel-count grid |
| 6-S1 | `figure_6_S1.R` | two digests under `figures/in_progress/ir_reliability_20260828/`, which are in this deposit |
| 7 | `figure_7.Rmd` | 143 pool files, no cache |

Two naming traps worth knowing before you go looking. The numbering of the
`.macroir` run scripts does not match the numbering of the notebooks: `figure_2.Rmd`
is fed by runs named `figure_3_mle*`. And inside `figure_3.Rmd`, the display label
`LSE` maps to the dump token `LSE_av0` while the label `ILSE` maps to the token
`LSE`.

## Known limits

- Four of the five data directories cannot be regenerated. See "Getting the data".
- Compute cost was not recorded, and neither was which cluster produced which
  directory.
- `macro_NMR` is a defective build that omits an interval-variance term.
  `macro_INR` is the correction. Both appear in the output; only the latter is used.
- The `a202e03` directory mixes a small smoke run in with real cells, so it must
  not be globbed indiscriminately.
- There is no `renv.lock`, so the R side is not version-pinned.

## License and citation

The program, its tests and its build system are GPL-3, as in `LICENSE`. The
vendored Catch2 under `third_party/catch2/` is Boost Software License 1.0. The
figures and the analysis notebooks under `projects/eLife_2025/figures/` are
CC-BY, as is the companion data record.

Cite both this record and the data record. `CITATION.cff` in the repository root
carries the machine-readable form, which is what GitHub's "Cite this repository"
button and most reference managers read.

The data record is <https://doi.org/10.5281/zenodo.22167744>. This software
record is <https://doi.org/10.5281/zenodo.22168409>; cite that one, which points
at this exact tree, rather than the all-versions DOI, which resolves to whatever
is newest.
