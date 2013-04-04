module: dylan-user

define library dylan-parser-library
   use support-library;
   use midsupport-library, import: { configs, parser-common };
   use markup-parser-library;
   use peg-parser;
   use strings;
   export dylan-parser;
end library;
