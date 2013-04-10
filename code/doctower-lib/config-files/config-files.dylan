module: config-files
synopsis: Processes .cfg files and declares information about configs.


define table $setting-names = {
   #"api-list-file" =>           "API names list",
   #"ascii-line-chars" =>        "Line characters",
   #"bullet-chars" =>            "Bullet characters",
   #"contents-file-extension" => "TOC file extension",
   #"output-directory" =>        "Output directory",
   #"output-types" =>            "Doc formats",
   #"package-title" =>           "Documentation title",
   #"quote-pairs" =>             "Quote pairs",    // Unused, except for diagnostics.
   #"quote-specs" =>             "Quotes",
   #"scan-only?" =>              "Ignore doc comments",
   #"section-style" =>           "Section markup",
   #"template-directory" =>      "Template directory",
   #"topic-file-extension" =>    "Topic file extension"
};


/**
There can be multiple config files, but to prevent surprising precedence issues,
they cannot set overlapping configs.
**/
define function set-configs-with-files (files :: <sequence>) => ()
   unless (files.empty?)
      verbose-log("Reading config files");
   end unless;

   let settings = reduce(concatenate, #[], map(config-file-settings, files));
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
   let quote-setting :: false-or(<quote-setting>) =
         any?(method (s) if (s.key = #"quote-specs") s end if end method, settings);
   if (quote-setting)
      let quote-pairs-setting = make(<setting>, key: #"quote-pairs",
            source-location: quote-setting.source-location,
            value: quote-setting.quote-pairs);
      settings := add!(settings, quote-pairs-setting);
   end if;
   
   // Activate settings.
   
   do(set-config, settings);
   
   // Check consistency.
   
   unless (member?(*section-style*.line-character, *ascii-line-chars*))
      illegal-character-in-section-style(header-chars: *ascii-line-chars*,
            section-header-char: *section-style*.line-character)
   end unless;
end function;


define class <setting> (<source-location-mixin>)
   constant slot key :: <symbol>, required-init-keyword: #"key";
   constant slot value :: <object>, required-init-keyword: #"value";
end class;

define class <quote-setting> (<setting>)
   constant slot quote-pairs :: <sequence>, required-init-keyword: #"quote-pairs";
end class;


define function set-config (setting :: <setting>) => ()
   select (setting.key)
      #"api-list-file" =>           *api-list-file* :=            setting.value;
      #"ascii-line-chars" =>        *ascii-line-chars* :=         setting.value;
      #"bullet-chars" =>            *bullet-chars* :=             setting.value;
      #"contents-file-extension" => *contents-file-extension* :=  setting.value;
      #"output-directory" =>        *output-directory* :=         setting.value;
      #"output-types" =>            *output-types* :=             setting.value;
      #"package-title" =>           *package-title* :=            setting.value;
      #"quote-pairs" =>             *quote-pairs* :=              setting.value;
      #"quote-specs" =>             *quote-specs* :=              setting.value;
      #"scan-only?" =>              *scan-only?* :=               setting.value;
      #"section-style" =>           *section-style* :=            setting.value;
      #"template-directory" =>      *template-directory* :=       setting.value;
      #"topic-file-extension" =>    *topic-file-extension* :=     setting.value;
   end select;
end function;


define function config-file-settings (file :: <file-locator>)
=> (settings :: <sequence>)
   with-open-file (s = file)
      let lines = map(strip, read-lines-to-end(s));
      let noncomment-lines =
            choose(method (line) line.empty? | line.first ~= '#' end, lines);
      let config-blocks = split-on-empty-lines(noncomment-lines);

      local method line-location (line :: <string>) => (loc :: <file-source-location>)
               let line-num = find-key(lines, curry(\==, line)) + 1;
               make(<file-source-location>, file: file,
                    start-line: line-num, end-line: line-num)
            end;

      let settings = make(<stretchy-vector>);
      for (config-block in config-blocks)
         block()
            add!(settings, config-block-setting(config-block, line-location))
         exception (<skip-error-restart>)
         end block
      end for;
      choose(true?, settings)
   end with-open-file;
end function;

define function split-on-empty-lines (lines :: <sequence> /* of <string> */)
=> (blocks :: <sequence> /* of <sequence> of <string> */)
   // Can't get this to work right with the split method, so I'll do my own.
   // Turns out this is hella easier anyway.
   let blocks = make(<stretchy-vector>);
   let partial-block = make(<stretchy-vector>);
   for (line in lines)
      if (line.empty?)
         add!(blocks, partial-block);
         partial-block := make(<stretchy-vector>);
      else
         add!(partial-block, line);
      end if
   finally
      add!(blocks, partial-block);
   end for;
   choose(complement(empty?), blocks)
end function;


define function config-block-setting (lines :: <sequence>, locator :: <function>)
=> (setting :: false-or(<setting>))
   let (config-name, first-line-rest) = config-block-header(lines.first, locator);
   if (config-name)
      let key = find-key($setting-names, curry(string-equal-ic?, config-name));
      if (key)
         if (first-line-rest | lines.size > 1)
            let parser = $setting-parsers[key];
            parser(lines, key, first-line-rest, locator)
         end if;
      else
         unknown-config-in-cfg-file(location: locator(lines.first),
               config-name: config-name);
      end if;
   else
      error-in-config(location: locator(lines.first),
            config-name: lines.first)
   end if;
end function;


define constant $header-regex = compile-regex("^([\\w ]+):(.*)?$");

define function config-block-header (line :: <string>, locator :: <function>)
=> (header :: false-or(<string>), rest :: false-or(<string>))
   let (match, header, rest) = regex-search-strings($header-regex, line);
   values (header, rest & strip(rest))
end function;
