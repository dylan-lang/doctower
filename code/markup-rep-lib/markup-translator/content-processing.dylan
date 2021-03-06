module: markup-translator


//
// Notes and warnings
//


define method process-tokens
   (seq :: type-union(<topic-content-seq>, <content-seq>),
    token :: <indented-content-directive-token>)
=> ()
   let note-class = select (token.directive-type)
                       #"note" => <note>;
                       #"warning" => <warning-note>;
                    end select;
   let note = make(note-class, source-location: token.token-src-loc);
   process-tokens(note, token.token-content);
   add!(seq, note);
end method;


/** Tokens go into 'note.content'. **/
define method process-tokens
   (note :: <note>, token :: <token>)
=> ()
   process-tokens(note.content, token)
end method;


//
// Code, verbatim, and raw blocks
//


define method process-tokens
   (seq :: type-union(<topic-content-seq>, <content-seq>),
    token :: <marginal-code-block-token>)
=> ()
   let code-block = make(<code-block>, source-location: token.token-src-loc);
   process-tokens(code-block, token.token-content);
   add!(seq, code-block);
end method;


define method process-tokens
   (seq :: type-union(<topic-content-seq>, <content-seq>),
    token :: <marginal-verbatim-block-token>)
=> ()
   let verb-block = make(<pre>, source-location: token.token-src-loc);
   process-tokens(verb-block, token.token-content);
   add!(seq, verb-block);
end method;


define method process-tokens
   (seq :: type-union(<topic-content-seq>, <content-seq>),
    token :: <bracketed-raw-block-token>)
=> ()
   let raw-block =
         make(if (token.block-type = #"verbatim") <pre> else <code-block> end,
              source-location: token.token-src-loc);
   process-tokens(raw-block, token.token-content);
   add!(seq, raw-block);
end method;


define method process-tokens
   (blk :: <pre>, line-token :: <raw-line-token>)
=> ()
   when (line-token.token-index)
      add!(blk.content, make(<line-marker>, index: line-token.token-index,
                             source-location: line-token.token-src-loc));
   end when;
   add!(blk.content, concatenate(line-token.token-text, "\n"));
end method;


//
// Reference lines
//


define method process-tokens
   (seq :: type-union(<topic-content-seq>, <content-seq>),
    token :: <figure-ref-line-token>)
=> ()
   let fig = make(<fig>, source-location: token.token-src-loc);
   fig.image-name := token.filename;
   fig.title := token.caption;
   select (token.scale-type)
      #"%" => fig.rel-size := token.scale-factor;
      #"x" => fig.abs-size := token.scale-factor;
   end select;
   add!(seq, fig);
end method;


define method process-tokens
   (seq :: type-union(<topic-content-seq>, <content-seq>),
    token :: <ditto-ref-line-token>)
=> ()
   add!(seq, make(<ditto-placeholder>, target: token.link.token-text,
                  source-location: token.token-src-loc));
end method;


//
// Tables
//


define method process-tokens
   (seq :: type-union(<topic-content-seq>, <content-seq>),
    token :: <table-token>)
=> ()
   let simp-tbl = make(<simple-table>);
   // TODO: <table-token>
end method;


//
// Bullet and numeric lists
//


define method process-tokens
   (seq :: type-union(<topic-content-seq>, <content-seq>),
    token :: type-union(<numeric-list-token>, <bullet-list-token>))
=> ()
   let list-item-tokens = token.token-content;
   let list =
         select (token.object-class)
            <numeric-list-token> =>
               make(<ordered-list>, source-location: token.token-src-loc,
                    start: token.list-start);
            <bullet-list-token> =>
               make(<unordered-list>, source-location: token.token-src-loc);
         end select;
   list.items := make(<vector>, size: list-item-tokens.size);
   for (i from 0, list-item-token in list-item-tokens)
      let list-item-content = content-seq();
      process-tokens(list-item-content, list-item-token.token-content);
      list.items[i] := list-item-content;
   end for;
   add!(seq, list);
end method;


//
// Hyphenated and phrase lists
//


define method process-tokens
   (seq :: type-union(<topic-content-seq>, <content-seq>),
    token :: type-union(<hyphenated-list-token>, <phrase-list-token>))
=> ()
   let list-item-tokens = token.token-content;
   let list-class =
         select (token.object-class)
            <hyphenated-list-token> => <one-line-defn-list>;
            <phrase-list-token> => <many-line-defn-list>;
         end select;
   let list = make(list-class, source-location: token.token-src-loc);
   list.items := make(<array>, dimensions: vector(list-item-tokens.size, 2));
   for (i from 0, list-item-token in list-item-tokens)
      let list-item-label = markup-seq();
      let list-item-content = content-seq();
      process-tokens(list-item-label, list-item-token.item-label);
      process-tokens(list-item-content, list-item-token.token-content);
      list.items[i, 0] := list-item-label;
      list.items[i, 1] := list-item-content;
   end for;
   add!(seq, list);
end method;


//
// Paragraphs
//


define method process-tokens
   (seq :: type-union(<topic-content-seq>, <content-seq>),
    token :: <paragraph-token>)
=> ()
   let para = make(<paragraph>, source-location: token.token-src-loc);
   process-tokens(para, token.token-content);
   add!(seq, para);
end method;


define method process-tokens
   (para :: <paragraph>, token :: <paragraph-token>)
=> ()
   process-tokens(para, token.token-content)
end method;


/** Tokens go into 'paragraph.content'. **/
define method process-tokens
   (para :: <paragraph>, token :: <token>)
=> ()
   process-tokens(para.content, token)
end method;
