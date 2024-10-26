# Recurrent snapshots of CRAN for nixpkgs

## Intro

This repository contains the necessary scripts to get CRAN snapshots for
`nixpkgs` at specific dates.

I forked upstream `nixpkgs` for this: https://github.com/rstats-on-nix/nixpkgs

The reason being that I wanted to backport fixes for R packages but also
for their dependencies, especially for macOS.

For a given date, the script from this repo checkouts a commit from upstream
`nixpkgs`, backports fixes, bumps the CRAN and Bioconductor packages, and then
creates a new branch and pushes to the `rstats-on-nix/nixpkgs` fork.

Each push to `rstats-on-nix/nixpkgs` starts a build in
`rstats-on-nix/build_tree`. A `default.nix` defining an environment with popular
packages and packages that are complicated to build gets built on Github Actions
for Linux and macOS (arm64).

For the year 2022, I use this commit of `nixpkgs` as a basis:
https://github.com/NixOS/nixpkgs/commit/5dfcc4f9ab8c09516715e2d3052e7de3e41a98c1

Then I "update" R packages on these dates (thanks to the Posit CRAN snapshots!!)

Dates working on linux and aarch64-darwin (M-series of apple computers)

- 2022-01-16: see https://github.com/rstats-on-nix/nixpkgs/commit/7d73fd6e94000f1a5bce2ed8f1852ba848da554d
- 2022-04-19: see https://github.com/rstats-on-nix/nixpkgs/commit/dba26d320a08bb9b72ba5f42472f26eebcab0ab4
- 2022-06-22: see https://github.com/rstats-on-nix/nixpkgs/commit/acfd0cc7dce72f9853c8aa4cb8903149485a4b71
- 2022-08-22: see https://github.com/rstats-on-nix/nixpkgs/commit/375791e66932da7734e13202e7a7c5999b34f50d
- 2022-10-20: see https://github.com/rstats-on-nix/nixpkgs/commit/fd313e8ac4868fc3fab6c98137fc43c36f3d985a
- 2022-12-20: see
  https://github.com/rstats-on-nix/nixpkgs/commit/b5a206e864a6b103891fe85c40e5c0bdc852e27e
  (for this CRAN snapshot, this `nixpkgs` commit was used as a basis:
  060f0dd496b10c5516de48977f268505a51ab116

For the year 2023, I use his commit of `nixpkgs` as a basis:
https://github.com/NixOS/nixpkgs/commit/6da67309c6d13f6dde2f6608af883dd5f81316a1
for the February snapshot, this one for the April snapshot
https://github.com/NixOS/nixpkgs/commit/71fa8d5b8fb70f00f891cbf935860c81306d8b7c

Dates working on linux and aarch64-darwin (M-series of apple computers)

- 2023-02-13: see https://github.com/rstats-on-nix/nixpkgs/commit/ed82b127e22e83cefc7b5e624d40f833ef44969a
- 2023-04-01: see https://github.com/rstats-on-nix/nixpkgs/commit/755f90f8210ef848882e1865359e957a7876e3da

For each date, the right version of R is built as well. Packages listed in the
`default.nix` are guaranteed to build, which should cover many use cases, but
this doesn't mean that other packages won't work. If you need a package at one
of these dates, but it doesn't work, feel free to open an issue.

## FAQ

- Why not use upstream `nixpkgs`?

Upstream `nixpkgs` doesn't contain all versions of all R packages, and some
packages can stay in a broken state for quite some time before they're fixed.
Sometimes, even some R versions are not available, when these get updated too
quickly. So I decided to start the `rstats-on-nix/nixpkgs` fork which builds
upon a state of `nixpkgs` that contains several useful fixes, and backport
R specific fixes as well. This is especially important for macOS, so the
`rstats-on-nix/nixpkgs` fork should be much more macOS-friendly than upstream
if you need older versions of packages or R.

- How do I use this?

For now there is no easy way to use this. You can define an environment and
point to the fork like so in your `default.nix`:

```
let
 pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/refs/heads/2022-08-22.tar.gz") {};
```

which will build the environment at that date. At some point I will include
a way to use this with [rix](https://docs.ropensci.org/rix/).

- Why only these dates?

I tried to pick dates that cover all versions of R, Bioconductor, and main CRAN
packages like the ones from `{tidyverse}`. I initially planned to this daily, or
weekly, but realized I would end up with so many binaries that no one would end
up using that it wasn't really worth it. If you need a specific date though,
open an issue, and I'll do it for that date.

- Why does it take hours to build the environment on my computer?

This is because many of these older packages are not in the public NixOS binary
cache, so you have to build everything locally. I'm looking into setting up a
public cache for this fork, in the meantime, I recommend you build the packages
on Github Actions and cache the binaries using Cachix as explained
[here](https://docs.ropensci.org/rix/articles/z-binary_cache.html).
