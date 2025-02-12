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

Here is the list of packages that were built and tested (but keep in mind that
just because a package isn't listed, doesn't mean it's not going to work!):

<details>
  <summary>Click to show package list</summary>

```

DBI

R6

RColorBrewer

RCurl

RSQLite

Rcpp

RcppEigen

arrow

askpass

backports

base64enc

bit

bit64

blob

broom

bslib

cachem

callr

cellranger

cli

clipr

collapse

colorspace

cpp11

crayon

curl

data_table

dbplyr

devtools

digest

dplyr

duckdb

evaluate

fansi

farver

fastmap

fontawesome

forcats

fs

gargle

generics

ggplot2

glue

gtable

haven

highr

hms

htmltools

htmlwidgets

httr

icosa

igraph

isoband

jquerylib

jsonlite

kit

knitr

labeling

later

lifecycle

lubridate

magrittr

memoise

mime

modelr

munsell

nloptr

openssl

openxlsx

pillar

pkgconfig

prettyunits

processx

progress

promises

ps

purrr

rJava

ragg

rappdirs

readr

readxl

rematch

rematch2

rlang

rmarkdown

rprojroot

rstan

rstudioapi

rvest

sass

scales

selectr

sf

shiny

stars

stringi

stringr

sys

systemfonts

terra

textshaping

tibble

tidyr

tidyselect

tidyverse

timechange

tinytex

tzdb

utf8

vctrs

viridisLite

withr

xfun

xlsx

xml2

yaml

zoo

```

</details>

These packages (and their direct dependencies) are guaranteed to build for the
listed dates and platforms below. This doesn't mean that other packages won't
work, only that I didn't test them. If you get a run-time error (meaning, you load
the package, try to use it, but get some error) then please open an issue.

Then I "update" R packages on these dates (thanks to the Posit CRAN snapshots!!):

* 2019, working and tested on amd64 Linux (can potentially work on Intel Macs,
but not Apple Silicon):
  - 2019-03-14: see https://github.com/rstats-on-nix/nixpkgs/tree/2019-03-14
  - 2019-05-05: see https://github.com/rstats-on-nix/nixpkgs/tree/2019-05-05
  - 2019-07-22: see https://github.com/rstats-on-nix/nixpkgs/tree/2019-07-22
  - 2019-12-19: see https://github.com/rstats-on-nix/nixpkgs/tree/2019-12-19

* 2020, working and tested on amd64 Linux (can potentially work on Intel Macs,
but not Apple Silicon):
  - 2020-03-12: see https://github.com/rstats-on-nix/nixpkgs/tree/2020-03-12
  - 2020-04-27: see https://github.com/rstats-on-nix/nixpkgs/tree/2020-04-27
  - 2020-06-07: see https://github.com/rstats-on-nix/nixpkgs/tree/2020-06-07
  - 2020-08-20: see https://github.com/rstats-on-nix/nixpkgs/tree/2020-08-20
  - 2020-10-30: see https://github.com/rstats-on-nix/nixpkgs/tree/2020-10-30

For the year 2020, collapse is always at 1.6.5, which is the earliest version
that we were able to compile for Nix.

* 2021, working and tested on amd64 Linux and Apple Silicon (can potentially work
on Intel Macs):
  - 2021-02-26: see https://github.com/rstats-on-nix/nixpkgs/tree/2021-02-26
  - 2021-04-01: see https://github.com/rstats-on-nix/nixpkgs/tree/2021-04-01
  - 2021-05-29: see https://github.com/rstats-on-nix/nixpkgs/tree/2021-05-29
  - 2021-08-03: see https://github.com/rstats-on-nix/nixpkgs/tree/2021-08-03
  - 2021-10-28: see https://github.com/rstats-on-nix/nixpkgs/tree/2021-10-28

The 2021 dates were particularly complicated to get to work on macOS, so we had
to make the following concession: the `nixpkgs` commit used as a basis is the
same as the one for January 2022 (mostly because support for Apple Silicon
before that was not quite there yet), and `{cpp11}` had to be updated from
version 0.4.0 to version 0.4.2, `{rstan}` from version 2.21.2 to version 2.21.3
and `{arrow}` is at version 9. `{isoband}` and `{textshaping}` also had to be
updated for the April and May dates. `{testthat}` also had to be updated from
3.0.2 to 3.0.4.

* 2022, working and tested on amd64 Linux and Apple Silicon (can potentially work
on Intel Macs):
  - 2022-01-16: see https://github.com/rstats-on-nix/nixpkgs/tree/2022-01-16
  - 2022-04-19: see https://github.com/rstats-on-nix/nixpkgs/tree/2022-04-19
  - 2022-06-22: see https://github.com/rstats-on-nix/nixpkgs/tree/2022-06-22
  - 2022-08-22: see https://github.com/rstats-on-nix/nixpkgs/tree/2022-08-22
  - 2022-10-20: see https://github.com/rstats-on-nix/nixpkgs/tree/2022-10-20
  - 2022-12-20: see https://github.com/rstats-on-nix/nixpkgs/tree/2022-12-20

For the year 2022, I use this commit of `nixpkgs` as a basis: https://github.com/NixOS/nixpkgs/commit/5dfcc4f9ab8c09516715e2d3052e7de3e41a98c1, but for the one in
December I use this one instead: https://github.com/NixOS/nixpkgs/commit/060f0dd496b10c5516de48977f268505a51ab116

* 2023, working and tested on amd64 Linux and Apple Silicon (can potentially work
on Intel Macs):
  - 2023-02-13: see https://github.com/rstats-on-nix/nixpkgs/tree/2023-02-13
  - 2023-04-01: see https://github.com/rstats-on-nix/nixpkgs/tree/2023-04-01
  - 2023-06-15: see https://github.com/rstats-on-nix/nixpkgs/tree/2023-06-15
  - 2023-08-15: see https://github.com/rstats-on-nix/nixpkgs/tree/2023-08-15
  - 2023-10-30: see https://github.com/rstats-on-nix/nixpkgs/tree/2023-10-30
  - 2023-12-30: see https://github.com/rstats-on-nix/nixpkgs/tree/2023-12-30

For the year 2023, I use this commit of `nixpkgs` as a basis:
https://github.com/NixOS/nixpkgs/commit/6da67309c6d13f6dde2f6608af883dd5f81316a1
for the February snapshot, this one for the April snapshot
https://github.com/NixOS/nixpkgs/commit/71fa8d5b8fb70f00f891cbf935860c81306d8b7c
and for the others this one:
https://github.com/NixOS/nixpkgs/commit/e529b7fed078a9054cc3ea6a4c305edeff1b1e9f
The 2023 snapshots deal with the MASS issue where some versions of MASS where
released in 2023 that depended on the (at the time) development version of R
(version 4.4.0 that got released in February 2024).

* 2024, working and tested on amd64 Linux and Apple Silicon (can potentially work
on Intel Macs):
  - 2024-02-29: see https://github.com/rstats-on-nix/nixpkgs/tree/2024-02-29
  - 2024-04-29: see https://github.com/rstats-on-nix/nixpkgs/tree/2024-04-29
  - 2024-06-14: see https://github.com/rstats-on-nix/nixpkgs/tree/2024-06-14
  - 2024-08-19: see https://github.com/rstats-on-nix/nixpkgs/tree/2024-08-19
  - 2024-10-01: see https://github.com/rstats-on-nix/nixpkgs/tree/2024-10-01
  - 2024-12-14: see https://github.com/rstats-on-nix/nixpkgs/tree/2024-12-14


For the year 2024, I use this commit of `nixpkgs` as a basis:
https://github.com/NixOS/nixpkgs/commit/bcd2f0016d4f4f23bce8ef040bae83b12020d1cd
for the February, April, June and October commit, and this one for the rest of
the year I've used my daily CRAN snapshots from
https://github.com/rstats-on-nix/nixpkgs/commits/r-daily by picking a suitable
date, and testing if the environment builds. If yes, then this becomes a
distinct branch.

After the 2024-12-14, there is a daily snapshot, but only Mondays get fixes,
so use other weekdays at your own risk.

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

My R package, [rix](https://docs.ropensci.org/rix/), generates expressions that
point to the `rstats-on-nix/nixpkgs` fork. If you don’t use {rix} to generate
expressions, shame on you, but you can still benefit from it by editing
your `default.nix` or flake input files like this:

```
let
 pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/refs/heads/2022-08-22.tar.gz") {};
```

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

Use cachix to setup the `rstats-on-nix` public cache, see the instructions to set
up Cachix 
[here](https://docs.ropensci.org/rix/articles/b1-setting-up-and-using-rix-on-linux-and-windows.html#using-the-determinate-systems-installer)
(ignore the ones about installing Nix).
