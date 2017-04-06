#!/usr/bin/awk -f

###############################
#
#   Style Check Script
#
###############################


# Set available linters.

function setLinters() {

    # Check for postcss.
    cmd = "command -v postcss || exit 1;";
    postcss = cmd | getline; close( cmd );

    # Check for stylelint.
    cmd = "command -v stylelint || exit 1;";
    stylelint = cmd | getline; close( cmd );

    # Check for CSScomb.
    cmd = "command -v csscomb || exit 1;";
    csscomb = cmd | getline; close( cmd );

    # Check for csslint.
    cmd = "command -v csslint || exit 1;";
    csslint = cmd | getline; close( cmd );

    # Check for postcss autoprefixer.
    cmd = "npm view --silent autoprefixer version;";
    autoprefix = cmd | getline; close( cmd );

    linters = ! stylelint && ! csslint && ! csscomb ? 0 : 1;
}


# Run stylelint.

function runStylelint() {

    cmd = "stylelint --config " varDir "/.stylelintrc " FILENAME;
    styleErrors=0;

    while ( ( cmd | getline ) > 0 ) {
    	if ( $0 != "" && $0 != FILENAME ) {
    	    if ( ! styleErrors ) printHeader( "Stylelint Errors" );
            styleErrors++;
            count++;
            print colored( "red", "  " $0 "\n" );
    	}
    }

    close( cmd );

    # Print Style Error.
    styleErrors && styleError( "Stylelint", styleErrors, "style error" );

    # Reset var for later use.
    styleErrors = 0;
}


# Run csscomb.

function runCSScomb() {

    cmd = "csscomb --config " varDir "/.csscomb.json " FILENAME;
    statusCount=0;

    # CSSComb generates unusable output, so we can just call it since we
    # already performed the available linters check.  The system() function is
    # not universal across all platforms, and is not as efficent to run when
    # performing many commands so we will print the command and pipe to shell.
    print cmd | "/bin/sh";

    # Close the shell.
    close( "/bin/sh" );

    # Print section header.
    printHeader( "CSScomb Errors" );

    cmd = "cd $(dirname " FILENAME "); git diff " FILENAME;

    while ( ( cmd | getline ) > 0 ) {

      # Error Reported.
      where = match( $0, /^@/ );

      if ( where != 0 ) {

        # If this is the first diff to print, format it properly.
        if ( ! laterLine ) print "  ", $0, "\n";

        # Flag where to start printing our diff.
        diffStart=1;

        # Flag laterlines for proper formatting.
        laterLine++;
      }

      # Add color highlighting for readability.

      if ( diffStart ) {

        # If line is being added highlight green.

        if ( substr( $0, 0, 1 ) == "+" ) {
          styleErrors++;
          highlightDiff = 1;
          print colored( "green", "    " $0 );
        }

        # If line is being removed highlight red.

        if ( substr( $0, 0, 1 ) == "-" ) {
          highlightDiff = 1;
          print colored( "red", "    " $0 );
        }

        # If not highlighted, and it's a line reference format output.

        if ( ! highlightDiff && where != 0 && laterLine != 1 ) {

          # Print with newline.
          print "\n  ", $0, "\n";

          # Flag no where.
          where = 1;
        }

        # Format unchanged lines in diff.
        if ( ! highlightDiff && ! where ) {
          print "  ", $0;
        }

        # Reset highlighting.
        highlightDiff = 0;
      }
    }

    # Increment error counter.
    count = count + styleErrors;

    # Print an empty line for consistent formatting.
    print "";

    # Print Style Error.
    if ( styleErrors ){
      styleError( "CSScomb", styleErrors, "style issue" );
    } else {
      print "     No errors found in this test, good job!"
    }

    # Reset var for later use.
    styleErrors = 0;

    # Reset the current branch.
    checkoutBranch();
}


# Lint vendor prefixing standards.

function runPrefixLint() {

    cmd = "postcss --use autoprefixer -r --config " varDir "/.autoprefix.json " FILENAME;
    styleErrors=0;

    while ( ( cmd | getline ) > 0 ) {
      print $0;
      styleErrors=1;
      # An error occured with the postcss plugin.
      styleErrors && count++ && postcssError();
    }

    close( cmd );

    # Reset the starting diff from other lints.
    diffStart = 0;

    # Reset styleErrors from other lints and run a diff to find any changes.
    styleErrors=0;

    # Run a git diff to check for modifications and format the output.
    cmd = "cd $(dirname " FILENAME "); git diff --unified=0 " FILENAME;

    while ( ( cmd | getline ) > 0 ) {

      # If this is our first error, then print report header and flag.

      if ( ! styleErrors ) {

        # Flag that there are style errors.
        styleErrors = 1;

        printHeader( "Vendor Prefix Errors" );
      }

      # Remove extraneous text from git diff and increment error count.

      where = match( $0, /^@/  );

      if ( where != 0 ) {

        # Flag where to start printing our diff.
        diffStart = 1;
        highlight = 1;

        # Increment error counter.
        count++;
      }

      if ( diffStart ) {

        if ( highlight ) {

          # Get line number from output.
          split( $0, numb, /[^0-9]*/, trash );
 
          print colored( "red", "  ↳ Line: " numb[2] " →  Vendor Prefixing Error. \n" ); highlight = 0;
        } else {

          if ( substr( $0, 0, 1 ) == "+" ) {
            print colored( "green", "    Add: " ), substr( $0, 2 ) "\n";
          } else {
            print colored( "red", "    Remove: " ), substr( $0, 2 ) "\n";
          } 

        }

      } # Diff Start.

    } # End while loop.

    styleErrors && styleError( "Postcss", styleErrors, "vendor prefix error" ); print "\n";
    close( cmd );

    # Reset the current branch.
    checkoutBranch();
}


# Post CSS Error

function postcssError() {
  # Exit code.
  z=1;

    print "\033[1;31m","✖ Style Syntax Error!","\033[0m ","\n\n",
          "\033[1;34m","  ↳ ",
          "An error occured with the postcss plugin, check your configuration and try again.","\033[0m \n";
}


# Style Error

function styleError( whoFound, styleErrors, errorTypes ) {

  # Exit code.
  z=1;

  # Plural for errors.
  plural = styleErrors > 1 ? "s" : "";

  print "\033[1;31m","✖ Style Errors!","\033[0m ","\n\n",
        "\033[1;34m","  ↳ ",
        whoFound, "found", styleErrors, errorTypes plural ".", "\033[0m ";
}


# Indentation Errors.

function indentError() {

	# Exit code.
	z=1;

    print "\033[1;31m","✖ Style Syntax Error!","\033[0m ","\n\n",
          "  → File:",FILENAME,"\n","      ↳ Line:",NR,"\n\n",
          "  -------------------------------------\n\n  ",
          $0,
          "\n\n   ------------------------------------- \n\n",
          "\033[1;34m","  ↳ ",
          "Use tabs, not spaces for your indentation.","\033[0m \n";

	# Count the error.
    count++;
}


# Empty Property and one line definition errors.

function braceError() {

	# Exit code.
	z=1;

    print "\033[1;31m","✖ Style Syntax Error!","\033[0m ","\n\n",
          "  → File:",FILENAME,"\n","      ↳ Line:",NR,"\n\n",
          "  -------------------------------------\n\n  ",
          $0,
          "\n\n   ------------------------------------- \n\n",
          "\033[1;34m","  ↳ ",
          "Single line definitions and empty properties are forbidden.","\033[0m \n";

    # Count the error.
    count++;
}


# Curly brace errors.

function curlyError() {

	# Exit code.
	z=1;

    print "\033[1;31m","✖ Style Syntax Error!","\033[0m ","\n\n",
          "  → File:",FILENAME,"\n","      ↳ Line:",NR,"\n\n",
          "  -------------------------------------\n\n  ",
          $0,
          "\n\n   ------------------------------------- \n\n",
          "\033[1;34m","  ↳ ",
          "Curly bracket closing should go on next line.","\033[0m \n";

    # Count the error.
	count++;
}


# Line Ending Errors.

function lineEndingError() {

	# Exit code.
    z=1;

    print "\033[1;31m","✖ Style Syntax Error!","\033[0m ","\n\n",
          "  → File:",FILENAME,"\n",
          "\033[1;34m","\n    ↳ ",
          "File does not use UNIX line endings (LF).",
		      "\033[0m \n";

    # Count the error.
    count++;
}


# Checkout git branch.

function checkoutBranch() {
    cmd = "cd $(dirname " FILENAME "); git checkout -- .";
    while ( ( cmd | getline ) > 0 ) {
      print "An Error occurred with your branch.  Make sure you don't have any pending changes."
    }

    close( cmd );
}


# Print Lint Headers

function printHeader( headerText ) {
        print colored( "green", "\n  --------------------------------------\n  # " headerText "\n  --------------------------------------\n" );
}


# Colorized Output

function colored( color, s ) {
	switch ( color ) {
		case "red" :
			printf "\033[1;31m" s "\033[0m ";
			break;
		case "green" :
			printf "\033[1;32m" s "\033[0m ";
			break;
		case "blue" :
			printf "\033[1;34m" s "\033[0m ";
			break;
		default :
			s;
			break;
	}
}


# Generate Report.

function getReport() {

  # Pass or fail message.

	fail = "\n✖ " count " Errors reported while checking your stylesheet, please make the required changes and try again.\n";
	pass = linters ? "\n✓ Style Checks Passed.\n" : "\n✓ Style checks passed with basic checks.\n"; 
	print z == 0 && count == 0 ? colored( "green", pass ) : colored( "red", fail );

  # No external linters were executed.  

  if ( ! linters ) print colored( "red", "  ☹  No linters were installed, using built in checks.  It's recommended that you run the install script.\n");

  if ( ! csscomb ) {
    print colored( "blue", "  ☹  CSScomb is not installed, we recommend installing it with 'npm install csscomb -g'.\n");
  }

  if ( ! postcss && ! autoprefix ) {
    print colored( "blue", "  ☹  Autoprefixer is not installed, we recommend installing it with 'npm install --global autoprefixer'.\n");
  }

  if ( ! postcss ) {
    print colored( "blue", "  ☹  Postcss is not installed, we recommend installing it with 'npm install -g postcss'.\n");
  }

  if ( ! stylelint ) {
    print colored( "blue", "  ☹  Stylelint is not installed, we recommend installing it with 'npm install -g stylelint'.\n     We also use the WordPress config, which can be installed locally for your theme with\n     'npm install stylelint-config-wordpress --save-dev'.\n");
  }

}


# Get the current time in milliseconds.

function getTime() {
  cmd = "echo $(($(date +'%s * 1000 + %-N / 1000000')))";
      while ( ( cmd | getline ) > 0 ) {
        time = $0;
    }

    close( cmd );

    return time;
}


########################################## BEGIN ##########################################


BEGIN   			{
                  # Directory we are running script in.
                  runDir = ENVIRON["PWD"];

                  # Path to our script bin.
                  varDir = scriptLocation ? scriptLocation : runDir;

                  # Error count.
                  count = 0;

                  # Exit code.
			            z = 0;

			            # Check what linters are available for checks or use our own.
			            setLinters();
			        }


########################################## RULES ##########################################


# Check if indentation starts with tabs.

! linters &&
/^ /    			{ indentError() }


# No empty properties or one line definitions.

! linters &&
/{.*}/  			{ braceError() }


# Check that curly brackets are not nested format.

! linters &&
/^\s.[a-zA-Z].*}$/  { curlyError() }


# Check if file has Windows line endings (CRLF).

/\r$/   			{ crlfs=1 }


##########################################   END   ##########################################


END           {
                # Run stylelint if it's an available linter.
                  csscomb && runCSScomb();

          		  # Run stylelint if it's an available linter.
          		  	stylelint && runStylelint();

                # Run prefix lint checks.
                  autoprefix && runPrefixLint();

          		  # File not using UNIX line endings error message.
          		  	crlfs && lineEndingError();

          		  # Print out our final reporting and exit with proper code for build fail/pass.
          		  	getReport();

                # Exit script with maintained error code for builds.
                  exit z;
          		}
