# Vignette generation related functions
# 
# Author: Renaud Gaujoux
# Creation: 25 Apr 2012
###############################################################################

rnw_message <- function(...) message("# ", ...)

#' Identifying Sweave Run
#' 
#' Tells if the current code is being executed within a Sweave document.
#' 
#' @return \code{TRUE} or \code{FALSE}
#' @export
#' 
#' @examples
#' 
#' # Not in a Sweave document 
#' inSweave()
#' 
#' # Within a Sweave document
#' 
inSweave <- function(){
#	in.sweave <- FALSE
	if ((n.parents <- length(sys.parents())) >= 3) {
		for (i in seq_len(n.parents) - 1) {
			if ("chunkopts" %in% ls(envir = sys.frame(i))) {
				chunkopts = get("chunkopts", envir = sys.frame(i))
				if (all(c("prefix.string", "label") %in% names(chunkopts))) {
#					in.sweave <- TRUE
					return(TRUE)
					break
				}
			}
		}
	}
	FALSE
}

#' Generate a Fake Vignette
#' 
#' @param src original Sweave file
#' @param out output file
#' @param PACKAGE package name where to look the source vignette
#' 
#' @export
makeFakeVignette <- function(src, out, PACKAGE=NULL){
	
	# interpret template within the package directory
	if( !is.null(PACKAGE) ){
		src <- str_c(, src)
	}
	# read in template file
	l <- readLines(src)
	# extract %\Vignette commands
	vign <- l[grep("^%\\s*\\\\Vignette", l)]
	# write output file
	cat(c("\\documentclass[10pt]{article}"
		, vign
		, "\\usepackage{url}\n\\usepackage[colorlinks]{hyperref}\n\n\\begin{document}\n\\end{document}")
		, file=out, sep="\n");

}

#' LaTeX Utilities for Vignettes
#' 
#' \code{latex_preamble} outputs/returns command definition LaTeX commands to 
#' be put in the preamble of vignettes.
#' 
#' @param R logical that indicate if general R commands should be added 
#' (e.g. package names, inline R code format commands) 
#' @param CRAN logical that indicate if general CRAN commands should be added
#' (e.g. CRAN package citations) 
#' @param Bioconductor logical that indicate if general Bioconductor commands 
#' should be added (e.g. Bioc package citations) 
#' @param GEO logical that indicate if general GEOmnibus commands should be added
#' (e.g. urls to GEO datasets) 
#' @param ArrayExpress logical that indicate if general ArrayExpress commands 
#' should be added (e.g. urls to ArrayExpress datasets)
#' 
#' @param only a logical that indicates if the only the commands whose 
#' dedicated argument is not missing should be considered.
#' @param file connection where to print. If \code{NULL} the result is returned
#' silently.
#' 
#' @import stringr
#' @export
#' @rdname latex
#' @examples
#' 
#' latex_preamble()
#' latex_preamble(R=TRUE, only=TRUE)
#' latex_preamble(R=FALSE, CRAN=FALSE, GEO=FALSE)
#' latex_preamble(GEO=TRUE, only=TRUE)
#' 
latex_preamble <- function(R=TRUE, CRAN=TRUE, Bioconductor=TRUE
							, GEO=TRUE, ArrayExpress=TRUE, only=FALSE, file=''){
	cmd <- "%%%% PKGMAKER COMMANDS %%%%%%"
	
	inc <- function(arg){
		e <- parent.frame()
		(!only || eval(substitute(hasArg(arg), list(arg=substitute(arg))), e)) && arg
	}
	
	if( inc(R) ) cmd <- c(cmd, 
"% R
\\let\\proglang=\\textit
\\let\\code=\\texttt 
\\newcommand{\\Rcode}{\\code}
\\newcommand{\\pkgname}[1]{\\textit{#1}\\xspace}
\\newcommand{\\Rpkg}[1]{\\pkgname{#1} package\\xspace}
\\newcommand{\\citepkg}[1]{\\cite{#1}}
")

	if( inc(CRAN) )  cmd <- c(cmd,
"% CRAN
\\newcommand{\\CRANurl}[1]{\\url{http://cran.r-project.org/package=#1}}
%% CRANpkg
\\makeatletter
\\def\\CRANpkg{\\@ifstar\\@CRANpkg\\@@CRANpkg}
\\def\\@CRANpkg#1{\\href{http://cran.r-project.org/package=#1}{\\pkgname{#1}}\\footnote{\\CRANurl{#1}}}
\\def\\@@CRANpkg#1{\\href{http://cran.r-project.org/package=#1}{\\pkgname{#1}} package\\footnote{\\CRANurl{#1}}}
\\makeatother
%% citeCRANpkg
\\newcommand{\\citeCRANpkg}[1]{\\CRANpkg{#1}~\\cite{#1}}
\\newcommand{\\CRANnmf}{\\href{http://cran.r-project.org/package=NMF}{CRAN}}
\\newcommand{\\CRANnmfURL}{\\url{http://cran.r-project.org/package=NMF}}
")

	if( inc(Bioconductor) )  cmd <- c(cmd,
"% Bioconductor
\\newcommand{\\BioCurl}[1]{\\url{http://www.bioconductor.org/packages/release/bioc/html/#1.html}}
\\newcommand{\\BioCpkg}[1]{\\href{http://www.bioconductor.org/packages/release/bioc/html/#1.html}{\\pkgname{#1}} package\\footnote{\\BioCurl{#1}}}
\\newcommand{\\citeBioCpkg}[1]{\\BioCpkg{#1}~\\cite{#1}}
% Bioconductor annotation
\\newcommand{\\BioCAnnurl}[1]{\\url{http://www.bioconductor.org/packages/release/data/annotation/html/#1.html}}
\\newcommand{\\BioCAnnpkg}[1]{\\href{http://www.bioconductor.org/packages/release/data/annotation/html/#1.html}{\\Rcode{#1}} annotation package\\footnote{\\BioCAnnurl{#1}}}
\\newcommand{\\citeBioCAnnpkg}[1]{\\BioCAnnpkg{#1}~\\cite{#1}}
")

	if( inc(GEO) ) cmd <- c(cmd, 
"% GEO
\\newcommand{\\GEOurl}[1]{\\href{http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=#1}{#1}\\xspace}
\\newcommand{\\GEOhref}[1]{\\GEOurl{#1}\\footnote{\\url{http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=#1}}}
")

	if( inc(ArrayExpress) ) cmd <- c(cmd,
"% ArrayExpress
\\newcommand{\\ArrayExpressurl}[1]{\\href{http://www.ebi.ac.uk/arrayexpress/experiments/#1}{#1}\\xspace}
\\newcommand{\\ArrayExpresshref}[1]{\\ArrayExpressurl{#1}\\footnote{\\url{http://www.ebi.ac.uk/arrayexpress/experiments/#1}}}
")

	# output or return commands
	cmd <- c(cmd, "%%%% END: PKGMAKER COMMANDS %%%%%%\n")
	cmd <- str_c(cmd, collapse="\n")
	if( !is.null(file) ) cat(cmd, file, sep='')
	else cmd
	
}

#' \code{latex_bibliography} prints or return a LaTeX command that includes a 
#' package bibliography file if it exists.
#' 
#' @param PACKAGE package name
#' 
#' @export
#' @rdname latex
#' 
latex_bibliography <- function(PACKAGE, file=''){
	
	# get REFERENCES.bib file
	reffile <- packageReferenceFile(PACKAGE=PACKAGE)
	if( !is.file(reffile) ) return()
	
	cmd <- paste("\\bibliography{", gsub("\\.bib$", "", reffile), "}\n", sep='')
	if( !is.null(file) ) cat(cmd, file=file)
	else cmd
}

#' @importFrom methods is
is.rnw <- function(x){
	is(x, 'rnw')
}

#' Utilities for Vignettes
#' 
#' \code{rnw} provides a unified interface to run vignettes that detects
#' the type of vignette (Sweave or \code{\link[knitr]{knitr}}), and which Sweave driver 
#' to use (either automatically or from an embedded command \code{\\VignetteDriver} 
#' command).
#' 
#' @param x vignette source file specification as a path or a \code{rnw} object.
#' @param file output file
#' @param ... extra arguments passed to \code{as.rnw} that can be used to force 
#' certain building parameters.
#' @param fig.path specification for the figure path. 
#' @param cache.path specification for the cache path.
#'  
#' @rdname vignette
#' @export
rnw <- function(x, file=NULL, ..., fig.path=TRUE, cache.path=TRUE){
	x <- as.rnw(x, ...)	
	driver <- x$driver
	
	comp <- x$compiler
	res <- 
	if( comp == 'knitr' ){ # compile with knitr
		library(knitr)
		# expand path to cache to fix issue in knitr
		bname <- sub("\\..{3}$", '', basename(x$file))
		
		# cache.path
		if( !isFALSE(cache.path) ){
			if( isTRUE(cache.path) ){
				cache.path <- file.path(getwd(), 'cache', bname, '/')
			}
			opts_chunk$set(cache.path=cache.path)	
		}
		# fig.path
		if( !isFALSE(fig.path) ){
			if( isTRUE(fig.path) ){
				fig.path <- file.path(getwd(), 'figure', str_c(bname,'-'))
			}
			opts_chunk$set(fig.path=fig.path)	
		}
		
		# set other options
		opts_chunk$set(...)
		
		# run knitr
		knit(x$file, file)
		
	}else{ # compile with Sweave
		Sweave(x$file, driver=x$driver, ...)
		# move output file
		if( !is.null(file) )
			file.rename(file_extension(x$file, 'tex'), file)
	}

	# Package citations
	if( !is.null(keys <- x$cite) ){
		message("# Writing package bibtex file [", length(keys)," key(s)] ... ", appendLF=FALSE)
		write.bib(keys, file='Rpackages.bib', verbose=FALSE)
		message('OK')
	}
	#
	
	#x$compiler(x, file, ...)
	invisible(res)
}

checkFile <- function(x, msg="file '%s' does not exist."){
	if( !is.file(x) ) stop(sprintf(msg, x))
	TRUE
}

checkRnwFile <- function(x){
	if( is.rnw(x) ) x <- x$file
	checkFile(x, msg="Vignette file '%s' does not exist.")
}

#' \code{as.rnw} creates a S3 \code{rnw} object that contains information
#' about a vignette, e.g., source filename, driver, fixed included files, etc..
#' 
#' @param load logical to indicate if all the object's properties should loaded, 
#' which is done by parsing the file and look up for specific tags. 
#' 
#' @rdname vignette
#' @export
as.rnw <- function(x, ..., load = TRUE){
	
	if( is.rnw(x) ) return(x)
	
	checkRnwFile(x)
	# initialise 'rnw' object
	obj <- list()
	class(obj) <- 'rnw'
	
	# store source full path
	obj$file <- normalizePath(x)
	obj$line <- NA
	if( !load ) return(obj)
	
	# detect compiler
	obj$compiler <- rnwCompiler(obj) %||% 'Sweave'
	# detect driver
	obj$driver <- rnwDriver(obj) %||% RweaveLatex()
	# detect fixed included images
	obj$includes <- rnwIncludes(obj)
	# detect children vignettes
	obj$children <- rnwChildren(obj)
	# detect package citations
	obj$cite <- rnwCite(obj)
	
	# override with passed extra arguments
	if( nargs() > 1L ){
		dots <- list(...)
		obj[names(dots)] <- dots
	}
	
	# return object
	obj
} 

rnwObject <- function(...) as.rnw(..., load=FALSE)

#' \code{rnwDriver} tries to detect the vignette compiler to use on a vignette
#' source file, e.g., \code{\link{Sweave}} or \code{\link[knitr]{knitr}}.
#' 
#' @rdname vignette
#' @export
rnwCompiler <- function(x){
	
	x <- rnwObject(x)
	
	# read all lines in
	l <- readLines(x$file)
	
	# identify driver
	dr <- str_match(l, "^\\s*%\\s*\\\\VignetteCompiler\\{([^}]*)\\}")
	w <- which(!is.na(dr[,1L]))
	if( length(w) > 0L ){
		s <- str_trim(dr[w[1L],2L])
		rnw_message("Detected compiler: '", s, "'")
		s
	}
	
}  


#' \code{rnwDriver} tries to detect Sweave driver to use on a vignette source 
#' file, e.g., \code{SweaveCache}, \code{highlight}, etc..
#' 
#' @rdname vignette
#' @export
rnwDriver <- function(x){
	
	x <- rnwObject(x)
	
	# read all lines in
	l <- readLines(x$file)
	
	# identify driver
	dr <- str_match(l, "^\\s*%\\s*\\\\VignetteDriver\\{([^}]*)\\}")
	w <- which(!is.na(dr[,1L]))
	if( length(w) > 0L ){
		s <- dr[w[1L],2L]
		rnw_message("Detected Vignette driver: '", str_trim(s), "'")
		# eval text
		eval(parse(text=s))
	}
	
}  

#' \code{rnwIncludes} detects fixed includes, e.g., image or pdf files, that are 
#' required to build the final document.  
#' 
#' @rdname vignette
#' @export
rnwIncludes <- function(x){
	
	x <- rnwObject(x)
	
	# read all lines in
	l <- readLines(x$file)
	
	# identify driver
	dr <- suppressWarnings(str_match(l, "^\\s*\\\\((include)|(includegraphics)|(input))\\{([^}]*)\\}"))
	w <- which(!is.na(dr[,1L]))
	rnw_message("Detected includes: ", appendLF=FALSE)
	if( length(w) > 0L ){
		inc <- str_trim(dr[w,6L])
		message(str_out(inc))
		inc
	}else
		message("NONE")
	
}

#' \code{rnwChildren} detects included vignette documents and return them as a 
#' list of vignette objects.  
#'  
#' @rdname vignette
#' @export
rnwChildren <- function(x){
	
	x <- rnwObject(x)
	
	# read all lines in
	l <- readLines(x$file)
	
	# identify driver
	dr <- str_match(l, "^\\s*\\\\SweaveInput\\{([^}]*)\\}")
	w <- which(!is.na(dr[,1L]))
	if( length(w) > 0L ){
		inc <- dr[w,2L]
		rnw_message("Detected children: ", str_out(inc, Inf))
		owd <- setwd(dirname(x$file))
		on.exit( setwd(owd) )
		mapply(as.rnw, inc, line=w, SIMPLIFY=FALSE)
	}
	
}  

rnwCite <- function(x){
	
	x <- rnwObject(x)
	
	# read all lines in
	l <- readLines(x$file)
	
	# identify driver
	dr <- str_match(l, "\\\\cite((CRAN)|(BioC)|(BioCAnn))pkg\\{([^}]*)\\}")
	w <- which(!is.na(dr[,6L]))
	rnw_message("Detected package citation: ", appendLF=FALSE)
	if( length(w) > 0L ){
		inc <- unique(str_trim(dr[w,6L]))
		message(str_out(inc))
		inc
	}else
		message("NONE")
}

#' \code{vignetteMakefile} returns the path to a generic makefile used to make 
#' vignettes.
#' 
#' @param package package name
#' @param user username of the package's author. It is used to compile the 
#' vignette differently when called locally or on CRAN check machines.  
#' @param print logical that specifies if the path should be printed or
#' only returned.  
#' 
#' @rdname vignette
#' @export
vignetteMakefile <- function(user, package, print=TRUE){
	
	# create makefile from template
	p <- packagePath('vignette.mk', package='pkgmaker')
	l <- paste(readLines(p), collapse="\n") 
	l <- sub('#%AUTHOR_USER%#', str_c('AUTHOR_USER=', user), l, fixed=TRUE)
	l <- sub('#%MAKE_R_PACKAGE%#', str_c('MAKE_R_PACKAGE=', package), l, fixed=TRUE)
	
	mk <- tempfile('vignette_', tmpdir='.', fileext='.mk')
	cat(l, file=mk)
	if ( print ){
		cat(mk)
	}
	invisible(l)
}