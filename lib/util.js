var fs = require('fs');
var path = require('path');

module.exports = {
  getCurrentDirectoryBase : function() {
    return path.basename( process.cwd() );
  },
  getStylesheetBasename : function( filePath ) {
    return path.posix.basename( filePath );
  },
  getFileDirectory : function( filePath ) {
    return path.dirname( filePath );
  },
  directoryExists : function( filePath ) {
    try {
      return fs.statSync( filePath ).isDirectory();
    } catch ( err ) {
      return false;
    }
  },
  fileExists : function( filePath ) {
    try {
      return fs.statSync( filePath );
    } catch ( err ) {
      return false;
    }
  }
};