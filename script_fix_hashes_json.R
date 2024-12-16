library(jsonlite)
library(parallel)

cl <- makeCluster(6)

readFormatted <- fromJSON("../nixpkgs/pkgs/development/r-modules/cran-packages.json")

readFormatted <- readFormatted$packages

nixPrefetch <- function(pkgs) {
    url <- paste0(mirrorUrl, pkgs$name, "_", pkgs$version, ".tar.gz")
    tmp <- tempfile(pattern=paste0(pkgs$name, "_", pkgs$version), fileext=".tar.gz")
    cmd <- paste0("wget -q -O '", tmp, "' '", url, "'")
    archiveUrl <- paste0(mirrorUrl, "Archive/", pkgs$name, "/", pkgs$name, "_", pkgs$version, ".tar.gz")
    cmd <- paste0(cmd, " || wget -q -O '", tmp, "' '", archiveUrl, "'")
    cmd <- paste0(cmd, " && nix-hash --type sha256 --base32 --flat '", tmp, "'")
    cmd <- paste0(cmd, " && echo >&2 '  added ", pkgs$name, " v", pkgs$version, "'")
    cmd <- paste0(cmd, " ; rm -rf '", tmp, "'")
    out <- system(cmd, intern=TRUE)
    pkgs$sha256 <- out

    if("broken" %in% names(pkgs)){
      list(name=unbox(pkgs$name),
           version=unbox(pkgs$version),
           sha256=unbox(pkgs$sha256),
           depends=pkgs$depends,
           broken=unbox(pkgs$broken))
    } else {
      list(name=unbox(pkgs$name),
           version=unbox(pkgs$version),
           sha256=unbox(pkgs$sha256),
           depends=pkgs$depends)
    }

}

mirrorType <- "cran"

# Probably no need to ever update biocVersion since
# I'm only checking CRAN packages
biocVersion <- "3.16"

mirrorUrls <- list( bioc=paste0("http://bioconductor.org/packages/",
                  biocVersion, "/bioc/src/contrib/") ,
                  "bioc-annotation"=paste0("http://bioconductor.org/packages/",
                  biocVersion, "/data/annotation/src/contrib/") ,
                  "bioc-experiment"=paste0("http://bioconductor.org/packages/",
                  biocVersion, "/data/experiment/src/contrib/") ,
                  cran="https://cran.r-project.org/src/contrib/"
                  )

mirrorUrl <- mirrorUrls[mirrorType][[1]]

clusterExport(cl, c("nixPrefetch","readFormatted", "mirrorUrl", "mirrorType", "unbox"))

#plan(multicore, workers = 6)

#out <- future_map(readFormatted, nixPrefetch)

out <- parLapply(cl, readFormatted, nixPrefetch)


# verify result and see if ok

extraArgs = setNames(list(), character(0))

if (mirrorType != "cran") {
  extraArgs=list(biocVersion=unbox(paste(biocVersion)))
}

output_json <- toJSON(list(extraArgs=extraArgs, packages=out), pretty=TRUE)

output_file <- "../nixpkgs/pkgs/development/r-modules/cran-packages.json"

writeLines(output_json, output_file)

system(paste0("cd ../nixpkgs/",
      " && git add . && git commit -m 'updated hashes and backported rJava fix'",
      " && git push origin 2024-10-01"))
