module: dylan-user

define module equal-table
   use common-imports;
   use table-extensions,
      export: { <hash-state>, collection-hash, sequence-hash, string-hash,
                values-hash, case-insensitive-string-hash };
   
   export equal-hash, <equal-table>;
end module;   
