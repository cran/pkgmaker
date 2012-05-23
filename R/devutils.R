# Development utility functions
# 
# Author: Renaud Gaujoux
# Creation: 25 Apr 2012
###############################################################################

#' @include namespace.R
#' @include unitTests.R
#' @include logging.R
NULL

#' Executing R Commands
#' 
#' \code{R.exec} executes R commands.
#' 
#' @param ... extra arguments that are concatenated and appended to 
#' the command. 
#' 
#' @export
R.exec <- function(...){	
	system(paste(file.path(R.home(), 'bin', 'R'),' ', ..., sep=''))
}

#' \code{R.CMD} executes R CMD commands.
#' 
#' @param cmd command to run, e.g. \sQuote{check} or \sQuote{INSTALL}.
#' 
#' @export
#' @rdname R.exec
R.CMD <- function(cmd, ...){
	R.exec('CMD ', cmd, ' ', ...)
}

#' \code{R.SHLIB} executes R CMD SHLIB commands.
#' 
#' @param libname name of the output compiled library
#' 
#' @export
#' @rdname R.exec
R.SHLIB <- function(libname, ...){
	R.CMD('SHLIB', '-o ', libname, .Platform$dynlib.ext, ...)
}

#' Compile Source Files from a Development Package
#' 
#' @param pkg the name of the package to compile
#' @param load a logical indicating whether the compiled library should be loaded
#' after the compilation (default) or not.
#' 
#' @return None
#' @export
compile_src <- function(pkg, load=TRUE){
	
	if( !missing(pkg) ){
		library(devtools)
		p <- as.package(pkg)
		path <- p$path
	}else{
		pkg <- packageName()
		path <- packagePath()
	}
	
	owd <- getwd()
	on.exit(setwd(owd))
	
	# Compile code in /src
	srcdir <- file.path(path, 'src')
	if( file.exists(srcdir) ){
		cat("# DEVMODE: Compiling src/ ... ")		
		setwd(srcdir)
		Sys.setenv(R_PACKAGE_DIR=path)
		R.SHLIB(pkg, " *.cpp ")
		cat("OK\n")
		if( load )
			load_c(pkg)
	}
}

#' Package Development Utilities
#' 
#' \code{packageEnv} is a slight modification from \code{\link{topenv}}, which 
#' returns the caller's top environment, which in the case of development packages
#' is the environment into which the source files are loaded by 
#' \code{\link[devtools]{load_all}}.
#' 
#' @param pkg package name. If missing the environment of the caller package is returned.
#' 
#' @rdname devutils
#' @return an environment
#' @export
packageEnv <- function(pkg){
	
	# return package namespace
	if( !missing(pkg) ){
		# if the package is loaded: use asNamespace because as.environment does not
		# return a correct environment (don't know why)
		env <- 
		if( !is.null(path.package(pkg, quiet=TRUE)) ) asNamespace(pkg)
		else as.environment(str_c('package:', pkg))
		return(env)
	}
	
	envir = parent.frame()
	matchThisEnv = getOption("topLevelEnvironment") 
	pkgmakerEnv <- topenv()
	n <- 1
	while (!identical(envir, emptyenv())) {
		nm <- attributes(envir)[["names", exact = TRUE]]
		nm2 <- environmentName(envir)
		if ((is.character(nm) && length(grep("^package:", nm)))
				|| length(grep("^package:", nm2))
				|| identical(envir, matchThisEnv) || identical(envir, .GlobalEnv) 
				|| identical(envir, baseenv()) || isNamespace(envir) 
				|| exists(".packageName", envir = envir, inherits = FALSE)){
		
			# go through pkgmaker frames
			if( identical(envir, pkgmakerEnv) ){
				n <- n + 1
				envir <- parent.frame(n)
			}else if( identical(envir, .BaseNamespaceEnv) ){
				# this means that top caller is within the pkgmaker package
				# as it is highly improbable to evaluated within the base namespace
				# except intentionally as evalq(packageEnv(), .BaseNamespaceEnv) 
				return(pkgmakerEnv)
			}else
				return(envir)
		
		}else envir <- parent.env(envir)
	}
	return(.GlobalEnv)
}

#' \code{packageName} returns the current package's name.
#' 
#' @param .Global a logical that indicates if calls from the global 
#' environment should throw an error (\code{FALSE}: default) or the string
#' \code{'R_GlobalEnv'}.
#' 
#' @export
#' @rdname devutils
#' @return a character string
packageName <- function(.Global=FALSE){
	
	# retrieve package environment
	e <- packageEnv()
	
	# try with name from environment
	nm <- environmentName(e)
	
	if( identical(e, .GlobalEnv) && .Global ) return(nm)
	else if( isNamespace(e) ) return(nm)
	else if( grepl("^package:", nm) ) # should work for devtools packages
		return(sub("^package:", "", nm))
	
	# try to find the name from the package's environment (namespace) 
	if( exists('.packageName', e) && .packageName != 'datasets' ){
		if( .packageName != '' )
			return(.packageName)
	}
	# get the info from the loadingNamespace
	info <- getLoadingNamespace(info=TRUE)
	if( !is.null(info) ) # check whether we are loading the namespace 
		info$pkgname
	else{# error
		stop("Could not reliably determine package name [", nm, "]")
	}
}

#' \code{packagePath} returns the current package's root directory, which is 
#' its installation/loading directory in the case of an installed package, or
#' its source directory served by devtools. 
#' 
#' @param package optional name of an installed package 
#' @param ... arguments passed to \code{\link{file.path}}.
#' 
#' @rdname devutils
#' @return a character string
#' @export
packagePath <- function(..., package=NULL){
	
	# try to find the path from the package's environment (namespace)
	pname <- if( !is.null(package) ) package else packageName()
	# try installed package
	path <- system.file(package=pname)		

	# somehow this fails when loading an installed package but is works 
	# when loading a package during the post-install check
	if( is.null(path) || path == '' ){
		# get the info from the loadingNamespace
		info <- getLoadingNamespace(info=TRUE)
		path <- 
			if( !is.null(info) ) # check whether we are loading the namespace 
				file.path(info$libname, info$pkgname)
			else{# we are in dev mode: use devtools
				library(devtools)
				p <- as.package(pname)
				
				# handle special sub-directories of the package's root directory
				if( nargs() == 0 || sub("^/?([^/]+).*", "\\1", list(...)[1]) %in% c('tests', 'data','R','src') )
					p$path
				else file.path(p$path,'inst')
				
			}
	}	
	stopifnot( !is.null(path) && path != '' )
	
	# add other part of the path
	file.path(path, ...)	
}

#' Tests if a package is installed
#' 
#' @param lib.loc path to a library of R packages where to search the package
#' 
#' @rdname devutils
#' @export
isPackageInstalled <- function(..., lib.loc=NULL){
	
	inst <- utils::installed.packages(lib.loc=lib.loc)
	pattern <- '^([a-zA-Z.]+)(_([0-9.]+)?)?$';
	res <- sapply(list(...), function(p){
				vers <- gsub(pattern, '\\3', p)
				print(vers)
				pkg <- gsub(pattern, '\\1', p)
				print(pkg)
				if( !(pkg %in% rownames(inst)) ) return(FALSE);
				p.desc <- inst[pkg,]
				if( (vers != '') && compareVersion(vers, p.desc['Version']) > 0 ) return(FALSE);
				TRUE
			})
	all(res)
}

#stripLatex <- function(x){
#	gsub("\\\\.\\{(.)\\}", "\\1", x)
#}

#' \code{as.package} is enhanced version of \code{\link[devtools]{as.package}}, 
#' that is not exported not to mask the original function.
#' It could eventually be incorporated into \code{devtools} itself.
#' Extra arguments in \code{...} are passed to \code{\link{find.package}}. 
#' 
#' @param x package specified by its installation/development path or its name
#' as \code{'package:*'}.
#' @param quiet a logical that indicate if an error should be thrown if a 
#' package is not found. It is also passed to \code{\link{find.package}}.
#' 
#' 
#' @rdname devutils
as.package <- function(x, ..., quiet=FALSE){
	
	# check for 'package:*'
	if( is.character(x) ){
		i <- grep('^package:', x)
		if( length(i) > 0L ){
			x[i] <- sapply(sub('^package:', '', x[i]), find.package, ..., quiet=quiet)
		}
	}
	res <- devtools::as.package(x)
	if( !is.package(res) ) return()
	res	
}

parse_deps <- function (string) 
{
	if (is.null(string)) 
		return()
	string <- gsub("\\s*\\(.*?\\)", "", string)
	pieces <- strsplit(string, ",")[[1]]
	pieces <- gsub("^\\s+|\\s+$", "", pieces)
	pieces[pieces != "R"]
}

packageDependencies <- function(x, recursive=FALSE){
	x <- as.package(x)
	d <- lapply(x[c('depends', 'imports', 'linkingto', 'suggests')], parse_deps)
	unlist(d)
}

# taken from devtools:::install_deps but add field Suggests
install_alldeps <- function (pkg = NULL, ...) 
{
	pkg <- as.package(pkg)
	#parse_deps <- devtools:::parse_deps
	deps <- c(parse_deps(pkg$depends), parse_deps(pkg$imports), 
			parse_deps(pkg$linkingto), parse_deps(pkg$suggests))
	not.installed <- function(x) length(find.package(x, quiet = TRUE)) == 
				0
	deps <- Filter(not.installed, deps)
	if (length(deps) == 0) 
		return(invisible())
	message("Installing dependencies for ", pkg$package, ":\n", 
			paste(deps, collapse = ", "))
	install.packages(deps, ...)
	invisible(deps)
}

NotImplemented <- function(msg){
	stop("Not implemented - ", msg)
}

