module: dylan-parser

define function join-header-values (value-lines :: <sequence>) => (value :: <string>)
   join(value-lines, "\n")
end function;

define lexical-parsers
   hdr-char    in "abcdefghijklmnopqrstuvwxyz0123456789-"
               label "hyphen or alphanumeric character"
end;

//
// Dylan Interchange Format
//

define parser interchange-file (<source-location-token>)
   rule seq(many(header), opt-seq(hdr-eol, source-record), not-next(char))
   => tokens;
   slot headers = tokens[0];
   slot source-record = tokens[1] & tokens[1][1];
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value);
end parser;

define parser header (<source-location-token>)
   label "interchange format header";
   rule seq(hdr-keyword, hdr-value, opt-many(hdr-addl-value))
   => tokens;
   slot hdr-keyword :: <string> = tokens[0];
   slot hdr-value :: <string>
      = join-header-values(concatenate(vector(tokens[1]), tokens[2] | #[])); 
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value);
end parser;

define parser hdr-keyword :: <string>
   rule seq(alphabetic-character, opt-many(hdr-char), colon, opt(hdr-whitespace))
   => tokens;
   yield reduce(concatenate, tokens[0], tokens[1] | #[]);
end parser;

define parser hdr-value :: <string>
   rule seq(opt-many(seq(not-next(hdr-eol), char)), hdr-eol)
   => tokens;
   yield reduce(concatenate, "", collect-subelements(tokens[0], 1));
end parser;

define parser hdr-addl-value :: <string>
   rule seq(hdr-whitespace, many(seq(not-next(hdr-eol), char)), hdr-eol)
   => tokens;
   yield reduce(concatenate, "", collect-subelements(tokens[1], 1));
end parser;

define parser hdr-whitespace
   rule many(spc);
end parser;

define parser hdr-eol
   rule seq(opt(hdr-whitespace), eol);
end parser;
