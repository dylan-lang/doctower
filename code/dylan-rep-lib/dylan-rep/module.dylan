module: dylan-user
synopsis: Represention of Dylan API elements, at a higher level than what the
          parser provides.

define module dylan-rep
   use common, exclude: { binding-name };

   export
      <api-object>, <documentable-api-object>, <definition>,
      <source-name>, <library-name>, <module-name>, <binding-name>,
      <namespace>, <defined-namespace>, <undefined-namespace>,
      <library>, <defined-library>, <undefined-library>,
      <module>, <defined-module>, <undefined-module>,
      <binding>, <placeholder-binding>, <empty-binding>,
         <class-binding>, <generic-binding>, <function-binding>,
         <constant-binding>, <variable-binding>, <macro-binding>,
      <explicit-class-defn>, <explicit-generic-defn>, <implicit-generic-defn>,
         <explicit-function-defn>, <explicit-constant-defn>, <explicit-variable-defn>,
         <explicit-macro-defn>, <explicit-body-macro-defn>, <explicit-list-macro-defn>,
         <explicit-stmt-macro-defn>, <explicit-func-macro-defn>,
      <slot>, <initable-slot>, <inherited-slot>, <accessor-slot>, <instance-slot>,
         <class-slot>, <subclass-slot>, <virtual-slot>,
      <init-arg>,
      <param-list>, <fixed-param-list>, <key-param-list>, <var-param-list>,
         <req-param>, <key-param>, <rest-param>,
      <value-list>, <req-value>, <rest-value>,
      <sealed-domain>, <vendor-option>,
      <fragment>, <computed-constant>, <type-fragment>, <singleton-type-fragment>,
         <code-fragment>
      ;

   export
      adjectives,
      adjectives-setter,
      aliases,
      aliases-setter,
      all-defns,
      all-keys?,
      all-keys?-setter,
      binding-name,
      canonical-name,
      canonical-name-setter,
      code-fragment,
      definitions,
      definitions-setter,
      direct-supers,
      effective-init-args,
      effective-init-args-setter,
      effective-slots,
      effective-slots-setter,
      effective-subs,
      effective-subs-setter,
      effective-supers,
      effective-supers-setter,
      enclosing-name,
      explicit-defn,
      explicit-defn-setter,
      exported-names,
      exported-names-setter,
      expr,
      expr-setter,
      file-markup-tokens,
      file-markup-tokens-setter,
      fragment-names,
      getter,
      getter-setter,
      implicit-defns,
      implicit-defns-setter,
      init-args,
      init-spec,
      init-spec-setter,
      key-params,
      key-params-setter,
      library-name,
      local-name,
      local-name-setter,
      markup-tokens,
      markup-tokens-setter,
      module-name,
      param-list,
      param-list-setter,
      provenance,
      provenance-setter,
      req-params,
      req-params-setter,
      req-values,
      req-values-setter,
      rest-param,
      rest-param-setter,
      rest-value,
      rest-value-setter,
      sealed-domains,
      sealed-domains-setter,
      sealed-types,
      sealed?,
      sealed?-setter,
      setter,
      setter-setter,
      simple-name?,
      simple-names,
      singleton-expr,
      slots,
      slots-setter,
      source-text,
      symbol,
      type,
      type-setter,
      unknown-reexport-sources,
      unknown-reexport-sources-setter,
      valid-binding?,
      valid-binding?,
      value,
      value-list,
      value-list-setter,
      value-setter,
      vendor-options,
      ;
   
   export
      visit-type-fragments;
end module;
