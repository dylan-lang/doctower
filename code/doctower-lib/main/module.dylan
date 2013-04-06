module: dylan-user

define module main
   use common;
   use conditions;
   use configs;
   use config-files;
   use tasks;
   use markup-parser, import: { *parser-trace* };
   
   // from io
   use format-out;
   use print;
   use pprint, import: { *default-line-length* };
   // from command-line-parser
   use command-line-parser;
   // from system
   use locators, import: { locator-extension };
end module;
