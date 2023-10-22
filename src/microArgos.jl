module microArgos

using Images
using ImageBinarization
using StatsBase
using DataFrames

# read pandas dataframe from python
import Pandas
export read_pickle
read_pickle(fname::AbstractString) = DataFrame(Pandas.read_pickle(fname))

include("framebuffer.jl")
include("preprocessing.jl")
include("utils.jl")

include("track_processing.jl")

end # module
