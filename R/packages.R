# Package related functions
# 
# Author: Renaud Gaujoux
# Creation: 29 Jun 2012
###############################################################################

#' @include package.R
NULL

path.protect <- function(...){
  f <- file.path(...)
  if( .Platform$OS.type == 'windows' ){
    f <- gsub("\\\\", "/", f)
  }
  paste('"', f, '"', sep='')
}

#' Quick Installation of a Source Package
#' 
#' Builds and install a minimal version of a package from its 
#' source directory.
#' 
#' @param path path to the package source directory
#' @param destdir installation directory. 
#' If \code{NULL}, the package is installed in the default installation library.
#' If \code{NA}, the package is installed in a temporary directory, whose path is returned
#' as a value.
#' @param vignettes logical that indicates if the vignettes should be 
#' rebuilt and installed.
#' @param force logical that indicates if the package should be installed even if a previous
#' installation exists in the installation library.
#' @param ... extra arguments passed to \code{\link{R.CMD}}
#' @param lib.loc library specification.
#' If \code{TRUE} then the installation directory \code{destdir} is added to the default 
#' library paths.
#' This can be usefull if dependencies are installed in this directory.
#' If \code{NULL}, then the default library path is left unchanged.
#' 
#' @return `quickinstall` returns the path of the library where the package was installed.
#' 
#' @export
#' 
quickinstall <- function(path, destdir=NULL, vignettes=FALSE, force=TRUE, ..., lib.loc=if(!is.null(destdir)) TRUE){
	
	npath <- normalizePath(path)
	pkg <- as.package(path)
  
  # define installation library
	nlib <- if( !is.null(destdir) ) destdir
  else if( is_NA(destdir) ) tempfile("pkglib_")
  
  # normalize path
  if( !is.null(nlib) ){
    # create direcory if needed
    if( !is.dir(nlib) ) dir.create(nlib, recursive=TRUE)
    nlib <- normalizePath(nlib)
    
    if( !is.dir(nlib) ){
      stop("Could not install package '", pkg$package, "': installation directory '", nlib, "' does not exist.")
    }
    
    # add destination directory to default libraries
    if( isTRUE(lib.loc) ) lib.loc <- unique(c(nlib, .libPaths()))
  }
  
  # setup result string
	res <- invisible(if( !is.null(destdir) ) nlib else .libPaths()[1L])
  
  # early exit if the package already exists in the library (and not forcing install)
	message("# Check for previous package installation ... ", appendLF=FALSE)
  if( !is.null(destdir) && is.dir(file.path(nlib, pkg$package)) ){
    if( !force ){
      message("YES (skip)")
      return(res)
    }
    message("YES (replace)")
  }else message("NO")
  
	# add lib path
	ol <- set_libPaths(lib.loc)
	on.exit(set_libPaths(ol), add=TRUE)
	message("Using R Libraries: ", str_out(.libPaths(), Inf))
	
	owd <- setwd(tempdir())
	on.exit( setwd(owd), add=TRUE)
  
	# build
	message("# Building package `", pkg$package, "` in '", getwd(), "'")
	opts <- '--no-manual --no-resave-data '
	if( !vignettes ){
        vflag <- if( testRversion('>= 3.0') ) '--no-build-vignettes ' else '--no-vignettes ' 
        opts <- str_c(opts, vflag)
    }
	R.CMD('build', opts, path.protect(npath), ...)
	spkg <- paste(pkg$package, '_', pkg$version, '.tar.gz', sep='')
	if( !file.exists(spkg) ) stop('Error in building package `', pkg$package,'`')
	# install
	message("# Installing package `", pkg$package, "`"
          , if( !is.null(destdir) ){
            tmp <- if( is_NA(destdir) ) 'temporary '
            str_c("in ", tmp, "'", nlib, "'")
          })
  opts_inst <- ' --no-multiarch --no-demo --with-keep.source '
	if( !vignettes ) opts_inst <- str_c(opts_inst, '--no-docs ')
	R.CMD('INSTALL', if( !is.null(destdir) ) paste('-l', path.protect(nlib)), opts_inst, path.protect(spkg), ...)
  
  # return installation library
	invisible(res)
}

#' Loading Packages
#' 
#' \code{require.quiet} silently requires a package, and \code{qrequire} is an alias to \code{require.quiet}.
#' 
#' @param ... extra arguments passed to \code{\link{library}} or \code{\link{require}}.
#' 
#' @return No return value, called to load packages.
#' 
#' @rdname packages
#' @family require
#' @export
require.quiet <- .silenceF(require)
#' @rdname packages
#' @export
qrequire <- require.quiet

#' @describeIn packages silently loads a package.
#' 
#' @export
qlibrary <- .silenceF(library)

#' @describeIn packages tries loading a package with base \code{\link{require}}  
#' and stops with a -- custom -- error message if it fails to do so.
#' 
#' @param msg error message to use, to which is appended the string 
#' \code{' requires package <pkg>'} to build the error message. 
#' @param package name of the package to load.
#' @inheritParams base::require
#' 
#' @export
#' @examples 
#' 
#' mrequire('Running this example', 'stringr')
#' try( mrequire('Doing impossible things', 'notapackage') )
#' 
mrequire <- function(msg, package, lib.loc = NULL, quietly = FALSE){
	
	if( !require(package = package, character.only = TRUE, lib.loc = lib.loc, quietly = quietly) ){
		if( !is.null(msg) ) stop(msg, " requires package ", str_out(package))
		else stop("Could not find required package ", str_out(package))
	}
}

#' @param pkg package name to load.
#' @return * `requirePackage`: returned no value, called to load a package.
#' @rdname pkgmaker-deprecated
#' @export
requirePackage <- function(pkg, ...){
     .Deprecated('mrequire')
#     mrequire(msg = c(...), package = pkg)   
}

#' Setting Mirrors and Repositories
#' 
#' \code{setBiocMirror} sets all Bioconductor repositories (software, data, 
#' annotation, etc.).
#' so that they are directly available to \code{\link{install.packages}}.
#' It differs from \code{\link{chooseBioCmirror}} in that it effectively enables 
#' the repositories.
#' 
#' @param url or Bioconductor mirror url
#' @param version version number
#' @param unique logical that indicate if duplicated urls or names should be 
#' removed.
#'
#' @return `setBiocMirror` returns the old set of Bioc repositories.
#' @rdname mirrors
#' @export 
setBiocMirror <- function(url='http://www.bioconductor.org', version=NULL, unique=TRUE){
	
    #get all bioconductor repos      
    biocRepos <- getBiocRepos(url, version)
	
	repos <- c(biocRepos, getOption('repos'))
	if( unique ){
		nam <- names(repos)
		repos <- repos[!duplicated(repos) & (!duplicated(nam) | nam=='')]
	}
    options(repos=repos)
}

#' @describeIn mirrors is a shortcut for \code{getOption('BioC_mirror')}, which 
#' returns the current Bioconductor mirror as used by \code{biocLite}.
#'  
#' @export
getBiocMirror <- function(){
	getOption('BioC_mirror')
}
#' @describeIn mirrors returns urls to all Bioconductor repositories on a 
#' given mirror.
#' 
#' @export
getBiocRepos <- function(url='http://www.bioconductor.org', version=NULL){
	
	if( is.null(url) ){
		url <- getBiocMirror()
		if( is.null(url) )
			stop("No Bioconductor mirror was setup. Use `setBiocMirror`.")
	}
	
	## BioConductor CRAN-style repositories.
	## The software repo (bioc) _must_ be the first element.
	biocParts <- c(
			bioc='bioc'
			, biocData='data/annotation'
			, biocExp='data/experiment'
			, biocExtra='extra'
    )
	
	# define version suffix for bioconductor repo
	if( is.null(version) ){
		assoc <- list(`2`=c(7L, 2L))
		Rv <- as.integer(sub("([0-9]+).*", "\\1", R.version$minor))
		offset <- assoc[[R.version$major]]
	    version <- paste(R.version$major, offset[2L] + Rv - offset[1L], sep='.')
	}
	
	#add version suffix for bioconductor repo
    setNames(paste(url, 'packages', version, biocParts, sep='/'), names(biocParts))
}

#' @describeIn mirrors sets the preferred CRAN mirror.
#' 
#' @export
setCRANMirror <- function(url=CRAN, unique=TRUE){
	
	repos <- c(CRAN=url, getOption('repos'))
	if( unique ){
		nam <- names(repos)
		repos <- repos[!duplicated(repos) & (!duplicated(nam) | nam=='')]
	}
    options(repos=repos)
}

#' Main CRAN Mirror URL
#' 
#' \code{CRAN} simply contains the url of CRAN main mirror 
#' (\url{https://cran.r-project.org}), and aims at simplifying its use, e.g., in 
#' calls to \code{\link{install.packages}}.
#' 
#' @export
#' 
#' @docType data
#' @examples
#' \donttest{
#' install.packages('pkgmaker', repos=CRAN)
#' }
CRAN <- 'https://cran.r-project.org'


#' Adding Package Libraries
#' 
#' Prepend/append paths to the library path list, using \code{\link{.libPaths}}.
#' 
#' This function is meant to be more convenient than \code{.libPaths}, which requires 
#' more writing if one wants to:
#' \itemize{
#' \item sequentially add libraries;
#' \item append and not prepend new path(s);
#' \item keep the standard user library in the search path.
#' }
#' 
#' @param ... paths to add to .libPath
#' @param append logical that indicates that the paths should be appended
#' rather than prepended.
#' 
#' @return Returns the new set of library paths.
#' @export
#' 
#' @examples
#' ol <- .libPaths()
#' # called sequentially, .libPaths only add the last library
#' show( .libPaths('.') )
#' show( .libPaths(tempdir()) )
#' # restore
#' .libPaths(ol)
#' 
#' # .libPaths does not keep the standard user library
#' show( .libPaths() ) 
#' show( .libPaths('.') )
#' # restore
#' .libPaths(ol)
#' 
#' # with add_lib
#' show( add_lib('.') )
#' show( add_lib(tempdir()) )
#' show( add_lib('..', append=TRUE) )
#' 
#' # restore 
#' .libPaths(ol)
#' 
add_lib <- function(..., append=FALSE){
	
	p <- 
	if( append ) c(.libPaths(), ...)
	else c(..., .libPaths())
	.libPaths(p)
}


#' Package Check Utils
#' 
#' \code{isCRANcheck} \strong{tries} to identify if one is running CRAN-like checks.
#' 
#' Currently \code{isCRANcheck} returns \code{TRUE} if the check is run with 
#' either environment variable \code{_R_CHECK_TIMINGS_} (as set by flag \code{'--timings'})
#' or \code{_R_CHECK_CRAN_INCOMINGS_} (as set by flag \code{'--as-cran'}).
#' 
#' \strong{Warning:} the checks performed on CRAN check machines are on purpose not always 
#' run with such flags, so that users cannot effectively "trick" the checks.
#' As a result, there is no guarantee this function effectively identifies such checks.
#' If really needed for honest reasons, CRAN recommends users rely on custom dedicated environment 
#' variables to enable specific tests or examples.
#' 
#' @param ... each argument specifies a set of tests to do using an AND operator.
#' The final result tests if any of the test set is true.
#' Possible values are:
#' \describe{
#' \item{\code{'timing'}}{Check if the environment variable \code{_R_CHECK_TIMINGS_} is set, 
#' as with the flag \code{'--timing'} was set.}
#' \item{\code{'cran'}}{Check if the environment variable \code{_R_CHECK_CRAN_INCOMING_} is set, 
#' as with the flag \code{'--as-cran'} was set.}
#' }
#' 
#' @references Adapted from the function \code{CRAN}
#' in the \pkg{fda} package.
#' 
#' @return A logical flag.
#' 
#' @export
isCRANcheck <- function(...){
  
  tests <- list(...)
  if( !length(tests) ){ #default tests
	  tests <- list('timing', 'cran')
  }
  test_sets <- c(timing="_R_CHECK_TIMINGS_", cran='_R_CHECK_CRAN_INCOMING_')
  tests <- sapply(tests, function(x){
			  # convert named tests
			  if( length(i <- which(x %in% names(test_sets))) ){
				  y <- test_sets[x[i]]
				  x <- x[-i]
				  x <- c(x, y)
			  }
			  # get environment variables
			  evar <- unlist(sapply(x, Sys.getenv))
			  all(nchar(as.character(evar)) > 0)
		  })
  
  any(tests)
}
#' @describeIn isCRANcheck tells if one is running CRAN check with flag \code{'--timing'}.
#' 
#' @export
isCRAN_timing <- function() isCRANcheck('timing')

#' @describeIn isCRANcheck tries harder to test if running under \code{R CMD check}.
#' It will definitely identifies check runs for: 
#' \itemize{
#' \item unit tests that use the unified unit test framework defined by \pkg{pkgmaker} (see \code{\link{utest}});
#' \item examples that are run with option \code{R_CHECK_RUNNING_EXAMPLES_ = TRUE}, 
#' which is automatically set for man pages generated with a fork of \pkg{roxygen2} (see \emph{References}).
#' }
#' 
#' Currently, \code{isCHECK} checks both CRAN expected flags, the value of environment variable
#' \code{_R_CHECK_RUNNING_UTESTS_}, and the value of option \code{R_CHECK_RUNNING_EXAMPLES_}.
#' It will return \code{TRUE} if any of these environment variables is set to 
#' anything not equivalent to \code{FALSE}, or if the option is \code{TRUE}.
#' For example, the function \code{\link{utest}} sets it to the name of the package  
#' being checked (\code{_R_CHECK_RUNNING_UTESTS_=<pkgname>}), 
#' but unit tests run as part of unit tests vignettes are run with 
#' \code{_R_CHECK_RUNNING_UTESTS_=FALSE}, so that all tests are run and reported when 
#' generating them.
#' 
#' @references \url{https://github.com/renozao/roxygen}
#' @export
#' 
#' @examples
#' 
#' isCHECK()
#' 
isCHECK <- function(){
	isCRANcheck() ||  # known CRAN check flags
            !isFALSE(utestCheckMode()) ||  # unit test-specific flag
            isTRUE(getOption('R_CHECK_RUNNING_EXAMPLES_')) # roxygen generated example flag
}

#' System Environment Variables
#' 
#' @param name variable name as a character string.
#' @param raw logical that indicates if one should return the raw value or
#' the convertion of any false value to \code{FALSE}.
#' 
#' @return the value of the environment variable as a character string or 
#' \code{NA} is the variable is not defined \strong{at all}.
#' 
#' @export
#' @examples
#' 
#' # undefined returns FALSE
#' Sys.getenv_value('TOTO')
#' # raw undefined returns NA
#' Sys.getenv_value('TOTO', raw = TRUE)
#' 
#' Sys.setenv(TOTO='bla')
#' Sys.getenv_value('TOTO')
#' 
#' # anything false-like returns FALSE
#' Sys.setenv(TOTO='false'); Sys.getenv_value('TOTO')
#' Sys.setenv(TOTO='0'); Sys.getenv_value('TOTO')
#' 
#' # cleanup
#' Sys.unsetenv('TOTO')
#' 
Sys.getenv_value <- function(name, raw = FALSE){
    val <- Sys.getenv(name, unset = NA, names = FALSE)
    if( raw ) return(val)
    # convert false values to FALSE if required
    if( is.na(val) || !nchar(val) || identical(tolower(val), 'false') || val == '0' ){
        val <- FALSE
    }
    val
}

checkMode_function <- function(varname){
    
    .varname <- varname
    function(value, raw = FALSE){
        if( missing(value) ) Sys.getenv_value(.varname, raw = raw)
        else{
            old <- Sys.getenv_value(.varname, raw = TRUE)
            if( is_NA(value) ) Sys.unsetenv(.varname) # unset
            else do.call(Sys.setenv, setNames(list(value), .varname)) # set value
            # return old value
            old	
        }	
    }
}


utestCheckMode <- checkMode_function('_R_CHECK_RUNNING_UTESTS_')

is_packagedir <- function(path, type = c('both', 'install', 'dev')){
    
    type <- match.arg(type)
    switch(type,
        both = is.file(file.path(path, 'DESCRIPTION')),
        install = is.dir(file.path(path, 'Meta')),
        dev = is.file(file.path(path, 'DESCRIPTION')) && !is.dir(file.path(path, 'Meta'))
    )
}

package_buildname <- function(path, type = c('source', 'win.binary', 'mac.binary')){
    p <- as.package(path)
    type <- match.arg(type)
    
    ext <- switch(type,
            source = 'tar.gz',
            win.binary = 'zip',
            mac.binary = 'tgz')
    sprintf("%s_%s.%s", p$package, p$version, ext)
}


#' Build a Windows Binary Package
#' 
#' @param path path to a source or already installed package
#' @param outdir output directory
#' @param verbose logical or numeric that indicates the verbosity level
#' 
#' @return Invisibly returns the full path to the generated zip file.
#' @export
#' @examples 
#' \dontrun{
#' 
#' # from source directory
#' winbuild('path/to/package/source/dir/')
#' # from tar ball
#' winbuild('PKG_1.0.tar.gz')
#' 
#' }
winbuild <- function(path, outdir = '.', verbose = TRUE){
    
    # create output directory if necessary
    if( !file.exists(outdir) ) dir.create(outdir, recursive = TRUE)
    outdir <- normalizePath(outdir, mustWork = TRUE)
    
    # install package if necessary
    if( grepl("\\.tar\\.gz$", path) ){
        pkgpath <- tempfile()
        on.exit( unlink(pkgpath, recursive = TRUE), add = TRUE)
        dir.create(pkgpath)
        if( verbose ) message("* Installing tar ball ", basename(path), " in temporary library ", pkgpath, " ... ")
        p <- as.package(path, extract = TRUE)
        R.CMD('INSTALL', '-l ', pkgpath, ' ', path)
        if( verbose ) message('OK')
        path <- file.path(pkgpath, p$package)
    }
    
    # make sure it is a pure R package
    if( file.exists(file.path(path, 'src')) ){
        stop("Cannot build windows binary for non-pure R packages (detected src/ sub-directory)")
    }
    p <- as.package(path)
    
    # install package in temporary directory if necessary
    pkgpath <- p$path
    if( !is_packagedir(path, 'install') ){
        pkgpath <- tempfile()
        on.exit( unlink(pkgpath, recursive = TRUE), add = TRUE)
        dir.create(pkgpath)
        if( verbose ) message("* Building ", p$package, " and installing in temporary library ", pkgpath, " ... ", appendLF = verbose > 1)
        olib <- .libPaths()
        on.exit( .libPaths(olib), add = TRUE)
        add_lib(pkgpath)
        devtools::install(path, quiet = verbose <= 1, reload = FALSE)
        if( verbose ) message('OK')
        pkgpath <- file.path(pkgpath, p$package)
        
    }
    if( verbose ) message('* Using package installation directory ', pkgpath)
    
    # build package filename
    outfile <- file.path(outdir, package_buildname(pkgpath, 'win.binary'))
    
    ## borrowed from package roxyPackage
    owd <- getwd()
    on.exit( setwd(owd), add = TRUE)
    setwd(dirname(pkgpath))
    pkgname <- p$package
    if( verbose ) message('* Removing platform information ... ', appendLF = FALSE)
    pkgInfo <- readRDS(pkgInfo_file <- file.path(pkgpath, 'Meta/package.rds'))
    pkgInfo$Built$Platform <- ''
    saveRDS(pkgInfo, pkgInfo_file)
    if( verbose ) message('OK')
    if( verbose ) message('* Checking libs/ ... ', appendLF = FALSE)
    if( has_libs <- file.exists(libs_dir <- file.path(pkgpath, 'libs')) ) unlink(libs_dir, recursive = TRUE)
    if( verbose ) message(has_libs)
    # make a list of backup files to exclude
    win.exclude.files <- list.files(pkgname, pattern=".*~$", recursive=TRUE, full.names = TRUE)
    if(length(win.exclude.files) > 0){
        win.exclude.files <- paste0("-x \"", paste(win.exclude.files, collapse="\" \""), "\"")
    }
    if( verbose ) message('* Creating windows binary package ', basename(outfile), ' ... ', appendLF = TRUE)
    if( file.exists(outfile) ) unlink(outfile)
    zip(outfile, pkgname, extras = win.exclude.files)
    if( verbose ) message('OK')
    
    # return path to generated zip file
    invisible(outfile)
}
