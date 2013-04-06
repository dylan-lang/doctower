module: dylan-user

define module config-files
   use common;
   use conditions;
   use configs;
   use strings, import: { strip, whitespace? };
   use regular-expressions,
      import: { compile-regex, regex-search-strings };
   
   export
      set-configs-from-files;
end module;
