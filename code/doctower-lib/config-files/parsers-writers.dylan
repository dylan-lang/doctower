module: config-files


define function parse-filename
   (lines :: <sequence>, name :: <symbol>, header-rest :: false-or(<string>),
    locator :: <function>)
=> (setting :: <setting>)
   let value-string = header-rest | element(lines, 1, default: #f);
   unless (value-string)
      error-in-config(location: locator(lines.first), config-name: name)
   end unless;
   let value = as(<file-locator>, strip(value-string));
   make(<setting>, key: name, value: value)
end function;


define function parse-directory
   (lines :: <sequence>, name :: <symbol>, header-rest :: false-or(<string>),
    locator :: <function>)
=> (setting :: <setting>)
   let value-string = header-rest | element(lines, 1, default: #f);
   unless (value-string)
      error-in-config(location: locator(lines.first), config-name: name)
   end unless;
   let value = as(<directory-locator>, strip(value-string));
   make(<setting>, key: name, value: value)
end function;


define function parse-string
   (lines :: <sequence>, name :: <symbol>, header-rest :: false-or(<string>),
    locator :: <function>)
=> (setting :: <setting>)
   let value-string = header-rest | element(lines, 1, default: #f);
   unless (value-string)
      error-in-config(location: locator(lines.first), config-name: name)
   end unless;
   make(<setting>, key: name, value: strip(value-string))
end function;

define constant parse-char-list = parse-string;
define constant parse-file-ext = parse-string;


define function parse-symbol-list
   (lines :: <sequence>, name :: <symbol>, header-rest :: false-or(<string>),
    locator :: <function>)
=> (setting :: <setting>)
   let lines-and-header =
         concatenate(vector(header-rest | ""), copy-sequence(lines, start: 1));
   let value-string =
         replace-elements!(join(lines-and-header, " "), whitespace?, always(' '));
   let symbol-strings = split(value-string, ' ', remove-if-empty?: #t);
   unless (symbol-strings.size > 0)
      error-in-config(location: locator(lines.first), config-name: name)
   end unless;
   let symbols = map(curry(as, <symbol>), symbol-strings);
   make(<setting>, key: name, value: symbols)
end function;


define function parse-boolean-complement
   (lines :: <sequence>, name :: <symbol>, header-rest :: false-or(<string>),
    locator :: <function>)
=> (setting :: <setting>)
   let value-string = header-rest | element(lines, 1, default: #f);
   unless (value-string)
      error-in-config(location: locator(lines.first), config-name: name)
   end unless;
   let value = select (strip(value-string) by string-equal-ic?)
                  ("yes", "#t", "true") => #t;
                  ("no", "#f", "false") => #f;
                  otherwise =>
                     error-in-config
                           (location: locator(lines.first), config-name: name);
               end select;
   make(<setting>, key: name, value: ~value)
end function;


// TODO: parse-quote-setting
define function parse-quote-setting
      (lines :: <sequence>, name :: <symbol>, header-rest :: false-or(<string>),
       locator :: <function>)
   #f
end function;

// TODO: parse-title-style
define function parse-title-style
      (lines :: <sequence>, name :: <symbol>, header-rest :: false-or(<string>),
       locator :: <function>)
   #f
end function;
