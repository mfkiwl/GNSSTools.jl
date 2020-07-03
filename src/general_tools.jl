"""
    AmultB2D!(A, B, Asize=size(A))

Multiply contents of A in place with contents of B.
Both A and B should be 2D arrays and be the same size.
"""
function AmultB2D!(A, B, Asize=size(A))
    @inbounds for i in 1:Asize[1]
        @inbounds for j in 1:Asize[2]
            A[i,j] = A[i,j] * B[i,j]
        end
    end
    return A
end


"""
    AmultB1D!(A, B, Asize=size(A))

Multiply contents of A in place with contents of B.
Both A and B should be 1D arrays and be the same size.
"""
function AmultB1D!(A, B, Asize=size(A)[1])
    @threads for i in 1:Asize
        @inbounds A[i] = A[i] * B[i]
    end
    return A
end


"""
    conjAmultB1D!(A, B, Asize=size(A))

Multiply contents of conj(A) in place with contents of B.
Both A and B should be 1D arrays and be the same size.
"""
function conjAmultB1D!(A, B, Asize=size(A)[1])
    @threads for i in 1:Asize
        @inbounds A[i] = conj(A[i]) * B[i]
    end
    return A
end


"""
    conjA!(A, Asize=size(A))

Takes the conjugate of A in place.
A should be a 1D array.
"""
function conjA!(A, Asize=size(A)[1])
    @threads for i in 1:Asize
        @inbounds A[i] = conj(A[i])
    end
    return A
end


"""
    calcsnr(x)

Calculates the SNR of the correlation peak in `x`.
"""
function calcsnr(x)
    N = length(x)
    amplitude = sqrt(maximum(abs2.(x)))
    PS = 2*amplitude^2
    PN = 0.
    @threads for i in 1:N
        @inbounds PN += abs2(x[i])
    end
    PN -= PS/(N-2)
    return 10*log10(PS/PN)
end


"""
    fft_correlate(data, reference)

Calculate the cyclical FFT based correlation
between the data and the reference signal.

Returns:

- Array containing the correlation result
"""
function fft_correlate(data, reference)
    return ifft(conj!(fft(reference)).*fft(data))
end


"""
    gnsstypes

Dictionary containing the qyuivalent strings for each
type used in `GNSSTools`.
"""
const gnsstypes = Dict(Val{:l5q}() => "l5q",
                       Val{:l5i}() => "l5i",
                       Val{:l1ca}() => "l1ca",
                       Val{:fft}() => "fft",
                       Val{:carrier}() => "carrier",
                       Val{:sc8}() => "sc8",
                       Val{:sc4}() => "sc4")


"""
    calcinitcodephase(code_length, f_code_d, f_code_dd,
                      f_s, code_start_idx)

Calculates the initial code phase of a given code
where f_d and fd_rate are the Doppler affected
code frequency and code frequency rate, respectively.
"""
function calcinitcodephase(code_length, f_code_d, f_code_dd,
                           f_s, code_start_idx)
    t₀ = (code_start_idx-1)/f_s
    init_phase = -f_code_d*t₀ - 0.5*f_code_dd*t₀^2
    return (init_phase%code_length + code_length)%code_length
end


"""
    calccodeidx(init_chip, f_code_d, f_code_dd, t, code_length)

Calculates the index in the codes for a given t.
"""
function calccodeidx(init_chip, f_code_d, f_code_dd,
                     t, code_length)
    return Int(floor(init_chip+f_code_d*t+0.5*f_code_dd*t^2)%code_length)+1
end


"""
    calctvector(N, f_s)

Generates a `N` long time vector
with time spacing `Δt` or `1/f_s`.
"""
function calctvector(N, f_s)
    # Generate time vector
    t = Array{Float64}(undef, N)
    @threads for i in 1:N
        @inbounds t[i] = (i-1)/f_s
    end
    return t
end


"""
    meshgrid(x, y)

Generate a meshgrid the way Python would in Numpy.
"""
function meshgrid(x, y)
    xsize = length(x)
    ysize = length(y)
    X = Array{eltype(x)}(undef, ysize, xsize)
    Y = Array{eltype(y)}(undef, ysize, xsize)
    for i in 1:ysize
        for j in 1:xsize
            X[i,j] = x[j]
            Y[i,j] = y[i]
        end
    end
    return (X, Y)
end


"""
    find_and_get_timestamp(file_name)

Find a sequency of 8 digits with `_` separating it from a sequence
of 6 digits. Return the timestamp tuple.
"""
function find_and_get_timestamp(file_name)
    sequence_found = false
    sequence_counter = 0
    sequence_start = 1
    sequence_stop = 1
    for i in 1:length(file_name)
        if isdigit(file_name[i])
            if sequence_found == false
                sequence_start = i
            end
            sequence_found = true
            sequence_counter += 1
            if sequence_counter == 14
                sequence_stop = i
                break
            end
        else
            if (file_name[i] == '_') && sequence_found && (sequence_counter == 8)
                # Do nothing
            else
                sequence_found = false
                sequence_counter = 0
                sequence_idx_start = 1
                sequence_idx_stop = 1
            end
        end
    end
    if sequence_found
        timestamp_string = file_name[sequence_start:sequence_stop]
        year = parse(Int, timestamp_string[1:4])
    	month = parse(Int, timestamp_string[5:6])
    	day = parse(Int, timestamp_string[7:8])
    	hour = parse(Int, timestamp_string[10:11])
    	minute = parse(Int, timestamp_string[12:13])
    	second = parse(Int, timestamp_string[14:15])
    	timestamp = (year, month, day, hour, minute, second)
    	timestamp_JD = DatetoJD(timestamp...)
        return (timestamp, timestamp_JD)
    else
        @warn "Data timestamp not found. Please supply it manually."
        return (missing, missing)
    end
end
