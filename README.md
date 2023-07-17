# Snopt.jl

Julia interface to SNOPT v7 (must obtain a licensed copy of SNOPT separately).

This package is a wrapper of SNOPT v7.7.7 and provides two Julia interfaces to the subroutine snOptA: 
1. `snsolve`, a convenient interface with auto-populating sparsity patterns, vector lengths, variable/function naming, etc... 
2. `snopta`, an inferface that directly replicates that of the snOptA FORTRAN subroutine. 

NOTE: This package was originally forked from [byuflowlab/Snopt.jl](https://github.com/byuflowlab/Snopt.jl), but has recieved significant modification.

### To Install

1. Checkout the repo for development:
```julia
(v1.9) pkg> dev https://github.com/GrantHecht/Snopt.jl.git
```

2. Copy your SNOPT source files into ~/.julia/dev/Snopt/deps/src.

3. You will need to make a couple of changes to subroutine sn02lib.f. Function snSet, snSeti, and snSetr require the following changes:

    `character*(*) buffer` => `character buffer*72`   (snSet)

    `character*(*) buffer` => `character buffer*55`  (snSeti and snSetr)

    `lenbuf = len(buffer)` => `lenbuf = len_trim(buffer)`  (snSeti and snSetr)

    The first two change the argument from a variable length string to one with a known length (which are the max lengths according to snopt docs).  I had problems trying to pass variable length strings from Julia.  I believe this can be done with pointers and allocatable strings, but that requires changes on the Fortran side anyway (and the changes would be more extensive).  You must then always pass in a string of the correct length from Julia, so I pad the options with spaces in Julia, but this is transparent to the user.  The latter change computes the length without the whitespace at the end so that the messages printed in the files don't contain the extra padding.

4.  sn27lu.f, sn27lu77.f, and sn27lu90.f contain duplicate symbols.  You'll need to keep only one file.  I deleted the latter two files. If you are building with SNOPT v7.7 and do not define any user functions, you will also need to delete snopth.f.

5. Mofify the build script at ~/.julia/dev/Snopt/deps/build.jl to reflect the requirements of your system and the desired BLAS library (if any).

    CMake Options:
    * `cmake_path` - Should be set to "cmake" (if cmake is on system's PATH) or the full path to the cmake executable.

    Windows Build Options:
    * `win_use_msvc` - If true, will use [Microsoft Visual Studio](https://visualstudio.microsoft.com/downloads/) (MSVC) at the CMake generator. Otherwise, will default to using MinGW Makefiles which requires mingw32-make to be on the system's PATH (mingw32-make is included with builds of [MinGW-w64](https://github.com/niXman/mingw-builds-binaries/releases))
      
      If using MSVC on Windows, you must ensure that a Fortran compiler has been installed and setup with MSVC. Users are recommended to use the [Intel Fortran compiler](https://www.intel.com/content/www/us/en/developer/tools/oneapi/fortran-compiler.html#gs.38acdw) (ifort) installed with the [Intel oneAPI Base Toolkit](https://www.intel.com/content/www/us/en/developer/tools/oneapi/base-toolkit.html#gs.38afbg) when using MSVC as the generator.

      If NOT using MSVC on Windows, you must ensure a Fortran compiler is also on the system's PATH. Users are recommended to use the GNU Fortran compiler (gfortran), which is also included in builds of MinGW-w64.
      
    * `win_msvc_version` - If `win_use_msvc = true`, this should be set to the version number system's installation of MSVC.
    * `win_msvc_year` - If `win_use_msvc = true`, this should be set to release year of the system's installation of MSVC.
  
    Unix (Linux/Mac) Options:
    * `unix_use_gfortran` - TODO: currently unix builds default to first Fortran compiler found on system's PATH.
    * `unix_use_ninja` - If true, cmake will use ninja for the project generator. Otherwise, will default to GNU Makefiles.
  
    BLAS Options:
    * `use_BLAS` - If true, will use the BLAS library specified by one of the following options. Otherwise, build will employ the default BLAS included with SNOPT.
    * `use_MKL` - If true, will use the MKL BLAS library (the `use_BLAS` option must also be true). [Intel MKL](https://www.intel.com/content/www/us/en/developer/tools/oneapi/onemkl-download.html) must be properly installed on the user's system. MKL is included with the Intel oneAPI Base Toolkit (the recommended method for installing MKL).
    * `use_OpenBLAS` - If true, will use the OpenBLAS library (the `use_BLAS` option must also be true). [OpenBLAS](https://www.openblas.net/) must be properly installed on the user's system.
    * `OpenBLAS_DIR` - If using OpenBLAS, cmake can fail to find the required library if it is not installed globally. If this problem occurs, `OpenBLAS_DIR` should be set to the OpenBLAS directory that contains the file "OpenBLASConfig.cmake".

7. Compile the fortran code.
```julia
(v1.9) pkg> build Snopt
```

## Run tests

```julia
(v1.9) pkg> test Snopt
```

## To Use

```julia
using Snopt
```

See examples in test and examples directories.
