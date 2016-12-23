module tcenal.parser_combinator.util;

import tcenal.parser_combinator.token : Token;
import tcenal.parser_combinator.memo : Memo;
import tcenal.parser_combinator.parsing_result : ParsingResult;

ParsingResult parseWithoutMemo(alias parser)(Token[] input)
{
    Memo memo;
    return parser(input, 0, memo);
}
