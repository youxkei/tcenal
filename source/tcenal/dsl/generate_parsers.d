module tcenal.dsl.generate_parsers;

import tcenal.parser_combinator.parse_tree_node : ParseTreeNode;
import tcenal.parser_combinator.memo : Memo;
import tcenal.dsl.lexer : lex;
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
            ruleName = node.children[0].children[0].token.value;
            generated  = "ParsingResult " ~ ruleName ~ "(alias ruleSelector)(Token[] input, size_t position, ref Memo memo)\n";
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
            if (node.children[0].ruleName == "#sequence" && node.children[0].children[0].token.type == "")
            {
                switch (node.children[0].children[0].token.value)
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
            if (node.children[0].ruleName == "#sequence" && node.children[0].children[1].token.type == "")
            {
                switch (node.children[0].children[1].token.value)
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

        case "primaryExpr":
            generated = node.children[0].generate(ruleName);
            break;

        case "ruleName":
            if (node.children[0].token.type == "" && node.children[0].token.value == "super")
            {
                generated = "ruleSelector!(\"" ~ ruleName ~ "\", true)";
            }
            else
            {
                generated = "ruleSelector!\"" ~ node.children[0].token.value ~ "\"";
            }
            break;

        case "tokenValue":
            generated = "parseToken!\"" ~ node.children[0].token.value ~ "\"";
            break;

        case "tokenType":
            generated = "parseTokenWithType!\"" ~ node.children[0].token.value ~ "\"";
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
            assert(false, node.toString());
    }

    return generated;
}


string generateParsers(string src)
{
    Memo memo;

    return src.lex().rules(0, memo).node.generate();
}
