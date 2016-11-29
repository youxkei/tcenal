module tcenal.dsl.lexer;

import std.typecons : Typedef;
import std.array : Appender;
import std.ascii : isAlpha, isWhite;
import std.range.primitives : empty;

import compile_time_unittest : enableCompileTimeUnittest;
import tcenal.dsl.token : OpCode, TokenKind, Token;

mixin enableCompileTimeUnittest;


Token[] lex(string src)
{
    return root(src);
}
unittest
{
    assert(
        lex(`foo <- #foo_bar baz <- "baz"`) ==
        [
            Token(TokenKind.IDENTIFIER, OpCode.NOT_OP, "foo"),
            Token(TokenKind.OPERATOR, OpCode.LEFT_ARROW),
            Token(TokenKind.OPERATOR, OpCode.NUMBER_SIGN),
            Token(TokenKind.IDENTIFIER, OpCode.NOT_OP, "foo_bar"),
            Token(TokenKind.IDENTIFIER, OpCode.NOT_OP, "baz"),
            Token(TokenKind.OPERATOR, OpCode.LEFT_ARROW),
            Token(TokenKind.STRING_LITERAL, OpCode.NOT_OP, "baz"),
        ]
    );
}

private:

Token[] root(string src) {
    Appender!(Token[]) tokenAppender;

    while (!src.empty) {
        switch (src[0]) {
            case '<':
                src = src[1..$];

                if (src.empty) {
                    throw new Exception("");
                }

                switch (src[0]) {
                    case '-':
                        tokenAppender.put(Token(TokenKind.OPERATOR, OpCode.LEFT_ARROW));
                        src = src[1..$];
                        continue;

                    default:
                        throw new Exception("");
                }

            case '#':
                src = src[1..$];
                tokenAppender.put(Token(TokenKind.OPERATOR, OpCode.NUMBER_SIGN));
                continue;

            case '/':
                src = src[1..$];
                tokenAppender.put(Token(TokenKind.OPERATOR, OpCode.SLASH));
                continue;

            case '*':
                src = src[1..$];
                tokenAppender.put(Token(TokenKind.OPERATOR, OpCode.ASTERISK));
                continue;

            case '+':
                src = src[1..$];
                tokenAppender.put(Token(TokenKind.OPERATOR, OpCode.PLUS));
                continue;

            case '?':
                src = src[1..$];
                tokenAppender.put(Token(TokenKind.OPERATOR, OpCode.QUESTION));
                continue;

            case '&':
                src = src[1..$];
                tokenAppender.put(Token(TokenKind.OPERATOR, OpCode.AMPERSAND));
                continue;

            case '!':
                src = src[1..$];
                tokenAppender.put(Token(TokenKind.OPERATOR, OpCode.EXCLAMATION));
                continue;

            case '"':
                src = src[1..$];
                tokenAppender.put(stringLiteral(src));
                continue;

            default:
                if (src[0].isWhite()) {
                    src = src[1..$];
                    continue;
                }

                if (src[0].isAlpha()) {
                    tokenAppender.put(identifier(src));
                    continue;
                }
        }

        throw new Exception("");
    }

    return tokenAppender.data;
}

Token stringLiteral(ref string src) {
    Appender!string charAppender;

    while (true) {
        if (src.empty) {
            throw new Exception("");
        }

        if (src[0] == '"') {
            src = src[1..$];
            break;
        }

        charAppender.put(src[0]);
        src = src[1..$];
    }

    return Token(TokenKind.STRING_LITERAL, OpCode.NOT_OP, charAppender.data);
}

Token identifier(ref string src) {
    Appender!string charAppender;

    while (!src.empty) {
        if (src[0].isWhite()) {
            break;
        }

        charAppender.put(src[0]);
        src = src[1..$];
    }

    return Token(TokenKind.IDENTIFIER, OpCode.NOT_OP, charAppender.data);
}
