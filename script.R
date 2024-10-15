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

target_date <- as.POSIXct("2021-01-01 12:00:00")

bioc_version <- set_bioc_version(target_date, bioc_versions)
r_version <- set_r_version(target_date, r_versions)

# Add difftime with target_data in seconds to then filter
# on it
nixpkgs_commits[,
                diff := difftime(when, target_date, units = "secs")]

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

# Define the function
checkout_commit_and_modify_file <- function(repo_path, target_date, target_commit) {

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

  # Replace mirrors from the deriveCran function in default.nix. Otherwise, packages cannot
  # be downloaded from the archive

  # Replace "mirror://cran/" with the new URL in a file using sed
  system(paste0("cd ",
                repo_path,
                "/pkgs/development/r-modules/ && ",
                paste0("sed -i 's|mirror://cran/|", new_string, "|g' default.nix")
                ))

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

  # TODO: set the correct quarto version by date
  # TODO: set the correct rstudio version by date

  system(paste0("cd ",
                repo_path,
                " && git checkout -b '", target_date, "'",
                " && git add . && git commit -m 'R CRAN update'",
                " && git push --force origin ", target_date))

  # Push the new branch to the remote repository
  #push(repo, name = "origin", refspec = paste0("refs/heads/", branch_name))
}

# Example usage:
# checkout_commit_and_modify_file("2022-01-01")

checkout_commit_and_modify_file(repo_path, target_date, target_commit)
