# Manual

## Installation / Updating

To install the package execute the following command in the REPL:
```julia
Pkg.clone("https://github.com/crstnbr/MonteCarloObservable.jl")
```

To obtain the latest version of the package just do `Pkg.update()` or specifically `Pkg.update("MonteCarloObservable")`.

## Example

This is a simple demontration of how to use the package for measuring a floating point observable:

```@repl
using MonteCarloObservable
obs = Observable(Float64, "myobservable")
add!(obs, 1.23) # add measurement
obs
push!(obs, rand(4)) # same as add!
length(obs)
timeseries(obs)
obs[3] # conventional element accessing
obs[end-2:end]
add!(obs, rand(995))
mean(obs)
error(obs) # one-sigma error of mean (binning analysis)
saveobs(obs, "myobservable.jld")
```

**TODO:** mention `alloc` keyword and importance of preallocation.
