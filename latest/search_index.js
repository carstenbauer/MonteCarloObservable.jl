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
    "location": "functions.html#MonteCarloObservable.reset!-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "Functions",
    "title": "MonteCarloObservable.reset!",
    "category": "Method",
    "text": "reset!(obs::Observable{T})\n\nResets all measurement information in obs. Identical to init! and clear!.\n\n\n\n"
},

{
    "location": "functions.html#MonteCarloObservable.timeseries-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "Functions",
    "title": "MonteCarloObservable.timeseries",
    "category": "Method",
    "text": "timeseries(obs::Observable{T})\n\nReturns the measurement timeseries of an observable.\n\nIf keep_in_memory == false it will read the timeseries from disk and thus might take some time.\n\nSee also getindex and view.\n\n\n\n"
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
