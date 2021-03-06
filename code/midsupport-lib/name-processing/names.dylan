module: name-processing


/// Synopsis: Removes spaces and makes titlecase.
define function standardize-qualified-name (name :: <string>) => (name :: <string>)
   choose(curry(\~=, ' '), name.as-titlecase);
end function;


/// Synopsis: Makes titlecase.
define function standardize-presentation-name (name :: <string>) => (name :: <string>)
   name.as-titlecase
end function;


/// Synopsis: Ensures legal characters in IDs.
define function standardize-id (id :: <string>) => (id :: <string>)
   replace-elements!(id, curry(\=, '/'), always('.'));
end function;


define constant $consec-space-regex = compile-regex(" {2,}");
define constant $spaced-comma-regex = compile-regex(" ?, ?([^ ])");
define constant $spaced-parens-regex = compile-regex(" ?([.\\(\\)\\[\\]]) ?");

/// Synopsis: Fixes spaces and makes titlecase in API titles.
define function standardize-title (title :: <string>) => (title :: <string>)
   title := as-titlecase(title);
   title := regex-replace(title, $consec-space-regex, " ");
   title := regex-replace(title, $spaced-comma-regex, ", \\1");
   title := regex-replace(title, $spaced-parens-regex, "\\1");
end function;


define function as-titlecase (str :: <string>) => (str :: <string>)
   let cased-str = str.copy-sequence;
   let should-cap? :: <boolean> = #t;
   for (c keyed-by i in cased-str)
      case
         c.alphabetic? =>
            when (should-cap?)
               cased-str[i] := c.as-uppercase;
               should-cap? := #f
            end when;
         member?(c, "!&*<=>|^$%@_-+~?/0123456789") =>
            #f;
         otherwise =>
            should-cap? := #t;
      end case
   end for;
   cased-str
end function;


/// Synopsis: Finds higher qualified name.
/// Value:
///   name - Higher qualified name (a <string>) as follows:
///            + "" for a library
///            + Library name for a module
///            + Module name for a binding
///            + Generic name for a method
define function enclosing-qualified-name (name :: <string>) => (name :: <string>)
   let paren-key = find-key(name, curry(\=, '(') /*)*/);
   if (paren-key)
      copy-sequence(name, end: paren-key)
   else
      let last-colon-key = find-last-key(name, curry(\=, ':'));
      if (last-colon-key)
         copy-sequence(name, end: last-colon-key)
      else
         ""
      end if
   end if
end function;


/// Synopsis: Returns the ID form of a qualified name.
define function qualified-name-as-id (name :: <string>) => (id :: <string>)
   format-to-string("::%s", name).standardize-id
end function;


/// Synopsis: Returns the short ID form of a qualified name.
define function short-qualified-name-as-id (name :: <string>) => (id :: <string>)
   format-to-string(":::%s", name).standardize-id
end function;
