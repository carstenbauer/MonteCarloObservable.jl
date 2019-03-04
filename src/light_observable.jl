struct LightObservable{N, T}
    name::String
    outfile::String
    group::String

    B::LogBinner{N, T}
end


function LightObservable(::Type{T};
                    name::String="unnamed",
                    outfile::String="Observables.jld",
                    group::String=name,
                    kws...) where T

    @assert isconcretetype(T) "Type must be concrete."

    obs = LightObservable{T, mt, inmemory}()
    obs.name = name
    obs.alloc = alloc
    obs.outfile = outfile
    obs.group = group

    _init!(obs)
    return obs
end