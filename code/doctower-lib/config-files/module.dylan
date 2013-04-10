module: dylan-user

define module config-files
   use common;
   use conditions;
   use configs;
   
   // from strings
   use strings, import: { strip, whitespace? };
   // from regular-expressions
   use regular-expressions,
      import: { compile-regex, regex-search-strings };
   // from system
   use locators, import: { locator-as-string };
   
   export
      set-configs-with-files, create-config-file;
end module;
