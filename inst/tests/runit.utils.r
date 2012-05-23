# Unit test for utils
# 
# Author: Renaud Gaujoux
###############################################################################

test.errorCheck <- function(){
	
	f <- function(err=''){
		success <- exitCheck()
		on.exit( if(success()) cat("no error\n") else cat("with error\n") )
		
		if( err=='error' ) stop('There is an error')
		if( err=='try' ) try(stop('Catched error'), silent=TRUE)
		if( err=='tryCatch' ) tryCatch(stop('Catched error'), error = function(e){})
		
		success(1+1)
	}
	
	# without error
	out <- capture.output(res <- f())
	checkIdentical(res, 2, 'If no error: return result')
	checkIdentical(out, 'no error', 'If no error: correctly detected no error')
	
	# with error
	out <- capture.output(res <- try(f('error'), silent=TRUE))
	checkTrue( is(res, 'try-error'), 'If error: effectively throws an error')
	checkIdentical(out, 'with error', 'If error: correctly detected the error')
	
	# with try-caught error 
	out <- capture.output(res <- f('try'))
	checkIdentical( res, 2, 'If try-catched error: return result')
	checkIdentical(out, 'no error', 'If try-catched error: correctly detected no error')
	
	# with tryCatch-caught error 
	out <- capture.output(res <- f('tryCatch'))
	checkIdentical( res, 2, 'If tryCatch-catched error: return result')
	checkIdentical(out, 'no error', 'If tryCatch-catched error: correctly detected no error')
}

