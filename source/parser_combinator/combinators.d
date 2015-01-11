module parser_combinator.combinators;

import parser_combinator.parsing_result : ParsingResult;
import parser_combinator.parse_tree_node : ParseTreeNode;
import parser_combinator.memo : Memo, MemoEntry;

import compile_time_unittest;

import std.algorithm : startsWith, until;
import std.range : retro;
import std.array : array;
import std.conv : to;

mixin enableCompileTimeUnittest;


ParsingResult toToken(string token)(string input, size_t position, ref Memo memo)
{
    if (token.length <= input[position .. $].length && input[position .. $].startsWith(token))
    {
        ParsingResult parsingResult = ParsingResult(true, position + token.length);
        parsingResult.node.value = token;

        return parsingResult;
    }
    else
    {
        return ParsingResult(false);
    }
}
unittest
{
    Memo memo;

    with (toToken!"foo"("foo", 0, memo))
    {
        assert (success);
        assert (nextPosition == 3);
        assert (node.value == "foo");
    }
}


ParsingResult parseWithMakingRuleNode(alias parser, string ruleName)(string input, size_t position, ref Memo memo)
{
    ParsingResult parsingResult = parser(input, position, memo);

    if (parsingResult.success)
    {
        parsingResult.node = ParseTreeNode("", [parsingResult.node], ruleName);
    }

    return parsingResult;
}
unittest
{
    Memo memo;

    with (parseWithMakingRuleNode!(toToken!"foo", "bar")("foo", 0, memo))
    {
        assert (success);
        assert (nextPosition == 3);
        assert (node.ruleName == "bar");
        assert (node.children[0].value == "foo");
    }
}


ParsingResult applyRule(alias parser, string ruleName = __FUNCTION__)(string input, size_t position, ref Memo memo)
{
    enum simplifiedRuleName = ruleName.retro().until('.').array().retro().to!string();

    if (position in memo)
    {
        if (ruleName in memo[position])
        {
            memo[position][ruleName].isCalled = true;
            return memo[position][ruleName].parsingResult;
        }
    }

    memo[position][ruleName] = MemoEntry();
    ParsingResult parsingResult = parseWithMakingRuleNode!(parser, simplifiedRuleName)(input, position, memo);

    if (!parsingResult.success)
    {
        return parsingResult;
    }

    memo[position][ruleName].parsingResult = parsingResult;

    if (!memo[position][ruleName].isCalled)
    {
        return parsingResult;
    }

    while (true)
    {
        size_t previousNextPosition = parsingResult.nextPosition;

        parsingResult = parseWithMakingRuleNode!(parser, simplifiedRuleName)(input, position, memo);

        if (!parsingResult.success)
        {
            assert(false);
        }

        if (parsingResult.nextPosition <= previousNextPosition)
        {
            break;
        }

        memo[position][ruleName].parsingResult = parsingResult;
    }

    return memo[position][ruleName].parsingResult;
}
unittest
{
    Memo memo;

    with (applyRule!(toToken!"foo", "parseFoo")("foo", 0, memo))
    {
        assert (success);
        assert (nextPosition == 3);
        assert (node.ruleName == "parseFoo");
        assert (node.children[0].value == "foo");
    }

    with (memo[0]["parseFoo"])
    {
        assert (parsingResult.success);
        assert (parsingResult.nextPosition == 3);
        assert (parsingResult.node.ruleName == "parseFoo");
        assert (parsingResult.node.children[0].value == "foo");
        assert (!isCalled);
    }

    static ParsingResult ruleForTest(string input, size_t position, ref Memo memo)
    {
        return applyRule!(
            choice!(
                sequence!(ruleForTest, toToken!"+", toToken!"1"),
                toToken!"1"
            ),
            "ruleForTest"
        )(input, position, memo);
    }

    with (ruleForTest("1", 0, memo))
    {
        assert (success);
        assert (nextPosition == 1);
        assert (node.ruleName == "ruleForTest");
        assert (node.children[0].value == "1");
    }

    memo = memo.init;

    with (ruleForTest("1+1", 0, memo))
    {
        assert (success);
        assert (nextPosition == 3);
        assert (node.ruleName == "ruleForTest");
        assert (node.children[0].children[0].ruleName == "ruleForTest");
        assert (node.children[0].children[0].children[0].value == "1");
        assert (node.children[0].children[1].value == "+");
        assert (node.children[0].children[2].value == "1");
    }

    memo = memo.init;

    with (ruleForTest("1+1+1", 0, memo))
    {
        assert (success);
        assert (nextPosition == 5);
        assert (node.ruleName == "ruleForTest");
        assert (node.children[0].children[0].ruleName == "ruleForTest");
        assert (node.children[0].children[0].children[0].children[0].ruleName == "ruleForTest");
        assert (node.children[0].children[0].children[0].children[0].children[0].value == "1");
        assert (node.children[0].children[0].children[0].children[1].value == "+");
        assert (node.children[0].children[0].children[0].children[2].value == "1");
        assert (node.children[0].children[1].value == "+");
        assert (node.children[0].children[2].value == "1");
    }

    with (memo[0]["ruleForTest"])
    {
        assert (parsingResult.success);
        assert (parsingResult.nextPosition == 5);
        assert (parsingResult.node.ruleName == "ruleForTest");
        assert (parsingResult.node.children[0].children[0].ruleName == "ruleForTest");
        assert (parsingResult.node.children[0].children[0].children[0].children[0].ruleName == "ruleForTest");
        assert (parsingResult.node.children[0].children[0].children[0].children[0].children[0].value == "1");
        assert (parsingResult.node.children[0].children[0].children[0].children[1].value == "+");
        assert (parsingResult.node.children[0].children[0].children[0].children[2].value == "1");
        assert (parsingResult.node.children[0].children[1].value == "+");
        assert (parsingResult.node.children[0].children[2].value == "1");
        assert (isCalled);
    }
}


ParsingResult sequence(parsers...)(string input, size_t position, ref Memo memo)
{
    ParsingResult parsingWholeResult = ParsingResult(true, position);
    parsingWholeResult.node.ruleName = "#sequence";

    foreach (parser; parsers)
    {
        ParsingResult parsingResult = parser(input, parsingWholeResult.nextPosition, memo);

        if (!parsingResult.success)
        {
            return ParsingResult(false);
        }

        parsingWholeResult.node.children ~= parsingResult.node;
        parsingWholeResult.nextPosition = parsingResult.nextPosition;
    }

    return parsingWholeResult;
}
unittest
{
    Memo memo;

    with (sequence!(toToken!"foo", toToken!"bar")("foobar", 0, memo))
    {
        assert (success);
        assert (nextPosition == 6);
        assert (node.ruleName == "#sequence");
    }
}


ParsingResult select(size_t n, parsers...)(string input, size_t position, ref Memo memo) if (n < parsers.length)
{
    ParsingResult parsingResult = sequence!(parsers)(input, position, memo);

    if (parsingResult.success)
    {
        parsingResult.node = parsingResult.node.children[n];
    }

    return parsingResult;
}
unittest
{
    Memo memo;
    with (select!(1, toToken!"foo", toToken!"bar")("foobar", 0, memo))
    {
        assert (success);
        assert (nextPosition == 6);
        assert (node.value == "bar");
    }
}


ParsingResult choice(parsers...)(string input, size_t position, ref Memo memo)
{
    foreach (parser; parsers)
    {
        ParsingResult parsingResult = parser(input, position, memo);

        if (parsingResult.success)
        {
            return parsingResult;
        }
    }

    return ParsingResult();
}
unittest
{
    Memo memo;

    with (choice!(toToken!"foo", toToken!"bar")("foo", 0, memo))
    {
        assert (success);
        assert (nextPosition == 3);
    }

    with (choice!(toToken!"foo", toToken!"bar")("bar", 0, memo))
    {
        assert (success);
        assert (nextPosition == 3);
    }
}


ParsingResult option(alias parser)(string input, size_t position,ref Memo memo)
{
    ParsingResult parsingWholeResult = ParsingResult(true, position);
    parsingWholeResult.node.ruleName = "#option";

    ParsingResult parsingResult = parser(input, position, memo);

    if (parsingResult.success)
    {
        parsingWholeResult.nextPosition = parsingResult.nextPosition;
        parsingWholeResult.node.children ~= parsingResult.node;
    }

    return parsingWholeResult;
}
unittest
{
    Memo memo;

    with (option!(toToken!"foo")("foo", 0, memo))
    {
        assert (success);
        assert (nextPosition == 3);
        assert (node.ruleName == "#option");
        assert (node.children[0].value == "foo");
    }

    with (option!(toToken!"foo")("bar", 0, memo))
    {
        assert (success);
        assert (node.ruleName == "#option");
        assert (node.children.length == 0);
    }
}


ParsingResult repeat(alias parser, size_t n)(string input, size_t position, ref Memo memo)
{
    ParsingResult parsingWholeResult;
    parsingWholeResult.node.ruleName = "#repeat";

    size_t currentPosition = position;

    while (true)
    {
        ParsingResult parsingResult = parser(input, currentPosition ,memo);

        if (!parsingResult.success)
        {
            break;
        }

        currentPosition = parsingResult.nextPosition;
        parsingWholeResult.node.children ~= parsingResult.node;
    }

    parsingWholeResult.nextPosition = currentPosition;

    if (n <= parsingWholeResult.node.children.length)
    {
        parsingWholeResult.success = true;
    }

    return parsingWholeResult;
}
unittest
{
    Memo memo;

    with (repeat!(toToken!"foo", 2)("foofoo", 0, memo))
    {
        assert (success);
        assert (nextPosition == 6);
        assert (node.children[0].value == "foo");
        assert (node.children[1].value == "foo");
    }

    assert (!repeat!(toToken!"foo", 2)("foo", 0, memo).success);
}


alias zeroOrMore(alias parser) = repeat!(parser, 0);
alias oneOrMore(alias parser) = repeat!(parser, 1);


ParsingResult repeatWithSeparator(alias parser, alias separator, size_t n)(string input, size_t position, ref Memo memo)
{
    ParsingResult parsingResult = sequence!(parser, zeroOrMore!(select!(1, separator, parser)))(input, position, memo);

    if (n == 0 && !parsingResult.success)
    {
        return ParsingResult(true, position, ParseTreeNode("", [], "#repeat"));
    }

    if (parsingResult.node.children[1].children.length < n - 1)
    {
        return ParsingResult(false);
    }

    if (parsingResult.success)
    {
        parsingResult.node.ruleName = "#repeat";
        parsingResult.node.children = parsingResult.node.children[0] ~ parsingResult.node.children[1].children;
    }

    return parsingResult;
}
unittest
{
    Memo memo;

    with (repeatWithSeparator!(toToken!"foo", toToken!",", 2)("foo,foo,foo", 0, memo))
    {
        assert (success);
        assert (nextPosition == 11);
        assert (node.ruleName == "#repeat");
        assert (node.children[0].value == "foo");
        assert (node.children[1].value == "foo");
        assert (node.children[2].value == "foo");
    }

    assert (!repeatWithSeparator!(toToken!"foo", toToken!",", 4)("foo,foo,foo", 0, memo).success);
}


alias zeroOrMoreWithSeparator(alias parser, alias separator) = repeatWithSeparator!(parser, separator, 0);
alias oneOrMoreWithSeparator(alias parser, alias separator) = repeatWithSeparator!(parser, separator, 1);
