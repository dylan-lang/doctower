module: config-files
synopsis: Converts between .cfg and internal representations of each setting.


define constant $illegal-quote-chars = "()[]";
define constant $valid-quote-options = #[ "unq", "sic", "q", "qq", "code",
      "term", "bib", "api", "em", "b", "i", "u", "qv", "vi" ];

define constant $valid-output-types = #[ "html", "dita" ];

define constant $valid-line-positions = #[ "above", "below", "sides" ];


define table $setting-parsers = {
   #"api-list-file" =>           parse-filename,
   #"ascii-line-chars" =>        parse-char-list,
   #"bullet-chars" =>            parse-char-list,
   #"contents-file-extension" => parse-file-ext,
   #"output-directory" =>        parse-directory,
   #"output-types" =>            rcurry(parse-symbol-list, $valid-output-types),
   #"package-title" =>           parse-string,
   // #"quote-pairs" =>             #f,
   #"quote-specs" =>             parse-quote-setting,
   #"scan-only?" =>              parse-boolean-complement,
   #"section-style" =>           parse-title-style,
   #"template-directory" =>      parse-directory,
   #"topic-file-extension" =>    parse-file-ext
};


define function parse-filename
   (lines :: <sequence>, name :: <symbol>, header-rest :: false-or(<string>),
    locator :: <function>)
=> (setting :: <setting>)
   let value-string = header-rest | element(lines, 1, default: #f);
   let value = as(<file-locator>, strip(value-string));
   make(<setting>, key: name, value: value)
end function;


define function parse-directory
   (lines :: <sequence>, name :: <symbol>, header-rest :: false-or(<string>),
    locator :: <function>)
=> (setting :: <setting>)
   let value-string = header-rest | element(lines, 1, default: #f);
   let value = as(<directory-locator>, strip(value-string));
   make(<setting>, key: name, value: value)
end function;


define function parse-string
   (lines :: <sequence>, name :: <symbol>, header-rest :: false-or(<string>),
    locator :: <function>)
=> (setting :: <setting>)
   let value-string = header-rest | element(lines, 1, default: #f);
   make(<setting>, key: name, value: strip(value-string))
end function;

define constant parse-char-list = parse-string;
define constant parse-file-ext = parse-string;


define function parse-symbol-list
   (lines :: <sequence>, name :: <symbol>, header-rest :: false-or(<string>),
    locator :: <function>, valid-strings :: <sequence>)
=> (setting :: <setting>)
   let lines-and-header =
         concatenate(vector(header-rest | ""), copy-sequence(lines, start: 1));
   let value-string =
         replace-elements!(join(lines-and-header, " "), whitespace?, always(' '));
   let symbol-strings = split(value-string, ' ', remove-if-empty?: #t);
   unless (symbol-strings.size > 0)
      error-in-config(location: locator(lines.first),
            config-name: $setting-names[name])
   end unless;
   for (symbol-string in symbol-strings)
      unless (member?(symbol-string, valid-strings, test: string-equal-ic?))
         error-in-config-option(location: locator(lines.first), option: symbol-string,
               config-name: $setting-names[name]);
      end unless
   end for;
   let symbols = map(curry(as, <symbol>), symbol-strings);
   make(<setting>, key: name, value: symbols)
end function;


define function parse-boolean-complement
   (lines :: <sequence>, name :: <symbol>, header-rest :: false-or(<string>),
    locator :: <function>)
=> (setting :: <setting>)
   let value-string = header-rest | element(lines, 1, default: #f);
   let value = select (strip(value-string) by string-equal-ic?)
                  ("yes", "#t", "true") => #t;
                  ("no", "#f", "false") => #f;
                  otherwise =>
                     error-in-config-option(location: locator(lines.first),
                           config-name: $setting-names[name], option: value-string);
               end select;
   make(<setting>, key: name, value: ~value)
end function;


define constant $quote-setting-regex =
      compile-regex("^(\\S+)\\s+(\\S+)\\s+\\[\\s*([a-zA-Z ]+)\\s*\\]$");

define function parse-quote-setting
      (lines :: <sequence>, name :: <symbol>, header-rest :: false-or(<string>),
       locator :: <function>)
=> (setting :: <quote-setting>)
   if (header-rest | lines.size = 1)
      error-in-config(location: locator(lines.first),
            config-name: $setting-names[name])
   end if;
   
   local method check-valid-quote-chars (chars :: <string>, location) => ()
            unless (intersection(chars, $illegal-quote-chars).size = 0)
               error-in-config-option(location: location, option: chars,
                     config-name: $setting-names[name])
            end unless;
         end method,
         
         method check-valid-options (opts :: <sequence>, location) => ()
            if (opts.empty?)
               error-in-config(location: location, config-name: $setting-names[name])
            else
               let invalid = choose(
                     method (opt :: <string>)
                        ~member?(opt, $valid-quote-options, test: string-equal-ic?)
                     end, opts);
               unless (invalid.empty?)
                  error-in-config-option(location: location,
                        option: join(invalid, " "),
                        config-name: $setting-names[name])
               end unless
            end if
         end method,
         
         method parse-line-values (line :: <string>) => (vals :: <sequence>)
            let (match, start-chars, end-chars, options-string) =
                  regex-search-strings($quote-setting-regex, line);
            let options = options-string &
                  split(options-string, ' ', remove-if-empty?: #t);
            unless (start-chars & end-chars & options)
               error-in-config(location: locator(line),
                     config-name: $setting-names[name])
            end unless;
            let location = locator(line);
            check-valid-quote-chars(start-chars, location);
            check-valid-quote-chars(end-chars, location);
            check-valid-options(options, location);
            vector(start-chars, end-chars, map(curry(as, <symbol>), options))
         end method;
         
   let line-values = map(parse-line-values, copy-sequence(lines, start: 1));
   let quote-pairs = make(<stretchy-vector>);
   let quote-specs = make(<string-table>);
   for (triple :: <sequence> in line-values)
      add!(quote-pairs, vector(triple.first, triple.second));
      quote-specs[triple.first] := triple.third;
   end for;
   make(<quote-setting>, location: locator(lines.first),
         key: name, value: quote-specs, quote-pairs: quote-pairs)
end function;


define constant $section-style-regex =
      compile-regex("^'(\\S)'\\s+(\\w+)(?:,\\s*(\\w+))?(?:,\\s*(\\w+))?$");

define function parse-title-style
      (lines :: <sequence>, name :: <symbol>, header-rest :: false-or(<string>),
       locator :: <function>)
   let value-string = header-rest | element(lines, 1, default: #f);
   let (match, char-str, pos-1, pos-2, pos-3) =
         regex-search-strings($section-style-regex, value-string);
   unless (match & char-str & pos-1)
      error-in-config(location: locator(lines.first), 
            config-name: $setting-names[name])
   end unless;
   
   let line-positions = choose(true?, vector(pos-1, pos-2, pos-3));
   let invalid-positions = choose(
         method (s :: <string>)
            ~member?(s, $valid-line-positions, test: string-equal-ic?) & s
         end, line-positions);
   unless (invalid-positions.empty?)
      error-in-config-option(location: locator(lines.first),
            option: invalid-positions.item-string-list,
            config-name: $setting-names[name])
   end unless;

   let section-style = make(<topic-level-style>,
         char: char-str.first,
         over: member?("above", line-positions, test: string-equal-ic?),
         under: member?("below", line-positions, test: string-equal-ic?),
         mid: member?("sides", line-positions, test: string-equal-ic?));
   make(<setting>, key: name, value: section-style)
end function;
