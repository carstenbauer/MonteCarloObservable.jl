using Documenter, MonteCarloObservable

makedocs(modules = [MonteCarloObservable], doctest=false)

deploydocs(
    deps   = Deps.pip("mkdocs", "mkdocs-material" ,"python-markdown-math", 
        "pygments", "pymdown-extensions"),
    repo   = "github.com/crstnbr/MonteCarloObservable.jl.git",
    julia  = "release",
    osname = "linux",
)