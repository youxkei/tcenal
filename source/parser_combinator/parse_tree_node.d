module parser_combinator.parse_tree_node;

import std.algorithm : map, joiner;
import std.conv : to;
import std.range : repeat;

struct ParseTreeNode
{
    string value;
    ParseTreeNode[] children;
    string ruleName;

    string toAsciiTree(string indent = "", bool isLast = true)
    {
        if (value.length > 0)
        {
            return indent ~ "+-\"" ~ value ~ "\"\n";
        }

        string result;

        if (ruleName.length > 0)
        {
            result ~= indent ~ "+-" ~ ruleName ~ "\n";
        }
        else
        {
            result ~= indent ~ "+\n";
        }

        foreach (i, child; children)
        {
            if (isLast)
            {
                result ~= child.toAsciiTree(indent ~ "  ", i == children.length - 1);
            }
            else
            {
                result ~= child.toAsciiTree(indent ~ "| ", i == children.length - 1);
            }
        }

        return result;
    }

    alias toString = toAsciiTree;
}
