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

# Get commit from target date
nixpkgs_commits <- fread("all_commits_df.csv")

# the next one should be on the 13th of february 23
# the next one should be on the 1st of april 23
# the next one should be on the 15th of june 23
# the next one should be on the 15th of august 23
# the next one should be on the 30th of october 23
# the next one should be on the 30th of december 23
# the next one should be on the 29th of february 24
# the next one should be on the 29th of april 24
# the next one should be on the 14th of june 24
target_date <- as.POSIXct("2023-02-13 12:00:00")

commit_date <- as.POSIXct("2023-10-21 12:00:00")

previous_date <- "2022-12-20"

bioc_version <- set_bioc_version(target_date, bioc_versions)
r_version <- set_r_version(target_date, r_versions)

# Add difftime with target_data in seconds to then filter
# on it
nixpkgs_commits[,
                diff := difftime(when, commit_date, units = "secs")]

closest_commit_df <- nixpkgs_commits[
                                  diff >= 0
                                 ][
                                  order(diff)][1]

target_commit <- closest_commit_df$sha

## Need to see if I need the below
repo_url <- "https://github.com/NixOS/nixpkgs.git"

# Set the local repository path
repo_path <- "../nixpkgs"

# Clone the repository if it doesn't exist locally
if (!dir.exists(repo_path)) {
  clone(repo_url, repo_path)
}


repo <- repository(repo_path)

target_date <- substr(target_date, 1, 10)

system(paste0("cd ", repo_path, " && git reset --hard ", target_commit))

# Get generate-r-packages.R before the switch to json
system(paste0("cd ",
              repo_path,
              "/pkgs/development/r-modules/ && rm generate-r-packages.R && wget https://raw.githubusercontent.com/NixOS/nixpkgs/d44a08dd6574bfc8c701fd0bab02a01391a422f3/pkgs/development/r-modules/generate-r-packages.R"))

# Get latest default.nix to backport fixes
system(paste0("cd ",
              repo_path,
              "/pkgs/development/r-modules/ && rm default.nix && wget https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/development/r-modules/default.nix"))


# Replace the repository with a snapshot from posit at target date
file_path <- file.path(repo_path,
                       "pkgs/development/r-modules/generate-r-packages.R")

file_content <- readLines(file_path)

old_string <- "https://cran.r-project.org/src/contrib/"

new_string <- paste0("https://packagemanager.posit.co/cran/",
                     target_date,
                     "/src/contrib/")

modified_content <- str_replace(file_content, old_string, new_string)

writeLines(modified_content, file_path)

# Needed for old script
# because the recent default.nix imports json files
# but these don't play well with the current setup
system(paste0("cd ",
              repo_path,
              " && git apply ../daily_cran/fix_generate-r-default.patch"))

# Change bioc version depending on date
system(paste0("cd ",
              repo_path,
              " && git apply ../daily_cran/fix_bioc_version.patch"))

system(paste0("cd ",
              repo_path,
              paste0("/pkgs/development/r-modules/ && sed -i 's/REPLACE_BIOC_VERSION/\"", bioc_version, "\"/g' generate-r-packages.R")))


# Replace mirrors from the deriveCran function in default.nix. Otherwise, packages cannot
# be downloaded from the archive

# Replace "mirror://cran/" with the new URL in a file using sed
system(paste0("cd ",
              repo_path,
              "/pkgs/development/r-modules/ && ",
              paste0("sed -i 's|mirror://cran/|", new_string, "|g' default.nix")
              ))

# Fix lwgeom for darwin
system(paste0("cd ",
              repo_path,
              " && git apply ../daily_cran/fix-lwgeom.patch"
              ))


# Fix ragg for darwin by adding libdeflate
system(paste0("cd ",
              repo_path,
              " && git apply ../daily_cran/fix-ragg.patch"
              ))

# We need this patch until 2023-02-23
if(as.Date(commit_date) < as.Date("2023-02-23")){
  system(paste0("cd ",
                repo_path,
                " && git apply ../daily_cran/fix-data_table.patch"
                ))

  system(paste0("cd ",
              repo_path,
              " && git apply ../daily_cran/fix-xlst.patch"
              ))

  system(paste0("cd ",
              repo_path,
              " && git apply ../daily_cran/fix-ModelMetrics.patch"
              ))

  system(paste0("cd ",
              repo_path,
              " && git apply ../daily_cran/fix-FlexReg.patch"
              ))

  system(paste0("cd ",
              repo_path,
              " && git apply ../daily_cran/fix-networkscaleup.patch"
              ))

  system(paste0("cd ",
              repo_path,
              " && git apply ../daily_cran/fix-OpenMx.patch"
              ))
}


# replace-fail only showed up starting 15th of January 2024
if(as.Date(commit_date) < as.Date("2024-01-16")){
  system(paste0("cd ",
                repo_path,
                paste0("/pkgs/development/r-modules/ && sed -i 's/replace-fail/replace/g' default.nix")))
}

# arrow needs rPackages.cpp11
if(as.Date(commit_date) < as.Date("2023-04-27")){
  system(paste0("cd ",
                repo_path,
                " && git apply ../daily_cran/fix-arrow.patch"
                ))
}

# We need this patch until 2023-04-27
if(as.Date(commit_date) < as.Date("2023-04-27")){
  system(paste0("cd ",
                repo_path,
                " && git apply ../daily_cran/fix-textshaping.patch"
                ))
}

# We need this patch until 2023-02-23
if(as.Date(commit_date) < as.Date("2023-04-27")){
  system(paste0("cd ",
              repo_path,
              " && git apply ../daily_cran/fix-rstan.patch"
              ))
}

# Fix later on darwin
system(paste0("cd ",
              repo_path,
              " && git apply ../daily_cran/fix-later.patch"))


# Fix libiconv deps for Darwin
if(as.Date(commit_date) < as.Date("2023-02-06")){

system(paste0("cd ",
              repo_path,
              "/pkgs/development/r-modules/ && rm generic-builder.nix && wget https://raw.githubusercontent.com/NixOS/nixpkgs/3f5c9df6511c5e9ed4a6e5242be74bce12b18533/pkgs/development/r-modules/generic-builder.nix"))

}

# Get latest mkShell to make it buildable
if(as.Date(commit_date) < as.Date("2023-11-24")){

system(paste0("cd ",
              repo_path,
              "/pkgs/build-support/mkshell/ && rm default.nix && wget https://raw.githubusercontent.com/NixOS/nixpkgs/0530d6bd0498e6f554cc9070a163ac9aec5819c8/pkgs/build-support/mkshell/default.nix"))

}

# Fixes nlme on aarch64-darwin
# see https://github.com/NixOS/nixpkgs/pull/151983
# fix is from here https://github.com/NixOS/nixpkgs/pull/186477
if(as.Date(commit_date) < as.Date("2022-08-16")){

system(paste0("cd ",
              repo_path,
              " && curl https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/186477.patch | git apply"))

}

# Fix lerc deps for Darwin before 2022-10-29
if(as.Date(commit_date) < as.Date("2022-11-15")){

system(paste0("cd ",
              repo_path,
              " && curl https://github.com/NixOS/nixpkgs/commit/b3f94fd518d6004e497b717e5466da046fb5a6e1.patch | git apply"))

}

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


# TODO: set the correct quarto version by date
# TODO: set the correct rstudio version by date

system(paste0("cd ",
              repo_path,
              " && git checkout -b '", target_date, "'",
              " && git add . && git commit -m 'R CRAN update'",
              " && git push --force origin ", target_date))

