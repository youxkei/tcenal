module tcenal.d.parsers;


import std.ascii : isWhite, isDigit, isAlpha, isAlphaNum;

import tcenal.parser_combinator.token : Token;
import tcenal.parser_combinator.combinators;
import tcenal.parser_combinator.memo;
import tcenal.parser_combinator.parsing_result;
import tcenal.dsl.generate_parsers : generateParsers;
import tcenal.rule_selector : createRuleSelector;

mixin(generateParsers(import("drules.peg")));
