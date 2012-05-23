\name{packageReference}
\alias{packageReference}
\title{Package References}
\usage{
  packageReference(key, short = FALSE)
}
\arguments{
  \item{key}{character vector of BibTex keys}
}
\value{
  a character string containing the text formated BibTex
  entries
}
\description{
  Create a citation string from package specific BibTex
  entries, suitable to be used in Rd files. The entries are
  looked in a file named REFERNCES.bib in the package's
  root directory (i.e. inst/ in development mode).
}
\keyword{internal}

