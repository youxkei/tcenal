module tcenal.parsers;

import parser_combinator.combinators;
import parser_combinator.memo;
import parser_combinator.parsing_result;

import std.ascii : isWhite, isDigit, isAlpha, isAlphaNum;

ParsingResult skip(alias parser)(string input, size_t position, ref Memo memo)
{
    static ParsingResult whitespaces(string input, size_t position, ref Memo memo)
    {
        for (; position < input.length && input[position].isWhite(); ++position){}

        return ParsingResult(true, position);
    }

    return select!(1, applyRule!(whitespaces, "whitespaces"), parser)(input, position, memo);
}


ParsingResult StringLiteral(alias ruleSelector)(string input, size_t position, ref Memo memo)
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

        return ParsingResult(true, currentPosition + 1, ParseTreeNode(input[position .. currentPosition + 1]));
    }

    return applyRule!(skip!stringLiteralImpl)(input, position, memo);
}


ParsingResult IntegerLiteral(alias ruleSelector)(string input, size_t position, ref Memo memo)
{
    static ParsingResult IntegerLiteralImpl(string input, size_t position, ref Memo memo)
    {
        size_t currentPosition = position;

        for (; currentPosition < input.length && input[currentPosition].isDigit(); ++currentPosition){}

        if (currentPosition == position)
        {
            return ParsingResult(false);
        }

        return ParsingResult(true, currentPosition, ParseTreeNode(input[position .. currentPosition]));
    }

    return applyRule!(skip!IntegerLiteralImpl)(input, position, memo);
}


ParsingResult FloatLiteral(alias ruleSelector)(string input, size_t position, ref Memo memo)
{
    return ParsingResult();
}


ParsingResult CharacterLiteral(alias ruleSelector)(string input, size_t position, ref Memo memo)
{
    static ParsingResult CharacterLiteralImpl(in string input, in size_t position, ref Memo memo)
    {
        if (input.length <= position)
        {
            return ParsingResult(false);
        }

        if (input[position] != '\'')
        {
            return ParsingResult(false);
        }

        size_t basePosition = position + 1,
               currentPosition = basePosition;

        for (; currentPosition < input.length && input[currentPosition] != '\''; ++currentPosition){}

        if (input.length <= currentPosition)
        {
            return ParsingResult(false);
        }

        return ParsingResult(true, currentPosition + 1, ParseTreeNode(input[position .. currentPosition + 1]));
    }

    return applyRule!(skip!CharacterLiteralImpl)(input, position, memo);
}


ParsingResult Identifier(alias ruleSelector)(string input, size_t position, ref Memo memo)
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

    return applyRule!(skip!identifierImpl)(input, position, memo);
}


import tcenal.dsl.generate_parsers : generateParsers;

mixin (generateParsers(import ("drules.peg")));
