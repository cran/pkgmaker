# General utility functions
# 
# Author: Renaud Gaujoux
# Creation: 25 Apr 2012
###############################################################################

# or-NULL operator
'%||%' <- function(x, y) if( !is.null(x) ) x else y

#' Get Anywhere
#' 
#' Similar to \code{\link{getAnywhere}}, but looks for the value of its argument. 
#' 
#' @param x a single character string
#' 
#' @export
cgetAnywhere <- function(x){
	do.call("getAnywhere", list(x))
}

#' Silent Require
#' 
#' Silently require a package.
#' 
#' @inheritParams base::require
#' @param ... extra arguments passed to \code{\link{require}}.
#' 
#' @export
require.quiet <- function(package, character.only = FALSE, ...){
	
	if( !character.only )
		package <- as.character(substitute(package))
	utils::capture.output(suppressMessages(suppressWarnings(
	 res <- do.call('require', 
			 list(package=package, ..., character.only=TRUE, quietly=TRUE))
	)))
	res
}

#' Require a Package
#' 
#' Require a package with a custom error message
#' 
#' @param pkg package name as a character string
#' @param ... extra arguments concatenated to for the header of the 
#' error message 
#' 
#' @export
requirePackage <- function(pkg, ...){
	
	if( !require(pkg, character.only=TRUE) ){
		if( nargs() > 1L ) stop(..., " requires package(s) ", str_out(pkg))
		else stop("Could not find required package(s) ", str_out(pkg))
	}
}


#' Testing R Version
#' 
#' Compares current R version with a given target version, which may be useful  
#' for implementing version dependent code. 
#' 
#' @param x target version to compare with. 
#' @param test numeric value that indicates the comparison to be carried out.
#' The comparison is based on the result from 
#' \code{utils::compareVersion(R.version, x)}:
#' \itemize{
#' \item 1: is R.version > \code{x}?
#' \item 0: is R.version = \code{x}?
#' \item -1: is R.version < \code{x}?
#' } 
#' 
#' @return a logical
#' @export
#' @examples
#' 
#' testRversion("2.14")
#' testRversion("2.15")
#' testRversion("2.30")
#' testRversion("2.30", -1)
#' testRversion("2")
#' testRversion(Rversion())
#' 
testRversion <- function(x, test=1L){
	rv <- Rversion()
	utils::compareVersion(rv, x) == test
}

#' Complete R version
#' 
#' Returns the complete R version, e.g. 2.15
#' 
#' @export
#' @examples
#' Rversion()
#' 
Rversion <- function(){
	paste(R.version$major, R.version$minor, sep='')
}

as.package2 <- function(x, error=TRUE){
	
	res <- tryCatch(devtools::as.package(x), error= function(e) e)
	if( !is.package(res) ){
		#str(res)
		if( error ) stop(res$message)
		return()
	}
	res
}

# taken from devtools:::install_deps but add field Suggests
install_alldeps <- function (pkg = NULL) 
{
	pkg <- as.package(pkg)
	parse_deps <- devtools:::parse_deps
	deps <- c(parse_deps(pkg$depends), parse_deps(pkg$imports), 
			parse_deps(pkg$linkingto), parse_deps(pkg$suggests))
	not.installed <- function(x) length(find.package(x, quiet = TRUE)) == 
				0
	deps <- Filter(not.installed, deps)
	if (length(deps) == 0) 
		return(invisible())
	message("Installing dependencies for ", pkg$package, ":\n", 
			paste(deps, collapse = ", "))
	install.packages(deps)
	invisible(deps)
}

#' Prints formatted list of values given as a character vector for use in show 
#' methods or error/warning messages.
#' 
#' @param x character vector
#' @param max maximum number of values to appear in the list. If \code{x} has 
#' more elements than \code{max}, a \code{"..."} suffix is appended.
#' @param quote a logical indicating whether the values should be quoted with 
#' single quotes (defaults) or not. 
#' @param use.names a logical indicating whether names should be added to the 
#' list as \code{NAME=VAL, ...} or not (default).
#' @param sep separator character
#' 
#' @return a single character string
#' 
#' @examples
#' 
#' x <- letters[1:10]
#' str_out(x)
#' str_out(x, 8)
#' str_out(x, Inf)
#' str_out(x, quote=FALSE)
#' 
#' @export
str_out <- function(x, max=3L, quote=is.character(x), use.names=FALSE, sep=", "){
	if( isNA(max) ) max <- Inf
	suffix <- if( length(x) > max ) ", ..."
	x <- head(x, max)
	
	# add quotes if necessary
	quote <- 
			if( isTRUE(quote) ) "'"
			else if( is.character(quote) ) quote
	if( !is.null(quote) ) x <- unlist(lapply(x, function(v) paste(quote,v,quote, sep='')))
	# add names if necessary
	if( use.names && !is.null(names(x)) ){
		nm <- str_c(names(x),'=')
		x <- paste(ifelse(nm=='=',NULL,nm), x, sep='')
	}
	paste(paste(x, collapse=sep), suffix, sep='')
}

#' Builds formatted string from a list of complex values.
#' 
#' @param object an R object
#' @param exdent extra indentation passed to str_wrap, and used if the output 
#' should spread over more than one lines.
#' 
#' @rdname str_out
#' @export
str_desc <- function(object, exdent=0L){
	p <- sapply(object, function(x){
				if( is.atomic(x) && length(x) == 1L ) x
				else paste("<", class(x), ">", sep='')
			})
	str_wrap(str_out(p, NA, use.names=TRUE, quote=FALSE), exdent=exdent)
}

#' Differences between strings
#' 
#' Computes which characters differ between two strings.
#' 
#' @param x a single string
#' @param y a single string
#' @return an integer vector containing the index of the mis-matched character 
#' @export
#' 
#' @examples
#' 
#' x <- "once upon a time"
#' y <- "once upon a time there was"
#' z <- "once upon two times"
#' str_diff(x, x)
#' str_diff(x, y)
#' str_diff(x, z)
#' str_diff(y, z)
#' 
str_diff <- function(x, y){
	sx <- strsplit(x,'')[[1]]
	sy <- strsplit(y,'')[[1]]
	n <- min(length(sx), length(sy))
	res <- mapply('!=', head(sx,n), head(sy,n))
	wres <- which(res)
	attr(wres, 'str') <- list(x=x,y=y)
	class(wres) <- 'str_diff'
	wres
}

#' @S3method print str_diff
print.str_diff <- function(x, ...){
	s <- attr(x, 'str')
	n <- min(length(s$x), length(s$y))
	d <- head(s$x,n)
	d[!x] <- '*'
	cat(str_c(s$x, collapse=''), "\n")
	cat(str_c(d, collapse=''), "\n")
	cat(str_c(s$y, collapse=''), "\n")				
}

#' Extracting Local Function Definition
#' 
#' @description
#' \code{extractLocalFun} Extracts local function from wrapper functions of the following type, typically 
#' used in S4 methods:
#' \samp{
#' function(a, b, ...)\{
#' 	.local <- function(a, b, c, d, ...)\{\}
#'	.local(a, b, ...)
#' \}
#' }
#'
#' @param f definition of the wrapper function
#' 
#' @return a function
#' @export
#' @rdname formals
extractLocalFun <- function(f){
	bf <- body(f)
	
	txt <- as.character(bf)[2]
	# in R-2.14.2 -- at least, as.character does not return the complete body
	# so some text manipulation is necessary 
	if( !grepl("\\{", txt) ){
		sf <- capture.output(print(bf))
		w <- tail(grep("^\\s*\\.local\\(", sf), 1L)
		txt <- paste(sf[-w], collapse="\n")
	}
	expr <- parse(text=txt)
	e <- new.env()
	eval(expr, e)
} 

#' Extended Formal Extraction
#'
#' Works for methods that are created (setMethod) as a wrapper function to an 
#' internal function named .local.
#'
#' @inheritParams extractLocalFun
#' @return a paired list like the one returned by \code{\link{formals}}. 
#' 
#' @export
#' @importFrom codetools getAssignedVar
#' @rdname formals
allFormals <- function(f){
	
	# look inside method for S4 methods
	if( is(f, 'MethodDefinition') ){
		
		# check if the method is defined as a wrapper function
		f <- f@.Data
		lf <- try(codetools::getAssignedVar(body(f)), silent=TRUE)
		if( !identical(lf, '.local') ) return( formals(f) )
		# extract arguments from local function
		lfun <- extractLocalFun(f)
		res <- formals(lfun)
		# set default values from the generic, only for arguments that have no 
		# default values in the method
		generic_args <- formals(f)
		meth_no_default <- sapply(res, is.symbol) 
		gen_no_default <- sapply(generic_args, is.symbol)
		generic_args <- generic_args[ !gen_no_default ]
		generic_args <- generic_args[ names(generic_args) %in% names(res[meth_no_default]) ]
		if( length(generic_args) ){
			res[names(generic_args)] <- generic_args
		}
		# return complete list of arguments
		res
		
	}else if( is.function(f) ) formals(f)
	
}

#' Alternative S4 Constructor
#' 
#' An alternative version of \code{\link{new}} to create objects based on a list
#' of values. 
#' 
#' @param class Class name to instanciate
#' @param ... extra arguments from which slot values are extracted by exact 
#' matching of names.
#' 
#' @export
#' @examples
#' 
#' setClass('A', contain='character', representation(x='numeric', y='character'))
#' 
#' # identical behaviour with standard calls
#' identical(new('A'), new2('A'))
#' identical(new('A', x=1), new2('A', x=1))
#' 
#' # but if passing that are names not slots 
#' identical(new('A'), new2('A', b=1))
#' identical(new('A', x=1), new2('A', x=1, b=3))
#' identical(new('A', x=1), new2('A', x=1, b=3))
#' 
#' # standard `new` would coerce first unnamed argument into parent of 'A' (i.e. 'character') 
#' new('A', list(x=1))
#' new('A', list(x=1, y='other'))
#' # `new2` rather use it to initialise the slots it can find in the list 
#' identical(new('A', x=1), new2('A', list(x=1)))
#' identical(new('A', x=1, y='other'), new2('A', list(x=1, y='other')))
#' 
#' 
new2 <- function(class, ...){
	sl <- getSlots(class)
	if( nargs() == 1L ) return( new(class) )
	
	dots <- list(...)
	if( nargs() == 2L && is.null(names(dots)) ){
		l <- dots[[1]]
		if( !is.list(l) )
			stop("Invalid call: single unnamed argument must be a list")
		dots <- l
	}
	
	if( is.null(names(dots)) || any(names(dots)=='') )
		stop("Invalid call: all slot arguments must be named")
	dots <- dots[names(dots) %in% names(sl)]
	do.call('new', c(list(class), dots))
}


#' One-off Global Variables
#' 
#' Defines a function that allow to get/assign a global variable whose value is 
#' ensured to be reset after each access.
#'   
#' @param default default value to which the global variable is reset after each 
#' access. Default is \code{NULL}.
#' 
#' @return a function with one argument (\code{value}) that provides get/set access
#' to a global variable.
#' If called with a value, it assigns this value to the global variable.
#' If called with no argument, it returns the current value of the global variable and 
#' reset it to its default value -- as defined at its creation. 
#'
#' @export
#' 
#' @examples
#' 
#' x <- oneoffVariable(0)
#' # returns default value
#' x()
#' # assign a value
#' x(3)
#' # get the value
#' x()
#' # second call returns default value again 
#' x()
#'  
oneoffVariable <- function(default=NULL){
	.var <- default
	function(value){
		if( missing(value) ){
			res <- .var
			.var <<- default
			res
		}else
			.var <<- value
	}
}


##  Exit Error Checker
##  
##  This function defines a function that checks if an error has been 
##  thrown after its definition.
##  It may be used to perform tasks on function exit depending on 
##  how the function exit (normal return or with an error).
##  
##  The function \code{errorCheck} itself is meant to be called at 
##  the beginning of functions that use \code{\link{on.exit}} to 
##  perform tasks when exiting.
##  The error checker function returned, when used in \code{on.exit} 
##  expressions, enables to distinguish between a normal exit and 
##  an exit due to an error, allowing is to perform tasks specific 
##  to each scenario.
##  
##  IMPORTANT: this function is not 100\% perfect in the sense that 
##  it will detect an error as soon as one has been thrown, even it 
##  is catched before the exit -- with \code{\link{try}} or 
##  \code{\link{tryCatch}}.
##  
##  @export
##  @examples 
##  
##  # define some function
##  f <- function(err){
##  
##   # initialise an error checker
##  	isError <- errorCheck()
##  
##   # do something on exit that depends on the error status
##  	on.exit({
##  		if(isError()) cat("with error: cleanup\n") 
##  		else cat("no error: do nothing\n") 
##  	})
##  	
##   # throw an error here
##  	if( err ) stop('There is an error')
##   
##  	1+1
##  }
##  
##  # without error
##  f(FALSE)
##  # with error
##  try( f(TRUE) )
##  
#errorCheck <- function(){
#	
#	# initialise with unique error message
#	.err <- tryCatch(stop('ERROR_CHECK:', digest(tempfile())), error=function(e) conditionMessage(e))
#	tb_digest <- function() digest(capture.output(traceback(max.lines=NULL)))
#	.traceback <- tb_digest()
#	
#	function(){
#		# error message is different
#		# tb_digest() != .traceback
#		length(grep(.err, msg, fixed=TRUE, invert=TRUE)) == 1L
#	}
#}


# Static Variable
sVariable <- function(default=NULL){
	.val <- default
	function(value){
		if( missing(value) ) .val
		else{
			old <- .val
			.val <<- value
			old
		}
	}
}

#' Exit Error Checks
#' 
#' \code{exitCheck} provides a mechanism to distinguish the exit status
#' in \code{\link{on.exit}} expressions.
#' 
#' It generates a function that is used wihtin a function's body to 
#' "flag" normal exits and in its \code{\link{on.exit}} expression
#' to check the exit status of a function.
#' Note that it will correctly detect errors only if all normal exit 
#' are wrapped into a call to it. 
#' 
#' @export
#' 
#' @examples
#' 
#' # define some function
#' f <- function(err){
#' 
#'  # initialise an error checker
#' 	success <- exitCheck()
#' 
#'  # do something on exit that depends on the error status
#' 	on.exit({
#' 		if(success()) cat("no error: do nothing\n") 
#' 		else cat("error: cleqnup mess\n") 
#' 	})
#' 	
#'  # throw an error here
#' 	if( err ) stop('There is an error')
#'  
#' 	success(1+1)
#' }
#' 
#' # without error
#' f(FALSE)
#' # with error
#' try( f(TRUE) )
#' 
exitCheck <- function(){
	
	.success <- FALSE
	function(x){
		if( nargs() == 0L ) .success
		else{
			.success <<- TRUE
			x
		}
	}
}
