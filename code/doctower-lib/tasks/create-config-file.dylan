module: tasks


define method create-config-file (filename :: <string>) => ()
   let new-file-locator = as(<file-locator>, filename);
   with-open-file (file = new-file-locator, direction: #"output")
      format(file, $default-config-file);
   end with-open-file
end method;


// TODO: Include actual config defaults in the generated config file.
// TODO: Do my parsing here.


define constant $default-config-file =
        "# Quote pairs cannot include ( ) or [ ]."
      "\n"
      "\nQuotes:"
      "\n' ' - [qv]"
      "\n\" \" - [qq]"
      "\n` ` - [code]"
      "\n"
      "\nList quotes:"
      "\n' ' - [q]"
      "\n\" \" - [qq]"
      "\n` ` - [code]"
      "\n"
      "\nSection markup:"
      "\n'-' on sides"
      "\n"
      "\nTab size: 8"
      "\n"
      "\n#"
      "\n# Other configs - one line"
      "\n#"
      "\n"
      "\nPackage title:"
      "\nHTML stylesheet:"
      "\nTopic templates:"
      "\n"
      "\n#"
      "\n# Other configs - multiple lines"
      "\n#"
      "\n"
      "\nContents:"
      "\n# List of titles or tags with hyphens indicating depth, e.g."
      "\n# - Introduction"
      "\n# -- About Us"
      "\n# - api_ref"
      "\n";
