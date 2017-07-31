#  James Bigler, NVIDIA Corp (nvidia.com - jbigler)
#
#  Copyright (c) 2008 - 2009 NVIDIA Corporation.  All rights reserved.
#
#  This code is licensed under the MIT License.  See the FindCUDA.cmake script
#  for the text of the license.

# The MIT License
#
# License for the specific language governing rights and limitations under
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.


##########################################################################
# This file runs the nvcc commands to produce the desired output file along with
# the dependency file needed by CMake to compute dependencies.  In addition the
# file checks the output of each command and if the command fails it deletes the
# output files.

# Input variables
#
# verbose:BOOL=<>          OFF: Be as quiet as possible (default)
#                          ON : Describe each step
#
# build_configuration:STRING=<> Typically one of Debug, MinSizeRel, Release, or
#                               RelWithDebInfo, but it should match one of the
#                               entries in CUDA_HOST_FLAGS. This is the build
#                               configuration used when compiling the code.  If
#                               blank or unspecified Debug is assumed as this is
#                               what CMake does.
#
# generated_file:STRING=<> File to generate.  This argument must be passed in.
#
# generated_cubin_file:STRING=<> File to generate.  This argument must be passed
#                                                   in if build_cubin is true.

if(NOT generated_file)
  message(FATAL_ERROR "You must specify generated_file on the command line")
endif()

# Set these up as variables to make reading the generated file easier
set(CMAKE_COMMAND "/usr/bin/cmake") # path
set(source_file "/home/yan/cs9535project/MattesMutualInformation/MattesMutualInformation/cudaMattesMutualInformation64bin.cu") # path
set(NVCC_generated_dependency_file "/home/yan/cs9535project/MattesMutualInformation/MattesMutualInformation/build/CMakeFiles/mattesMutualInformation.dir//mattesMutualInformation_generated_cudaMattesMutualInformation64bin.cu.o.NVCC-depend") # path
set(cmake_dependency_file "/home/yan/cs9535project/MattesMutualInformation/MattesMutualInformation/build/CMakeFiles/mattesMutualInformation.dir//mattesMutualInformation_generated_cudaMattesMutualInformation64bin.cu.o.depend") # path
set(CUDA_make2cmake "/usr/share/cmake-3.5/Modules/FindCUDA/make2cmake.cmake") # path
set(CUDA_parse_cubin "/usr/share/cmake-3.5/Modules/FindCUDA/parse_cubin.cmake") # path
set(build_cubin OFF) # bool
set(CUDA_HOST_COMPILER "/usr/bin/cc") # path
# We won't actually use these variables for now, but we need to set this, in
# order to force this file to be run again if it changes.
set(generated_file_path "/home/yan/cs9535project/MattesMutualInformation/MattesMutualInformation/build/CMakeFiles/mattesMutualInformation.dir//.") # path
set(generated_file_internal "/home/yan/cs9535project/MattesMutualInformation/MattesMutualInformation/build/CMakeFiles/mattesMutualInformation.dir//./mattesMutualInformation_generated_cudaMattesMutualInformation64bin.cu.o") # path
set(generated_cubin_file_internal "/home/yan/cs9535project/MattesMutualInformation/MattesMutualInformation/build/CMakeFiles/mattesMutualInformation.dir//./mattesMutualInformation_generated_cudaMattesMutualInformation64bin.cu.o.cubin.txt") # path

set(CUDA_NVCC_EXECUTABLE "/usr/local/cuda-8.0/bin/nvcc") # path
set(CUDA_NVCC_FLAGS -gencode;arch=compute_30,code=sm_30;-gencode;arch=compute_35,code=sm_35;-gencode;arch=compute_37,code=sm_37;-gencode;arch=compute_50,code=sm_50;-gencode;arch=compute_52,code=sm_52;-gencode;arch=compute_60,code=sm_60;-gencode;arch=compute_60,code=compute_60 ;; ) # list
# Build specific configuration flags
set(CUDA_NVCC_FLAGS_CMAKE_CXX_FLAGS  ; )
set(CUDA_NVCC_FLAGS_DEBUG  ; )
set(CUDA_NVCC_FLAGS_MINSIZEREL  ; )
set(CUDA_NVCC_FLAGS_RELEASE  ; )
set(CUDA_NVCC_FLAGS_RELWITHDEBINFO  ; )
set(nvcc_flags -m64;-DITK_IO_FACTORY_REGISTER_MANAGER) # list
set(CUDA_NVCC_INCLUDE_ARGS "-I/usr/local/cuda-8.0/include;-I/home/yan/cs9535project/MattesMutualInformation/MattesMutualInformation/build/ITKIOFactoryRegistration;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Segmentation/Watersheds/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Segmentation/Voronoi/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Video/IO/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Video/Filtering/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Video/Core/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Bridge/VTK/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Core/TestKernel/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/TIFF/src;-I/usr/local/itk/InsightToolkit-4.11.0/bin/Modules/ThirdParty/TIFF/src/itktiff;-I/usr/local/itk/InsightToolkit-4.11.0/bin/Modules/ThirdParty/TIFF/src;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/SpatialFunction/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Registration/RegistrationMethodsv4/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Segmentation/RegionGrowing/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/QuadEdgeMeshFiltering/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/PNG/src;-I/usr/local/itk/InsightToolkit-4.11.0/bin/Modules/ThirdParty/PNG/src;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/NrrdIO/src/NrrdIO;-I/usr/local/itk/InsightToolkit-4.11.0/bin/Modules/ThirdParty/NrrdIO/src/NrrdIO;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Numerics/NeuralNetworks/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Numerics/Optimizersv4/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Registration/Metricsv4/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Segmentation/MarkovRandomFieldsClassifiers/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Segmentation/LevelSetsv4/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Segmentation/LabelVoting/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Segmentation/KLMRegionGrowing/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/JPEG/src;-I/usr/local/itk/InsightToolkit-4.11.0/bin/Modules/ThirdParty/JPEG/src;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/ImageNoise/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/ImageFusion/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/XML/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/VTK/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/TransformMatlab/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/TransformInsightLegacy/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/TransformHDF5/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/TransformFactory/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/TransformBase/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/TIFF/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/Stimulate/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/Siemens/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/RAW/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/PNG/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/NRRD/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/NIFTI/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/Meta/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/Mesh/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/MRC/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/LSM/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/JPEG/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/IPL/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/HDF5/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/GIPL/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/GE/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/GDCM/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/CSV/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/BioRad/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/BMP/include;-I/usr/local/itk/InsightToolkit-4.11.0/bin/Modules/ThirdParty/HDF5/src;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/HDF5/src;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/GPUThresholding/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/GPUSmoothing/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Registration/GPUCommon/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Registration/GPUPDEDeformable/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/GPUImageFilterBase/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Core/GPUFiniteDifference/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Core/GPUCommon/include;-I/usr/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/GPUAnisotropicSmoothing/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/NIFTI/src/nifti/znzlib;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/NIFTI/src/nifti/niftilib;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/GIFTI/src/gifticlib;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/GDCM/src/gdcm/Source/DataStructureAndEncodingDefinition;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/GDCM/src/gdcm/Source/MessageExchangeDefinition;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/GDCM/src/gdcm/Source/InformationObjectDefinition;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/GDCM/src/gdcm/Source/Common;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/GDCM/src/gdcm/Source/DataDictionary;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/GDCM/src/gdcm/Source/MediaStorageAndFileFormat;-I/usr/local/itk/InsightToolkit-4.11.0/bin/Modules/ThirdParty/GDCM/src/gdcm/Source/Common;-I/usr/local/itk/InsightToolkit-4.11.0/bin/Modules/ThirdParty/GDCM;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Registration/PDEDeformable/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Registration/FEM/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Registration/Common/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/SpatialObjects/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Numerics/FEM/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/Expat/src/expat;-I/usr/local/itk/InsightToolkit-4.11.0/bin/Modules/ThirdParty/Expat/src/expat;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Numerics/Eigen/include;-I/usr/local/itk/InsightToolkit-4.11.0/bin/Modules/ThirdParty/DoubleConversion/src/double-conversion;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/DoubleConversion/src/double-conversion;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/DisplacementField/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/DiffusionTensorImage/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/Denoising/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Segmentation/DeformableMesh/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/Deconvolution/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/DICOMParser/src/DICOMParser;-I/usr/local/itk/InsightToolkit-4.11.0/bin/Modules/ThirdParty/DICOMParser/src/DICOMParser;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/FFT/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/Convolution/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/Colormap/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Segmentation/Classifiers/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Segmentation/BioCell/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Numerics/Polynomials/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/BiasCorrection/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Segmentation/SignedDistanceFunction/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Numerics/Optimizers/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/ImageSources/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/Smoothing/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/ImageGradient/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/ImageFeature/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/ImageCompare/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/IO/ImageBase/include;-I/usr/local/itk/InsightToolkit-4.11.0/bin/Modules/IO/ImageBase;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Core/QuadEdgeMesh/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Core/Mesh/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/FastMarching/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Numerics/NarrowBand/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/ImageLabel/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/Thresholding/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/Path/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/ZLIB/src;-I/usr/local/itk/InsightToolkit-4.11.0/bin/Modules/ThirdParty/ZLIB/src;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/MetaIO/src/MetaIO/src;-I/usr/local/itk/InsightToolkit-4.11.0/bin/Modules/ThirdParty/MetaIO/src/MetaIO/src;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Core/SpatialObjects/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/ImageCompose/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/ImageStatistics/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/ImageIntensity/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Segmentation/ConnectedComponents/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/MathematicalMorphology/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/LabelMap/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/BinaryMathematicalMorphology/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/DistanceMap/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Segmentation/LevelSets/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/AntiAlias/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Core/Transform/include;-I/usr/local/itk/InsightToolkit-4.11.0/bin/Modules/ThirdParty/Netlib;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Numerics/Statistics/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Core/ImageAdaptors/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Core/ImageFunction/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/ImageGrid/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/ImageFilterBase/include;-I/usr/local/itk/InsightToolkit-4.11.0/bin/Modules/ThirdParty/VNL/src/vxl/core;-I/usr/local/itk/InsightToolkit-4.11.0/bin/Modules/ThirdParty/VNL/src/vxl/vcl;-I/usr/local/itk/InsightToolkit-4.11.0/bin/Modules/ThirdParty/VNL/src/vxl/v3p/netlib;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/VNL/src/vxl/core;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/VNL/src/vxl/vcl;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/VNL/src/vxl/v3p/netlib;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/VNLInstantiation/include;-I/usr/local/itk/InsightToolkit-4.11.0/bin/Modules/ThirdParty/KWSys/src;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/ThirdParty/KWIML/src;-I/usr/local/itk/InsightToolkit-4.11.0/bin/Modules/ThirdParty/KWIML/src;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Core/Common/include;-I/usr/local/itk/InsightToolkit-4.11.0/bin/Modules/Core/Common;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Core/FiniteDifference/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/CurvatureFlow/include;-I/usr/local/itk/InsightToolkit-4.11.0/Modules/Filtering/AnisotropicSmoothing/include;-I/home/yan/cs9535project/MattesMutualInformation/MattesMutualInformation/./common/inc;-I/usr/local/cuda-8.0/include") # list (needs to be in quotes to handle spaces properly).
set(format_flag "-c") # string
set(cuda_language_flag ) # list

if(build_cubin AND NOT generated_cubin_file)
  message(FATAL_ERROR "You must specify generated_cubin_file on the command line")
endif()

# This is the list of host compilation flags.  It C or CXX should already have
# been chosen by FindCUDA.cmake.
set(CMAKE_HOST_FLAGS   -msse2 )
set(CMAKE_HOST_FLAGS_CMAKE_CXX_FLAGS )
set(CMAKE_HOST_FLAGS_DEBUG -g)
set(CMAKE_HOST_FLAGS_MINSIZEREL -Os -DNDEBUG)
set(CMAKE_HOST_FLAGS_RELEASE -O3 -DNDEBUG)
set(CMAKE_HOST_FLAGS_RELWITHDEBINFO -O2 -g -DNDEBUG)

# Take the compiler flags and package them up to be sent to the compiler via -Xcompiler
set(nvcc_host_compiler_flags "")
# If we weren't given a build_configuration, use Debug.
if(NOT build_configuration)
  set(build_configuration Debug)
endif()
string(TOUPPER "${build_configuration}" build_configuration)
#message("CUDA_NVCC_HOST_COMPILER_FLAGS = ${CUDA_NVCC_HOST_COMPILER_FLAGS}")
foreach(flag ${CMAKE_HOST_FLAGS} ${CMAKE_HOST_FLAGS_${build_configuration}})
  # Extra quotes are added around each flag to help nvcc parse out flags with spaces.
  set(nvcc_host_compiler_flags "${nvcc_host_compiler_flags},\"${flag}\"")
endforeach()
if (nvcc_host_compiler_flags)
  set(nvcc_host_compiler_flags "-Xcompiler" ${nvcc_host_compiler_flags})
endif()
#message("nvcc_host_compiler_flags = \"${nvcc_host_compiler_flags}\"")
# Add the build specific configuration flags
list(APPEND CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS_${build_configuration}})

# Any -ccbin existing in CUDA_NVCC_FLAGS gets highest priority
list( FIND CUDA_NVCC_FLAGS "-ccbin" ccbin_found0 )
list( FIND CUDA_NVCC_FLAGS "--compiler-bindir" ccbin_found1 )
if( ccbin_found0 LESS 0 AND ccbin_found1 LESS 0 AND CUDA_HOST_COMPILER )
  if (CUDA_HOST_COMPILER STREQUAL "$(VCInstallDir)bin" AND DEFINED CCBIN)
    set(CCBIN -ccbin "${CCBIN}")
  else()
    set(CCBIN -ccbin "${CUDA_HOST_COMPILER}")
  endif()
endif()

# cuda_execute_process - Executes a command with optional command echo and status message.
#
#   status  - Status message to print if verbose is true
#   command - COMMAND argument from the usual execute_process argument structure
#   ARGN    - Remaining arguments are the command with arguments
#
#   CUDA_result - return value from running the command
#
# Make this a macro instead of a function, so that things like RESULT_VARIABLE
# and other return variables are present after executing the process.
macro(cuda_execute_process status command)
  set(_command ${command})
  if(NOT "x${_command}" STREQUAL "xCOMMAND")
    message(FATAL_ERROR "Malformed call to cuda_execute_process.  Missing COMMAND as second argument. (command = ${command})")
  endif()
  if(verbose)
    execute_process(COMMAND "${CMAKE_COMMAND}" -E echo -- ${status})
    # Now we need to build up our command string.  We are accounting for quotes
    # and spaces, anything else is left up to the user to fix if they want to
    # copy and paste a runnable command line.
    set(cuda_execute_process_string)
    foreach(arg ${ARGN})
      # If there are quotes, excape them, so they come through.
      string(REPLACE "\"" "\\\"" arg ${arg})
      # Args with spaces need quotes around them to get them to be parsed as a single argument.
      if(arg MATCHES " ")
        list(APPEND cuda_execute_process_string "\"${arg}\"")
      else()
        list(APPEND cuda_execute_process_string ${arg})
      endif()
    endforeach()
    # Echo the command
    execute_process(COMMAND ${CMAKE_COMMAND} -E echo ${cuda_execute_process_string})
  endif()
  # Run the command
  execute_process(COMMAND ${ARGN} RESULT_VARIABLE CUDA_result )
endmacro()

# Delete the target file
cuda_execute_process(
  "Removing ${generated_file}"
  COMMAND "${CMAKE_COMMAND}" -E remove "${generated_file}"
  )

# For CUDA 2.3 and below, -G -M doesn't work, so remove the -G flag
# for dependency generation and hope for the best.
set(depends_CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS}")
set(CUDA_VERSION 8.0)
if(CUDA_VERSION VERSION_LESS "3.0")
  cmake_policy(PUSH)
  # CMake policy 0007 NEW states that empty list elements are not
  # ignored.  I'm just setting it to avoid the warning that's printed.
  cmake_policy(SET CMP0007 NEW)
  # Note that this will remove all occurances of -G.
  list(REMOVE_ITEM depends_CUDA_NVCC_FLAGS "-G")
  cmake_policy(POP)
endif()

# nvcc doesn't define __CUDACC__ for some reason when generating dependency files.  This
# can cause incorrect dependencies when #including files based on this macro which is
# defined in the generating passes of nvcc invokation.  We will go ahead and manually
# define this for now until a future version fixes this bug.
set(CUDACC_DEFINE -D__CUDACC__)

# Generate the dependency file
cuda_execute_process(
  "Generating dependency file: ${NVCC_generated_dependency_file}"
  COMMAND "${CUDA_NVCC_EXECUTABLE}"
  -M
  ${CUDACC_DEFINE}
  "${source_file}"
  -o "${NVCC_generated_dependency_file}"
  ${CCBIN}
  ${nvcc_flags}
  ${nvcc_host_compiler_flags}
  ${depends_CUDA_NVCC_FLAGS}
  -DNVCC
  ${CUDA_NVCC_INCLUDE_ARGS}
  )

if(CUDA_result)
  message(FATAL_ERROR "Error generating ${generated_file}")
endif()

# Generate the cmake readable dependency file to a temp file.  Don't put the
# quotes just around the filenames for the input_file and output_file variables.
# CMake will pass the quotes through and not be able to find the file.
cuda_execute_process(
  "Generating temporary cmake readable file: ${cmake_dependency_file}.tmp"
  COMMAND "${CMAKE_COMMAND}"
  -D "input_file:FILEPATH=${NVCC_generated_dependency_file}"
  -D "output_file:FILEPATH=${cmake_dependency_file}.tmp"
  -P "${CUDA_make2cmake}"
  )

if(CUDA_result)
  message(FATAL_ERROR "Error generating ${generated_file}")
endif()

# Copy the file if it is different
cuda_execute_process(
  "Copy if different ${cmake_dependency_file}.tmp to ${cmake_dependency_file}"
  COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${cmake_dependency_file}.tmp" "${cmake_dependency_file}"
  )

if(CUDA_result)
  message(FATAL_ERROR "Error generating ${generated_file}")
endif()

# Delete the temporary file
cuda_execute_process(
  "Removing ${cmake_dependency_file}.tmp and ${NVCC_generated_dependency_file}"
  COMMAND "${CMAKE_COMMAND}" -E remove "${cmake_dependency_file}.tmp" "${NVCC_generated_dependency_file}"
  )

if(CUDA_result)
  message(FATAL_ERROR "Error generating ${generated_file}")
endif()

# Generate the code
cuda_execute_process(
  "Generating ${generated_file}"
  COMMAND "${CUDA_NVCC_EXECUTABLE}"
  "${source_file}"
  ${cuda_language_flag}
  ${format_flag} -o "${generated_file}"
  ${CCBIN}
  ${nvcc_flags}
  ${nvcc_host_compiler_flags}
  ${CUDA_NVCC_FLAGS}
  -DNVCC
  ${CUDA_NVCC_INCLUDE_ARGS}
  )

if(CUDA_result)
  # Since nvcc can sometimes leave half done files make sure that we delete the output file.
  cuda_execute_process(
    "Removing ${generated_file}"
    COMMAND "${CMAKE_COMMAND}" -E remove "${generated_file}"
    )
  message(FATAL_ERROR "Error generating file ${generated_file}")
else()
  if(verbose)
    message("Generated ${generated_file} successfully.")
  endif()
endif()

# Cubin resource report commands.
if( build_cubin )
  # Run with -cubin to produce resource usage report.
  cuda_execute_process(
    "Generating ${generated_cubin_file}"
    COMMAND "${CUDA_NVCC_EXECUTABLE}"
    "${source_file}"
    ${CUDA_NVCC_FLAGS}
    ${nvcc_flags}
    ${CCBIN}
    ${nvcc_host_compiler_flags}
    -DNVCC
    -cubin
    -o "${generated_cubin_file}"
    ${CUDA_NVCC_INCLUDE_ARGS}
    )

  # Execute the parser script.
  cuda_execute_process(
    "Executing the parser script"
    COMMAND  "${CMAKE_COMMAND}"
    -D "input_file:STRING=${generated_cubin_file}"
    -P "${CUDA_parse_cubin}"
    )

endif()
