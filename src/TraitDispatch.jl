module TraitDispatch

using MacroTools
using MacroTools: postwalk, @q, combinedef

export
    AbstractTrait,
    NullTrait,
    @define_trait,
    @implement_trait,
    @define_traitfn,
    @implement_traitfn,
    istrait,
    isleaftrait,
    subtraits,
    hastrait,
    hastraits,
    implementstrait,
    implementstraits,
    notraits,
    traits


abstract type AbstractTrait{T} end
abstract type NullTrait{T} end
traitdispatch(::Type{Trait}) where {T,Trait<:AbstractTrait{T}} = NullTrait{T}

include("trait_functions.jl")
include("trait_definition.jl")
include("trait_utils.jl")

end # module
