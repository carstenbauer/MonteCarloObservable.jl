var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#Documentation-1",
    "page": "Home",
    "title": "Documentation",
    "category": "section",
    "text": "TODO"
},

{
    "location": "index.html#Installation-1",
    "page": "Home",
    "title": "Installation",
    "category": "section",
    "text": "To install the package execute the following command in the REPL:Pkg.clone(\"https://github.com/crstnbr/MonteCarloObservable.jl\")Afterwards, you can use MonteCarloObservable.jl like any other package installed with Pkg.add():using MonteCarloObservableTo obtain the latest version of the package just do Pkg.update() or specifically Pkg.update(\"MonteCarloObservable\")."
},

{
    "location": "functions.html#",
    "page": "Functions",
    "title": "Functions",
    "category": "page",
    "text": ""
},

{
    "location": "functions.html#Functions-1",
    "page": "Functions",
    "title": "Functions",
    "category": "section",
    "text": "Below you will find all methods exported by MonteCarloObservable.jl."
},

{
    "location": "functions.html#Index-1",
    "page": "Functions",
    "title": "Index",
    "category": "section",
    "text": ""
},

{
    "location": "functions.html#Base.Distributed.clear!-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "Functions",
    "title": "Base.Distributed.clear!",
    "category": "Method",
    "text": "clear!(obs::Observable{T})\n\nClears all measurement information in obs. Identical to init! and reset!.\n\n\n\n"
},

{
    "location": "functions.html#Base.eltype-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "Functions",
    "title": "Base.eltype",
    "category": "Method",
    "text": "eltype(obs::Observable{T})\n\nReturns the type T of a measurment of the observable.\n\n\n\n"
},

{
    "location": "functions.html#Base.getindex-Union{Tuple{MonteCarloObservable.Observable{T},Vararg{Any,N} where N}, Tuple{T}} where T",
    "page": "Functions",
    "title": "Base.getindex",
    "category": "Method",
    "text": "getindex(obs::Observable{T}, args...)\n\nGet an element of the measurement timeseries of the observable.\n\n\n\n"
},

{
    "location": "functions.html#Base.isempty-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "Functions",
    "title": "Base.isempty",
    "category": "Method",
    "text": "isempty(obs::Observable{T})\n\nDetermine wether the observable hasn't been measured yet.\n\n\n\n"
},

{
    "location": "functions.html#Base.length-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "Functions",
    "title": "Base.length",
    "category": "Method",
    "text": "length(obs::Observable{T})\n\nNumber of measurements of the observable.\n\n\n\n"
},

{
    "location": "functions.html#Base.mean-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "Functions",
    "title": "Base.mean",
    "category": "Method",
    "text": "mean(obs::Observable{T})\n\nEstimate of the mean of the observable.\n\n\n\n"
},

{
    "location": "functions.html#Base.ndims-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "Functions",
    "title": "Base.ndims",
    "category": "Method",
    "text": "ndims(obs::Observable{T})\n\nNumber of dimensions of the observable (of one measurement).\n\nEquivalent to ndims(T).\n\n\n\n"
},

{
    "location": "functions.html#Base.push!-Union{Tuple{MonteCarloObservable.Observable{T},AbstractArray{T,N} where N}, Tuple{T}} where T",
    "page": "Functions",
    "title": "Base.push!",
    "category": "Method",
    "text": "push!(obs::Observable{T}, measurements::AbstractArray{T}; verbose=false)\n\nAdd multiple measurements to observable obs. Note that because of preallocation this isn't really a push.\n\n\n\n"
},

{
    "location": "functions.html#Base.push!-Union{Tuple{MonteCarloObservable.Observable{T},T}, Tuple{T}} where T",
    "page": "Functions",
    "title": "Base.push!",
    "category": "Method",
    "text": "push!(obs::Observable{T}, measurement::T; verbose=false)\n\nAdd a measurement to observable obs. Note that because of preallocation this isn't really a push.\n\n\n\n"
},

{
    "location": "functions.html#Base.size-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "Functions",
    "title": "Base.size",
    "category": "Method",
    "text": "size(obs::Observable{T})\n\nSize of the observable (of one measurement).\n\n\n\n"
},

{
    "location": "functions.html#Base.std-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "Functions",
    "title": "Base.std",
    "category": "Method",
    "text": "std(obs::Observable{T})\n\nEstimate of the standard deviation (one-sigma error) of the mean. Respects correlations between measurements through binning analysis.\n\nNote that this is not the same as Base.std(timeseries(obs)), not even  for uncorrelated measurements.\n\nCorresponds to the square root of var(obs). See also mean(obs).\n\n\n\n"
},

{
    "location": "functions.html#Base.var-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "Functions",
    "title": "Base.var",
    "category": "Method",
    "text": "var(obs::Observable{T})\n\nEstimate of the variance of the mean. Respects correlations between measurements through binning analysis.\n\nNote that this is not the same as Base.var(timeseries(obs)), not even  for uncorrelated measurements.\n\nCorresponds to the square of std(obs). See also mean(obs).\n\n\n\n"
},

{
    "location": "functions.html#Base.view-Union{Tuple{MonteCarloObservable.Observable{T},Vararg{Any,N} where N}, Tuple{T}} where T",
    "page": "Functions",
    "title": "Base.view",
    "category": "Method",
    "text": "view(obs::Observable{T}, args...)\n\nGet a view into the measurement timeseries of the observable.\n\n\n\n"
},

{
    "location": "functions.html#MonteCarloObservable.add!-Union{Tuple{MonteCarloObservable.Observable{T},AbstractArray{T,N} where N}, Tuple{T}} where T",
    "page": "Functions",
    "title": "MonteCarloObservable.add!",
    "category": "Method",
    "text": "add!(obs::Observable{T}, measurements::AbstractArray{T}; verbose=false)\n\nAdd multiple measurements to observable obs.\n\n\n\n"
},

{
    "location": "functions.html#MonteCarloObservable.add!-Union{Tuple{MonteCarloObservable.Observable{T},T}, Tuple{T}} where T",
    "page": "Functions",
    "title": "MonteCarloObservable.add!",
    "category": "Method",
    "text": "add!(obs::Observable{T}, measurement::T; verbose=false)\n\nAdd a measurement to observable obs.\n\n\n\n"
},

{
    "location": "functions.html#MonteCarloObservable.export_result-Union{Tuple{MonteCarloObservable.Observable{T},AbstractString,AbstractString}, Tuple{MonteCarloObservable.Observable{T},AbstractString}, Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "Functions",
    "title": "MonteCarloObservable.export_result",
    "category": "Method",
    "text": "export_results(obs::Observable{T}[, filename::AbstractString, entryname::AbstractString; timeseries::Bool=false])\n\nExport result for given observable nicely to JLD.\n\nWill export name, number of measurements, estimates for mean and one-sigma error (standard deviation). Optionally (timeseries==true) exports the full timeseries as well.\n\n\n\n"
},

{
    "location": "functions.html#MonteCarloObservable.inmemory-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "Functions",
    "title": "MonteCarloObservable.inmemory",
    "category": "Method",
    "text": "inmemory(obs::Observable{T})\n\nChecks wether the observable is kept in memory (vs. on disk).\n\n\n\n"
},

{
    "location": "functions.html#MonteCarloObservable.loadobs-Tuple{AbstractString,AbstractString}",
    "page": "Functions",
    "title": "MonteCarloObservable.loadobs",
    "category": "Method",
    "text": "loadobs(filename::AbstractString, entryname::AbstractString)\n\nLoad complete representation of an observable from JLD file.\n\nSee also saveobs.\n\n\n\n"
},

{
    "location": "functions.html#MonteCarloObservable.loadobs_frommemory-Tuple{AbstractString,AbstractString}",
    "page": "Functions",
    "title": "MonteCarloObservable.loadobs_frommemory",
    "category": "Method",
    "text": "loadobs_frommemory(filename::AbstractString, group::AbstractString)\n\nCreate an observable based on memory dump (inmemory==false).\n\n\n\n"
},

{
    "location": "functions.html#MonteCarloObservable.name-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "Functions",
    "title": "MonteCarloObservable.name",
    "category": "Method",
    "text": "name(obs::Observable{T})\n\nReturns the name of the observable.\n\n\n\n"
},

{
    "location": "functions.html#MonteCarloObservable.rename-Union{Tuple{MonteCarloObservable.Observable{T},AbstractString}, Tuple{T}} where T",
    "page": "Functions",
    "title": "MonteCarloObservable.rename",
    "category": "Method",
    "text": "rename(obs::Observable{T}, name)\n\nRenames the observable.\n\n\n\n"
},

{
    "location": "functions.html#MonteCarloObservable.reset!-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "Functions",
    "title": "MonteCarloObservable.reset!",
    "category": "Method",
    "text": "reset!(obs::Observable{T})\n\nResets all measurement information in obs. Identical to init! and clear!.\n\n\n\n"
},

{
    "location": "functions.html#MonteCarloObservable.saveobs-Union{Tuple{MonteCarloObservable.Observable{T},AbstractString,AbstractString}, Tuple{MonteCarloObservable.Observable{T},AbstractString}, Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "Functions",
    "title": "MonteCarloObservable.saveobs",
    "category": "Method",
    "text": "saveobs(obs::Observable{T}[, filename::AbstractString, entryname::AbstractString])\n\nSaves complete representation of the observable to JLD file.\n\nDefault filename is \"Observables.jld\" and default entryname is name(obs).\n\nSee also loadobs.\n\n\n\n"
},

{
    "location": "functions.html#MonteCarloObservable.timeseries-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "Functions",
    "title": "MonteCarloObservable.timeseries",
    "category": "Method",
    "text": "timeseries(obs::Observable{T})\n\nReturns the measurement timeseries of an observable.\n\nIf inmemory(obs) == false it will read the timeseries from disk and thus might take some time.\n\nSee also getindex and view.\n\n\n\n"
},

{
    "location": "functions.html#MonteCarloObservable.timeseries_frommemory-Tuple{AbstractString,AbstractString}",
    "page": "Functions",
    "title": "MonteCarloObservable.timeseries_frommemory",
    "category": "Method",
    "text": "timeseries_frommemory(filename::AbstractString, group::AbstractString)\n\nLoad timeseries from memory dump (inmemory==false) in HDF5/JLD file.\n\nWill load and concatenate timeseries chunks. Output will be a vector of measurements.\n\n\n\n"
},

{
    "location": "functions.html#MonteCarloObservable.timeseries_frommemory_flat-Tuple{AbstractString,AbstractString}",
    "page": "Functions",
    "title": "MonteCarloObservable.timeseries_frommemory_flat",
    "category": "Method",
    "text": "timeseries_frommemory_flat(filename::AbstractString, group::AbstractString)\n\nLoad timeseries from memory dump (inmemory==false) in HDF5/JLD file.\n\nWill load and concatenate timeseries chunks. Output will be higher-dimensional array whose last dimension corresponds to Monte Carlo time.\n\n\n\n"
},

{
    "location": "functions.html#MonteCarloObservable.Observable-Union{Tuple{String}, Tuple{T}} where T",
    "page": "Functions",
    "title": "MonteCarloObservable.Observable",
    "category": "Method",
    "text": "Observable{T}(name)\n\nCreate an observable.\n\n\n\n"
},

{
    "location": "functions.html#Docs-1",
    "page": "Functions",
    "title": "Docs",
    "category": "section",
    "text": "Modules = [MonteCarloObservable]\nPrivate = false\nOrder   = [:function, :type]"
},

]}
