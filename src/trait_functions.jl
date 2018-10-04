macro define_traitfn(trait,traitfndef)
    !(@capture(trait,Trait_Symbol)) && error("Please provide a trait to dispatch on")
    (fndef, impls) = @match traitfndef begin
        fn_(args__) => (:($traitfndef = begin end),Expr(:block))
        fn_(args__) where wargs__ => (:($traitfndef = begin end),Expr(:block))
        (fndef_ = body_) => (:($fndef = begin end),block(prettify(body)))
    end
    # Match function definition
    traitfn_def_split = try
        splitdef(fndef)
    catch er
        error("Invalid trait function syntax. Parser says: ", er.msg)
    end
    isempty(traitfn_def_split[:args]) && error("No arguments to (trait)dispatch on")

    # Almost the same definition will be used to implement the NullTrait- and NotImplemented behaviour
    nulltrait_split = deepcopy(traitfn_def_split)
    noimplement_split = deepcopy(traitfn_def_split)

    impltraits = Symbol[]
    if !isempty(impls.args)
        for (i,fnimpl) in enumerate(impls.args)
            (fn,args,wparams,impltrait) = @match fnimpl begin
                (fn_(args__,trait_) = body_) => (fn,args,[],trait)
                (fn_(args__,trait_) where wparams__ = body_) => (fn,args,wparams,trait)
                (function fn_(args__,trait_)
                    body_
                 end) => (fn,args,[],trait)
                (function fn_(args__,trait_) where wparams__
                    body_
                end) => (fn,args,wparams,trait)
                _ => error("Syntax error in implementation list. Provide function implementations with the trait as last argument.")
            end
            if isa(impltrait,Expr)
                if impltrait.head == :call && impltrait.args[1] == :! && impltrait.args[2] == trait
                    impltrait = :NullTrait
                    if !isempty(wparams)
                        impls.args[i].args[1].args[1].args[end] = :NullTrait
                    else
                        impls.args[i].args[1].args[end] = :NullTrait
                    end
                else
                    error("Syntax error in last argument of implementation list. Use !Trait to specify that the function is implemented for types that do not implement Trait.")
                end
            end
            isempty(args) && error("Syntax error in implementation list. Provide function implementations with the trait as last argument.")
            length(args) < 1 && error("Syntax error in implementation list. Provide function implementations with the trait as last argument.")
            !isa(impltrait,Symbol) && error("Syntax error in last argument of implementation list. Specify for which trait the function is being implemented as last argument.")
            fn != traitfn_def_split[:name] && error("Name of implemented function does not match defined function.")
            !(all(args .== traitfn_def_split[:args])) && error("Inconsistent arguments in definition and implementation, in function ", traitfn_def_split[:name])
            if !isempty(wparams)
                !(all(wparams .== traitfn_def_split[:whereparams])) && error("Inconsistent where parameters in definition and implementation, in function ",traitfn_def_split[:name])
            end
            push!(impltraits,impltrait)
        end
    end

    # Prepare the lhs of the traitfn def.
    parname = prepare_dispatchparameter!(traitfn_def_split)

    # Change rhs of traitfn definition to trait dispatch call
    rhs = Expr(:block)
    push!(rhs.args,:(Base.@_inline_meta()))
    call = Expr(:call)
    push!(call.args,traitfn_def_split[:name])
    append!(call.args,[isa(arg,Symbol) ? arg : arg.args[1] for arg in traitfn_def_split[:args]])
    traitpick = @q begin
        TraitDispatch.traitdispatch($trait{$parname})
    end
    push!(call.args,traitpick)
    push!(rhs.args,call)
    traitfn_def_split[:body] = rhs

    # Construct the traitfn definition
    traitfn_def = combinecall(traitfn_def_split)

    # Finish NullTrait implementation with NullTrait dispatch
    push!(nulltrait_split[:args],:NullTrait)
    nulltrait_split[:body] = :(error($(nulltrait_split[:args][1])," has no applicable traits"))
    nulltrait_impl = combinecall(nulltrait_split)

    # Finish NotImplemented implementation with dispatch on parent trait
    push!(noimplement_split[:args],:($trait))
    noimplement_split[:body] = :(error("Trait function ",$(traitfn_def_split[:name])," not implemented for trait ",Trait.name))
    noimplement_impl = combinecall(noimplement_split)

    # Construct the definition code, with sanity checks
    code = @q begin
        # Sanity checks
        $(esc(trait)) == AbstractTrait && error("Cannot define trait function for the AbstractTrait")
        $(esc(trait)) == NullTrait && error("Cannot define trait function for the NullTrait")
        !($(esc(trait)) <: AbstractTrait) && error($(esc(trait))," is not a trait")
        # Definition
        $(esc(traitfn_def))
    end
    # Provided implementations
    for traitfn_impl in impls.args
        push!(code.args,esc(:(@implement_traitfn $traitfn_impl)))
    end
    # Default implementations
    if !(:NullTrait in impltraits)
        push!(code.args,esc(:(@implement_traitfn $nulltrait_impl)))
    end
    if !(trait in impltraits)
        push!(code.args,esc(@q begin
            if !isempty(subtraits($trait))
                @implement_traitfn $noimplement_impl
            end
        end))
    end
    prettify(code)
end

macro implement_traitfn(fndef)
    # Match function definition
    traitfn_impl_split = try
        splitdef(fndef)
    catch er
        error("Invalid trait function syntax. Parser says: ", er.msg)
    end
    isempty(traitfn_impl_split[:args]) && error("No arguments to (trait)dispatch on")
    length(traitfn_impl_split[:args]) == 1 && error("Provide at least one argument to trait dispatch on, and one trait")
    trait = pop!(traitfn_impl_split[:args])

    # Prepare the lhs of the traitfn impl.
    parname = prepare_dispatchparameter!(traitfn_impl_split)

    # Finish the lhs of the traitfn implementation, by adding TraitDispatch
    push!(traitfn_impl_split[:args],:(::Type{Trait}))
    traitfn_impl_split[:whereparams] = (traitfn_impl_split[:whereparams]...,:(Trait <: $trait{$parname}))

    # Construct the traitfn definition
    traitfn_impl = combinecall(traitfn_impl_split)

    # Construct the definition code, with sanity checks
    code = @q begin
        # Sanity checks
        $(esc(trait)) == AbstractTrait && error("Cannot implement trait function for the AbstractTrait")
        $(esc(trait)) != NullTrait && !($(esc(trait)) <: AbstractTrait) && error($(esc(trait))," is not a trait. Provide a trait as the final argument")

        # Implementation
        $(esc(traitfn_impl))
    end
    prettify(code)
end

function prepare_dispatchparameter!(fn_split::Dict)
    # Prepare the argument x that will be subjected to trait dispatch
    first_arg = fn_split[:args][1]
    x,x_type = @capture(first_arg,x_::T_) ? (x,T) : (first_arg,:none)

    # Make sure parameter restriction matches type restriction on x
    parname = :T
    if x_type == :none
        fn_split[:whereparams] = tuple(fn_split[:whereparams]...,:T)
    else
        if isempty(fn_split[:whereparams])
            fn_split[:whereparams] = tuple(fn_split[:whereparams]...,:(T <: $x_type))
        else
            if !(x_type ∈ fn_split[:whereparams])
                if !any(map(wparam -> @capture(wparam,T_ <: types_) && x_type == T,fn_split[:whereparams]))
                    fn_split[:whereparams] = tuple(fn_split[:whereparams]...,:(VarType <: $x_type))
                    parname = :VarType
                end
            end
        end
    end
    fn_split[:args][1] = :($x::$parname)

    parname
end

function combinecall(dict::Dict)
    params = get(dict, :params, [])
    wparams = get(dict, :whereparams, [])
    name = dict[:name]
    name_param = isempty(params) ? name : :($name{$(params...)})
    if isempty(wparams)
        :(function $name_param($(dict[:args]...);$(dict[:kwargs]...))
          $(dict[:body])
          end)
    else
        :(function $name_param($(dict[:args]...);$(dict[:kwargs]...)) where {$(wparams...)}
          $(dict[:body])
          end)
    end
end
