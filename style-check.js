#!/usr/bin/env node
const
  clear        = require( 'clear' ),
  chalk        = require( 'chalk' ),
  inquirer     = require( 'inquirer' ),
  argv         = require( 'minimist' )( process.argv.slice(2) ),
  autoprefixer = require( 'autoprefixer' ),
  postcss      = require( 'postcss' ),
  csscomb      = require( 'postcss-csscomb' ),
  longhand     = require( 'postcss-merge-longhand' ),
  fontweights  = require( 'postcss-font-weights' )(),
  pseudoColons = require( 'postcss-pseudo-element-colons' ),
  pseudoCase   = require( 'postcss-pseudo-element-cases' ),
  normalizeUrl = require( 'postcss-normalize-url' ),
  _csscomb     = require( './.csscomb.json' ),
  _postcss     = require( './.autoprefix.json'),
  dateFormat   = require( 'dateformat' ),
  util         = require( './lib/util' ),
  git          = require( 'simple-git' ),
  fs           = require( 'fs' );

clear();
console.log("                                                                             ");
console.log("                                                                             ");
console.log("                      ███                         █                    █     ");
console.log("          █             █                         █                    █     ");
console.log("          █             █                         █                    █     ");
console.log(" ▒███▒  █████  █░  █    █     ███           ▓██▒  █▒██▒   ███    ▓██▒  █  ▒█ ");
console.log(" █▒ ░█    █    ▓▒ ▒▓    █    ▓▓ ▒█         ▓█  ▓  █▓ ▒█  ▓▓ ▒█  ▓█  ▓  █ ▒█  ");
console.log(" █▒░      █    ▒█ █▒    █    █   █         █░     █   █  █   █  █░     █▒█   ");
console.log(" ░███▒    █     █ █     █    █████   ███   █      █   █  █████  █      ██▓   ");
console.log("    ▒█    █     █▓▓     █    █             █░     █   █  █      █░     █░█░  ");
console.log(" █░ ▒█    █░    ▓█▒     █░   ▓▓  █         ▓█  ▓  █   █  ▓▓  █  ▓█  ▓  █ ░█  ");
console.log(" ▒███▒    ▒██   ▒█      ▒██   ███▒          ▓██▒  █   █   ███▒   ▓██▒  █  ▒█ ");
console.log("                ▒█                                                           ");
console.log("                █▒                                                   [0;1;35;95m⡀[0;1;31;91m⢀[0m [0;1;33;93m⠊⡱[0m   [0;1;36;96m⣎[0;1;34;94m⣵[0m");
console.log("               ██                                                    [0;1;31;91m⠱[0;1;33;93m⠃[0m [0;1;32;92m⠮⠤[0m [0;1;36;96m⠶[0m [0;1;34;94m⠫[0;1;35;95m⠜[0m");
console.log("");
console.log("");

var stylesheet = argv['stylesheet'] || argv['s'] || null,
    helpFlag = argv['help'] || argv['h'] || null,
    gitPath = stylesheet ? util.getFileDirectory( stylesheet ) : null;

function init() {
  checkHelp();
  if ( ! stylesheet || ! checkStylesheet( stylesheet ) ) {
    promptForStylesheet();
  } else {
    lintOrFix();
        console.log(gitPath);
  }
}

function checkHelp() {
  if ( helpFlag  ) {
    displayHelp();
    process.exit();
  }
}

function displayHelp() {
    console.log( chalk.blue( "   usage: style-check <options>" ) );
    console.log( "" );
    console.log( "     -h, --help                Available options and help." );
    console.log( "     -s, --stylesheet          Stylesheet to perform tasks on." );
    console.log( "     -f, --fix                 Attempts to run recommended fixes automatically." );
    console.log( "" );
}

function promptForStylesheet( callback ) {
  var questions = [
    {
      name: 'stylesheet',
      type: 'input',
      message: 'Please enter a valid stylesheet to run tasks on:',
      default: stylesheet || util.getCurrentDirectoryBase(),
      validate: ( value ) => {
        // Handle empty.
        if ( ! value.length ) {
          return chalk.blue( 'Please enter a valid path to the stylesheet to check.' );
        }
        // Directory should exist.
        if ( ! util.fileExists( value ) ) {
          return chalk.blue( 'This stylesheet doesn\'t exist! Please enter a valid stylesheet!' );
        }
        // Theme directory should be a git repo.
        if ( ! util.directoryExists( util.getFileDirectory( value ) + '/.git' ) ) {
          return chalk.blue( 'Stylesheet should be contained in a valid .git repository!' );
        }
        // Validated.
        return true;
      }
    }
  ];
  // Use user input.
  inquirer.prompt( questions ).then( ( answer ) => {
    // Update stylesheet location.
    stylesheet = answer['stylesheet'];
    // Update git working dir.
    gitPath = util.getFileDirectory( stylesheet );
    // Run lints or fixes.
    lintOrFix();
  }).catch( ( err ) => {
    console.log( err );
  });
}

function lintOrFix() {
  // If we are flagging to run fix scripts.
  if ( argv['f'] || argv['fix'] ) {
    return runFixes();
  } else {
    return runLints();
  }
}

function runFixes() {
  var plugin = autoprefixer( _postcss.autoprefixer );
  // Run postcss autoprefixer.
  fs.readFile( stylesheet, ( err, css ) => {
    postcss( [plugin, csscomb( _csscomb ), longhand, pseudoColons, pseudoCase, fontweights, normalizeUrl] )
      .process( css, {
        from: stylesheet,
        to: stylesheet
      } ).then( result => {
        fs.writeFile( stylesheet, result.css,
          ( err ) => {
            if ( err ) throw err;
            showDiff( stylesheet );
          });
      }).catch( ( err ) => {
        console.log( err );
      });
  });
}

function runLints() {
  const
    spawn = require( 'child_process' ).spawnSync,
    runLints = spawn( 'awk', [
      '-f', './lib/run-lints',
      stylesheet
    ]);
    console.log( `${runLints.stderr.toString()}` );
    console.log( `${runLints.stdout.toString()}` );
}

function checkStylesheet( stylesheet ) {
  var exists = stylesheet.length && 
    util.fileExists( stylesheet ) && 
    util.directoryExists( util.getFileDirectory( stylesheet ) + '/.git' );
  return exists;
}

function showDiff( stylesheet ) {
  git( gitPath ).outputHandler(
    ( command, stdout, stderr ) => {
      stdout.pipe(process.stdout);
      stderr.pipe(process.stderr);
    }).diff(["--color=always"], promptForCommit );
}

function promptForCommit( callback ) {
  var questions = [
    {
      name: 'commit',
      type: 'input',
      message: 'Would you like to commit these changes now?',
      default: 'n',
      validate: ( value ) => {
        var validResponses = [ 'y', 'yes', 'n', 'no' ];
        // Handle empty.
        if ( ! value.match( /^(?:y|yes|n|no)$/i ) ) {
          return chalk.blue( 'Please enter yes or no.' );
        }
        // Validated.
        return true;
      }
    }
  ];
  // Use user input.
  inquirer.prompt( questions ).then( ( answer ) => {
    commit = answer['commit'].toLowerCase();
    commit.match( /^(?:y|yes)$/i ) ?
      promptForCommitMsg() :
      process.exit();
  }).catch( ( err ) => {
    console.log( err );
  });
}

function promptForCommitMsg( callback ) {
  var questions = [
    {
      name: 'commitMsg',
      type: 'input',
      message: 'Enter commit message or press enter for default:',
      default: 'style-check formatted on ' + dateFormat( new Date(), 'shortDate' ),
    }
  ];
  // Use user input.
  inquirer.prompt( questions ).then( ( answer ) => {
    commitMsg = answer['commitMsg'];
    git( gitPath ).commit( commitMsg, [util.getStylesheetBasename( stylesheet )], { '--author': '"style-check <stylecheck@tim.ph>"' } );
  }).catch( ( err ) => {
    console.log( err );
  });
}

init();
