# Error estimation

The automatic estimation of error bars (one-sigma confidence intervals) is outsourced in the package [ErrorAnalysis.jl](https://github.com/crstnbr/ErrorAnalysis.jl).

## Binning analysis

For $N$ uncorrelated measurements of an observable $O$ the statistical error $\sigma$, the root-mean-square deviation of the time series mean from the true expectation value, falls off with the number of measurements $N$ according to

$\sigma = \frac{\sigma_{O}}{\sqrt{N}},$

where $\sigma_{O}$ is the standard deviation of the observable $O$.

In a Markov chain Monte Carlo sampling, however, measurements are usually correlated due to the fact that the next step of the Markov walker depends on his current position in configuration space. One way to estimate the statistical error in this case is by binning analysis. The idea is to partition the time series into bins of a fixed size large enough such that neighboring bins are uncorrelated, that is there means are uncorrelated. For this procedure to be reliable we need both a large bin size (larger than the Markov time scale of correlations, typically called autocorrelation time) and many bins (to suppress statistical fluctuations).

In principle, what one *should* do is look at the estimate for the statistical error as a function of bin size and expect a plateau (convergence of the estimate). However, finding a plateau (with fluctuations) numerically in an automated manner is difficult. Instead we simply always partition the time series into 32 bins what is generally considered a large sample by statisticians. The more data we add the larger the bin size and the better the error estimate.

From this we conclude that estimates for the error only become reliable in the limit of many measurements.

## Resources

J. Gubernatis, N. Kawashima, and P. Werner, [Quantum Monte Carlo Methods: Algorithms for Lattice Models](https://www.cambridge.org/core/books/quantum-monte-carlo-methods/AEA92390DA497360EEDA153CF1CEC7AC), Book (2016)

V. Ambegaokar, and M. Troyer, [Estimating errors reliably in Monte Carlo simulations of the Ehrenfest model](http://aapt.scitation.org/doi/10.1119/1.3247985), American Journal of Physics **78**, 150 (2010)
