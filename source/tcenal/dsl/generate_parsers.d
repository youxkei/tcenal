module tcenal.dsl.generate_parsers;

import parser_combinator.parse_tree_node : ParseTreeNode;
import parser_combinator.memo : Memo;
import tcenal.dsl.parsers : rules;

private string generate(ParseTreeNode node, string ruleName = "")
{
    string generated;

    switch (node.ruleName)
    {
        case "rules":
            foreach (i, child; node.children[0].children)
            {
                if (i)
                {
                    generated ~= "\n\n\n";
                }

                generated ~= child.generate();
            }
            break;

        case "rule":
            ruleName = node.children[0].children[0].children[0].value;
            generated  = "ParsingResult " ~ ruleName ~ "(alias ruleSelector)(string input, size_t position, ref Memo memo)\n";
            generated ~= "{\nreturn applyRule!(\n";
            generated ~= node.children[0].children[1].generate(ruleName);
            generated ~= "\n)(input, position, memo);\n}";
            break;

        case "choiceExpr":
            if (node.children[0].children.length == 1)
            {
                generated = node.children[0].children[0].generate(ruleName);
            }
            else
            {
                generated = "choice!(\n" ~ node.children[0].generate(ruleName) ~ "\n)";
            }
            break;

        case "sequenceExpr":
            if (node.children[0].children.length == 1)
            {
                generated = node.children[0].children[0].generate(ruleName);
            }
            else
            {
                generated = "sequence!(\n" ~ node.children[0].generate(ruleName) ~ "\n)";
            }
            break;

        case "prefixExpr":
            if (node.children[0].ruleName == "#sequence")
            {
                switch (node.children[0].children[0].value)
                {
                    case "&":
                        generated = "andPred!(\n" ~ node.children[0].children[1].generate(ruleName) ~ "\n)";
                        break;

                    case "!":
                        generated = "notPred!(\n" ~ node.children[0].children[1].generate(ruleName) ~ "\n)";
                        break;

                    default:
                        assert (0);
                }
            }
            else
            {
                generated = node.children[0].generate(ruleName);
            }
            break;

        case "postfixExpr":
            if (node.children[0].ruleName == "#sequence")
            {
                switch (node.children[0].children[1].value)
                {
                    case "*":
                        generated = "zeroOrMore!(\n" ~ node.children[0].children[0].generate(ruleName) ~ "\n)";
                        break;

                    case "+":
                        generated = "oneOrMore!(\n" ~ node.children[0].children[0].generate(ruleName) ~ "\n)";
                        break;

                    case "?":
                        generated = "option!(\n" ~ node.children[0].children[0].generate(ruleName) ~ "\n)";
                        break;

                    default:
                        assert (0);
                }
            }
            else
            {
                generated = node.children[0].generate(ruleName);
            }
            break;

        case "identifier":
            if (node.children[0].value == "super")
            {
                generated = "skip!(ruleSelector!(\"" ~ ruleName ~ "\", true))";
            }
            else
            {
                generated = "skip!(ruleSelector!\"" ~ node.children[0].value ~ "\")";
            }
            break;

        case "stringLiteral":
            generated = "skip!(toToken!\"" ~ node.children[0].value ~ "\")";
            break;

        case "primaryExpr":
            generated = node.children[0].generate(ruleName);
            break;

        case "#repeat":
            foreach (i, child; node.children)
            {
                if (i)
                {
                    generated ~= ",\n";
                }

                generated ~= child.generate(ruleName);
            }
            break;

        default:
            assert (0);
    }

    return generated;
}


string generateParsers(string src)
{
    Memo memo;

    return src.rules(0, memo).node.generate();
}
