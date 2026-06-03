# Relin-FPGA

**FHE Relinearization Accelerator on FPGA**

This repository contains an FPGA-based accelerator for BFV/FHE relinearization. The project includes software model generation, test-vector creation, RTL simulation, hardware emulation, and real FPGA testing support.

The design has been tested on the **AMD/Xilinx Alveo U280 FPGA board with HBM**.

---

## 1. Repository Setup

Clone the repository:

```bash
git clone <repository-url> Relin-FPGA
cd Relin-FPGA
```

Initialize and update the Git submodules:

```bash
git submodule update --init --recursive
```

Alternatively, the repository can be cloned directly with submodules using:

```bash
git clone --recursive <repository-url> Relin-FPGA
cd Relin-FPGA
```

---

## 2. Generate Relinearization Test Vectors

First, go to the BFV model directory:

```bash
cd model/BFV
```

Open `test.py` and update the following variables according to the desired parameter set:

```python
ring_dimension
LOGQ
q_tilda_size
```

These parameters are used to generate the relinearization test vectors.

After running the script, the generated test vectors should appear in:

```bash
model/BFV/test_vectors
```

---

## 3. Configure Simulation Parameters

For RTL simulation testing, go to the testbench directory:

```bash
cd src/relin/tb/kernel_tb
```

Update the following parameters in the testbench according to your configuration:

```verilog
parameter LOGN  = 12;
parameter LOGQ  = 60;
parameter LOGQH = 17;
parameter LOGTP = 5;
parameter L     = 2;
```

The `LOGQH` parameter depends on `LOGQ`:

```text
LOGQ = 60  -> LOGQH = 17
LOGQ = 32  -> LOGQH = 15
```

Make sure that the RTL simulation parameters match the test-vector parameters generated in `model/BFV/test.py`.

---

## 4. Run RTL Simulation in Vivado

Open the Vivado 2023 project:

```bash
vivado_2023/relin.xpr
```

You can open this file directly from Vivado.

Then click:

```text
Run Simulation
```

If the configuration and test vectors are correct, the simulation should finish successfully.

At the end of the simulation output, you should see:

```text
HBM Data Verification Completed
```

There should be no errors in the simulation log.

---

## 5. Real FPGA Testing

For hardware emulation or real FPGA testing, go to the HBM interface directory:

```bash
cd HBM_interface
```

Copy the generated test vectors from:

```bash
model/BFV/test_vectors
```

to:

```bash
HBM_interface/scripts/kernel
```

These files are used as the input test vectors for the host-side hardware test.

---

### 5.1 Hardware Emulation

Hardware emulation can be built and run with `TARGET=hw_emu`.

This may take around 30 minutes.

```bash
make build TARGET=hw_emu
make run_prepare TARGET=hw_emu
make host TARGET=hw_emu
make run TARGET=hw_emu
```

This runs the design in hardware emulation mode for the Alveo U280 platform.

---

### 5.2 Real Hardware Execution

Real hardware execution can be built and run with `TARGET=hw`.

This may take several hours.

Before running the hardware test, open:

```bash
HBM_interface/auto_run.sh
```

Update the following variables:

```bash
ITER
RNS_NUM
```

`ITER` specifies how many times the hardware test will be repeated.

`RNS_NUM` specifies the number of RNS primes in `Q`. This corresponds to the BFV modulus decomposition, where `RNS_NUM` is related to `\tilde{l} - 1` in the paper.

Then build and run the hardware design:

```bash
make build TARGET=hw
make host TARGET=hw
make run_prepare TARGET=hw
./auto_run.sh
```

The script automatically creates test logs in:

```bash
run.txt
```

It also compares the original reference results:

```bash
test_vectors/relin_ct*
```

with the computed hardware results:

```bash
computed/relin_ct*
```

If the test is successful, the computed FPGA outputs should match the reference test-vector outputs.

---

## Notes

Make sure the following parameters are consistent between the software model, RTL simulation, hardware emulation, and real FPGA testing:

* `ring_dimension`
* `LOGN`
* `LOGQ`
* `LOGQH`
* `LOGTP`
* `L`
* `q_tilda_size`
* `RNS_NUM`

Mismatch between generated test vectors, RTL parameters, and host-side hardware configuration may cause simulation or hardware verification errors.

---

## Contact

For any questions, please contact:

**Emre Koçer**
`kocer@sabanciuniv.edu`
