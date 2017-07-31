cmake_minimum_required(VERSION 2.8)

#CMAKE_CXX_FLAGS
set(CMAKE_BUILD_TYPE "CMAKE_CXX_FLAGS" CACHE STRING "Choose the type of build, options are: Debug Release RelWithDebInfo MinSizeRel." FORCE)

# You need to set your own ITK directorty
set(ITK_DIR "/usr/local/itk/InsightToolkit-4.11.0/bin")

find_package(CUDA)

# Pass options to NVCC
set( CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS};
  -gencode arch=compute_30,code=sm_30 -gencode arch=compute_35,code=sm_35 -gencode arch=compute_37,code=sm_37 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_52,code=sm_52 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_60,code=compute_60)

find_package(ITK)
# itk include
include(${ITK_USE_FILE})

# Specify include directories
include_directories(
  # cuda helper functions
  ./common/inc/
  )

# Specify binary name and source file to build it from
cuda_add_executable(
  ImageMutualInformation
  cudaImageMutualInformation64bin.cu
  cudaImageMutualInformation256bin.cu
  ImageMutualInformation1.cxx
  cudaImageMutualInformation.cxx
  main.cpp
  )

# Sepcify libraries
target_link_libraries(
  ImageMutualInformation
  ${ITK_LIBRARIES}
  )
