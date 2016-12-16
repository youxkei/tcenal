module tcenal.util;

auto allowRvalue(alias f, Args...)(Args args)
{
    return f(args);
}
