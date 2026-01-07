# 32-bit 5-Stage Pipelined MIPS Processor (Verilog)

This project implements a **32-bit 5-stage pipelined MIPS processor** in **Verilog HDL**.  
The processor is designed and simulated using **Xilinx Vivado**.

The implementation follows a **clean modular structure**, includes **data hazard handling**, and is suitable for learning, experimentation, and FPGA deployment.

---

## 📌 Features

- 32-bit MIPS architecture
- 5-stage pipeline:
  - Instruction Fetch (IF)
  - Instruction Decode (ID)
  - Execute (EX)
  - Memory Access (MEM)
  - Write Back (WB)
- Pipeline registers between all stages (IF/ID, ID/EX, EX/MEM, MEM/WB)
- Data hazard handling:
  - Forwarding unit
  - Stall (load-use hazard detection)
- Control hazard handling:
  - Branch (BNE)
  - Jump (J)
  - Jump Register (JR)
  - Pipeline flush logic
- Separate instruction and data memory
- Written entirely in synthesizable Verilog
- Compatible with Xilinx Vivado Simulator and synthesis flow

---

## 🧠 Architecture Overview

The processor follows the standard MIPS pipelined datapath:

IF → IF/ID → ID → ID/EX → EX → EX/MEM → MEM → MEM/WB → WB

- Each pipeline stage is separated by registers
- Control signals are generated in the ID stage and propagated forward
- Forwarding logic resolves most data hazards without stalling
- Load-use hazards are handled using pipeline stalls
- WB stage is implemented as combinational logic (no dedicated WB module)

---

### 📌 Note on WB Directory
The Write Back (WB) stage does **not** have a dedicated module in this design.  
It consists of:
- MEM/WB pipeline registers
- A `MemToReg` multiplexer
- Direct write-back to the register file

Hence, the `rtl/WB/` directory is intentionally empty.

---

## 🧩 Key Modules

### Common
- `register.v` – Generic pipeline register
- `RegBit.v` – Single-bit pipeline register
- `mux2x32to32.v`, `mux3x32to32.v`
- `adder.v`
- `sign_extend.v`, `zero_extend.v`

### Control & Datapath
- `Control.v` – Main control unit
- `ALUControl_Block.v` – ALU control
- `alu.v` – Arithmetic Logic Unit
- `regfile.v` – Register file

### Hazard Handling
- `ForwardingUnit.v` – Data forwarding
- `StallControl.v` – Load-use hazard detection

### Memory
- `InstructionMem.v`
- `dataMem.v`

---

## 📖 Instruction Support (Typical)

- R-type: `add`, `sub`, `and`, `or`, `slt`
- I-type: `lw`, `sw`, `addi`
- Control flow: `bne`, `j`, `jr`

(Instruction support depends on the control logic configuration.)

---

## 🎯 Learning Outcomes

This project helps you understand:

- Pipelined CPU datapath design
- Hazard detection and forwarding
- Control signal propagation across pipeline stages
- Practical Verilog coding for processors
- Vivado simulation and debugging workflow

---

## 🚀 Possible Extensions

- Add new custom instructions
- Integrate performance counters
- Replace memories with FPGA BRAM
- Add UART or AXI interface
- Modify pipeline depth or control logic

---

