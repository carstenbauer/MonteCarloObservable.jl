using MonteCarloObservable
using Test, Statistics

@testset "General" begin

    # constructor
    @test typeof(Observable(Float64, "myobs")) == Observable{Float64, Float64}
    @test typeof(Observable(ComplexF64, "myobs")) == Observable{ComplexF64, ComplexF64}
    @test typeof(Observable(Matrix{Float64}, "myobs")) == Observable{Matrix{Float64}, Matrix{Float64}}
    @test typeof(Observable(Matrix{ComplexF64}, "myobs")) == Observable{Matrix{ComplexF64}, Matrix{ComplexF64}}

    @test typeof(Observable(Int64, "myobs")) == Observable{Int64, Float64}
    @test typeof(Observable(Int64, "myobs"; meantype=Int64)) == Observable{Int64, Int64}
    @test typeof(Observable(Matrix{Int64}, "myobs")) == Observable{Matrix{Int64}, Matrix{Float64}}

    @test eltype(Observable(Int64, "myobs")) == Int64
    @test eltype(Observable(Matrix{Int64}, "myobs")) == Matrix{Int64}

    # macro
    @test (@obs rand(10)) isa Observable{Float64, Float64}
    @test (@obs [rand(2,2) for _ in 1:3]) isa Observable{Array{Float64, 2}, Array{Float64, 2}}

    # size etc.
    @test size(@obs rand(10)) == () # TODO
    @test size(@obs [rand(2,2) for _ in 1:3]) == (2,2)
    @test ndims(@obs rand(10)) == 0
    @test ndims(@obs [rand(2,2) for _ in 1:3]) == 2

    # name
    obs = Observable(Float64, "myobs")
    @test name(obs) == "myobs"
    @test name(Observable(ComplexF64, "julia")) == "julia"
    rename(obs, "juhu")
    @test name(obs) == "juhu"

    # adding and reading
    obs = Observable(Float64, "myobs")
    @test inmemory(obs)
    add!(obs, 1.0)
    @test obs[1] == 1.0
    @test length(obs) == 1
    add!(obs, 2.0:4.0)
    @test length(obs) == 4
    push!(obs, 5.0:9.0)
    @test length(obs) == 9
    push!(obs, 10.0)
    @test length(obs) == 10
    @test timeseries(obs) == 1.0:10.0
    @test obs[3] == 3.0
    @test obs[2:4] == 2.0:4.0
    @test typeof(view(obs, 1:3)) <: SubArray
    @test !isempty(obs)
    @test obs == (@obs 1.0:10.0)

    # reset
    reset!(obs)
    @test length(obs) == 0
    @test isempty(obs)
end

@testset "Statistics" begin
    ots = [0.00124803, 0.643089, 0.183268, 0.799899, 0.0857666, 0.955348, 0.165763, 0.765998, 0.63942, 0.308818]
    obs = @obs ots
    @test mean(ots) == mean(obs)
    @test mean(obs) == 0.454861763
    @test std(ots) == std(obs)
    @test std(obs) == 0.3426207601556565
    @test var(obs) == var(ots)
    @test var(obs) == 0.1173889852896399

    @test error(obs) == 0.1083461975750141
    @test binning_error(ots) == 0.1083461975750141
    @test error(obs, 2) == 0.03447037957199948
    @test binning_error(ots, 2) == 0.03447037957199948
    @test tau(obs) == 0.0
    @test tau(obs, 1.23) == 0.11499999999999999
    @test tau(ots) == 0.0
    @test tau(1.23) == 0.11499999999999999
    @test error_with_convergence(obs) == (0.1083461975750141, false)
    @test error_with_convergence(@obs rand(100000))[2] == true

    # TODO: add tests for complex and matrix data.

    # details
    @test MonteCarloObservable.R_value(ots, 2) == 0.10121963870000192
    @test typeof(MonteCarloObservable.R_function(ots)) == Tuple{UnitRange{Int},Array{Float64,1},Array{Float64,1}}

    # jackknife
    @test jackknife_error(x->mean(x), obs) == 0.10834619757501414
    @test jackknife_error(x->mean(1 ./ x), obs) == 79.76537738034833
    @test Jackknife.estimate(x->mean(x), ts(obs)) == 0.45486176300000025

    # scalar
    @test !iswithinerrorbars(3.123,3.12,0.001)
    @test iswithinerrorbars(3.123,3.12,0.004)
    @test iswithinerrorbars(0.0,-0.1,0.1)

    # array
    A = rand(2,2)
    B = Matrix(reshape(0.1:0.1:0.4, (2,2)))
    @test iswithinerrorbars(A,A+B, 1.1*B)
    @test !iswithinerrorbars(A,A+B, 0.9*B)

    # observables
    # TODO: improve!
    # a = @obs A[:]
    # b = @obs B[:]
    # Aobs = @obs [A]
    # Bobs = @obs [B]
    # @test iswithinerrorbars(Aobs, Bobs, 1.1*B)
    # @test iswithinerrorbars(a, a, 0.1)
end


@testset "Disk observables" begin
    # constructor
    obs = Observable(Float64, "myobs"; inmemory=false, alloc=10)
    @test !inmemory(obs)

    # macro
    @test !inmemory(@diskobs rand(10))

    mktempdir() do d
        cd(d) do
            add!(obs, 1.0:9.0)
            @test !isfile(obs.outfile)
            add!(obs, 10.0)
            @test isfile(obs.outfile)

            ots = timeseries_frommemory("Observables.jld", "myobs")
            @test ots == 1.0:10.0

            add!(obs, 11.0:20.0)
            @test ts(obs) == 1.0:20.0
            @test obs[1:3] == 1.0:3.0
            @test obs[18:end] == 18.0:20.0
            @test obs[3] == 3.0

            @test_throws ErrorException view(obs, 1:3) # views not yet supported for diskobs
        end
    end
end


@testset "IO" begin
    obs = @obs rand(10)
    mktempdir() do d
        cd(d) do
            saveobs(obs, "myobs.jld", "myobservables/obs")
            x = loadobs("myobs.jld", "myobservables/obs")
            @test x == obs
            @test "obs" in listobs("myobs.jld", "myobservables/")
            rmobs("myobs.jld", "obs", "myobservables/")
            @test !("obs" in listobs("myobs.jld", "myobservables/"))

            export_result(obs, "myresults.jld", "myobservables"; timeseries=true)
            ots = timeseries_frommemory_flat("myresults.jld", "myobservables/")
            @test ots == timeseries(obs)
            ots = timeseries_frommemory("myresults.jld", "myobservables/")
            @test ots == timeseries(obs)
        end
    end
end