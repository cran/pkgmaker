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
	cmd <- paste(file.path(R.home(), 'bin', 'R'),' ', ..., sep='')
	print(cmd)
	system(cmd)
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
compile_src <- function(pkg=NULL, load=TRUE){
	
	if( !is.null(pkg) ){
		library(devtools)
		p <- as.package(pkg)
		path <- p$path
	}else{
		pkg <- packageName()
		path <- packagePath(lib=NA) # do not look installed packages
	}
	
	owd <- getwd()
	on.exit(setwd(owd))
	
	# Compile code in /src
	srcdir <- file.path(path, 'src')
	message("# Checking '", srcdir, "' ... ", appendLF=FALSE)
	if( !file.exists(srcdir) ){
		message("NO")
	} else {
		message("YES")
		message("## Compiling '",srcdir,"' ##")
		setwd(srcdir)
		Sys.setenv(R_PACKAGE_DIR=path)
		R.SHLIB(pkg, " *.cpp ")
		message("## DONE")
		if( load )
			load_c(pkg)
	}
}

#' Package Development Utilities
#' 
#' \code{packageEnv} is a slight modification from \code{\link{topenv}}, which 
#' returns the top environment, which in the case of development 
#' packages is the environment into which the source files are loaded by 
#' \code{\link[devtools]{load_all}}.
#' 
#' @param pkg package name. If missing the environment of the runtime caller 
#' package is returned.
#' @param skip a logical that indicates if the calling namespace should be 
#' skipped.
#' @param verbose logical that toggles verbosity
#' 
#' @rdname devutils
#' @return an environment
#' @export
packageEnv <- function(pkg, skip=FALSE, verbose=FALSE){
	
	# return package namespace
	if( !missing(pkg) ){
		# - if the package is loaded: use asNamespace because as.environment does not
		# return a correct environment (don't know why)
		# - as.environment('package:*') will return the correct environment
		# in dev mode.
		env <- 
		if( !is.null(path.package(pkg, quiet=TRUE)) ) asNamespace(pkg)
		else if( isLoadingNamespace(pkg) ) getLoadingNamespace(env=TRUE)
		else if( pkg %in% search() ) as.environment(pkg)
		else as.environment(str_c('package:', pkg)) # dev mode
		return(env)
	}
	
	envir = parent.frame()
#	message("parent.frame: ", str_ns(envir))
	pkgmakerEnv <- topdevenv()
#	message("pkgmaker ns: ", str_ns(pkgmakerEnv))

	n <- 1
	skipEnv <- pkgmakerEnv
	while( identical(e <- topdevenv(envir), skipEnv) 
			&& !identical(e, emptyenv()) 
			&& !identical(e, .GlobalEnv) ){
		if( verbose > 1 ) print(e)
		n <- n + 1
		envir <- parent.frame(n)
	}
	
	if( !skip ){
		if( identical(e, .BaseNamespaceEnv) ){
			if( verbose ) message("packageEnv - Inferred ", str_ns(skipEnv))
			return( skipEnv )
		}
		if( verbose ) message("packageEnv - Detected ", str_ns(e))
		return(e)
	}
	if( verbose > 1 ) message("Skipping ", str_ns(skipEnv))
	# go up one extra namespace
	skipEnv <- e
	while( identical(e <- topdevenv(envir), skipEnv) 
			&& !identical(e, emptyenv()) 
			&& !identical(e, .GlobalEnv) ){
		if( verbose > 1 ) print(e)
		n <- n + 1
		envir <- parent.frame(n)
	}
	if( identical(e, .BaseNamespaceEnv) ){
		if( verbose ) message("packageEnv - Inferred ", str_ns(skipEnv))
		return( skipEnv )
	}
	if( verbose ) message("packageEnv - Detected ", str_ns(e))
	return(e)
		
##   message("skip ns:")
##	print(skipEnv)
#	n <- 1
##	i <- -1
#	while (!identical(envir, emptyenv())) {
##		i <- i + 1
##		message("i=", i)
##		print(envir)
#		nm <- attributes(envir)[["names", exact = TRUE]]
#		nm2 <- environmentName(envir)
#		if ((is.character(nm) && length(grep("^package:", nm)))
#				|| length(grep("^package:", nm2))
#				|| identical(envir, matchThisEnv) || identical(envir, .GlobalEnv) 
#				|| identical(envir, baseenv()) || isNamespace(envir) 
#				|| exists(".packageName", envir = envir, inherits = FALSE)){
#		
#			# go through pkgmaker frames, and skip caller namespace if requested
#			if( identical(envir, pkgmakerEnv) 
#					|| (!is.null(skipEnv) && identical(envir, skipEnv)) ){
#				n <- n + 1
#				envir <- parent.frame(n)
#			}else if( identical(envir, .BaseNamespaceEnv) ){
#				# this means that top caller is within the pkgmaker package
#				# as it is highly improbable to evaluated within the base namespace
#				# except intentionally as evalq(packageEnv(), .BaseNamespaceEnv)
#    			if( !is.null(skipEnv) ) return(skipEnv)
#				else return(pkgmakerEnv)
#			}else
#				return(envir)
#		
#		}else envir <- parent.env(envir)
#	}
#	return(.GlobalEnv)
}

topdevenv <- function (envir = parent.frame(), matchThisEnv = getOption("topLevelEnvironment")) {
	
	while (!identical(envir, emptyenv())) {
		nm <- attributes(envir)[["names", exact = TRUE]]
		nm2 <- environmentName(envir)
		if ((is.character(nm) && length(grep("^package:", nm)))
				|| length(grep("^package:", nm2))
				|| identical(envir, matchThisEnv) || identical(envir, .GlobalEnv) 
				|| identical(envir, baseenv()) || isNamespace(envir) 
				|| exists(".packageName", envir = envir, inherits = FALSE)){
			return(envir)
		}else envir <- parent.env(envir)
	}
	return(.GlobalEnv)
}

#' \code{toppackage} returns the runtime top namespace, i.e. the namespace of 
#' the top calling namespace, skipping the namespace where \code{toppackage} 
#' is effectively called.
#' This is useful for packages that define functions that need to access the 
#' calling namespace, even from calls nested into calls to another function from
#' the same package -- in which case \code{topenv} would not give the desired 
#' environment.   
#'  
#' @rdname devutils
#' @export
toppackage <- function(verbose=FALSE){
	packageEnv(skip=TRUE, verbose=verbose)
}

#' \code{packageName} returns the current package's name.
#' 
#' @param envir environment where to start looking for a package name.
#' The default is to use the \strong{runtime} calling package environment.
#' @param .Global a logical that indicates if calls from the global 
#' environment should throw an error (\code{FALSE}: default) or the string
#' \code{'R_GlobalEnv'}.
#' @param rm.prefix logical that indicates if an eventual prefix 'package:' 
#' should be removed from the returned string.
#' 
#' @export
#' @rdname devutils
#' @return a character string
packageName <- function(envir=packageEnv(), .Global=FALSE, rm.prefix=TRUE){
	
	if( is.null(envir) ) envir <- packageEnv() 
	if( is.character(envir) ){
		return( sub("^package:", "", envir) )
	}
	
	# retrieve package environment
	e <- envir
	
	# try with name from environment
	nm <- environmentName(e)
	if( identical(e, .GlobalEnv) && .Global ) return(nm)
	else if( isNamespace(e) || identical(e, baseenv()) ) return(nm)
	else if( grepl("^package:", nm) ){# should work for devtools packages
		if( rm.prefix ) 
			nm <- sub("^package:", "", nm)
		return(nm)
	}
	
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

#' \code{str_ns} formats a package environment/namespace for log/info messages.
#' 
#' @rdname devutils
#' @export
str_ns <- function(envir=packageEnv()){
	if( !is.environment(envir) )
		stop("Invalid argument: must be an environment [", class(envir), ']')
	str_c(if( isNamespace(envir) ) 'namespace' else 'environment',
			" '", packageName(envir, rm.prefix=FALSE), "'")
}


#' \code{packagePath} returns the current package's root directory, which is 
#' its installation/loading directory in the case of an installed package, or
#' its source directory served by devtools. 
#' 
#' @param package optional name of an installed package 
#' @param lib path to a package library where to look. If \code{NA}, then only 
#' development packages are looked up.
#' @param ... arguments passed to \code{\link{file.path}}.
#' 
#' @rdname devutils
#' @return a character string
#' @export
packagePath <- function(..., package=NULL, lib=NULL){
	
	# try to find the path from the package's environment (namespace)
	pname <- packageName(package)
	# try installed package
	path <- if( !isNA(lib) ) system.file(package=pname, lib.loc=lib)		

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
				dots <- list(...)
				Rdirs <- c('data', 'R', 'src', 'exec', 'tests', 'demo'
							, 'exec', 'libs', 'man', 'help', 'html'
							, 'Meta')
				if( length(dots) == 0L || sub("^/?([^/]+).*", "\\1", ..1) %in%  Rdirs)
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
	if( !devtools::is.package(res) ) return()
	res	
}

NotImplemented <- function(msg){
	stop("Not implemented - ", msg)
}
