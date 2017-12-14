istrait(::Type{T}) where T = false
istrait(::Type{Trait}) where Trait <: AbstractTrait = true

isleaftrait(::Type{T}) where T = false
isleaftrait(::Type{Trait}) where Trait <: AbstractTrait = isempty(subtraits(Trait))
isleaftrait(::Type{AbstractTrait{T}}) where T = false
isleaftrait(::Type{NullTrait{T}}) where T = false

subtraits(::Type{T}) where T = DataType[]
subtraits(::Type{Trait}) where Trait <: AbstractTrait = Vector{UnionAll}(subtypes(Trait))

function hastrait(x,::Type{T}) where T
    info(T, " is not a trait")
    return false
end
hastrait(x::T,::Type{Trait}) where {T, Trait <: AbstractTrait} = traitdispatch(Trait{T}) != NullTrait{T}
hastrait(x::T,::Type{AbstractTrait{T}}) where T = false
hastrait(x::T,::Type{NullTrait{T}}) where T = NullTrait{T} ∈ traits(x)
hastraits(x,traits...) = all(map(trait -> hastrait(x,trait),[traits...]))
hastraits(x::T) where T = !hastrait(x,NullTrait{T})

function implementstrait(x,::Type{T}) where T
    info(T, " is not a trait")
    return false
end
implementstrait(::Type{T},::Type{Trait}) where {T, Trait <: AbstractTrait} = traitdispatch(Trait{T}) != NullTrait{T}
implementstrait(::Type{T},::Type{AbstractTrait{T}}) where T = false
implementstrait(::Type{T},::Type{NullTrait{T}}) where T = NullTrait{T} ∈ traits(x)
implementstraits(x,traits...) = all(map(trait -> hastrait(x,trait),[traits...]))
implementstraits(x::Type{T}) where T = !implementstrait(x,NullTrait{T})

notraits(x) = !hastraits(x)
notraits(x::Type{T}) where T = !implementstraits(x)

traits() = subtraits(AbstractTrait)
function traits(x::T) where T
    traitlist = _traits(x,AbstractTrait)
    if isempty(traitlist)
        return [NullTrait{T}]
    else
        return traitlist
    end
end

function _traits(x::T,::Type{Trait}) where {T, Trait <: AbstractTrait}
    traitlist = Vector{UnionAll}()
    if hastrait(x,Trait)
        push!(traitlist,Trait)
    end
    subtraits = Vector{UnionAll}(subtypes(Trait))
    if isempty(subtraits)
        return traitlist
    else
        for subtrait in subtraits
            append!(traitlist,_traits(x,subtrait))
        end
    end
    return traitlist
end
