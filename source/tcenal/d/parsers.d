module tcenal.d.parsers;

import tcenal.dsl.generate_parsers : generateParsers;

mixin(generateParsers(import("drules.peg")));
