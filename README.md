# TraitDispatch

[![Build Status](https://travis-ci.org/martinbiel/TraitDispatch.jl.svg?branch=master)](https://travis-ci.org/martinbiel/TraitDispatch.jl)

[![Coverage Status](https://coveralls.io/repos/martinbiel/TraitDispatch.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/martinbiel/TraitDispatch.jl?branch=master)

[![codecov.io](http://codecov.io/github/martinbiel/TraitDispatch.jl/coverage.svg?branch=master)](http://codecov.io/github/martinbiel/TraitDispatch.jl?branch=master)

## Description

`TraitDispatch` extends the method dispatch functionality of the Julia programming language through dispatch on traits. Its primary function is to simplify software design and reduce code repetition. The module bares many similarities to [SimpleTraits.jl][SimpleTraits], but with differing syntax and the ability to specify subtraits. It was developed as an auxilliary module during the development of [LShapedSolvers.jl][LShaped].

[SimpleTraits]: https://github.com/mauro3/SimpleTraits.jl
[LShaped]: https://github.com/martinbiel/LShapedSolvers.jl

## Trait Definition

Here follows some simple examples that shows how traits are defined and implemented. The examples are not meant to be useful, only to exemplify the syntax.

### Defining Traits

Traits are defined using the `@define_trait` macro. Define a single trait that describes something callable.

```julia
julia> using TraitDispatch

julia> @define_trait Callable

```
Moreover, define a trait family of things that are combinable. Assume that combinable things can either be merged or summed up. This can be defined through

```julia
julia> @define_trait Combineable = begin
         Mergeable
         Summable
       end

```
This defines a parent trait `Callable` and two subtraits `Mergeable` and `Summable`. This says that anything mergable or summable is combinable. The following equivalent syntax will define the same trait structure:

```julia
julia> @define_trait Combineable

julia> @define_trait Mergeable <: Combineable

julia> @define_trait Summable <: Combineable

```

### Implementing Traits

A Julia type can implement a defined trait using the `@implement_trait` macro. This will give access to any defined trait functions, shown later. Lets consider Julia functions as callable:

```julia
julia> @implement_trait Function Callable

```

Moreover, define a simple functor type that also implements `Callable`

```julia
julia> struct SimpleFunctor end

julia> function (::SimpleFunctor)()
         println("I was called")
       end

julia> @implement_trait SimpleFunctor Callable

```

Dictionaries can be merged:

```julia
julia> @implement_trait Dict Mergeable

```

Numbers and arrays can be summed:

```julia
julia> @implement_trait Number Summable

julia> @implement_trait AbstractArray Summable

```

## Trait Functions

Now, the defined traits will be associated with trait functions. These trait functions become available to all types that implement the trait.

### Defining Trait Functions

Trait functions are defined using the `@define_traitfn` macro. First, define a `call` function for the `Callable` trait:

```julia
julia> @define_traitfn Callable call(x)

```

Next, give the `Combineable` traits a `combine` function.

```julia
julia> @define_traitfn Combineable combine(x::T,y::T) where T

```

Trait dispatch currently only operates on the first argument, so where syntax is used to ensure that both arguments have the same type.

### Implementing Trait Functions

The defined trait functions are then implemented using the `@implement_traitfn` macro.

```julia
julia> @implement_traitfn call(x,Callable) = x()

```

Now, types that implement the `Callable` trait can make use of `call`:

```julia
julia> call(rand)
0.6330234599166538

julia> call(SimpleFunctor())
I was called

```

Next, the two versions of `combine` is implemented as follows:

```julia
julia> @implement_traitfn combine(x::T,y::T,Mergeable) where T = merge(x,y)

julia> @implement_traitfn combine(x::T,y::T,Summable) where T = x+y

```

and so:

```julia
julia> d1 = Dict(:a=>1)
Dict{Symbol,Int64} with 1 entry:
  :a => 1

julia> d2 = Dict(:b=>2,:c=>3)
Dict{Symbol,Int64} with 2 entries:
  :b => 2
  :c => 3

julia> combine(d1,d2)
Dict{Symbol,Int64} with 3 entries:
  :a => 1
  :b => 2
  :c => 3

julia> combine(1,2)
3

julia> combine([1,2],[3,4])
2-element Array{Int64,1}:
 4
 6

```

It can also be checked that `combine` is not available for other types

```julia
julia> combine(rand,rand)
ERROR: rand has no applicable traits

```

### Advanced

Trait functions can be implemented while they are being defined. This also offers a possibility to define default functionality. Consider the following alternative way of defining the `combine` function

```julia
julia> @define_traitfn Combineable combine(x::T,y::T) where T = begin
         combine(x::T,y::T,!Combineable) where T = (x,y)

         combine(x::T,y::T,Mergeable) where T = merge(x,y)

         combine(x::T,y::T,Summable) where T = x+y
       end

```

This has the same effect as the previous use of `@implement_traitfn`, with the exception that `combine` now operates on things that are not Combineable. The fallback behaviour is to place the two objects in a tuple and return it. It can be checked to work on for example Strings, which were not defined as Combineable:

```julia
julia> combine("a","b")
("a", "b")

```

The syntax `combine(x::T,y::T,Combineable) where T = ...` can be used to define default behaviour for subtraits that do not yet have any implementation.

## Auxilliary Functions

A selection of helper functions is exemplified below

```julia
julia> istrait(Combineable)
true

julia> isleaftrait(Combineable)
false

julia> isleaftrait(Summable)
true

julia> hastrait(1,Summable)
true

julia> hastrait(1,Combineable)
true

julia> hastrait("a",Combinable)
false

julia> implementstrait(Integer,Combineable)
true

julia> subtraits(Combineable)
2-element Array{UnionAll,1}:
 Mergeable
 Summable

```

## Simple Example

Consider the following exemplatory type tree of workers.

```julia
abstract type Worker end

function work(::Worker)
    # ...
    # Work code
    # ...
    println("I did work!")
end

struct LazyWorker <: Worker end

# ... methods for lazy workers ...

function work(::LazyWorker)
    # ...
    # Slow work code
    # ...
    println("I did work slowly!")
end

abstract type DiligentWorker <: Worker end

# ... common methods for diligent workers ...

struct FastWorker <: DiligentWorker end
struct SlowWorker <: DiligentWorker end

function work(::FastWorker)
    # ...
    # Fast work code
    # ...
    println("I did work fast!")
end

function work(::SlowWorker)
    # ...
    # Slow work code
    # ...
    println("I did work slowly!")
end

```

`TraitDispatch` becomes useful when the type tree is complex, and there is some common functionality at leaf nodes. Without multiple inheritance, it is sometimes not clearcut how these common blocks of code could be abstracted away.

The following is an alternative implementation, using `TraitDispatch`

```julia
abstract type Worker end

@define_trait HasWorkSpeed = begin
    WorksFast
    WorksSlow

    work(::Worker) = begin
        function work(::Worker,!Workable)
            # ...
            # Work code (Default behavior when a worker does not have any trait)
            # ...
            println("I did work!")
        end
        function work(::Worker,WorksFast)
            # ...
            # Fast work code
            # ...
            println("I did work fast!")
        end
        function work(::Worker,WorksSlow)
            # ...
            # Slow work code
            # ...
            println("I did work slowly!")
        end
    end
end

abstract type DiligentWorker end

# ... common methods for diligent workers ...

struct FastWorker end
struct SlowWorker end
struct LazyWorker end

# ... methods for lazy workers ...

@implement_trait FastWorker WorksFast
@implement_trait SlowWorker WorksSlow
@implement_trait LazyWorker WorksSlow

```

The type tree is preserved, with the corresponding common functionality. The common code is sucessfully abstracted out into the trait `HasWorkSpeed`. For a comprehensive example of the use of `TraitDispatch`, consider [LShapedSolvers.jl][LShaped]
