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

#define INPUT_RB_FILE "../../../scripts/kernel/kernel_8192_I_64_readback.txt"
#define OUTPUT_FILE   "../../../scripts/kernel/kernel_8192_O_64_computed.txt"

#define LOGQ 32

// Determine how many coefficients fit into one 64-bit word
#if LOGQ == 60
    #define PACK_FACTOR 1
#else
    #define PACK_FACTOR 2
#endif



#define POLY_N        (65536)
#define PSI_N         (65536)
#define L             (59)

#define PCI_COUNT          (24)
#define P0_OFFSET          (0)
#define P0_COUNT           (8)
#define P1_OFFSET          (8)
#define P1_COUNT           (8)
#define P2_OFFSET          (16)
#define P2_COUNT           (8)
#define PCO_COUNT          (8)

#define PC_DATA_WIDTH      (32) // interleaving 32-bytes per PC

#define POLY_N_WORDS (POLY_N / PACK_FACTOR)
#define PSI_N_WORDS  (PSI_N / PACK_FACTOR)

#define PC_POLY_COEFF_NUM  (POLY_N_WORDS / PCO_COUNT)
#define PC_POLY_BYTE_SIZE  (PC_POLY_COEFF_NUM*sizeof(uint64_t))
#define PC_DATA_U64_SIZE   (4) // num words at each data
#define PC_POLY_DATA_NUM   (PC_POLY_COEFF_NUM / PC_DATA_U64_SIZE) // coeffs at each PC

#define PC_PSI_COEFF_NUM   (PSI_N_WORDS / PCO_COUNT)
#define PC_PSI_BYTE_SIZE   (PC_PSI_COEFF_NUM*sizeof(uint64_t))
// PC_DATA_U64_SIZE already defined above
#define PC_PSI_DATA_NUM    (PC_PSI_COEFF_NUM / PC_DATA_U64_SIZE) // coeffs at each PC

#define READBACKTEST
// #define VERBOSE

unsigned int offset_ct_0 = 0;
unsigned int offset_ct_1 = 0;
unsigned int offset_ct_2 = 0;


int test_kernel(xrt::kernel kernel, xrt::bo *hbm_i, xrt::bo *hbm_o);


void printArray(const char* title, auto* array, uint32_t len) {
  printf("%s ", title);
  for (uint32_t i=0; i<len; i++)
    printf("0x%08X ", array[i]);
  printf("\n");
}


unsigned int readFromPC(uint64_t *out, xrt::bo *hbm, unsigned int n, unsigned int pc_num, unsigned int width, unsigned int hbm_offset=0, bool sync=true, bool coalesced=false) {

  unsigned int bsize          = n * sizeof(uint64_t);
  unsigned int pc_bsize       = bsize / pc_num;
  unsigned int pc_dsize       = pc_bsize / width;
  unsigned int pc_wsize       = n / pc_num;
  unsigned int pc_offset      = width*pc_num;
  unsigned int pc_woffset     = pc_offset >> 3;
  unsigned int word_per_width = width / sizeof(uint64_t);

  for (unsigned int pc = 0; pc < pc_num; pc++) {
    if (sync) {
      hbm[pc].sync(XCL_BO_SYNC_BO_FROM_DEVICE, pc_bsize, hbm_offset);
    }
    if (!coalesced) {
      for (unsigned int i = 0; i < pc_dsize; i++) {
        hbm[pc].read(&(out[(pc_woffset*i) + (word_per_width*pc)]), width, width*i + hbm_offset);
      }
    } else {
      hbm[pc].read(&(out[pc * pc_wsize]), pc_bsize, hbm_offset);
    }
  }
  return pc_bsize;
}


void postprocessFromCoalesced(const uint64_t* in, uint64_t* out, unsigned int n, unsigned int pc_num, unsigned int width) {
  assert(in != nullptr);
  assert(out != nullptr);
  assert(pc_num != 0);
  assert(width != 0);
  assert((width % sizeof(uint64_t)) == 0);

  const unsigned int word_per_width = width / sizeof(uint64_t);
  const unsigned int pc_wsize       = n / pc_num;
  const unsigned int pc_woffset     = word_per_width * pc_num;

  assert((n % pc_num) == 0);
  assert((pc_wsize % word_per_width) == 0);

  const unsigned int chunks_per_pc = pc_wsize / word_per_width;

  for (unsigned int pc = 0; pc < pc_num; pc++) {
    const unsigned int src_base = pc * pc_wsize;
    for (unsigned int i = 0; i < chunks_per_pc; i++) {
      const unsigned int src_idx = src_base + (i * word_per_width);
      const unsigned int dst_idx = (pc_woffset * i) + (word_per_width * pc);
      std::memcpy(&out[dst_idx], &in[src_idx], width);
    }
  }
}


void postprocessManyFromCoalesced(const uint64_t* in, uint64_t* out, unsigned int l, unsigned int n, unsigned int pc_num, unsigned int width) {
  assert(in != nullptr);
  assert(out != nullptr);

  for (unsigned int i = 0; i < l; i++) {
    postprocessFromCoalesced(in + (i * n), out + (i * n), n, pc_num, width);
  }
}


unsigned int readManyFromPC(uint64_t *out, unsigned int l, xrt::bo *hbm, unsigned int n, unsigned int pc_num, unsigned int width, unsigned int hbm_offset=0, bool coalesced=false) {
  unsigned int bsize          = n * sizeof(uint64_t);
  unsigned int pc_bsize       = bsize / pc_num;

  for (unsigned int pc = 0; pc < pc_num; pc++) {
    hbm[pc].sync(XCL_BO_SYNC_BO_FROM_DEVICE, pc_bsize*l, hbm_offset);
  }

  for (unsigned int i = 0; i < l; i++) {
    readFromPC(out + (i*n), hbm, n, pc_num, width, hbm_offset + (i * pc_bsize), false, coalesced);
  }

  return l * pc_bsize;
}


unsigned int writeToPC(const uint64_t *in, xrt::bo *hbm, unsigned int n, unsigned int pc_num, unsigned int width, unsigned int hbm_offset=0, bool sync=true, bool coalesced=false) {
  unsigned int bsize          = n * sizeof(uint64_t);
  unsigned int pc_bsize       = bsize / pc_num;
  unsigned int pc_dsize       = pc_bsize / width;
  unsigned int pc_wsize       = n / pc_num;
  unsigned int pc_offset      = width * pc_num;
  unsigned int pc_woffset     = pc_offset >> 3;
  unsigned int word_per_width = width / sizeof(uint64_t);

  //std::cout << "bsize" << bsize << std::endl;

  for (unsigned int pc = 0; pc < pc_num; pc++) {
    if (!coalesced) {
      for (unsigned int i = 0; i < pc_dsize; i++) {
        hbm[pc].write(&(in[(pc_woffset * i) + (word_per_width * pc)]), width, width * i + hbm_offset);
      }
    }
    else {
      hbm[pc].write(&(in[pc * pc_wsize]), pc_bsize, hbm_offset);
    }
    if (sync) {
      hbm[pc].sync(XCL_BO_SYNC_BO_TO_DEVICE, pc_bsize, hbm_offset);
    }
  }
  return pc_bsize;
}


void preprocessForCoalesced(const uint64_t* in, uint64_t* out, unsigned int n, unsigned int pc_num, unsigned int width) {
  assert(in != nullptr);
  assert(out != nullptr);
  assert(pc_num != 0);
  assert(width != 0);
  assert((width % sizeof(uint64_t)) == 0);

  const unsigned int word_per_width = width / sizeof(uint64_t);
  const unsigned int pc_wsize       = n / pc_num;
  const unsigned int pc_woffset     = word_per_width * pc_num;

  assert((n % pc_num) == 0);
  assert((pc_wsize % word_per_width) == 0);

  const unsigned int chunks_per_pc = pc_wsize / word_per_width;

  for (unsigned int pc = 0; pc < pc_num; pc++) {
    const unsigned int dst_base = pc * pc_wsize;
    for (unsigned int i = 0; i < chunks_per_pc; i++) {
      const unsigned int src_idx = (pc_woffset * i) + (word_per_width * pc);
      const unsigned int dst_idx = dst_base + (i * word_per_width);
      std::memcpy(&out[dst_idx], &in[src_idx], width);
    }
  }
}


void preprocessManyForCoalesced(const uint64_t* in, uint64_t* out, unsigned int l, unsigned int n, unsigned int pc_num, unsigned int width) {
  assert(in != nullptr);
  assert(out != nullptr);

  for (unsigned int i = 0; i < l; i++) {
    preprocessForCoalesced(in + (i * n), out + (i * n), n, pc_num, width);
  }
}


unsigned int writeManyToPC(const uint64_t *in, unsigned int l, xrt::bo *hbm, unsigned int n, unsigned int pc_num, unsigned int width, unsigned int hbm_offset=0, bool coalesced=false) {
  unsigned int bsize          = n * sizeof(uint64_t);
  unsigned int pc_bsize       = bsize / pc_num;

  for (unsigned int i = 0; i < l; i++) {
    writeToPC(in + (i*n), hbm, n, pc_num, width, hbm_offset + (i * pc_bsize), false, coalesced);
    //sleep(0.3); // sleep for 300 ms to avoid overwhelming the device with back-to-back writes
  }
  for (unsigned int pc = 0; pc < pc_num; pc++) {
    hbm[pc].sync(XCL_BO_SYNC_BO_TO_DEVICE, pc_bsize*l, hbm_offset);
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


int writeMemFileFlat(const char* filename, const uint64_t *memBuffer, int num_coeffs) {
  FILE * fp = fopen(filename, "w");
  if (fp == NULL) exit(EXIT_FAILURE);

  int num_words = num_coeffs / PACK_FACTOR;

  for (int i = 0; i < num_words; i++) {
    uint64_t packed_val = memBuffer[i];
    
    // Unpack the uint64_t back into individual text lines
    for (int p = 0; p < PACK_FACTOR; p++) {
#if LOGQ == 60
      fprintf(fp, "%016" PRIx64 "\n", packed_val);
#else
      uint32_t val = (packed_val >> (32 * p)) & 0xFFFFFFFF;
      fprintf(fp, "%08" PRIx32 "\n", val);
#endif
    }
  }

  fclose(fp);
  return 1;
}


int writeManyMemFileFlat(const std::string& prefix, const uint64_t* memBuffer, int l, int size) {
  int num_words = size / PACK_FACTOR;
  for (int i = 0; i < l; i++) {
    std::string filename = prefix + std::to_string(i) + ".txt";
    const uint64_t* chunk_ptr = memBuffer + (i * num_words);
    int status = writeMemFileFlat(filename.c_str(), chunk_ptr, size);
    if (status != 1) {
      fprintf(stderr, "Error writing to file: %s\n", filename.c_str());
      return -1;
    }
  }
  return 1;
}


int readMemFileFlat(const char* filename, uint64_t* memBuffer, int num_coeffs) {
  FILE* fp = fopen(filename, "r");
  if (fp == NULL) exit(EXIT_FAILURE);

  int num_words = num_coeffs / PACK_FACTOR;

  for (int i = 0; i < num_words; i++) {
    uint64_t packed_val = 0;
    
    // Read PACK_FACTOR elements from the file and pack them into 1 uint64_t
    for (int p = 0; p < PACK_FACTOR; p++) {
#if LOGQ == 60
      uint64_t temp = 0;
      if (fscanf(fp, "%" SCNx64, &temp) != 1) { fclose(fp); return -1; }
      packed_val |= temp; 
#else
      uint32_t temp = 0;
      if (fscanf(fp, "%" SCNx32, &temp) != 1) { fclose(fp); return -1; }
      packed_val |= (static_cast<uint64_t>(temp) << (32 * p));
#endif
    }
    memBuffer[i] = packed_val;
  }

  fclose(fp);
  return 1;
}


int readManyMemFileFlat(const std::string& prefix, uint64_t* memBuffer, int l, int size) {
  int num_words = size / PACK_FACTOR;

  for (int i = 0; i < l; i++) {
    std::string filename = prefix + std::to_string(i) + ".txt";
    uint64_t* target = memBuffer + (i * num_words);
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
  std::cout << "Allocating host-side buffers" << std::endl;

  std::vector<uint64_t> ct_0   (static_cast<size_t>(L)            * POLY_N_WORDS, 0);
  std::vector<uint64_t> ct_1   (static_cast<size_t>(L)            * POLY_N_WORDS, 0);
  std::vector<uint64_t> ct_2   (static_cast<size_t>(L)            * POLY_N_WORDS, 0);
  std::vector<uint64_t> psi    (static_cast<size_t>(L + 1)        * PSI_N_WORDS,  0);
  std::vector<uint64_t> psi_inv(static_cast<size_t>(L + 1)        * PSI_N_WORDS,  0);
  std::vector<uint64_t> rlk_0  (static_cast<size_t>(L * (L + 1)) * POLY_N_WORDS, 0);
  std::vector<uint64_t> rlk_1  (static_cast<size_t>(L * (L + 1)) * POLY_N_WORDS, 0);
  std::vector<uint64_t> ct_0_rl(static_cast<size_t>(L) * POLY_N_WORDS, 0);
  std::vector<uint64_t> ct_1_rl(static_cast<size_t>(L) * POLY_N_WORDS, 0);
  std::vector<uint64_t> ct_0_coalesced(static_cast<size_t>(L) * POLY_N_WORDS, 0);
  std::vector<uint64_t> ct_1_coalesced(static_cast<size_t>(L) * POLY_N_WORDS, 0);
  std::vector<uint64_t> ct_2_coalesced(static_cast<size_t>(L) * POLY_N_WORDS, 0);
  std::vector<uint64_t> ct_0_rl_coalesced(static_cast<size_t>(L) * POLY_N_WORDS, 0);
  std::vector<uint64_t> ct_1_rl_coalesced(static_cast<size_t>(L) * POLY_N_WORDS, 0);

  std::cout << "[INFO] Reading input files" << std::endl;
  //////////////////////////////////////////////////// p0 /////////////////////////////////////////////////////////////
  readManyMemFileFlat("../../../scripts/kernel/test_vectors/ct2_"        , ct_2.data()   , L          , POLY_N);
  readManyMemFileFlat("../../../scripts/kernel/test_vectors/psi_"        , psi.data()    , L + 1      ,  POLY_N);
  readManyMemFileFlat("../../../scripts/kernel/test_vectors/psi_inv_"    , psi_inv.data(), L + 1      ,  POLY_N);
  std::cout << "[INFO] p0 files are read" << std::endl;
  //////////////////////////////////////////////////// p1 /////////////////////////////////////////////////////////////
  readManyMemFileFlat("../../../scripts/kernel/test_vectors/relinkey_0_" , rlk_0.data()  , L * (L + 1), POLY_N);
  readManyMemFileFlat("../../../scripts/kernel/test_vectors/ct0_"     , ct_0.data()   , L          , POLY_N);
  readManyMemFileFlat("../../../scripts/kernel/test_vectors/ct1_"     , ct_1.data()   , L          , POLY_N);
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



  std::cout << "[INFO] Writing inputs to device HBM" << std::endl;

  unsigned int offset;

  //////////////////////////////////////// CONSTANT DATA ////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////// P0 //////////////////////////////////////////////////////////
  // offset  = POLY_N << 1;
  offset  = PC_POLY_BYTE_SIZE * L;
  offset += writeManyToPC(psi.data()    , L + 1, &(hbm_i[P0_OFFSET]), PSI_N_WORDS , P0_COUNT, PC_DATA_WIDTH, offset);
  offset += writeManyToPC(psi_inv.data(), L + 1, &(hbm_i[P0_OFFSET]), PSI_N_WORDS , P0_COUNT, PC_DATA_WIDTH, offset);
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////// P1 //////////////////////////////////////////////////////////
  offset  = 0;
  writeManyToPC(rlk_0.data()  , L * (L + 1) , &(hbm_i[P1_OFFSET]), POLY_N_WORDS, P1_COUNT, PC_DATA_WIDTH, offset);
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////// P2 //////////////////////////////////////////////////////////
  offset  = 0;
  writeManyToPC(rlk_1.data()  , L * (L + 1), &(hbm_i[P2_OFFSET]), POLY_N_WORDS, P2_COUNT, PC_DATA_WIDTH, offset);
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////


  // Preprocess live ct_2 for coalesced HBM writes.
  preprocessManyForCoalesced(ct_0.data(), ct_0_coalesced.data(), L, POLY_N_WORDS, P0_COUNT, PC_DATA_WIDTH);
  preprocessManyForCoalesced(ct_1.data(), ct_1_coalesced.data(), L, POLY_N_WORDS, P0_COUNT, PC_DATA_WIDTH);
  preprocessManyForCoalesced(ct_2.data(), ct_2_coalesced.data(), L, POLY_N_WORDS, P0_COUNT, PC_DATA_WIDTH);

  auto t_start = std::chrono::high_resolution_clock::now();

  //////////////////////////////////////// LIVE DATA //////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////// P0 //////////////////////////////////////////////////////////
  offset  = 0;
  offset += writeManyToPC(ct_2_coalesced.data(), L, &(hbm_i[P0_OFFSET]), POLY_N_WORDS, P0_COUNT, PC_DATA_WIDTH, offset, true);

  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////// P1 //////////////////////////////////////////////////////////
  offset = (L + 1)*(PC_POLY_BYTE_SIZE * L);
  offset_ct_0 = offset; // save offset for ct_0 to read back later
  offset += writeManyToPC(ct_0_coalesced.data() , L             , &(hbm_i[P1_OFFSET]), POLY_N_WORDS, P1_COUNT, PC_DATA_WIDTH, offset, true);
  offset_ct_1 = offset; // save offset for ct_1 to read back later
  offset += writeManyToPC(ct_1_coalesced.data() , L             , &(hbm_i[P1_OFFSET]), POLY_N_WORDS, P1_COUNT, PC_DATA_WIDTH, offset, true);
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////

#ifdef READBACKTEST

  for (int i = 0; i < 24; i++)
    std::cout << i << " " << std::hex << hbm_i[i].address() << std::endl;
  std::cout << "Reading back the inputs" << std::endl;

  // FIX: poly readback buffer on heap (was stack: 2 * 8192 * 8B = 512 KB)
  std::vector<uint64_t> poly(static_cast<size_t>(2) * POLY_N, 0);

  readManyFromPC(poly.data(), 2, hbm_i, POLY_N_WORDS, P0_COUNT, PC_DATA_WIDTH, 0);
  std::cout << "[INFO] Read back the inputs" << std::endl;
  writeManyMemFileFlat("../../../scripts/kernel/kernel_8192_I_64_readback_", poly.data(), 2, POLY_N);
#endif

  ////////////////////////////////////////////////////////////////////////////
  // Start Test

  test_kernel(kernel, hbm_i, hbm_o);
  
#ifdef VERBOSE
  std::cout << "Reading back the results" << std::endl;
#endif

  offset = 0;
  // Read back L rows of ct_0_rl
  offset += readManyFromPC(ct_0_rl_coalesced.data(), L, hbm_o, POLY_N_WORDS, PCO_COUNT, PC_DATA_WIDTH, offset, true);
  readManyFromPC(ct_1_rl_coalesced.data(), L, hbm_o, POLY_N_WORDS, PCO_COUNT, PC_DATA_WIDTH, offset, true);



#ifdef VERBOSE
  std::cout << "Reading back ct_0_rl done" << std::endl;
#endif

#ifdef VERBOSE
  std::cout << "Reading back ct_1_rl done" << std::endl;
#endif

  auto t_end = std::chrono::high_resolution_clock::now();

  // compute time in ms
  double elapsed_ms =
    std::chrono::duration<double, std::milli>(t_end - t_start).count();

  std::cout << "Kernel execution time (outer): "
            << elapsed_ms << " ms" << std::endl;

  // Postprocess only after all reads are completed.
  postprocessManyFromCoalesced(ct_0_rl_coalesced.data(), ct_0_rl.data(), L, POLY_N_WORDS, PCO_COUNT, PC_DATA_WIDTH);
  postprocessManyFromCoalesced(ct_1_rl_coalesced.data(), ct_1_rl.data(), L, POLY_N_WORDS, PCO_COUNT, PC_DATA_WIDTH);


  writeManyMemFileFlat("../../../scripts/kernel/computed/ct0_rl_", ct_0_rl.data(), L, POLY_N);
  writeManyMemFileFlat("../../../scripts/kernel/computed/ct1_rl_", ct_1_rl.data(), L, POLY_N);

  return 0;
}

////////////////////////////////////////////////////////////////////////////////

int test_kernel(xrt::kernel kernel, xrt::bo *hbm_i, xrt::bo *hbm_o) {

  uint32_t ap_control   = 1;
  uint32_t ap_status    = 0;
  uint32_t ap_debug     = 0;
  uint32_t ap_timing    = 0;
  uint32_t hbm_params_0 = 0;
  uint32_t hbm_params_1 = 0;

  //////////////////////////////////////////////////////////////////////////////
  // Start running the kernel
#ifdef VERBOSE
  std::cout << "Ready?" << std::endl;
#endif
  //getchar();

  // start timer
  auto t_start = std::chrono::high_resolution_clock::now();
#ifdef VERBOSE
  std::cout << "Run the Kernel" << std::endl;
#endif

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
#ifdef VERBOSE
  std::cout << "Running the Kernel" << std::endl;
#endif



  run.wait(); // wait for kernel to finish before reading debug registers

  
#ifdef VERBOSE
  std::cout << "Kernel is done" << std::endl;
#endif
  // end timer
  auto t_end = std::chrono::high_resolution_clock::now();

  // compute time in ms
  double elapsed_ms =
    std::chrono::duration<double, std::milli>(t_end - t_start).count();

  std::cout << "Kernel execution time: "
            << elapsed_ms << " ms" << std::endl;

  return 1;
}