module: dylan-parser
synopsis: Line-oriented parsing and grammar of documentation comments.


/**
=== Documentation comments ===

Documentation comments must be associated with the relevant grammar
productions. This is done in three layers.

First, each lexeme sets its 'lexeme-doc' slot to its immediately preceding
documentation comment. A parser that wants such a comment pulls it from the
appropriate lexeme token and calls 'claim-docs' in its "afterwards" clause.
Calling 'claim-docs' signifies an interest in it, and this interest propogates
upwards: higher productions claim the claimed documentation of their lower
productions.

Second, the production for a top-level definition employs the '*scoped-docs*'
attribute to capture all documentation comments within its lexical scope, via
the "doc-comment-block" production. But the top-level definition production
removes those document comments claimed by lower productions from that set, by
calling 'remove-claimed-docs' in its "afterwards" clause. This leaves its
'scoped-docs' slot with only those documentation comments found at large within
its scope.

Third, the production for the entire source record similarly employs the
'*scoped-docs*' attribute and removes documentation comments found in its
top-level definitions, setting its 'unscoped-docs' slot to those documentation
comments associated with nothing in particular.
**/


define thread variable *scoped-docs* = make(<stretchy-vector> /* of <markup-content-token */);


// Span includes opening comment delimiter and all text up to and including 
// closing comment delimiter or eol, including leading spaces and eol comment
// delimiters on each line.
define class <doc-comment-token> (<text-token>)
end class;

define method last-whitespace-doc (ws :: false-or(<whitespace-token>))
=> (doc :: false-or(<markup-content-token>))
   if (ws & ~ws.whitespace-docs.empty?)
      ws.whitespace-docs.last;
   end if;
end method;


//
// Line oriented parsing
//

define parser source-record (<source-location-token>)
   rule seq(opt-many(seq(opt(lines-til-parsable), choice(definition, doc-block))),
            opt(lines-til-parsable))
   => tokens;
   slot definitions = source-record-definitions(tokens[0] | #[]);
   slot unscoped-docs = *scoped-docs*;
dynamic-bind
   *scoped-docs* = make(<stretchy-vector> /* of <markup-content-token> */);
afterwards (context, tokens, value, start-pos, end-pos)
   value.unscoped-docs := sort!(value.unscoped-docs, test: markup-sort-test);
   value.unscoped-docs := remove-claimed-docs(value.unscoped-docs, value.definitions);
   note-source-location(context, value);
end;

define parser lines-til-parsable
   rule many(seq(not-next(definition), not-next(doc-block), line));
end;


//
// Lexical whitespace
//

define caching parser opt-spaces
   rule opt-many(spc)
end;

define parser whitespace (<token>)
   label "comment or whitespace";
   rule many(choice(spc, eol, doc-block, comment)) => tokens;
   slot whitespace-docs = tokens.choose-markup-tokens;
end;

define caching parser opt-whitespace :: false-or(<whitespace-token>)
   rule opt(whitespace) => token;
   yield token;
end;

define parser lex-EOF
   rule seq(opt-whitespace, not-next(char))
end;


//
// Comments
//

define caching parser comment
   rule choice(delim-comment, eol-comment);
end;

define parser delim-comment
   rule seq(lf-comment, opt-many(choice(delim-comment, delim-comment-text)),
            rt-comment)
end;

define parser eol-comment
   rule seq(double-slash, opt(eol-comment-text), eol)
end;

define parser-method doc-block (stream, context)
=> (token :: false-or(<doc-comment-block-token>), succ? :: <boolean>,
    err :: false-or(<parse-failure>))
   label "documentation comment block";
   if (*scan-only?*)
      values(#f, #f, #f)
   else
      parse-doc-comment-block(stream, context)
   end if
end;

define caching parser doc-comment-block (<token>)
   rule seq(opt-spaces, choice(delim-doc-comment, eol-doc-comments)) => tokens;
   slot comment :: <doc-comment-token> = tokens[1];
   slot markup :: <markup-content-token>;
afterwards (context, tokens, value, start-pos, end-pos, fail: fail)
   let (token, failure) = markup-from-comment(value.comment, context);
   if (token)
      value.markup := token;
      add-new!(*scoped-docs*, token, test: \=);
   else
      fail(failure)
   end if;
end;

define parser delim-doc-comment (<doc-comment-token>)
   rule seq(lf-doc-comment, choice(spc, eol),
            opt-many(choice(delim-comment, delim-comment-text)),
            rt-comment)
   => tokens;
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value);
   capture-text(context, value);
end;

define parser eol-doc-comments (<doc-comment-token>)
   rule many(seq(opt-spaces, eol-doc-comment)) => tokens;
afterwards (context, tokens, value, start-pos, end-pos)
   note-combined-source-location(context, value, tokens);
   capture-text(context, value);
end;

define parser eol-doc-comment (<token>)
   rule seq(triple-slash, opt-seq(spc, eol-comment-text), eol) => tokens;
end;

define parser delim-comment-text
   rule many(seq(not-next(rt-comment), char))
end;

define parser eol-comment-text
   rule many(seq(not-next(eol), char))
end;
