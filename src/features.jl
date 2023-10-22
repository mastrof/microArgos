export normalized_displacements!, rescaled_trajectory!

normalized_displacements!(gdf::GroupedDataFrame) = [normalized_displacements!(g) for g in gdf]
function normalized_displacements!(df::AbstractDataFrame)
    x = df.x
    y = df.y
    dx = diff(x)
    dy = diff(y)
    wx = [0.0; dx ./ std(dx)]
    wy = [0.0; dy ./ std(dy)]
    if !("wx" in names(df))
        insertcols!(df, :wx => wx, :wy => wy)
    else
        df.wx .= wx
        df.wy .= wy
    end
end

rescaled_trajectory!(gdf::GroupedDataFrame) = [rescaled_trajectory!(g) for g in gdf]
function rescaled_trajectory!(df::AbstractDataFrame)
    wx = df.wx
    wy = df.wy
    xhat = cumsum(wx)
    xhat .-= mean(xhat)
    yhat = cumsum(wy)
    yhat .-= mean(yhat)
    if !("xhat" in names(df))
        insertcols!(df, :xhat => xhat, :yhat => yhat)
    else
        df.xhat .= xhat
        df.yhat .= yhat
    end
end

absolute_displacements!(gdf::GroupedDataFrame) = [absolute_displacements!(g) for g in gdf]
function absolute_displacements!(df::AbstractDataFrame)
    wx = df.wx
    wy = df.wy
    Wx = abs.(wx)
    Wy = abs.(wy)
    if !("Wx" in names(df))
        insertcols!(df, :Wx => Wx, :Wy => Wy)
    else
        df.Wx .= Wx
        df.Wy .= Wy
    end
end
