# LCD-16x2-Controller
A simple LCD 16x2 Controller with UART interface.

This is a Controller for classic LCD 16x2 with UART interface. The Uart interface has to output 8bit data and a Data Ready flag.
The Idea was to connect the keyboard to the COM port of the FPGA and write on the LCD with keyboard.
It was simulated with Verilator. (I can upload simulation)
It was tested on a Spartan 6 Mojo FPGA dev board and their UART core.
