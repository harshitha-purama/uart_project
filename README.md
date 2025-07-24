# UART Project with FIFO, Runtime Configuration, and Robust Simulation

## Overview

This project implements a **UART (Universal Asynchronous Receiver/Transmitter)** communication interface using Verilog, designed and tested fully in simulation. It includes:

- A **baud rate generator** to create timing pulses for UART bits.
- A **FIFO buffer** for both transmitter (TX) and receiver (RX) paths to smooth data flow.
- A **configurable runtime register block** to set UART parameters like baud rate, parity, and stop bits dynamically.
- Clean, modular **UART transmitter and receiver** modules, parameterized for data bits, parity, and stop bits.
- A **loopback testbench** that sends data through UART and verifies received data correctness with automated checking.
- Waveform output for detailed visualization in GTKWave.

## Concepts and Highlights Learned

- **Serial Communication Protocol:** Understanding start bits, data bits (LSB first), optional parity, and stop bits fundamentals.
- **Clock Domain and Timing:** Carefully generating baud rate ticks from a fast system clock and sampling bits at correct intervals.
- **Finite State Machines (FSM):** Designing transmitter and receiver FSMs to handle serial data streams.
- **Mid-bit Sampling:** Implementing mid-bit sampling on RX side to ensure reliable reception.
- **FIFO Buffers:** Creating and interfacing FIFOs to handle asynchronous data buffering and flow control.
- **SystemVerilog to Verilog Conversion:** Adapting or avoiding SystemVerilog features for wider tool compatibility (Icarus Verilog).
- **Simulation and Verification:** Writing testbenches with loopback, delays, runtime configurability, and automated checking.
- **Signal Visualization:** Using GTKWave extensively to debug protocol timing and data correctness.
- **Git & Version Control:** Managing code versions, multiple remotes, and organizing project folders for clean repository structure.

## Challenges and Where We Got Stuck

- **Bit Sampling Timing:**  
  Initially, data reception was unreliable with many corrupted bytes even though no framing or parity errors were flagged.  
  I realized the UART RX sampling was done at the wrong timing (start of bit period rather than mid-bit), causing intermittent misalignment and bit errors.

- **Fix:**  
  Implemented mid-bit sampling by waiting half a baud period after detecting the start bit before sampling data bits. This crucial fix made reception accurate and stable.
  i am stuck here as the error was still there, and as i leanr more about timing analysis and verilog i hope soon i will find solution to fix this ( hope so ;( ) 

- **Toolchain Issues:**  
  Using Icarus Verilog meant older Verilog-2001 compatibility constraints. I adapted SystemVerilog constructs and typedefs to classic Verilog to avoid compiler errors.

- **FIFO Interfacing:**  
  Designing and connecting FIFO buffers for smooth data flow was non-trivial, requiring careful control of write/read enable signals to avoid overflow or data loss.

- **GitHub Setup:**  
  Managing multiple remote repositories and pushing only specific project folders was confusing at times, but ultimately resolved by using separate repos and remote names.

## How to Use This Project

1. **Simulation:**  
   Compile all Verilog files with Icarus Verilog and run the testbench to simulate UART data transmission and reception.

2. **Waveform Analysis:**  
   Open the generated `.vcd` file in GTKWave to inspect clocks, UART line signals, FIFO status, and FSM states.

3. **Configuration:**  
   Change UART parameters at runtime via configuration registers in testbench (baud rate, parity, stop bits).

4. **Extend and Customize:**  
   Add flow control, higher data widths, protocol enhancements based on your needs.

## Final Thoughts

Working through this project strengthened our understanding of UART communication and FPGA/ASIC design challenges — especially timing and verification nuances.

Persistence in debugging, methodical simulation, and toolchain adjustments were key to success.

This experience builds a solid foundation for further digital communication projects and hardware design verification.

---

**Feel free to explore the code, experiment with waveform timings, and extend the functionality!**

Happy coding! 🚀
