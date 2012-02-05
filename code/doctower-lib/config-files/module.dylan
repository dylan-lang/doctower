module: dylan-user

define module config-files
   use common;
   use conditions;
   use configs;
   use strings, import: { trim };
   use regular-expressions, import: { regexp-matches, split => regexp-split };
   
   export
      set-configs-from-files;
end module;
