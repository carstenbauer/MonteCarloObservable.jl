using MonteCarloObservable
using Test, Statistics
import HDF5

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
    @testset "Scalar Observables" begin
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
    end

    @testset "Complex Observables" begin
        ots = Complex{Float64}[0.458585+0.676913im, 0.41603+0.0800011im, 0.439703+0.472044im, 0.86602+0.756838im, 0.615955+0.312498im, 0.916813+0.150829im, 0.434218+0.839293im, 0.888952+0.648892im, 0.799521+0.734382im, 0.678336+0.810805im]
        obs = @obs ots
        @test mean(ots) == mean(obs)
        @test mean(obs) == 0.6514133 + 0.54824951im
        @test std(ots) == std(obs)
        @test std(obs) == 0.34616692168645863
        @test var(obs) == var(ots)
        @test var(obs) == 0.11983153766987877

        @test error(obs) == 0.09206504762323696
        @test binning_error(ots) == 0.09206504762323696
        @test error(obs, 2) == 0.12019696825992575
        @test binning_error(ots, 2) == 0.12019696825992575
        @test tau(obs) == -0.14633796917389313
        @test tau(obs, 1.23) == 0.11499999999999999
        @test tau(ots) == -0.14633796917389313
        @test tau(1.23) == 0.11499999999999999
        @test error_with_convergence(obs) == (0.09206504762323696, false)
        @test error_with_convergence(@obs rand(ComplexF64, 100000))[2] == true

        # jackknife
        @test jackknife_error(x->mean(x), obs) == 0.10946759231383452
        @test jackknife_error(x->mean(1 ./ x), obs) == 0.1930517185451075
        @test Jackknife.estimate(x->mean(x), ts(obs)) == 0.6514132999999989 + 0.5482495099999998im

        # scalar
        @test !iswithinerrorbars(0.195 + 0.519im, 0.196 + 0.519im ,0.001)
        @test iswithinerrorbars(0.195 + 0.519im, 0.196 + 0.519im, 0.01)
        @test !iswithinerrorbars(0.195 + 0.519im, 0.195 + 0.520im, 0.001)
        @test iswithinerrorbars(0.195 + 0.519im, 0.195 + 0.520im, 0.01)
    end

    @testset "Matrix Observables" begin
        ots = Array{Float64,2}[[0.127479 0.144452; 0.0934332 0.465612], [0.716647 0.576685; 0.44389 0.256331], [0.811945 0.457262; 0.634971 0.188656]]
        obs = @obs ots
        @test mean(ots) == mean(obs)
        @test isapprox(mean(obs), [0.552024 0.3928; 0.390765 0.303533], atol=1e-6)
        @test std(ots) == std(obs)
        @test isapprox(std(obs), [0.370741 0.22321; 0.27465 0.144386], atol=1e-6)
        @test var(obs) == var(ots)
        @test isapprox(var(obs), [0.137449 0.0498229; 0.0754325 0.0208472], atol=1e-6)

        @test isapprox(error(obs), [0.214048 0.128871; 0.158569 0.083361], atol=1e-6)
        @test isapprox(binning_error(ots), [0.214048 0.128871; 0.158569 0.083361], atol=1e-6)
        @test error(obs, 2) == [Inf Inf; Inf Inf]
        @test binning_error(ots, 2) == [Inf Inf; Inf Inf]
        @test isapprox(tau(obs), [2.036790901 -3.804975758; 1.318619 -2.876001], atol=1e-6)
        @test isapprox(tau(ots), [2.036790901 -3.804975758; 1.318619 -2.876001], atol=1e-6)
        ec = error_with_convergence(obs)
        @test isapprox(ec[1], [0.214048 0.128871; 0.158569 0.083361], atol=1e-6)
        @test ec[2] == Bool[false false; false false]

        # jackknife
        # TODO: missing Base.error(g::Function, x::AbstractArray) or similar in jackknife.jl
        # @test jackknife_error(x->mean(x), obs)
        # @test jackknife_error(x->mean(1 ./ x), obs)
        # @test Jackknife.estimate(x->mean(x), ts(obs))
    end
end


@testset "Disk observables" begin
    mktempdir() do d
        cd(d) do
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

                    @test timeseries_frommemory("Observables.jld", "myobs") == 1.0:10.0
                    @test timeseries_frommemory_flat("Observables.jld", "myobs") == 1.0:10.0
                    @test timeseries("Observables.jld", "myobs") == 1.0:10.0
                    @test timeseries_flat("Observables.jld", "myobs") == 1.0:10.0
                    @test ts("Observables.jld", "myobs") == 1.0:10.0
                    @test ts_flat("Observables.jld", "myobs") == 1.0:10.0
                    @test loadobs_frommemory("Observables.jld", "myobs") == obs

                    add!(obs, 11.0:20.0)
                    @test ts(obs) == 1.0:20.0
                    @test obs[1:3] == 1.0:3.0
                    @test obs[18:end] == 18.0:20.0
                    @test obs[3] == 3.0

                    @test_throws ErrorException view(obs, 1:3) # views not yet supported for diskobs

                end
            end
        end
    end
end


@testset "IO" begin
    mktempdir() do d
        cd(d) do
            obs = @obs rand(10)
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

            MonteCarloObservable.export_error(obs, "myobs.jld" ,"myobservables/obserror")
            HDF5.h5open("myobs.jld", "r") do f
                @test HDF5.has(f, "myobservables/obserror/error")
                @test HDF5.has(f, "myobservables/obserror/error_rel")
                @test HDF5.has(f, "myobservables/obserror/error_conv")
                @test HDF5.read(f["myobservables/obserror/error"]) == error(obs)
                @test HDF5.read(f["myobservables/obserror/error_rel"]) == error(obs)/mean(obs)
                @test parse(Bool, HDF5.read(f["myobservables/obserror/error_conv"])) == false
            end

            rm("myobs.jld")
            rm("myresults.jld")
        end
    end
end