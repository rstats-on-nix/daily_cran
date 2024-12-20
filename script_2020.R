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

target_date <- as.POSIXct("2019-03-14 12:00:00")

previous_date <- "2020-08-20"

bioc_version <- set_bioc_version(target_date, bioc_versions)
#r_version <- set_r_version(target_date, r_versions)
#r_version <- "4.0.3"

#target_commit <- "a3f9335ed25c3dbe5fa168392f17c813e0e06621"

# Set the local repository path
repo_path <- "../nixpkgs"

repo <- repository(repo_path)

target_date <- substr(target_date, 1, 10)

#system(paste0("cd ", repo_path, " && git reset --hard ", target_commit))

# Replace the repository with a snapshot from posit at target date
file_path <- file.path(repo_path,
                       "pkgs/development/r-modules/generate-r-packages.R")

file_content <- readLines(file_path)

old_string_index <- which(grepl("mran", file_content))

snapshot_date_index <- which(grepl("snapshotDate <- Sys.Date\\(\\)-1",
                                   file_content))

new_string <- paste0(", cran = \"https://packagemanager.posit.co/cran/", target_date, "/src/contrib/\"")

file_content[old_string_index] <- new_string
file_content[snapshot_date_index] <- paste0("snapshotDate <- \"",
                                            target_date,
                                            "\"")

old_string_bioc <- "statistik.tu-dortmund.de"
new_string_bioc <- "org"

modified_content <- str_replace(file_content, old_string, new_string)

modified_content <- str_replace(modified_content, old_string_bioc, new_string_bioc)

writeLines(modified_content, file_path)

# Bump the tree
system(paste0("cd ",
              repo_path,
              "/pkgs/development/r-modules/ && Rscript generate-r-packages.R cran > new && mv new cran-packages.nix"))

#delete the snapshot from cran-packages.nix

system(paste0("cd ",
              repo_path,
              "/pkgs/development/r-modules/ && Rscript generate-r-packages.R bioc > new && mv new bioc-packages.nix"))

system(paste0("cd ",
              repo_path,
              "/pkgs/development/r-modules/ && Rscript generate-r-packages.R bioc-annotation > new && mv new bioc-annotation-packages.nix"))

system(paste0("cd ",
              repo_path,
              "/pkgs/development/r-modules/ && Rscript generate-r-packages.R bioc-experiment > new && mv new bioc-experiment-packages.nix"))

# Need to change the name of the r_import package to import
system(paste0("cd ",
              repo_path,
              "/pkgs/development/r-modules/ && ",
              "sed -i 's/name=\"r_import\"/name=\"import\"/g' cran-packages.nix")
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
              " && git push origin ", target_date))
