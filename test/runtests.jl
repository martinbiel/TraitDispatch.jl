using TraitDispatch
using Test

@define_trait A
@define_trait B = begin
    B1
    B2
    bfunc(x) = begin
        bfunc(x,NullTrait) = "B"
    end
end
@define_trait B3 <: B

@implement_trait Integer A
@implement_trait Real B1
@implement_trait Real B2
@implement_trait Complex B2
@implement_trait AbstractArray B3

@define_traitfn A afunc(x)
@implement_traitfn afunc(x,A) = "A"

@implement_traitfn bfunc(x,B1) = "B1"
@implement_traitfn bfunc(x::T,B2) where T <: Number = "B2"

@define_traitfn B parentbfunc(x) = begin
    parentbfunc(x,B) = "B"
    parentbfunc(x,B1) = "B1"
    parentbfunc(x,B2) = "B2"
end
@define_traitfn B3 b3func(x) = begin
    b3func(x,B3) = "B3"
end

@testset "Trait Definition" begin
    @test istrait(A)
    @test isleaftrait(A)

    @test istrait(B)
    @test istrait(B1)
    @test istrait(B2)
    @test istrait(B3)
    @test !isleaftrait(B)
    @test isleaftrait(B1)
    @test isleaftrait(B2)
    @test isleaftrait(B3)
    @test B1 <: B
    @test B2 <: B
    @test B3 <: B
    @test [B1,B2,B3] == subtraits(B)
end

@testset "Trait Implementation" begin
    # Integers should have A, floats should not
    @test hastrait(Int32(1),A)
    @test hastrait(Int64(1),A)
    @test !hastrait(1.0,A)

    # Strings should not have anything
    @test notraits("string")

    # Subtypes of AbstractArray should have B3
    @test hastrait(Vector(),B3)
    @test hastrait(Matrix(undef,0,0),B3)

    # Integers and floats should have B1 (and thereby B) as well
    @test hastrait(1,A)
    @test hastrait(1,B1)
    @test !hastrait(1.0,A)
    @test hastrait(1.0,B1)
    @test hastrait(1.0,B)

    # Should not have been possible to add B2 to float types
    @test !hastrait(1.0,B2)
    # but should have been added to Complex
    @test hastrait(complex(1),B2)

    # Sanity checks
    @test_throws ErrorException @implement_trait 1 A
    @test_throws ErrorException @implement_trait Integer TraitDispatch.AbstractTrait
    @test_throws ErrorException @implement_trait Integer TraitDispatch.NullTrait
    @test_throws ErrorException @implement_trait Real B
end

@testset "Trait Functions" begin
    # Integers have A, should have the afunc
    @test afunc(1) == "A"
    # Float do not have A, should not have the afunc
    @test_throws ErrorException afunc(1.0)

    # Integers and Floats have B1
    @test bfunc(1.0) == "B1"
    # Complex has B2
    @test bfunc(complex(1)) == "B2"
    # Vector has B3, but there is no bfunc implementation for B3
    @test_throws ErrorException bfunc(Vector())

    # Same should work for parentbfunc
    @test parentbfunc(1.0) == "B1"
    @test parentbfunc(complex(1)) == "B2"
    # There is still no B3 implementation, but here should fallback to parent B version
    @test parentbfunc(Vector()) == "B"
    # B3 should have its own function b3func
    @test b3func(Vector()) == "B3"
    @test_throws ErrorException b3func(1.0)

    # Sanity checks
    # Definitions
    @test_throws ErrorException @define_traitfn AbstractTrait f(x)
    @test_throws ErrorException @define_traitfn NullTrait f(x)
    # Implementations
    @test_throws ErrorException @implement_traitfn f(x,AbstractTrait) = 0
end
