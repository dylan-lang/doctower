module: equal-table
synopsis: Implements <equal-table> like Gwydion Dylan.


// TODO: Get rid of <equal-table> and use bespoke <table> subclasses.


define open generic equal-hash (thing :: <object>, state :: <hash-state>)
   => (id :: <integer>, state :: <hash-state>);

// Uses = as key comparison
//
define sealed class <equal-table> (<table>)
end class <equal-table>;

define sealed domain make (singleton(<equal-table>));
define sealed domain initialize (<equal-table>);

define sealed inline method table-protocol (ht :: <equal-table>) 
=> (key-test :: <function>, key-hash :: <function>);
   values(\=, equal-hash);
end method table-protocol;

// Call object-hash for characters, integers, symbols, classes,
// functions, and conditions.
//
define inline method equal-hash
   (key :: <character>, initial-state :: <hash-state>)
=> (id :: <integer>, state :: <hash-state>);
   object-hash(key, initial-state);
end method equal-hash;

define inline method equal-hash
   (key :: <integer>, initial-state :: <hash-state>)
=> (id :: <integer>, state :: <hash-state>);
   object-hash(key, initial-state);
end method equal-hash;

define inline method equal-hash
   (key :: <symbol>, initial-state :: <hash-state>)
=> (id :: <integer>, state :: <hash-state>);
   object-hash(key, initial-state);
end method equal-hash;

define inline method equal-hash
   (key :: <class>, initial-state :: <hash-state>)
=> (id :: <integer>, state :: <hash-state>);
   object-hash(key, initial-state);
end method equal-hash;

define inline method equal-hash
   (key :: <function>, initial-state :: <hash-state>)
=> (id :: <integer>, state :: <hash-state>);
   object-hash(key, initial-state);
end method equal-hash;

define inline method equal-hash
   (key :: <type>, initial-state :: <hash-state>)
=> (id :: <integer>, state :: <hash-state>);
   object-hash(key, initial-state);
end method equal-hash;

define inline method equal-hash
   (key :: singleton (#f), initial-state :: <hash-state>)
=> (id :: <integer>, state :: <hash-state>);
   object-hash(key, initial-state);
end method equal-hash;

define inline method equal-hash
   (key :: singleton (#t), initial-state :: <hash-state>)
=> (id :: <integer>, state :: <hash-state>);
   object-hash(key, initial-state);
end method equal-hash;

define inline method equal-hash
   (key :: <condition>, initial-state :: <hash-state>)
=> (id :: <integer>, state :: <hash-state>);
   object-hash(key, initial-state);
end method equal-hash;

define inline method equal-hash
   (col :: <collection>, initial-state :: <hash-state>)
=> (id :: <integer>, state :: <hash-state>);
   collection-hash(equal-hash, equal-hash, col, initial-state);
end method equal-hash;
