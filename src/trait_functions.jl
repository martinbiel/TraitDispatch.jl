macro define_traitfn(args...)
    length(args) != 2 && error("Give a trait and function signature")
    !isa(args[1],Symbol) && error("First argument must be the trait")
    !(args[2].head == :call || args[2].head == :(=)) && error("Second argument must be the function signature, possibly with a default implementation")

    trait = args[1]
    func_signature = args[2].head == :call ? args[2] : args[2].args[1]
    fun_name = esc(func_signature.args[1])
    first_arg = func_signature.args[2]
    default_impl = if args[2].head == :(=)
        args[2].args[2]
    else
        :(error($first_arg," has no applicable traits"))
    end

    trait_function_LHS = Expr(:where)
    funcall = Expr(:call)
    push!(funcall.args,fun_name)
    typechange = Expr(:(::))
    push!(typechange.args,first_arg)
    push!(typechange.args,esc(:T))
    push!(funcall.args,typechange)
    push!(trait_function_LHS.args,funcall)
    push!(trait_function_LHS.args,esc(:T))

    trait_function_RHS = Expr(:call)
    push!(trait_function_RHS.args,fun_name)
    push!(trait_function_RHS.args,first_arg)
    traitpick = Expr(:call)
    push!(traitpick.args,esc(trait))
    push!(traitpick.args,esc(:T))
    push!(trait_function_RHS.args,traitpick)

    quote
        $(esc(trait)) == AbstractTrait && error("Cannot define trait function for the AbstractTrait")
        $(esc(trait)) == NullTrait && error("Cannot define trait function for the NullTrait")
        !($(esc(trait)) <: AbstractTrait) && error($(esc(trait))," is not a trait")
        (supertype($(esc(trait))) != AbstractTrait && leaftrait($(esc(trait)))) && error("Trait function must be defined for the parent trait. ", $(esc(trait))," has parent ",supertype($(esc(trait))))
        $trait_function_LHS = $trait_function_RHS

        $fun_name($first_arg,::Type{NullTrait}) = $default_impl
    end
end
