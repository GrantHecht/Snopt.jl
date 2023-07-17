LIST(APPEND CMAKE_MODULE_PATH "C:/Source/OpenBLAS/install/share/cmake/OpenBLAS")

IF (USE_EXTERNAL_BLAS)
    IF (USE_MKL)
        FIND_PACKAGE(MKL CONFIG REQUIRED)
    ELSEIF (USE_OPENBLAS)
        FIND_PACKAGE(OpenBLAS REQUIRED)
    ELSE()
        FIND_PACKAGE(BLAS REQUIRED)
        ADD_DEFINITIONS(-DUSE_BLAS)
    ENDIF()
ENDIF()