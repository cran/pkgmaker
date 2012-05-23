\name{latex_preamble}
\alias{latex_bibliography}
\alias{latex_preamble}
\title{LaTeX Utilities for Vignettes}
\usage{
  latex_preamble(R = TRUE, CRAN = TRUE,
    Bioconductor = TRUE, GEO = TRUE, ArrayExpress = TRUE,
    only = FALSE, file = "")

  latex_bibliography(PACKAGE, file = "")
}
\arguments{
  \item{R}{logical that indicate if general R commands
  should be added (e.g. package names, inline R code format
  commands)}

  \item{CRAN}{logical that indicate if general CRAN
  commands should be added (e.g. CRAN package citations)}

  \item{Bioconductor}{logical that indicate if general
  Bioconductor commands should be added (e.g. Bioc package
  citations)}

  \item{GEO}{logical that indicate if general GEOmnibus
  commands should be added (e.g. urls to GEO datasets)}

  \item{ArrayExpress}{logical that indicate if general
  ArrayExpress commands should be added (e.g. urls to
  ArrayExpress datasets)}

  \item{only}{a logical that indicates if the only the
  commands whose dedicated argument is not missing should
  be considered.}

  \item{file}{connection where to print. If \code{NULL} the
  result is returned silently.}

  \item{PACKAGE}{package name}
}
\description{
  \code{latex_preamble} outputs/returns command definition
  LaTeX commands to be put in the preamble of vignettes.

  \code{latex_bibliography} prints or return a LaTeX
  command that includes a package bibliography file if it
  exists.
}
\examples{
latex_preamble()
latex_preamble(R=TRUE, only=TRUE)
latex_preamble(R=FALSE, CRAN=FALSE, GEO=FALSE)
latex_preamble(GEO=TRUE, only=TRUE)
}

