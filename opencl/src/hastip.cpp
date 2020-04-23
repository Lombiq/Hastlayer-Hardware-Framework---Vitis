/*******************************************************************************
Description: Hastlayer dummy kernel
*******************************************************************************/

#include "stdio.h"

extern "C" {
  
void hastip(unsigned int *buffer)
{
  printf("KERNEL: begin\n");
  
  // configure the input output buffer
  #pragma HLS INTERFACE m_axi port=buffer offset=slave bundle=gmem
  #pragma HLS INTERFACE s_axilite port=buffer bundle=control
  #pragma HLS INTERFACE s_axilite port=return bundle=control

  // read the input parameters
  unsigned int bufferOffset = buffer[0];
  printf("KERNEL: bufferOffset = 0x%08x\n", bufferOffset);
  
  unsigned int memberId = buffer[1];
  printf("KERNEL: memberId = 0x%08x\n", memberId);

  // mimic simple Hast_IP behavior: cell[0] = cell[0] + cell[1]
  unsigned int cell0 = buffer[bufferOffset + 0];
  unsigned int cell1 = buffer[bufferOffset + 1];
  printf("KERNEL: input cell[0] = 0x%08x\n", cell0);
  printf("KERNEL: input cell[1] = 0x%08x\n", cell1);
  cell0 += cell1;
  buffer[bufferOffset + 0] = cell0;
  printf("KERNEL: output cell[0] = 0x%08x\n", cell0);

  // write the output parameters
  unsigned long hardwareExecutionTime = 0x0000765400003210;
  unsigned int hardwareExecutionTimeLo = (unsigned int)(hardwareExecutionTime >>  0);
  unsigned int hardwareExecutionTimeHi = (unsigned int)(hardwareExecutionTime >> 32);
  buffer[2] = hardwareExecutionTimeLo;
  buffer[3] = hardwareExecutionTimeHi;
  printf("KERNEL: hardwareExecutionTimeLo = 0x%08x\n", hardwareExecutionTimeLo);
  printf("KERNEL: hardwareExecutionTimeHi = 0x%08x\n", hardwareExecutionTimeHi);
  
  printf("KERNEL: end\n");
}

}
