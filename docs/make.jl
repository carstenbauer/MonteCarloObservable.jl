using Documenter, MonteCarloObservable

makedocs(modules = [MonteCarloObservable], doctest=false, format = :markdown)

deploydocs(
    deps   = Deps.pip("mkdocs", "mkdocs-material" ,"python-markdown-math", 
        "pygments", "pymdown-extensions"),
    repo   = "github.com/crstnbr/MonteCarloObservable.jl.git",
    target = "site",
    make   = () -> run(`mkdocs build`)
)