library(rvest)
library(dplyr)

get_versions <- function(url){

  webpage <- read_html(url)

  pkg_archive <- webpage %>%
    html_table() %>%
    .[[1]]

  colnames(pkg_archive) <- c("a", "name", "last_modified", "size", "description")

  pkg_archive %>%
    filter(last_modified != "") %>%
    select(name, last_modified) %>%
    mutate(hu = as.Date(last_modified)) %>%
    filter(hu > as.Date("2021-01-16"))

}

dplyr_url <- "https://cran.r-project.org/src/contrib/Archive/dplyr/"

dplyr_versions <- get_versions(dplyr_url)

duckdb_url <- "https://cran.r-project.org/src/contrib/Archive/duckdb/"

duckdb_versions <- get_versions(duckdb_url)

data.table_url <- "https://cran.r-project.org/src/contrib/Archive/data.table/"

data.table_versions <- get_versions(data.table_url)

arrow_url <- "https://cran.r-project.org/src/contrib/Archive/arrow/"

arrow_versions <- get_versions(arrow_url)

sf_url <- "https://cran.r-project.org/src/contrib/Archive/sf/"

sf_versions <- get_versions(sf_url)

rJava_url <- "https://cran.r-project.org/src/contrib/Archive/rJava/"

rJava_versions <- get_versions(rJava_url)

rstan_url <- "https://cran.r-project.org/src/contrib/Archive/rstan/"

rstan_versions <- get_versions(rstan_url)

RCurl_url <- "https://cran.r-project.org/src/contrib/Archive/RCurl/"

RCurl_versions <- get_versions(RCurl_url)

RSQLite_url <- "https://cran.r-project.org/src/contrib/Archive/RSQLite/"

RSQLite_versions <- get_versions(RSQLite_url)

stringi_url <- "https://cran.r-project.org/src/contrib/Archive/stringi/"

stringi_versions <- get_versions(stringi_url)

bind_rows(
  dplyr_versions,
  duckdb_versions,
  data.table_versions,
  arrow_versions,
  sf_versions,
  rJava_versions,
  rstan_versions,
  RCurl_versions,
  RSQLite_versions,
  stringi_versions
) %>%
  arrange(last_modified) %>%
  mutate(month = lubridate::month(hu), .before = name) %>%
  group_by(month) %>%
  mutate(pkg_name = sub("_.*", "", name), .before = name,
         dup = ifelse(duplicated(pkg_name), 1, 0)) %>%
  print(n=120)
