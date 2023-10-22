export process_nd2

function process_nd2(
    nd2;
    PxType = Float32,
    channel = 1,
    bufsize = 5,
    bandpass = true, σ₁ = 0.5, σ₂ = 4.0,
    mediansubtraction = true,
    binarization = true,
    info = true,
    verbose = false,
    maxnf = 50
)
    ntiles = size(nd2, 1)
    nc, ny, nx, nz, nf = size(first(nd2))
    nf = min(nf, maxnf)

    if info
        tmp = first(nd2)
        print_info(tmp, channel, ntiles, nf)
    end

    # preallocate Gaussian kernels and dummy matrix for bandpass
    K₁ = Kernel.gaussian(PxType(σ₁))
    K₂ = Kernel.gaussian(PxType(σ₂))
    dummy_img = zeros(PxType, ny, nx)

    # preallocate tiles and spatial ranges
    tiles = zeros(PxType, ny, nx, nf-bufsize, ntiles)
    xs = [0.0:0.0 for _ in 1:ntiles]
    ys = [0.0:0.0 for _ in 1:ntiles]

    # process each tile independently
    @inbounds for n in axes(tiles, 4)
        tilestack = nd2[n]
        verbose && println("TILE #$(n)")
        tile = @view tiles[:, :, :, n]
        process_tile!(tile, tilestack, nf,
            PxType, channel, bufsize,
            bandpass, K₁, K₂, dummy_img,
            mediansubtraction,
            binarization,
            verbose
        )

        # get x and y ranges
        p = properties(tilestack)[:Pixels]
        x₀ = p[:Plane][1][:PositionX]
        y₀ = p[:Plane][1][:PositionY]
        Δx = p[:PhysicalSizeX]
        Δy = p[:PhysicalSizeY]
        xs[n] = range(x₀; step = Δx, length = nx)
        ys[n] = range(y₀; step = Δy, length = ny)
    end

    #return tiles, smoothgrid(xs, 1), smoothgrid(ys, 1)
    return tiles, xs, ys
end

function process_tile!(tile, nd2, nf,
    PxType, channel, bufsize,
    bandpass, K₁, K₂, dummy_img,
    mediansubtraction,
    binarization,
    verbose
)
    data = PxType.(arraydata(@view nd2[channel, :, :, 1, :]).data)
    buffer = FrameBuffer(data[:, :, 1], bufsize)

    @inbounds for t in 2:nf
        verbose && println(" FRAME #$(t):")
        img = @view data[:, :, t]
        push!(buffer, img)
        # start processing only after buffer is filled
        if buffer.full
            if bandpass
                verbose && print("  BANDPASS... ")
                bandpass!(img, dummy_img, K₁, K₂)
                verbose && println("DONE")
            end
            if mediansubtraction
                verbose && print("  MEDIAN SUBTRACTION... ")
                median_subtraction!(img, buffer)
                verbose && println("DONE")
            end
            @. img = max(img, PxType(0))
            tile[:, :, t-bufsize] .= img
        end
    end
    if binarization
        dilate!(tile; dims=(1,2))
        binarize!(tile, Otsu(); nbins=12)
    end
    return nothing
end

function smoothgrid(allxs, ε)
    smoothxs = copy(allxs)
    for (i,xs) in enumerate(allxs[2:end])
        Δx = xs[2] - xs[1]
        ≃(x,y) = isapprox(x, y; atol = ε*Δx) # \simeq
        j = findfirst(ys -> first(ys) ≃ first(xs), allxs[1:i])
        isnothing(j) && continue
        smoothxs[1+i] = allxs[j]
    end
    return smoothxs
end

function bandpass!(img, tmp, K₁, K₂)
    imfilter!(tmp, img, K₂)
    imfilter!(img, img, K₁) # unsafe?
    @. img -= tmp
    return nothing
end

function median_subtraction!(img, buffer::FrameBuffer)
    m = median(buffer) # acts on 3rd dimension of FrameBuffer
    @. img -= m
    return nothing
end

function print_info(args...)
    # not implemented
end
