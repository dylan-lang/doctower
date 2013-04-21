module: markup-rep
synopsis: Contains slot visitor functions.


/// Generic Function: visit-target-references
/// Synopsis: Visits a <topic> and its nested elements that can contain
/// user-specified <target-placeholder> objects or resolved <target-placeholder>
/// objects.
///
/// Arguments:
///   element     - The <markup-element> or collection to visit.
///   operation   - A <function> on 'element'. The setter is passed a setter:
///                 [api] argument and the 'keys' argument.
///   #rest keys  - A set of keys passed to 'operation'.

define collection-recursive slot-visitor visit-target-references
   // Topic elements
   <topic>,                content, shortdesc, parent, footnotes, related-links,
                           relevant-to;
   <api-doc>,              declarations-section;
   <library-doc>,          modules-section;
   <module-doc>,           bindings-section;
   <class-doc>,            adjectives-section, keywords-section, conds-section,
                           inheritables-section, supers-section, subs-section,
                           funcs-on-section, funcs-returning-section;
   <function-doc>,         adjectives-section, args-section, vals-section, conds-section;
   <variable-doc>,         adjectives-section, value-section;
   <macro-doc>,            syntax-section, args-section, vals-section;
   <placeholder-doc>,      ;
   <unbound-doc>,          ;

   // Body elements
   <conref>,               target;
   <defn-list>,            items;
   <footnote>,             content;
   <exhibit>,              content;
   <note>,                 content;
   <ordered-list>,         items;
   <unordered-list>,       items;
   <paragraph>,            content;
   <section>,              title, content;
   <simple-table>,         headings, items;

   // Quote elements
   <api/parm-name>,        markup-text;
   <bold>,                 markup-text;
   <cite>,                 markup-text;
   <code-phrase>,          markup-text;
   <emphasis>,             markup-text;
   <italic>,               markup-text;
   <term-style>,           markup-text;
   <term>,                 markup-text;
   <underline>,            markup-text;
   <xref>,                 target, markup-text;
   
   // Placeholders
   <ditto-placeholder>,    target;
   <target-placeholder>,   ;
   <topic-ref>,            target;
   
   // Cut collection recursion
   <string>,               ;
end slot-visitor;


/// Generic function: visit-content-references
/// Synopsis: Visit a <topic> and its nested elements that can contain
/// <ditto-placeholder> objects.
///
/// Arguments:
///   element     - The <markup-element> or collection to visit.
///   operation   - A <function> on 'element'. The setter is passed a 'setter:'
///                 [api] argument and the 'keys' argument.
///   #rest keys  - A set of keys passed to 'operation'.

define collection-recursive slot-visitor visit-content-references
   // Topic elements
   <topic>,                content, footnotes;
   <api-doc>,              declarations-section;
   <library-doc>,          modules-section;
   <module-doc>,           bindings-section;
   <class-doc>,            adjectives-section, keywords-section, conds-section,
                           inheritables-section, supers-section, subs-section,
                           funcs-on-section, funcs-returning-section;
   <function-doc>,         adjectives-section, args-section, vals-section, conds-section;
   <variable-doc>,         adjectives-section, value-section;
   <macro-doc>,            syntax-section, args-section, vals-section;
   <placeholder-doc>,      ;
   <unbound-doc>,          ;
   
   // Body elements
   <defn-list>,            items;
   <footnote>,             content;
   <exhibit>,              content;
   <note>,                 content;
   <ordered-list>,         items;
   <section>,              content;
   <simple-table>,         items;
   <unordered-list>,       items;
   
   // Quote elements
   <api/parm-name>,        markup-text;
   <bold>,                 markup-text;
   <cite>,                 markup-text;
   <code-phrase>,          markup-text;
   <emphasis>,             markup-text;
   <italic>,               markup-text;
   <term-style>,           markup-text;
   <term>,                 markup-text;
   <underline>,            markup-text;
   <xref>,                 target, markup-text;

   // Placeholders
   <ditto-placeholder>     ;
   
   // Cut collection recursion
   <string>                ;
end slot-visitor;


/// Generic function: visit-markup-references
/// Synopsis: Visit a <topic> and its nested elements that can contain
/// <footnote-placeholder>, <exhibit-placeholder>, or <line-marker-placeholder>
/// objects.
///
/// Arguments:
///   element     - The <markup-element> or collection to visit.
///   operation   - A <function> on 'element'. The setter is passed a 'setter:'
///                 [api] argument and the 'keys' argument.
///   #rest keys  - A set of keys passed to 'operation'.

define collection-recursive slot-visitor visit-markup-references
   // Topic elements
   <topic>,                   content, footnotes;
   <api-doc>,                 declarations-section;
   <library-doc>,             modules-section;
   <module-doc>,              bindings-section;
   <class-doc>,               adjectives-section, keywords-section, conds-section,
                              inheritables-section, supers-section, subs-section,
                              funcs-on-section, funcs-returning-section;
   <function-doc>,            adjectives-section, args-section, vals-section, conds-section;
   <variable-doc>,            adjectives-section, value-section;
   <macro-doc>,               syntax-section, args-section, vals-section;
   <placeholder-doc>,         ;
   <unbound-doc>,             ;
   
   // Body elements
   <defn-list>,               items;
   <footnote>,                content;
   <exhibit>,                 content;
   <note>,                    content;
   <ordered-list>,            items;
   <paragraph>,               content;
   <section>,                 content;
   <simple-table>,            items;
   <unordered-list>,          items;
   
   // Quote elements
   <api/parm-name>,           markup-text;
   <bold>,                    markup-text;
   <cite>,                    markup-text;
   <code-phrase>,             markup-text;
   <emphasis>,                markup-text;
   <italic>,                  markup-text;
   <term-style>,              markup-text;
   <term>,                    markup-text;
   <underline>,               markup-text;
   <xref>,                    target, markup-text;

   // Placeholders
   <footnote-placeholder>,    ;
   <exhibit-placeholder>,     ;
   <line-marker-placeholder>, ;
   
   // Cut collection recursion
   <string>                   ;
end slot-visitor;


/// Generic function: visit-targets
/// Synopsis: Visit a <topic> and its nested elements that can contain <xref> or
/// <conref> targets.
///
/// These targets are <topic>, <section>, <footnote>, <exhibit>, and <line-marker>.
///
/// Arguments:
///   element     - The <markup-element> or collection to visit.
///   operation   - A <function> on 'element'. The setter is passed a 'setter:'
///                 [api] argument and the 'keys' argument.
///   #rest keys  - A set of keys passed to 'operation'.

define collection-recursive slot-visitor visit-targets
   // Topic elements
   <topic>,           content, footnotes;
   <api-doc>,         declarations-section;
   <library-doc>,     modules-section;
   <module-doc>,      bindings-section;
   <class-doc>,       adjectives-section, keywords-section, conds-section,
                      inheritables-section, supers-section, subs-section,
                      funcs-on-section, funcs-returning-section;
   <function-doc>,    adjectives-section, args-section, vals-section, conds-section;
   <variable-doc>,    adjectives-section, value-section;
   <macro-doc>,       syntax-section, args-section, vals-section;
   <placeholder-doc>, ;
   <unbound-doc>,     ;

   // Body elements
   <section>,         content;
   <footnote>,        content;
   <exhibit>,         content;
   <note>,            content;
   <ordered-list>,    items;
   <unordered-list>,  items;
   <defn-list>,       items;
   <simple-table>,    items;
   <line-marker>,     ;
   <pre>,             content;
   
   // Cut collection recursion
   <string>,          ;
end slot-visitor;
