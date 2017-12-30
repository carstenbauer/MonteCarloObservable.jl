# Memory / disk storage

By default the full Monte Carlo time series of an observable is kept in memory. This is the most convenient option as it renders element access and error computation fast. However, one can think of at least two scenarios in which it might be preferable to track the time series on disk rather than in memory:

* Abrupt termination: the simulation might be computationally expensive, thus slow, and might abort abruptly (maybe due to cluster outage or time limit). In this case, one probably wants to have a restorable "memory dump" of the so far recorded measurements to not have to restart from scratch.

* Memory limit: the tracked observable might be large, i.e. a large complex matrix. Then, storing a long time series might make the simulation exceed a memory limit (and often stop unexpectedly). Keeping the time series memory on disk solves this problem.

As we show below, `MonteCarloObservable.jl` allows you to handle those cases by keeping the time series on disk.

!!! note

    One can always save the full observable object ([`saveobs`](@ref)) or export the time series to disk ([`export_result`](@ref) with `timeseries=true`). This section is about the (internal) temporary storage of the time series during simulation. If you will, you can think of "memory observables" (default) and "disk observables".

## Example

You can create an "disk observable" that every once in a while dumps it's time series memory to disk as follows:

```julia
obs = Observable(Float64, "myobservable"; inmemory=false, alloc=100)
```

It will record measurements in memory until the preallocated time series buffer (`alloc=100`) overflows in which case it will save a "memory dump" in a JLD file (default is `outfile="Observables.jld"`). In the above example this will thus happen for the first time after 100 measurements.

Apart from the special initialization (`inmemory=false`) basically everything else stays the same as for an in-memory observable. For example, we can still get the mean via `mean(obs)`, access time series elements with `obs[idx]` and load the full time series to memory at any point via `timeseries(obs)`. However, because of now necessary disk operations same functionality might be slightly slower for those "disk observables".