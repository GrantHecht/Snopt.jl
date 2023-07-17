
"""
    f, fail = example_snsolve!(g, df, dg, x, deriv)

The expected function signature for user functions used with snsolve.

# Arguments
- `g::Vector{Float64}`: (output) constraint vector, modified in place
- `df::Vector{Float64}`: (output) gradient vector, modified in place
- `dg::Vector{Float64}`: (output) constraint jacobian vector, modified in place. 
    dgi/dxj in order corresponding to sparsity pattern provided to snopt 
    (preferably column major order if dense)
- `x::Vector{Float64}`: (input) design variables, unmodified
- `deriv::Bool`: (input) if false snopt does not need derivatives that iteration so you can skip their computation.

# Returns
- `f::Float64`: objective value
- `fail::Bool`: true if function fails to compute at this x
"""
function example_snsolve!(g, df, dg, x, deriv)
    return 0.0, false
end


"""
    fail = example_snopta!(f, dg, x, deriv)

The expected function signature for user functions used with snopta.

# Arguments
- `f::Vector{Float64}`: (output) function vector, modified in place
- `dg::Vector{Float64}`: (output) function jacobian vector, modified in place. 
    dgi/dxj in order corresponding to sparsity pattern provided to snopt 
    (preferably column major order if dense)
- `x::Vector{Float64}`: (input) design variables, unmodified
- `deriv::Bool`: (input) if false snopt does not need derivatives that iteration so you can skip their computation.

# Returns
- `fail::Bool`: true if function fails to compute at this x
"""
function example_snopta!(f, dg, x, deriv)
    return false
end

# Set global userfun variables (only used if on ARM or FORCE_GLOBAL_USERFUN is true)
global _userfun_snsolve! = example_snsolve!
global _userfun_snopta!  = example_snopta!

# Functions for processing user function when on ARM
function process_user_function_snsolve(func!)
    if FORCE_GLOBAL_USERFUN || Sys.ARCH == :aarch64
        global _userfun_snsolve! = func!
    end
    return nothing
end

function process_user_function_snopta(func!)  
    if FORCE_GLOBAL_USERFUN || Sys.ARCH == :aarch64
        global _userfun_snopta!  = func!
    end
    return nothing
end

# snsolve wrapper for usrfun (augmented with function pass-in)
function usrcallback_snsolve(func!, status_::Ptr{Cint}, 
                             nx::Cint, x_::Ptr{Cdouble},
                             needf::Cint, nf::Cint, f_::Ptr{Cdouble}, 
                             needG::Cint, ng::Cint, G_::Ptr{Cdouble}, 
                             cu::Ptr{Cuchar}, lencu::Cint, iu::Ptr{Cint},
                             leniu::Cint, ru::Ptr{Cdouble}, lenru::Cint)
    
    # check if solution finished, no need to calculate more
    status = unsafe_load(status_)
    if status >= 2
        return
    end

    # unpack design variables
    x = unsafe_wrap(Array, x_, nx)
   
    # set functions
    f = unsafe_wrap(Array, f_, nf)
    G = unsafe_wrap(Array, G_, ng)
    f[1], fail = func!(@view(f[2:end]), @view(G[1:nx]), @view(G[nx+1:end]), x, needG > 0)

    # check if solutions fails
    if fail
        unsafe_store!(status_, -1, 1)
    end
    return nothing
end

# snsolve wrapper for userfun (calls global function _userfun_snsolve!)
function usrcallback_snsolve(status_::Ptr{Cint}, 
                             nx::Cint, x_::Ptr{Cdouble},
                             needf::Cint, nf::Cint, f_::Ptr{Cdouble}, 
                             needG::Cint, ng::Cint, G_::Ptr{Cdouble}, 
                             cu::Ptr{Cuchar}, lencu::Cint, iu::Ptr{Cint},
                             leniu::Cint, ru::Ptr{Cdouble}, lenru::Cint)
    
    # check if solution finished, no need to calculate more
    status = unsafe_load(status_)
    if status >= 2
        return
    end

    # unpack design variables
    x = unsafe_wrap(Array, x_, nx)
   
    # set functions
    f = unsafe_wrap(Array, f_, nf)
    G = unsafe_wrap(Array, G_, ng)
    f[1], fail = _userfun_snsolve!(@view(f[2:end]), @view(G[1:nx]), @view(G[nx+1:end]), x, needG > 0)

    # check if solutions fails
    if fail
        unsafe_store!(status_, -1, 1)
    end
    return nothing
end

# snopta wrapper for usrfun (augmented with function pass-in)
function usrcallback_snopta(func!, status_::Ptr{Cint}, 
                            n::Cint, x_::Ptr{Cdouble},
                            needf::Cint, nF::Cint, f_::Ptr{Cdouble}, 
                            needG::Cint, lenG::Cint, G_::Ptr{Cdouble}, 
                            cu::Ptr{Cuchar}, lencu::Cint, iu::Ptr{Cint},
                            leniu::Cint, ru::Ptr{Cdouble}, lenru::Cint)
    
    # check if solution finished, no need to calculate more
    status = unsafe_load(status_)
    if status >= 2
        return
    end

    # unpack design variables
    x = unsafe_wrap(Array, x_, n)
   
    # set functions
    f = unsafe_wrap(Array, f_, nF)
    G = unsafe_wrap(Array, G_, lenG)
    fail = func!(f, G, x, needG > 0)

    # check if solutions fails
    if fail
        unsafe_store!(status_, -1, 1)
    end
    return nothing
end

# snopta wrapper for userfun (calls global function _userfun_snopta!)
function usrcallback_snopta(status_::Ptr{Cint}, 
                            n::Cint, x_::Ptr{Cdouble},
                            needf::Cint, nF::Cint, f_::Ptr{Cdouble}, 
                            needG::Cint, lenG::Cint, G_::Ptr{Cdouble}, 
                            cu::Ptr{Cuchar}, lencu::Cint, iu::Ptr{Cint},
                            leniu::Cint, ru::Ptr{Cdouble}, lenru::Cint)
    
    # check if solution finished, no need to calculate more
    status = unsafe_load(status_)
    if status >= 2
        return
    end

    # unpack design variables
    x = unsafe_wrap(Array, x_, n)
   
    # set functions
    f = unsafe_wrap(Array, f_, nF)
    G = unsafe_wrap(Array, G_, lenG)
    fail = _userfun_snopta!(f, G, x, needG > 0)

    # check if solutions fails
    if fail
        unsafe_store!(status_, -1, 1)
    end
    return nothing
end

# Function to get userfun pointer
function get_user_function_pointer_snsolve(func!) 
    if FORCE_GLOBAL_USERFUN || Sys.ARCH == :aarch64
        # Set function to global variable
        process_user_function_snsolve(func!)

        # Return function pointer
        return @cfunction(usrcallback_snsolve, Cvoid, 
                    (Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}, Ref{Cint}, 
                    Ptr{Cdouble}, Ref{Cint}, Ref{Cint}, Ptr{Cdouble}, Ptr{Cuchar}, 
                    Ref{Cint}, Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint})) 
    else
        # Create wrapper for userfun with runtime closure
        wrapper = function(status_::Ptr{Cint}, n::Cint, x_::Ptr{Cdouble},
                           needf::Cint, nF::Cint, f_::Ptr{Cdouble}, needG::Cint, lenG::Cint,
                           G_::Ptr{Cdouble}, cu::Ptr{Cuchar}, lencu::Cint, iu::Ptr{Cint},
                           leniu::Cint, ru::Ptr{Cdouble}, lenru::Cint)

            usrcallback_snsolve(func!, status_, n, x_, needf, nF, f_, needG, lenG,
                G_, cu, lencu, iu, leniu, ru, lenru)

            return nothing
        end

        # c wrapper to callback function
        return @cfunction($wrapper, Cvoid,
            (Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}, Ref{Cint}, 
            Ptr{Cdouble}, Ref{Cint}, Ref{Cint}, Ptr{Cdouble}, Ptr{Cuchar}, 
            Ref{Cint}, Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}))
    end
end

function get_user_function_pointer_snopta(func!) 
    if FORCE_GLOBAL_USERFUN || Sys.ARCH == :aarch64
        # Set function to global variable
        process_user_function_snopta(func!)

        # Return function pointer
        return @cfunction(usrcallback_snopta, Cvoid,
            (Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}, Ref{Cint}, 
            Ptr{Cdouble}, Ref{Cint}, Ref{Cint}, Ptr{Cdouble}, Ptr{Cuchar}, 
            Ref{Cint}, Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint})) 
    else
        # Create wrapper for userfun with runtime closure
        wrapper = function(status_::Ptr{Cint}, n::Cint, x_::Ptr{Cdouble},
                           needf::Cint, nF::Cint, f_::Ptr{Cdouble}, needG::Cint, lenG::Cint,
                           G_::Ptr{Cdouble}, cu::Ptr{Cuchar}, lencu::Cint, iu::Ptr{Cint},
                           leniu::Cint, ru::Ptr{Cdouble}, lenru::Cint)

            usrcallback_snopta(func!, status_, n, x_, needf, nF, f_, needG, lenG,
                G_, cu, lencu, iu, leniu, ru, lenru)

            return nothing
        end  

        # Return function pointer
        return @cfunction($wrapper, Cvoid,
            (Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}, Ref{Cint}, 
            Ptr{Cdouble}, Ref{Cint}, Ref{Cint}, Ptr{Cdouble}, Ptr{Cuchar}, 
            Ref{Cint}, Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}))
    end
end