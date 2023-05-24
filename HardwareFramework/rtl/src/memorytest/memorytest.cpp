#define CL_HPP_CL_1_2_DEFAULT_BUILD
#define CL_HPP_TARGET_OPENCL_VERSION 120
#define CL_HPP_MINIMUM_OPENCL_VERSION 120
#define CL_HPP_ENABLE_PROGRAM_CONSTRUCTION_FROM_ARRAY_COMPATIBILITY 1
#define CL_USE_DEPRECATED_OPENCL_1_2_APIS

//OCL_CHECK doesn't work if call has templatized function call
#define OCL_CHECK(error,call)                                       \
    call;                                                           \
    if (error != CL_SUCCESS) {                                      \
      printf("%s:%d Error calling " #call ", error code is: %d\n",  \
              __FILE__,__LINE__, error);                            \
      exit(EXIT_FAILURE);                                           \
    }

#include <getopt.h>

#include <vector>
#include <unistd.h>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <CL/cl2.hpp>

template <typename T>
struct aligned_allocator
{
  using value_type = T;
  T* allocate(std::size_t num)
  {
    void* ptr = nullptr;
    if (posix_memalign(&ptr,4096,num*sizeof(T)))
      throw std::bad_alloc();
    return reinterpret_cast<T*>(ptr);
  }
  void deallocate(T* p, std::size_t num)
  {
    free(p);
  }
};

std::vector<cl::Device> get_devices(const std::string& vendor_name) 
{
  size_t i;
  cl_int err;
  std::vector<cl::Platform> platforms;
  OCL_CHECK(err, err = cl::Platform::get(&platforms));
  cl::Platform platform;
  for (i  = 0 ; i < platforms.size(); i++){
      platform = platforms[i];
      OCL_CHECK(err, std::string platformName = platform.getInfo<CL_PLATFORM_NAME>(&err));
      if (platformName == vendor_name){
          std::cout << "Found Platform" << std::endl;
          std::cout << "Platform Name: " << platformName.c_str() << std::endl;
          break;
      }
  }
  if (i == platforms.size()) {
      std::cout << "Error: Failed to find Xilinx platform" << std::endl;
      exit(EXIT_FAILURE);
  }

  //Getting ACCELERATOR Devices and selecting 1st such device
  std::vector<cl::Device> devices;
  OCL_CHECK(err, err = platform.getDevices(CL_DEVICE_TYPE_ACCELERATOR, &devices));
  return devices;
}

char* read_binary_file(const std::string &xclbin_file_name, unsigned &nb)
{
  std::cout << "INFO: Reading " << xclbin_file_name << std::endl;

  if(access(xclbin_file_name.c_str(), R_OK) != 0) 
  {
    printf("ERROR: %s xclbin not available please build\n", xclbin_file_name.c_str());
    exit(EXIT_FAILURE);
  }
  //Loading XCL Bin into char buffer
  std::cout << "Loading: '" << xclbin_file_name.c_str() << "'\n";
  std::ifstream bin_file(xclbin_file_name.c_str(), std::ifstream::binary);
  bin_file.seekg (0, bin_file.end);
  nb = bin_file.tellg();
  bin_file.seekg (0, bin_file.beg);
  char *buf = new char [nb];
  bin_file.read(buf, nb);
  return buf;
}

int atoi2(const char* optarg)
{
 int result = atoi(optarg);
 if (strstr(optarg, "k") || strstr(optarg, "K")) result *= 1024;
 if (strstr(optarg, "m") || strstr(optarg, "M")) result *= 1024*1024;
 if (strstr(optarg, "g") || strstr(optarg, "G")) result *= 1024*1024*1024;
 return result;
}

int main(int argc, char** argv)
{
  std::cout << "HOST: begin" << std::endl;

    // if (argc != 2) {
        // std::cout << "Usage: " << argv[0] << " <XCLBIN File>" << std::endl;
        // return EXIT_FAILURE;
    // }

  std::string binaryFile;

  int size = 16384;
  int a = 2;
  int b = 3;
  int disable_cache_flag = 0;
  int pause_flag = 0;
  int randomize_flag = 0;
  int loop_count = 1;
  int opt;
  while ((opt = getopt(argc, argv, "s:a:b:x:dprl:h")) != -1)
  {
    switch(opt) {
      case 's':
        std::cout << "getopt s " << optarg << std::endl;
        size = atoi2(optarg);
        break;
      case 'a':
        std::cout << "getopt a " << optarg << std::endl;
        a = atoi2(optarg);
        break;
      case 'b':
        std::cout << "getopt b " << optarg << std::endl;
        b = atoi2(optarg);
        break;
      case 'x':
        std::cout << "getopt x " << optarg << std::endl;
        binaryFile = optarg;
        break;
      case 'd':
        std::cout << "getopt d" << std::endl;
        disable_cache_flag = 1;
        break;
      case 'p':
        std::cout << "getopt p" << std::endl;
        pause_flag = 1;
        break;
      case 'r':
        std::cout << "getopt r" << std::endl;
        randomize_flag = 1;
        break;
      case 'l':
        std::cout << "getopt l " << optarg << std::endl;
        loop_count = atoi2(optarg);
        break;
      case 'h':
        std::cout << "getopt h" << std::endl;
        return 0;
      default:
        break;
    }
  }

  std::cout << "size = " << size << std::endl;
  std::cout << "a = " << a << std::endl;
  std::cout << "b = " << b << std::endl;
  std::cout << "d = " << disable_cache_flag << std::endl;
  std::cout << "p = " << pause_flag << std::endl;
  std::cout << "r = " << randomize_flag << std::endl;
  std::cout << "l = " << loop_count << std::endl;
  std::cout << "x = " << binaryFile << std::endl;
  
  int int_size = size / sizeof(int);

  // std::string binaryFile = argv[1];
  size_t vector_size_bytes = size; // sizeof(int) * DATA_SIZE;
  cl_int err;
  unsigned fileBufSize;
  // Allocate Memory in Host Memory
  std::vector<unsigned int, aligned_allocator<unsigned int>> host_buffer(int_size); // DATA_SIZE
  int host_buffer_offset = 8;

// OPENCL HOST CODE AREA START

  std::vector<cl::Device> devices = get_devices("Xilinx");
  devices.resize(1);
  cl::Device device = devices[0];

  OCL_CHECK(err, cl::Context context(device, NULL, NULL, NULL, &err));
  OCL_CHECK(err, cl::CommandQueue q(context, device, CL_QUEUE_PROFILING_ENABLE, &err));

  char* fileBuf = read_binary_file(binaryFile, fileBufSize);
  cl::Program::Binaries bins{{fileBuf, fileBufSize}};

  OCL_CHECK(err, cl::Program program(context, devices, bins, NULL, &err));

  OCL_CHECK(err, cl::Kernel krnl_vector_add(program,"hastip", &err));

  OCL_CHECK(err, cl::Buffer fpga_buffer   (context,CL_MEM_USE_HOST_PTR | CL_MEM_READ_WRITE,
            vector_size_bytes, host_buffer.data(), &err));

  unsigned int *emu_buffer = new unsigned int [int_size];
  if (!emu_buffer) 
  {
    printf("emu_buffer malloc failed\n");
    exit(EXIT_FAILURE);
  }

  // main loop
  int total_error_count = 0;
  for (int j=1; j<=loop_count; j++)
  {
    if (randomize_flag)
    {
      int range1 = int_size - host_buffer_offset - 8;
      a = host_buffer_offset + 2 + (rand() % range1);
      int range2 = int_size - 4 - a;
      b = 2 + (rand() % range2);
    }

    // std::cout << "a = " << a << std::endl;
    // std::cout << "b = " << b << std::endl;
    printf("Iteration: %d (a:%d, b:%d)\n", j, a, b);
    
    host_buffer[0] = host_buffer_offset;
    host_buffer[1] = 0;
    host_buffer[2] = -1;
    host_buffer[3] = -1;
    host_buffer[host_buffer_offset + 0] = a; // 1024;
    host_buffer[host_buffer_offset + 1] = b; // 3;
    
    if (disable_cache_flag) host_buffer[2] = 0xABBA0000; // disable cache

    for (int i=0; i<int_size; i++) emu_buffer[i] = host_buffer[i];
    for (int i=0; i<b; i++) emu_buffer[host_buffer_offset + a + i]++;

    if (pause_flag)
    {
      std::cout << "\nPress ENTER to continue after setting up ILA trigger..." << std::endl;
      std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
    }
    
    std::cout << ".. krnl_vector_add.setArg" << std::endl;
    OCL_CHECK(err, err = krnl_vector_add.setArg(0, fpga_buffer));
    std::cout << ".. q.enqueueMigrateMemObjects" << std::endl;
    OCL_CHECK(err, err = q.enqueueMigrateMemObjects({fpga_buffer}, 0/* 0 means from host*/));
    std::cout << ".. q.enqueueTask" << std::endl;
    OCL_CHECK(err, err = q.enqueueTask(krnl_vector_add));
    
    std::cout << ".. q.enqueueMigrateMemObjects" << std::endl;
    OCL_CHECK(err, err = q.enqueueMigrateMemObjects({fpga_buffer}, CL_MIGRATE_MEM_OBJECT_HOST));

    q.finish();

    unsigned long long HardwareExecutionTimeLo = host_buffer[2];
    unsigned long long HardwareExecutionTimeHi = host_buffer[3];
    unsigned long long HardwareExecutionTime = (HardwareExecutionTimeHi << 32) + HardwareExecutionTimeLo;
    printf(".. HardwareExecutionTime = %llu (%0.1f)\n", HardwareExecutionTime, (float)HardwareExecutionTime / (float)b);

    // for (int i = 0 ; i < 15 ; i++)
    // {
      // std::cout << "HOST: buffer[" << i << "] = 0x" << std::hex << std::setw(8) << std::setfill('0') << host_buffer[i] << std::endl;
    // }

    int error_count = 0;
    for (int i = host_buffer_offset; i < int_size; i++)
    {
      if (host_buffer[i] != emu_buffer[i])
      {
        total_error_count++;
        error_count++;
        // std::cout << "HOST: buffer[" << i << "] = 0x" << std::hex << std::setw(8) << std::setfill('0') << host_buffer[i] << std::endl;
        printf("DIFF: i:%04x, fpga:%08x, emu:%08x\n", i, host_buffer[i], emu_buffer[i]);
      }
    }
    printf(".. Error Count = %d\n", error_count);

  }

  delete [] emu_buffer;
  delete[] fileBuf;

  printf("Total Error Count = %d\n", total_error_count);
  std::cout << "HOST: end" << std::endl;

  return EXIT_SUCCESS;
}