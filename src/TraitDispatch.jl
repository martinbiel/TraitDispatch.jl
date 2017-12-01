module TraitDispatch

using MacroTools
using MacroTools: postwalk

export
    @define_trait,
    @implement_trait,
    @define_traitfn,
    @implement_traitfn,
    istrait,
    isleaftrait,
    subtraits,
    hastrait,
    hastraits,
    notraits,
    traits


abstract type AbstractTrait end
abstract type NullTrait end

include("trait_definition.jl")
include("trait_functions.jl")
include("trait_utils.jl")

end # module
