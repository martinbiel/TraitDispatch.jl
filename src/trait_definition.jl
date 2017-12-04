macro define_trait(args)
    def = if @capture(args, trait_Symbol)
        prettify(@q begin
            abstract type $(esc(trait)) <: AbstractTrait end
            $(esc(trait))(::Type{$(esc(:T))}) where $(esc(:T)) = NullTrait
        end)
    elseif @capture(args, trait_Symbol = block_)
        code = @q begin
            abstract type $(esc(trait)) <: AbstractTrait end
            $(esc(trait))(::Type{$(esc(:T))}) where $(esc(:T)) = NullTrait
        end
        for ex in rmlines(block).args
            if @capture(ex,subtrait_Symbol)
                push!(code.args,unblock(@q begin
                                        abstract type $(esc(subtrait)) <: $(esc(trait)) end
                                        end
                                        ))
            elseif @capture(ex,f_(x__)) || @capture(ex,f_(x__) = body_)
                push!(code.args,:(@define_traitfn($(esc(trait)),$(esc(ex)))))
            else
                error("Expected subtrait or traitfn definition, got ", ex)
            end
        end
        prettify(code)
    elseif @capture(args, subtrait_Symbol <: trait_Symbol)
        prettify(@q begin
            !($(esc(trait)) <: AbstractTrait) && error($(esc(trait))," is not a trait")
            $(esc(trait)) == NullTrait && error("The NullTrait can not have subtraits")
            supertype($(esc(trait))) != AbstractTrait && error($(esc(trait))," is a subtrait and can not be given subtraits")
            abstract type $(esc(subtrait)) <: $(esc(trait)) end
        end)
    end
end


macro implement_trait(x,trait)
    prettify(@q begin
        # Sanity checks
        !(isa($x,DataType) || isa($x,UnionAll)) && error("Can only give traits to types")
        $(esc(trait)) == AbstractTrait && error("Cannot give the AbstractTrait")
        $(esc(trait)) == NullTrait && error("Cannot give the NullTrait")
        !($(esc(trait)) <: AbstractTrait) && error($(esc(trait))," is not a trait")
        supertype($(esc(trait))) != AbstractTrait && error($(esc(trait))," is a subtrait and must be given along with its parent traits")
        !isleaftrait($(esc(trait))) && error("Trait must be a leaf trait, ",$(esc(trait))," has subtraits: ",[@sprintf("%s ",t) for t in subtraits($(esc(trait)))]...)
        if implementstrait($x,$(esc(trait)))
            warn($x," already has trait ",$(esc(trait)),", ignoring.")
        else
            @_traitconstructor($x,$(esc(trait)),$(esc(trait)))
        end
    end)
end

macro implement_trait(x,trait,subtrait)
    prettify(@q begin
        # Sanity checks
        !(isa($x,DataType) || isa($x,UnionAll)) && error("Can only give traits to types")
        $(esc(trait)) == AbstractTrait && error("Cannot give the AbstractTrait")
        $(esc(subtrait)) == AbstractTrait && error("Cannot give the AbstractTrait")
        $(esc(trait)) == NullTrait && error("Cannot give the NullTrait")
        $(esc(subtrait)) == NullTrait && error("Cannot give the NullTrait")
        !($(esc(trait)) <: AbstractTrait) && error($(esc(trait))," is not a trait")
        !($(esc(subtrait)) <: AbstractTrait) && error($(esc(subtrait))," is not a trait")
        !($(esc(subtrait)) <: $(esc(trait))) && error($(esc(subtrait))," is not a subtrait of ",$(esc(trait)))
        if implementstrait($x,$(esc(trait)))
            warn($x," already has trait ",$(esc(trait)),", ignoring.")
        else
            @_traitconstructor($x,$(esc(trait)),$(esc(subtrait)))
        end
    end)
end

macro _traitconstructor(x,traitdef,traitval)
    @q begin
        if isleaftype($x)
            $(esc(traitdef))(::Type{$x}) = $(esc(traitval))
        else
            $(esc(traitdef))(::Type{$(esc(:T))}) where $(esc(:T)) <: $x = $(esc(traitval))
        end
    end
end
