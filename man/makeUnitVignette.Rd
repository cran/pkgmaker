\name{makeUnitVignette}
\alias{makeUnitVignette}
\title{Make Vignette for Unit Tests}
\usage{
  makeUnitVignette(pkg,
    file = paste(pkg, "-unitTests.Rnw", sep = ""))
}
\arguments{
  \item{pkg}{Package name}

  \item{file}{Output Sweave (.Rnw) document}
}
\value{
  Result of running unit test suite
}
\description{
  Make Vignette for Unit Tests
}

