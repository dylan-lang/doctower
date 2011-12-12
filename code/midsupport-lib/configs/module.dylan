module: dylan-user

define module configs
   use common;
   
   export
      *api-list-file*, *topic-file-extension*, *contents-file-extension*,
      *config-file-extension*, *package-title*, *output-directory*,
      *output-types*, *template-directory*, *debug-features*, *scan-only?*;
   
   export
      debugging?;
      
   export
      *ascii-line-chars*, *bullet-chars*, *quote-chars*, *markup-quote-specs*,
      *list-quote-specs*, *title-quote-specs*, *section-style*, $tab-size,
      $debug-features;

   export
      <topic-level-style>, line-character, underline?, midline?, overline?;

end module;
