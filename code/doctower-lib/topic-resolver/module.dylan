module: dylan-user
synopsis: Merges generated and authored topics and resolves links.

define module topic-resolver
   use common;
   use conditions;
   use markup-rep;
   use ordered-tree;
   use name-processing;
   use regular-expressions, 
      import: { regex-replace, regex-search-strings, compile-regex };
   
   export
      group-mergeable-topics, check-and-merge-topics,
      resolution-info, resolve-target-placeholders,
      arrange-topics, add-catalog-information;
end module;
