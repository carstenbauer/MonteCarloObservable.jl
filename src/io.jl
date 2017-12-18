"""
Adding a measurement to the observable triggers the following cascade:
1. the measurement is added to the buffers
2. if the buffer is full
    - all measurements are pushed to the timeseries array if desired
    - buffer is averaged and added to bins
        + if all bins are used -> rebin, adjust buffer size
"""
function Base.push!{T}(mco::Observable{T}, measurement::T, verbose = false)
    push!(mco, T[measurement], verbose)
end

function Base.push!{T}(mco::Observable{T}, measurement::Array{T}, verbose = false)
    colons = [Colon() for _ in mco.entry_dims]
    buffer_size = size(mco.measurement_buffer)[end]
    ac_buffer_size = size(mco.autocorrelation_buffer)[end]
    bin_size = size(mco.bins)[end]

    measurement_entry = mod1(mco.n_measurements, buffer_size)
    autocorrelation_entry = mod1(mco.n_measurements, ac_buffer_size)
    if verbose println("Saving measurement to position $(measurement_entry)") end

    mco.measurement_buffer[colons..., measurement_entry] = measurement
    mco.autocorrelation_buffer[colons..., autocorrelation_entry] = measurement

    if mod(mco.n_measurements, buffer_size) == 0
        if verbose println("Buffer is full") end
        if mco.keep_timeseries == true
            if verbose println("Appending to timeseries") end
            timeseries_copy = copy(mco.timeseries)
            mco.timeseries = Array{T}(mco.entry_dims..., mco.n_measurements)
            if size(timeseries_copy)[end] > 0
                if verbose println("Timeseries length $(size(timeseries_copy)[end])") end

                mco.timeseries[colons..., 1:size(timeseries_copy)[end]] = timeseries_copy
            end
            mco.timeseries[colons..., size(timeseries_copy)[end] + 1:end] = mco.measurement_buffer
        end

        bin_entry = mod1(mco.n_measurements, bin_size)
        if verbose println("Calculating current bin $(mco.curr_bin) with mean on $(mco.last_dim)") end
        mco.bins[colons..., mco.curr_bin] = mean(mco.measurement_buffer, mco.last_dim)

        if mco.curr_bin == bin_size
            if verbose println("All bins are full") end
            for (i, j) in enumerate(1:2:bin_size)
                mco.bins[colons..., i] = 0.5 * (mco.bins[colons..., j] + mco.bins[colons..., j + 1])
            end

            mco.curr_bin = Int(0.5 * bin_size) + 1
            if verbose println("Starting refill at $(mco.curr_bin)" ) end
            mco.bins[colons..., mco.curr_bin:end] = typemin(T)

            mco.measurement_buffer = typemin(T) * ones(mco.entry_dims..., 2 * buffer_size)
            if verbose println("New buffer size $(size(mco.measurement_buffer)[end])" ) end
        else
            mco.curr_bin += 1
        end
        mco.measurement_buffer[:] = typemin(T)
    end
    mco.n_measurements += 1
end

function HDF5.write{T}(h5file::HDF5File, mco::Observable{T})
    write_parameters(h5file, mco)
    write_datasets(h5file, mco)
end

function write_parameters{T}(h5file::HDF5File, mco::Observable{T})
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

function write_datasets{T}(h5file::HDF5File, mco::Observable{T})
    colons = [Colon() for _ in mco.entry_dims]
    grp_prefix = "simulation/results/$(mco.name)"
    timeseries_size = (size(mco.timeseries), (mco.entry_dims..., -1))
    buffer_size = (size(mco.measurement_buffer), (mco.entry_dims..., -1))
    chunk_size = (mco.entry_dims..., 256)

    if exists(h5file, "$(grp_prefix)/measurement_buffer")
        set_dims!(h5file["$(grp_prefix)/measurement_buffer"], size(mco.measurement_buffer))
        h5file["$(grp_prefix)/measurement_buffer"][colons..., 1:size(mco.measurement_buffer)[end]] = mco.measurement_buffer
        h5file["$(grp_prefix)/bins"][colons..., :] = mco.bins
        h5file["$(grp_prefix)/autocorrelation_buffer"][colons..., :] = mco.autocorrelation_buffer
        if mco.keep_timeseries == true
            set_dims!(h5file["$(grp_prefixa)/timeseries"], size(mco.timeseries))
            h5file["$(grp_prefix)/timeseries"][colons..., 1:size(mco.timeseries)[end]]  = mco.timeseries[:]
        end
    else
        m_set = d_create(h5file, "$(grp_prefix)/measurement_buffer", T, buffer_size, "chunk", chunk_size)
        m_set[colons..., 1:size(mco.measurement_buffer)[end]] = mco.measurement_buffer
        h5file["$(grp_prefix)/bins"] = mco.bins
        h5file["$(grp_prefix)/autocorrelation_buffer"] = mco.autocorrelation_buffer
        if mco.keep_timeseries == true
            t_set = d_create(h5file, "$(grp_prefix)/timeseries", T, timeseries_size, "chunk", chunk_size)
            t_set[colons..., 1:size(mco.timeseries)[end]]  = mco.timeseries
        end
    end
end

function Base.read!{T}(h5file::HDF5File, mco::Observable{T})
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