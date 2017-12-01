module TraitDispatch

using MacroTools
using MacroTools: postwalk

export
    @define_trait,
    @define_subtrait,
    @define_traitfn,
    @implement_traitfn,
    @implement_trait,
    istrait,
    isleaftrait,
    subtraits,
    hastrait,
    hastraits,
    traits


abstract type AbstractTrait end
abstract type NullTrait end

include("trait_definition.jl")
include("trait_functions.jl")
include("trait_utils.jl")

end # module
