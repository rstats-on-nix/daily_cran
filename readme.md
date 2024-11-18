# Dated snapshots of CRAN for nixpkgs

## Intro

This repository contains the necessary scripts to get CRAN snapshots for
`nixpkgs` at specific dates.

I forked upstream `nixpkgs` for this: https://github.com/rstats-on-nix/nixpkgs

The reason being that I wanted to backport fixes for R packages but also
for their dependencies, especially for macOS.

For a given date, the script from this repo checkouts a commit from upstream
`nixpkgs`, backports fixes, bumps the CRAN and Bioconductor packages, and then
creates a new branch and pushes to the `rstats-on-nix/nixpkgs` fork.

Each push to `rstats-on-nix/nixpkgs` starts a build in the
`rstats-on-nix/build_tree` repository. A `default.nix` defining an environment
with popular packages and packages that are complicated to build gets built on
Github Actions for Linux (amd64 and arm64) and macOS (arm64).

Then I "update" R packages on these dates (thanks to the Posit CRAN snapshots!!):

* 2021:
  - 2021-04-01: see https://github.com/rstats-on-nix/nixpkgs/commit/54c1c5f001d39e99667d9c7c8b1f9b7831140e74
  - 2021-05-29: see https://github.com/rstats-on-nix/nixpkgs/commit/853f17ea45642fffdf1531eacca229fbe9c28730
  - 2021-08-03: see https://github.com/rstats-on-nix/nixpkgs/commit/f190b349565535c05ceef0c9d427a3e7a1806cf4
  - 2021-10-28: see https://github.com/rstats-on-nix/nixpkgs/commit/88567ee830e6a273c05294e445df9cba10aed111

The 2021 dates were particularly complicated to get to work on macOS, so we had
to make the following concession: the `nixpkgs` commit used as a basis is the
same as the one for January 2022 (mostly because support for Apple Silicon before
that was not quite there yet), and `{cpp11}` had to be updated from version
0.4.0 to version 0.4.2, `{rstan}` from version 2.21.2 to version 2.21.3 and
`{arrow}` is at version 9. `{isoband}` and `{textshaping}` also had to be updated
for the April and May dates.

* 2022:

  - 2022-01-16: see https://github.com/rstats-on-nix/nixpkgs/commit/7d73fd6e94000f1a5bce2ed8f1852ba848da554d
  - 2022-04-19: see https://github.com/rstats-on-nix/nixpkgs/commit/dba26d320a08bb9b72ba5f42472f26eebcab0ab4
  - 2022-06-22: see https://github.com/rstats-on-nix/nixpkgs/commit/acfd0cc7dce72f9853c8aa4cb8903149485a4b71
  - 2022-08-22: see https://github.com/rstats-on-nix/nixpkgs/commit/375791e66932da7734e13202e7a7c5999b34f50d
  - 2022-10-20: see https://github.com/rstats-on-nix/nixpkgs/commit/fd313e8ac4868fc3fab6c98137fc43c36f3d985a
  - 2022-12-20: see https://github.com/rstats-on-nix/nixpkgs/commit/b5a206e864a6b103891fe85c40e5c0bdc852e27e

For the year 2022, I use this commit of `nixpkgs` as a basis: https://github.com/NixOS/nixpkgs/commit/5dfcc4f9ab8c09516715e2d3052e7de3e41a98c1, but for the one in
December I use this one instead: https://github.com/NixOS/nixpkgs/commit/060f0dd496b10c5516de48977f268505a51ab116

* 2023:

  - 2023-02-13: see https://github.com/rstats-on-nix/nixpkgs/commit/ed82b127e22e83cefc7b5e624d40f833ef44969a
  - 2023-04-01: see https://github.com/rstats-on-nix/nixpkgs/commit/755f90f8210ef848882e1865359e957a7876e3da
  - 2023-06-01: see https://github.com/rstats-on-nix/nixpkgs/commit/823018e017665e3dcac7b96c5745bb2e1d631340
  - 2023-08-15: see https://github.com/rstats-on-nix/nixpkgs/commit/084aa29838f755c47a838d2dd106006687d05175
  - 2023-10-30: see https://github.com/rstats-on-nix/nixpkgs/commit/8e2fc8d45be09a463587424a540f9b96cf08cbd3
  - 2023-12-30: see https://github.com/rstats-on-nix/nixpkgs/commit/b55b2a76cc631a5df6d308c8ac578ccc8c335513

For the year 2023, I use this commit of `nixpkgs` as a basis:
https://github.com/NixOS/nixpkgs/commit/6da67309c6d13f6dde2f6608af883dd5f81316a1
for the February snapshot, this one for the April snapshot
https://github.com/NixOS/nixpkgs/commit/71fa8d5b8fb70f00f891cbf935860c81306d8b7c
and for the others this one:
https://github.com/NixOS/nixpkgs/commit/e529b7fed078a9054cc3ea6a4c305edeff1b1e9f
The 2023 snapshots deal with the MASS issue where some versions of MASS where
released in 2023 that depended on the (at the time) development version of R
(version 4.4.0 that got released in February 2024).

* 2024:

  - 2024-02-29: see https://github.com/rstats-on-nix/nixpkgs/commit/f749e864e0f08ebd7040a467626331616267d088
  - 2024-04-29: see https://github.com/rstats-on-nix/nixpkgs/commit/ac0a00a1a31cc1c7d8e38a2553fa46330eecf73f
  - 2024-06-14: see https://github.com/rstats-on-nix/nixpkgs/commit/22bb52431cc29da70d37cea1af32f0365410c68b
  - 2024-10-01: see https://github.com/rstats-on-nix/nixpkgs/commit/bb702f4c7a89c9dcf0507e8fe1ded3877f8f9c8d

For the year 2024, I use this commit of `nixpkgs` as a basis:
https://github.com/NixOS/nixpkgs/commit/bcd2f0016d4f4f23bce8ef040bae83b12020d1cd
for the February, April, June and October commit, and this one for the rest of
the year I've used my daily CRAN snapshots from
https://github.com/rstats-on-nix/nixpkgs/commits/r-daily by picking a suitable
date, and testing if the environment builds. If yes, then this becomes a
distinct branch.



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

- Why use different commits of `nixpkgs` as basis? Wouldn't it be better to only
pick one?

Some R packages requires specific versions of specific development libraries, so
I need to pick a `nixpkgs` revision that contains these versions of these
libraries. Also, it can happen, especially for macOS, that some dependencies get
broken at certain dates, so I need to pick a date where these issues have been
fixed. For example `mesa` was marked as broken on darwin from 2023-05-29 until
2023-12-05 and `curl` must be on version 7 for R 4.2.2, so before a `nixpkgs`
revision before the 2023-03-20 had to be used. Another example was
`libspatialite` using a deprecated feature of one its dependencies, `libxml2`
which indirectly broke many R packages during the summer of 2024 for both Linux
and macOS. These situations are rather uncommon, but when they happen, oh boy.

- Why does it take hours to build the environment on my computer?

This is because many of these older packages are not in the public NixOS binary
cache, so you have to build everything locally. I'm looking into setting up a
public cache for this fork, in the meantime, I recommend you build the packages
on Github Actions and cache the binaries using Cachix as explained
[here](https://docs.ropensci.org/rix/articles/z-binary_cache.html).
