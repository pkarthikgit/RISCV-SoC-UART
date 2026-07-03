# 32-bit RISC-V Processor with UART

This is a simple 32-bit (RV32I) RISC-V CPU core implemented in Verilog. It is integrated into a System-on-a-Chip (SoC) with data RAM, instruction ROM, and a memory-mapped UART for external communication.

This project is intended for simulation and as a learning tool for computer architecture.

## 🚀 Core Features

* **RISC-V Core (`top_riscv.v`):** A single-cycle RV32I processor that implements:
    * R-type instructions (ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND)
    * I-type instructions (ADDI, SLLI, SLTI, SLTIU, XORI, SRLI, SRAI, ORI, ANDI, LW, JALR)
    * S-type instructions (SW)
    * B-type instructions (BEQ, BNE, BLT, BGE, BLTU, BGEU)
    * U-type instructions (LUI, AUIPC)
    * J-type instructions (JAL)
* **UART Peripheral (`uart_top.v`):** A full UART transmitter and receiver with a 16-byte FIFO buffer for received data.
* **SoC (`soc.v`):** The top-level module that connects the CPU, RAM, and UART using memory-mapped I/O.
* **Memory:**
    * `instruction_memory.v`: A 1KB ROM, pre-loaded with a test program.
    * `data_memory.v`: A 32-word (128-byte) RAM for the CPU to read and write.

## 🗺️ Memory Map

The CPU interacts with its peripherals by reading from and writing to specific addresses.

| Address | R/W | Description |
| --- | --- | --- |
| `0x00000000` - `0x0000007C` | R/W | 32-word Data RAM |
| `0x10000000` | R/W | **UART Data Register** <br> **Write:** Sends a byte to the TX FIFO. <br> **Read:** Reads a byte from the RX FIFO. |
| `0x10000004` | R | **UART Status Register** <br> `bit 0`: `rx_ready` (1 = byte waiting in FIFO). <br> `bit 1`: `tx_busy` (1 = UART is currently sending). |

## 📁 Key Modules

* `soc.v`: Top-level System-on-a-Chip.
* `top_riscv.v`: The complete RISC-V CPU.
    * `control_unit.v`: Decodes instructions and generates control signals.
    * `data_path.v`: Contains the ALU, registers, and multiplexers.
    * `alu.v`: The Arithmetic Logic Unit.
    * `register_file.v`: The 32 CPU registers (x0-x31).
* `uart_top.v`: The complete UART peripheral.
    * `uart_tx.v`: Transmit FSM.
    * `uart_rx.v`: Receive FSM.
    * `FIFO_buffer.v`: 16-byte storage for received data.
    * `baud_gen.v`: Generates the UART clock ticks.
* `data_memory.v`: The CPU's RAM.
* `instruction_memory.v`: The CPU's ROM with the hard-coded program.
