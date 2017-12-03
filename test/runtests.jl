using TraitDispatch
using Base.Test

@define_trait A
@define_trait B = begin
    B1
    B2
end
@define_trait B3 <: B

@implement_trait Integer A
@implement_trait Real B B1
@implement_trait Real B B2
@implement_trait Complex B B2

@define_traitfn A afunc(x)
#@implement_traitfn
afunc(x,::Type{A}) = "A"

@define_traitfn B bfunc(x) = "B"
#@implement_traitfn
#@implement_traitfn
bfunc(x,::Type{B1}) = "B1"
bfunc(x,::Type{B2}) = "B2"

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
    @test_throws ErrorException @implement_trait Real B1
    @test_throws ErrorException @implement_trait Real A B1
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
end
