\name{str_diff}
\alias{str_diff}
\title{Differences between strings}
\usage{
  str_diff(x, y)
}
\arguments{
  \item{x}{a single string}

  \item{y}{a single string}
}
\value{
  an integer vector containing the index of the mis-matched
  character
}
\description{
  Computes which characters differ between two strings.
}
\examples{
x <- "once upon a time"
y <- "once upon a time there was"
z <- "once upon two times"
str_diff(x, x)
str_diff(x, y)
str_diff(x, z)
str_diff(y, z)
}

