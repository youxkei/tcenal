module tcenal.parser_combinator.memo;

import tcenal.parser_combinator.parsing_result;

struct MemoEntry
{
    ParsingResult parsingResult;
    bool isCalled;
}

alias Memo = MemoEntry[string][size_t];
