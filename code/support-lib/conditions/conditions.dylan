module: conditions
synopsis: Condition support and error handling.


define macro errors-definer
   {  define errors (?class:expression)
         ?code:expression ?:name ?format-string:expression, location, ?format-args:*;
         ?more:*
      end
   }
   => {  define function ?name (#key location, ?format-args)
            signal(make(?class,
                        error-code: ?code,
                        error-location: location,
                        format-string: ?format-string,
                        format-arguments: vector(?format-args)));
         end;
         define errors (?class) ?more end
      }

   {  define errors (?class:expression)
         ?code:expression ?:name ?format-string:expression, ?format-args:*;
         ?more:*
      end
   }
   => {  define function ?name (#key ?format-args)
            signal(make(?class,
                        error-code: ?code,
                        error-location: #f,
                        format-string: ?format-string,
                        format-arguments: vector(?format-args)));
         end;
         define errors (?class) ?more end
      }

   { define errors (?class:expression) end } => { }
end macro;


/** Synopsis: Conditions that may be displayed for the user. **/
define abstract class <user-visible-condition> (<format-string-condition>)
   constant slot error-location ::
         type-union(<source-location>, <file-locator>, singleton(#f)),
      required-init-keyword: #"error-location";
   constant slot error-code :: <integer>,
      required-init-keyword: #"error-code";
end class;

define method make
   (cls :: subclass(<user-visible-condition>),
    #key format-string, format-arguments, error-code, error-location,
         error-class :: <string>)
=> (inst :: <user-visible-condition>)
   let (prefix-string, prefix-args) =
         if (~error-location | ~instance?(error-location, <file-source-location>))
            values("%s: ", vector(error-class))
         else
            values("%s: %s: ", vector(error-location, error-class))
         end if;

   let padded-code = integer-to-string(error-code, size: 2);
   let (postfix-string, postfix-args) = values(" (%s)", vector(padded-code));
   next-method(cls, error-code: error-code, error-location: error-location,
         format-string: concatenate(prefix-string, format-string, postfix-string),
         format-arguments: concatenate(prefix-args, format-arguments, postfix-args))
end method;

// Use io library to format string.
define method condition-to-string (cond :: <user-visible-condition>)
=> (str :: <string>)
   apply(format-to-string, cond.condition-format-string, cond.condition-format-arguments)
end method;


/**
Synopsis: Can be disabled and safely ignored by the user; content is still valid
or as valid as possible. The program must have a fallback.

Recovery protocol is handler can return values (which are ignored).
**/
define class <user-visible-warning> (<user-visible-condition>, <warning>)
end class;

define method make
   (cls == <user-visible-warning>, #rest keys, #key, #all-keys)
=> (inst :: <user-visible-warning>)
   apply(next-method, cls, error-class:, "Warning", keys);
end method;

define method return-allowed? (warning :: <user-visible-warning>)
=> (yes :: singleton(#t))
   #t
end method;


/**
Synopsis: Cannot be disabled or safely ignored by the user; results in incorrect
content. The program may have a fallback allowing it to display further errors.

Recovery protocol is handler cannot return values, but can signal
<skip-error-restart>.
**/
define class <user-visible-error> (<user-visible-condition>, <serious-condition>)
end class;

define method make
   (cls == <user-visible-error>, #rest keys, #key, #all-keys)
=> (inst :: <user-visible-error>)
   apply(next-method, cls, #"error-class", "Error", keys);
end method;


/**
Synopsis: Retry handler for <user-visible-error>, in case program can continue.
**/
define abstract class <user-visible-restart> (<restart>)
   constant slot error-condition :: <user-visible-error>,
         required-init-keyword: #"condition";
end class;

/** Synopsis: Handler to skip an erroneous thing. **/
define class <skip-error-restart> (<user-visible-restart>)
end class;


define errors (<user-visible-warning>)
   01 unparsable-expression-in-code
      "Unparsable expression will not be automatically documented",
      location;
   
   02 unsupported-syntax-in-code
      "Unsupported syntactic form will not be automatically documented",
      location;

   03 api-not-found-in-code
      "No source code found for %s \"%s\"",
      location, topic-type, api-name;

   04 doc-comment-in-undocumented-file
      "Documentation from internal %s \"%s\" will not be used",
      location, api-type, api-name;

   05 qv-or-vi-in-title
      "Title cannot include quoted phrase options \"qv\" or \"vi\"",
      location;
   
   06 doc-comment-on-virtual-slot
      "Virtual slot can only be documented via its method or generic definition",
      location;
      
   07 doc-comment-on-binding-alias
      "Alias of binding \"%s\" can only be documented via the original binding",
      location, alias-name;
   
   08 ambiguous-module-in-topics
      "\"%s\" is ambiguous and might refer to any of %s; "
      "specify with \"In Library:\" directive",
      location, api-name, qualified-names;
   
   09 api-not-found-in-namespace
      "No source code found for %s \"%s\" in \"%s\"",
      location, topic-type, api-name, api-namespace;
   
   10 unused-docs-in-topic
      "Documentation replaces other documentation at %s",
      location, doc-locations;
   
   11 ambiguous-binding-in-topics
      "\"%s\" is ambiguous and might refer to any of %s; "
      "specify with \"In Module:\" directive",
      location, api-name, qualified-names;
   
   12 unresolvable-target-in-xref
      "Unable to resolve cross-reference to \"%s\"",
      location, target-text;
   
   13 section-id-without-topic-id
      "Section tag has no use without topic tag",
      location;

   14 ambiguous-title-in-xref
      "Cross-reference to \"%s\" is ambiguous and might refer to any of %s",
      location, target-text, target-locations;
   
   15 doc-comment-on-undocumented-api
      "Documentation related to internal %s \"%s\" will not be used",
      location, api-type, api-name;
      
   16 mismatch-in-api-arguments
      "Documented parameters of \"%s\" do not match source code",
      location, qualified-name;
      
   17 mismatch-in-api-values
      "Documented return values of \"%s\" do not match source code",
      location, qualified-name;
      
   18 mismatch-in-api-keywords
      "Documented keywords of \"%s\" do not match source code",
      location, qualified-name;
   
   19 unknown-config-in-cfg-file
      "Unknown config \"%s\"",
      location, config-name;
end errors;


define errors (<user-visible-error>)
   51 illegal-character-in-id
      "Tag cannot include space, slash, open bracket, or close bracket characters",
      location;

   52 leading-colon-in-id
      "Tag cannot include a leading colon",
      location;

   53 leading-colon-in-title
      "Title cannot include a leading colon",
      location;

   54 duplicate-section-in-topic
      "Topic can only include one \"%s\" section",
      location, section-type;

   55 illegal-section-in-topic
      "Topic cannot include \"%s\" section",
      location, section-type;

   56 q-and-qq-in-spec
      "Quoted phrase options cannot include both \"q\" and \"qq\"",
      location;

   57 bad-syntax-in-toc-file
      "Incorrect syntax",
      location;
   
   58 skipped-level-in-toc-file
      "Over-indented title or tag",
      location;
   
   59 parse-error-in-markup
      "Unparsable markup; expected %s",
      location, expected;

   60 parse-error-in-dylan
      "Unparsable syntax; expected %s",
      location, expected;

   61 no-context-topic-in-block
      "Content not associated with a topic",
      location;

   62 target-not-found-in-link
      "Title or tag \"%s\" not found",
      location, target-text;

   63 duplicate-id-in-targets
      "Tag is already used at %s", 
      location, id-locations;

   64 id-matches-topic-title
      "Tag is already used as title at %s",
      location, title-locations;

   65 ambiguous-title-in-link
      "\"%s\" is ambiguous and might refer to any of %s",
      location, target-text, target-locations;

   66 conflicting-locations-in-tree
      "Topic is placed ambiguously by %s",
      location, arranger-locations;
   
   67 multiple-libraries-in-fileset
      "Multiple library definitions found in library at %s",
      location, defn-locations;
   
   68 no-library-in-fileset
      "No library definition found in %s",
      filenames;
   
   69 link-without-qv-or-vi-in-spec
      "Quoted phrase options include a link without \"qv\" or \"vi\"",
      location;

   70 file-error
      "File error with %s: %s",
      filename, error;

   71 file-not-found
      "File %s not found",
      location, filename;
   
   72 empty-header-in-interchange-file
      "\"%s\" header is empty",
      location, header;
   
   73 error-in-command-option
      "Incorrect %s option; see --help",
      option;
   
   74 no-files-in-command-arguments
      "No files specified; see --help";
   
   75 conflicting-modules-in-library
      "Differing definitions of module \"%s\" at %s",
      location, name, defn-locations;
   
   76 error-in-command-arguments
      "Incorrect arguments; see --help";
   
   77 no-header-in-interchange-file
      "\"%s\" header is missing",
      location, header;

   78 file-type-not-known
      "File %s has unknown extension",
      filename;
   
   79 undefined-module-for-interchange-file
      "No definition of module \"%s\"",
      location, name;
   
   80 conflicting-bindings-in-module
      "Differing definitions of binding \"%s\" at %s",
      location, name, defn-locations;
   
   81 conflicting-libraries-in-filesets
      "Differing definitions of library \"%s\" at %s",
      location, name, defn-locations;
   
   82 circular-definition
      "Circular dependency for \"%s\" among %s",
      location, name, defn-locations;

   83 multiple-topics-for-api
      "Multiple topics for \"%s\" found at %s",
      location, name, topic-locations;
   
   84 topics-in-nontopic-markup
      "Content cannot include topics at %s",
      location, topic-locations;
   
   85 sections-in-nonsection-markup
      "Content cannot include sections at %s",
      location, section-locations;
   
   86 inconsistent-cpl
      "Superclasses cannot be determined; inconsistent class precedence list",
      location;
   
   87 circular-class-inheritance
      "Circular inheritance among %s",
      location, defn-locations;

   88 multiple-topics-for-fqn
      "Multiple topics with fully qualified name \"%s\" found at %s", 
      location, fqn, fqn-locations;
   
   89 section-where-topic-required-in-link
      "Topic-only link cannot refer to section at %s",
      location, section-location;
   
   90 library-specifier-in-non-module-topic
      "Library specifier only applies to module topics",
      location;

   91 module-specifier-in-non-binding-topic
      "Module specifier only applies to binding topics",
      location;
   
   92 duplicate-configs-in-cfg-files
      "Multiple settings for config \"%s\" found at %s",
      location, config-name, config-locations;
   
   93 error-in-config
      "Config \"%s\" is not specified with the correct syntax",
      location, config-name;
   
   94 error-in-config-option
      "Config \"%s\" does not allow \"%s\"",
      location, config-name, option;
      
   95 illegal-character-in-section-style
      "Section markup character \"%c\" not included in valid header characters \"%s\"",
      section-header-char, header-chars;
      
   96 no-target-for-indexed-reference
      "Markup does not include %s \"%s\"",
      location, reference-type, reference-index;
      
   97 footnote-referenced-outside-topic
      "Footnote \"%s\" must be defined in same topic",
      location, reference-index;
end errors;
