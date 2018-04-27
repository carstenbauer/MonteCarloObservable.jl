![logo](assets/logo_with_text.png)

# Introduction

This package provides an implementation of an observable in a Markov Chain Monte Carlo simulation context (like [MonteCarlo.jl](https://github.com/crstnbr/MonteCarlo.jl)).

During a [Markov chain Monte Carlo simulation](https://en.wikipedia.org/wiki/Markov_chain_Monte_Carlo) a Markov walker (after thermalization) walks through configuration space according to the equilibrium distribution. Typically, one measures observables along the Markov path, records the results, and in the end averages the measurements. `MonteCarloObservable.jl` provides all the necessary tools for conveniently conducting these types of measurements, including estimation of one-sigma error bars through binning or jackknife analysis.