module Snopt

export snopt

# callback function
function objcon_wrapper(status::Int32, n::Int32, x_::Ptr{Cdouble},
    needf::Int32, nF::Int32, f_::Ptr{Cdouble}, needG::Int32, lenG::Int32,
    G_::Ptr{Cdouble}, cu::Ptr{UInt8}, lencu::Int32, iu::Ptr{Cint},
    leniu::Int32, ru_::Ptr{Cdouble}, lenru::Int32)

    # check if solution finished, no need to calculate more
    if status >= 2
        return
    end

    # unpack design variables
    x = zeros(n)
    for i = 1:n
        x[i] = unsafe_load(x_, i)
    end
    # x = unsafe_load(x_)  # TODO: test this

    # call function
    res = objcon(x)
    if length(res) == 3
        J, c, fail = res
        gradprovided = false
    else
        J, c, gJ, gc, fail = res
        gradprovided = true
    end

    # copy obj and con values into C pointer
    unsafe_store!(f_, J, 1)
    for i = 2:nF
        unsafe_store!(f_, c[i-1], i)
    end

    # gradients  TODO: separate gradient computation in interface?
    if needG > 0 && gradprovided

        for j = 1:n
            # gradients of f
            unsafe_store!(G_, gJ[j], j)
        end

        k = n+1
        for i = 2:nF
            for j = 1:n
                unsafe_store!(G_, gc[i-1, j], k)
                k += 1
            end
        end
    end


    # check if solutions fails
    if fail
        status = -1
    end

end

# c wrapper to callback function
const usrfun = cfunction(objcon_wrapper, Void, (Ref{Cint}, Ref{Cint}, Ptr{Cdouble},
    Ref{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}, Ref{Cint}, Ptr{Cdouble},
    Ptr{UInt8}, Ref{Cint}, Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}))



# main call to snopt
function snopt(fun, x0, lb, ub, options)

    # TODO: there is a probably a better way than to use a global
    global objcon = fun

    # TODO: set a timer

    # call function
    f, c, fail = fun(x0)

    # TODO: check if no constraints

    # setup
    Start = 0  # cold start
    nF = 1 + length(c)  # 1 objective + constraints
    n = length(x0)  # number of design variables
    ObjAdd = 0.0  # no constant term added to objective (user can add themselves if desired)
    ObjRow = 1  # objective is first thing returned, then constraints

    # linear constraints (none for now)
    iAfun = Int32[1]
    jAvar = Int32[1]
    A = [0.0]  # TODO: change later
    lenA = 1
    neA = 0

    # nonlinear constraints (assume dense jacobian for now)
    lenG = nF*n
    neG = lenG
    iGfun = Array{Int32}(lenG)
    jGvar = Array{Int32}(lenG)
    k = 1
    for i = 1:nF
        for j = 1:n
            iGfun[k] = i
            jGvar[k] = j
            k += 1
        end
    end

    # bound constriaints (no infinite bounds for now)
    xlow = lb
    xupp = ub
    Flow = -1e20*ones(nF)  # TODO: check Infinite Bound size
    Fupp = zeros(nF)  # TODO: currently c <= 0, but perhaps change

    # names
    Prob = "opt prob"  # problem name TODO: change later
    nxname = 1  # TODO: change later
    xnames = Array{UInt8}(nxname, 8)
    # xnames = ["TODOTODO"]
    nFname = 1  # TODO: change later
    Fnames = Array{UInt8}(nFname, 8)
    # Fnames = ["TODOTODO"]

    # starting info
    x = x0
    xstate = zeros(n)
    xmul = zeros(n)
    F = zeros(nF)
    Fstate = zeros(nF)
    Fmul = zeros(nF)
    # INFO = 0
    INFO = Cint[0]
    mincw = 0  # TODO: check that these are sufficient
    miniw = 0
    minrw = 0
    nS = Cint[0]
    nInf = Cint[0]
    sInf = Cdouble[0]
    lencu = 1
    cu = Array{UInt8}(lencu, 8)
    iu = Int32[0]
    leniu = length(iu)
    ru = [0.0]
    lenru = length(ru)

    # open files for printing
    iprint = 18
    isumm = 19
    printerr = Cint[0]
    sumerr = Cint[0]
    # TODO: maybe make the output file names options (hard coded in the fortran)
    ccall( (:openfiles_, "snopt/libsnopt"), Void,
        (Ref{Cint}, Ref{Cint}, Ptr{Cint}, Ptr{Cint}),
        iprint, isumm, printerr, sumerr)
    if printerr[1] != 0
        println("failed to open print file")
    end
    if sumerr[1] != 0
        println("failed to open summary file")
    end

    # working arrays
    lencw = 500 + (n+nF)
    cw = Array{UInt8}(lencw, 8)
    leniw = 500 + 100*(n+nF)
    iw = Array{Int32}(leniw)
    lenrw = 500 + 200*(n+nF)
    rw = Array{Float64}(lenrw)


    # compilation command I used (OS X with gfortran):
    # gfortran -shared -O2 *.f *.f90 -o libhybrd.dylib -fPIC -v

    # --- initialize ----
    ccall( (:sninit_, "snopt/libsnopt"), Void,
        (Ref{Cint}, Ref{Cint}, Ptr{UInt8}, Ref{Cint}, Ptr{Cint},
        Ref{Cint}, Ptr{Cdouble}, Ref{Cint}),
        iprint, isumm, cw, lencw, iw,
        leniw, rw, lenrw)
    # println("here")

    # --- set options ----

    errors = Cint[0]

    for key in keys(options)
        ivalue = options[key]
        buffer = string(key, repeat(" ", 55-length(key)))  # buffer length is 55 so pad with space.

        if length(key) > 55
            println("warning: invalid option, too long")
            continue
        end

        errors[1] = 0

        ccall( (:snseti_, "snopt/libsnopt"), Void,
            (Ptr{UInt8}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ptr{Cint},
            Ptr{UInt8}, Ref{Cint}, Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}),
            buffer, ivalue, iprint, isumm, errors,
            cw, lencw, iw, leniw, rw, lenrw)

        # println(errors[1])

    end

    # --- call snopta ----

    ccall( (:snopta_, "snopt/libsnopt"), Void,
        (Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cdouble},
        Ref{Cint}, Ptr{UInt8}, Ptr{Void}, Ptr{Cint}, Ptr{Cint}, Ref{Cint},
        Ref{Cint}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}, Ref{Cint}, Ref{Cint},
        Ptr{Cdouble}, Ptr{Cdouble}, Ptr{UInt8}, Ptr{Cdouble}, Ptr{Cdouble},
        Ptr{UInt8}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cint},
        Ptr{Cdouble}, Ptr{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ptr{Cint},
        Ptr{Cint}, Ptr{Cdouble}, Ptr{UInt8}, Ref{Cint}, Ptr{Cint}, Ref{Cint},
        Ptr{Cdouble}, Ref{Cint}, Ptr{UInt8}, Ref{Cint}, Ptr{Cint}, Ref{Cint},
        Ptr{Cdouble}, Ref{Cint}),
        Start, nF, n, nxname, nFname, ObjAdd,
        ObjRow, Prob, usrfun, iAfun, jAvar, lenA,
        neA, A, iGfun, jGvar, lenG, neG,
        xlow, xupp, xnames, Flow, Fupp,
        Fnames, x, xstate, xmul, F, Fstate,
        Fmul, INFO, mincw, miniw, minrw, nS,
        nInf, sInf, cu, lencu, iu, leniu,
        ru, lenru, cw, lencw, iw, leniw,
        rw, lenrw)

    # println("done")

    # close output files
    ccall( (:closefiles_, "snopt/libsnopt"), Void,
        (Ref{Cint}, Ref{Cint}),
        iprint, isumm)

end


end