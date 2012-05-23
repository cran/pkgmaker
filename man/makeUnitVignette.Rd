\name{makeUnitVignette}
\alias{makeUnitVignette}
\title{Make Vignette for Unit Tests}
\usage{
  makeUnitVignette(pkg,
    file = paste(pkg, "-unitTests.pdf", sep = ""))
}
\arguments{
  \item{pkg}{Package name}

  \item{file}{Output file (.Rnw, .tex, or .pdf)}
}
\value{
  Result of running unit test suite
}
\description{
  Make Vignette for Unit Tests
}

