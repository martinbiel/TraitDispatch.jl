macro define_trait(args...)
    length(args) > 2 && error("Define either a single trait or a trait with subtraits")
    !isa(args[1],Symbol) && error("First argument must be the trait")
    code =  quote
        abstract type $(esc(args[1])) <: AbstractTrait end
        $(esc(args[1]))(::Type{$(esc(:T))}) where $(esc(:T)) = NullTrait
    end
    if length(args) == 1
        return code
    end
    (!isa(args[2],Expr) || args[2].head != :block) && error("Subtraits must be defined in a begin end block")
    for subtraitexpr in args[2].args
        if isa(subtraitexpr,Symbol)
            code = quote
                $code
                abstract type $(esc(subtraitexpr)) <: $(esc(args[1])) end
            end
        end
    end
    return code
end

# Add single trait
macro implement_trait(x,trait)
    quote
        # Sanity checks
        !isa($x,DataType) && error("Can only give traits to types")
        $(esc(trait)) == AbstractTrait && error("Cannot give the AbstractTrait")
        $(esc(trait)) == NullTrait && error("Cannot give the NullTrait")
        !($(esc(trait)) <: AbstractTrait) && error($(esc(trait))," is not a trait")
        supertype($(esc(trait))) != AbstractTrait && error($(esc(trait))," is a subtrait and must be given along with its parent traits")
        !isleaftrait($(esc(trait))) && error("Trait must be a leaf trait, ",$(esc(trait))," has subtraits: ",[@sprintf("%s ",t) for t in subtraits($(esc(trait)))]...)
        if hastrait($x,$(esc(trait)))
            warn($x," already has trait ",$(esc(trait)),", ignoring.")
        else
            @_traitconstructor($x,$(esc(trait)),$(esc(trait)))
        end
    end
end

macro implement_trait(x,trait,subtrait)
    quote
        # Sanity checks
        !isa($x,DataType) && error("Can only give traits to types")
        $(esc(trait)) == AbstractTrait && error("Cannot give the AbstractTrait")
        $(esc(subtrait)) == AbstractTrait && error("Cannot give the AbstractTrait")
        $(esc(trait)) == NullTrait && error("Cannot give the NullTrait")
        $(esc(subtrait)) == NullTrait && error("Cannot give the NullTrait")
        !($(esc(trait)) <: AbstractTrait) && error($(esc(trait))," is not a trait")
        !($(esc(subtrait)) <: AbstractTrait) && error($(esc(subtrait))," is not a trait")
        !($(esc(subtrait)) <: $(esc(trait))) && error($(esc(subtrait))," is not a subtrait of ",$(esc(trait)))
        if hastrait($x,$(esc(trait)))
            warn($x," already has trait ",$(esc(trait)),", ignoring.")
        else
            @_traitconstructor($x,$(esc(trait)),$(esc(subtrait)))
        end
    end
end

macro _traitconstructor(x,traitdef,traitval)
    quote
        if isleaftype($x)
            $(esc(traitdef))(::Type{$x}) = $(esc(traitval))
        else
            $(esc(traitdef))(::Type{$(esc(:T))}) where $(esc(:T)) <: $x = $(esc(traitval))
        end
    end
end
