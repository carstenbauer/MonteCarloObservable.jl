module MonteCarloObservable

    using HDF5

    include("type.jl")
    include("statistics.jl")
    include("io.jl")

    export monte_carlo_observable
    export integrated_autocorrelation_time
    export binning_error
    export jackknife_error

    function Base.start(mco::monte_carlo_observable) state = 1 end
    function Base.done(mco::monte_carlo_observable, state::Int) return state == mco.curr_bin end
    function Base.next(mco::monte_carlo_observable, state::Int)
        return mco.bins[mco.colons..., state], state + 1
    end
end