using Documenter, MonteCarloObservable

makedocs(
    # options
    
)

makedocs(
    modules = [MonteCarloObservable],
    format = :html,
    sitename = "MonteCarloObservable.jl",
    pages = [
        "Home" => "index.md",
        "Functions" => "functions.md"
        # "Subsection" => [
        #     ...
        # ]
    ]
)

deploydocs(
    repo   = "github.com/crstnbr/MonteCarloObservable.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing,
    julia  = "release",
    osname = "linux"
)