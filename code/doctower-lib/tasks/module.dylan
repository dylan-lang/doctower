module: dylan-user

/// Synopsis: Controls other modules to read files and generate the internal
/// model of the documentation and output.
define module tasks
   use common;
   use configs,
      import: { *output-types*, *output-directory*, *template-directory*, 
                debugging? };
   use conditions;
   use template-files;
   use source-files;
   use dylan-topics, import: { $topic-templates };
   use topic-resolver;
   use output;
   use ordered-tree;
   // from system
   use file-system, import: { file-exists? };
   
   export
      create-doc-tree, create-output-files, create-config-file;
end module;
