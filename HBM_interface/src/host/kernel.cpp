#include "cmdlineparser.h"
#include <iostream>
#include <cstring>
#include <memory>
#include <string>
#include <stdexcept>
#include <cstdarg>
#include <assert.h>
#include <stdio.h>  
#include <stdlib.h> 
#include <inttypes.h>


// XRT includes
#include "experimental/xrt_bo.h"
#include "experimental/xrt_device.h"
#include "experimental/xrt_kernel.h"

#include "sizes.h"
#include "time_utils.h"

#define CMD_EXIT     0xFFFFFFFF
#define CMD_NONE     0x00000000
#define CMD_RX       0x00000001
#define CMD_TX       0x00000002

#define AP_CONTROL   0x010
#define AP_STATUS    0x014
#define AP_DEBUG     0x018
#define AP_TIMING    0x01C
#define HBM_PARAMS_0 0x020
#define HBM_PARAMS_1 0x024

#define INPUT_RB_FILE "../../../scripts/kernel/kernel_4096_I_64_readback.txt"
#define OUTPUT_FILE   "../../../scripts/kernel/kernel_4096_O_64_computed.txt"

#define PC_COUNT      16     // 16 HBM Pseudo Channels (PC)
#define PC_SIZE       (2*KB) //  2 KiB

#define HBM_BUFFER_LENGTH_BYTE (PC_SIZE)
#define HBM_BUFFER_LENGTH_WORD (PC_SIZE/sizeof(uint64_t))

int test_kernel(xrt::kernel kernel, xrt::bo *hbm_i, xrt::bo *hbm_o);


void printArray(const char* title, auto* array, uint32_t len) {
  printf("%s ", title);
  for (uint32_t i=0; i<len; i++)
    printf("0x%08X ", array[i]);
  printf("\n");
}

int writeMemFile(const char* filename, uint64_t **memBuffer) {
  FILE * fp;

  fp = fopen(filename, "w");
  if (fp == NULL) exit(EXIT_FAILURE);

  for (auto pc=0; pc<PC_COUNT; pc++)
    for (auto i=0; i<HBM_BUFFER_LENGTH_WORD; i++)
      fprintf(fp, "%016" PRIx64 "\n", memBuffer[pc][i]);

  fclose(fp);
  return 1;
}

int main(int argc, char *argv[]) {

  // Command Line Arguments
  sda::utils::CmdLineParser parser;
  parser.addSwitch("--xclbin"    , "-x", "xcl bin file", "" );
  parser.addSwitch("--device_id" , "-d", "device index", "0");
  parser.parse(argc, argv);

  /// Read settings
  std::string package = parser.value("xclbin");
  int device_index = stoi(parser.value("device_id"));

  if (argc < 3) {
    parser.printHelp();
    return EXIT_FAILURE;
  }

  std::cout << "Open the device " << device_index << std::endl;
  auto device = xrt::device(device_index);

  char buff[100];
  snprintf(buff, sizeof(buff), "%s.xclbin", package.c_str());
  std::string binaryFile = buff;
  std::cout << "Load the xclbin " << binaryFile << std::endl;
  auto uuid = device.load_xclbin(binaryFile);

  // create kernel object
  std::cout << "[INFO] Creating kernel object" << std::endl;
  xrt::kernel kernel =
    xrt::kernel(
      device,
      uuid,
      "kernel",
      xrt::kernel::cu_access_mode::exclusive);

  //////////////////////////////////////////////////////////////////////////////
  // Prepare Memory Buffers

  std::cout << "[INFO] Prepare Input Data Buffer in Host Memory" << std::endl;
  uint64_t* buffer_i[PC_COUNT];
  for (auto pc=0; pc<PC_COUNT; pc++) {
    posix_memalign((void**)&buffer_i[pc], 4096, HBM_BUFFER_LENGTH_BYTE);
    assert(buffer_i[pc] != NULL);
  }

  std::cout << "[INFO] Initialise BO Buffers with Data" << std::endl;
  for (auto pc=0; pc<PC_COUNT; pc++)
    for (auto i=0; i<HBM_BUFFER_LENGTH_WORD; i++) 
      buffer_i[pc][i] = i;

  std::cout << "[INFO] Prepare BO for Host->Device" << std::endl;
  xrt::bo hbm_i[PC_COUNT];
  
  for (auto i=0; i<PC_COUNT; i++) {
    int index = i;
    // int index = PC_COUNT-i-1;
    // Allocate
    hbm_i[index] =
      xrt::bo(
        device,
        HBM_BUFFER_LENGTH_BYTE,
        kernel.group_id(index+6));
    // Initialise
    hbm_i[index].write(buffer_i[i]);
    // Transfer host to kernel
    hbm_i[index].sync(XCL_BO_SYNC_BO_TO_DEVICE);
    std::cout << "[INFO] mem[" << index << "] is ready" << std::endl;
  }

  std::cout << "Reading back the inputs" << std::endl;
  for (auto i=0; i<PC_COUNT; i++) {
    hbm_i[i].sync(XCL_BO_SYNC_BO_FROM_DEVICE);
    hbm_i[i].read(buffer_i[i]);
  }
  writeMemFile(INPUT_RB_FILE, buffer_i);
  
  std::cout << "[INFO] Prepare BO for Device->Host" << std::endl;
  xrt::bo hbm_o[PC_COUNT];
  for (auto i=0; i<PC_COUNT; i++) {
    int index = i; // Straightforwards
    // Allocate
    hbm_o[index] =
      xrt::bo(
        device,
        HBM_BUFFER_LENGTH_BYTE,
        kernel.group_id(index+6+16));
    std::cout << "[INFO] mem[" << index << "] is ready" << std::endl;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Start Test

  test_kernel(kernel, hbm_i, hbm_o);

  return 0;
}

////////////////////////////////////////////////////////////////////////////////

int test_kernel(xrt::kernel kernel, xrt::bo *hbm_i, xrt::bo *hbm_o) {

  uint32_t ap_control   = 0;
  uint32_t ap_status    = 0;
  uint32_t ap_debug     = 0;
  uint32_t ap_timing    = 0;
  uint32_t hbm_params_0 = 0;
  uint32_t hbm_params_1 = 0;
    
  //////////////////////////////////////////////////////////////////////////////
  // Start running the kernel

  std::cout << "Ready?" << std::endl;
  getchar();

  std::cout << "Run the Kernel" << std::endl;

  auto run =
    kernel(
      ap_control,   //
      ap_status,    //
      ap_debug,     //
      ap_timing,    //
      hbm_params_0, //
      hbm_params_1, //
      hbm_i[ 0],    // Pointer to hbm memory [ 0]
      hbm_i[ 1],    // Pointer to hbm memory [ 1]
      hbm_i[ 2],    // Pointer to hbm memory [ 2]
      hbm_i[ 3],    // Pointer to hbm memory [ 3]
      hbm_i[ 4],    // Pointer to hbm memory [ 4]
      hbm_i[ 5],    // Pointer to hbm memory [ 5]
      hbm_i[ 6],    // Pointer to hbm memory [ 6]
      hbm_i[ 7],    // Pointer to hbm memory [ 7]
      hbm_i[ 8],    // Pointer to hbm memory [ 8]
      hbm_i[ 9],    // Pointer to hbm memory [ 9]
      hbm_i[10],    // Pointer to hbm memory [10]
      hbm_i[11],    // Pointer to hbm memory [11]
      hbm_i[12],    // Pointer to hbm memory [12]
      hbm_i[13],    // Pointer to hbm memory [13]
      hbm_i[14],    // Pointer to hbm memory [14]
      hbm_i[15],    // Pointer to hbm memory [15]
      hbm_o[ 0],    // Pointer to hbm memory [16]
      hbm_o[ 1],    // Pointer to hbm memory [17]
      hbm_o[ 2],    // Pointer to hbm memory [18]
      hbm_o[ 3],    // Pointer to hbm memory [19]
      hbm_o[ 4],    // Pointer to hbm memory [20]
      hbm_o[ 5],    // Pointer to hbm memory [21]
      hbm_o[ 6],    // Pointer to hbm memory [22]
      hbm_o[ 7],    // Pointer to hbm memory [23]
      hbm_o[ 8],    // Pointer to hbm memory [24]
      hbm_o[ 9],    // Pointer to hbm memory [25]
      hbm_o[10],    // Pointer to hbm memory [26]
      hbm_o[11],    // Pointer to hbm memory [27]
      hbm_o[12],    // Pointer to hbm memory [28]
      hbm_o[13],    // Pointer to hbm memory [29]
      hbm_o[14],    // Pointer to hbm memory [30]
      hbm_o[15]     // Pointer to hbm memory [31]
    );
  std::cout << "Running the Kernel" << std::endl;
  
  run.wait();
  std::cout << "Kernel is done" << std::endl;

  //////////////////////////////////////////////////////////////////////////////
  // Get the outputs

  std::cout << "Reading back the results" << std::endl;
  uint64_t* buffer_o[PC_COUNT];
  for (auto i=0; i<PC_COUNT; i++) {
    posix_memalign((void**)&buffer_o[i], 4096, HBM_BUFFER_LENGTH_BYTE);
    assert(buffer_o[i] != NULL);
    hbm_o[i].sync(XCL_BO_SYNC_BO_FROM_DEVICE);
    hbm_o[i].read(buffer_o[i]);
  }
  writeMemFile(OUTPUT_FILE, buffer_o);

  return 1;
}
