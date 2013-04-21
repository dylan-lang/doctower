module: markup-rep
synopsis: Intermediate elements from quote directives.


define class <xref> (<markup-element>)
   // If the target is <topic>, <footnote>, <exhibit>, <line-marker>, or <section>,
   // the DITA xref tag will have a format attr of "dita," else based on the URL;
   // the scope attr will be "local," else "external." If the text is <conref>,
   // its style must be #"title" and the target's title is used as the text.
   slot target :: type-union(<topic>, <footnote>, <exhibit>, <section>, <line-marker>,
                             <url>, <target-placeholder>, <footnote-placeholder>,
                             <line-marker-placeholder>, <exhibit-placeholder>),
         init-keyword: #"target";
   // Can be a <conref>, <title-seq>, or anything allowed in a <title-seq>. This
   // includes <cite> which is not normally allowed in DITA <xref>, but we put
   // the link text in a <ph> so it is okay. Ignored for <footnote>, <exhibit>,
   // and <line-marker> targets.
   slot markup-text = make(<title-seq>),
         init-keyword: #"text";
   slot target-from-text? :: <boolean> = #f,
         init-keyword: #"target-from-text";
end class;

/// Synopsis: Represents a vi quotation directive (as opposed to <xref>'s qv
/// directive).
define class <vi-xref> (<xref>)
   inherited slot target /* :: type-union(<topic>, <target-placeholder>) */;
end class;

define class <api/parm-name> (<markup-element>)
   // DITA only allows plain text; must be innermost quotation wrapper.
   slot markup-text :: <string>, init-keyword: #"text";
end class;

define class <term> (<markup-element>)
   // DITA only allows plain text; must be innermost quotation wrapper.
   slot markup-text :: <string>, init-keyword: #"text";
end class;

/// Synopsis: Like <emphasis>, this is a style that will be rendered as bold,
/// italic, whatever. It is associated with a <term>, but is separate to allow
/// for typographical quotes that are appropriately styled but not part of the
/// actual term.
define class <term-style> (<markup-element>)
   slot markup-text, init-keyword: #"text";
end class;

define class <code-phrase> (<markup-element>)
   slot markup-text, init-keyword: #"text";
end class;

define class <entity> (<markup-element>)
   slot code :: <integer>, init-keyword: #"code";
end class;

define class <cite> (<markup-element>)
   slot markup-text, init-keyword: #"text";
end class;

define class <bold> (<markup-element>)
   slot markup-text, init-keyword: #"text";
end class;

define class <italic> (<markup-element>)
   slot markup-text, init-keyword: #"text";
end class;

define class <underline> (<markup-element>)
   slot markup-text, init-keyword: #"text";
end class;

define class <emphasis> (<markup-element>)
   slot markup-text, init-keyword: #"text";
end class;
