module: configs
synopsis: Configurable parameters. These are read from config files if present.


define variable *api-list-file* :: false-or(<file-locator>) = #f;
define variable *template-directory* :: <directory-locator>
      = as(<directory-locator>, "../defaults");

define variable *topic-file-extension* :: <string> = "txt";
define variable *contents-file-extension* :: <string> = "toc";
define variable *config-file-extension* :: <string> = "cfg";

define variable *package-title* :: <string> = "Untitled";
define variable *output-directory* :: <directory-locator>
      = as(<directory-locator>, "./doc");
define variable *output-types* :: <sequence> = #[ #"html" ];

define variable *scan-only?* :: <boolean> = #f;

define constant $debug-features =
      #[ #"doc-tree", #"raw-topics", #"dylan-parser", #"file-markup-parser",
         #"template-markup-parser", #"template-output" ];

define variable *debug-features* :: <sequence> = #[];

define method debugging? (#rest features) => (debugging? :: <boolean>)
   intersection(features, *debug-features*).size > 0
end method;


/// Synopsis: The size of the tab character, in spaces. The parsers do not want
/// tab characters.
define constant $tab-size = 8;


/// Synopsis: The set of characters allowed for underline/overline.
define variable *ascii-line-chars* :: <string> = "=-:.~^_*+#";


/// Synopsis: The set of characters allowed for bullets.
define variable *bullet-chars* :: <string> = "-*+";


/// Synopsis: The set of quote characters.
define variable *quote-pairs* :: <vector> =
      #[ #["{", "}"],
         #["'", "'"],
         #["\"", "\""],
         #["`", "`"], 
         #["``", "``"] ];


/// Synopsis: The specifiers for each quote type in markup.
/// Key is open-quote characters.
define variable *quote-specs* =
      table(<string-table>,
            "{" =>   #[#"qv"],
            "'" =>   #[#"api", #"qv"],
            "\"" =>  #[#"qq"],
            "`" =>   #[#"api"],
            "``" =>  #[#"code"]
      );


/// Synopsis: The underline/overline style of a section (as opposed to topic).
/// TODO: Should be configurable.
define variable *section-style* :: <topic-level-style> =
      make(<topic-level-style>, char: '-', under: #f, mid: #t, over: #f);


/// Synopsis: Records the characteristics of a topic level style.
define class <topic-level-style> (<object>)
   slot line-character :: <character>, init-keyword: #"char";
   slot underline? :: <boolean>, init-keyword: #"under";
   slot midline? :: <boolean>, init-keyword: #"mid";
   slot overline? :: <boolean>, init-keyword: #"over";
end class;

define method \= (style1 :: <topic-level-style>, style2 :: <topic-level-style>)
=> (equal? :: <boolean>)
   style1.line-character = style2.line-character &
   style1.underline? = style2.underline? &
   style1.midline? = style2.midline? &
   style1.overline? = style2.overline?
end method;

define method print-object (o :: <topic-level-style>, s :: <stream>) => ()
   format(s, "{topic-style '%c'%s%s%s}", o.line-character,
          (o.overline? & " over") | "", (o.midline? & " mid") | "",
          (o.underline? & " under") | "");
end method;

