#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// CUDA includes
#include <cuda_runtime.h>
#include <helper_functions.h>
#include <helper_cuda.h>
#include "mutual_information_common.h"


#define LOG_2 std::log(2.0)

////////////////////////////////////////////////////////////////////////////////
// Shortcut shared memory atomic addition functions
////////////////////////////////////////////////////////////////////////////////
inline __device__ void addByte(uint *s_JointHist, uint *s_WarpHist1, uint *s_WarpHist2, uint data1, uint data2)
{
  uint d1 = data1 / 4;
  uint d2 = data2 / 4;
  atomicAdd(s_WarpHist1 + d1, 1);
  atomicAdd(s_WarpHist2 + d2, 1);
  atomicAdd(s_JointHist + d1 * HISTOGRAM64_BIN_COUNT + d2, 1);
}

inline __device__ void addWord(uint *s_JointHist, uint *s_WarpHist1, uint *s_WarpHist2, uint data1, uint data2)
{
  addByte(s_JointHist, s_WarpHist1, s_WarpHist2, (data1 >> 0) & 0xFFU, (data2 >>  0) & 0xFFU);
  addByte(s_JointHist, s_WarpHist1, s_WarpHist2, (data1 >> 8) & 0xFFU, (data2 >>  8) & 0xFFU);
  addByte(s_JointHist, s_WarpHist1, s_WarpHist2, (data1 >> 16) & 0xFFU, (data2 >>  16) & 0xFFU);
  addByte(s_JointHist, s_WarpHist1, s_WarpHist2, (data1 >> 24) & 0xFFU, (data2 >>  24) & 0xFFU);
}


__global__ void histogram64Kernel(uint *d_PartialJointHistograms,
				  uint *d_PartialHistograms1, uint *d_PartialHistograms2,
				  uint *d_Data1, uint *d_Data2, uint dataCount)
{
  __shared__ uint s_Hist1[HISTOGRAM64_THREADBLOCK_MEMORY]; //  warp_count * 64
  __shared__ uint s_Hist2[HISTOGRAM64_THREADBLOCK_MEMORY]; //  warp_count * 64
  __shared__ uint s_JointHist[JOINT_HISTOGRAM64_THREADBLOCK_MEMORY]; // 64 * 64
 
  // calculating starting position for the warp
  uint *s_WarpHist1 = s_Hist1 + (threadIdx.x >> LOG2_WARP_SIZE) * HISTOGRAM64_BIN_COUNT;
  uint *s_WarpHist2 = s_Hist2 + (threadIdx.x >> LOG2_WARP_SIZE) * HISTOGRAM64_BIN_COUNT;

  
  // Clear shared memory storage for current threadblock before processing
#pragma unroll
  // memory = 6 * 64  ; block size = 6 * 32
  // i < 2
  for (uint i = 0; i < (HISTOGRAM64_THREADBLOCK_MEMORY / HISTOGRAM64_THREADBLOCK_SIZE); i++)
    {
      s_Hist1[threadIdx.x + i * HISTOGRAM64_THREADBLOCK_SIZE] = 0;
      s_Hist2[threadIdx.x + i * HISTOGRAM64_THREADBLOCK_SIZE] = 0;
    }

  for (uint i = 0; i < (JOINT_HISTOGRAM64_THREADBLOCK_MEMORY / HISTOGRAM64_THREADBLOCK_SIZE); i++)
    {
      s_JointHist[threadIdx.x + i * HISTOGRAM64_THREADBLOCK_SIZE] = 0;
    }
  __syncthreads();

  for (uint pos = UMAD(blockIdx.x, blockDim.x, threadIdx.x); pos < dataCount; pos += UMUL(blockDim.x, gridDim.x))
    {
      uint data1 = d_Data1[pos];
      uint data2 = d_Data2[pos];
      addWord(s_JointHist, s_WarpHist1, s_WarpHist2, data1, data2);
    }
  // Merge per-warp histograms into per-block and write to global memory
  __syncthreads();

  for (uint bin = threadIdx.x; bin < HISTOGRAM64_BIN_COUNT; bin += HISTOGRAM64_THREADBLOCK_SIZE)
    {
      uint sum1 = 0;
      uint sum2 = 0;

      for (uint i = 0; i < WARP_COUNT; i++)
	{
	  sum1 += s_Hist1[bin + i * HISTOGRAM64_BIN_COUNT];
	  sum2 += s_Hist2[bin + i * HISTOGRAM64_BIN_COUNT];
	}
      // per block sub-histogram 
      d_PartialHistograms1[blockIdx.x * HISTOGRAM64_BIN_COUNT + bin] = sum1;
      d_PartialHistograms2[blockIdx.x * HISTOGRAM64_BIN_COUNT + bin] = sum2;  
    }
  
  // store shared Joint histogram on global mem
  for (uint i = 0; i < (JOINT_HISTOGRAM64_THREADBLOCK_MEMORY / HISTOGRAM64_THREADBLOCK_SIZE); i++)
    {
      d_PartialJointHistograms[blockIdx.x * JOINT_HISTOGRAM64_BIN_COUNT + threadIdx.x + i * HISTOGRAM64_THREADBLOCK_SIZE]
	= s_JointHist[threadIdx.x + i * HISTOGRAM64_THREADBLOCK_SIZE];
    }
}
////////////////////////////////////////////////////////////////////////////////
// Merge histogram64() output
// Run one threadblock per bin; each threadblock adds up the same bin counter
// from every partial histogram. Reads are uncoalesced, but mergeHistogram256
// takes only a fraction of total processing time
////////////////////////////////////////////////////////////////////////////////
#define MERGE_THREADBLOCK_SIZE 1024

__global__ void mergeHistogram64Kernel(
				       uint *d_Histogram1,
				       uint *d_Histogram2,
				       uint *d_PartialHistograms1,
				       uint *d_PartialHistograms2,
				       uint histogramCount )
{
  uint sum1 = 0;
  uint sum2 = 0;
  
  for (uint i = threadIdx.x; i < histogramCount; i += MERGE_THREADBLOCK_SIZE)
    {
      sum1 += d_PartialHistograms1[blockIdx.x + i * HISTOGRAM64_BIN_COUNT];
      sum2 += d_PartialHistograms2[blockIdx.x + i * HISTOGRAM64_BIN_COUNT];
    }

  __shared__ uint data1[MERGE_THREADBLOCK_SIZE];
  __shared__ uint data2[MERGE_THREADBLOCK_SIZE];
  
  data1[threadIdx.x] = sum1;
  data2[threadIdx.x] = sum2;

  for (uint stride = MERGE_THREADBLOCK_SIZE / 2; stride > 0; stride >>= 1)
    {
      __syncthreads();
      // reduction
      if (threadIdx.x < stride)
        {
	  data1[threadIdx.x] += data1[threadIdx.x + stride];
	  data2[threadIdx.x] += data2[threadIdx.x + stride];
        }
    }
  // blockIdx is the bin number.
  if (threadIdx.x == 0)
    {
      d_Histogram1[blockIdx.x] = data1[0];
      d_Histogram2[blockIdx.x] = data2[0];
    }
}


__global__ void mergeJointHistogram64Kernel(uint *d_JointHistogram, uint *d_PartialHistograms, uint jointHistogramCount )
{
  double sum = 0;
  for (uint i = threadIdx.x; i < jointHistogramCount; i += MERGE_THREADBLOCK_SIZE)
    {
      sum += d_PartialHistograms[blockIdx.x + i * JOINT_HISTOGRAM64_BIN_COUNT];
    }

  __shared__ uint data[MERGE_THREADBLOCK_SIZE];

  data[threadIdx.x] = sum;

  for (uint stride = MERGE_THREADBLOCK_SIZE / 2; stride > 0; stride >>= 1)
    {
      __syncthreads();
      if (threadIdx.x < stride)
	{
	  data[threadIdx.x] += data[threadIdx.x + stride];
	}
    }
  if (threadIdx.x == 0)
    {
      d_JointHistogram[blockIdx.x] = data[0];
    }
}


static const uint PARTIAL_HISTOGRAM64_COUNT = 240;
static uint *d_PartialHistograms1;
static uint *d_PartialHistograms2;
static uint *d_PartialJointHistograms;
static double *d_PartialJointEntropy;
static double *d_ImageEntropy1;
static double *d_ImageEntropy2;
static double *d_JointEntropy;


//Internal memory allocation
extern "C" void initHistogram64(void)
{
  //d_PartialHistogram is a uint array of size 240 * 64,
  checkCudaErrors(cudaMalloc((void **)&d_PartialHistograms1, PARTIAL_HISTOGRAM64_COUNT * HISTOGRAM64_BIN_COUNT * sizeof(uint)));
  checkCudaErrors(cudaMalloc((void **)&d_PartialHistograms2, PARTIAL_HISTOGRAM64_COUNT * HISTOGRAM64_BIN_COUNT * sizeof(uint)));
  checkCudaErrors(cudaMalloc((void **)&d_PartialJointHistograms, PARTIAL_HISTOGRAM64_COUNT * JOINT_HISTOGRAM64_BIN_COUNT * sizeof(uint)));
  checkCudaErrors(cudaMalloc((void **)&d_PartialJointEntropy, HISTOGRAM64_BIN_COUNT * sizeof(double)));
  checkCudaErrors(cudaMalloc((void **)&d_ImageEntropy1, sizeof(double)));
  checkCudaErrors(cudaMalloc((void **)&d_ImageEntropy2, sizeof(double)));
  checkCudaErrors(cudaMalloc((void **)&d_JointEntropy, sizeof(double)));
 
}

//Internal memory deallocation
extern "C" void closeHistogram64(void)
{
  checkCudaErrors(cudaFree(d_PartialHistograms1));
  checkCudaErrors(cudaFree(d_PartialHistograms2));
  checkCudaErrors(cudaFree(d_PartialJointHistograms));
  checkCudaErrors(cudaFree(d_PartialJointEntropy));
}


extern "C" void histogram64(
			    uint *d_JointHistogram,
			    uint *d_Histogram1,
			    uint *d_Histogram2,
			    void *d_Data1,
			    void *d_Data2,
			    uint byteCount1,
			    uint byteCount2)
{
  // assert(byteCount % sizeof(uint) == 0);

  uint byteCount = (byteCount1 < byteCount2) ? byteCount1 : byteCount2;
  
  histogram64Kernel<<<PARTIAL_HISTOGRAM64_COUNT, HISTOGRAM64_THREADBLOCK_SIZE>>>(   d_PartialJointHistograms,
										    d_PartialHistograms1,
										    d_PartialHistograms2,
										    (uint *)d_Data1,
										    (uint *)d_Data2,
										    byteCount
										    );
  getLastCudaError("histogram64Kernel() execution failed\n");
  

  mergeHistogram64Kernel<<<HISTOGRAM64_BIN_COUNT, MERGE_THREADBLOCK_SIZE>>>(
									    d_Histogram1,
									    d_Histogram2,
									    d_PartialHistograms1,
									    d_PartialHistograms2,
									    PARTIAL_HISTOGRAM64_COUNT
									    );
  getLastCudaError("mergeHistogram64Kernel() execution failed\n");


  mergeJointHistogram64Kernel<<<JOINT_HISTOGRAM64_BIN_COUNT, MERGE_THREADBLOCK_SIZE>>>(
										       d_JointHistogram,
										       d_PartialJointHistograms,
										       PARTIAL_HISTOGRAM64_COUNT
										       );
  getLastCudaError("mergeJointHistogram64Kernel() execution failed\n");
  
}


__global__ void entropy_kernel(double *d_ImageEntropy1,
			       double *d_ImageEntropy2,
			       uint *d_Histogram1,
			       uint *d_Histogram2,
			       uint totalCount)
{
  // calculate entropy 1 in block 0
  if (blockIdx.x == 0)
    {
      __shared__ double s_entropy1[HISTOGRAM64_BIN_COUNT];
      uint tid = threadIdx.x;
  
      if(d_Histogram1[tid])
	s_entropy1[tid] = - ((double)d_Histogram1[tid] / totalCount) * std::log((double)d_Histogram1[tid] / totalCount ) / LOG_2;
      else
	s_entropy1[tid] = 0;
      // before reduce, make sure threads within block finish its own work.
      __syncthreads();
      // reduction method from CUDA sample reduction code ( most optimized )
      if (tid < 32) s_entropy1[tid] += s_entropy1[tid + 32];	  
      if (tid < 16) s_entropy1[tid] += s_entropy1[tid + 16];	  
      if (tid < 8) s_entropy1[tid] += s_entropy1[tid + 8];	  
      if (tid < 4) s_entropy1[tid] += s_entropy1[tid + 4];	  
      if (tid < 2) s_entropy1[tid] += s_entropy1[tid + 2];	  
      if (tid < 1) s_entropy1[tid] += s_entropy1[tid + 1];	 
      if(tid == 0) d_ImageEntropy1[0] = s_entropy1[0];
    }
  // calculate entropy 2 in block 1
  if (blockIdx.x == 1)
    {
      __shared__ double s_entropy2[HISTOGRAM64_BIN_COUNT];
      uint tid = threadIdx.x;
      
      if(d_Histogram2[tid])
	s_entropy2[tid] = - ((double)d_Histogram2[tid] / totalCount) * std::log((double)d_Histogram2[tid] / totalCount) / LOG_2;
      else
	s_entropy2[tid] = 0;
      // before reduce, make sure threads within block finish its own work.
      __syncthreads();
      // reduction 
      if (tid < 32) s_entropy2[tid] += s_entropy2[tid + 32];
      if (tid < 16) s_entropy2[tid] += s_entropy2[tid + 16];
      if (tid < 8) s_entropy2[tid] += s_entropy2[tid + 8];
      if (tid < 4) s_entropy2[tid] += s_entropy2[tid + 4];
      if (tid < 2) s_entropy2[tid] += s_entropy2[tid + 2];
      if (tid < 1) s_entropy2[tid] += s_entropy2[tid + 1];
      if(tid == 0) d_ImageEntropy2[0] = s_entropy2[0];
    }
}


__global__ void joint_entropy_kernel(double *d_PartialJointEntropy, uint *d_JointHistogram, uint totalCount)
{
  __shared__ double s_joint_entropy[HISTOGRAM64_BIN_COUNT];
  uint tid = threadIdx.x;
  uint bid = blockIdx.x;
  
  uint i = bid * blockDim.x + threadIdx.x;
      
  s_joint_entropy[tid] = (d_JointHistogram[i] == 0) ?
    0 :  - ((double)d_JointHistogram[i] / totalCount) * std::log((double)d_JointHistogram[i] / totalCount) / LOG_2;
 
  __syncthreads();
  // reduce
  if (tid < 32) s_joint_entropy[tid] += s_joint_entropy[tid + 32];
  if (tid < 16) s_joint_entropy[tid] += s_joint_entropy[tid + 16];
  if (tid < 8) s_joint_entropy[tid] += s_joint_entropy[tid + 8];
  if (tid < 4) s_joint_entropy[tid] += s_joint_entropy[tid + 4];
  if (tid < 2) s_joint_entropy[tid] += s_joint_entropy[tid + 2];
  if (tid < 1) s_joint_entropy[tid] += s_joint_entropy[tid + 1];
  if(tid == 0) d_PartialJointEntropy[bid] = s_joint_entropy[0];
 
}


// global memory is coalesced 
__global__ void merge_joint_entropy_kernel(double *d_JointEntropy, double *d_PartialJointEntropy)
{
  uint tid = threadIdx.x;
  if (tid < 32) 
    d_PartialJointEntropy[tid] += d_PartialJointEntropy[tid + 32];
  if (tid < 16)
    d_PartialJointEntropy[tid] += d_PartialJointEntropy[tid + 16];
  if (tid < 8)
    d_PartialJointEntropy[tid] += d_PartialJointEntropy[tid + 8];
  if (tid < 4)
    d_PartialJointEntropy[tid] += d_PartialJointEntropy[tid + 4];
  if (tid < 2)
    d_PartialJointEntropy[tid] += d_PartialJointEntropy[tid + 2];
  if (tid < 1)
    d_PartialJointEntropy[tid] += d_PartialJointEntropy[tid + 1];
  if (tid == 0)
    d_JointEntropy[0] = d_PartialJointEntropy[0];
}


extern "C" void getImageEntropyAndJointEntropy(uint *d_Histogram1,
					       uint *d_Histogram2,
					       uint *d_JointHistogram,
					       uint commonPixelCount)
{
  // puts("getImageEntropyAndJointEntropy...");
   
  // puts("entering entropy_kernel...");
  entropy_kernel<<<2, 64>>>(d_ImageEntropy1, d_ImageEntropy2, d_Histogram1, d_Histogram2, commonPixelCount);

  
   
  //  puts("entering joint_entropy_kernel...");
  joint_entropy_kernel<<<64, 64>>>(d_PartialJointEntropy, d_JointHistogram, commonPixelCount);


  // puts("merging joint_entropy kernel...");
  merge_joint_entropy_kernel<<<1 , 64 >>>(d_JointEntropy,  d_PartialJointEntropy);

}



extern "C" bool cudaImageMutualInformation64( double *h_JointEntropy,
					      double *h_Entropy1,
					      double *h_Entropy2,
					      uint *h_JointHistogram,
					      uint *h_Histogram1,
					      uint *h_Histogram2,
					      uchar *h_Data1,
					      uint dataCount1,
					      uchar *h_Data2,
					      uint dataCount2)
{
  cudaEvent_t start_device, stop_device, start_histogram, stop_histogram, start_entropy, stop_entropy;
  
  cudaEventCreate(&start_device);
  cudaEventCreate(&stop_device);
  cudaEventCreate(&start_histogram);
  cudaEventCreate(&stop_histogram);
  cudaEventCreate(&start_entropy);
  cudaEventCreate(&stop_entropy);
  
  cudaEventRecord(start_device,0);
  
  uchar *d_Data1, *d_Data2;
  uint *d_JointHistogram, *d_Histogram1, *d_Histogram2;
  
  uint byteCount1, byteCount2;
  //  uint copyCount1, copyCount2;

  //  uint countRemainder1 = dataCount1 % sizeof(uint);
  //  uint countRemainder2 = dataCount2 % sizeof(uint);
  
  byteCount1 = dataCount1 / sizeof(uint);
  byteCount2 = dataCount2 / sizeof(uint);
  // copyCount1 = dataCount1 - countRemainder1;
  // copyCount2 = dataCount2 - countRemainder2;
  
  //  printf(">>>>\t Allocating GPU Memory\t <<<<\n");
  checkCudaErrors(cudaMalloc((void **)&d_Data1, dataCount1));
  checkCudaErrors(cudaMalloc((void **)&d_Data2, dataCount2));
  
  checkCudaErrors(cudaMalloc((void **)&d_Histogram1,			
			     HISTOGRAM64_BIN_COUNT * sizeof(uint)));
  
  checkCudaErrors(cudaMalloc((void **)&d_Histogram2,
			     HISTOGRAM64_BIN_COUNT * sizeof(uint)));

  checkCudaErrors(cudaMalloc((void **)&d_JointHistogram,
			     HISTOGRAM64_BIN_COUNT * HISTOGRAM64_BIN_COUNT * sizeof(uint)));
  
  
  // printf(">>>>\t Copying Input Data\t <<<<\n");
  checkCudaErrors(cudaMemcpy(d_Data1, h_Data1, dataCount1, cudaMemcpyHostToDevice));
  checkCudaErrors(cudaMemcpy(d_Data2, h_Data2, dataCount2, cudaMemcpyHostToDevice));

  
  // printf(">>>>\t Initializing 64-bin histogram\t <<<<\n");
  initHistogram64();

  cudaEventRecord(start_histogram, 0);
  
  // histogram calculation
  histogram64(d_JointHistogram, d_Histogram1, d_Histogram2, d_Data1, d_Data2, byteCount1, byteCount2);
  
  cudaDeviceSynchronize();
  
  cudaEventRecord(stop_histogram,0);
  cudaEventSynchronize(stop_histogram);
  
  float histogram_time;
  cudaEventElapsedTime(&histogram_time, start_histogram, stop_histogram);
  
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // now we have all 3 histograms, i.e. histogram of image A, histogram of image B, joint histogram of A and B.
  // calculate image entropy of each.
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////

  uint commonPixelCount = (dataCount1 < dataCount2) ? dataCount1 : dataCount2;

  cudaEventRecord(start_entropy, 0);
  // calculate entropy and joint entropy
  getImageEntropyAndJointEntropy( d_Histogram1, d_Histogram2, d_JointHistogram, commonPixelCount);
  
  cudaEventRecord(stop_entropy,0);
  cudaEventSynchronize(stop_entropy);
  
  float entropy_time;
  cudaEventElapsedTime(&entropy_time, start_entropy, stop_entropy);
  
  
  checkCudaErrors(cudaMemcpy(h_Entropy1, d_ImageEntropy1, sizeof(double), cudaMemcpyDeviceToHost));
  checkCudaErrors(cudaMemcpy(h_Entropy2, d_ImageEntropy2, sizeof(double), cudaMemcpyDeviceToHost));
  checkCudaErrors(cudaMemcpy(h_JointEntropy, d_JointEntropy, sizeof(double), cudaMemcpyDeviceToHost));

  //printf(">>>>\t Returning GPU results \t<<<<\n");
  checkCudaErrors(cudaMemcpy(h_Histogram1,
			     d_Histogram1,
			     HISTOGRAM64_BIN_COUNT * sizeof(uint),	
			     cudaMemcpyDeviceToHost));

  checkCudaErrors(cudaMemcpy(h_Histogram2,
			     d_Histogram2,
			     HISTOGRAM64_BIN_COUNT * sizeof(uint),	
			     cudaMemcpyDeviceToHost));

  
  checkCudaErrors(cudaMemcpy(h_JointHistogram,
			     d_JointHistogram,
			     HISTOGRAM64_BIN_COUNT * HISTOGRAM64_BIN_COUNT * sizeof(uint),	
			     cudaMemcpyDeviceToHost));
 
  /*
    printf("countRemainder1 : %d \ncountRemainder2 : %d\n", countRemainder1, countRemainder2);  
    for (uint i = 0; i < countRemainder1; i++)
    h_Histogram1[ (uint) *(h_Data1 + copyCount1 + i) ]++;

    for (uint i = 0; i < countRemainder2; i++)
    h_Histogram2[ (uint) *(h_Data2 + copyCount2 + i) ]++;
    printf(">>>>\t Shutting down 64-bin histogram \t<<<<\n");
  */
  
  closeHistogram64();
  
  checkCudaErrors(cudaFree(d_Data1));
  checkCudaErrors(cudaFree(d_Histogram1));
  checkCudaErrors(cudaFree(d_Data2));
  checkCudaErrors(cudaFree(d_Histogram2));
  checkCudaErrors(cudaFree(d_JointHistogram));

  cudaEventRecord(stop_device,0);
  cudaEventSynchronize(stop_device);
  float device_time;
  cudaEventElapsedTime(&device_time, start_device, stop_device);

  printf("Histogram Calculation Time             =  %f ms\n\n", histogram_time );
  printf("Entropy Calculation Time               =  %f ms\n\n", entropy_time );
  printf("CUDA Device Total Running Time         =  %f ms\n\n", device_time );
  return 0;
}