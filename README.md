# Snopt.jl

Julia interface to SNOPT v7 (must obtain a licensed copy of SNOPT separately).

This package is a basic wrapper to the Fortran functions. It follows the snopt functions, but with some conveniences in auto-populating sparsity patterns, vector lengths, making names the appropriate size, etc.

### To Install

1. Checkout the repo for development:
```julia
(v1.0) pkg> dev https://github.com/GrantHecht/Snopt.jl.git
```

2. Copy your SNOPT source files into ~/.julia/dev/Snopt/deps/src.

3. You will need to make a couple of changes to subroutine sn02lib.f. Function snSet, snSeti, and snSetr require the following changes:

    `character*(*) buffer` => `character buffer*72`   (snSet)

    `character*(*) buffer` => `character buffer*55`  (snSeti and snSetr)

    `lenbuf = len(buffer)` => `lenbuf = len_trim(buffer)`  (snSeti and snSetr)

    The first two change the argument from a variable length string to one with a known length (which are the max lengths according to snopt docs).  I had problems trying to pass variable length strings from Julia.  I believe this can be done with pointers and allocatable strings, but that requires changes on the Fortran side anyway (and the changes would be more extensive).  You must then always pass in a string of the correct length from Julia, so I pad the options with spaces in Julia, but this is transparent to the user.  The latter change computes the length without the whitespace at the end so that the messages printed in the files don't contain the extra padding.

4.  sn27lu.f, sn27lu77.f, and sn27lu90.f contain duplicate symbols.  You'll need to keep only one file.  I deleted the latter two files. If you are building with SNOPT v7.7 and do not define any user functions, you will also need to delete snopth.f.

5. Compile the fortran code.
```julia
(v1.0) pkg> build Snopt
```

**Note for ARM architectures (e.g., new macs)**

The ARM architecture does not yet support closures for C callbacks (see https://github.com/JuliaLang/julia/issues/27174).  A temporary workaround is in the "arm" branch.

## Run tests

```julia
(v1.0) pkg> test Snopt
```

## To Use

```julia
using Snopt
```

See examples in tests.
