macro define_trait(args)
    def = if @capture(args, trait_Symbol)
        @q begin
            abstract type $(esc(trait)){$(esc(:T))} <: AbstractTrait{$(esc(:T))} end
        end
    elseif @capture(args, trait_Symbol = block_)
        code = @q begin
            abstract type $(esc(trait)){$(esc(:T))} <: AbstractTrait{$(esc(:T))} end
        end
        for ex in rmlines(block).args
            if @capture(ex,subtrait_Symbol)
                subcode = @q begin
                    abstract type $(esc(subtrait)){$(esc(:T))} <: $(esc(trait)){$(esc(:T))} end
                end
                push!(code.args,unblock(subcode))
            elseif @capture(ex,f_(x__)) || @capture(ex,f_(x__) = body_)
                push!(code.args,:(@define_traitfn($(esc(trait)),$(esc(ex)))))
            else
                error("Expected subtrait or traitfn definition, got ", ex)
            end
        end
        code
    elseif @capture(args, subtrait_Symbol <: trait_Symbol)
        @q begin
            $(esc(trait)) == NullTrait && error("The NullTrait can not have subtraits")
            !($(esc(trait)) <: AbstractTrait) && error($(esc(trait))," is not a trait")
            supertype($(esc(trait))) != AbstractTrait && error($(esc(trait))," is a subtrait and can not be given subtraits")
            abstract type $(esc(subtrait)){$(esc(:T))} <: $(esc(trait)){$(esc(:T))} end
        end
    end
    prettify(def)
end

macro implement_trait(x,trait)
    code = @q begin
        # Sanity checks
        !(isa($(esc(x)),DataType) || isa($(esc(x)),UnionAll)) && error("Can only give traits to types")
        ($(esc(x)) <: AbstractTrait) && error($(esc(x))," is a trait, and can not implement traits")
        $(esc(trait)) == AbstractTrait && error("Cannot give the AbstractTrait")
        $(esc(trait)) == NullTrait && error("Cannot give the NullTrait")
        !($(esc(trait)) <: AbstractTrait) && error($(esc(trait))," is not a trait")
        supertype($(esc(trait))) != AbstractTrait && error($(esc(trait))," is a subtrait and must be given along with its parent traits")
        !isleaftrait($(esc(trait))) && error("Trait must be a leaf trait, ",$(esc(trait))," has subtraits: ",[@sprintf("%s ",t) for t in subtraits($(esc(trait)))]...)
        if implementstrait($(esc(x)),$(esc(trait)))
            warn($(esc(x))," already has trait ",$(esc(trait)),", ignoring.")
        else
            $(esc(:TraitDispatch)).traitdispatch(::Type{$(esc(trait)){$(esc(:T))}}) where $(esc(:T)) <: $(esc(x)) = $(esc(trait)){$(esc(:T))}
        end
    end
    prettify(code)
end

macro implement_trait(x,trait,subtrait)
    code = @q begin
        # Sanity checks
        !(isa($(esc(x)),DataType) || isa($(esc(x)),UnionAll)) && error("Can only give traits to types")
        ($(esc(x)) <: AbstractTrait) && error($(esc(x))," is a trait, and can not implement traits")
        $(esc(trait)) == AbstractTrait && error("Cannot give the AbstractTrait")
        $(esc(subtrait)) == AbstractTrait && error("Cannot give the AbstractTrait")
        $(esc(trait)) == NullTrait && error("Cannot give the NullTrait")
        $(esc(subtrait)) == NullTrait && error("Cannot give the NullTrait")
        !($(esc(trait)) <: AbstractTrait) && error($(esc(trait))," is not a trait")
        !($(esc(subtrait)) <: AbstractTrait) && error($(esc(subtrait))," is not a trait")
        !($(esc(subtrait)) <: $(esc(trait))) && error($(esc(subtrait))," is not a subtrait of ",$(esc(trait)))
        if implementstrait($(esc(x)),$(esc(trait)))
            warn($(esc(x))," already has trait ",$(esc(trait)),", ignoring.")
        else
            $(esc(:TraitDispatch)).traitdispatch(::Type{$(esc(trait)){$(esc(:T))}}) where $(esc(:T)) <: $(esc(x)) = $(esc(subtrait)){$(esc(:T))}
            $(esc(:TraitDispatch)).traitdispatch(::Type{$(esc(subtrait)){$(esc(:T))}}) where $(esc(:T)) <: $(esc(x)) = $(esc(subtrait)){$(esc(:T))}
        end
    end
    prettify(code)
end
