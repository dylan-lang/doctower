module: dylan-user

define library support-library
   use dylan;
   use common-dylan;
   use collection-extensions;
   use collections, import: { table-extensions };
   use strings;
   use regular-expressions;
   use system;
   use io;
   use sequence-stream;
   use dynamic-binding;
   use skip-list;
   use slot-visitor;
   // from Monday project
   use source-location;

   export common, conditions, ordered-tree, equal-table;
end library;
