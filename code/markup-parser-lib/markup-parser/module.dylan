module: dylan-user
synopsis: This module parses Doxygen markup read from a stream.

define module markup-parser
   use common, exclude: { table, source-location };
   use parser-common, export: { source-location };
   use conditions;
   use configs;
   
   // from peg-parser
   use peg-parser, export: { <token>, *parser-trace* };
   // from strings
   use strings;
   // from wrapper-streams
   use replacing-stream;
   // from regular-expressions
   use regular-expressions, import: { regex-replace, compile-regex };
   
   export
      parse-markup, parse-internal-markup;
   
   export
      <bracketed-raw-block-token>, <bracketed-render-span-token>,
      <bullet-list-item-token>, <bullet-list-token>, <directive-topic-token>,
      <ditto-ref-line-token>, <division-directive-token>, <exhibit-ref-token>,
      <exhibit-token>, <figure-ref-line-token>, <footnote-ref-token>,
      <footnote-token>, <hyphenated-list-item-token>, <hyphenated-list-token>,
      <image-ref-token>, <indented-content-directive-token>,
      <line-marker-ref-token>, <link-directive-token>, <link-word-token>,
      <links-directive-token>, <marginal-code-block-token>,
      <marginal-verbatim-block-token>, <markup-content-token>,
      <numeric-list-item-token>, <numeric-list-token>,
      <paragraph-directive-token>, <paragraph-token>, <phrase-list-item-token>,
      <phrase-list-token>, <quote-spec-token>, <quote-token>, <raw-line-token>,
      <section-directive-title-token>, <section-directive-token>,
      <synopsis-ref-token>, <table-token>, <text-word-token>,
      <title-nickname-token>, <titled-section-token>, <titled-topic-token>,
      <topic-directive-title-token>, <topic-or-section-title-token>,
      <word-directive-token>;
   
   export
      <topic-content-types>, <division-content-types>;
      
   export
      block-type, caption, close-quote, content, default-topic-content,
      directive-type, filename, index, item-label, link, links, list-start,
      open-quote, ordinal, postquoted-text, prequoted-text, quote-options,
      quote-spec, quoted-text, scale-factor, scale-type, section-nickname,
      section-title, text, title-content, title-style, topic-nickname,
      topic-title, topic-type, topics, word;
      
end module;
