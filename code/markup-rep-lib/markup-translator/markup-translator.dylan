module: markup-translator

define thread variable *internal-markup* :: <boolean> = #f;
define thread variable *title-markup* :: <boolean> = #f;
define thread variable *catalog-topics* :: <boolean> = #f;
define thread variable *topic-level-styles* :: <stretchy-vector> = make(<stretchy-vector>);
define thread variable *topic-level-topics* :: <stretchy-vector> = make(<stretchy-vector>);

/** Synopsis: Returns <topic>s from a markup block. **/
define method topics-from-markup
   (token :: <markup-content-token>, context-topic :: false-or(<topic>),
    #key internal :: <boolean> = #f, catalog :: <boolean> = #f)
=> (result :: <sequence>)
   let topics = make(<stretchy-vector>);
   let header-styles = make(<stretchy-vector>);
   let header-topics = make(<stretchy-vector>);
   
   dynamic-bind (*internal-markup* = internal, *catalog-topics* = catalog,
          *topic-level-styles* = header-styles, *topic-level-topics* = header-topics)
      unless (token.default-topic-content.empty?)
         if (context-topic)
            // Use context topic as parent for subsequent topics in block.
            header-styles[0] := #f;
            header-topics[0] := context-topic;
            
            process-tokens(context-topic, token.default-topic-content);
            add!(topics, context-topic);
         else
            let content = token.default-topic-content;
            let loc = merge-file-source-locations
                  (content.first.token-src-loc, content.last.token-src-loc);
            no-context-topic-in-block(location: loc);
         end if;
      end unless;

      topics := concatenate(topics, map(make-topic-from-token, token.token-topics));
   
      // Resolve markers, exhibits, and footnotes. The scope of the numeric
      // identifier of a line marker, exhibit, or footnote number in any topic
      // or section of the markup is isolated to 'token'; this function is the
      // highest point at which they can be properly resolved.
      resolve-line-markers(topics);
      resolve-exhibits(topics);
      resolve-footnotes(topics);
      
   end dynamic-bind;
   
   topics
end method;


/** Synopsis: Returns a content sequence from a markup block. **/
define method content-from-markup (token :: <markup-content-token>)
=> (result :: <content-seq>)
   // Disallow topics in this markup.
   unless (token.token-topics.empty?)
      let topic-locs = map(token-src-loc, token.token-topics);
      let topic-loc = reduce1(merge-file-source-locations, topic-locs);
      topics-in-nontopic-markup(location: token.token-src-loc,
            topic-locations: topic-loc);
   end unless;

   // Disallow sections, exhibits, and footnotes in this markup.
   let content = token.default-topic-content;
   let invalid-content =
         choose(complement(rcurry(instance?, <division-content-types>)), content);
   unless (invalid-content.empty?)
      let invalid-locs = map(token-src-loc, invalid-content);
      sections-in-nonsection-markup(location: token.token-src-loc,
            section-locations: invalid-locs.item-string-list);
   end unless;
   
   // Process everything else.
   let result = content-seq();
   process-tokens(result, content);
   result
end method;


/**
Generic Function: process-tokens
--------------------------------
Synopsis: Add a token into an intermediate object, merging if necessary.

'Owner' could be the object itself or the value of some slot of the object. We
don't call this method on the content slot of a topic, because 'tokens' may
include things that affect the topic itself, and the topic isn't reachable
from its content slot.

Arguments:
   owner - An intermediate object or content sequence.
   tokens - The token or tokens to process and add to 'owner'.
**/
define generic process-tokens
   (owner :: type-union(<markup-element>, <content-seq>, <markup-seq>,
                        <title-seq>, <topic-content-seq>),
    tokens :: type-union(<token>, <sequence>, singleton(#f)))
=> ();


/** A sequence of tokens is added to <markup-element>s individually. **/
define method process-tokens
   (owner :: type-union(<markup-element>, <content-seq>, <markup-seq>,
                        <title-seq>, <topic-content-seq>),
    tokens :: <sequence>)
=> ()
   do(curry(process-tokens, owner), tokens)
end method;


/** #f is ignored. **/
define method process-tokens
   (owner :: type-union(<markup-element>, <content-seq>, <markup-seq>,
                        <title-seq>, <topic-content-seq>),
    token == #f)
=> ()
end method;

