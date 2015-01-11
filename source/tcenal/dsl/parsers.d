module tcenal.dsl.parsers;

import compile_time_unittest : enableCompileTimeUnittest;

import parser_combinator.parsing_result : ParsingResult;
import parser_combinator.parse_tree_node : ParseTreeNode;
import parser_combinator.memo : Memo;
import parser_combinator.combinators : toToken, applyRule, sequence, select, choice, option, zeroOrMore, oneOrMore, zeroOrMoreWithSeparator, oneOrMoreWithSeparator;

import std.ascii : isWhite, isAlpha, isAlphaNum;

mixin enableCompileTimeUnittest;


ParsingResult skip(alias parser)(string input, size_t position, ref Memo memo)
{
    static ParsingResult whitespaces(string input, size_t position, ref Memo memo)
    {
        for (; position < input.length && input[position].isWhite(); ++position){}

        return ParsingResult(true, position);
    }

    return select!(1, applyRule!(whitespaces, "whitespaces"), parser)(input, position, memo);
}
unittest
{
    Memo memo;
    with (skip!(toToken!"foo")("  foo", 0, memo))
    {
        assert (success);
        assert (nextPosition == 5);
        assert (node.value == "foo");
    }
}


ParsingResult rules(string input, size_t position, ref Memo memo)
{
    return applyRule!(oneOrMore!rule)(input, position, memo);
}


ParsingResult rule(string input, size_t position, ref Memo memo)
{
    return applyRule!(
        sequence!(
            select!(0,
                skip!(identifier),
                skip!(toToken!"<-"),
            ),
            select!(0,
                choiceExpr,
                skip!(toToken!";")
            )
        )
    )(input, position, memo);
}
unittest
{
    Memo memo;
    with (rule(`foo <- foo "foo" / "foo";`, 0, memo))
    {
        assert (success);
        assert (nextPosition == 25);
        assert (node.ruleName == "rule");
        assert (node.children[0].ruleName == "#sequence");
        assert (node.children[0].children[0].ruleName == "identifier");
        assert (node.children[0].children[0].children[0].value == "foo");
        assert (node.children[0].children[1].ruleName == "choiceExpr");
        assert (node.children[0].children[1].children[0].ruleName == "#repeat");
        assert (node.children[0].children[1].children[0].children[0].ruleName == "sequenceExpr");
        assert (node.children[0].children[1].children[0].children[0].children[0].ruleName == "#repeat");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].ruleName == "prefixExpr");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].children[0].ruleName == "postfixExpr");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].children[0].children[0].children[0].ruleName == "identifier");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].children[0].children[0].children[0].children[0].value == "foo");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[1].ruleName == "prefixExpr");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[1].children[0].ruleName == "postfixExpr");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[1].children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[1].children[0].children[0].children[0].ruleName == "stringLiteral");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[1].children[0].children[0].children[0].children[0].value == "foo");
        assert (node.children[0].children[1].children[0].children[1].ruleName == "sequenceExpr");
        assert (node.children[0].children[1].children[0].children[1].children[0].ruleName == "#repeat");
        assert (node.children[0].children[1].children[0].children[1].children[0].children[0].ruleName == "prefixExpr");
        assert (node.children[0].children[1].children[0].children[1].children[0].children[0].children[0].ruleName == "postfixExpr");
        assert (node.children[0].children[1].children[0].children[1].children[0].children[0].children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[1].children[0].children[1].children[0].children[0].children[0].children[0].children[0].ruleName == "stringLiteral");
        assert (node.children[0].children[1].children[0].children[1].children[0].children[0].children[0].children[0].children[0].children[0].value == "foo");
    }
}


ParsingResult choiceExpr(string input, size_t position, ref Memo memo)
{
    return applyRule!(
        oneOrMoreWithSeparator!(
            sequenceExpr,
            skip!(toToken!"/")
        )
    )(input, position, memo);
}
unittest
{
    Memo memo;
    with (choiceExpr(`foo !bar / buz+ / "foobar"`, 0, memo))
    {
        assert (success);
        assert (nextPosition == 26);
        assert (node.ruleName == "choiceExpr");
        assert (node.children[0].ruleName == "#repeat");
        assert (node.children[0].children[0].ruleName == "sequenceExpr");
        assert (node.children[0].children[0].children[0].ruleName == "#repeat");
        assert (node.children[0].children[0].children[0].children[0].ruleName == "prefixExpr");
        assert (node.children[0].children[0].children[0].children[0].children[0].ruleName == "postfixExpr");
        assert (node.children[0].children[0].children[0].children[0].children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[0].children[0].children[0].children[0].children[0].children[0].ruleName == "identifier");
        assert (node.children[0].children[0].children[0].children[0].children[0].children[0].children[0].children[0].value == "foo");
        assert (node.children[0].children[0].children[0].children[1].ruleName == "prefixExpr");
        assert (node.children[0].children[0].children[0].children[1].children[0].ruleName == "#sequence");
        assert (node.children[0].children[0].children[0].children[1].children[0].children[0].value == "!");
        assert (node.children[0].children[0].children[0].children[1].children[0].children[1].ruleName == "postfixExpr");
        assert (node.children[0].children[0].children[0].children[1].children[0].children[1].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[0].children[0].children[1].children[0].children[1].children[0].children[0].ruleName == "identifier");
        assert (node.children[0].children[0].children[0].children[1].children[0].children[1].children[0].children[0].children[0].value == "bar");
        assert (node.children[0].children[1].ruleName == "sequenceExpr");
        assert (node.children[0].children[1].children[0].ruleName == "#repeat");
        assert (node.children[0].children[1].children[0].children[0].ruleName == "prefixExpr");
        assert (node.children[0].children[1].children[0].children[0].children[0].ruleName == "postfixExpr");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].ruleName == "#sequence");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].children[0].children[0].ruleName == "identifier");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].children[0].children[0].children[0].value == "buz");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].children[1].value == "+");
        assert (node.children[0].children[2].ruleName == "sequenceExpr");
        assert (node.children[0].children[2].children[0].ruleName == "#repeat");
        assert (node.children[0].children[2].children[0].children[0].ruleName == "prefixExpr");
        assert (node.children[0].children[2].children[0].children[0].children[0].ruleName == "postfixExpr");
        assert (node.children[0].children[2].children[0].children[0].children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[2].children[0].children[0].children[0].children[0].children[0].ruleName == "stringLiteral");
        assert (node.children[0].children[2].children[0].children[0].children[0].children[0].children[0].children[0].value == "foobar");
    }
}


ParsingResult sequenceExpr(string input, size_t position, ref Memo memo)
{
    return applyRule!(oneOrMore!prefixExpr)(input, position, memo);
}
unittest
{
    Memo memo;
    with (sequenceExpr(`foo !bar buz+ "foobar"`, 0, memo))
    {
        assert (success);
        assert (nextPosition == 22);
        assert (node.ruleName == "sequenceExpr");
        assert (node.children[0].ruleName == "#repeat");
        assert (node.children[0].children[0].ruleName == "prefixExpr");
        assert (node.children[0].children[0].children[0].ruleName == "postfixExpr");
        assert (node.children[0].children[0].children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[0].children[0].children[0].children[0].ruleName == "identifier");
        assert (node.children[0].children[0].children[0].children[0].children[0].children[0].value == "foo");
        assert (node.children[0].children[1].ruleName == "prefixExpr");
        assert (node.children[0].children[1].children[0].ruleName == "#sequence");
        assert (node.children[0].children[1].children[0].children[0].value == "!");
        assert (node.children[0].children[1].children[0].children[1].ruleName == "postfixExpr");
        assert (node.children[0].children[1].children[0].children[1].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[1].children[0].children[1].children[0].children[0].ruleName == "identifier");
        assert (node.children[0].children[1].children[0].children[1].children[0].children[0].children[0].value == "bar");
        assert (node.children[0].children[2].ruleName == "prefixExpr");
        assert (node.children[0].children[2].children[0].ruleName == "postfixExpr");
        assert (node.children[0].children[2].children[0].children[0].ruleName == "#sequence");
        assert (node.children[0].children[2].children[0].children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[2].children[0].children[0].children[0].children[0].ruleName == "identifier");
        assert (node.children[0].children[2].children[0].children[0].children[0].children[0].children[0].value == "buz");
        assert (node.children[0].children[2].children[0].children[0].children[1].value == "+");
        assert (node.children[0].children[3].ruleName == "prefixExpr");
        assert (node.children[0].children[3].children[0].ruleName == "postfixExpr");
        assert (node.children[0].children[3].children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[3].children[0].children[0].children[0].ruleName == "stringLiteral");
        assert (node.children[0].children[3].children[0].children[0].children[0].children[0].value == "foobar");
    }
}


ParsingResult prefixExpr(string input, size_t position, ref Memo memo)
{
    return applyRule!(
        choice!(
            sequence!(
                skip!(
                    choice!(
                        toToken!"&",
                        toToken!"!"
                    ),
                ),
                postfixExpr
            ),
            postfixExpr
        )
    )(input, position, memo);
}
unittest
{
    Memo memo;
    with (prefixExpr("&foo", 0, memo))
    {
        assert (success);
        assert (nextPosition == 4);
        assert (node.ruleName == "prefixExpr");
        assert (node.children[0].ruleName == "#sequence");
        assert (node.children[0].children[0].value == "&");
        assert (node.children[0].children[1].ruleName == "postfixExpr");
        assert (node.children[0].children[1].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[1].children[0].children[0].ruleName == "identifier");
        assert (node.children[0].children[1].children[0].children[0].children[0].value == "foo");
    }
}


ParsingResult postfixExpr(string input, size_t position, ref Memo memo)
{
    return applyRule!(
        choice!(
            sequence!(
                primaryExpr,
                skip!(
                    choice!(
                        toToken!"*",
                        toToken!"+",
                        toToken!"?",
                    )
                )
            ),
            primaryExpr
        )
    )(input, position, memo);
}
unittest
{
    Memo memo;
    with (postfixExpr("foo*", 0, memo))
    {
        assert (success);
        assert (nextPosition == 4);
        assert (node.ruleName == "postfixExpr");
        assert (node.children[0].ruleName == "#sequence");
        assert (node.children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[0].children[0].ruleName == "identifier");
        assert (node.children[0].children[0].children[0].children[0].value == "foo");
        assert (node.children[0].children[1].value == "*");
    }
}


ParsingResult primaryExpr(string input, size_t position, ref Memo memo)
{
    return applyRule!(
        choice!(
            select!(1,
                skip!(toToken!"("),
                choiceExpr,
                skip!(toToken!")")
            ),
            skip!stringLiteral,
            skip!identifier
        )
    )(input, position, memo);
}
unittest
{
    Memo memo;
    with (primaryExpr(" foo", 0, memo))
    {
        assert (success);
        assert (nextPosition == 4);
        assert (node.ruleName == "primaryExpr");
        assert (node.children[0].ruleName == "identifier");
        assert (node.children[0].children[0].value == "foo");
    }
}


ParsingResult identifier(string input, size_t position, ref Memo memo)
{
    static ParsingResult identifierImpl(string input, size_t position, ref Memo memo)
    {
        size_t currentPosition = position;

        while (currentPosition < input.length)
        {
            if (currentPosition == position && (input[currentPosition].isAlpha() || input[currentPosition] == '_'))
            {
                ++currentPosition;
            }
            else if (currentPosition != position && (input[currentPosition].isAlphaNum() || input[currentPosition] == '_'))
            {
                ++currentPosition;
            }
            else
            {
                break;
            }
        }

        if (currentPosition == position)
        {
            return ParsingResult(false);
        }

        return ParsingResult(true, currentPosition, ParseTreeNode(input[position .. currentPosition]));
    }

    return applyRule!identifierImpl(input, position, memo);
}
unittest
{
    Memo memo;
    with (identifier("foobar2000 mobile", 0, memo))
    {
        assert (success);
        assert (nextPosition == 10);
        assert (node.ruleName == "identifier");
        assert (node.children[0].value == "foobar2000");
    }
}


ParsingResult stringLiteral(string input, size_t position, ref Memo memo)
{
    static ParsingResult stringLiteralImpl(in string input, in size_t position, ref Memo memo)
    {
        if (input.length <= position)
        {
            return ParsingResult(false);
        }

        if (input[position] != '"')
        {
            return ParsingResult(false);
        }

        size_t basePosition = position + 1,
               currentPosition = basePosition;

        for (; currentPosition < input.length && input[currentPosition] != '"'; ++currentPosition){}

        if (input.length <= currentPosition)
        {
            return ParsingResult(false);
        }

        return ParsingResult(true, currentPosition + 1, ParseTreeNode(input[basePosition .. currentPosition]));
    }

    return applyRule!stringLiteralImpl(input, position, memo);
}
unittest
{
    Memo memo;
    assert (!stringLiteral(`"`, 0, memo).success);

    memo = memo.init;
    assert (!stringLiteral(`"foo`, 0, memo).success);

    memo = memo.init;
    with (stringLiteral(`"foo"`, 0, memo))
    {
        assert (success);
        assert (nextPosition == 5);
        assert (node.ruleName == "stringLiteral");
        assert (node.children[0].value == "foo");
    }

    memo = memo.init;
    with (stringLiteral(`"foo-bar"`, 0, memo))
    {
        assert (success);
        assert (nextPosition == 9);
        assert (node.ruleName == "stringLiteral");
        assert (node.children[0].value == "foo-bar");
    }
}
