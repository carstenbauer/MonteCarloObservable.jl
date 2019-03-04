# personal wrapper
function getfrom(filename::AbstractString, obs::AbstractString, what::AbstractString)
    if !(what in ["ts", "ts_flat", "timeseries", "timeseries_flat"])
        d = joinpath("obs/", obs, what)
        return jldopen(filename) do f
            return read(f[d])
        end
    else
        grp = joinpath("obs/", obs)
        return occursin("flat", what) ? ts_flat(filename, grp) : ts(filename, grp)
    end
end





"""
List all observables in a given file and HDF5 group.
"""
function listobs(filename::AbstractString, group::AbstractString="obs/")
    s = Vector{String}()
    HDF5.h5open(filename, "r") do f
        if HDF5.has(f, group)
            for el in HDF5.names(f[group])
                # println(el)
                push!(s, el)
            end
        end
    end
    return s
end




"""
Remove an observable.
"""
function rmobs(filename::AbstractString, dset::AbstractString, group::AbstractString="obs/")
    HDF5.h5open(filename, "r+") do f
        HDF5.o_delete(f, joinpath(group,dset))
    end
end















# time series
timeseries(filename::AbstractString, group::AbstractString; kw...) = timeseries_frommemory(filename, group; kw...)
ts(filename::AbstractString, group::AbstractString; kw...) = timeseries_frommemory(filename, group; kw...)
"""
    timeseries_frommemory(filename::AbstractString, group::AbstractString)

Load time series from memory dump (`inmemory==false`) in HDF5/JLD file.

Will load and concatenate time series chunks. Output will be a vector of measurements.
"""
function timeseries_frommemory(filename::AbstractString, group::AbstractString; kw...)
    ts = timeseries_frommemory_flat(filename, group; kw...)
    r = [ts[.., i] for i in 1:size(ts, ndims(ts))]
    return r
end






timeseries_flat(filename::AbstractString, group::AbstractString; kw...) = timeseries_frommemory_flat(filename, group; kw...)
ts_flat(filename::AbstractString, group::AbstractString; kw...) = timeseries_frommemory_flat(filename, group; kw...)
"""
    timeseries_frommemory_flat(filename::AbstractString, group::AbstractString)

Load time series from memory dump (`inmemory==false`) in HDF5/JLD file.

Will load and concatenate time series chunks. Output will be higher-dimensional
array whose last dimension corresponds to Monte Carlo time.
"""
function timeseries_frommemory_flat(filename::AbstractString, group::AbstractString; verbose=false)
    grp = endswith(group, "/") ? group : group*"/"
    tsgrp = joinpath(grp, "timeseries")

    isfile(filename) || error("File not found.")
    jldopen(filename) do f
        HDF5.has(f.plain, grp) || error("Group not found in file.")
        if typeof(f[grp]) == JLD.JldGroup && HDF5.has(f.plain, tsgrp) && typeof(f[tsgrp]) == JLD.JldGroup
            # n_meas = read(f, joinpath(grp, "count"))
            element_type = read(f, joinpath(grp, "eltype"))
            chunk_count = read(f,joinpath(tsgrp, "chunk_count"))
            T = jltype(element_type)

            firstchunk = read(f, joinpath(tsgrp,"ts_chunk1"))
            # ignore potential empty last chunk
            lastchunk = read(f, joinpath(tsgrp,"ts_chunk$(chunk_count)"))
            if length(lastchunk) == 0
                chunk_count -= 1
            end
            
            chunks = Vector{typeof(firstchunk)}(undef, chunk_count)
            chunks[1] = firstchunk


            for c in 2:chunk_count
                chunks[c] = read(f, joinpath(tsgrp,"ts_chunk$(c)"))
            end

            flat_timeseries = cat(chunks..., dims=ndims(T)+1)

            return flat_timeseries

        else
            if typeof(f[grp]) == JLD.JldDataset
                return read(f, grp)
            elseif HDF5.has(f.plain, joinpath(grp, "timeseries"))
                verbose && println("Loading time series (export_result or old format).")
                flat_timeseries = read(f, joinpath(grp, "timeseries"))
                return flat_timeseries

            elseif HDF5.has(f.plain, joinpath(grp, "timeseries_real"))
                verbose && println("Loading complex time series (old format).")
                flat_timeseries = read(f, joinpath(grp, "timeseries_real")) + im*read(f, joinpath(grp, "timeseries_imag"))
                return flat_timeseries

            else
                error("No timeseries/observable found.")
            end
        end
    end
end























"""
    iswithinerrorbars(a, b, δ[, print=false])

Checks whether numbers `a` and `b` are equal up to given error `δ`.
Will print `x ≈ y + k·δ` for `print=true`.

Is equivalent to `isapprox(a,b,atol=δ,rtol=zero(b))`.
"""
function iswithinerrorbars(a::T, b::S, δ::Real, print::Bool=false) where T<:Number where S<:Number
  equal = isapprox(a,b,atol=δ,rtol=zero(δ))
  if print && !equal
    out = a>b ? abs(a-(b+δ))/δ : -abs(a-(b-δ))/δ
    println("x ≈ y + ",round(out, digits=4),"·δ")
  end
  return equal
end


"""
    iswithinerrorbars(A::AbstractArray{T<:Number}, B::AbstractArray{T<:Number}, Δ::AbstractArray{<:Real}[, print=false])

Elementwise check whether `A` and `B` are equal up to given real error matrix `Δ`.
Will print `A ≈ B + K.*Δ` for `print=true`.
"""
function iswithinerrorbars(A::AbstractArray{T}, B::AbstractArray{S},
                           Δ::AbstractArray{<:Real}, print::Bool=false) where T<:Number where S<:Number
  size(A) == size(B) == size(Δ) || error("A, B and Δ must have same size.")

  R = iswithinerrorbars.(A,B,Δ,false)
  allequal = all(R)

  if print && !all(R)
    if T<:Real && S<:Real
      O = similar(A, promote_type(T,S))
      for i in eachindex(O)
        a = A[i]; b = B[i]; δ = Δ[i]
        O[i] = R[i] ? 0.0 : round(a>b ? abs(a-(b+δ))/δ : -abs(a-(b-δ))/δ, digits=4)
      end
      println("A ≈ B + K.*Δ, where K is:")
      display(O)
    else
      @warn "Unfortunately print=true is only supported for real input."
    end
  end

  return allequal
end