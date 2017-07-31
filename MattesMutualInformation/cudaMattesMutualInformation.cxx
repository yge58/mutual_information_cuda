#include <iostream>
#include <stdlib.h>
#include <string>
#include "mutual_information_common.h"

// CUDA
#include <cuda_runtime.h>
#include <helper_cuda.h>

// ITK
#include "itkImage.h"
#include "itkImportImageContainer.h"
#include "itkImageFileReader.h"
#include "itkTimeProbe.h"

bool cudaMattesMutualInformation(const std::string &image_1_name, const std::string &image_2_name, const uint &bin_count)
{
  itk::TimeProbe clock;
  const uint Dimension = 3;
  
  typedef uchar                                                    PixelType;
  typedef itk::Image< PixelType, Dimension >                       ImageType;
  typedef itk::ImageFileReader< ImageType >                        ReaderType;
  typedef itk::Image< PixelType, Dimension >::PixelContainer       ImagePixelContainerType;

  
  // Allocate Image Reader 
  ReaderType::Pointer reader_1 = ReaderType::New();
  ReaderType::Pointer reader_2 = ReaderType::New();
  
  reader_1->SetFileName( image_1_name );
  reader_2->SetFileName( image_2_name );

  // Reading Image, catch exception if failed
  try
    {
      reader_1->Update();
      reader_2->Update();
    }
  catch( itk::ExceptionObject & err )
    {
      std::cerr << "ExceptionObject caught" << std::endl;
      std::cerr << err << std::endl;
      return EXIT_FAILURE;
    }

  //Output Image from Reader
  ImageType::Pointer image_1_ptr = reader_1->GetOutput();
  ImageType::Pointer image_2_ptr = reader_2->GetOutput();

  /* DEBUGGING code

  itk::TimeProbe clock;
  const     unsigned int   Dimension = 1;
  typedef   unsigned char  PixelType;
  typedef itk::Image< PixelType, Dimension >   ImageType;
  ImageType::Pointer image_1_ptr = ImageType::New();
  typedef itk::Image< PixelType, Dimension >::PixelContainer       ImagePixelContainerType;

  typedef ImageType::IndexType pixelIndex;

  pixelIndex idx0 = {0};
  pixelIndex idx1 = {1};
  pixelIndex idx2 = {2};
  pixelIndex idx3 = {3};
  pixelIndex idx4 = {4};
  pixelIndex idx5 = {5};
  pixelIndex idx6 = {6};
  pixelIndex idx7 = {7};
  pixelIndex idx8 = {8};
  pixelIndex idx9 = {9};
  pixelIndex idx10 = {10};
  
  const unsigned int imageSize = 10;

  ImageType::SizeType size;
  size[0] = imageSize;

  ImageType::RegionType region;
  region.SetSize( size );
  region.SetIndex( idx0 );


  ////////////////////////////////// IMAGE ONE /////////////////////////////////
  // Allocate first Image
  image_1_ptr->SetRegions( region );
  image_1_ptr->Allocate( true ); // initialize buffer to zero
  
  // Debugging test 1, image 1, size 10
  image_1_ptr->SetPixel(idx0, 9);
  image_1_ptr->SetPixel(idx1, 8);
  image_1_ptr->SetPixel(idx2, 7);
  image_1_ptr->SetPixel(idx3, 6);
  image_1_ptr->SetPixel(idx4, 5);
  image_1_ptr->SetPixel(idx5, 4);
  image_1_ptr->SetPixel(idx6, 3);
  image_1_ptr->SetPixel(idx7, 2);
  image_1_ptr->SetPixel(idx8, 1);
  image_1_ptr->SetPixel(idx9, 0);
  
  ///////////////////////////   IMAGE TWO   ////////////////////////////////////
  ImageType::Pointer image_2_ptr = ImageType::New();

  image_2_ptr->SetRegions( region );
  image_2_ptr->Allocate( true );


  // Debugging test 1, image 2
  image_2_ptr->SetPixel(idx0, 0);
  image_2_ptr->SetPixel(idx1, 1);
  image_2_ptr->SetPixel(idx2, 2);
  image_2_ptr->SetPixel(idx3, 3);
  image_2_ptr->SetPixel(idx4, 4);
 
  image_2_ptr->SetPixel(idx5, 5);
  image_2_ptr->SetPixel(idx6, 6);
  image_2_ptr->SetPixel(idx7, 7);
  image_2_ptr->SetPixel(idx8, 8);
  image_2_ptr->SetPixel(idx9, 9);

  /*   debugging   */


  /* Store image pixel value (grayscale 8-bit)*/
  ImagePixelContainerType::Pointer image_1_pixel_ptr = image_1_ptr->GetPixelContainer();
  ImagePixelContainerType::Pointer image_2_pixel_ptr = image_2_ptr->GetPixelContainer();

  PixelType *image_1_pixel_data_ptr = image_1_pixel_ptr->GetImportPointer();  
  PixelType *image_2_pixel_data_ptr = image_2_pixel_ptr->GetImportPointer();
  
  /* Get Image Basic Info */
  ImageType::RegionType region_1 = image_1_ptr->GetLargestPossibleRegion();
  ImageType::RegionType region_2 = image_2_ptr->GetLargestPossibleRegion();
  
  ImageType::SizeType image_1_size = region_1.GetSize();
  ImageType::SizeType image_2_size = region_2.GetSize();

  uint image_1_pixel_count = 1; 
  uint image_2_pixel_count = 1; 

  for (uint i = 0; i < Dimension; ++i)
    {
      if (image_1_size[i] && image_1_size[i])
	{
	  image_1_pixel_count *= image_1_size[i];
	  image_2_pixel_count *= image_2_size[i];
	}
    }

  std::cout << "\n>>>>>>>>>>>  Image One(Fixed Image) Basic Info  <<<<<<<<<<<"
	    << "\nName: " << image_1_name << "\nsize: " << image_1_size
	    << "\nPixel count: " << image_1_pixel_count << std::endl;
  
  std::cout << "\n>>>>>>>>>>>  Image Two(Moving Image) Basic Info  <<<<<<<<<<<"
	    << "\nName: " << image_2_name << "\nsize: " << image_2_size
	    << "\nPixel count: " << image_2_pixel_count << std::endl;
  
  /**********************************CUDA STARTING POINT *************************/
  std::cout << "\n=====================  Calling CUDA kernel  ===================\n";
  clock.Start();


  uint *h_Histogram1 = NULL;
  uint *h_Histogram2 = NULL; 
  uint *h_JointHistogram = NULL; 
  double h_Entropy1 = 0;
  double h_Entropy2 = 0;
  double h_JointEntropy = 0;

  // Bin Count is selected as 64 because of warp size, memory coalescing, avoiding bank conflict and other consideration.
  // In practice, ITK suggests 50 as its bin count for calculating mattes mutual information, and it is a tunable parameter.
  // According to ITK software guide, 50 is good enough. More bin count would be a waste.
  // Therefore, I did not implement other bin count for this application beside 64 bin count.
  // 
  //if (bin_count == 64)
  //  {
  float h_MattesMutualInfo64 = 0;
  uint *h_mattesHistogram1 = NULL;
  float *h_mattesHistogram2 = NULL;
  float *h_mattesJointHistogram64 = NULL;
  h_mattesHistogram1 = (uint *)malloc(HISTOGRAM64_BIN_COUNT * sizeof(uint));
  h_mattesHistogram2 = (float *)malloc(HISTOGRAM64_BIN_COUNT * sizeof(float));  
  h_mattesJointHistogram64 = (float *)malloc(JOINT_HISTOGRAM64_BIN_COUNT * sizeof(float));
      
  std::cout<< "\n===========  Calculating Mattes Mutual Information  =========== \n\n";
      
  if (cudaMattesMutualInformation64( &h_MattesMutualInfo64,
				     h_mattesJointHistogram64,
				     h_mattesHistogram1,
				     h_mattesHistogram2,
				     image_1_pixel_data_ptr,
				     image_1_pixel_count,
				     image_2_pixel_data_ptr,
				     image_2_pixel_count ))
    {
      std::cerr << "cudaImageMutualInformation64 Error\n";
      return EXIT_FAILURE;
    }
  printf("\nMattes Mutual Information\t\t = %f bits\n\n", h_MattesMutualInfo64);
      /*
}
  else
    {
      std::cout << "Sorry, currently I have not implemented this program for your bin number " << bin_count << std::endl;
      std::cout << "You may choose ITK option for your bin number.\n";
      return EXIT_FAILURE;
    }
      */
  std::cout << "=====================  Leaving CUDA kernel  ===================\n\n";
  
  /*********************************CUDA ENDING POINT ***************************/

  clock.Stop();
  //std::cout << "\n\nCUDA Mattes Mutual Information total Time: " << clock.GetMean() * 1000 << " ms\n\n" << std::endl;

  /*
 
  std::cout << "\n\n>>>>>>>>>>>  Image One 64-Bin Histogram  <<<<<<<<<<<\n";

  int sum1 = 0;
  for (uint i = 0; i < HISTOGRAM64_BIN_COUNT; i++)
    {  if (h_Histogram1[i])
	{
	  // printf("BIN[%d] =  %d\n", i, h_Histogram1[i]);
	  sum1 += h_Histogram1[i]; // debugging.
	}
    }
  std::cout << image_1_name << " -- total count: " << sum1 << std::endl;


  std::cout << "\n\n>>>>>>>>>>>  Image Two 64-Bin Histogram  <<<<<<<<<<<\n";
  float sum2 = 0;
  for (uint i = 0; i < HISTOGRAM64_BIN_COUNT; i++)
    {  if (h_Histogram2_64[i])
	{
	  //printf("BIN[%d] =  %f\n", i, h_Histogram2_64[i]);
	  sum2 += h_Histogram2_64[i]; // debugging.
	}
    }
  std::cout << image_2_name << " -- total count: " << sum2 << std::endl;
  
  
  std::cout << "\n\n>>>>>>>>>>>  64 x 64 Joint Histogram  <<<<<<<<<<<\n";
  float sum3 = 0;
  for (uint i = 0; i < HISTOGRAM64_BIN_COUNT; i++)
    {
      for (uint j = 0; j < HISTOGRAM64_BIN_COUNT; j++)
	{
	  if (h_JointHistogram64[i*HISTOGRAM64_BIN_COUNT + j] != 0)
	    {
	      //printf("Joint[%d][%d] =  %f\n", i, j, h_JointHistogram64[i*HISTOGRAM64_BIN_COUNT + j]);
	      sum3 += h_JointHistogram64[i*HISTOGRAM64_BIN_COUNT + j]; // debugging.
	    }
	}
    }
  std::cout << "Joint Histogram 64 -- total count: " << sum3 << std::endl;

  //std::cout << "h_MattesMutualInfo = " << h_MattesMutualInfo << std::endl;
  
  /**************DEBUGGING**************/

  /*
  // DEBUGGING 256-bin 
  std::cout << "\n\n>>>>>>>>>>>  Image One 256-Bin Histogram  <<<<<<<<<<<\n";

  int sum1 = 0;
  for (uint i = 0; i < HISTOGRAM256_BIN_COUNT; i++)
    {  if (h_Histogram1[i])
	{
	  printf("BIN[%d] =  %d\n", i, h_Histogram1[i]);
	  sum1 += h_Histogram1[i]; // debugging.
	}
    }
  std::cout << image_1_name << " -- total count: " << sum1 << std::endl;

  std::cout << "\n\n>>>>>>>>>>>  Image Two 256-Bin Histogram  <<<<<<<<<<<\n";
  int sum2 = 0;
  for (uint i = 0; i < HISTOGRAM256_BIN_COUNT; i++)
    {  if (h_Histogram2[i])
	{
	  printf("BIN[%d] =  %d\n", i, h_Histogram2[i]);
	  sum2 += h_Histogram2[i]; // debugging.
	}
    }
  std::cout << image_2_name << " -- total count: " << sum2 << std::endl;
  
  std::cout << "\n\n>>>>>>>>>>>  256 x 256 Joint Histogram  <<<<<<<<<<<\n";
  int sum3 = 0;
  for (uint i = 0; i < HISTOGRAM256_BIN_COUNT; i++)
    {
      for (uint j = 0; j < HISTOGRAM256_BIN_COUNT; j++)
	{
	  if (h_JointHistogram[ i * HISTOGRAM256_BIN_COUNT + j ])
	    {
	      printf("Joint[%d][%d] =  %d\n", i, j, h_JointHistogram[ i*HISTOGRAM256_BIN_COUNT + j ]);
	      sum3 += h_JointHistogram[ i * HISTOGRAM256_BIN_COUNT + j ]; // debugging.
	    }
	}
    }
  std::cout << "Joint Histogram -- total count: " << sum2 << std::endl;
  /**************DEBUGGING**************/
  
  free(h_Histogram1);
  free(h_Histogram2);
  free(h_JointHistogram);
  
  return EXIT_SUCCESS;
}
