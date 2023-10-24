##
using DrWatson
@quickactivate :microArgos
using BioformatsLoader; BioformatsLoader.init()
using Images
using DelimitedFiles

## Import raw data
fdir = datadir("exp_raw", "2023-10-23_12B09")
fname = joinpath(fdir, "uargos001.nd2")
nd2 = bf_import(fname);


## Preprocess each tile individually
tiles, x, y = process_nd2(nd2;
    mediansubtraction = true,
    bandpass = false,
    binarization = false,
    maxnf = 900
)
nd2 = nothing; GC.gc()

## Save each tile and metadata
p = sort_tile_indices(x, 3, y, 3)
for n in eachindex(p)
    i = lpad(n, 2, '0')
    fout = joinpath(fdir, "tile_$(i)_bp.tif")
    out = tiles[:, :, :, p[n]]
    out ./= maximum(out)
    save(fout, out)
    x1, x2 = x[p[n]][[1,end]]
    y1, y2 = y[p[n]][[1,end]]
    writedlm(joinpath(fdir, "xy_$i.dat"), [x1, x2, y1, y2])
end
