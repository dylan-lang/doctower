module: dylan-user

define library output-library
   use support-library;
   use midsupport-library;
   use markup-rep-library;
   use template-engine;
   use system;
   use common-dylan, import: { transcendentals };
   use strings;
   export output;
end library;
