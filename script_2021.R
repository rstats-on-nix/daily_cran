# This version of the script uses 2022 as a basis, and tries to 
# build the environment "retro-actively"
# Load necessary libraries
library(git2r)
library(stringr)
library(data.table)
library(dplyr)
library(parallel)
library(BiocManager)

bioc_versions <- read.csv("bioc_versions.csv")
r_versions <- read.csv("r_versions.csv")

set_bioc_version <- function(target_date, bioc_versions){
  bioc_versions |>
    dplyr::arrange(desc(date)) |>
    dplyr::mutate(date = as.POSIXct(date)) |>
    dplyr::filter(target_date >= date) |>
    head(1) |>
    dplyr::pull(bioc_version)
}

set_r_version <- function(target_date, r_versions){
  r_versions |>
    dplyr::arrange(desc(date)) |>
    dplyr::mutate(date = as.POSIXct(date)) |>
    dplyr::filter(target_date >= date) |>
    head(1) |>
    dplyr::pull(r_version)
}

target_date <- as.POSIXct("2021-08-03 12:00:00")

commit_date <- as.POSIXct("2021-12-01 12:00:00")

previous_date <- "2022-01-16"

bioc_version <- set_bioc_version(target_date, bioc_versions)
r_version <- set_r_version(target_date, r_versions)


# Now, we try for 2021 by using this commit at january 2022
target_commit <- "7d73fd6e94000f1a5bce2ed8f1852ba848da554d"

# Set the local repository path
repo_path <- "../nixpkgs"

repo <- repository(repo_path)

target_date <- substr(target_date, 1, 10)

system(paste0("cd ", repo_path, " && git reset --hard ", target_commit))

# Replace the repository with a snapshot from posit at target date
file_path <- file.path(repo_path,
                       "pkgs/development/r-modules/generate-r-packages.R")

file_content <- readLines(file_path)

old_string <- paste0("cran/", previous_date)

new_string <- paste0("cran/", target_date)

modified_content <- str_replace(file_content, old_string, new_string)

writeLines(modified_content, file_path)

# Do the same for the default.nix
file_path <- file.path(repo_path,
                       "pkgs/development/r-modules/default.nix")

file_content <- readLines(file_path)

old_string <- paste0("cran/", previous_date)

new_string <- paste0("cran/", target_date)

modified_content <- str_replace_all(file_content, old_string, new_string)

writeLines(modified_content, file_path)

# Download previous file to make bumping faster
system(paste0("cd ",
              repo_path,
              paste0("/pkgs/development/r-modules/ && rm bioc-annotation-packages.nix && wget https://raw.githubusercontent.com/rstats-on-nix/nixpkgs/refs/heads/",
                     previous_date, "/pkgs/development/r-modules/bioc-annotation-packages.nix")))

system(paste0("cd ",
              repo_path,
              paste0("/pkgs/development/r-modules/ && rm bioc-experiment-packages.nix && wget https://raw.githubusercontent.com/rstats-on-nix/nixpkgs/refs/heads/",
                     previous_date, "/pkgs/development/r-modules/bioc-experiment-packages.nix")))

system(paste0("cd ",
              repo_path,
              paste0("/pkgs/development/r-modules/ && rm bioc-packages.nix && wget https://raw.githubusercontent.com/rstats-on-nix/nixpkgs/refs/heads/",
                     previous_date, "/pkgs/development/r-modules/bioc-packages.nix")))

system(paste0("cd ",
              repo_path,
              paste0("/pkgs/development/r-modules/ && rm cran-packages.nix && wget https://raw.githubusercontent.com/rstats-on-nix/nixpkgs/refs/heads/",
                     previous_date, "/pkgs/development/r-modules/cran-packages.nix")))

# Bump the tree
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
