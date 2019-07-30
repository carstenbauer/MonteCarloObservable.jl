@deprecate error(obs::Observable) std_error(obs::Observable)

export binning_error
@deprecate binning_error(ts) std_error(ts, method=:full)

@deprecate jackknife_error(g, obs...) jackknife(g, obs...)[2]