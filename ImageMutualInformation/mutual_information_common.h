/*
 * Copyright 1993-2015 NVIDIA Corporation.  All rights reserved.
 *
 * Please refer to the NVIDIA end user license agreement (EULA) associated
 * with this source code for terms and conditions that govern your use of
 * this software. Any use, reproduction, disclosure, or distribution of
 * this software and related documentation outside the terms of the EULA
 * is strictly prohibited.
 *
 */

#ifndef MUTUAL_INFORMATION_COMMON_H
#define MUTUAL_INFORMATION_COMMON_H

////////////////////////////////////////////////////////////////////////////////
// Common definitions
////////////////////////////////////////////////////////////////////////////////
#define UINT_BITS 32
typedef unsigned int uint;
typedef unsigned char uchar;

////////////////////////////////////////////////////////////////////////////////
// GPU-specific common definitions
////////////////////////////////////////////////////////////////////////////////
#define LOG2_WARP_SIZE 5U // 5 = log (32) / log (2)
#define WARP_SIZE 32

//May change on future hardware, so better parametrize the code
#define SHARED_MEMORY_BANKS 16

//Threadblock size: must be a multiple of (4 * SHARED_MEMORY_BANKS)
//because of the bit permutation of threadIdx.x

//#define HISTOGRAM64_THREADBLOCK_SIZE (4 * SHARED_MEMORY_BANKS)

// Warps ==subhistograms per threadblock
#define WARP_COUNT 32
#define WARP_COUNT256 16


#define HISTOGRAM64_BIN_COUNT 64
#define JOINT_HISTOGRAM64_BIN_COUNT 64*64

// Threadblock size
#define HISTOGRAM64_THREADBLOCK_SIZE (WARP_COUNT * WARP_SIZE) 
// Histogram shared memory per threadblock
#define HISTOGRAM64_THREADBLOCK_MEMORY (WARP_COUNT * HISTOGRAM64_BIN_COUNT)
// Joint histogram shared memory
#define JOINT_HISTOGRAM64_THREADBLOCK_MEMORY (HISTOGRAM64_BIN_COUNT * HISTOGRAM64_BIN_COUNT)


#define HISTOGRAM256_BIN_COUNT 256
#define JOINT_HISTOGRAM256_BIN_COUNT 256*256

// Threadblock size
#define HISTOGRAM256_THREADBLOCK_SIZE (WARP_COUNT256 * WARP_SIZE)
// Histogram shared memory per threadblock
#define HISTOGRAM256_THREADBLOCK_MEMORY (WARP_COUNT256 * HISTOGRAM256_BIN_COUNT)
// Joint histogram shared memory
#define JOINT_HISTOGRAM256_THREADBLOCK_MEMORY (HISTOGRAM256_BIN_COUNT * HISTOGRAM256_BIN_COUNT)




#define UMUL(a, b) ( (a) * (b) )
#define UMAD(a, b, c) ( UMUL((a), (b)) + (c) )

////////////////////////////////////////////////////////////////////////////////
// GPU histogram
////////////////////////////////////////////////////////////////////////////////
extern "C" void initHistogram64(void);
extern "C" void initHistogram256(void);
extern "C" void closeHistogram64(void);
extern "C" void closeHistogram256(void);


extern "C" void histogram64(
			    uint *d_JointHistogram,
			    uint *d_Histogram1,
			    uint *d_Histogram2,
			    void *d_Data1,
			    void *d_Data2,
			    uint byteCount1,
			    uint byteCount2
			    );

extern "C" void histogram256(
			     uint *d_JointHistogram,
			     uint *d_Histogram1,
			     uint *d_Histogram2,
			     void *d_Data1,
			     void *d_Data2,
			     uint byteCount1,
			     uint byteCount2
			     );




extern "C" bool cudaImageMutualInformation64(double *entropy1, double *entropy2, double *entropy3,
					     uint *jointHist, uint *hist1, uint *hist2,
					     uchar *data1, uint byteCount1, uchar *data2, uint byteCount2);


extern "C" bool cudaImageMutualInformation256(
					      double *entropy1, double *entropy2, double *entropy3,
					      uint *jointHist, uint *hist1, uint *hist2,
					      uchar *data1, uint byteCount1, uchar *data2, uint byteCount2);


bool itkImageMutualInformation( const std::string &image1Name, const std::string &image2Name, const uint &bin_count);


bool cudaImageMutualInformation(const std::string &image1Name, const std::string &image2Name, const uint &bin_count);





#endif
