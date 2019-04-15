@testset "clean" begin
    remove(join(TEST_TMP_DIR, "test-playground"), recursive=true)
    @test !exists(join(TEST_TMP_DIR, "test-playground"))
    @test islink(join(TEST_CONFIG.bin, "julia-bin"))
    @test islink(join(TEST_CONFIG.share, "myproject"))

    clean(TEST_CONFIG)
    @test !exists(join(TEST_TMP_DIR, "test-playground"))
    @test islink(join(TEST_CONFIG.bin, "julia-bin"))
    @test !islink(join(TEST_CONFIG.share, "myproject"))
end


@testset "remove" begin
    rm(TEST_CONFIG, dir=join(TEST_DIR, ".playground"))
    @test !exists(join(TEST_DIR, ".playground"))

    rm(TEST_CONFIG, name="julia-nightly-dir")
    @test !exists(join(TEST_CONFIG.bin, "julia-nightly-dir"))

    remove(join(TEST_TMP_DIR, "test-playground2"), recursive=true)
    rm(TEST_CONFIG, name="otherproject")
    @test !islink(join(TEST_CONFIG.share, "otherproject"))
    @test !exists(join(TEST_TMP_DIR, "test-playground2"))
end
