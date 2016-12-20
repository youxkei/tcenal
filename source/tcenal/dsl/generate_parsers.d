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
            generated  = "tcenal.parser_combinator.parsing_result.ParsingResult " ~ ruleName ~ "(alias ruleSelector)(tcenal.parser_combinator.token.Token[] input, size_t position, ref tcenal.parser_combinator.memo.Memo memo)\n";
            generated ~= "{\nreturn tcenal.parser_combinator.combinators.applyRule!(\n";
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
                generated = "tcenal.parser_combinator.combinators.choice!(\n" ~ node.children[0].generate(ruleName) ~ "\n)";
            }
            break;

        case "sequenceExpr":
            if (node.children[0].children.length == 1)
            {
                generated = node.children[0].children[0].generate(ruleName);
            }
            else
            {
                generated = "tcenal.parser_combinator.combinators.sequence!(\n" ~ node.children[0].generate(ruleName) ~ "\n)";
            }
            break;

        case "prefixExpr":
            if (node.children[0].ruleName == "#sequence" && node.children[0].children[0].token.type == "")
            {
                switch (node.children[0].children[0].token.value)
                {
                    case "&":
                        generated = "tcenal.parser_combinator.combinators.andPred!(\n" ~ node.children[0].children[1].generate(ruleName) ~ "\n)";
                        break;

                    case "!":
                        generated = "tcenal.parser_combinator.combinators.notPred!(\n" ~ node.children[0].children[1].generate(ruleName) ~ "\n)";
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
                        generated = "tcenal.parser_combinator.combinators.zeroOrMore!(\n" ~ node.children[0].children[0].generate(ruleName) ~ "\n)";
                        break;

                    case "+":
                        generated = "tcenal.parser_combinator.combinators.oneOrMore!(\n" ~ node.children[0].children[0].generate(ruleName) ~ "\n)";
                        break;

                    case "?":
                        generated = "tcenal.parser_combinator.combinators.option!(\n" ~ node.children[0].children[0].generate(ruleName) ~ "\n)";
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
            generated = "tcenal.parser_combinator.combinators.parseTokenWithValue!\"" ~ node.children[0].token.value ~ "\"";
            break;

        case "tokenType":
            generated = "tcenal.parser_combinator.combinators.parseTokenWithType!\"" ~ node.children[0].token.value ~ "\"";
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
    enum preamble = q{
        static import tcenal.parser_combinator.token;
        static import tcenal.parser_combinator.memo;
        static import tcenal.parser_combinator.parsing_result;
        static import tcenal.parser_combinator.combinators;
    };

    Memo memo;

    return preamble ~ src.lex().rules(0, memo).node.generate();
}
