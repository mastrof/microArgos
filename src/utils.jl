export sort_tile_indices

function sort_tile_indices(xs, nx, ys, ny)
    ntiles = nx*ny
    xy = [(xs[n], ys[n]) for n in 1:ntiles]
    sortedinds = sortperm(xy, by = a -> (-a[1], a[2]))
    return reshape(sortedinds, (ny, nx))
end # function
