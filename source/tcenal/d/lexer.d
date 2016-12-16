module tcenal.d.lexer;

import std.array : Appender;
import std.ascii : isAlpha, isAlphaNum, isWhite, isDigit;
import std.range.primitives : empty;
import std.algorithm : startsWith;
import std.meta : AliasSeq;

import tcenal.parser_combinator.token : Token;
import tcenal.util : allowRvalue;

import compile_time_unittest : enableCompileTimeUnittest;
import assert_that : assertThat, eq, array, fields;

mixin enableCompileTimeUnittest;


Token[] lex(string src)
{
    return root(src);
}
unittest
{
    mixin assertThat!(
        "tokens", q{
            lex(q{
                import std.stdio : writeln;
                void main()
                {
                    writeln("Hello, world!");
                }
            })
        },
        array!()._!(
            fields!()._!(eq!q{import}, eq!""),
            fields!()._!(eq!q{std}, eq!"identifier"),
            fields!()._!(eq!q{.}, eq!""),
            fields!()._!(eq!q{stdio}, eq!"identifier"),
            fields!()._!(eq!q{:}, eq!""),
            fields!()._!(eq!q{writeln}, eq!"identifier"),
            fields!()._!(eq!q{;}, eq!""),
            fields!()._!(eq!q{void}, eq!""),
            fields!()._!(eq!q{main}, eq!"identifier"),
            fields!()._!(eq!q{(}, eq!""),
            fields!()._!(eq!q{)}, eq!""),
            fields!()._!(eq!"{", eq!""),
            fields!()._!(eq!q{writeln}, eq!"identifier"),
            fields!()._!(eq!q{(}, eq!""),
            fields!()._!(eq!q{"Hello, world!"}, eq!"stringLiteral"),
            fields!()._!(eq!q{)}, eq!""),
            fields!()._!(eq!q{;}, eq!""),
            fields!()._!(eq!"}", eq!""),
        )
    );
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
            continue;
        }

        if (src[0].isAlpha() || src[0] == '_')
        {
            tokenAppender.put(identifier(src));
            continue;
        }

        throw new Exception(src);
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
    size_t immediatelyFollowingNonAlphaNumIndex;

    foreach (i, c; src) {
        if (!c.isAlphaNum() && c != '_')
        {
            immediatelyFollowingNonAlphaNumIndex = i;
            break;
        }
    }

    if (immediatelyFollowingNonAlphaNumIndex == 0) immediatelyFollowingNonAlphaNumIndex = src.length;

    Token token = Token(src[0..immediatelyFollowingNonAlphaNumIndex], "identifier");
    src = src[immediatelyFollowingNonAlphaNumIndex..$];

    alias keywords = AliasSeq!("abstract", "alias", "align", "asm", "assert", "auto", "body", "bool", "break", "byte", "case", "cast", "catch", "cdouble", "cent", "cfloat", "char", "class", "const", "continue", "creal", "dchar", "debug", "default", "delegate", "delete (deprecated)", "deprecated", "do", "double", "else", "enum", "export", "extern", "false", "final", "finally", "float", "for", "foreach", "foreach_reverse", "function", "goto", "idouble", "if", "ifloat", "immutable", "import", "in", "inout", "int", "interface", "invariant", "ireal", "is", "lazy", "long", "macro (unused)", "mixin", "module", "new", "nothrow", "null", "out", "override", "package", "pragma", "private", "protected", "public", "pure", "real", "ref", "return", "scope", "shared", "short", "static", "struct", "super", "switch", "synchronized", "template", "this", "throw", "true", "try", "typedef", "typeid", "typeof", "ubyte", "ucent", "uint", "ulong", "union", "unittest", "ushort", "version", "void", "volatile", "wchar", "while", "with", "__FILE__", "__FILE_FULL_PATH__", "__MODULE__", "__LINE__", "__FUNCTION__", "__PRETTY_FUNCTION__", "__gshared", "__traits", "__vector", "__parameters");
    foreach (keyword; keywords)
    {
        if (token.value == keyword) {
            token.type = "";
            break;
        }
    }

    return token;
}
unittest
{
    mixin assertThat!("token", q{allowRvalue!identifier(q{foo})},         fields!()._!(eq!q{foo},         eq!"identifier"));
    mixin assertThat!("token", q{allowRvalue!identifier(q{bar57})},       fields!()._!(eq!q{bar57},       eq!"identifier"));
    mixin assertThat!("token", q{allowRvalue!identifier(q{_foo_bar_57})}, fields!()._!(eq!q{_foo_bar_57}, eq!"identifier"));
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

    Token token = Token(src[0..immediatelyFollowingNonDigitIndex], "integerLiteral");
    src = src[immediatelyFollowingNonDigitIndex..$];

    return token;
}
unittest
{
    assert(allowRvalue!numericLiteral(q{123}) == Token(q{123}, "integerLiteral"));
}
