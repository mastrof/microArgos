using DrWatson
@quickactivate :microArgos
using DataFrames
using MeanSquaredDisplacement
using GLMakie

##
function speed(df, dt=3.5)
    dx = diff(df.x)
    dy = diff(df.y)
    sqrt.(abs2.(dx) .+ abs2.(dy)) ./ dt
end

## Input
dir = datadir("exp_raw/2023-07-29_12B09")
fname = joinpath(dir, "tracks_bp.pkl")
df = read_pickle(fname)
xmin, xmax = extrema(df.x)
ymin, ymax = extrema(df.y)
gdf = groupby(df, :particle)

## Fitering
# keep only trajectories longer than lmin
lmin = 300 # frames
gdf_flt = filter(:x => x -> length(x) > lmin, gdf)

# keep only trajectories with avg speed > umin
umin = 1 # micron/s
inst_speed = [speed(g) for g in gdf_flt]
gdf_flt = gdf_flt[mean.(inst_speed) .> umin]


## Visualize trajectories
fig = Figure()
ax = GLMakie.Axis(fig[1,1];
    aspect = 1,
    title = "Trajectories longer than 18 minutes",
    xlabel = "μm",
    ylabel = "μm",
    xticks = round.(Int, range(0, 1e4; length=4)),
    yticks = round.(Int, range(0, 1e4; length=4)),
)
for g in gdf_flt
    x = g.x .- xmin
    y = g.y .- ymin
    #x0, y0 = x[1], y[1]
    lines!(ax, x, y)
end
limits!(ax, (0,1e4), (0,1e4))
fig
# save(joinpath(dir, "trajectories.png"), fig)

## msd
M = [imsd(Vector(g.x)) + imsd(Vector(g.y)) for g in gdf_flt]
fig = Figure()
ax = GLMakie.Axis(fig[1,1];
    xlabel = "time (s)",
    ylabel = "MSD (μm²)",
    yscale = log10,
    xscale = log10,
)
for m in M
    mm = m[2:end]
    t = eachindex(mm) .* 3.5
    lines!(ax, t, mm; linewidth = 0.75)
end

Mall = (emsd([Vector(g.x) for g in gdf_flt])+emsd([Vector(g.y) for g in gdf_flt]))[2:end]
lines!(ax, eachindex(Mall).*3.5, Mall;
    color = :black,
    linewidth = 8
)

lines!(range(3.5, 500; length=100), t -> 1.0 * 2e3/3.5 * t;
    linewidth = 6, linestyle = :dash, color = :red
)
lines!(range(35, 1000; length=100), t -> 15 * 2e3/3.5 * sqrt(t);
    linewidth = 6, linestyle = :dash, color = :green3
)

ylims!(ax, (1e2, 2e6))
xlims!(ax, (3.5, 1e3))
fig
# save(joinpath(dir, "msd.png"), fig)

## step length
step_length = inst_speed .* 3.5 # μm
fig = Figure()
ax = GLMakie.Axis(fig[1,1];
    xlabel = "step length (μm)",
    ylabel = "pdf",
)
hist!(ax, vcat(step_length...), bins=range(0,15;length=150), normalization=:pdf)
fig
# save(joinpath(dir, "steplength.png"), fig)

## NGDR
netdisp = [sqrt(abs2(g.x[end]-g.x[1])+abs2(g.y[end]-g.y[1])) for g in gdf_flt]
grossdisp = [
    sum(sqrt.(abs2.(diff(g.x)) .+ abs2.(diff(g.y)))) for g in gdf_flt
]
ngdr = netdisp ./ grossdisp

fig = Figure()
ax = GLMakie.Axis(fig[1,1];
    xlabel = "net displacement (μm)",
    ylabel = "gross displacement (μm)",
    xscale = log10, yscale = log10
)
scatter!(ax, netdisp, grossdisp; color=ngdr, colormap=:coolwarm, markersize=24)
Colorbar(fig[1,2];
    colorrange = extrema(ngdr),
    colormap = :coolwarm,
    label = "net to gross displacement ratio",
)
fig
# save(joinpath(dir, "ngdr.png"), fig)
