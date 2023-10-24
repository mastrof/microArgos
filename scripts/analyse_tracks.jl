using DrWatson
@quickactivate :microArgos
using DataFrames
using GLMakie

##
function speed(df, dt=3.5)
    dx = diff(df.x)
    dy = diff(df.y)
    sqrt.(abs2.(dx) .+ abs2.(dy)) ./ dt
end

## Input
fname = datadir("exp_raw/2023-07-29_12B09/tracks.pkl")
df = read_pickle(fname)
gdf = groupby(df, :particle)

## Fitering
# keep only trajectories longer than lmin
lmin = 10 # frames
gdf_flt = filter(:x => x -> length(x) > lmin, gdf)

# keep only trajectories with avg speed > umin
umin = 1 # micron/s
inst_speed = [speed(g) for g in gdf_flt]
gdf_flt = gdf_flt[mean.(inst_speed) .> umin]


##
fig = Figure()
ax = Axis(fig[1,1]; aspect = 1)
for g in gdf_flt
    x = g.x
    y = g.y
    x0, y0 = x[1], y[1]
    lines!(ax, x, y)
end
fig
