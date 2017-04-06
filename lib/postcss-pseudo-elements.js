const postcss = require( 'postcss' );

module.exports = postcss.plugin( 'postcss-pseudo-elements', ( options ) => {

  options = options || {};

  const
    selectors = options.selectors || [
      'before',
      'after',
      'first-line',
      'first-letter',
      'selection',
      'spelling-error',
      'grammar-error',
      'backdrop',
      'marker',
      'placeholder',
      'shadow',
      'slotted',
      'content'
    ],
    notationOption = options['colon-notation'] || 'double',
    notation = notationOption === 'double' ? '::' : ':',
    replacements = new RegExp( '(?:|:):(' + selectors.join('|') + ')', 'gi' );

  return ( css ) => {
    css.walkRules( ( rule ) => {
      rule.selector = rule.selector.replace( replacements, notation + '$1' );
    });
  }
});