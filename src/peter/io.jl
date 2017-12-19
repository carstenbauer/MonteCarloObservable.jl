"""
Adding a measurement to the observable triggers the following cascade:
1. the measurement is added to the buffer
2. if the buffer is full
    - all measurements are pushed to the timeseries array if desired
    - buffer is averaged and added to bins
        + if all bins are used -> rebin, adjust buffer size
"""
function Base.push!(mco::Observable{T}, measurement::T; verbose = false) where T
    push!(mco, T[measurement]; verbose)
end

function Base.push!(mco::Observable{T}, measurement::AbstractArray{T}; verbose = false) where T
    buffer_size = size(mco.measurement_buffer, ndims(mco.measurement_buffer))
    ac_buffer_size = size(mco.autocorrelation_buffer, ndims(mco.autocorrelation_buffer))
    bin_size = size(mco.bins, ndims(mco.bins))

    measurement_entry = mod1(mco.n_measurements, buffer_size)
    autocorrelation_entry = mod1(mco.n_measurements, ac_buffer_size)
    verbose && println("Storing measurement at position $(measurement_entry) of $().")

    mco.measurement_buffer[mco.colons..., measurement_entry] = measurement
    mco.autocorrelation_buffer[mco.colons..., autocorrelation_entry] = measurement

    if mod(mco.n_measurements, buffer_size) == 0
        verbose && println("Buffer is full.")
        if mco.keep_timeseries == true
            verbose && println("Appending buffer to timeseries.")
            timeseries_copy = copy(mco.timeseries)
            mco.timeseries = Array{T}(mco.entry_size..., mco.n_measurements)
            if size(timeseries_copy)[end] > 0
                verbose && println("Timeseries length $(size(timeseries_copy)[end])")

                mco.timeseries[mco.colons..., 1:size(timeseries_copy)[end]] = timeseries_copy
            end
            mco.timeseries[mco.colons..., size(timeseries_copy)[end] + 1:end] = mco.measurement_buffer
        end

        bin_entry = mod1(mco.n_measurements, bin_size)
        verbose && println("Calculating current bin $(mco.curr_bin) with mean on $(mco.last_dim)")
        mco.bins[mco.colons..., mco.curr_bin] = mean(mco.measurement_buffer, mco.last_dim)

        if mco.curr_bin == bin_size
            verbose && println("All bins are full")
            for (i, j) in enumerate(1:2:bin_size)
                mco.bins[mco.colons..., i] = 0.5 * (mco.bins[mco.colons..., j] + mco.bins[mco.colons..., j + 1])
            end

            mco.curr_bin = Int(0.5 * bin_size) + 1
            verbose && println("Starting refill at $(mco.curr_bin)" )
            mco.bins[mco.colons..., mco.curr_bin:end] = typemin(T)

            mco.measurement_buffer = typemin(T) * ones(mco.entry_size..., 2 * buffer_size)
            verbose && println("New buffer size $(size(mco.measurement_buffer)[end])" )
        else
            mco.curr_bin += 1
        end
        mco.measurement_buffer[:] = typemin(T)
    end
    mco.n_measurements += 1
end

function HDF5.write(h5file::HDF5File, mco::Observable{T}) where T
    write_parameters(h5file, mco)
    write_datasets(h5file, mco)
end

function write_parameters(h5file::HDF5File, mco::Observable{T}) where T
    grp_prefix = "simulation/results/$(mco.name)"

    if exists(h5file, grp_prefix)
        o_delete(h5file, "$(grp_prefix)/keep_timeseries")
        o_delete(h5file, "$(grp_prefix)/n_measurements")
        o_delete(h5file, "$(grp_prefix)/curr_bin")

        if exists(h5file, "$(grp_prefix)/mean") o_delete(h5file, "$(grp_prefix)/mean") end
        if exists(h5file, "$(grp_prefix)/variance") o_delete(h5file, "$(grp_prefix)/variance") end
    end

    h5file["$(grp_prefix)/keep_timeseries"] = mco.keep_timeseries
    h5file["$(grp_prefix)/n_measurements"] = mco.n_measurements
    h5file["$(grp_prefix)/curr_bin"] = mco.curr_bin
    h5file["$(grp_prefix)/mean"] = mean(mco)
    h5file["$(grp_prefix)/variance"] = var(mco)

end

function write_datasets(h5file::HDF5File, mco::Observable{T}) where T
    grp_prefix = "simulation/results/$(mco.name)"
    timeseries_size = (size(mco.timeseries), (mco.entry_size..., -1))
    buffer_size = (size(mco.measurement_buffer), (mco.entry_size..., -1))
    chunk_size = (mco.entry_size..., 256)

    if exists(h5file, "$(grp_prefix)/measurement_buffer")
        set_dims!(h5file["$(grp_prefix)/measurement_buffer"], size(mco.measurement_buffer))
        h5file["$(grp_prefix)/measurement_buffer"][mco.colons..., 1:size(mco.measurement_buffer)[end]] = mco.measurement_buffer
        h5file["$(grp_prefix)/bins"][mco.colons..., :] = mco.bins
        h5file["$(grp_prefix)/autocorrelation_buffer"][mco.colons..., :] = mco.autocorrelation_buffer
        if mco.keep_timeseries == true
            set_dims!(h5file["$(grp_prefixa)/timeseries"], size(mco.timeseries))
            h5file["$(grp_prefix)/timeseries"][mco.colons..., 1:size(mco.timeseries)[end]]  = mco.timeseries[:]
        end
    else
        m_set = d_create(h5file, "$(grp_prefix)/measurement_buffer", T, buffer_size, "chunk", chunk_size)
        m_set[mco.colons..., 1:size(mco.measurement_buffer)[end]] = mco.measurement_buffer
        h5file["$(grp_prefix)/bins"] = mco.bins
        h5file["$(grp_prefix)/autocorrelation_buffer"] = mco.autocorrelation_buffer
        if mco.keep_timeseries == true
            t_set = d_create(h5file, "$(grp_prefix)/timeseries", T, timeseries_size, "chunk", chunk_size)
            t_set[mco.colons..., 1:size(mco.timeseries)[end]]  = mco.timeseries
        end
    end
end

function Base.read!(h5file::HDF5File, mco::Observable{T}) where T
    grp_prefix = "simulation/results/$(mco.name)"

    if exists(h5file, grp_prefix)
        mco.n_measurements = read(h5file, "$(grp_prefix)/n_measurements")
        mco.keep_timeseries = read(h5file, "$(grp_prefix)/keep_timeseries")
        if mco.keep_timeseries == true
            mco.timeseries = read(h5file, "$(grp_prefix)/timeseries")
        end
        mco.measurement_buffer = read(h5file, "$(grp_prefix)/measurement_buffer")
        mco.bins = read(h5file, "$(grp_prefix)/bins")
        mco.curr_bin = read(h5file, "$(grp_prefix)/curr_bin")
        mco.autocorrelation_buffer = read(h5file, "$(grp_prefix)/autocorrelation_buffer")
    end
end