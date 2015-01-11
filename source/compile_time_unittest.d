module compile_time_unittest;

mixin template enableCompileTimeUnittest(string module_ = __MODULE__)
{
    static assert(
    {
        foreach(test; __traits(getUnitTests, mixin(module_)))
        {
            test();
        }
        return true;
    }());
}
