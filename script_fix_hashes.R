library(data.table)
library(parallel)

cl <- makeCluster(6)

readFormatted <- as.data.table(read.table(skip=8, sep='"', text=head(readLines("../nixpkgs/pkgs/development/r-modules/cran-packages.nix"), -1)))

nixPrefetch <- function(name, version) {
    url <- paste0(mirrorUrl, name, "_", version, ".tar.gz")
    tmp <- tempfile(pattern=paste0(name, "_", version), fileext=".tar.gz")
    cmd <- paste0("wget -q -O '", tmp, "' '", url, "'")
    archiveUrl <- paste0(mirrorUrl, "Archive/", name, "/", name, "_", version, ".tar.gz")
    cmd <- paste0(cmd, " || wget -q -O '", tmp, "' '", archiveUrl, "'")
    cmd <- paste0(cmd, " && nix-hash --type sha256 --base32 --flat '", tmp, "'")
    cmd <- paste0(cmd, " && echo >&2 '  added ", name, " v", version, "'")
    cmd <- paste0(cmd, " ; rm -rf '", tmp, "'")
    system(cmd, intern=TRUE)
}

mirrorType <- "cran"

# Probably no need to ever update biocVersion since
# I'm only checking CRAN packages
biocVersion <- "3.11"

mirrorUrls <- list( bioc=paste0("http://bioconductor.org/packages/",
                  biocVersion, "/bioc/src/contrib/") ,
                  "bioc-annotation"=paste0("http://bioconductor.org/packages/",
                  biocVersion, "/data/annotation/src/contrib/") ,
                  "bioc-experiment"=paste0("http://bioconductor.org/packages/",
                  biocVersion, "/data/experiment/src/contrib/") ,
                  cran="https://cran.r-project.org/src/contrib/"
                  )

mirrorUrl <- mirrorUrls[mirrorType][[1]]

clusterExport(cl, c("nixPrefetch","readFormatted", "mirrorUrl", "mirrorType"))

readFormatted$V6 <- parApply(cl, readFormatted, 1,
                                     function(p) nixPrefetch(p[2], p[4]))

output_file <- "../nixpkgs/pkgs/development/r-modules/cran-packages.nix"

output <- c(
  "# This file is generated from generate-r-packages.R. DO NOT EDIT.",
  "# Execute the following command to update the file.",
  "#",
  paste("# Rscript generate-r-packages.R", mirrorType, ">new && mv new cran-packages.nix"),
  "",
  "{ self, derive }:",
  "let derive2 = derive {  };",
  "in with self; {",
  apply(readFormatted, 1, paste0, collapse = "\""),
  "}\n"
)

writeLines(output, output_file)

system(paste0("cd ../nixpkgs/",
      " && git add . && git commit -m 'updated hashes and backported rJava fix'",
      " && git push origin 2019-12-19"))
