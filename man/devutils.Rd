\name{packageEnv}
\alias{as.package}
\alias{isPackageInstalled}
\alias{packageEnv}
\alias{packageName}
\alias{packagePath}
\title{Package Development Utilities}
\usage{
  packageEnv(pkg)

  packageName(.Global = FALSE)

  packagePath(..., package = NULL)

  isPackageInstalled(..., lib.loc = NULL)

  as.package(x, ..., quiet = FALSE)
}
\arguments{
  \item{pkg}{package name. If missing the environment of
  the caller package is returned.}

  \item{.Global}{a logical that indicates if calls from the
  global environment should throw an error (\code{FALSE}:
  default) or the string \code{'R_GlobalEnv'}.}

  \item{package}{optional name of an installed package}

  \item{...}{arguments passed to \code{\link{file.path}}.}

  \item{lib.loc}{path to a library of R packages where to
  search the package}

  \item{x}{package specified by its
  installation/development path or its name as
  \code{'package:*'}.}

  \item{quiet}{a logical that indicate if an error should
  be thrown if a package is not found. It is also passed to
  \code{\link{find.package}}.}
}
\value{
  an environment

  a character string

  a character string
}
\description{
  \code{packageEnv} is a slight modification from
  \code{\link{topenv}}, which returns the caller's top
  environment, which in the case of development packages is
  the environment into which the source files are loaded by
  \code{\link[devtools]{load_all}}.

  \code{packageName} returns the current package's name.

  \code{packagePath} returns the current package's root
  directory, which is its installation/loading directory in
  the case of an installed package, or its source directory
  served by devtools.

  Tests if a package is installed

  \code{as.package} is enhanced version of
  \code{\link[devtools]{as.package}}, that is not exported
  not to mask the original function. It could eventually be
  incorporated into \code{devtools} itself. Extra arguments
  in \code{...} are passed to \code{\link{find.package}}.
}

