#include <iostream>
#include <string>
#include "mutual_information_common.h"
#include "itkImage.h"
#include "itkTimeProbe.h"

int main(int argc, char **argv)
{
  itk::TimeProbe clock;
  if( argc < 5 )
    {
      std::cerr << "Missing command line arguments." << std::endl;
      std::cerr << "Usage : ./ImageMutualInformation \narg[1]Image 1 file name \narg[2]Image 2 file name    \
\narg[3]please enter 0 for ITK, 1 for CUDA  \narg[4]please enter histogram bin number(if choose CUDA, please enter 64 only.)\n(if choose ITK, you can enter any bin number)\n";
      return EXIT_FAILURE;
    }

  const std::string image1Name = argv[1];
  const std::string image2Name = argv[2];
  const uint option = atoi(argv[3]);
  const uint BIN_COUNT = atoi(argv[4]);
  
  if ( option == 0 )
    {
      
      clock.Start();
      std::cout << "Calculating Mattes Mutual Information in ITK" << std::endl;
      
      if (itkMattesMutualInformation(image1Name, image2Name, BIN_COUNT) == EXIT_FAILURE)
	{
	  std::cerr << "ITK Error!" << std::endl;
	  return EXIT_FAILURE;
	}
      clock.Stop();
      std::cout << "\nApplication Running Time: " << clock.GetMean() * 1000 << " ms" << std::endl;
      return EXIT_SUCCESS;
      
    }
  else if ( option == 1 )
    {
      clock.Start();
      std::cout << "Calculating Mattes Mutual Information in CUDA" << std::endl;
      if (cudaMattesMutualInformation(image1Name, image2Name, BIN_COUNT ) == EXIT_FAILURE)
	{
	  std::cerr << "CUDA Error!" << std::endl;
	  return EXIT_FAILURE;
	}
      clock.Stop();
      std::cout << "\nApplication Running Time: " << clock.GetMean() * 1000 << " ms" << std::endl;
      return EXIT_SUCCESS;
    }
  else
    {
      std::cerr << "Wrong option code, please enter 0 for ITK, 1 for CUDA" << std::endl;
      return EXIT_FAILURE;
    }
}
