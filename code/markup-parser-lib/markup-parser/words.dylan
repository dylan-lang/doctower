module: markup-parser

//
// Types
//

define constant <markup-word-types> =
      type-union(<quote-token>,
                 <line-marker-ref-token>,
                 <footnote-ref-token>,
                 <exhibit-ref-token>,
                 <image-ref-token>,
                 <synopsis-ref-token>,
                 <bracketed-render-span-token>,
                 <text-word-token>);

define constant <title-word-types> =
      type-union(<quote-token>,
                 <image-ref-token>,
                 <bracketed-render-span-token>,
                 <text-word-token>);

define constant <markup-word-sequence> =
      limited(<vector>, of: <markup-word-types>);

define constant <link-word-sequence> =
      limited(<vector>, of: <link-word-token>);

//
// Markup & title words
//

define caching parser markup-words :: <markup-word-sequence>
   rule many(seq(markup-word, opt-spaces)) => items;
   yield as(<markup-word-sequence>, collect-subelements(items, 0));
end;

define caching parser markup-words-til-hyphen-spc :: <markup-word-sequence>
   rule many(seq(not-next(hyphen-spc), markup-word, opt-spaces)) => items;
   yield as(<markup-word-sequence>, collect-subelements(items, 1));
end;

define caching parser markup-word :: <markup-word-types>
   rule choice(quote, line-marker-ref, footnote-ref, exhibit-ref, image-ref,
               synopsis-ref, bracketed-render-span, text-word)
      => token;
   yield token;
end;

define caching parser title-word :: <title-word-types>
   rule choice(quote, image-ref, bracketed-render-span, text-word) => token;
   yield token;
end;

// exported
define caching parser text-word (<source-location-token>)
   rule text-til-spc-ls => token;
   slot text :: <string> = token.text;
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

define caching parser word-line :: <text-word-token>
   rule seq(sol, text-word, ls) => tokens;
   yield tokens[1];
end;

// exported as <text-word-token>
define caching parser word-til-cls-brack (<text-word-token>)
   rule text-til-spc-cls-brack => token;
   inherited slot text = token.text;
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

//
// Links
//

define caching parser indented-link-words :: <link-word-sequence>
   rule seq(indent, link-word-lines, dedent) => tokens;
   yield tokens[1];
end;

define caching parser link-word-lines :: <link-word-sequence>
   rule many(seq(sol, link-words, ls)) => tokens;
   yield as(<link-word-sequence>, integrate-sequences(collect-subelements(tokens, 1)));
end;

define caching parser link-words :: <link-word-sequence>
   rule seq(link-word, opt-many(seq(spaces, link-word))) => tokens;
   yield as(<link-word-sequence>, first-item-and-last-subelements(tokens));
end;

// exported
define caching parser link-word (<source-location-token>)
   rule choice(seq(quote-start, text-til-end-quote, quote-end),
               seq(nil(#f), text-til-spc-ls))
      => token;
   slot text :: <string> = remove-multiple-spaces(token[1].text);
dynamically-bind
   *close-quote-chars* = #f;
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

// exported as <link-word-token>
define caching parser link-line (<link-word-token>)
   rule choice(seq(sol, quote-start, text-til-end-quote, quote-end, ls),
               seq(sol, nil(#f), text-til-ls, ls))
      => token;
   inherited slot text = remove-multiple-spaces(token[2].text);
dynamically-bind
   *close-quote-chars* = #f;
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

// exported as <link-word-token>
define caching parser link-til-cls-brack (<link-word-token>)
   rule choice(seq(quote-start, text-til-end-quote, quote-end),
               seq(nil(#f), text-til-cls-brack))
      => token;
   inherited slot text = remove-multiple-spaces(token[1].text);
dynamically-bind
   *close-quote-chars* = #f;
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

//
// Names & API names
//

define caching parser filename :: <string>
   rule seq(quote-start, text-til-end-quote, quote-end) => tokens;
   yield tokens[1].text;
dynamically-bind
   *close-quote-chars* = #f;
end;

define caching parser nickname-word :: <string>
   rule text-til-cls-brack => token;
   yield remove-multiple-spaces(token.text);
end;

//
// Text tokens
//

define caching parser text-til-ls (<token>)
   rule many(seq(not-next(ls), char)) => items;
   slot text :: <string> = as(<string>, collect-subelements(items, 1));
end;

define caching parser text-til-spc-ls (<token>)
   rule many(seq(not-next(spc-ls), char)) => items;
   slot text :: <string> = as(<string>, collect-subelements(items, 1));
end;

define caching parser text-til-cls-brack (<token>)
   rule many(seq(not-next(spc-cls-brack), char)) => items;
   slot text :: <string> =
      replace-ls-with-spc(as(<string>, collect-subelements(items, 1)));
end;

define caching parser text-til-spc-cls-brack (<token>)
   rule many(seq(not-next(spc-ls), not-next(close-bracket), char)) => items;
   slot text :: <string> = as(<string>, collect-subelements(items, 2));
end;

define caching parser text-til-end-quote (<token>)
   rule many(seq(not-next(quote-end), char)) => items;
   slot text :: <string> =
      replace-ls-with-spc(as(<string>, collect-subelements(items, 1)));
end;

//
// Bracketed render span
//

// exported
define caching parser bracketed-render-span (<source-location-token>)
   rule seq(bracketed-render-span-start,
            opt-many(seq(not-next(bracketed-render-span-end), char)),
            bracketed-render-span-end)
      => tokens;
   slot block-type :: <symbol> = tokens[0];
   slot text :: <string> = as(<string>, collect-subelements(tokens[1], 1));
dynamically-bind
   *bracketed-spec-text* = #f;
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

define caching parser bracketed-render-span-start :: <symbol>
   rule seq(opn-brack-spc, bracketed-render-span-spec-text, spc-cls-brack)
      => tokens;
   yield tokens[1];
afterwards (context, tokens, value, start-pos, end-pos)
   *bracketed-spec-text* := tokens[1];
end;

define caching parser bracketed-render-span-end
   rule seq(opn-brack-spc, end-lit,
            opt-seq(many-spc-ls, bracketed-render-span-spec-text),
            spc-cls-brack);
afterwards (context, tokens, value, start-pos, end-pos, fail: fail)
   check-end-spec-text(tokens[2] & tokens[2][1], fail)
end;

//
// Literals
//

define caching parser topic-directive-spec-text :: <symbol>
   rule choice(seq(nil(#f), constant-lit),
               seq(nil(#f), function-lit),
               seq(nil(#f), variable-lit),
               seq(generic-lit, opt-seq(spaces, function-lit)),
               seq(nil(#f), library-lit),
               seq(nil(#f), method-lit),
               seq(nil(#f), module-lit),
               seq(nil(#f), class-lit),
               seq(nil(#f), macro-lit),
               seq(nil(#f), topic-lit))
      => token;
   yield select (token[0])
            #"generic" => #"generic-function";
            otherwise => token[1];
         end select;
end;

define caching parser section-directive-spec-text :: <symbol>
   rule section-lit => token;
   yield #"section";
end;

define caching parser paragraph-directive-spec-text :: <symbol>
   rule choice(synopsis-lit, syn-lit) => token;
   yield #"synopsis";
end;

define caching parser link-directive-spec-text :: <symbol>
   rule seq(parent-lit, opt-seq(spaces, topic-lit)) => tokens;
   yield #"parent";
end;

define caching parser links-directive-spec-text :: <symbol>
   rule choice(seq(relevant-lit, spaces, to-lit),
               seq(see-lit, spaces, also-lit))
      => token;
   yield select (token[0])
            #"relevant" => #"relevant-to";
            #"see" => #"see-also";
         end select;
end;

define caching parser word-directive-spec-text :: <symbol>
   rule seq(in-lit, spaces, choice(module-lit, library-lit))
      => tokens;
   yield select (tokens[2])
            #"module" => #"in-module";
            #"library" => #"in-library";
         end select;
end;

define caching parser division-directive-spec-text :: <symbol>
   rule choice(seq(nil(#"keywords"),   init-keywords-lit),
               seq(nil(#"conditions"), conditions-lit),
               seq(nil(#"conditions"), exceptions-lit),
               seq(nil(#"arguments"),  arguments-lit),
               seq(nil(#"keywords"),   keywords-lit),
               seq(nil(#"conditions"), signals-lit),
               seq(nil(#"conditions"), errors-lit),
               seq(nil(#"values"),     values-lit), 
               seq(nil(#"arguments"),  args-lit),
               seq(nil(#"keywords"),   make-lit, spaces, keywords-lit))
      => token;
   yield token[0];
end;

define caching parser indented-content-directive-spec-text :: <symbol>
   rule choice(warning-lit, note-lit) => token;
   yield token;
end;

define caching parser null-directive-spec-text
   rule discussion-lit;
end;

define caching parser bracketed-raw-block-spec-text :: <symbol>
   rule choice(verbatim-lit, diagram-lit, example-lit, code-lit) => token;
   yield token;
end;

define caching parser bracketed-render-span-spec-text
   rule choice(dita-lit, html-lit) => token;
   yield token;
end;

//
// Special characters
//

define parser-method ascii-line-char (stream, context)
=> (char :: false-or(<character>))
   label format-to-string("line character (%s)", *ascii-line-chars*);
   let char = read-element(stream, on-end-of-stream: #f);
   member?(char, *ascii-line-chars*) & char
end;

define parser-method bullet-char (stream, context)
=> (char :: false-or(<character>))
   label format-to-string("bullet character (%s)", *bullet-chars*);
   let char = read-element(stream, on-end-of-stream: #f);
   member?(char, *bullet-chars*) & char
end;

//
// Convenience
//

define caching parser spc-ls
   rule choice(spc, ls)
end;

define caching parser opn-brack-spc
   rule seq(open-bracket, opt-many-spc-ls)
end;

define caching parser spc-cls-brack
   rule seq(opt-many-spc-ls, close-bracket)
end;

define caching parser many-spc-ls
   rule many(spc-ls)
end;

define caching parser opt-many-spc-ls
   rule opt-many(spc-ls)
end;

define caching parser spaces
   rule many(spc)
end;

define caching parser opt-spaces
   rule opt-many(spc)
end;

define parser sol (<token>)
   rule opt-spaces => token
end;

define parser indent-dedent
   rule opt-many(choice(indent, dedent))
end;
