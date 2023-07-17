module Snopt

using SparseArrays

export snsolve, snopta
export ColdStart, WarmStart

# Set path do snopt dynamic library
const snoptlib = joinpath(@__DIR__, "..", "deps", "lib", "libsnopt")
include_dependency(snoptlib)

# Global flag to force use of global userfun (instead of runtime closure)
const FORCE_GLOBAL_USERFUN = true
if FORCE_GLOBAL_USERFUN
    @warn "Forcing global userfun. This is not recommended and should only be used for debugging."
end

"""
Define global variables for print and summery file numbers.
"""
PRINTNUM = 18
SUMNUM = 6

# Utility functions
include("utils.jl")
include("sparse.jl")

# Types
include("Names.jl")
include("Start.jl")
include("Workspace.jl")
include("Outputs.jl")

# SNOPT function wrappers
include("ccalls.jl")

# SNOPT interfaces
include("userfun.jl")
include("snsolve.jl")
include("snopta.jl")

end  # end module
