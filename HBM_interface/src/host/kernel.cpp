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

#define POLY_N        (4096)
#define PSI_N         (12288)
#define L             (2)

#define PCI_COUNT          (24)
#define P0_OFFSET          (0)
#define P0_COUNT           (8)
#define P1_OFFSET          (8)
#define P1_COUNT           (8)
#define P2_OFFSET          (16)
#define P2_COUNT           (8)
#define PCO_COUNT          (8)

#define PC_DATA_WIDTH      (32) // interleaving 32-bytes per PC

#define PC_POLY_COEFF_NUM  (POLY_N / PCO_COUNT)
#define PC_POLY_BYTE_SIZE  (PC_POLY_COEFF_NUM*sizeof(uint64_t))
#define PC_DATA_U64_SIZE   (4) // num words at each data
#define PC_POLY_DATA_NUM   (PC_POLY_COEFF_NUM / PC_DATA_U64_SIZE) // coeffs at each PC

#define PC_PSI_COEFF_NUM   (PSI_N / PCO_COUNT)
#define PC_PSI_BYTE_SIZE   (PC_PSI_COEFF_NUM*sizeof(uint64_t))
#define PC_DATA_U64_SIZE   (4) // num words at each data
#define PC_PSI_DATA_NUM    (PC_PSI_COEFF_NUM / PC_DATA_U64_SIZE) // coeffs at each PC


int test_kernel(xrt::kernel kernel, xrt::bo *hbm_i, xrt::bo *hbm_o);


void printArray(const char* title, auto* array, uint32_t len) {
  printf("%s ", title);
  for (uint32_t i=0; i<len; i++)
    printf("0x%08X ", array[i]);
  printf("\n");
}


unsigned int readFromPC(uint64_t *out, xrt::bo *hbm, unsigned int n, unsigned int pc_num, unsigned int width, unsigned int hbm_offset=0) {

  unsigned int bsize          = n * sizeof(uint64_t);
  unsigned int pc_bsize       = bsize / pc_num;
  unsigned int pc_dsize       = pc_bsize / width;
  unsigned int pc_offset      = width*pc_num;
  unsigned int pc_woffset     = pc_offset >> 3;
  unsigned int word_per_width = width / sizeof(uint64_t);

  for (unsigned int pc = 0; pc < pc_num; pc++) {
    hbm[pc].sync(XCL_BO_SYNC_BO_FROM_DEVICE, pc_bsize, hbm_offset);
    for (unsigned int i = 0; i < pc_dsize; i++) {
      hbm[pc].read(&(out[(pc_woffset*i) + (word_per_width*pc)]), width, width*i + hbm_offset);
    }
  }
  return pc_bsize;
}


unsigned int readManyFromPC(uint64_t *out, unsigned int l, xrt::bo *hbm, unsigned int n, unsigned int pc_num, unsigned int width, unsigned int hbm_offset=0) {
  unsigned int bsize          = n * sizeof(uint64_t);
  unsigned int pc_bsize       = bsize / pc_num;

  for (unsigned int i = 0; i < l; i++) {
    readFromPC(out + (i*n), hbm, n, pc_num, width, hbm_offset + (i * pc_bsize));
  }
  return l * pc_bsize;
}


unsigned int writeToPC(const uint64_t *in, xrt::bo *hbm, unsigned int n, unsigned int pc_num, unsigned int width, unsigned int hbm_offset=0) {
  unsigned int bsize          = n * sizeof(uint64_t);
  unsigned int pc_bsize       = bsize / pc_num;
  unsigned int pc_dsize       = pc_bsize / width;
  unsigned int pc_offset      = width * pc_num;
  unsigned int pc_woffset     = pc_offset >> 3;
  unsigned int word_per_width = width / sizeof(uint64_t);

  std::cout << "bsize" << bsize << std::endl;

  for (unsigned int pc = 0; pc < pc_num; pc++) {
    for (unsigned int i = 0; i < pc_dsize; i++) {
      hbm[pc].write(&(in[(pc_woffset * i) + (word_per_width * pc)]), width, width * i + hbm_offset);
    }
    hbm[pc].sync(XCL_BO_SYNC_BO_TO_DEVICE, pc_bsize, hbm_offset);
  }
  return pc_bsize;
}


unsigned int writeManyToPC(const uint64_t *in, unsigned int l, xrt::bo *hbm, unsigned int n, unsigned int pc_num, unsigned int width, unsigned int hbm_offset=0) {
  unsigned int bsize          = n * sizeof(uint64_t);
  unsigned int pc_bsize       = bsize / pc_num;

  for (unsigned int i = 0; i < l; i++) {
    writeToPC(in + (i*n), hbm, n, pc_num, width, hbm_offset + (i * pc_bsize));
  }
  return l * pc_bsize;
}



int writeMemFileOut(const char* filename, uint64_t **memBuffer) {
  FILE * fp;

  fp = fopen(filename, "w");
  if (fp == NULL) exit(EXIT_FAILURE);

  for (auto j=0; j<PC_POLY_DATA_NUM; j++)
    for (auto pc=0; pc<PCO_COUNT; pc++)
      for (auto i=0; i<PC_DATA_U64_SIZE; i++)
        fprintf(fp, "%016" PRIx64 "\n", memBuffer[pc][j*PC_DATA_U64_SIZE + i]);

  fclose(fp);
  return 1;
}


int writeMemFileFlat(const char* filename, const uint64_t *memBuffer, int size) {
  FILE * fp;

  fp = fopen(filename, "w");
  if (fp == NULL) exit(EXIT_FAILURE);

  for (auto i=0; i<size; i++)
    fprintf(fp, "%016" PRIx64 "\n", memBuffer[i]);

  fclose(fp);
  return 1;
}


int writeManyMemFileFlat(const std::string& prefix, const uint64_t* memBuffer, int l, int size) {
  for (int i = 0; i < l; i++) {
    std::string filename = prefix + std::to_string(i) + ".txt";
    const uint64_t* chunk_ptr = memBuffer + (i * size);
    int status = writeMemFileFlat(filename.c_str(), chunk_ptr, size);
    if (status != 1) {
      fprintf(stderr, "Error writing to file: %s\n", filename.c_str());
      return -1;
    }
  }
  return 1;
}


int readMemFileFlat(const char* filename, uint64_t* memBuffer, int size) {
  FILE* fp = fopen(filename, "r");
  if (fp == NULL) exit(EXIT_FAILURE);

  for (int i = 0; i < size; i++) {
    if (fscanf(fp, "%" SCNx64, &memBuffer[i]) != 1) {
      fclose(fp);
      return -1;  // Error or unexpected end of file
    }
  }

  fclose(fp);
  return 1;
}


int readManyMemFileFlat(const std::string& prefix, uint64_t* memBuffer, int l, int size) {
  for (int i = 0; i < l; i++) {
    std::string filename = prefix + std::to_string(i) + ".txt";
    uint64_t* target = memBuffer + (i * size);
    int status = readMemFileFlat(filename.c_str(), target, size);
    if (status != 1) {
      fprintf(stderr, "Error reading file: %s\n", filename.c_str());
      return -1;
    }
  }
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

  uint64_t ct_0     [L    ][POLY_N] = {0x0};
  uint64_t ct_1     [L    ][POLY_N] = {0x0};
  uint64_t ct_2     [L    ][POLY_N] = {0x0};
  uint64_t psi      [L + 1][ PSI_N] = {0x0};
  uint64_t psi_inv  [L + 1][ PSI_N] = {0x0};
  uint64_t rlk_0    [L * (L + 1)][POLY_N] = {0x0};
  uint64_t rlk_1    [L * (L + 1)][POLY_N] = {0x0};

  //////////////////////////////////////////////////// p0 /////////////////////////////////////////////////////////////
  readManyMemFileFlat("../../../scripts/kernel/test_vectors/ct2_"         , (uint64_t*) ct_2   , L          , POLY_N);
  readManyMemFileFlat("../../../scripts/kernel/test_vectors/psi_"         , (uint64_t*) psi    , L + 1      ,  PSI_N);
  readManyMemFileFlat("../../../scripts/kernel/test_vectors/psi_inv_"     , (uint64_t*) psi_inv, L + 1      ,  PSI_N);
  //////////////////////////////////////////////////// p1 /////////////////////////////////////////////////////////////
  readManyMemFileFlat("../../../scripts/kernel/test_vectors/relinkey_0_"  , (uint64_t*) rlk_0  , L * (L + 1), POLY_N);
  // readManyMemFileFlat("../../../scripts/kernel/test_vectors/ct0_"         , (uint64_t*) ct_0   , L          , POLY_N);
  // readManyMemFileFlat("../../../scripts/kernel/test_vectors/ct1_"         , (uint64_t*) ct_1   , L          , POLY_N);
  //////////////////////////////////////////////////// p2 /////////////////////////////////////////////////////////////
  readManyMemFileFlat("../../../scripts/kernel/test_vectors/relinkey_1_"  , (uint64_t*) rlk_1  , L * (L + 1), POLY_N);
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  


  std::cout << "[INFO] Prepare BO for Host->Device" << std::endl;
  xrt::bo hbm_i[PCI_COUNT];
  
  ///////////////////////////////////////////////////////////////////////////////////////////////
  for (int i = 0; i < PCI_COUNT; i++) {
    unsigned int pc_size;
    //////////////////////////// P0 /////////////////////////////////////////////////////////////
    if (i < P1_OFFSET) {
      // ct_2, psi, psi_inv
      pc_size = (PC_POLY_BYTE_SIZE * L) + (PC_PSI_BYTE_SIZE * (L + 1) * 2);
    }
    //////////////////////////// P1 /////////////////////////////////////////////////////////////
    else if (i < P2_OFFSET) {
      // rlk_0, ct_0, ct_1
      pc_size = (PC_POLY_BYTE_SIZE * L * (L + 1)) + (PC_POLY_BYTE_SIZE * L * 2);
    }
    //////////////////////////// P2 /////////////////////////////////////////////////////////////
    else {
      // rlk_1
      pc_size = (PC_POLY_BYTE_SIZE * L * (L + 1));
    }
    hbm_i[i] =
      xrt::bo(
        device,
        pc_size,
        kernel.group_id(i + 6));
    std::cout << "[INFO] hbm_i[" << i << "] is ready" << std::endl;
  }
  ///////////////////////////////////////////////////////////////////////////////////////////////


  unsigned int offset;

  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////// P0 //////////////////////////////////////////////////////////
  offset  = 0;
  offset += writeManyToPC((uint64_t*) ct_2   , L    , &(hbm_i[P0_OFFSET]), POLY_N, P0_COUNT, PC_DATA_WIDTH, offset);
  offset += writeManyToPC((uint64_t*) psi    , L + 1, &(hbm_i[P0_OFFSET]), PSI_N , P0_COUNT, PC_DATA_WIDTH, offset);
  offset += writeManyToPC((uint64_t*) psi_inv, L + 1, &(hbm_i[P0_OFFSET]), PSI_N , P0_COUNT, PC_DATA_WIDTH, offset);
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////// P1 //////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  offset  = 0;
  offset += writeManyToPC((uint64_t*) rlk_0  , L * (L + 1), &(hbm_i[P1_OFFSET]), POLY_N, P1_COUNT, PC_DATA_WIDTH, offset);
  // offset += writeManyToPC((uint64_t*) ct_0   , L          , &(hbm_i[P1_OFFSET]), POLY_N, P1_COUNT, PC_DATA_WIDTH, offset);
  // offset += writeManyToPC((uint64_t*) ct_1   , L          , &(hbm_i[P1_OFFSET]), POLY_N, P1_COUNT, PC_DATA_WIDTH, offset);
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////// P2 //////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  offset  = 0;
  offset += writeManyToPC((uint64_t*) rlk_1  , L * (L + 1), &(hbm_i[P2_OFFSET]), POLY_N, P2_COUNT, PC_DATA_WIDTH, offset);
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////

  for (int i = 0; i < 24; i++)
    std::cout << i << " " << std::hex << hbm_i[i].address() << std::endl;
  std::cout << "Reading back the inputs" << std::endl;

  uint64_t poly[2][POLY_N] = {0x0};

  readManyFromPC((uint64_t*) poly, 2, hbm_i, POLY_N, P0_COUNT, PC_DATA_WIDTH, 0);
  std::cout << "[INFO] Read back the inputs" << std::endl;
  writeManyMemFileFlat("../../../scripts/kernel/kernel_4096_I_64_readback_", (uint64_t*) poly, 2, POLY_N);
  

  std::cout << "[INFO] Prepare BO for Device->Host" << std::endl;
  xrt::bo hbm_o[PCO_COUNT];
  for (int i = 0; i < PCO_COUNT; i++) {
    // Allocate
    hbm_o[i] =
      xrt::bo(
        device,
        PC_POLY_BYTE_SIZE * L * 2,
        kernel.group_id(i + 6 + PCI_COUNT));
    std::cout << "[INFO] hbm_o[" << i << "] is ready" << std::endl;
  }

  ////////////////////////////////////////////////////////////////////////////
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
  // getchar();

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
      hbm_i[16],    // Pointer to hbm memory [16]
      hbm_i[17],    // Pointer to hbm memory [17]
      hbm_i[18],    // Pointer to hbm memory [18]
      hbm_i[19],    // Pointer to hbm memory [19]
      hbm_i[20],    // Pointer to hbm memory [20]
      hbm_i[21],    // Pointer to hbm memory [21]
      hbm_i[22],    // Pointer to hbm memory [22]
      hbm_i[23],    // Pointer to hbm memory [23]
      hbm_o[ 0],    // Pointer to hbm memory [24]
      hbm_o[ 1],    // Pointer to hbm memory [25]
      hbm_o[ 2],    // Pointer to hbm memory [26]
      hbm_o[ 3],    // Pointer to hbm memory [27]
      hbm_o[ 4],    // Pointer to hbm memory [28]
      hbm_o[ 5],    // Pointer to hbm memory [29]
      hbm_o[ 6],    // Pointer to hbm memory [30]
      hbm_o[ 7]     // Pointer to hbm memory [31]
    );
  std::cout << "Running the Kernel" << std::endl;
  
  run.wait();
  std::cout << "Kernel is done" << std::endl;

  //////////////////////////////////////////////////////////////////////////////
  // Get the outputs

  std::cout << "Reading back the results" << std::endl;
  uint64_t ct_0_rl[L][POLY_N] = {0x0};
  uint64_t ct_1_rl[L][POLY_N] = {0x0};

  unsigned int offset = 0;
  offset += readFromPC((uint64_t*) ct_0_rl[0], hbm_o, POLY_N, PCO_COUNT, PC_DATA_WIDTH, offset);
  offset += readFromPC((uint64_t*) ct_0_rl[1], hbm_o, POLY_N, PCO_COUNT, PC_DATA_WIDTH, offset);
  offset += readFromPC((uint64_t*) ct_1_rl[0], hbm_o, POLY_N, PCO_COUNT, PC_DATA_WIDTH, offset);
  offset += readFromPC((uint64_t*) ct_1_rl[1], hbm_o, POLY_N, PCO_COUNT, PC_DATA_WIDTH, offset);
  writeManyMemFileFlat("../../../scripts/kernel/computed/ct0_rl_", (uint64_t*) ct_0_rl, 2, POLY_N);
  writeManyMemFileFlat("../../../scripts/kernel/computed/ct1_rl_", (uint64_t*) ct_1_rl, 2, POLY_N);

  return 1;
}
