# Vignette generation related functions
# 
# Author: Renaud Gaujoux
# Creation: 25 Apr 2012
###############################################################################

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
makeFakeVignette <- function(src, out, PACKAGE=NULL){
	
	# interpret template within the package directory
	if( !is.null(PACKAGE) ){
		src <- str_c(, src)
	}
	# read in template file
	l <- readLines(src)
	# extract %\Vignette commands
	vign <- l[grep("^%\\\\Vignette", l)]
	# write output file
	cat(c("\\documentclass[10pt]{article}"
		, vign
		, "\\usepackage{url}\n\\usepackage[colorlinks]{hyperref}\n\n\\begin{document}\n\\end{document}")
		, file=out, sep="\n");

}
