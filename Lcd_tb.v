`timescale 1ns/1ns

module Lcd_tb;

   reg         rst,RxD_datardy =0;
   reg         [7:0]Rx_data = 8'b0;
   wire	       [7:0]LCD_Out;
   wire        LCD_rs, LCD_e,rdy,kappa,LCD_rw; 
  initial begin

     #100 rst = 1;
     #50  rst = 0;
     #100 rst = 1;
     #50  rst = 0;
     #100
     #10000000 Rx_data = 8'h33; RxD_datardy = 1; $display("RESET SEQUENCE IS OVER");
     #200 RxD_datardy = 0;
     #5000    Rx_data = 8'h23; RxD_datardy = 1;
     #200     RxD_datardy = 0;
     #5000    Rx_data = 8'h56; RxD_datardy = 1;
     #200     RxD_datardy = 0;
     #5000    Rx_data = 8'h0D; RxD_datardy = 1 ; $display("RESETING AGAIN WAIT FOR RESET SEQUENCE TO START OVER");
     #200     RxD_datardy = 0;
     #11000000


 $stop;
  end

  initial begin
    $dumpfile("gtk.vcd");
    $dumpvars(0,Lcd_tb);
 end
  /* Make a regular pulsing clock. */
  reg clk = 0;
  always #10 clk = !clk;



  Lcd_Reader lcd_UT(
	.clk                        (clk),
        .rst                        (rst),
        .RxD_data_ready             (RxD_datardy),
	.RxD_data 	            (Rx_data), 	
	.LCD_DB			    (LCD_Out),
	.LCD_RS                    (LCD_rs),
	.LCD_E			    (LCD_e),
        .RDY			    (rdy),
	.kappa			    (kappa),
        .LCD_RW			    (LCD_rw)	 	

);

  initial begin
     $monitor("At time %t, value = %h (%0d), reset = %2b, RDY=%2b, LCD_RS=%b, LCD_E=%b",
              $time, LCD_Out, LCD_Out,rst,rdy,LCD_rs, LCD_e);
  end
endmodule // test
