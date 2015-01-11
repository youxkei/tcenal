module parser_combinator.parsing_result;

import parser_combinator.parse_tree_node;

struct ParsingResult
{
    bool success;
    size_t nextPosition;
    ParseTreeNode node;
}
