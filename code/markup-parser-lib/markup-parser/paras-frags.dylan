module: markup-parser

//
// Types
//

define constant <quote-options-sequence> = limited(<vector>, of: <symbol>);

//
// Paragraphs
//

define caching parser paragraph-directive-content :: <paragraph-token>
   rule choice(seq(indent, paragraph, dedent),
               seq(nil(#f), paragraph-til-null-directive, nil(#f)))
      => tokens;
   yield tokens[1]
end;

// exported -- contents are those of paragraph-lines combined
define caching parser paragraph (<source-location-token>)
   rule many(paragraph-line) => items;
   slot content :: <markup-word-sequence> = reduce1(concatenate, items);
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

// exported as <paragraph-token>
// contents are those of paragraph-lines combined
define caching parser paragraph-til-null-directive (<paragraph-token>)
   rule many(seq(not-next(null-directive-spec), paragraph-line))
      => items;
   inherited slot content /* :: <markup-word-sequence> */ =
      as(<markup-word-sequence>, reduce1(concatenate, collect-subelements(items, 1)));
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

// exported as <paragraph-token>
// contents are those of paragraph-line-til-hyphen-ls combined
define caching parser paragraph-til-hyphen-ls (<paragraph-token>)
   rule many(paragraph-line-til-hyphen-ls) => items;
   inherited slot content /* :: <markup-word-sequence> */ =
      reduce1(concatenate, items);
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

//
// Paragraph lines
//

define caching parser paragraph-line :: <markup-word-sequence>
   rule seq(not-next(paragraph-break), sol, markup-words, ls) => tokens;
   yield tokens[2];
end;

define caching parser paragraph-line-til-hyphen-ls :: <markup-word-sequence>
   rule seq(not-next(paragraph-break), sol,
            many(seq(not-next(hyphen-ls), markup-word, spaces)),
            choice(req-next(hyphen-ls), ls))
      => tokens;
   yield as(<markup-word-sequence>, collect-subelements(tokens[2], 1));
end;

define caching parser paragraph-break
   rule choice(blank-lines, bracketed-line, marginal-code-block, marginal-verbatim-block)
end;

define caching parser bracketed-line
   rule choice(figure-ref-line, ditto-ref-line, bracketed-raw-block-start-line)
end;

//
// Raw lines
//

// exported
define caching parser raw-line (<source-location-token>)
   rule seq(indent-dedent, opt-many(seq(not-next(raw-line-end), char)),
            raw-line-end)
      => tokens;
   slot text :: <string> =
      begin
         let first-part = collect-subelements(tokens[1], 1) | "";
         let leading-spaces = *raw-leading-spaces*;
         let first-part = copy-sequence(first-part, start: leading-spaces);
         concatenate(as(<string>, first-part), tokens[2].text)
      end;
   slot index :: false-or(type-union(<integer>, <character>)) =
      tokens[2].index;
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

// content promoted to <raw-line-token> -- includes literal string representation
define caching parser raw-line-end (<token>)
   rule seq(opt(line-marker), ls) => tokens;
   slot text :: <string> = (tokens[0] & tokens[0].text) | "";
   slot index :: false-or(type-union(<integer>, <character>)) =
      tokens[0] & tokens[0].index
end;

// content promoted to <raw-line-end-token> -- includes literal string representation
define caching parser line-marker (<token>)
   rule seq(open-bracket, opt-spaces, colon, choice(number, ordinal),
            opt-spaces, close-bracket)
      => tokens;
   slot text :: <string> = format-to-string("[:%s]", tokens[3]);
   slot index :: type-union(<integer>, <character>) = tokens[3];
end;

//
// ASCII lines
//

define caching parser ascii-overline
   rule seq(sol, ascii-line, ls);
afterwards (context, tokens, value, start-pos, end-pos, fail: fail)
   check-title-line-char(tokens[1].ascii-line-char, fail);
   *title-line-char* := tokens[1].ascii-line-char;
end;

define caching parser ascii-midline
   rule ascii-line;
afterwards (context, token, value, start-pos, end-pos, fail: fail)
   check-title-line-char(token.ascii-line-char, fail);
   *title-line-char* := token.ascii-line-char;
end;

define caching parser ascii-underline
   rule seq(sol, ascii-line, ls);
afterwards (context, tokens, value, start-pos, end-pos, fail: fail)
   check-title-line-char(tokens[1].ascii-line-char, fail);
   *title-line-char* := tokens[1].ascii-line-char;
end;

define caching parser ascii-line (<token>)
   rule seq(ascii-line-char, ascii-line-char, many(ascii-line-char)) => tokens;
   slot ascii-line-char :: <character> = tokens[0];
   slot ascii-line-size :: <integer> = tokens[2].size + 2;
afterwards (context, tokens, value, start-pos, end-pos, fail: fail)
   let line = format-to-string("%c%c%s", tokens[0], tokens[1], as(<string>, tokens[2]));
   check-ascii-line-chars(line, start-pos, fail);
end;
   
//
// References
//

// exported
define caching parser image-ref (<source-location-token>)
   rule seq(opn-brack-spc, img-lit, many-spc-ls, filename, 
            opt-seq(many-spc-ls, text-til-cls-brack), spc-cls-brack)
      => tokens;
   slot filename :: <string> = tokens[3];
   slot caption :: false-or(<string>) =
      tokens[4] & remove-multiple-spaces(tokens[4][1].text);
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

// exported
define caching parser line-marker-ref (<source-location-token>)
   rule seq(opn-brack-spc, colon, choice(number, ordinal), spc-cls-brack)
      => tokens;
   slot index :: type-union(<integer>, <character>) = tokens[2];
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

// exported
define caching parser footnote-ref (<source-location-token>)
   rule seq(opn-brack-spc, choice(number, ordinal), spc-cls-brack) => tokens;
   slot index :: type-union(<integer>, <character>) = tokens[1];
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

// exported
define caching parser exhibit-ref (<source-location-token>)
   rule seq(opn-brack-spc, exhibit-lit, many-spc-ls, choice(number, ordinal),
            spc-cls-brack)
      => tokens;
   slot index :: type-union(<integer>, <character>) = tokens[3];
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

// exported
define caching parser synopsis-ref (<source-location-token>)
   rule seq(opn-brack-spc, synopsis-lit, many-spc-ls, of-lit, many-spc-ls,
            link-til-cls-brack, spc-cls-brack)
      => tokens;
   slot link :: <link-word-token> = tokens[5];
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

//
// Quotes
//

define thread variable *close-quote-chars* :: false-or(<string>) = #f;

// exported
define caching parser quote (<source-location-token>)
   rule seq(quoted-words, opt-seq(many-spc-ls, quote-spec)) => tokens;
   slot prequoted-text :: false-or(<string>) =
      tokens[0].prequoted-text;
   slot open-quote :: <string> = 
      tokens[0].open-quote;
   slot quoted-text :: <string> =
      tokens[0].quoted-text | "";
   slot close-quote :: <string> =
      tokens[0].close-quote;
   slot postquoted-text :: false-or(<string>) =
      tokens[0].postquoted-text;
   slot quote-spec :: false-or(<quote-spec-token>) =
      tokens[1] & tokens[1][1];
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

// content promoted to <quote-token>
define caching parser quoted-words (<token>)
   rule seq(opt-many(choice(left-paren, open-bracket)),
            quote-start, opt(text-til-end-quote), quote-end,
            opt(text-til-spc-ls))
      => tokens;
   slot prequoted-text :: false-or(<string>) =
      begin
         if (tokens[0])
            let strings = map(method (sym) as(<string>, sym) end, tokens[0]);
            reduce(concatenate, "", strings);
         end if
      end;
   slot open-quote :: <string> = tokens[1];
   slot quoted-text :: false-or(<string>) = tokens[2] & tokens[2].text;
   slot close-quote :: <string> = tokens[3];
   slot postquoted-text :: false-or(<string>) = tokens[4] & tokens[4].text;
dynamically-bind
   *close-quote-chars* = #f;
end;

define parser-method quote-start (stream, context :: <markup-precomputed-context>)
=> (open-quote :: false-or(<string>))
   label format-to-string("opening quote characters (%s)",
                          join(map(first, *quote-pairs*), ", "));
   let stream-pos = stream.stream-position;
   let match-pair = any?(method (quote-pair)
                            stream.stream-position := stream-pos;
                            let res = read-expected(stream, quote-pair.first, failure: #f);
                            if (res) quote-pair else #f end
                         end, context.sorted-quote-pairs);
   if (match-pair)
      *close-quote-chars* := match-pair.second;
      match-pair.first
   else
      #f
   end if;
end;

define parser-method quote-end (stream, context)
=> (close-quote :: false-or(<string>), success? :: <boolean>,
    err :: false-or(<parse-failure>))
   label format-to-string("closing quote characters (%s)",
                          join(map(second, *quote-pairs*), ", "));
   let close-quote-chars = *close-quote-chars*;
   let result = read-expected(stream, close-quote-chars, failure: #f);
   if (result)
      values(close-quote-chars, #t, #f)
   else
      let desc = format-to-string("closing quote characters \"%s\"", close-quote-chars);
      values(#f, #f, make(<parse-failure>, expected: desc))
   end if;
end;

// exported
define caching parser quote-spec (<source-location-token>)
   rule seq(opn-brack-spc, many(seq(quote-spec-option, opt-many-spc-ls)),
            opt(link-til-cls-brack), spc-cls-brack)
      => tokens;
   slot quote-options :: <quote-options-sequence> =
      as(<quote-options-sequence>, collect-subelements(tokens[1], 0).remove-duplicates);
   slot link :: false-or(<link-word-token>) = tokens[2];
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

define caching parser quote-spec-option :: <symbol>
   rule seq(quote-spec-option-text, req-next(choice(spc-ls, close-bracket)))
      => tokens;
   yield tokens[0];
end;
   

define caching parser quote-spec-option-text :: <symbol>
   rule choice(code-lit, term-lit, api-lit, bib-lit, sic-lit, unq-lit, em-lit,
               qq-lit, qv-lit, vi-lit, b-lit, i-lit, u-lit, q-lit)
      => token;
   yield token;
end;
