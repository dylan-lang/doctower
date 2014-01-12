##################
###  Doctower  ###
##################

Doctower is a documentation generator. It can scan Dylan source files and
automatically generate skeletal documentation and various indices. You can add
more specific documentation to the Dylan source files directly, or write
separate text files and various overview topics as desired.

Markup capabilities include cross-references, verbatim text, images, footnotes,
tables, and very nice organizational tools (including dedicated table of
contents files). The markup is very unobtrusive, following common text-file
conventions where possible.

Doctower can output documentation in DITA XML format or in HTML format, and
can include raw DITA or HTML markup within each topic.


### Development ###

DOCTOWER IS STILL UNDER DEVELOPMENT. Only some of what I said above is true at
the moment. If you want to help (and I can definitely use some), check out the
TODO file and source-code comments, or ask me, |Agent, on IRC.

- I use 3-space tab stops.


### Directories ###

code      - Source code. Aside from "registry" and "ext", each directory is a
            library, and the directories within those are modules.
thoughts  - What passes for design documents. These contain some of my thought
            processes. I also have a notebook, which I cannot really upload.
defaults  - Prototype designs for HTML, CSS, and various generated elements.


### Making ###

cd code
dylan-compiler -build doctower-library
