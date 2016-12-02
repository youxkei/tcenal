module tcenal.dsl.lexer;

import std.array : Appender;
import std.ascii : isAlpha, isWhite;
import std.range.primitives : empty;
import std.algorithm : startsWith;
import std.meta : AliasSeq;

import compile_time_unittest : enableCompileTimeUnittest;
import parser_combinator.token : Token;

mixin enableCompileTimeUnittest;


Token[] lex(string src)
{
    return root(src);
}
unittest
{
    assert(
        lex(q{foo <- @foo_bar baz <- "baz"}) ==
        [
            Token("foo", "identifier"),
            Token("<-"),
            Token("@"),
            Token("foo_bar", "identifier"),
            Token("baz", "identifier"),
            Token("<-"),
            Token(`"baz"`, "stringLiteral"),
        ]
    );
}

private:

Token[] root(string src) {
    Appender!(Token[]) tokenAppender;

    loop:
    while (!src.empty) {
        if (src[0].isWhite()) {
            src = src[1..$];
            continue;
        }

        alias untypedTokens = AliasSeq!("<-", "@", "/", "*", "+", "?", "&", "!");
        foreach (untypedToken; untypedTokens)
        {
            if (src.startsWith(untypedToken)) {
                tokenAppender.put(Token(untypedToken));
                src = src[untypedToken.length..$];

                continue loop;
            }
        }

        if (src[0] == '"')
        {
            tokenAppender.put(stringLiteral(src));
            continue;
        }

        if (src[0].isAlpha() || src[0] == '_')
        {
            tokenAppender.put(identifier(src));
            continue;
        }

        throw new Exception("");
    }

    return tokenAppender.data;
}

Token stringLiteral(ref string src) {
    size_t closingDoubleQuoteIndex;

    foreach (i, c; src) {
        if (i == 0) continue; // starting double quote

        if (c == '"')
        {
            closingDoubleQuoteIndex = i;
            break;
        }
    }

    if (closingDoubleQuoteIndex == 0) throw new Exception("");

    Token token = Token(src[0..(closingDoubleQuoteIndex + 1)], "stringLiteral");
    src = src[(closingDoubleQuoteIndex + 1)..$];

    return token;
}

Token identifier(ref string src) {
    size_t immediatelyFollowingWhiteSpaceIndex;

    foreach (i, c; src) {
        if (c.isWhite())
        {
            immediatelyFollowingWhiteSpaceIndex = i;
            break;
        }
    }

    if (immediatelyFollowingWhiteSpaceIndex == 0) immediatelyFollowingWhiteSpaceIndex = src.length;

    Token token = Token(src[0..immediatelyFollowingWhiteSpaceIndex], "identifier");
    src = src[immediatelyFollowingWhiteSpaceIndex..$];

    return token;
}
