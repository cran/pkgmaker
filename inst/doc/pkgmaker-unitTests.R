### R code from vignette source 'pkgmaker-unitTests.Rnw'

###################################################
### code chunk number 1: pkgmaker-unitTests.Rnw:10-15
###################################################
pkg <- 'pkgmaker'
require( pkg, character.only=TRUE )
prettyVersion <- packageDescription(pkg)$Version
prettyDate <- format(Sys.Date(), '%B %e, %Y')
authors <- packageDescription(pkg)$Author


