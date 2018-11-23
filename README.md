# LCD-16x2-Controller
A simple LCD 16x2 Controller with UART interface.

This is a Controller for classic LCD 16x2. The twist is that is connected
with a UART interface so you can write whatever characters. The Uart interface has to output 8bit data and a Data Ready flag.
The Idea was to connect the keyboard to the COM port of the FPGA and write on the LCD with keyboard.
It was simulated with Verilator(I can upload simulation if there is interest).
It was tested on a Spartan 6 Mojo FPGA dev board and their UART core.
