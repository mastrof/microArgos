# Copied from BlobTracking.jl

"""
    FrameBuffer{T}
A buffer for images, supports efficient updating and calculation of
statistics along its third dimension.

Construct using
    fb = FrameBuffer(img::Matrix, n)
    fb = FrameBuffer(buffer::Array{T,3})
    fb = FrameBuffer{T}(w::Int, h::Int, n::Int)
where `n` is the buffer capacity.
`fb` supports `push!`, `median`, `mean`, `sum`, `var`, `std`,
`reshape`, `size`, `length`, `capacity`, `Matrix`, `isready`
and iteration.
"""
mutable struct FrameBuffer{T}
    b::Array{T,3}
    c::Int
    full::Bool

    function FrameBuffer(img::Matrix, n)
        fb = new{eltype(img)}(similar(img, size(img)..., n), 0, false)
        push!(fb, img)
        fb
    end
    function FrameBuffer(buffer::Array{T,3}) where T
        fb = new{T}(buffer, 0, true)
    end
    function FrameBuffer{T}(w::Int, h::Int, d::Int) where T
        new{T}(Array{T,3}(undef, w, h, d), 0, false)
    end
end

capacity(fb::FrameBuffer) = size(fb.b, 3)

function Base.push!(b::FrameBuffer, img)
    b.c += 1
    if b.c > capacity(b)
        b.full = true
        b.c = 1
    end
    b.b[:, :, b.c] .= img
end

Base.@propagate_inbounds function Base.getindex(b::FrameBuffer, i::Int)
    Base.@boundscheck if !b.full && i > b.c
        throw(BoundsError(b, i))
    end
    @view b.b[:, :, i]
end

Base.@propagate_inbounds function Base.getindex(b::FrameBuffer, i, j, k)
    Base.@boundscheck if !b.full && i > b.c
        throw(BoundsError(b, i))
    end
    b.b[i, j, k]
end

for f in (median, mean, sum, std, var, reshape, size)
    m = parentmodule(f)
    fs = nameof(f)
    @eval function $m.$fs(b::FrameBuffer{T}, args...)::Matrix{T} where T
        if b.full
            return map($fs, Slices(b.b, 3))
        else
            return dropdims($fs(@view(b.b[:, :, 1:b.c]), args..., dims=3), dims=3)
        end
    end
end

for f in (diff,)
    m = parentmodule(f)
    fs = nameof(f)
    @eval function $m.$fs(b::FrameBuffer{T}, args...) where T
        if b.full
            return FrameBuffer($fs(b.b, args..., dims=3))
        else
            return FrameBuffer($fs(@view(b.b[:, :, 1:b.c]), args..., dims=3))
        end
    end
end
