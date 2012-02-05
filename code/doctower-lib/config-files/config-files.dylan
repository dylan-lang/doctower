module: config-files


/**
There can be multiple config files, but to prevent surprising precedence issues,
they cannot set overlapping configs.
**/
define function set-configs-from-files (files :: <sequence>) => ()
   let settings = reduce1(concatenate, map(config-file-settings, files));
   let settings-by-key = group-elements(settings,
         test: method (s1, s2) s1.key = s2.key end);
   let (single-settings, duplicate-settings) = 
         partition(method (sl :: <sequence>) sl.size = 1 end, settings-by-key);

   // Check for duplicates.
   
   for (group in duplicate-settings)
      block ()
         let setting = group.first;
         let locs = map(source-location, group).item-string-list;
         duplicate-configs-in-cfg-files(location: setting.source-location,
               config-name: $setting-names[setting.key], config-locations: locs);
      exception (<skip-error-restart>)
      end block
   end for;
   
   // Simplify settings and deal with quote configs.
   
   let settings = map(first, single-settings);
   let quote-setting-keys = #[ #"list-quote-specs", #"markup-quote-specs", #"title-quote-specs" ];
   let quote-settings = choose(method (s) member?(s.key, quote-setting-keys) end,
                               settings);
   let quote-chars-setting = make(<setting>,
         source-location: $generated-source-location,
         key: #"quote-chars", name: "collected quote pairs",
         value: reduce1(union, map(quote-pairs, quote-settings)));
   settings := add!(settings, quote-chars-setting);
   
   // Activate settings.
   
   do(set-config, settings)
end function;


define class <setting> (<source-location-mixin>)
   slot key :: <symbol>, init-keyword: #"key";
   slot value :: <object>, init-keyword: #"value";
end class;

define class <quote-setting> (<setting>)
   slot quote-pairs :: <sequence>, init-keyword: #"quotes";
end class;


define function set-config (setting :: <setting>) => ()
   select (setting.key)
      #"api-list-file" =>           *api-list-file* :=            setting.value;
      #"ascii-line-chars" =>        *ascii-line-chars* :=         setting.value;
      #"bullet-chars" =>            *bullet-chars* :=             setting.value;
      #"contents-file-extension" => *contents-file-extension* :=  setting.value;
      #"list-quote-specs" =>        *list-quote-specs* :=         setting.value;
      #"markup-quote-specs" =>      *markup-quote-specs* :=       setting.value;
      #"output-directory" =>        *output-directory* :=         setting.value;
      #"output-types" =>            *output-directory* :=         setting.value;
      #"package-title" =>           *package-title* :=            setting.value;
      #"quote-chars" =>             *quote-chars* :=              setting.value;
      #"scan-only?" =>              *scan-only?* :=               setting.value;
      #"section-style" =>           *section-style* :=            setting.value;
      #"template-directory" =>      *template-directory* :=       setting.value;
      #"title-quote-specs" =>       *title-quote-specs* :=        setting.value;
      #"topic-file-extension" =>    *topic-file-extension* :=     setting.value;
   end select
end function;


define table $setting-names = {
   #"api-list-file" =>           "API names list",
   #"ascii-line-chars" =>        "Line characters",
   #"bullet-chars" =>            "Bullet characters",
   #"contents-file-extension" => "TOC file extension",
   #"list-quote-specs" =>        "List quotes",
   #"markup-quote-specs" =>      "Quotes",
   #"output-directory" =>        "Output directory",
   #"output-types" =>            "Doc formats",
   #"package-title" =>           "Package title",
   #"quote-chars" =>             "Collected quote pairs",
   #"scan-only?" =>              "Ignore doc comments",
   #"section-style" =>           "Section markup",
   #"template-directory" =>      "Template directory",
   #"title-quote-specs" =>       "Title quotes",
   #"topic-file-extension" =>    "Topic file extension"
};


define table $setting-parsers = {
   #"api-list-file" =>           parse-filename,
   #"ascii-line-chars" =>        parse-char-list,
   #"bullet-chars" =>            parse-char-list,
   #"contents-file-extension" => parse-file-ext,
   #"list-quote-specs" =>        parse-quote-setting,
   #"markup-quote-specs" =>      parse-quote-setting,
   #"output-directory" =>        parse-directory,
   #"output-types" =>            parse-symbol-list,
   #"package-title" =>           parse-string,
   #"quote-chars" =>             #f,
   #"scan-only?" =>              parse-boolean-complement,
   #"section-style" =>           parse-title-style,
   #"template-directory" =>      parse-directory,
   #"title-quote-specs" =>       parse-quote-setting,
   #"topic-file-extension" =>    parse-file-ext
};


define table $setting-writers = {
   #"api-list-file" =>           write-filename,
   #"ascii-line-chars" =>        write-char-list,
   #"bullet-chars" =>            write-char-list,
   #"contents-file-extension" => write-file-ext,
   #"list-quote-specs" =>        write-quote-setting,
   #"markup-quote-specs" =>      write-quote-setting,
   #"output-directory" =>        write-directory,
   #"output-types" =>            write-symbol-list,
   #"package-title" =>           write-string,
   #"quote-chars" =>             #f,
   #"scan-only?" =>              write-boolean-complement,
   #"section-style" =>           write-title-style,
   #"template-directory" =>      write-directory,
   #"title-quote-specs" =>       write-quote-setting,
   #"topic-file-extension" =>    write-file-ext
}
   

define function config-file-settings (file :: <file-locator>)
=> (settings :: <sequence>)
   with-open-file (s = file)
      let lines = map(trim, read-lines-to-end(s));
      let noncomment-lines = choose(method (line) line.first ~= '#' end, lines);
      let config-blocks = split(noncomment-lines,
            method (lines :: <sequence>, start-idx :: <integer>, end-idx :: <integer>)
            => (start-idx, end-idx)
               let k = find-first-key(lines,
                     method (elem) elem = "" end,
                     start: start-idx, end: end-idx);
               values(k, k & (k + 1))
            end,
            remove-if-empty: #t);

      local method line-location (line :: <string>) => (loc :: <file-source-location>)
               let line-num = find-key(lines, curry(\==, line));
               make(<file-source-location>, file: file,
                    start-line: line-num, end-line: line-num)
            end;

      map(rcurry(config-block-setting, line-location), config-blocks)
   end with-open-file;
end function;


define function config-block-setting (lines :: <sequence>, locator :: <function>)
=> (setting :: <setting>)
   let (config-name, first-line-rest) = config-block-header(lines.first);
   let key = find-key($setting-names, curry(case-insensitive-equal?, config-name));
   unless (key)
      unknown-config-in-cfg-file(location: locator(lines.first),
            config-name: config-name);
   end unless;
   let parser = $setting-parsers[key];
   parser(lines, key, first-line-rest, locator)
end function;


define function config-block-header (line :: <string>, locator :: <function>)
=> (header :: false-or(<string>), rest :: false-or(<string>))
   let (match, header, rest) = regexp-matches(line, "^([\\w ]+):(.*)?$");
   values (header, rest)
end function;
