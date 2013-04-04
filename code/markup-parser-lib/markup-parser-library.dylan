module: dylan-user

define library markup-parser-library
   use support-library;
   use midsupport-library, import: { parser-common, configs };
   use peg-parser;
   use strings;
   use wrapper-streams;
   use regular-expressions;

   export markup-parser;
end library;