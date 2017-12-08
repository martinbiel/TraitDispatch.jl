macro define_traitfn(trait,fndef,impl...)
    @capture(fndef,f_()) && error("Nothing to trait dispatch on")
    # Match arguments of type f(x) and f(x) = body
    fndef = (fndef.head == :call || fndef.head == :where) ? :($fndef = error($(fndef.args[2])," has no applicable traits")) : fndef
    traitfn_def_split = try
        splitdef(fndef)
    catch er
        error("Invalid trait function syntax. Parser says: ", er.msg)
    end

    # Maybe a parentimpl was provided
    traitfn_impl_split = if length(impl) > 1
        error("Too many arguments provided. Specify a trait, a trait function definition and possibly an implementation")
    else
        if length(impl) == 1
            traitfn_impl_split = try
                splitdef(impl[1])
            catch er
                error("Invalid trait function syntax. Parser says: ", er.msg)
            end
            traitfn_def_split[:name] != traitfn_impl_split[:name] && error("Trait function names are not consistent")
            traitfn_impl_split[:args][end] != trait && error("Specify clearly that ", traitfn_def_split[:name], " is being implemented for trait ", trait, " by specifying it as the last argument")
            pop!(traitfn_impl_split[:args])
            !(all(traitfn_def_split[:args] .== traitfn_impl_split[:args])) && error("Inconsistent trait function arguments")
            traitfn_impl_split
        else
            Dict()
        end
    end

    # Almost the same definition will be used to implement the NullTrait- and NotImplemented behaviour
    nulltrait_split = deepcopy(traitfn_def_split)
    noimplement_split = deepcopy(traitfn_def_split)

    # Prepare the argument x that will be subjected to trait dispatch
    first_arg = traitfn_def_split[:args][1]
    x,x_type = @capture(first_arg,x_::T_) ? (x,T) : (first_arg,:none)

    # Prepare the lhs of the traitfn def. Make sure parameter restriction match type restriction on x
    parname = :T
    if x_type == :none
        traitfn_def_split[:whereparams] = tuple(traitfn_def_split[:whereparams]...,:T)
    else
        if isempty(traitfn_def_split[:whereparams])
            traitfn_def_split[:whereparams] = tuple(traitfn_def_split[:whereparams]...,:(T <: $x_type))
        else
            if !(x_type ∈ traitfn_def_split[:whereparams])
                if !any(map(wparam -> @capture(wparam,T_ <: types_) && x_type == T,traitfn_def_split[:whereparams]))
                    traitfn_def_split[:whereparams] = tuple(traitfn_def_split[:whereparams]...,:(VarType <: $x_type))
                    parname = :VarType
                end
            end
        end
    end
    traitfn_def_split[:args][1] = :($x::$parname)

    # Change rhs of traitfn definition to trait dispatch call
    rhs = Expr(:call)
    push!(rhs.args,traitfn_def_split[:name])
    append!(rhs.args,[isa(arg,Symbol) ? arg : arg.args[1] for arg in traitfn_def_split[:args]])
    traitpick = Expr(:call)
    push!(traitpick.args,trait)
    push!(traitpick.args,parname)
    push!(rhs.args,traitpick)
    traitfn_def_split[:body] = rhs

    # Construct the traitfn definition
    traitfn_def = combinecall(traitfn_def_split)

    # Finish NullTrait implementation with NullTrait dispatch
    push!(nulltrait_split[:args],:(::Type{NullTrait}))
    nulltrait_impl = combinecall(nulltrait_split)

    # Finish NotImplemented implementation with dispatch on parent trait
    push!(noimplement_split[:args],:(::Type{TraitType}))
    noimplement_split[:whereparams] = (noimplement_split[:whereparams]...,:(TraitType <: $trait))
    noimplement_split[:body] = isempty(traitfn_impl_split) ? :(error("Trait function not implemented")) : traitfn_impl_split[:body]

    noimplement_impl = combinecall(noimplement_split)

    # Construct the definition code, with sanity checks
    prettify(@q begin
        # Sanity checks
        $(esc(trait)) == AbstractTrait && error("Cannot define trait function for the AbstractTrait")
        $(esc(trait)) == NullTrait && error("Cannot define trait function for the NullTrait")
        !($(esc(trait)) <: AbstractTrait) && error($(esc(trait))," is not a trait")
        (supertype($(esc(trait))) != AbstractTrait && isleaftrait($(esc(trait)))) && error("Trait function must be defined for the parent trait. ", $(esc(trait))," has parent ",supertype($(esc(trait))))
        # Definitions
        $(esc(traitfn_def))
        $(esc(nulltrait_impl))
        if !isempty(subtraits($(esc(trait))))
            $(esc(noimplement_impl))
        end
    end)
end

macro implement_traitfn(trait,fndef)
    @capture(fndef,f_()) && error("Nothing to trait dispatch on")
    # Match function definition
    traitfn_impl_split = try
        splitdef(fndef)
    catch er
        error("Invalid trait function syntax. Parser says: ", er.msg)
    end

    # Finish the lhs of the traitfn implementation, by adding TraitDispatch
    push!(traitfn_impl_split[:args],:(::Type{$trait}))

    # Construct the traitfn definition
    traitfn_impl = combinecall(traitfn_impl_split)

    # Construct the definition code, with sanity checks
    prettify(@q begin
        # Sanity checks
        $(esc(trait)) == AbstractTrait && error("Cannot implement trait function for the AbstractTrait")
        $(esc(trait)) == NullTrait && error("Cannot implement trait function for the NullTrait")
        !($(esc(trait)) <: AbstractTrait) && error($(esc(trait))," is not a trait")
        (supertype($(esc(trait))) == AbstractTrait && !isleaftrait($(esc(trait)))) && error("Trait function must be implemented for some child trait. ",$(esc(trait))," has subtraits: ",[@sprintf("%s ",t) for t in subtraits($(esc(trait)))]...)

        # Implementation
        $(esc(traitfn_impl))
    end)
end

function combinecall(dict::Dict)
  params = get(dict, :params, [])
  wparams = get(dict, :whereparams, [])
  name = dict[:name]
  name_param = isempty(params) ? name : :($name{$(params...)})
  if isempty(wparams)
    :($name_param($(dict[:args]...);$(dict[:kwargs]...)) = $(dict[:body]))
  else
    :($name_param($(dict[:args]...);$(dict[:kwargs]...)) where {$(wparams...)} = $(dict[:body]))
  end
end
