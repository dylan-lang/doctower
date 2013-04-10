module: config-files
synopsis: Outputs the default configuration to a .cfg file, with comments.


define constant $file-structure = #[
   "# This file contains a copy of Doctower's default configuration. You may edit it\n"
   "# as you like and include it in the package's files to change Doctower's\n"
   "# configuration.\n"
   "#\n" 
   "# Setting names and values are case insensitive. Most setting values may appear\n"
   "# on the same line as the setting name or on the next line, but some complex\n"
   "# values may only appear on the next line. Lines starting with \"#\" are ignored.\n",
   
   "############################\n"
   "#  DOCUMENTATION SETTINGS  #\n"
   "############################\n",
   
   #"package-title",
   #"output-types",
   #"contents-file-extension",
   #"topic-file-extension",
   #"output-directory",
   #"template-directory",
   #"api-list-file",

   "#####################################\n"
   "#  SOURCE CODE AND MARKUP SETTINGS  #\n"
   "#####################################\n",
   
   #"scan-only?",
   #"quote-specs",
   #"bullet-chars",
   #"ascii-line-chars",
   #"section-style"
];


define table $setting-descriptions = {
   #"api-list-file" =>
      "# Generates a file with the given filename that contains all scanned Dylan names\n"
      "# and where they were defined. [--names]\n",
      
   #"ascii-line-chars" =>
      "# Line characters comprise the ASCII art surrounding topics and section headings.\n",
      
   #"bullet-chars" =>
      "# Bullet characters may be used to indicate bulleted items. All are equivalent.\n",
      
   #"contents-file-extension" =>
      "# File extension of table-of-contents files. [--toc]\n"
      "#\n"
      "# A table-of-contents file consists of a list of titles or tags with hyphens\n"
      "# indicating depth, e.g.\n"
      "#\n"
      "#   - Introduction\n"
      "#   -- About Us\n"
      "#   - api_ref\n",
      
   #"output-directory" =>
      "# Directory in which to place generated documentation files, relative to the\n"
      "# current directory. [--output-dir]\n",
      
   #"output-types" =>
      "# The doc formats to build. Options are \"html\" and/or \"dita\". [--format]\n"
      "#\n"
      "# Example:\n"
      "#\n"
      "#  Doc formats: html dita\n",
      
   #"package-title" =>
      "# The title displayed in the title bar. [--title]\n",

   #"quote-specs" =>
      format-to-string(
      "# Quote pairs cannot include %s. Options may include one or more of:\n"
      "#   %s\n",
      $illegal-quote-chars, $valid-quote-options.item-string-list),
      
   #"scan-only?" =>
      "# Set to \"true\", \"#t\", or \"yes\" to ignore doc comments in Dylan source code.\n"
      "# [--no-comment]\n"
      "#\n"
      "# Doc comments are in the style \"/** .... */\" or \"/// ...\".\n",

   #"section-style" =>
      "# Section markup indicates the style of ASCII art that surrounds section\n"
      "# headings. Other styles of ASCII art indicate topic headings.\n"
      "#\n"
      "# The syntax for this setting is:\n"
      "#\n"
      "#   'c' above, below, sides\n"
      "#\n"
      "# where \"c\" is the line character and \"above\", \"below\", and \"sides\" indicate\n"
      "# where the ASCII art lines must be placed.\n"
      "#\n"
      "# Examples:\n"
      "#\n"
      "#   '+'  above, sides\n"
      "#\n"
      "# would treat the following markup as a section heading:\n"
      "#\n"
      "#   ++++++++++++++++++\n"
      "#   +++ My Section +++\n",
   
   #"template-directory" =>
      "# Directory containing topic templates, HTML and DITA file templates, and CSS\n"
      "# files, relative to the current directory. [--templates]\n",
      
   #"topic-file-extension" =>
      "# File extension of topic files containing Doctower markup. [--doc]\n"
};


define method create-config-file (filename :: <string>) => ()
   let new-file-locator = as(<file-locator>, filename);
   with-open-file (file = new-file-locator, direction: #"output")
      let parts = map(format-part, $file-structure);
      write(file, join(parts, "\n\n"));
   end with-open-file
end method;


define method format-part (string :: <string>) => (string :: <string>)
   string
end method;

define method format-part (config-name :: <symbol>) => (string :: <string>)
   let setting-value :: <string> =
         select (config-name)
            #"api-list-file" =>           if (*api-list-file*)
                                             format-filename(*api-list-file*);
                                          else
                                             ""
                                          end if;
            #"ascii-line-chars" =>        format-char-list(*ascii-line-chars*);
            #"bullet-chars" =>            format-char-list(*bullet-chars*);
            #"contents-file-extension" => format-file-ext(*contents-file-extension*);
            #"output-directory" =>        format-directory(*output-directory*);
            #"output-types" =>            format-symbol-list(*output-types*);
            #"package-title" =>           format-string(*package-title*);
            #"quote-specs" =>             format-quote-setting(*quote-specs*, *quote-pairs*);
            #"scan-only?" =>              format-boolean-complement(*scan-only?*);
            #"section-style" =>           format-title-style(*section-style*);
            #"template-directory" =>      format-directory(*template-directory*);
            #"topic-file-extension" =>    format-file-ext(*topic-file-extension*);
         end select;
   format-to-string("%s\n%s:\n%s", $setting-descriptions[config-name],
         $setting-names[config-name], setting-value)
end method;


define function format-filename (filename :: <file-locator>)
=> (output :: <string>)
   format-to-string("%s\n", locator-as-string(<string>, filename))
end function;

define function format-directory (directory :: <directory-locator>)
=> (output :: <string>)
   format-to-string("%s\n", locator-as-string(<string>, directory))
end function;

define function format-symbol-list (symbol-list :: <sequence>)
=> (output :: <string>)
   format-to-string("%s\n", join(map(curry(as, <string>), symbol-list), " "))
end function;

define function format-boolean-complement (bool :: <boolean>)
=> (output :: <string>)
   format-to-string("%s\n", if (bool) "no" else "yes" end)
end function;

define function format-string (string :: <string>)
=> (output :: <string>)
   format-to-string("%s\n", string)
end function;

define constant format-file-ext = format-string;
define constant format-char-list = format-string;

define function format-quote-setting (specs :: <string-table>, pairs :: <sequence>)
=> (output :: <string>)
   let lines = map(
         method (quote-pair :: <sequence>) => (line :: <string>)
            let spec-list = element(specs, quote-pair.first, default: #["unq"]);
            let spec-str = join(map(curry(as, <string>), spec-list), " ");
            format-to-string("%s %s\t[%s]\n", quote-pair.first, quote-pair.second,
                  spec-str)
          end method, pairs);
    reduce(concatenate!, "", lines)
end function;

define function format-title-style (style :: <topic-level-style>)
=> (output :: <string>)
   let pos-strs = make(<stretchy-vector>);
   if (style.overline?) add!(pos-strs, "above") end;
   if (style.underline?) add!(pos-strs, "below") end;
   if (style.midline?) add!(pos-strs, "sides") end;
   format-to-string("'%c'\t%s\n", style.line-character, pos-strs.item-string-list)
end function;
