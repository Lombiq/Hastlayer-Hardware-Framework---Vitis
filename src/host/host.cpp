/*******************************************************************************
Description:
*******************************************************************************/

#include "host.hpp"

int main(int argc, char** argv)
{
    std::cout << "HOST: begin" << std::endl;
    
    if (argc != 2) {
        std::cout << "Usage: " << argv[0] << " <XCLBIN File>" << std::endl;
	return EXIT_FAILURE;
	}

    std::string binaryFile = argv[1];
    size_t vector_size_bytes = sizeof(int) * DATA_SIZE;
    cl_int err;
    unsigned fileBufSize;
    // Allocate Memory in Host Memory
    std::vector<int,aligned_allocator<int>> host_buffer(DATA_SIZE);

    // Create the test data 
    host_buffer[0] = 8; // offset

    host_buffer[8] = 2; // loopback + memtest
    host_buffer[9] = 3;

    //host_buffer[8] = 3268687283; // prime
    //host_buffer[9] = 3268687283;

    //host_buffer[8] = 1181; // prime
    //host_buffer[9] = 1181;

// OPENCL HOST CODE AREA START
	
// ------------------------------------------------------------------------------------
// Step 1: Get All PLATFORMS, then search for Target_Platform_Vendor (CL_PLATFORM_VENDOR)
//	   Search for Platform: Xilinx 
// Check if the current platform matches Target_Platform_Vendor
// ------------------------------------------------------------------------------------	
    std::vector<cl::Device> devices = get_devices("Xilinx");
    devices.resize(1);
    cl::Device device = devices[0];

// ------------------------------------------------------------------------------------
// Step 1: Create Context
// ------------------------------------------------------------------------------------
    OCL_CHECK(err, cl::Context context(device, NULL, NULL, NULL, &err));
	
// ------------------------------------------------------------------------------------
// Step 1: Create Command Queue
// ------------------------------------------------------------------------------------
    OCL_CHECK(err, cl::CommandQueue q(context, device, CL_QUEUE_PROFILING_ENABLE, &err));

// ------------------------------------------------------------------
// Step 1: Load Binary File from disk
// ------------------------------------------------------------------		
    char* fileBuf = read_binary_file(binaryFile, fileBufSize);
    cl::Program::Binaries bins{{fileBuf, fileBufSize}};
	
// -------------------------------------------------------------
// Step 1: Create the program object from the binary and program the FPGA device with it
// -------------------------------------------------------------	
    OCL_CHECK(err, cl::Program program(context, devices, bins, NULL, &err));

// -------------------------------------------------------------
// Step 1: Create Kernels
// -------------------------------------------------------------
    OCL_CHECK(err, cl::Kernel krnl_vector_add(program,"hastip", &err));

// ================================================================
// Step 2: Setup Buffers and run Kernels
// ================================================================
//   o) Allocate Memory to store the results 
//   o) Create Buffers in Global Memory to store data
// ================================================================

// ------------------------------------------------------------------
// Step 2: Create Buffers in Global Memory to store data
//             o) fpga_buffer - stores host_buffer
// ------------------------------------------------------------------	

// .......................................................
// Allocate Global Memory for host_buffer
// .......................................................	
    OCL_CHECK(err, cl::Buffer fpga_buffer   (context,CL_MEM_USE_HOST_PTR | CL_MEM_READ_WRITE, 
            vector_size_bytes, host_buffer.data(), &err));

// ============================================================================
// Step 2: Set Kernel Arguments and Run the Application
//         o) Set Kernel Arguments
//              ----------------------------------------------------
//              Kernel Argument  Description
//              ----------------------------------------------------
//              in1   (input)     --> Input Vector1
//         o) Copy Input Data from Host to Global Memory on the device
//         o) Submit Kernels for Execution
//         o) Copy Results from Global Memory, device to Host
// ============================================================================	
    std::cout << "HOST: krnl_vector_add.setArg" << std::endl;
    OCL_CHECK(err, err = krnl_vector_add.setArg(0, fpga_buffer));

// ------------------------------------------------------
// Step 2: Copy Input data from Host to Global Memory on the device
// ------------------------------------------------------
    OCL_CHECK(err, err = q.enqueueMigrateMemObjects({fpga_buffer}, 0/* 0 means from host*/));	
	
// ----------------------------------------
// Step 2: Submit Kernels for Execution
// ----------------------------------------
    std::cout << "HOST: q.enqueueTask" << std::endl;
    OCL_CHECK(err, err = q.enqueueTask(krnl_vector_add));
	
// --------------------------------------------------
// Step 2: Copy Results from Device Global Memory to Host
// --------------------------------------------------
    OCL_CHECK(err, err = q.enqueueMigrateMemObjects({fpga_buffer}, CL_MIGRATE_MEM_OBJECT_HOST));

    q.finish();
	
// OPENCL HOST CODE AREA END

    for (int i = 0 ; i < 15 ; i++)
    {
      std::cout << "HOST: buffer[" << i << "] = 0x" << std::hex << std::setw(8) << std::setfill('0') << host_buffer[i] << std::endl;
    }


// ============================================================================
// Step 3: Release Allocated Resources
// ============================================================================
    delete[] fileBuf;

    std::cout << "HOST: end" << std::endl;

    return EXIT_SUCCESS;
}
