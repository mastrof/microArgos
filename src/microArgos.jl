module microArgos

using Images
using ImageBinarization
using StatsBase

include("framebuffer.jl")
include("preprocessing.jl")

function merge_tiles(nd2)
    indices = arrange_indices(nd2)
    m = size(indices, 1)
    nx = properties(nd2[1])[:Pixels][:SizeX] * m
    ny = properties(nd2[1])[:Pixels][:SizeY] * m
    nt = properties(nd2[1])[:Pixels][:SizeT]
    tiles = [Float16.(arraydata(nd2[i])[1,:,:,1,:]) for i in indices]
    stack = zeros(Float16, nx, ny, nt)
end

function arrange_indices(nd2)
    xs = map(
        tile -> round(Int, properties(tile)[:Pixels][:Plane][1][:PositionX]),
        nd2
    )
    ys = map(
        tile -> round(Int, properties(tile)[:Pixels][:Plane][1][:PositionY]),
        nd2
    )
    # assume square tiling ntiles = m x m
    ntiles = size(nd2, 1)
    m = Int(sqrt(ntiles))
    positions = Tuple.(zip(xs, ys))
    indices = reshape(
        # sort x left to right, y bottom to top
        sortperm(positions; by = p -> (p[1], -p[2])),
        (m, m)
    )
    return indices
end

end # module
