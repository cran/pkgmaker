## This Makefile automates common tasks in R package developement
## Copyright (C) 2013 Renaud Gaujoux

#%AUTHOR_USER%#
#%MAKE_R_PACKAGE%#
#%R_PACKAGE_PATH%#
#%R_PACKAGE_TAR_GZ%#

#%INIT_CHECK%#

ifndef MAKE_R_PACKAGE
#$(error Required make variable 'MAKE_R_PACKAGE' is not defined.)
endif
ifndef R_PACKAGE_PATH
R_PACKAGE_PATH=../pkg
endif

ifdef devel
RSCRIPT=Rdscript
RCMD=Rdevel
endif

ifndef R_BIN
#%R_BIN%#
endif
ifndef RSCRIPT
RSCRIPT:=$(R_BIN)/Rscript
endif
ifndef RCMD
RCMD:=$(R_BIN)/R
endif

# CHECK COMMAND
#%R_CMD_CHECK%#
define CMD_CHECK
library(devtools);
library(methods);
p <- as.package('$(R_PACKAGE_PATH)');
pdir <- p[['path']];
src <- paste0(p[['package']], '_', p[['version']], '.tar.gz')
rlibs <- NULL
if( file.exists(devlib <- file.path(dirname(pdir), 'lib')) ){
	rlibs <- paste0("R_LIBS=", devlib, ' ')
}
Rbin <- file.path(R.home('bin'), 'R')
cmd <- paste0(rlibs, Rbin, " CMD check --as-cran --timings ", src)
message("R CMD check command:\n", cmd)
system(cmd, intern=FALSE, ignore.stderr=FALSE)
endef
export CMD_CHECK


# ROXYGEN COMMAND
define CMD_ROXYGEN
library(devtools);
library(methods);
p <- as.package('$(R_PACKAGE_PATH)');
pdir <- p[['path']]
message("Package directory: ", pdir)
dev_mode(path=file.path(dirname(pdir), 'lib'))
load_all('~/projects/roxygen2')
err <- try( roxygenize(pdir) )
if( is(err, 'try-error') ) traceback()
warnings()
endef
export CMD_ROXYGEN

# STATICDOCS COMMAND
define CMD_STATICDOCS
library(devtools);
library(methods);
p <- as.package('$(R_PACKAGE_PATH)');
pdir <- p[['path']];
message("Package directory: ", pdir);
dev_mode(path=file.path(dirname(pdir), 'lib'))
load_all('~/projects/staticdocs');
destdir <- file.path(pdir, file.path(c('../www', '../../www'), p[['package']]));
if( basename(pdir) == 'pkg' ) destdir <- c(destdir, file.path(pdir, '../www'));
id <- which(file.exists(destdir));
if( !length(id) ) id <- 1L;
destdir <- destdir[id[1L]];
message("Staticdoc directory: ", destdir);
options(warn=1);
build_package(pdir, destdir, examples=TRUE);
warnings();
endef
export CMD_STATICDOCS


# VIGNETTES COMMAND
define CMD_VIGNETTES
library(devtools);
library(methods);
p <- as.package('$(R_PACKAGE_PATH)');
pdir <- p[['path']]
message("Package directory: ", pdir)
dev_mode(path=file.path(dirname(pdir), 'lib'))
library(pkgmaker);
tmp <- quickinstall(pdir, tempfile());
library(p[['package']], lib=tmp, character.only=TRUE) 
library(tools); 
buildVignettes(p[['package']])
endef
export CMD_VIGNETTES

# PACKAGE_TAR COMMAND
define CMD_PACKAGE_TAR
library(devtools);
library(methods);
p <- as.package('$(R_PACKAGE_PATH)');
pdir <- p[['path']];
cat(paste0(p[['package']], '_', p[['version']], '.tar.gz'));
endef
export CMD_PACKAGE_TAR

# BUILD-BINARIES COMMAND
define CMD_BUILD_BINARIES
library(devtools);
library(methods);
p <- as.package('$(R_PACKAGE_PATH)');
pdir <- p[['path']];
src <- paste0(p[['package']], '_', p[['version']], '.tar.gz')
run <- function(){
tmp <- tempfile()
on.exit( unlink(tmp, recursive=TRUE) )
cmd <- paste0("wine R CMD INSTALL -l ", tmp, ' --build ', src)
message("R CMD check command:\n", cmd)
system(cmd, intern=FALSE, ignore.stderr=FALSE)
}
run()
endef
export CMD_BUILD_BINARIES

all: roxygen build check 

dist: all staticdoc

init:

build:
	@cd checks && \
	echo "\n*** STEP: BUILD\n" && \
	$(RCMD) CMD build $(R_PACKAGE_PATH) && \
	echo "*** DONE: BUILD"
	
build-bin: build
	@cd checks && \
	echo "\n*** STEP: BUILD-BINARIES\n" && \
	`echo "$$CMD_BUILD_BINARIES" > build-bin.r` && \
	$(RSCRIPT) --vanilla ./build-bin.r && \
	echo "\n*** DONE: BUILD-BINARIES" && \
	cd -
	
check: $(R_PACKAGE_TAR_GZ)
	@cd checks && \
	echo "\n*** STEP: CHECK\n" && \
	`echo "$$CMD_CHECK" > check.r` && \
	$(RSCRIPT) --vanilla ./check.r && \
	echo "\n*** DONE: CHECK" && \
	cd -

roxygen: init
	@cd checks && \
	echo "\n*** STEP: ROXYGEN\n" && \
	`echo "$$CMD_ROXYGEN" > roxy.r` && \
	$(RSCRIPT) --vanilla ./roxy.r && \
	echo "\n*** DONE: ROXYGEN" && \
	cd -

staticdocs: init
	@cd checks && \
	echo "\n*** STEP: STATICDOCS\n" && \
	`echo "$$CMD_STATICDOCS" > staticdocs.r` && \
	$(RSCRIPT) --vanilla ./staticdocs.r && \
	echo "\n*** DONE: STATICDOCS\n" && \
	cd -

ifdef rebuild
vignettes: init rmvignettes
else
vignettes: init
endif
	@cd checks && \
	cd $(R_PACKAGE_PATH)/vignettes && \
	echo "\n*** STEP: BUILD VIGNETTES\n" && \
	make && \
	echo "Cleaning up ..." && \
	make clean && \
	echo "\n*** DONE: BUILD VIGNETTES\n" && \
	cd -

rmvignettes:
	@cd checks && \
	cd $(R_PACKAGE_PATH)/vignettes && \
	echo "\n*** STEP: REMOVE VIGNETTES\n" && \
	make clean-all && \
	echo "\n*** DONE: REMOVE VIGNETTES\n" && \
	cd -
	
r-forge: build
	@cd checks && \
	echo "\n*** STEP: R-FORGE\n" && \
	`echo "$$CMD_PACKAGE_TAR" > tar.r` && \
	echo "\n*** DONE: R-FORGE\n" && \
	cd -	
