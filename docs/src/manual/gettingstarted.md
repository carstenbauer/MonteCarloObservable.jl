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
push!(obs, rand(10)) # same as add!
length(obs)
mean(obs)
std(obs) # one-sigma error of mean (binning analysis)
timeseries(obs)
obs[3] # conventional element accessing
obs[end-2:end]
saveobs(obs, "myobservable.jld")
```