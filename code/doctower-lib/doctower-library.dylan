module: dylan-user

define library doctower-library
   use support-library;
   use midsupport-library;
   use template-engine;
   use strings;
   use dylan-parser-library;
   use markup-parser-library;
   use dylan-rep-library;
   use markup-rep-library;
   use output-library;
   use peg-parser;
   use system;
   use regular-expressions;
   use strings;
   use io;
   use command-line-parser;
   use collection-extensions, import: { vector-search };
   use dylan;
end library;
