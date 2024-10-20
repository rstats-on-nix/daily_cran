# Taken from {versions}
available.versions <- function (pkgs){
    if (length(pkgs) > 1) {
        ans <- lapply(pkgs, available.versions)
        ans <- lapply(ans, "[[", 1)
        names(ans) <- pkgs
        return(ans)
    }
    current_df <- current.version(pkgs)
    archive_url <- sprintf("%s/src/contrib/Archive",
                           "https://packagemanager.posit.co/cran/latest")

    archived <- pkg.in.archive(archive_url, pkgs)
    if (archived) {
        pkg_archive_url <- sprintf("%s/src/contrib/Archive/%s", 
                                   "https://packagemanager.posit.co/cran/latest", pkgs)
        previous_df <- scrape.index.versions(pkg_archive_url, 
            pkgs)
    }
    else {
        previous_df <- current_df[0, ]
    }
    df <- rbind(current_df, previous_df)
    df$available <- as.Date(df$date) >= as.Date("2014-09-17")
    if (!all(df$available)) {
        first_available <- min(which(as.Date(df$date) <= as.Date("2014-09-17")))
        df$available[first_available] <- TRUE
    }
    ans <- list()
    ans[[pkgs]] <- df
    return(ans)
}

current.version <- function (pkg) {

  # get all current contributed packages in latest MRAN
  url <- paste0("https://packagemanager.posit.co/cran/latest",
                '/src/contrib')

  # get the lines
  lines <- url_lines(url)

  # keep only lines starting with hrefs
  lines <- grep('^<a href="*',
                lines,
                value = TRUE)

  # take the sequence after the href that is between the quotes
  tarballs <- gsub('.*href=\"([^\"]+)\".*',
                   '\\1',
                   lines)

  # match the sequence in number-letter-number format
  dates <- gsub('.*  ([0-9]+-[a-zA-Z]+-[0-9]+) .*',
                '\\1',
                lines)

  # convert dates to standard format
  dates <- as.Date(dates, format = '%d-%b-%Y')

  # get the ones matching the package
  idx <- grep(sprintf('^%s_.*.tar.gz$', pkg),
              tarballs)

  if (length(idx) == 1) {
    # if this provided exactly one match, it's the current package
    # so scrape the version and get the date

    versions <- tarballs[idx]

    # remove the leading package name
    versions <- gsub(sprintf('^%s_', pkg),
                     '',
                     versions)

    # remove the trailing tarball extension
    versions <- gsub('.tar.gz$',
                     '',
                     versions)

    dates <- dates[idx]

  } else {

    # otherwise return NAs
    versions <- dates <- NA

  }

  # return dataframe with these
  data.frame(version = versions,
             date = as.character(dates),
             stringsAsFactors = FALSE)

}

url_lines <- function (url) {

                                        # create a tempfile
  file <- tempfile()

                                        # stick the html in there
  suppressWarnings(success <- download.file(url, file,
                                            quiet = TRUE))

                                        # if it failed, issue a nice error
  if (success != 0)
    stop ('URL does not appear to exist: ', url)

                                        # get the lines, delete the file and return
  lines <- readLines(file, encoding = "UTF-8")
  file.remove(file)
  lines

}

available.versions("dplyr")
