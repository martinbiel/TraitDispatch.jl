using TraitDispatch
using Base.Test

@define_trait A
@define_trait B begin
    B1
    B2
end

@implement_trait Integer A
@implement_trait Real B B1
@implement_trait Real B B2

@testset "Trait Definition" begin
    @test istrait(A) == true
    @test isleaftrait(A) == true

    @test istrait(B) == true
    @test istrait(B1) == true
    @test istrait(B2) == true
    @test isleaftrait(B) == false
    @test isleaftrait(B1) == true
    @test isleaftrait(B2) == true
    @test (B1 <: B) == true
    @test (B2 <: B) == true
    @test [B1,B2] == subtraits(B)
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

    # Sanity checks
    @test_throws ErrorException @implement_trait 1 A
    @test_throws ErrorException @implement_trait Integer TraitDispatch.AbstractTrait
    @test_throws ErrorException @implement_trait Integer TraitDispatch.NullTrait
    @test_throws ErrorException @implement_trait Real B
    @test_throws ErrorException @implement_trait Real B1
    @test_throws ErrorException @implement_trait Real A B1
end
