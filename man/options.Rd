% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/options.R
\name{option_symlink}
\alias{option_symlink}
\alias{is_option_symlink}
\alias{option_symlink_target}
\alias{as.package_options}
\alias{[[.package_options}
\alias{packageOptions}
\alias{listPackageOptions}
\title{\code{option_symlink} creates a symbolic link to option \code{x}.}
\usage{
option_symlink(x)

is_option_symlink(x, opts)

option_symlink_target(x, opts)

as.package_options(..., defaults = NULL)

\method{[[}{package_options}(x, ...)

packageOptions(..., PACKAGE = packageName())

listPackageOptions()
}
\arguments{
\item{x}{a character string, a list or an object of class
\code{package_options}.}

\item{opts}{a list of options}

\item{...}{
  Arguments passed on to \code{\link[base:options]{base::options}}
  \describe{
    \item{\code{}}{}
  }}

\item{defaults}{\code{NULL} or a list of default options
with their values.}

\item{PACKAGE}{a package name}
}
\value{
\itemize{
\item \code{packageOptions} returns a list of package-specific options.
}

\itemize{
\item \code{listPackageOptions} returns a character vector (possibly empty).
}
}
\description{
\code{option_symlink} creates a symbolic link to option \code{x}.

\code{is_option_symlink} tests if \code{x} is a symbolic link option.

\code{option_symlink_target} returns the end target option of a symbolic link
option \code{x}.

\code{as.package_options} creates an object such as the
ones used to stores package specific options.

The method \code{[[} is equivalent to \code{options()} or \code{getOption(...)}:
e.g. \code{obj[[]]} returns the list of options defined in \code{obj}, and
\code{obj[['abc']]} returns the value of option \code{'abc'}.

\code{packageOptions} provides access to package specific options from a
given package that were defined with \code{setupPackageOptions}, and behaves as the base function \code{\link[base]{options}}.

\code{listPackageOptions} returns the names of all option
currently defined with \code{setupPackageOptions}.
}
\examples{
listPackageOptions()

}
