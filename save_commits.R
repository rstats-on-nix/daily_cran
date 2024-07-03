library(git2r)
library(stringr)
library(arrow)
library(dplyr)

repo_url <- "https://github.com/NixOS/nixpkgs.git"

# Set the local repository path
repo_path <- "../nixpkgs"

# Clone the repository if it doesn't exist locally
if (!dir.exists(repo_path)) {
  clone(repo_url, repo_path)
}

# Open the repository
repo <- repository(repo_path)

all_commits <- commits(repo)

all_commits_df <- bind_rows(lapply(all_commits, as.data.frame))

write.csv(all_commits_df, "all_commits_df.csv", row.names = FALSE)
