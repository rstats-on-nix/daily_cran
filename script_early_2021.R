# Now I use what I did for august 2021 as a basis
# Don't use, simply checkout from august then bump in may
#
#library(git2r)
#library(stringr)
#library(data.table)
#library(dplyr)
#library(parallel)
#library(BiocManager)
#
#bioc_versions <- read.csv("bioc_versions.csv")
#r_versions <- read.csv("r_versions.csv")
#
#set_bioc_version <- function(target_date, bioc_versions){
#  bioc_versions |>
#    dplyr::arrange(desc(date)) |>
#    dplyr::mutate(date = as.POSIXct(date)) |>
#    dplyr::filter(target_date >= date) |>
#    head(1) |>
#    dplyr::pull(bioc_version)
#}
#
#set_r_version <- function(target_date, r_versions){
#  r_versions |>
#    dplyr::arrange(desc(date)) |>
#    dplyr::mutate(date = as.POSIXct(date)) |>
#    dplyr::filter(target_date >= date) |>
#    head(1) |>
#    dplyr::pull(r_version)
#}
#
target_date <- as.POSIXct("2021-04-01 12:00:00")
#
#bioc_version <- set_bioc_version(target_date, bioc_versions)
#r_version <- set_r_version(target_date, r_versions)
#
## 11 August 2021
#target_commit <- "4b88ab8c5cc3afd36e24224b16740082a91bd3f2"
#
## Set the local repository path
repo_path <- "../nixpkgs"
#
repo <- repository(repo_path)
#
target_date <- substr(target_date, 1, 10)
#
#system(paste0("cd ", repo_path, " && git reset --hard ", target_commit))
#
#previous_date <- "2021-08-03"
#
## Get latest default.nix to backport fixes
#system(paste0("cd ",
#              repo_path,
#              "/pkgs/development/r-modules/ && rm default.nix && wget https://raw.githubusercontent.com/rstats-on-nix/nixpkgs/refs/heads/",previous_date, "/pkgs/development/r-modules/default.nix"))
#
#
#system(paste0("cd ",
#              repo_path,
#              "/pkgs/development/r-modules/ && rm generate-r-packages.R && wget https://raw.githubusercontent.com/NixOS/nixpkgs/d44a08dd6574bfc8c701fd0bab02a01391a422f3/pkgs/development/r-modules/generate-r-packages.R"))
#
#system(paste0("cd ",
#              repo_path,
#              " && git apply ../daily_cran/fix_bioc_version.patch"))
#
#system(paste0("cd ",
#              repo_path,
#              paste0("/pkgs/development/r-modules/ && sed -i 's/REPLACE_BIOC_VERSION/\"", bioc_version, "\"/g' generate-r-packages.R")))
#
#
## Replace the repository with a snapshot from posit at target date
#file_path <- file.path(repo_path,
#                       "pkgs/development/r-modules/generate-r-packages.R")
#
#file_content <- readLines(file_path)
#
#old_string <- "https://cran.r-project.org/src/contrib/"
#
#new_string <- paste0("https://packagemanager.posit.co/cran/",
#                     target_date,
#                     "/src/contrib/")
#
#modified_content <- str_replace(file_content, old_string, new_string)
#
#writeLines(modified_content, file_path)
#
## Bump the tree
system(paste0("cd ",
              repo_path,
              "/pkgs/development/r-modules/ && Rscript generate-r-packages.R cran > new && mv new cran-packages.nix"))

system(paste0("cd ",
              repo_path,
              "/pkgs/development/r-modules/ && Rscript generate-r-packages.R bioc > new && mv new bioc-packages.nix"))

system(paste0("cd ",
              repo_path,
              "/pkgs/development/r-modules/ && Rscript generate-r-packages.R bioc-annotation > new && mv new bioc-annotation-packages.nix"))

system(paste0("cd ",
              repo_path,
              "/pkgs/development/r-modules/ && Rscript generate-r-packages.R bioc-experiment > new && mv new bioc-experiment-packages.nix"))

# .dev attribute from dependencies needs to be removed because it wasn't always
# used
system(paste0("cd ",
              repo_path,
              "/pkgs/development/r-modules/ && sed -i 's/\\.dev / /g' default.nix"))

# For some reason r_import is defined twice, but the one where
# name = r_import is wrong so let's get rid of that
system(paste0("cd ",
              repo_path,
              "/pkgs/development/r-modules/ && ",
              "sed -i '/r_import.*name=\"r_import\"/d' cran-packages.nix")
       )

# Get correct version of R for that day. It should be the same as the
# one in nixpkgs at that time most of the time
system(paste0("cp r_versions/", r_version, ".nix ",
              repo_path,
              "/pkgs/applications/science/math/R/default.nix"
              ))

# Put the GA workflow file in there to build on build_tree repo
system(paste0("cp trigger_build.yml ",
              repo_path,
              "/.github/workflows/"
              ))

# Update date in trigger_build.yml
system(paste0("cd ",
              repo_path,
              "/.github/workflows/ && ",
              paste0("sed -i 's|REPLACE_DATE|", target_date, "|g' trigger_build.yml"))
              )

system(paste0("cd ",
              repo_path,
              " && git checkout -b '", target_date, "'",
              " && git add . && git commit -m 'R CRAN update'",
              " && git push --force origin ", target_date))
