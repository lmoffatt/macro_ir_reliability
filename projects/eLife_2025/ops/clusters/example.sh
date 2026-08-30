#!/bin/bash
# Example cluster profile. Copy it, rename it after your site, and adjust.
#
# Source it from your interactive shell before building or submitting:
#
#     source projects/eLife_2025/ops/clusters/example.sh
#     which gcc g++ ninja cmake     # check the toolchain actually resolved
#
# The campaign behind the manuscript ran on Slurm clusters of this shape: a few
# hundred conventional CPU cores across ~30 two-socket nodes, no GPU, OpenHPC
# with environment modules. Nothing here needs a GPU or an interconnect beyond
# plain ethernet: the parallelism is one independent job per grid cell, with
# OpenMP inside each.

# The scripts expect to run from the repository root.
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)" || return 1

# --- toolchain ------------------------------------------------------------
# Adjust the module names to your site. What matters is what they provide:
#   a C++20 compiler (GCC 14 or 15 verified), BLAS + LAPACK, GSL,
#   CMake (3.25+ if you use the presets) and Ninja.
module purge
module load gnu14
module load mkl
module load gsl
module load ninja
module load cmake

# --- where things live ----------------------------------------------------
export PATH_MACRO="${PWD%/*}"
export CLUSTER=example

# Outputs are large. Point this at scratch, not at your home quota: a full
# figure-3 campaign writes on the order of 10 GB per algorithm. Note that many
# sites auto-delete scratch files after a fixed age, so move what you want to
# keep before it expires.
export SCRATCH_MACRO=/scratch/$(whoami)/macro_dr   # $(whoami): $USER is not always set

# --- BLAS dispatch --------------------------------------------------------
# Pick the vendor that matches your hardware. On mostly-Intel nodes, MKL in its
# SEQUENTIAL form is the right choice: the parallelism is taken at our level
# with OpenMP, so a threaded BLAS underneath oversubscribes the cores and slows
# the run down. On AMD or on a generic site, drop the line and let CMake's
# FindBLAS pick up the reference or OpenBLAS libraries.
export BLA_VENDOR=Intel10_64lp_seq

# --- scheduler ------------------------------------------------------------
# Default partition, overridable from the environment. Some sites also require
# an allocation to be named on every submission; if yours does, export ACCOUNT
# here and the dispatchers will pass it through as --account.
if [ -z "${PARTITION}" ]; then
    export PARTITION=batch
fi
