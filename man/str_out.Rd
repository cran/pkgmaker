% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R, R/knitr.R
\name{str_out}
\alias{str_out}
\alias{str_desc}
\alias{str_fun}
\alias{str_class}
\alias{str_pkg}
\alias{str_md5sum}
\alias{str_hash}
\alias{str_dim}
\alias{str_bs}
\title{Formatting Utilities}
\usage{
str_out(
  x,
  max = 3L,
  quote = is.character(x),
  use.names = FALSE,
  sep = ", ",
  total = FALSE
)

str_desc(object, exdent = 0L)

str_fun(object)

str_class(x, max = Inf, ...)

str_pkg(pkg, lib.loc = NULL)

str_md5sum(x)

str_hash(x, algo = "md5")

str_dim(x, dims = dim(x))

str_bs(x)
}
\arguments{
\item{x}{character vector}

\item{max}{maximum number of values to appear in the list. If \code{x} has
more elements than \code{max}, a \code{"..."} suffix is appended.}

\item{quote}{a logical indicating whether the values should be quoted with
single quotes (defaults) or not.}

\item{use.names}{a logical indicating whether names should be added to the
list as \code{NAME=VAL, ...} or not (default).}

\item{sep}{separator character}

\item{total}{logical that indicates if the total number of elements should be
appended to the formatted string as \code{"'a', ..., 'z' (<N> total)"}.}

\item{object}{an R object}

\item{exdent}{extra indentation passed to str_wrap, and used if the output
should spread over more than one lines.}

\item{...}{other arguments passed to \link{str_out}.}

\item{pkg}{package name}

\item{lib.loc}{path to a library of R packages}

\item{algo}{The algorithms to be used; currently available choices are
    \code{md5}, which is also the default, \code{sha1}, \code{crc32},
    \code{sha256}, \code{sha512}, \code{xxhash32}, \code{xxhash64},
    \code{murmur32}, \code{spookyhash} and \code{blake3}.}

\item{dims}{a numeric vector of dimensions.
Default is to use the input object dimensions (via function \code{dims()})}
}
\value{
a single character string

\itemize{
\item \code{str_bs} returns a character string.
}
}
\description{
\code{str_out} formats character vectors for use in show methods or
error/warning messages.
}
\section{Functions}{
\itemize{
\item \code{str_desc()}: builds formatted string from a list of complex values.

\item \code{str_fun()}: extracts and formats a function signature.
It typically formats the output \code{capture.output(args(object))}.

\item \code{str_class()}: outputs the class(es) of an object using \code{str_out}.

\item \code{str_pkg()}: formats a package name and version

\item \code{str_md5sum()}: computes md5sum on character vector using \code{\link[tools]{md5sum}}.

\item \code{str_hash()}: computes hash of a character vector using \code{\link[digest]{digest}}.

\item \code{str_dim()}: builds a string that describes the dimension of an object, in the form
\verb{n x m} for 2D-objects, \verb{n x m x p} for 3D-objects, and so on.

\item \code{str_bs()}: substitutes backspace characters (\verb{\\\\b}) to produce
a character string as it would be displayed in the console.

}}
\examples{

x <- letters[1:10]
str_out(x)
str_out(x, 8)
str_out(x, Inf)
str_out(x, quote=FALSE)
str_out(x, total = TRUE)

str_fun(install.packages)
str_class(matrix())

# Backspace substitution
str_bs("abc")
str_bs("abc\b")
str_bs("abc\b\b")
str_bs("abc\bd")
str_bs("abc\b\bde\b")

# more complex example
x <- "\bab\nc\bd\n\babc\b\bd"
cat(x, "\n")
y <- str_bs(x)
y
cat(y, "\n")

}
\author{
Renaud Gaujoux

\code{str_bs} was adapted from a proposal from Yihui Xie.
}
