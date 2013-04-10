module: main

//// Arguments

// TODO: Make --names a separate task from doc gen.

define command-line <my-command-line-parser> ()
   positional-options files;
   option output-path :: <directory-locator> = *output-directory*,
      names: #("output-dir", "o"), 
      variable: "DIRECTORY", help: "Documentation path [\"%default\"]",
      kind: <parameter-option>;
   option output-formats :: <symbol> = *output-types*,
      names: #("format", "f"), 
      variable: "html|dita",
      help: format-to-string("Documentation format [%s]",
                             *output-types*.item-string-list),
      kind: <repeated-parameter-option>;
   option package-title = *package-title*,
      names: #("title", "t"),
      help: "Documentation title [\"%default\"]",
      kind: <parameter-option>;
   option cfg-pattern = *config-file-extension*, 
      names: #("cfg", "c"), 
      variable: "EXT", help: "Configuration files [\"%default\"]",
      kind: <parameter-option>;
   option toc-pattern = *contents-file-extension*, 
      names: #("toc"),
      variable: "EXT", help: "Table of contents files [\"%default\"]",
      kind: <parameter-option>;
   option doc-pattern = *topic-file-extension*, 
      names: #("doc"),
      variable: "EXT", help: "Documentation text files [\"%default\"]",
      kind: <parameter-option>;
   option template-path :: <directory-locator> = *template-directory*, 
      names: #("templates", "T"),
      variable: "DIRECTORY", help: "Template files [\"%default\"]",
      kind: <parameter-option>;
   option api-list-filename :: <file-locator>, 
      names: #("names", "n"), 
      variable: "FILENAME", help: "Write fully qualified API names to file",
      kind: <parameter-option>;
   option ignore-comments?,
      names: #("no-comment", "N"),
      help: "Ignore source code documentation comments";
   option disabled-warnings, 
      names: #("no-warn", "w"), 
      variable: "NN", help: "Hide warning message",
      kind: <repeated-parameter-option>;
   option stop-on-errors?,
      names: #("stop"),
      help: "Stop on first error or warning";
   option debug-features :: <symbol>, 
      names: #("debug", "D"),
      variable: "FEATURE", help: "Enable developer debugging feature",
      kind: <repeated-parameter-option>;
   option quiet?,
      names: #("quiet", "q"),
      help: "Hide progress messages";
   option new-config-file, 
      names: #("new-config"), 
      variable: "FILENAME", help: "Create default config file and exit",
      kind: <parameter-option>;
   option help?,
      names: #("help", "h"),
      help: "Show this help message and exit";
   option version?,
      names: #("version"),
      help: "Show program version and exit";
   synopsis "Usage: doctower [OPTIONS] FILES\n",
      description:
      "Creates Dylan API documentation from files. Files may include configuration\n"
      "files, table of contents files, documentation text files, Dylan source code\n"
      "files, and Dylan LID files.\n"
end command-line;

define method parse-option-parameter (param :: <string>, type == <directory-locator>)
=> (value)
   as(<directory-locator>, param)
end method;

define method parse-option-parameter (param :: <string>, type == <file-locator>)
=> (value)
   as(<file-locator>, param)
end method;


//// Main

define constant $disabled-warnings = make(<stretchy-vector>);
define variable *stop-on-errors?* :: <boolean> = #f;
define variable *error-code* :: false-or(<integer>) = #f;

define function main (name, arguments)

   // Retrieve arguments

   let args = make(<my-command-line-parser>, provide-help-option?: #f);
   block()
      parse-command-line(args, arguments)
   exception (err :: <usage-error>)
      error-in-command-arguments();
   end block;

   // Set basic configs

   *verbose?* := ~args.quiet?;

   block()
      map-into($disabled-warnings, string-to-integer, args.disabled-warnings)
   exception (e :: <error>)
      error-in-command-option(option: "--no-warn");
   end block;

   *stop-on-errors?* := args.stop-on-errors?;
   *debug-features* := args.debug-features;
   unless (every?(rcurry(member?, $debug-features), *debug-features*))
      error-in-command-option(option: "--debug");
   end unless;

   // Process act-and-exit command-line options

   case
       args.new-config-file =>
         verbose-log("Writing %s", args.new-config-file);
         create-config-file(args.new-config-file);
         exit-application(0);
      args.help? =>
         print-synopsis(args, *standard-output*);
         format-out("\nDeveloper debugging features that can be enabled are:\n%s\n",
               $debug-features.item-string-list);
         exit-application(0);
      args.version? =>
         format-out("Doctower 1.0\nby Dustin Voss\n");
         exit-application(0);
      args.files.empty? =>
         no-files-in-command-arguments();
   end case;
   
   block (exit)

      // Retrieve and process config files
   
      let file-locators = map(curry(as, <file-locator>), args.files);
      *config-file-extension* := args.cfg-pattern | *config-file-extension*;
      let cfg-files = choose(
            method (loc :: <file-locator>) => (cfg-locator? :: <boolean>)
               string-equal-ic?(*config-file-extension*, loc.locator-extension)
            end method, file-locators);
   
      set-configs-with-files(cfg-files);

      // Override configs with command-line options

      if (args.toc-pattern-parser.option-present?)
         *contents-file-extension* := args.toc-pattern;
      end;

      if (args.doc-pattern-parser.option-present?)
         *topic-file-extension* := args.doc-pattern;
      end;

      if (args.package-title-parser.option-present?)
         *package-title* := args.package-title;
      end;

      if (args.ignore-comments?-parser.option-present?)
         *scan-only?* := args.ignore-comments?;
      end;

      if (args.template-path-parser.option-present?)
         *template-directory* := args.template-path;
      end;

      if (args.output-path-parser.option-present?)
         *output-directory* := args.output-path;
      end;

      if (args.output-formats-parser.option-present?)
         *output-types* := args.output-formats;
      end;

      if (args.api-list-filename-parser.option-present?)
         *api-list-file* := args.api-list-filename;
      end;

      // Classify input files

      let toc-files = make(<stretchy-vector>);
      let doc-files = make(<stretchy-vector>);
      let src-files = make(<stretchy-vector>);
      for (loc in file-locators)
         select (loc.locator-extension by string-equal-ic?)
            *config-file-extension*
               => #f /* Already dealt with these */;
            *topic-file-extension*
               => doc-files := add!(doc-files, loc);
            *contents-file-extension*
               => toc-files := add!(toc-files, loc);
            ("dylan", "dyl", "lid")
               => src-files := add!(src-files, loc);
            otherwise
               => file-type-not-known(filename: as(<string>, loc));
         end select;
      end for;
   
      // Build documentation

      if (*error-code*) exit() end;
      let doc-tree = create-doc-tree(toc-files, doc-files, src-files);

      if (*error-code*) exit() end;
      create-output-files(doc-tree);

      if (debugging?(#"doc-tree"))
         log("--- Doc tree ---");
         print(doc-tree, *standard-output*, pretty?: #t);
         new-line(*standard-output*);
      end if;
   end block;

   exit-application(*error-code* | 0);
end function main;


// Invoke our main() function with error handlers.
begin
   let handler <user-visible-error> =
         method (cond, next)
            format(*standard-error*, "%s\n", cond);
            force-output(*standard-error*);
            when (*stop-on-errors?*)
               exit-application(cond.error-code);
            end when;
            *error-code* := *error-code* | cond.error-code;
            signal(make(<skip-error-restart>, condition: cond));
         end method;
   
   let handler <user-visible-warning> =
         method (cond, next)
            case
               member?(cond.error-code, $disabled-warnings) =>
                  #f;
               *stop-on-errors?* =>
                  format(*standard-error*, "%s\n", cond);
                  force-output(*standard-error*);
                  exit-application(cond.error-code);
               otherwise =>
                  format(*standard-output*, "%s\n", cond);
                  force-output(*standard-output*);
            end case
         end method;
   
   let handler <skip-error-restart> =
         method (cond, next)
            exit-application(*error-code*);
         end method;
         
   *default-line-length* := 132;
   main(application-name(), application-arguments());
end
