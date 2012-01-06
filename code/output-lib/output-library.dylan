module: dylan-user

define library output-library
   use support-library;
   use midsupport-library;
   use markup-rep-library;
   use template-engine;
   use system;
   use dylan, import: { transcendental };
   use string-extensions;
   export output;
end library;
