# Namespace related functions
# 
# Author: Renaud Gaujoux
# Creation: 30 Apr 2012
###############################################################################

#' Namespace Development Functions
#' 
#' \code{getLoadingNamespace} returns information about the loading namespace.
#' It is a wrapper to \code{\link{loadingNamespaceInfo}}, that does not throw 
#' an error.
#' 
#' @param env logical that indicates that the namespace's environment (i.e. the 
#' namespace itself) should be returned.
#' @param info logical that indicates that the complete information list should 
#' be returned
#' 
#' @return the name of the loading namespace if \code{env} and \code{info} are 
#' \code{FALSE}, an environment if \code{env=TRUE}, a list with elements 
#' \code{pkgname} and \code{libname} if \code{info=TRUE}. 
#' 
#' @rdname namespace
#' @export
#' 
getLoadingNamespace <- function(env=FALSE, info=FALSE){
	is.loading <- try(nsInfo <- loadingNamespaceInfo(), silent=TRUE)
	if( !is(is.loading, 'try-error') ){
		if( env ) asNamespace(as.name(nsInfo$pkgname))
		else if( info ) nsInfo 
		else nsInfo$pkgname
	}
	else NULL
}

#' Tests if a namespace is being loaded.
#' 
#' @param name the name of a namespace whose loading state is tested.
#' If missing \code{isLoadingNamespace} test if any namespace is being loaded.
#' 
#' @rdname namespace
#' @export
isLoadingNamespace <- function(name){
	ns <- getLoadingNamespace()
	!is.null(ns) && (missing(name) || ns==name)
}

#' Tests if a given namespace is loaded, without loading it, contrary to 
#' \code{\link{isNamespace}}.
#' 
#' @rdname namespace
#' @export
isNamespaceLoaded <- function(name){
	name %in% loadedNamespaces()
}


#' Dynamically adds exported objects into the loading namespace.   
#' 
#' @param x character vector containing the names of R objects to export in the 
#' loading namespace.
#' 
#' @rdname namespace
#' @export
addNamespaceExport <- function(x){
	ns <- pkgmaker::getLoadingNamespace(env=TRUE)
	if( !is.null(ns) ){
		namespaceExport(ns, x)
	}
}
