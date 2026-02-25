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
#include <vector>

#include <unistd.h>
#include <chrono>

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

#define AP_DEBUG2  0x128
#define AP_DEBUG3  0x12C
#define AP_DEBUG4  0x130
#define AP_DEBUG5  0x134
#define AP_DEBUG6  0x138
#define AP_DEBUG7  0x13C
#define AP_DEBUG8  0x140
#define AP_DEBUG9  0x144
#define AP_DEBUG10 0x148
#define AP_DEBUG11 0x14C
#define AP_DEBUG12 0x150
#define AP_DEBUG13 0x154
#define AP_DEBUG14 0x158
#define AP_DEBUG15 0x15C
#define AP_DEBUG16 0x160
#define AP_DEBUG17 0x164
#define AP_DEBUG18 0x168
#define AP_DEBUG19 0x16C
#define AP_DEBUG20 0x170
#define AP_DEBUG21 0x174
#define AP_DEBUG22 0x178
#define AP_DEBUG23 0x17C
#define AP_DEBUG24 0x180
#define AP_DEBUG25 0x184
#define AP_DEBUG26 0x188
#define AP_DEBUG27 0x18C
#define AP_DEBUG28 0x190
#define AP_DEBUG29 0x194
#define AP_DEBUG30 0x198
#define AP_DEBUG31 0x19C

#define INPUT_RB_FILE "../../../scripts/kernel/kernel_65536_I_64_readback.txt"
#define OUTPUT_FILE   "../../../scripts/kernel/kernel_65536_O_64_computed.txt"

#define POLY_N        (65536)
#define PSI_N         (65536)
#define L             (28)

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
// PC_DATA_U64_SIZE already defined above
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
    sleep(0.3); // sleep for 300 ms to avoid overwhelming the device with back-to-back writes
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

void print_bin(uint32_t v, int bits)
{
    for (int i = bits - 1; i >= 0; i--)
        printf("%c", (v & (1u << i)) ? '1' : '0');
}

static inline void print_bin_w(uint32_t v, int w)
{
    for (int i = w - 1; i >= 0; --i)
        putchar((v & (1u << i)) ? '1' : '0');
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
  //
  // FIX: All large arrays moved from stack to heap via std::vector.
  //
  // Original stack usage breakdown (caused segfault):
  //   ct_0, ct_1, ct_2  : 3 * 14 * 65536 * 8B  =  ~11 MB
  //   psi, psi_inv       : 2 * 15 * 65536 * 8B  =  ~7.9 MB
  //   rlk_0, rlk_1       : 2 * 210 * 65536 * 8B =  ~110 MB
  //   Total              :                        =  ~130 MB  <-- WAY over 8MB stack limit
  //
  // Now all allocated on heap; stack usage is negligible.

  std::cout << "Allocating host-side buffers" << std::endl;

  std::vector<uint64_t> ct_0   (static_cast<size_t>(L)            * POLY_N, 0);
  std::vector<uint64_t> ct_1   (static_cast<size_t>(L)            * POLY_N, 0);
  std::vector<uint64_t> ct_2   (static_cast<size_t>(L)            * POLY_N, 0);
  std::vector<uint64_t> psi    (static_cast<size_t>(L + 1)        * PSI_N,  0);
  std::vector<uint64_t> psi_inv(static_cast<size_t>(L + 1)        * PSI_N,  0);
  std::vector<uint64_t> rlk_0  (static_cast<size_t>(L * (L + 1)) * POLY_N, 0);
  std::vector<uint64_t> rlk_1  (static_cast<size_t>(L * (L + 1)) * POLY_N, 0);

  std::cout << "[INFO] Reading input files" << std::endl;
  //////////////////////////////////////////////////// p0 /////////////////////////////////////////////////////////////
  readManyMemFileFlat("../../../scripts/kernel/test_vectors/ct2_"        , ct_2.data()   , L          , POLY_N);
  readManyMemFileFlat("../../../scripts/kernel/test_vectors/psi_"        , psi.data()    , L + 1      ,  PSI_N);
  readManyMemFileFlat("../../../scripts/kernel/test_vectors/psi_inv_"    , psi_inv.data(), L + 1      ,  PSI_N);
  std::cout << "[INFO] p0 files are read" << std::endl;
  //////////////////////////////////////////////////// p1 /////////////////////////////////////////////////////////////
  readManyMemFileFlat("../../../scripts/kernel/test_vectors/relinkey_0_" , rlk_0.data()  , L * (L + 1), POLY_N);
  // readManyMemFileFlat("../../../scripts/kernel/test_vectors/ct0_"     , ct_0.data()   , L          , POLY_N);
  // readManyMemFileFlat("../../../scripts/kernel/test_vectors/ct1_"     , ct_1.data()   , L          , POLY_N);
  std::cout << "[INFO] p1 files are read" << std::endl;
  //////////////////////////////////////////////////// p2 /////////////////////////////////////////////////////////////
  readManyMemFileFlat("../../../scripts/kernel/test_vectors/relinkey_1_" , rlk_1.data()  , L * (L + 1), POLY_N);
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  std::cout << "[INFO] Input files are read" << std::endl;

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

  std::cout << "[INFO] Writing inputs to device HBM" << std::endl;

  unsigned int offset;

  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////// P0 //////////////////////////////////////////////////////////
  offset  = 0;
  offset += writeManyToPC(ct_2.data()   , L    , &(hbm_i[P0_OFFSET]), POLY_N, P0_COUNT, PC_DATA_WIDTH, offset);
  offset += writeManyToPC(psi.data()    , L + 1, &(hbm_i[P0_OFFSET]), PSI_N , P0_COUNT, PC_DATA_WIDTH, offset);
  offset += writeManyToPC(psi_inv.data(), L + 1, &(hbm_i[P0_OFFSET]), PSI_N , P0_COUNT, PC_DATA_WIDTH, offset);
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////// P1 //////////////////////////////////////////////////////////
  offset  = 0;
  offset += writeManyToPC(rlk_0.data()  , L * (L + 1), &(hbm_i[P1_OFFSET]), POLY_N, P1_COUNT, PC_DATA_WIDTH, offset);
  // offset += writeManyToPC(ct_0.data() , L          , &(hbm_i[P1_OFFSET]), POLY_N, P1_COUNT, PC_DATA_WIDTH, offset);
  // offset += writeManyToPC(ct_1.data() , L          , &(hbm_i[P1_OFFSET]), POLY_N, P1_COUNT, PC_DATA_WIDTH, offset);
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////// P2 //////////////////////////////////////////////////////////
  offset  = 0;
  offset += writeManyToPC(rlk_1.data()  , L * (L + 1), &(hbm_i[P2_OFFSET]), POLY_N, P2_COUNT, PC_DATA_WIDTH, offset);
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////

  for (int i = 0; i < 24; i++)
    std::cout << i << " " << std::hex << hbm_i[i].address() << std::endl;
  std::cout << "Reading back the inputs" << std::endl;

  // FIX: poly readback buffer on heap (was stack: 2 * 65536 * 8B = 512 KB)
  std::vector<uint64_t> poly(static_cast<size_t>(2) * POLY_N, 0);

  readManyFromPC(poly.data(), 2, hbm_i, POLY_N, P0_COUNT, PC_DATA_WIDTH, 0);
  std::cout << "[INFO] Read back the inputs" << std::endl;
  writeManyMemFileFlat("../../../scripts/kernel/kernel_65536_I_64_readback_", poly.data(), 2, POLY_N);

  std::cout << "[INFO] Prepare BO for Device->Host" << std::endl;
  xrt::bo hbm_o[PCO_COUNT];
  for (int i = 0; i < PCO_COUNT; i++) {
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
  getchar();

  // start timer
  auto t_start = std::chrono::high_resolution_clock::now();

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

  //

  run.wait(); // wait for kernel to finish before reading debug registers

  for (int t = 0; t < 10; t++) {

    usleep(3000);

    // ---------- PSI ----------
    uint32_t psi = kernel.read_register(AP_DEBUG);

    // ---------- NTT ----------
    uint32_t ntt_i     = kernel.read_register(AP_DEBUG2);
    uint32_t ntt_valid = kernel.read_register(AP_DEBUG3);

    uint32_t had_0_i_poly_A_dbg      = kernel.read_register(AP_DEBUG22);
    uint32_t had_0_i_poly_B_dbg  = kernel.read_register(AP_DEBUG23);
    uint32_t had_0_i_poly_last      = kernel.read_register(AP_DEBUG24);
    uint32_t had_0_i_poly_last_B  = kernel.read_register(AP_DEBUG25);

    // ---------- Pipeline taps (former FIFO/Hadamard/ACC inputs) ----------
    uint32_t dbg0_i  = kernel.read_register(AP_DEBUG4);
    uint32_t dbg0_l  = kernel.read_register(AP_DEBUG5);

    uint32_t dbg4_i  = kernel.read_register(AP_DEBUG6);
    uint32_t dbg4_l  = kernel.read_register(AP_DEBUG7);

    uint32_t dbg8_i  = kernel.read_register(AP_DEBUG8);
    uint32_t dbg8_l  = kernel.read_register(AP_DEBUG9);

    uint32_t dbg16_i = kernel.read_register(AP_DEBUG10);
    uint32_t dbg16_l = kernel.read_register(AP_DEBUG11);

    uint32_t dbg20_i = kernel.read_register(AP_DEBUG12);
    uint32_t dbg20_l = kernel.read_register(AP_DEBUG13);

    uint32_t dbg27_i = kernel.read_register(AP_DEBUG14);
    uint32_t dbg27_l = kernel.read_register(AP_DEBUG15);

    // ---------- ACC output ----------
    uint32_t acc_out   = kernel.read_register(AP_DEBUG16);
    uint32_t acc_last  = kernel.read_register(AP_DEBUG21);

    // ---------- INTT ----------
    uint32_t intt_i     = kernel.read_register(AP_DEBUG17);
    uint32_t intt_last  = kernel.read_register(AP_DEBUG30);

    // ---------- Final FN ----------
    uint32_t fn_i      = kernel.read_register(AP_DEBUG18);
    uint32_t fn_iLast  = kernel.read_register(AP_DEBUG31);
    uint32_t fn_o      = kernel.read_register(AP_DEBUG19);
    uint32_t fn_oLast  = kernel.read_register(AP_DEBUG20);

    uint32_t stat = kernel.read_register(AP_STATUS);

    printf("\n========== FPGA PIPELINE DEBUG ==========\n");

    printf("PSI                 : 0x%08X\n", psi);

    printf("NTT in              : 0x%08X\n", ntt_i);
    printf("NTT valid           : 0x%08X\n", ntt_valid);

    printf("Had0 A/B/last/last_B: 0x%08X / 0x%08X / 0x%08X / 0x%08X\n", had_0_i_poly_A_dbg, had_0_i_poly_B_dbg, had_0_i_poly_last, had_0_i_poly_last_B);

    printf("DBG0 in/last        : 0x%08X / 0x%08X\n", dbg0_i, dbg0_l);
    printf("DBG4 in/last        : 0x%08X / 0x%08X\n", dbg4_i, dbg4_l);
    printf("DBG8 in/last        : 0x%08X / 0x%08X\n", dbg8_i, dbg8_l);
    printf("DBG16 in/last       : 0x%08X / 0x%08X\n", dbg16_i, dbg16_l);
    printf("DBG20 in/last       : 0x%08X / 0x%08X\n", dbg20_i, dbg20_l);
    printf("DBG27 in/last       : 0x%08X / 0x%08X\n", dbg27_i, dbg27_l);

    printf("ACC out/last        : 0x%08X / 0x%08X\n", acc_out, acc_last);

    printf("INTT in/last        : 0x%08X / 0x%08X\n", intt_i, intt_last);

    printf("FN in/last          : 0x%08X / 0x%08X\n", fn_i, fn_iLast);
    printf("FN out/last         : 0x%08X / 0x%08X\n", fn_o, fn_oLast);

    printf("STATUS              : 0x%08X\n", stat);
    printf("=========================================\n");

    if (stat & 0x1) break;

    usleep(1000);
}

  // for (int t = 0; t < 100; t++) {

  //   usleep(3000); // sleep for 300 ms

  //   // PSI stage
  //   uint32_t psi = kernel.read_register(AP_DEBUG);

  //   // NTT stage
  //   uint32_t ntt_i       = kernel.read_register(AP_DEBUG2);
  //   uint32_t ntt_i_last  = kernel.read_register(AP_DEBUG21);
  //   uint32_t ntt_valid   = kernel.read_register(AP_DEBUG3);
  //   uint32_t ntt_o_last  = kernel.read_register(AP_DEBUG22);

  //   // FIFO stage
  //   uint32_t fifo0_i = kernel.read_register(AP_DEBUG4);
  //   uint32_t fifo1_i = kernel.read_register(AP_DEBUG5);
  //   uint32_t fifo0_o = kernel.read_register(AP_DEBUG6);
  //   uint32_t fifo1_o = kernel.read_register(AP_DEBUG7);

  //   // Hadamard stage
  //   uint32_t had0A      = kernel.read_register(AP_DEBUG8);
  //   uint32_t had0B      = kernel.read_register(AP_DEBUG9);
  //   uint32_t had0_iLast = kernel.read_register(AP_DEBUG23);

  //   uint32_t had1A      = kernel.read_register(AP_DEBUG10);
  //   uint32_t had1B      = kernel.read_register(AP_DEBUG11);
  //   uint32_t had1_iLast = kernel.read_register(AP_DEBUG24);

  //   uint32_t had0_out   = kernel.read_register(AP_DEBUG12);
  //   uint32_t had0_oLast = kernel.read_register(AP_DEBUG25);

  //   uint32_t had1_out   = kernel.read_register(AP_DEBUG13);
  //   uint32_t had1_oLast = kernel.read_register(AP_DEBUG26);

  //   // Accumulator stage
  //   uint32_t acc_i0     = kernel.read_register(AP_DEBUG14);
  //   uint32_t acc_i0Last = kernel.read_register(AP_DEBUG27);
  //   uint32_t acc_i1     = kernel.read_register(AP_DEBUG15);
  //   uint32_t acc_i1Last = kernel.read_register(AP_DEBUG28);
  //   uint32_t acc_out    = kernel.read_register(AP_DEBUG16);
  //   uint32_t acc_oLast  = kernel.read_register(AP_DEBUG29);

  //   // INTT stage
  //   uint32_t intt_i     = kernel.read_register(AP_DEBUG17);
  //   uint32_t intt_iLast = kernel.read_register(AP_DEBUG30);

  //   // Final FN stage
  //   uint32_t fn_i       = kernel.read_register(AP_DEBUG18);
  //   uint32_t fn_iLast   = kernel.read_register(AP_DEBUG31);
  //   uint32_t fn_o       = kernel.read_register(AP_DEBUG19);
  //   uint32_t fn_oLast   = kernel.read_register(AP_DEBUG20);

  //   uint32_t stat = kernel.read_register(AP_STATUS);

  //   printf("\n========== FPGA PIPELINE DEBUG ==========\n");

  //   // PSI
  //   printf("PSI                : 0x%08X\n", psi);

  //   // NTT
  //   printf("NTT in             : 0x%08X\n", ntt_i);
  //   printf("NTT in last        : 0x%08X\n", ntt_i_last);
  //   printf("NTT valid          : 0x%08X\n", ntt_valid);
  //   printf("NTT out last       : 0x%08X\n", ntt_o_last);

  //   // FIFO
  //   printf("FIFO0 in/out       : 0x%08X -> 0x%08X\n", fifo0_i, fifo0_o);
  //   printf("FIFO1 in/out       : 0x%08X -> 0x%08X\n", fifo1_i, fifo1_o);

  //   // Hadamard
  //   printf("HAD0 A/B           : 0x%08X 0x%08X\n", had0A, had0B);
  //   printf("HAD0 in last       : 0x%08X\n", had0_iLast);
  //   printf("HAD0 out           : 0x%08X\n", had0_out);
  //   printf("HAD0 out last      : 0x%08X\n", had0_oLast);

  //   printf("HAD1 A/B           : 0x%08X 0x%08X\n", had1A, had1B);
  //   printf("HAD1 in last       : 0x%08X\n", had1_iLast);
  //   printf("HAD1 out           : 0x%08X\n", had1_out);
  //   printf("HAD1 out last      : 0x%08X\n", had1_oLast);

  //   // ACC
  //   printf("ACC in0/last       : 0x%08X / 0x%08X\n", acc_i0, acc_i0Last);
  //   printf("ACC in1/last       : 0x%08X / 0x%08X\n", acc_i1, acc_i1Last);
  //   printf("ACC out/last       : 0x%08X / 0x%08X\n", acc_out, acc_oLast);

  //   // INTT
  //   printf("INTT in/last       : 0x%08X / 0x%08X\n", intt_i, intt_iLast);

  //   // FN
  //   printf("FN in/last         : 0x%08X / 0x%08X\n", fn_i, fn_iLast);
  //   printf("FN out/last        : 0x%08X / 0x%08X\n", fn_o, fn_oLast);

  //   printf("STATUS             : 0x%08X\n", stat);
  //   printf("=========================================\n");

  //     if (stat & 0x1) break;

  //   usleep(1000);
  // }

  //run.wait();

  

  std::cout << "Kernel is done" << std::endl;

  // end timer
  auto t_end = std::chrono::high_resolution_clock::now();

  // compute time in ms
  double elapsed_ms =
    std::chrono::duration<double, std::milli>(t_end - t_start).count();

  std::cout << "Kernel execution time: "
            << elapsed_ms << " ms" << std::endl;

  //////////////////////////////////////////////////////////////////////////////
  // Get the outputs
  //
  // FIX: ct_0_rl and ct_1_rl moved from stack to heap.
  //      Each was [L][POLY_N] = 14 * 65536 * 8B = ~3.7 MB on the stack.
  //      Now allocated as flat vectors and accessed via a row-pointer helper.

  std::cout << "Reading back the results" << std::endl;

  std::vector<uint64_t> ct_0_rl(static_cast<size_t>(L) * POLY_N, 0);
  std::vector<uint64_t> ct_1_rl(static_cast<size_t>(L) * POLY_N, 0);

  // Helper: returns pointer to row i in a flat [L * POLY_N] vector
  auto row = [](std::vector<uint64_t>& v, int i) -> uint64_t* {
    return v.data() + static_cast<size_t>(i) * POLY_N;
  };

  unsigned int offset = 0;

  // Read back L rows of ct_0_rl
  for (int i = 0; i < L; i++) {
    offset += readFromPC(row(ct_0_rl, i), hbm_o, POLY_N, PCO_COUNT, PC_DATA_WIDTH, offset);
  }
  std::cout << "Reading back ct_0_rl done" << std::endl;

  // Read back L rows of ct_1_rl
  for (int i = 0; i < L; i++) {
    offset += readFromPC(row(ct_1_rl, i), hbm_o, POLY_N, PCO_COUNT, PC_DATA_WIDTH, offset);
  }
  std::cout << "Reading back ct_1_rl done" << std::endl;

  writeManyMemFileFlat("../../../scripts/kernel/computed/ct0_rl_", ct_0_rl.data(), L, POLY_N);
  writeManyMemFileFlat("../../../scripts/kernel/computed/ct1_rl_", ct_1_rl.data(), L, POLY_N);

  return 1;
}