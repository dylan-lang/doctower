module: markup-translator


define method resolve-line-markers (topics :: <sequence>) => ()
   let line-marker-catalog = make(<stretchy-vector>);
   visit-targets(topics, 
         method (marker :: <line-marker>, #key, #all-keys) 
         => (slots? :: <boolean>)
            add!(line-marker-catalog, marker);
            #f
         end);
         
   visit-markup-references(topics, 
         method (ref :: <line-marker-placeholder>, #key setter, #all-keys)
         => (slots? :: <boolean>)
            let target = target-with-index(ref, line-marker-catalog);
            if (target)
               setter(target)
            else
               no-target-for-indexed-reference(location: ref.source-location,
                     reference-type: "line marker", reference-index: ref.index)
            end if;
            #f
         end);
end method;


define method resolve-exhibits (topics :: <sequence>) => ()
   let exhibit-catalog = make(<stretchy-vector>);
   visit-targets(topics,
         method (exhibit :: <exhibit>, #key, #all-keys) 
         => (slots? :: <boolean>)
            add!(exhibit-catalog, exhibit);
            #f
         end);
         
   visit-markup-references(topics,
         method (ref :: <exhibit-placeholder>, #key setter, #all-keys)
         => (slots? :: <boolean>)
            let target = target-with-index(ref, exhibit-catalog);
            if (target)
               setter(target)
            else
               no-target-for-indexed-reference(location: ref.source-location,
                     reference-type: "exhibit", reference-index: ref.index)
            end if;
            #f
         end);
end method;


define method resolve-footnotes (topics :: <sequence>) => ()
   let footnote-catalog = make(<stretchy-vector>);
   let footnotes-by-topic = make(<object-table>, size: topics.size);
   for (topic in topics)
      footnotes-by-topic[topic] := make(<stretchy-vector>);
      visit-targets(topic,
            method (footnote :: <footnote>, #key, #all-keys)
            => (slots? :: <boolean>)
               add!(footnote-catalog, footnote);
               add!(footnotes-by-topic[topic], footnote);
               #f
            end);
   end for;
   
   for (topic in topics)
      visit-markup-references(topic,
            method (ref :: <footnote-placeholder>, #key setter, #all-keys)
            => (slots? :: <boolean>)
               let target = find-element(footnote-catalog,
                     method (target) => (match? :: <boolean>)
                        target.index = ref.index
                     end);
               if (target & member?(target, footnotes-by-topic[topic]))
                  setter(target)
               elseif (target)
                  footnote-referenced-outside-topic(location: ref.source-location,
                        reference-index: ref.index)
               else
                  no-target-for-indexed-reference(location: ref.source-location,
                        reference-type: "footnote", reference-index: ref.index)
               end if;
               #f
            end);
   end for;
end method;


define method target-with-index (ref, target-list) => ()
   find-element(target-list,
         method (target) => (match? :: <boolean>)
            target.index = ref.index
         end);
end method
