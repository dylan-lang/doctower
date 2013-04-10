module: dylan-user

define module main
   use common;
   use conditions;
   use configs;
   use config-files;
   use markup-parser, import: { *parser-trace* };
   use template-files;
   use source-files;
   use dylan-topics, import: { $topic-templates };
   use topic-resolver;
   use output;
   use ordered-tree;
   
   // from io
   use format-out;
   use print;
   use pprint, import: { *default-line-length* };
   // from command-line-parser
   use command-line-parser;
   use option-parser-protocol, import: { option-present? };
   // from system
   use locators, import: { locator-extension };
   use file-system, import: { file-exists? };
end module;
