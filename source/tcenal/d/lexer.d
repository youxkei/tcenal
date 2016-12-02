module tcenal.d.lexer;

import std.array : Appender;
import std.ascii : isAlpha, isWhite, isDigit;
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
        lex(q{
            import std.stdio : writeln;
            void main()
            {
                writeln("Hello, world!");
            }
        }) == [
            Token(q{import}, "identifier"),
            Token(q{std}, "identifier"),
            Token(q{.}),
            Token(q{stdio}, "identifier"),
            Token(q{:}),
            Token(q{writeln}, "identifier"),
            Token(q{;}),
            Token(q{void}, "identifier"),
            Token(q{main}, "identifier"),
            Token(q{(}),
            Token(q{)}),
            Token("{"),
            Token(q{writeln}, "identifier"),
            Token(q{(}),
            Token(q{"Hello, world!"}, "stringLiteral"),
            Token(q{)}),
            Token(q{;}),
            Token("}"),
        ]
    );
}

private:

version(unittest) auto allowRvalue(alias f, Args...)(Args args)
{
    return f(args);
}

Token[] root(string src)
{
    Appender!(Token[]) tokenAppender;

    loop:
    while (!src.empty) {
        if (src[0].isWhite()) {
            src = src[1..$];
            continue;
        }

        if (src.startsWith("//"))
        {
            lineComment(src);
            continue;
        }

        if (src.startsWith("/*"))
        {
            blockComment(src);
            continue;
        }

        if (src.startsWith("/+"))
        {
            nestingBlockComment(src);
            continue;
        }

        alias untypedTokens = AliasSeq!("~=", "~", "}", "||", "|=", "|", "{", "^^=", "^^", "^=", "^", "]", "[", "@", "?", ">>>=", ">>>", ">>=", ">>", ">=", ">", "=>", "==", "=", "<>=", "<>", "<=", "<<=", "<<", "<", ";", ":", "/=", "/", "...", "..", ".", "-=", "--", "-", ",", "+=", "++", "+", "*=", "*", ")", "(", "&=", "&&", "&", "%=", "%", "$", "#", "!>=", "!>", "!=", "!<>=", "!<>", "!<=", "!<", "!");
        foreach (untypedToken; untypedTokens)
        {
            if (src.startsWith(untypedToken)) {
                tokenAppender.put(Token(untypedToken));
                src = src[untypedToken.length..$];

                continue loop;
            }
        }

        if (src.startsWith(`r"`) || src[0] == '`' || src[0] == '"')
        {
            tokenAppender.put(stringLiteral(src));
            continue;
        }

        if (src[0] == '\'')
        {
            tokenAppender.put(characterLiteral(src));
            continue;
        }

        if (src[0].isDigit())
        {
            tokenAppender.put(numericLiteral(src));
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

void lineComment(ref string src)
{
    while (!src.empty)
    {
        if (src[0] == '\n')
        {
            src = src[1..$];
            break;
        }

        src = src[1..$];
    }
}

void blockComment(ref string src)
{
    while (!src.empty)
    {
        if (src.startsWith("*/"))
        {
            src = src[2..$];
            break;
        }

        src = src[1..$];
    }
}

void nestingBlockComment(ref string src)
{
    src = src[2..$];

    while (!src.empty)
    {
        if (src.startsWith("/+"))
        {
            nestingBlockComment(src);
        }

        if (src.startsWith("+/"))
        {
            src = src[2..$];
            break;
        }

        src = src[1..$];
    }
}

Token stringLiteral(ref string src)
{
    char closingQuote;
    bool escapeSequenceAvailable;
    size_t contentStartingIndex;

    switch (src[0])
    {
        case 'r':
            closingQuote = '"';
            contentStartingIndex = 2;
            break;

        case '`':
            closingQuote = '`';
            contentStartingIndex = 1;
            break;

        case '"':
            closingQuote = '"';
            escapeSequenceAvailable = true;
            contentStartingIndex = 1;
            break;

        default:
            assert(0);
    }

    size_t closingIndex;
    bool inEscapeSequence;
    foreach (i, c; src) {
        if (i < contentStartingIndex) continue;

        if (escapeSequenceAvailable && c == '\\')
        {
            inEscapeSequence = true;
            continue;
        }

        if (!inEscapeSequence && c == closingQuote)
        {
            closingIndex = i;
            break;
        }

        inEscapeSequence = false;
    }

    if (closingIndex == 0) throw new Exception("");

    Token token = Token(src[0..(closingIndex + 1)], "stringLiteral");
    src = src[(closingIndex + 1)..$];

    return token;
}
unittest
{
    assert(allowRvalue!stringLiteral(q{"foo"}) == Token(q{"foo"}, "stringLiteral"));
    assert(allowRvalue!stringLiteral(q{"foo\"bar"}) == Token(q{"foo\"bar"}, "stringLiteral"));
    assert(allowRvalue!stringLiteral(q{r"f\o\o"}) == Token(q{r"f\o\o"}, "stringLiteral"));
    assert(allowRvalue!stringLiteral(q{`"f\o\o"`}) == Token(q{`"f\o\o"`}, "stringLiteral"));
}

Token characterLiteral(ref string src)
{
    Token token;
    token.type = "characterLiteral";

    if (src[1] == '\\')
    {
        token.value = src[0..4];
        src = src[4..$];
    }
    else
    {
        token.value = src[0..3];
        src = src[3..$];
    }

    return token;
}
unittest
{
    assert(allowRvalue!characterLiteral(q{'c'}) == Token(q{'c'}, "characterLiteral"));
    assert(allowRvalue!characterLiteral(q{'\n'}) == Token(q{'\n'}, "characterLiteral"));
    assert(allowRvalue!characterLiteral(q{'\\'}) == Token(q{'\\'}, "characterLiteral"));
}

Token identifier(ref string src)
{
    size_t immediatelyFollowingNonAlphaIndex;

    foreach (i, c; src) {
        if (!c.isAlpha())
        {
            immediatelyFollowingNonAlphaIndex = i;
            break;
        }
    }

    if (immediatelyFollowingNonAlphaIndex == 0) immediatelyFollowingNonAlphaIndex = src.length;

    Token token = Token(src[0..immediatelyFollowingNonAlphaIndex], "identifier");
    src = src[immediatelyFollowingNonAlphaIndex..$];

    return token;
}

Token numericLiteral(ref string src)
{
    size_t immediatelyFollowingNonDigitIndex;

    foreach (i, c; src)
    {
        if (!c.isDigit() && c != '_')
        {
            immediatelyFollowingNonDigitIndex = i;
            break;
        }
    }

    if (immediatelyFollowingNonDigitIndex == 0) immediatelyFollowingNonDigitIndex = src.length;

    Token token = Token(src[0..immediatelyFollowingNonDigitIndex], "numericLiteral");
    src = src[immediatelyFollowingNonDigitIndex..$];

    return token;
}
unittest
{
    assert(allowRvalue!numericLiteral(q{123}) == Token(q{123}, "numericLiteral"));
}
