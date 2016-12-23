module tcenal.dsl.parsers;

import compile_time_unittest : enableCompileTimeUnittest;

import tcenal.parser_combinator.token : Token;
import tcenal.parser_combinator.parsing_result : ParsingResult;
import tcenal.parser_combinator.parse_tree_node : ParseTreeNode;
import tcenal.parser_combinator.memo : Memo;
import tcenal.parser_combinator.combinators : parseToken, parseTokenWithType, applyRule, sequence, select, choice, option, zeroOrMore, oneOrMore, zeroOrMoreWithSeparator, oneOrMoreWithSeparator, not;
import tcenal.parser_combinator.util : parseWithoutMemo;
import tcenal.dsl.lexer : lex;

import std.ascii : isWhite, isAlpha, isAlphaNum;

mixin enableCompileTimeUnittest;


ParsingResult rules(Token[] input, size_t position, ref Memo memo)
{
    return applyRule!(oneOrMore!rule)(input, position, memo);
}


ParsingResult rule(Token[] input, size_t position, ref Memo memo)
{
    return applyRule!(
        sequence!(
            select!(0,
                parseTokenWithType!"identifier",
                parseToken!"<-",
            ),
            choiceExpr,
        )
    )(input, position, memo);
}
unittest
{
    Memo memo;
    with (rule(lex(q{foo <- foo "foo" / "foo"}), 0, memo))
    {
        assert (success);
        assert (nextPosition == 6);
        assert (node.ruleName == "rule");
        assert (node.children[0].ruleName == "#sequence");
        assert (node.children[0].children[0].token.value == "foo");
        assert (node.children[0].children[0].token.type == "identifier");
        assert (node.children[0].children[1].ruleName == "choiceExpr");
        assert (node.children[0].children[1].children[0].ruleName == "#repeat");
        assert (node.children[0].children[1].children[0].children[0].ruleName == "sequenceExpr");
        assert (node.children[0].children[1].children[0].children[0].children[0].ruleName == "#repeat");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].ruleName == "prefixExpr");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].children[0].ruleName == "postfixExpr");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].children[0].children[0].children[0].ruleName == "ruleName");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].children[0].children[0].children[0].children[0].token.value == "foo");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].children[0].children[0].children[0].children[0].token.type == "identifier");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[1].ruleName == "prefixExpr");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[1].children[0].ruleName == "postfixExpr");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[1].children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[1].children[0].children[0].children[0].ruleName == "tokenValue");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[1].children[0].children[0].children[0].children[0].token.value == "foo");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[1].children[0].children[0].children[0].children[0].token.type == "stringLiteral");
        assert (node.children[0].children[1].children[0].children[1].ruleName == "sequenceExpr");
        assert (node.children[0].children[1].children[0].children[1].children[0].ruleName == "#repeat");
        assert (node.children[0].children[1].children[0].children[1].children[0].children[0].ruleName == "prefixExpr");
        assert (node.children[0].children[1].children[0].children[1].children[0].children[0].children[0].ruleName == "postfixExpr");
        assert (node.children[0].children[1].children[0].children[1].children[0].children[0].children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[1].children[0].children[1].children[0].children[0].children[0].children[0].children[0].ruleName == "tokenValue");
        assert (node.children[0].children[1].children[0].children[1].children[0].children[0].children[0].children[0].children[0].children[0].token.value == "foo");
        assert (node.children[0].children[1].children[0].children[1].children[0].children[0].children[0].children[0].children[0].children[0].token.type == "stringLiteral");
    }
}


ParsingResult choiceExpr(Token[] input, size_t position, ref Memo memo)
{
    return applyRule!(
        oneOrMoreWithSeparator!(
            sequenceExpr,
            parseToken!"/"
        )
    )(input, position, memo);
}
unittest
{
    Memo memo;
    with (choiceExpr(lex(q{foo !bar / buz+ / "foobar"}), 0, memo))
    {
        assert (success);
        assert (nextPosition == 8);
        assert (node.ruleName == "choiceExpr");
        assert (node.children[0].ruleName == "#repeat");
        assert (node.children[0].children[0].ruleName == "sequenceExpr");
        assert (node.children[0].children[0].children[0].ruleName == "#repeat");
        assert (node.children[0].children[0].children[0].children[0].ruleName == "prefixExpr");
        assert (node.children[0].children[0].children[0].children[0].children[0].ruleName == "postfixExpr");
        assert (node.children[0].children[0].children[0].children[0].children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[0].children[0].children[0].children[0].children[0].children[0].ruleName == "ruleName");
        assert (node.children[0].children[0].children[0].children[0].children[0].children[0].children[0].children[0].token.value == "foo");
        assert (node.children[0].children[0].children[0].children[0].children[0].children[0].children[0].children[0].token.type == "identifier");
        assert (node.children[0].children[0].children[0].children[1].ruleName == "prefixExpr");
        assert (node.children[0].children[0].children[0].children[1].children[0].ruleName == "#sequence");
        assert (node.children[0].children[0].children[0].children[1].children[0].children[0].token.value == "!");
        assert (node.children[0].children[0].children[0].children[1].children[0].children[1].ruleName == "postfixExpr");
        assert (node.children[0].children[0].children[0].children[1].children[0].children[1].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[0].children[0].children[1].children[0].children[1].children[0].children[0].ruleName == "ruleName");
        assert (node.children[0].children[0].children[0].children[1].children[0].children[1].children[0].children[0].children[0].token.value == "bar");
        assert (node.children[0].children[0].children[0].children[1].children[0].children[1].children[0].children[0].children[0].token.type == "identifier");
        assert (node.children[0].children[1].ruleName == "sequenceExpr");
        assert (node.children[0].children[1].children[0].ruleName == "#repeat");
        assert (node.children[0].children[1].children[0].children[0].ruleName == "prefixExpr");
        assert (node.children[0].children[1].children[0].children[0].children[0].ruleName == "postfixExpr");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].ruleName == "#sequence");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].children[0].children[0].ruleName == "ruleName");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].children[0].children[0].children[0].token.value == "buz");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].children[0].children[0].children[0].token.type == "identifier");
        assert (node.children[0].children[1].children[0].children[0].children[0].children[0].children[1].token.value == "+");
        assert (node.children[0].children[2].ruleName == "sequenceExpr");
        assert (node.children[0].children[2].children[0].ruleName == "#repeat");
        assert (node.children[0].children[2].children[0].children[0].ruleName == "prefixExpr");
        assert (node.children[0].children[2].children[0].children[0].children[0].ruleName == "postfixExpr");
        assert (node.children[0].children[2].children[0].children[0].children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[2].children[0].children[0].children[0].children[0].children[0].ruleName == "tokenValue");
        assert (node.children[0].children[2].children[0].children[0].children[0].children[0].children[0].children[0].token.value == "foobar");
        assert (node.children[0].children[2].children[0].children[0].children[0].children[0].children[0].children[0].token.type == "stringLiteral");
    }
}


ParsingResult sequenceExpr(Token[] input, size_t position, ref Memo memo)
{
    return applyRule!(oneOrMore!prefixExpr)(input, position, memo);
}
unittest
{
    Memo memo;
    with (sequenceExpr(lex(q{foo !bar buz+ "foobar"}), 0, memo))
    {
        assert (success);
        assert (nextPosition == 6);
        assert (node.ruleName == "sequenceExpr");
        assert (node.children[0].ruleName == "#repeat");
        assert (node.children[0].children[0].ruleName == "prefixExpr");
        assert (node.children[0].children[0].children[0].ruleName == "postfixExpr");
        assert (node.children[0].children[0].children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[0].children[0].children[0].children[0].ruleName == "ruleName");
        assert (node.children[0].children[0].children[0].children[0].children[0].children[0].token.value == "foo");
        assert (node.children[0].children[0].children[0].children[0].children[0].children[0].token.type == "identifier");
        assert (node.children[0].children[1].ruleName == "prefixExpr");
        assert (node.children[0].children[1].children[0].ruleName == "#sequence");
        assert (node.children[0].children[1].children[0].children[0].token.value == "!");
        assert (node.children[0].children[1].children[0].children[1].ruleName == "postfixExpr");
        assert (node.children[0].children[1].children[0].children[1].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[1].children[0].children[1].children[0].children[0].ruleName == "ruleName");
        assert (node.children[0].children[1].children[0].children[1].children[0].children[0].children[0].token.value == "bar");
        assert (node.children[0].children[1].children[0].children[1].children[0].children[0].children[0].token.type == "identifier");
        assert (node.children[0].children[2].ruleName == "prefixExpr");
        assert (node.children[0].children[2].children[0].ruleName == "postfixExpr");
        assert (node.children[0].children[2].children[0].children[0].ruleName == "#sequence");
        assert (node.children[0].children[2].children[0].children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[2].children[0].children[0].children[0].children[0].ruleName == "ruleName");
        assert (node.children[0].children[2].children[0].children[0].children[0].children[0].children[0].token.value == "buz");
        assert (node.children[0].children[2].children[0].children[0].children[0].children[0].children[0].token.type == "identifier");
        assert (node.children[0].children[2].children[0].children[0].children[1].token.value == "+");
        assert (node.children[0].children[3].ruleName == "prefixExpr");
        assert (node.children[0].children[3].children[0].ruleName == "postfixExpr");
        assert (node.children[0].children[3].children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[3].children[0].children[0].children[0].ruleName == "tokenValue");
        assert (node.children[0].children[3].children[0].children[0].children[0].children[0].token.value == "foobar");
        assert (node.children[0].children[3].children[0].children[0].children[0].children[0].token.type == "stringLiteral");
    }
}


ParsingResult prefixExpr(Token[] input, size_t position, ref Memo memo)
{
    return applyRule!(
        choice!(
            sequence!(
                choice!(
                    parseToken!"&",
                    parseToken!"!"
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
    with (prefixExpr(lex(q{&foo}), 0, memo))
    {
        assert (success);
        assert (nextPosition == 2);
        assert (node.ruleName == "prefixExpr");
        assert (node.children[0].ruleName == "#sequence");
        assert (node.children[0].children[0].token.value == "&");
        assert (node.children[0].children[1].ruleName == "postfixExpr");
        assert (node.children[0].children[1].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[1].children[0].children[0].ruleName == "ruleName");
        assert (node.children[0].children[1].children[0].children[0].children[0].token.value == "foo");
        assert (node.children[0].children[1].children[0].children[0].children[0].token.type == "identifier");
    }
}


ParsingResult postfixExpr(Token[] input, size_t position, ref Memo memo)
{
    return applyRule!(
        choice!(
            sequence!(
                primaryExpr,
                choice!(
                    parseToken!"*",
                    parseToken!"+",
                ),
                option!(
                    select!(1,
                        parseToken!"<",
                        choiceExpr,
                        parseToken!">",
                    )
                )
            ),
            sequence!(
                primaryExpr,
                parseToken!"?",
            ),
            primaryExpr
        )
    )(input, position, memo);
}
unittest
{
    with (parseWithoutMemo!postfixExpr(lex(q{foo*})))
    {
        assert (success);
        assert (nextPosition == 2);
        assert (node.ruleName == "postfixExpr");
        assert (node.children[0].ruleName == "#sequence");
        assert (node.children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[0].children[0].ruleName == "ruleName");
        assert (node.children[0].children[0].children[0].children[0].token.value == "foo");
        assert (node.children[0].children[0].children[0].children[0].token.type == "identifier");
        assert (node.children[0].children[1].token.value == "*");
        assert (node.children[0].children[2].ruleName == "#option");
        assert (node.children[0].children[2].children.length == 0);
    }
    with (parseWithoutMemo!postfixExpr(lex(q{foo*<foo>})))
    {
        assert (success);
        assert (nextPosition == 5);
        assert (node.ruleName == "postfixExpr");
        assert (node.children[0].ruleName == "#sequence");
        assert (node.children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[0].children[0].ruleName == "ruleName");
        assert (node.children[0].children[0].children[0].children[0].token.value == "foo");
        assert (node.children[0].children[0].children[0].children[0].token.type == "identifier");
        assert (node.children[0].children[1].token.value == "*");
        assert (node.children[0].children[2].ruleName == "#option");
        assert (node.children[0].children[2].children[0].ruleName == "choiceExpr");
        assert (node.children[0].children[2].children[0].children[0].ruleName == "#repeat");
        assert (node.children[0].children[2].children[0].children[0].children[0].ruleName == "sequenceExpr");
        assert (node.children[0].children[2].children[0].children[0].children[0].children[0].ruleName == "#repeat");
        assert (node.children[0].children[2].children[0].children[0].children[0].children[0].children[0].ruleName == "prefixExpr");
        assert (node.children[0].children[2].children[0].children[0].children[0].children[0].children[0].children[0].ruleName == "postfixExpr");
        assert (node.children[0].children[2].children[0].children[0].children[0].children[0].children[0].children[0].children[0].ruleName == "primaryExpr");
        assert (node.children[0].children[2].children[0].children[0].children[0].children[0].children[0].children[0].children[0].children[0].ruleName == "ruleName");
        assert (node.children[0].children[2].children[0].children[0].children[0].children[0].children[0].children[0].children[0].children[0].children[0].token.value == "foo");
        assert (node.children[0].children[2].children[0].children[0].children[0].children[0].children[0].children[0].children[0].children[0].children[0].token.type == "identifier");
    }
}


ParsingResult primaryExpr(Token[] input, size_t position, ref Memo memo)
{
    return applyRule!(
        choice!(
            select!(1,
                parseToken!"(",
                choiceExpr,
                parseToken!")"
            ),
            tokenValue,
            tokenType,
            select!(0,
                ruleName,
                not!(parseToken!"<-")
            )
        )
    )(input, position, memo);
}
unittest
{
    Memo memo;
    with (primaryExpr(lex(q{foo}), 0, memo))
    {
        assert (success);
        assert (nextPosition == 1);
        assert (node.ruleName == "primaryExpr");
        assert (node.children[0].ruleName == "ruleName");
        assert (node.children[0].children[0].token.value == "foo");
        assert (node.children[0].children[0].token.type == "identifier");
    }

    memo = memo.init;
    assert (!primaryExpr(lex(q{foo <-}), 0, memo).success);
}


ParsingResult ruleName(Token[] input, size_t position, ref Memo memo)
{
    return applyRule!(parseTokenWithType!"identifier")(input, position, memo);
}


ParsingResult tokenValue(Token[] input, size_t position, ref Memo memo)
{
    return applyRule!(parseTokenWithType!"stringLiteral")(input, position, memo);
}


ParsingResult tokenType(Token[] input, size_t position, ref Memo memo)
{
    return applyRule!(select!(1, parseToken!"@", parseTokenWithType!"identifier"))(input, position, memo);
}
