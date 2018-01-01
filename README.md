# MonteCarloObservable.jl

[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://crstnbr.github.io/MonteCarloObservable.jl/latest)
[![travis][travis-img]](https://travis-ci.org/crstnbr/MonteCarloObservable.jl)
[![appveyor][appveyor-img]](https://ci.appveyor.com/project/crstnbr/montecarloobservable-jl/branch/master)
[![codecov][codecov-img]](http://codecov.io/github/crstnbr/MonteCarloObservable.jl?branch=master)

[travis-img]: https://img.shields.io/travis/crstnbr/MonteCarloObservable.jl/master.svg?label=Linux+/+macOS
[appveyor-img]: https://img.shields.io/appveyor/ci/crstnbr/montecarloobservable-jl/master.svg?label=Windows
[codecov-img]: https://img.shields.io/codecov/c/github/crstnbr/MonteCarloObservable.jl/master.svg?label=codecov

This package provides an implementation of an observable in a Markov Chain Monte Carlo simulation context (like [MonteCarlo.jl](https://github.com/crstnbr/MonteCarlo.jl)).

During a [Markov chain Monte Carlo simulation](https://en.wikipedia.org/wiki/Markov_chain_Monte_Carlo) a Markov walker (after thermalization) walks through configuration space according to the equilibrium distribution. Typically, one measures observables along the Markov path, records the results, and in the end averages the measurements. `MonteCarloObservable.jl` provides all the necessary tools for conveniently conducting these types of measurements, including estimation of one-sigma error bars through binning or jackknife analysis.

In Julia REPL:
```julia
Pkg.clone("https://github.com/crstnbr/MonteCarloObservable.jl")
using MonteCarloObservable
```

Look at the [documentation](https://crstnbr.github.io/MonteCarloObservable.jl/latest) for more information.

## Authors

* Carsten Bauer ([github](https://github.com/crstnbr))
