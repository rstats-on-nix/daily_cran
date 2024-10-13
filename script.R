# Load necessary libraries
library(git2r)
library(stringr)
library(data.table)
library(dplyr)
library(parallel)
library(BiocManager)

set_bioc_version <- function(target_date){
  dplyr::case_when(
           #dplyr::between(target_date, )
           as.POSIXct("2019-05-03 12:00:00")
         )
}

# Get commit from target date
nixpkgs_commits <- fread("all_commits_df.csv")

target_date <- as.POSIXct("2019-05-03 12:00:00")

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

  evercran_target_date <- gsub("-", "/", substr(target_date, 1, 10))

  system(paste0("cd ", repo_path, " && git reset --hard ", target_commit))

  system(paste0("cd ",
                repo_path,
                "/pkgs/development/r-modules/ && rm generate-r-packages.R && wget https://raw.githubusercontent.com/NixOS/nixpkgs/d44a08dd6574bfc8c701fd0bab02a01391a422f3/pkgs/development/r-modules/generate-r-packages.R"))

  system(paste0("cd ",
                repo_path,
                "/pkgs/development/r-modules/ && rm default.nix && wget https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/development/r-modules/default.nix"))

#  system(paste0("cd ",
#                repo_path,
#                "/pkgs/development/r-modules/ && rm generate-shell.nix && wget https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/development/r-modules/generate-shell.nix"))


  file_path <- file.path(repo_path,
                         "pkgs/development/r-modules/generate-r-packages.R")

  file_content <- readLines(file_path)

  old_string <- "https://cran.r-project.org/src/contrib/"

  new_string <- paste0("https://evercran.r-pkg.org/",
                       evercran_target_date,
                       "/src/contrib/")

  modified_content <- str_replace(file_content, old_string, new_string)

  writeLines(modified_content, file_path)

  # Needed for old script
  system(paste0("cd ",
                repo_path,
                " && git apply ../daily_cran/fix_generate-r-default.patch"))

  system(paste0("cd ",
                repo_path,
                "/pkgs/development/r-modules/ && Rscript generate-r-packages.R cran > new && mv new cran-packages.nix"))

  # TODO: set the correct bioc version by date
  # TODO: set the correct R version by date
  # TODO: set the correct quarto version by date

  system(paste0("cd ",
                repo_path,
                " && git checkout -b '", evercran_target_date, "'",
                " && git add . && git commit -m 'R CRAN update'",
                " && git push --force origin ", evercran_target_date))

  # Push the new branch to the remote repository
  #push(repo, name = "origin", refspec = paste0("refs/heads/", branch_name))
}

# Example usage:
# checkout_commit_and_modify_file("2022-01-01")

checkout_commit_and_modify_file(repo_path, target_date, target_commit)
