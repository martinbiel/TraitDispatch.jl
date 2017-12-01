istrait(::Type{T}) where T = false
istrait(::Type{T}) where T <: AbstractTrait = true

isleaftrait(::Type{T}) where T <: AbstractTrait = isempty(subtraits(T))
isleaftrait(::Type{AbstractTrait}) = false
isleaftrait(::Type{NullTrait}) = false

subtraits(::Type{T}) where T <: AbstractTrait = Vector{DataType}(subtypes(T))

function hastrait(x,::Type{T}) where T
    info(T, " is not a trait")
    return false
end
function hastrait(::Type{S},::Type{T}) where {S, T <: AbstractTrait}
    if supertype(T) == AbstractTrait
        return T(S) != NullTrait
    else
        return supertype(T)(S) == T
    end
end
hastrait(x,::Type{AbstractTrait}) = false
hastrait(x,::Type{NullTrait}) = NullTrait ∈ traits(x)
hastraits(x,traits...) = all(map(trait -> hastrait(x,trait),[traits...]))
hastraits(x) = !hastrait(x,NullTrait)

notraits(x) = !hastraits(x)

traits() = subtraits(AbstractTrait)
function traits(x)
    traitlist = _traits(x,AbstractTrait)
    if isempty(traitlist)
        return [NullTrait]
    else
        return traitlist
    end
end

function _traits(x,::Type{T}) where T <: AbstractTrait
    traitlist = Vector{DataType}()
    if hastrait(x,T)
        push!(traitlist,T)
    end
    subtraits = Vector{DataType}(subtypes(T))
    if isempty(subtraits)
        return traitlist
    else
        for subtrait in subtraits
            append!(traitlist,_traits(x,subtrait))
        end
    end
    return traitlist
end
