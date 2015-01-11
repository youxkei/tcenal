module tcenal.rule_selector;

template apply(alias template_, args...)
{
    alias apply = template_!args;
}

template createRuleSelector(string module_ = __MODULE__)
{
    template RuleSelector(string rule, bool isSuper = false)
    {
        mixin ("static import " ~ module_ ~ ";");
        static import tcenal.dparsers;

        static if (isSuper || !__traits(compiles, mixin (module_ ~ "." ~ rule)))
        {
            alias RuleSelector = apply!(mixin ("tcenal.dparsers." ~ rule), createRuleSelector!module_.RuleSelector);
        }
        else
        {
            alias RuleSelector = apply!(mixin (module_ ~ "." ~ rule), createRuleSelector!module_.RuleSelector);
        }
    }
}
