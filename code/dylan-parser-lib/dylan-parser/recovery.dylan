module: dylan-parser
synopsis: Grammars that recover from parse failures.

/**
=== Error Recovery ===

Most productions don't bother to recover from parse failures. The parse
failures that I expect and wish to recover from involve weird macros or
something in expressions or types. The "checked-type" and "checked-expression"
parsers are just like the "type" or "expression" parsers, but in the event of a
problem they skip ahead to the next place where parsing can continue.

They detect problems by verifying that they have one of the expected followers,
for example a comma or closing parenthesis. Higher parsers that have
"checked-type" or "checked-expression" in their tree specify the expected
followers using the '*type-followers*' or '*expression-followers*' attributes.

If they don't have one of the expected followers, then the input stream is
skipped using a skipping parser. Higher parsers specify the skipping parser 
using the '*type-skipper*' or '*expression-skipper*' attributes. The former is
used by the "checked-type" parser and the latter is used by the
"checked-expression" parsers. Different parsers can specify '*type-followers*',
'*type-skipper*', '*expression-followers*', and '*expression-skipper*'.
**/


define thread variable *type-followers* :: false-or(<sequence>) = #f;
define thread variable *expression-followers* :: false-or(<sequence>) = #f;
define thread variable *type-skipper* :: false-or(<function>) = #f;
define thread variable *expression-skipper* :: false-or(<function>) = #f;


define class <skipped-token> (<token>)
end class;


define parser checked-type :: <token>
   rule choice(seq(type, req-next(checked-type-followers)),
               seq(checked-type-recovery))
   => tokens;
   yield tokens[0];
end;

define parser checked-expression :: <token>
   rule choice(seq(expression, req-next(checked-expression-followers)),
               seq(checked-expression-recovery))
   => tokens;
   yield tokens[0];
end;


/**
Generic Function: checked-followers
Synopsis: Checks if the current parse point has expected syntax.
**/

define method checked-followers (follows :: <sequence>, stream, context)
=> (result, succ?, extent)
   let parser = apply(choice, follows);
   parser(stream, context);
end method;

define method checked-followers (follows, stream, context)
=> (result, succ?, extent)
   values(#f, #t, make(<parse-success>, position: stream.stream-position));
end method;

define parser-method checked-type-followers (stream, context)
=> (result, succ? :: <boolean>, extent :: <parse-extent>)
   label "valid input";
   checked-followers(*type-followers*, stream, context)
end;

define parser-method checked-expression-followers (stream, context)
=> (result, succ? :: <boolean>, extent :: <parse-extent>)
   label "valid input";
   checked-followers(*expression-followers*, stream, context)
end;


/**
Generic Function: checked-recovery
Synopsis: Advances the parser to the next recovery point (using a skipping
parser) and signals a warning to the user.
**/

define method checked-recovery
   (skipper :: <function>, stream :: <positionable-stream>, context)
=> (result, succ?, extent)
   // Skip to next graphic character before starting recovery, so that the range
   // of skipped input does not include end-of-line characters.
   for (c = peek(stream, on-end-of-stream: #f) then peek(stream, on-end-of-stream: #f),
        while: c & ~c.graphic?)
      read-element(stream)
   end for;

   let parser = skip(skipper);
   let start-pos = stream.stream-position;
   let (result :: false-or(<token>), succ? :: <boolean>, extent) = parser(stream, context);
   let start-pos = (succ? & result.parse-start) | start-pos;
   let end-pos = (succ? & result.parse-end) | stream.stream-position;
   let source-location =
         source-location-from-stream-positions(context, start-pos, end-pos);
   unparsable-expression-in-code(location: source-location);
   values(result, succ?, extent);
end method;

define method checked-recovery (skipper, stream, context) => (result, succ?, extent)
   values(#f, #t, make(<parse-success>, position: stream.stream-position))
end method;

define parser-method checked-type-recovery (stream, context)
=> (result, succ? :: <boolean>, err :: false-or(<parse-failure>))
   label "unparsable input";
   checked-recovery(*type-skipper*, stream, context)
end;

define parser-method checked-expression-recovery (stream, context)
=> (result, succ? :: <boolean>, err :: false-or(<parse-failure>))
   label "unparsable input";
   checked-recovery(*expression-skipper*, stream, context)
end;


//
// Skipping parsers
//

define parser til-parsable (<skipped-token>)
   rule lines-til-parsable => tokens;
end;

define parser til-rt-paren (<skipped-token>)
   rule many(seq(not-next(lex-RT-PAREN),
                 choice(seq(lex-LF-PAREN, til-rt-paren, lex-RT-PAREN),
                        char)))
   => tokens;
end;

define parser til-class-clause (<skipped-token>)
   rule many(seq(not-next(seq(eol, lex-END)),
                 not-next(seq(lex-SEMICOLON, class-clause)),
                 char))
   => tokens;
end;
