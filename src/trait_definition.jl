macro define_trait(args)
    def = if @capture(args, trait_Symbol)
        @q begin
            abstract type $(esc(trait)) <: AbstractTrait end
            $(esc(trait))(::Type{$(esc(:T))}) where $(esc(:T)) = NullTrait
        end
    elseif @capture(args, trait_Symbol = subtraits_)
        code = @q begin
            abstract type $(esc(trait)) <: AbstractTrait end
            $(esc(trait))(::Type{$(esc(:T))}) where $(esc(:T)) = NullTrait
        end
        for ex in rmlines(subtraits).args
            @capture(ex,subtrait_Symbol) || error("Expected subtrait symbol, got ", ex)
            push!(code.args,unblock(@q begin
                  abstract type $(esc(subtrait)) <: $(esc(trait)) end
                  end
                  ))
        end
        code
    elseif @capture(args, subtrait_Symbol <: trait_Symbol)
        @q begin
            !($(esc(trait)) <: AbstractTrait) && error($(esc(trait))," is not a trait")
            $(esc(trait)) == NullTrait && error("The NullTrait can not have subtraits")
            supertype($(esc(trait))) != AbstractTrait && error($(esc(trait))," is a subtrait and can not be given subtraits")
            abstract type $(esc(subtrait)) <: $(esc(trait)) end
        end
    end
end


macro implement_trait(x,trait)
    @q begin
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
            unblock(@_traitconstructor($x,$(esc(trait)),$(esc(trait))))
        end
    end
end

macro implement_trait(x,trait,subtrait)
    @q begin
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
            unblock(@_traitconstructor($x,$(esc(trait)),$(esc(subtrait))))
        end
    end
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
