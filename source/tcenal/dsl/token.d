module tcenal.dsl.token;

enum OpCode
{
    NOT_OP, LEFT_ARROW, NUMBER_SIGN, SLASH, ASTERISK, PLUS, QUESTION, AMPERSAND, EXCLAMATION,
}

enum TokenKind
{
    OPERATOR, PAREN_OPEN, PAREN_CLOSE, STRING_LITERAL, IDENTIFIER,
}

struct Token
{
    TokenKind kind;
    OpCode opcode;
    string value;
}
