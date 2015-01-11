module parser_combinator.memo;

import parser_combinator.parsing_result;

struct MemoEntry
{
    ParsingResult parsingResult;
    bool isCalled;
}

alias Memo = MemoEntry[string][size_t];
