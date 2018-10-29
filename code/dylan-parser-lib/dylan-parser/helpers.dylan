module: dylan-parser
synopsis: Functions and classes used in various places.

//
// General helpers
//

define method add-to-front (item, seq :: <sequence>) => (seq :: <sequence>)
   if (item) concatenate-as(seq.type-for-copy, vector(item), seq) else seq end
end method;

define method skipped? (item) => (skipped? :: <boolean>)
   instance?(item, <skipped-token>)
end method;

define method choose-unskipped (seq) => (seq :: <sequence>)
   choose(complement(skipped?), seq)
end method;

/// Used to make a list of x from tokens parsed using (x? (s x)* s?).
define method list-from-tokens (tokens) => (seq :: <sequence>)
   add-to-front(tokens[0], collect-subelements(tokens[1], 1) | #[])
end method;


//
// Markup tokens
//

define method markup-sort-test
   (item1 :: <markup-content-token>, item2 :: <markup-content-token>)
=> (strictly-< :: <boolean>)
   item1.source-location < item2.source-location
end method;

define method choose-markup-tokens (seq) => (seq :: <sequence>)
   map(markup, choose(rcurry(instance?, <doc-comment-block-token>), seq));
end method;

define method claim-docs (token :: <documentable-token-mixin>, seq :: <sequence>)
=> ()
   do(curry(claim-docs, token), seq)
end method;

define method claim-docs (token :: <documentable-token-mixin>, nil == #f) => ()
   #f
end method;

define method claim-docs
   (token :: <documentable-token-mixin>, another :: <documentable-token-mixin>)
=> ()
   token.claimed-docs := concatenate(token.claimed-docs, another.claimed-docs)
end method;

define method claim-docs
   (token :: <documentable-token-mixin>, doc :: <markup-content-token>)
=> ()
   token.claimed-docs := add!(token.claimed-docs, doc)
end method;

define method remove-claimed-docs (docs :: <sequence>, nil == #f)
=> (docs :: <sequence>)
   docs
end method;

define method remove-claimed-docs (docs :: <sequence>, tokens :: <sequence>)
=> (docs :: <sequence>)
   reduce(remove-claimed-docs, docs, tokens)
end method;

define method remove-claimed-docs
   (docs :: <sequence>, token :: <documentable-token-mixin>)
=> (docs :: <sequence>)
   for (claimed :: <markup-content-token> in token.claimed-docs)
      docs := remove(docs, claimed, test: \=)
   end for;
   docs
end method;


//
// Text tokens
//

define function no-backslash (string :: <string>) => (string :: <string>)
   if (string.size > 0 & string[0] = '\\')
      copy-sequence(string, start: 1)
   else
      string
   end if
end function;

define method capture-text
   (context :: <dylan-parse-context>, token :: <text-token>)
=> ()
   let text-span = token.parse-end - token.parse-start;
   token.source-text := make(<simple-object-vector>, size: text-span);

   let saved-pos = context.source-stream.stream-position;
   context.source-stream.stream-position := token.parse-start;
   read-into!(context.source-stream, text-span, token.source-text);
   context.source-stream.stream-position := saved-pos;
end method;

define method capture-text-and-names
   (context :: <dylan-parse-context>, token :: <text-token>,
    source-names :: <sequence> /* of <text-name-token> */)
=> ()
   // Grab text from stream.
   capture-text(context, token);
   
   // Replace characters with appropriate <text-name-token>.
   let offset = token.parse-start;
   source-names := sort!(source-names,
         test: method (tok1 :: <text-name-token>, tok2 :: <text-name-token>)
               => (less? :: <boolean>)
                  tok1.parse-start < tok2.parse-start
               end);
   for (name in source-names using backward-iteration-protocol)
      when (name.parse-start >= token.parse-start & name.parse-end <= token.parse-end)
         token.source-text := replace-subsequence!(token.source-text, vector(name),
               start: name.parse-start - offset, end: name.parse-end - offset)
      end when;
   end for;
end method;

define method note-text-name (token :: <text-name-token>) => ()
   add-new!(*text-names*, token, test: \=)
end method;


//
// Source records
//

// Structure is [] or [[lines-til-parsable/#f, definition/doc-block], ...]
define method source-record-definitions (meat) => (defns)
   let flat-list = collect-subelements(meat, 1);
   choose(rcurry(instance?, <definition-token>), flat-list);
end method;


//
// Slots and initialization keywords
//

define class <class-keyword> (<updatable-source-location-mixin>)
   slot keyword-slot-name :: false-or(<string>);
   slot keyword-required? :: <boolean>;
   slot keyword-name :: <string>;
   slot keyword-type :: false-or(<text-token>);
   slot keyword-init :: false-or(<text-token>);
   slot keyword-doc :: false-or(<markup-content-token>);
end class;

define class <class-slot> (<updatable-source-location-mixin>)
   slot slot-modifiers :: <sequence> /* of <string> */;
   slot slot-name :: <string>;
   slot slot-type :: false-or(<text-token>);
   slot slot-init :: false-or(<text-token>);
   slot slot-setter :: false-or(<string>);
   slot slot-doc :: false-or(<markup-content-token>);
end class;

define method slot-from-clause (tok :: <token>)
=> (slot :: singleton(#f))
   #f
end method;

define method slot-from-clause (tok :: <slot-spec-token>)
=> (slot :: <class-slot>)
   let slot = make(<class-slot>, source-location: tok.source-location);
   slot.slot-doc := tok.clause-doc;
   slot.slot-modifiers := tok.slot-modifiers;
   slot.slot-name := tok.slot-name;
   slot.slot-type := tok.slot-type | clauses-type-option(tok.clause-options);
   slot.slot-init := tok.init-expression | clauses-init-option(tok.clause-options);

   let const? = member?("constant", slot.slot-modifiers, test: string-equal-ic?);
   let (setter-present?, setter-name) = clauses-setter-option(tok.clause-options);
   slot.slot-setter :=
         case
            const? => #f;
            setter-present? & setter-name => setter-name;
            setter-present? & ~setter-name =>
               slot.slot-modifiers := add!(slot.slot-modifiers, "constant");
               #f;
            otherwise => concatenate(slot.slot-name, "-setter");
         end case;

   slot;
end method;

define method keyword-from-clause (tok :: <token>)
=> (keyword :: singleton(#f))
   #f
end method;

define method keyword-from-clause (tok :: <slot-spec-token>)
=> (keyword :: false-or(<class-keyword>))
   let keyword-option = clauses-keyword-option(tok.clause-options);
   if (keyword-option)
      let keyword = make(<class-keyword>, source-location: tok.source-location);
      keyword.keyword-slot-name := tok.slot-name;
      keyword.keyword-required? :=
            instance?(keyword-option, <required-init-keyword-option-token>);
      keyword.keyword-name := keyword-option.value;
      keyword.keyword-type := tok.slot-type | clauses-type-option(tok.clause-options);
      keyword.keyword-init := tok.init-expression | clauses-init-option(tok.clause-options);
      keyword.keyword-doc := tok.clause-doc;
      keyword;
   end if;
end method;

define method keyword-from-clause (tok :: <init-arg-spec-token>)
=> (keyword :: <class-keyword>)
   let keyword = make(<class-keyword>, source-location: tok.source-location);
   keyword.keyword-slot-name := #f;
   keyword.keyword-required? := tok.keyword-required?;
   keyword.keyword-name := tok.keyword-name;
   keyword.keyword-type := clauses-type-option(tok.clause-options);
   keyword.keyword-init := clauses-init-option(tok.clause-options);
   keyword.keyword-doc := tok.clause-doc;
   keyword;
end method;

define method clauses-init-option (seq) => (tok :: false-or(<text-token>))
   let <init-option-type> =
         type-union(<init-value-option-token>, <init-function-option-token>);
   let tok = find-element(seq, rcurry(instance?, <init-option-type>), failure: #f);
   tok & tok.value
end method;

define method clauses-type-option (seq) => (tok :: false-or(<text-token>))
   let tok = find-element(seq, rcurry(instance?, <type-option-token>), failure: #f);
   tok & tok.value
end method;

define method clauses-setter-option (seq)
=> (present? :: <boolean>, setter :: false-or(<string>))
   let tok = find-element(seq, rcurry(instance?, <setter-option-token>), failure: #f);
   values(tok.true?, tok & tok.name);
end method;

define method clauses-keyword-option (seq) => (tok :: false-or(<token>))
   let <keyword-option-type> =
         type-union(<init-keyword-option-token>, <required-init-keyword-option-token>);
   find-element(seq, rcurry(instance?, <keyword-option-type>), failure: #f);
end method;

/// A keyword may be defined in several slot clause and in one keyword clause.
/// If both are provided, keep only the keyword clause.
define method remove-duplicate-keywords (seq) => (seq)
   let new-seq = make(<stretchy-vector>);
   for (k1 from 0 below seq.size)
      block (skip)
         when (seq[k1].keyword-slot-name)
            // This keyword is from a slot clause. Skip it, but only if there is
            // a keyword clause later.
            for (k2 from k1 + 1 below seq.size)
               if (string-equal-ic?(seq[k1].keyword-name, seq[k2].keyword-name))
                  if (seq[k2].keyword-slot-name = #f)
                     skip();
                  end if;
               end if;
            end for;
         end when;
         add!(new-seq, seq[k1]);
      end block;
   end for;
   new-seq
end method;


//
// Parameter lists
//

define abstract class <func-param> (<updatable-source-location-mixin>)
   slot param-doc :: false-or(<markup-content-token>), init-keyword: #"doc";
end class;

define abstract class <func-argument> (<func-param>)
end class;

define abstract class <func-value> (<func-param>)
end class;

define abstract class <required-argument> (<func-argument>)
   slot param-name :: <string>;
end class;

define class <required-typed-argument> (<required-argument>)
   slot param-type :: false-or(<text-token>), init-keyword: #"type";
end class;

define class <required-singleton-argument> (<required-argument>)
   slot param-instance :: false-or(<text-token>), init-keyword: #"instance";
end class;

define class <rest-argument> (<func-argument>)
   slot param-name :: <string>, init-keyword: #"name";
end class;

define class <keyword-argument> (<func-argument>)
   /// The keyword symbol; the actual variable name is of less interest.
   slot param-name :: <string>;
   slot param-type :: false-or(<text-token>);
   slot param-default :: false-or(<text-token>);
end class;

define class <accepts-keys-argument> (<func-argument>)
end class;

define class <all-keys-argument> (<func-argument>)
end class;

define class <required-value> (<func-value>)
   slot param-name :: <string>, init-keyword: #"name";
   slot param-type :: false-or(<text-token>), init-keyword: #"type";
end class;

define class <rest-value> (<func-value>)
   slot param-name :: <string>, init-keyword: #"name";
   slot param-type :: false-or(<text-token>), init-keyword: #"name";
end class;

define method parameter-list-from-token (tok == #f)
=> (param-list :: <sequence>)
   #[]
end method;

define method parameter-list-from-token (params-tok :: <parameters-token>)
=> (param-list :: <sequence>)
   let required-param-list = map-as(<stretchy-vector>, required-param-from-token,
                                    params-tok.required-params);
   let rest-key-param-list = rest-key-params-from-token(params-tok.rest-key-param);
   concatenate(required-param-list, rest-key-param-list);
end method;

define method required-param-from-token (param-tok :: <required-parameter-token>)
=> (param :: <required-argument>)
   let param =
         if (param-tok.req-sing?)
            make(<required-singleton-argument>, instance: param-tok.req-inst,
                 source-location: param-tok.source-location);
         else
            make(<required-typed-argument>, type: param-tok.req-var.type,
                 source-location: param-tok.source-location);
         end if;
   param.param-doc := param-tok.req-doc;
   param.param-name := param-tok.req-var.name;
   param
end method;

define method rest-key-params-from-token (tok == #f)
=> (param-list :: <sequence>)
   #[]
end method;

define method rest-key-params-from-token (tok :: <rest-key-parameter-list-token>)
=> (param-list :: <sequence>)
   let rest-param = tok.rest-var &
         make(<rest-argument>, doc: tok.rest-doc, name: tok.rest-var.name,
              source-location: tok.source-location);
   let key-param-list = key-params-from-token(tok.key-param);
   add-to-front(rest-param, key-param-list);
end method;

define method key-params-from-token (tok == #f)
=> (param-list :: <sequence>)
   #[]
end method;

define method key-params-from-token (tok :: <key-parameter-list-token>)
=> (param-list :: <sequence>)
   let accepts-keys-param = make(<accepts-keys-argument>, doc: #f,
                                 source-location: tok.source-location);
   let all-keys-param = tok.all-keys? &
                        make(<all-keys-argument>, doc: #f,
                             source-location: tok.source-location);
   let key-param-list = map-as(<stretchy-vector>, key-param-from-token, tok.key-params);
   key-param-list := add-to-front(accepts-keys-param, key-param-list);
   if (all-keys-param)
      add!(key-param-list, all-keys-param);
   end if;
   key-param-list;
end method;

define method key-param-from-token (tok :: <keyword-parameter-token>)
=> (param :: <keyword-argument>)
   let keyword = make(<keyword-argument>, doc: tok.key-doc,
                      source-location: tok.source-location);
   keyword.param-name := tok.key-symbol | tok.key-var.name;
   keyword.param-type := tok.key-var.type;
   keyword.param-default := tok.key-default;
   keyword
end method;

define method value-list-from-token (token == #f)
=> (value-list :: <sequence>)
   #[]
end method;

define method value-list-from-token (token :: <variable-token>)
=> (value-list :: <sequence>)
   vector(value-from-token(token))
end method;

define method value-list-from-token (token :: <values-list-token>)
=> (value-list :: <sequence>)
   let rest-value = token.rest-val &
         make(<rest-value>, doc: token.rest-doc, source-location: token.source-location,
              name: token.rest-val.name, type: token.rest-val.type);
   let req-values = map-as(<stretchy-vector>, value-from-token, token.required-vals);
   if (rest-value)
      add!(req-values, rest-value)
   else
      req-values;
   end if;
end method;

define method value-from-token (token :: <variable-token>)
=> (value :: <required-value>)
   make(<required-value>, doc: token.var-doc, name: token.name, type: token.type,
        source-location: token.source-location);
end method;
