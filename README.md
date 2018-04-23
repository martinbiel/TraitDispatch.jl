# TraitDispatch

[![Build Status](https://travis-ci.org/martinbiel/TraitDispatch.jl.svg?branch=master)](https://travis-ci.org/martinbiel/TraitDispatch.jl)

[![Coverage Status](https://coveralls.io/repos/martinbiel/TraitDispatch.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/martinbiel/TraitDispatch.jl?branch=master)

[![codecov.io](http://codecov.io/github/martinbiel/TraitDispatch.jl/coverage.svg?branch=master)](http://codecov.io/github/martinbiel/TraitDispatch.jl?branch=master)

## Description

`TraitDispatch` extends the method dispatch functionality of the Julia programming language by allowing dispatch on traits. Its primary function is to simplify software design and reduce code repetition.

## Basic Usage

### Defining Scenarios

```julia
julia> using TraitDispatch

julia> StochasticPrograms.probability(s::SimpleScenario) = s.π

```

[MathProgBase]: https://github.com/JuliaOpt/MathProgBase.jl
[LShapedImpl]: https://github.com/martinbiel/LShapedSolvers.jl/blob/master/src/spinterface.jl


## Interfaces
