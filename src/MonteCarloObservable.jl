module MonteCarloObservable

    using HDF5

    include("type.jl")
    include("statistics.jl")
    include("io.jl")

    export Observable
    export integrated_autocorrelation_time
    export binning_error
    export jackknife_error

    # iteration interface implementation
    function Base.start(mco::Observable) state = 1 end
    function Base.done(mco::Observable, state::Int) return state == mco.curr_bin end
    function Base.next(mco::Observable, state::Int)
        return mco.bins[mco.colons..., state], state + 1
    end
    # TODO: implement Base.length(mco)
end