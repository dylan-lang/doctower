module: markup-parser

//
// Bullet lists
//

define thread variable *bullet-list-bullet-char* :: <character> = ' ';

// exported
define caching parser bullet-list (<source-location-token>)
   rule many(seq(bullet-list-item, opt(blank-lines)))
      => items;
   slot content :: <sequence> /* of <bullet-list-item-token> */ =
      collect-subelements(items, 0);
dynamically-bind
   *bullet-list-bullet-char* = ' ';
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

// exported
define caching parser bullet-list-item (<source-location-token>)
   rule seq(sol, bullet-list-marker, remainder-and-indented-content) => tokens;
   slot content :: <division-content-sequence> = tokens[2];
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

define caching parser bullet-list-marker
   rule seq(bullet-char, spaces);
afterwards (context, tokens, value, start-pos, end-pos, fail: fail)
   check-bullet-char(tokens[0], fail)
end;

//
// Numeric list
//

define thread variable *ordinal-type* :: false-or(<class>) = #f;
define thread variable *ordinal-separator* :: false-or(<symbol>) = #f;

// exported
define caching parser numeric-list (<source-location-token>)
   rule seq(numeric-list-first-item,
            opt-many(seq(opt(blank-lines), numeric-list-item)),
            opt(blank-lines))
      => items;
   slot list-start :: type-union(<integer>, <character>) = items[0].ordinal;
   slot content :: <sequence> /* of <numeric-list-item-token> */ =
      first-item-and-last-subelements(items);
dynamically-bind
   *ordinal-type* = #f,
   *ordinal-separator* = #f;
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

// exported as <numeric-list-item-token>
define caching parser numeric-list-first-item (<numeric-list-item-token>)
   rule seq(sol, numeric-list-first-marker, remainder-and-indented-content)
      => tokens;
   slot ordinal :: type-union(<integer>, <character>) = tokens[1];
   inherited slot content /* :: <division-content-sequence> */ = tokens[2];
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

// exported
define caching parser numeric-list-item (<source-location-token>)
   rule seq(sol, numeric-list-marker, remainder-and-indented-content) => tokens;
   slot content :: <division-content-sequence> = tokens[2];
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

define caching parser numeric-list-first-marker :: type-union(<integer>, <character>)
   rule seq(choice(number, ordinal), choice(colon, right-paren, period), spaces)
      => tokens;
   yield tokens[0];
afterwards (context, tokens, value, start-pos, end-pos)
   *ordinal-type* := tokens[0].object-class;
   *ordinal-separator* := tokens[1];
end;

define caching parser numeric-list-marker
   rule seq(choice(number, ordinal, hash), choice(colon, right-paren, period), spaces);
afterwards (context, tokens, value, start-pos, end-pos, fail: fail)
   check-numeric-list-marker(tokens, fail);
end;

//
// Hyphenated list
//

// exported
define caching parser hyphenated-list (<source-location-token>)
   rule many(seq(hyphenated-list-item, opt(blank-lines))) => items;
   slot content :: <sequence> /* of <hyphenated-list-item-token> */ =
      collect-subelements(items, 0);
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

// exported
define caching parser hyphenated-list-item (<source-location-token>)
   rule seq(sol, hyphenated-list-label, remainder-and-indented-content) => tokens;
   slot item-label :: <markup-word-sequence> = tokens[1];
   slot content :: <division-content-sequence> = tokens[2];
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

define caching parser hyphenated-list-label :: <markup-word-sequence>
   rule seq(markup-words-til-hyphen-spc, hyphen-spc) => tokens;
   yield tokens[0];
end;

define caching parser hyphen-spc
   rule seq(hyphen, spaces);
end;

//
// Phrase list
//

// exported
define caching parser phrase-list (<source-location-token>)
   rule many(seq(phrase-list-item, opt(blank-lines))) => items;
   slot content :: <sequence> /* of <phrase-list-item-token> */ =
      collect-subelements(items, 0);
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

// exported
define caching parser phrase-list-item (<source-location-token>)
   rule seq(sol, phrase-list-label, indented-content) => tokens;
   slot item-label :: <markup-word-sequence> = tokens[1];
   slot content :: <division-content-sequence> = tokens[2];
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

define caching parser phrase-list-label :: <markup-word-sequence>
   rule seq(paragraph-til-hyphen-ls, hyphen-ls) => tokens;
   yield tokens[0].content;
end;

define caching parser hyphen-ls
   rule seq(hyphen, ls)
end parser;
