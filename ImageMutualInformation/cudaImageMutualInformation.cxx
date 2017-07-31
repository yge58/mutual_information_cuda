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

bool cudaImageMutualInformation(const std::string &image_1_name, const std::string &image_2_name, const uint &bin_count)
{
  itk::TimeProbe clock;
  const uint Dimension = 3;
  
  typedef uchar                                                    PixelType;
  typedef itk::Image< PixelType, Dimension >                       ImageType;
  typedef itk::ImageFileReader< ImageType >                        ReaderType;
  typedef itk::Image< PixelType, Dimension >::PixelContainer       ImagePixelContainerType;

  
  /* Allocate Image Reader */
  ReaderType::Pointer reader_1 = ReaderType::New();
  ReaderType::Pointer reader_2 = ReaderType::New();
  
  reader_1->SetFileName( image_1_name );
  reader_2->SetFileName( image_2_name );

  /* Reading Image, catch exception if failed.*/
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

  /* Output Image from Reader*/
  ImageType::Pointer image_1_ptr = reader_1->GetOutput();
  ImageType::Pointer image_2_ptr = reader_2->GetOutput();

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

  for (uint i = 0; i < 3 ; ++i)
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

  double h_Entropy1 = 0.0;
  double h_Entropy2 = 0.0;
  double h_JointEntropy = 0.0;
  uint *h_Histogram1 = NULL;
  uint *h_Histogram2 = NULL;
  uint *h_JointHistogram = NULL;
  if (bin_count == 64)
    {

      h_Histogram1 = (uint *)malloc(HISTOGRAM64_BIN_COUNT * sizeof(uint));
      h_Histogram2 = (uint *)malloc(HISTOGRAM64_BIN_COUNT * sizeof(uint));
      h_JointHistogram = (uint *)malloc(JOINT_HISTOGRAM64_BIN_COUNT * sizeof(uint));
      
     
      if (cudaImageMutualInformation64( &h_JointEntropy, &h_Entropy1, &h_Entropy2,
					h_JointHistogram, h_Histogram1, h_Histogram2,
					image_1_pixel_data_ptr, image_1_pixel_count,
					image_2_pixel_data_ptr, image_2_pixel_count ))
	{
	  std::cerr << "cudaImageMutualInformation64 Error\n";
	  return EXIT_FAILURE;
	}
    }
  else if (bin_count == 256)
    {
      h_Histogram1 = (uint *)malloc(HISTOGRAM256_BIN_COUNT * sizeof(uint));
      h_Histogram2 = (uint *)malloc(HISTOGRAM256_BIN_COUNT * sizeof(uint));
      h_JointHistogram = (uint *)malloc(JOINT_HISTOGRAM256_BIN_COUNT * sizeof(uint));
       
      if (cudaImageMutualInformation256( &h_JointEntropy, &h_Entropy1, &h_Entropy2,
					 h_JointHistogram, h_Histogram1, h_Histogram2,
					 image_1_pixel_data_ptr, image_1_pixel_count,
					 image_2_pixel_data_ptr, image_2_pixel_count ))
	{
	  std::cerr << "cudaImageMutualInformation256 Error\n";
	  return EXIT_FAILURE;
	}
    }
  else
    {
      std::cout << "Sorry, currently I have not implemented this program for your bin number " << bin_count << std::endl;
      std::cout << "You may choose ITK option for your bin number.\n";
      return EXIT_FAILURE;
    }
  clock.Stop();
  std::cout << "Total Time (data transfer time + CUDA device running time) = " << clock.GetMean() * 1000 << " ms" << std::endl;
  std::cout << "=====================  Leaving CUDA kernel  ===================\n\n\n";
  



  /*********************************CUDA ENDING POINT ***************************/
  
  std::cout << "Joint Entropy  \t\t\t= " << h_JointEntropy << " bits" << std::endl;
  std::cout << "Image1 Entropy\t\t\t= " << h_Entropy1 << " bits" << std::endl;
  std::cout << "Image2 Entropy\t\t\t= " << h_Entropy2 << " bits" << std::endl;
  
  double mutualInformation = h_Entropy1 + h_Entropy2 - h_JointEntropy;
  std::cout << "Mutual Information   \t\t= " << mutualInformation << " bits" <<std::endl;
  
  double normalizedMutualInformation1 = 2.0 * mutualInformation / (h_Entropy1 + h_Entropy2); 
  std::cout << "Normalized Mutual Information 1 = " << normalizedMutualInformation1 << std::endl;
  
  double normalizedMutualInformation2 = ( h_Entropy1 + h_Entropy2 ) / h_JointEntropy; 
  std::cout << "Normalized Mutual Information 2 = " << normalizedMutualInformation2 << std::endl;


  
  /*  // DEBUGGING  64-bin 
  std::cout << "\n\n>>>>>>>>>>>  Image One 64-Bin Histogram  <<<<<<<<<<<\n";

  int sum1 = 0;
  for (uint i = 0; i < HISTOGRAM64_BIN_COUNT; i++)
    {  if (h_Histogram1[i])
	{
	  printf("BIN[%d] =  %d\n", i, h_Histogram1[i]);
	  sum1 += h_Histogram1[i]; // debugging.
	}
    }
  std::cout << image_1_name << " -- total count: " << sum1 << std::endl;


  std::cout << "\n\n>>>>>>>>>>>  Image Two 64-Bin Histogram  <<<<<<<<<<<\n";
  
  
  int sum2 = 0;
  for (uint i = 0; i < HISTOGRAM64_BIN_COUNT; i++)
    {  if (h_Histogram2[i])
	{
	  printf("BIN[%d] =  %d\n", i, h_Histogram2[i]);
	  sum2 += h_Histogram2[i]; // debugging.
	}
    }
  std::cout << image_2_name << " -- total count: " << sum2 << std::endl;
  

  std::cout << "\n\n>>>>>>>>>>>  64 x 64 Joint Histogram  <<<<<<<<<<<\n";
  
  
  int sum3 = 0;
  for (uint i = 0; i < HISTOGRAM64_BIN_COUNT; i++)
    {
      for (uint j = 0; j < HISTOGRAM64_BIN_COUNT; j++)
	{
	  if (h_JointHistogram[i*HISTOGRAM64_BIN_COUNT + j])
	    {
	      printf("Joint[%d][%d] =  %d\n", i, j, h_JointHistogram[i*HISTOGRAM64_BIN_COUNT + j]);
	      sum3 += h_JointHistogram[i*HISTOGRAM64_BIN_COUNT + j]; // debugging.
	    }
	}
    }
  std::cout << "Joint Histogram -- total count: " << sum2 << std::endl;
  
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
