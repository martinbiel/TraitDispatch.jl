using TraitDispatch
using Base.Test

@define_trait A
@define_trait B begin
    B1
    B2
end

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
    @implement_trait Integer A
    # Integers should now have A, floats should not
    @test hastrait(Int32(1),A) == true
    @test hastrait(Int64(1),A) == true
    @test hastrait(1.0,A) == false
    # Actually, floats should not have anything
    @test notraits(1.0) == true

    @implement_trait Real B B1
    # Integers should have B1 now, but also retain A
    @test hastrait(Int32(1),A) == true
    @test hastrait(Int64(1),A) == true
    @test hastrait(Int32(1),B1) == true
    @test hastrait(Int64(1),B1) == true
    # Float should have B1 (and thereby B) as well, but still not A
    @test hastrait(1.0,A) == false
    @test hastrait(1.0,B1) == true
    @test hastrait(1.0,B) == true
    # Should not be possible to add B2 to float types now
    @implement_trait Real B B2
    @test hastrait(1.0,B1) == false
    @test hastrait(1.0,B2) == false

    # Sanity checks
    @test_throws ErrorException @implement_trait 1 A
    @test_throws ErrorException @implement_trait Integer AbstractTrait
    @test_throws ErrorException @implement_trait Integer NullTrait
    @test_throws ErrorException @implement_trait Integer Real
    @test_throws ErrorException @implement_trait Real B
    @test_throws ErrorException @implement_trait Real B1
end
