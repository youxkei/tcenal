module parser_combinator.report_parsing;

import compile_time_unittest : enableCompileTimeUnittest;
import parser_combinator.memo : Memo, MemoEntry;

import std.stdio : writeln;
import std.algorithm : sort, splitter, until;
import std.typecons : Tuple;
import std.range : repeat, retro;
import std.conv : to;
import std.array : array;

mixin enableCompileTimeUnittest;


void reportParsing(string input, Memo memo)
{
    size_t[] positions = memo.keys;
    positions.sort();

    foreach (position; positions)
    {
        with (calcLineLineNumColumnNum(input, position))
        {
            writeln('='.repeat(32));
            writeln(lineNum, ": ", line);
            writeln(' '.repeat(lineNum.to!string().length + 2 + columnNum), "^");
        }

        string[] ruleNames = memo[position].keys;
        ruleNames.sort();

        foreach (ruleName; ruleNames)
        {
            MemoEntry memoEntry = memo[position][ruleName];

            if (memoEntry.parsingResult.success)
            {
                writeln(memoEntry.parsingResult.node.toAsciiTree());
            }
            else
            {
                writeln("+-", ruleName.retro().until('.').array().retro(), ": fail");
            }
        }
    }
}


Tuple!(string, "line", size_t, "lineNum", size_t, "columnNum") calcLineLineNumColumnNum(string input, size_t position)
in
{
    assert (position <= input.length);
}
body
{
    size_t lineNum = 1;
    size_t totalLength;

    foreach (line; input.splitter('\n'))
    {
        if (position < totalLength + line.length + 1)
        {
            return typeof(return)(line, lineNum, position - totalLength);
        }

        totalLength += line.length + 1;
        ++lineNum;
    }

    return typeof(return)();
}
unittest
{
    with (calcLineLineNumColumnNum("foo\nbar\nfoobar", 1))
    {
        assert (line == "foo");
        assert (lineNum == 1);
        assert (columnNum == 1);
    }

    with (calcLineLineNumColumnNum("foo\nbar\nfoobar", 3))
    {
        assert (line == "foo");
        assert (lineNum == 1);
        assert (columnNum == 3);
    }

    with (calcLineLineNumColumnNum("foo\nbar\nfoobar", 5))
    {
        assert (line == "bar");
        assert (lineNum == 2);
        assert (columnNum == 1);
    }
}
