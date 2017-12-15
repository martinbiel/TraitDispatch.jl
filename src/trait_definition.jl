macro define_trait(args)
    def = if @capture(args, trait_Symbol)
        trait == :AbstractTrait && error("Can not redefine the AbstractTrait")
        trait == :NullTrait && error("Can not redefine the NullTrait")
        @q begin
            abstract type $(esc(trait)){$(esc(:T))} <: AbstractTrait{$(esc(:T))} end
        end
    elseif @capture(args, trait_Symbol = block_)
        trait == :AbstractTrait && error("Can not redefine the AbstractTrait")
        trait == :NullTrait && error("Can not redefine the NullTrait")
        code = @q begin
            abstract type $(esc(trait)){$(esc(:T))} <: AbstractTrait{$(esc(:T))} end
        end
        for ex in rmlines(block).args
            if @capture(ex,subtrait_Symbol)
                subtrait == :AbstractTrait && error("Can not redefine the AbstractTrait")
                subtrait == :NullTrait && error("Can not redefine the NullTrait")
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
        subtrait == :AbstractTrait && error("Can not redefine the AbstractTrait")
        subtrait == :NullTrait && error("Can not redefine the NullTrait")
        @q begin
            $(esc(trait)) == NullTrait && error("The NullTrait can not have subtraits")
            !($(esc(trait)) <: AbstractTrait) && error($(esc(trait))," is not a trait")
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
        !isleaftrait($(esc(trait))) && error("Trait must be a leaf trait, ",$(esc(trait))," has subtraits: ",[@sprintf("%s ",t) for t in subtraits($(esc(trait)))]...)
        if implementstrait($(esc(x)),$(esc(trait)))
            warn($(esc(x))," already has trait ",$(esc(trait)),", ignoring.")
        elseif implementstrait($(esc(x)),$(esc(supertype))($(esc(trait))))
            warn($(esc(x))," already has parent trait ",$(esc(supertype))($(esc(trait))).body.name,", ignoring.")
        else
            $(esc(:TraitDispatch)).traitdispatch(::Type{$(esc(trait)){$(esc(:T))}}) where $(esc(:T)) <: $(esc(x)) = $(esc(trait)){$(esc(:T))}
            super = $(esc(supertype))($(esc(trait)))
            if super != AbstractTrait
                $(esc(:TraitDispatch)).traitdispatch(::Type{super{$(esc(:T))}}) where $(esc(:T)) <: $(esc(x)) = $(esc(trait)){$(esc(:T))}
            end
        end
        nothing
    end
    prettify(code)
end
