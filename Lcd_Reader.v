module Lcd_Reader (
input clk, rst,RxD_data_ready,
input [7:0]RxD_data,
output reg LCD_RS, LCD_E, RDY, kappa,
output LCD_RW,
output reg [7:0] LCD_DB
);
///////////////CLOCKING UNIT///////////////////


//Define the Timing Parameters my
parameter [19:0] t_500ns 	= 25;		//500ns 		== ~25clks 
parameter [19:0] t_2000us 	= 100_000;		//2ms 	== ~100000clks
parameter [19:0] t_100us 	= 5000;		//42us 		== ~1008clks
parameter [19:0] t_2us 	= 100;		//2us		== ~100clks



reg [19:0] cnt_timer=0; 			//39360 clks, used to delay the STATEmachine during a command execution (SEE above command set)
reg flag_500ns=0, flag_2000us=0, flag_2us=0;
reg flag_rst=1;					//Start with flag RST set. so that the counting has not started

always @(posedge clk) begin
	if(flag_rst) begin
		flag_500ns	<=	1'b0;		//Unlatch the flag OK      E PULSES WIDTH
	 		        
		flag_2000us	<=	1'b0;		//Unlatch the flag OK	     COMMANDS DELAY
		flag_2us	   <=	1'b0;	      //Unlatch the flag OK       TESTING PURPOSE DELAY
		cnt_timer	<=	20'b0;		
	end
	else begin
	   cnt_timer	<= cnt_timer + 1;
		if(cnt_timer>=t_500ns) begin			
			flag_500ns	<=	1'b1;
		end
		else begin			
			flag_500ns	<=	flag_500ns;
		end
		//----------------------------
		if(cnt_timer>=t_2000us) begin			
			flag_2000us	<=	1'b1;
		end
		else begin			
			flag_2000us	<=	flag_2000us;
		end
		//----------------------------
		if(cnt_timer>=t_2us) begin			//THIS IS FOR TEST PURPOSES NOT REALLY USED
			flag_2us		<=	1'b1;          //IN PROPER OPERATION
		end
		else begin			
			flag_2us		<=	flag_2us;
		end	
		//----------------------------
		
end
end

/////////END OF CLOCKING UNIT///////////////

//// LCD FSM ///////

localparam STATE_SIZE = 15; 
localparam RESET    = 1,
			  IDLE     = 2,
           INSTR    = 3, 
           SETUP    = 4,
           CURSOR   = 5,
			  CLEAR    = 6,
			  CRSRINC  = 7,
			  CRSRSTRT = 8,
			  WAIT_E   = 9,
			  WAIT_OP  = 10,
			  WRITE    = 11,
		WAIT_WRITE1   = 12,
	   WAIT_WRITE2   = 13,
			IDLE_FINAL = 14,
			  DECIDE	  = 15;	
			 		  
reg [2:0] instruction_register, text_reg;

reg [STATE_SIZE-1:0]State;

  
assign LCD_RW=1'b0;  //WE NEVER READ SO LCD_R/W IS STUCK TO 0 --- > WRITE

  
always @ (posedge clk) begin
	if(rst) begin
	   text_reg <= 3'b000;
	   kappa	   <=		1'b0;
	   RDY		<=     1'b0;	
		LCD_RS	<=		1'b1;										//DOUBLE RESET FOR TESTING PURPOSES
		LCD_E		<=		1'b0;										 
		LCD_DB 	<= 	8'b11111111;
		flag_rst <=     1'b1;
	   instruction_register<=3'b0;
		State <= RESET;
		end
	else begin
		case (State)
      RESET:begin
		         text_reg <= 3'b000;
		         kappa	   <=		1'b0;
		         RDY		<=     1'b0;	
					LCD_RS	<=		1'b0;											
					LCD_E		<=		1'b0;										
					LCD_DB 	<= 	   8'b00000000;
					flag_rst <=     1'b1;
					instruction_register<=3'b0;
					State    <=     IDLE;	
							
				end
		 IDLE:begin
		         if(RDY)State <=WRITE;           //IDLE STATE THAT DIRECTS TO INITILIAZATION OR WRITE PURPOSE
               else State <=INSTR;
					
						
	         end
	   INSTR:begin     //INSTRUCTION SEQUENCE HANDLING STATE
					LCD_RS <=		1'b0;
					case (instruction_register)
					      0:begin
							  instruction_register<=instruction_register+1'b1;
							  State <=SETUP;
							  end
							1:begin
							  instruction_register<=instruction_register+1'b1;
							  State <=CURSOR;
							  end
							2:begin
							  instruction_register<=instruction_register+1'b1;
							  State <=CLEAR;
							  end
							3:begin
							  instruction_register<=instruction_register+1'b1;
							  State <=CRSRINC;
							  end
							4:begin
							  instruction_register<=instruction_register+1'b1;
							  State <=CRSRSTRT;
							  end
							5:begin
							  instruction_register<=3'b0;
							  RDY<=1'b1;
							  State  <= IDLE;
							  
							  end
					endcase		
				end		
      SETUP:begin
					LCD_DB <= 8'b0011_1100;
					State  <= WAIT_E;
				end
     CURSOR:begin
					LCD_DB <= 8'b0000_1111;
					State  <= WAIT_E;
				 end
		CLEAR:begin
					LCD_DB <= 8'b0000_0001;            //INSTRUCTION STATES USED FOR INITILLIZATION OF LCD
					State <= WAIT_E;
				end		 
	 CRSRINC:begin
					LCD_DB <= 8'b0000_0110;
					State <= WAIT_E;
				end
	CRSRSTRT:begin
					LCD_DB <= 8'b1000_0000;
					State <= WAIT_E;
				end 
     WAIT_E:begin
					LCD_E<=1'b1;
	            if(!flag_500ns)begin
											flag_rst<=1'b0;
											State <= WAIT_E;  //FIRST DELAY 500ns for keeping ENABLE HIGH for 500ns
										end 
					else begin					  
						  flag_rst<=1'b1;
						  State<=WAIT_OP;
						  end	
				end		  
     WAIT_OP:begin
					LCD_E<=1'b0;
	            if(!flag_2000us)begin
											flag_rst<=1'b0;
											State <= WAIT_OP; 
										end 
					else begin
									flag_rst<=1'b1;
									State <=INSTR;
								 end	
					end

//////////WRITE PORTION OF FSM//////////////////
   WRITE:begin
					LCD_RS <=		1'b1;
					if( RxD_data_ready) begin
                                    if(RxD_data == 8'b00001101) 					
												      State<=RESET;
												else begin
												      LCD_DB<=RxD_data;        //LCD CHECKS HANDSHAKE SIGNAL RxD_data_ready TO 
														State<=WAIT_WRITE1; 	    // TO REPORT READY INPUT FROM KEYBOARD 
													  end                       //IF THE KEYBOARD INPUT IS ENTER WE GO BACK TO RESET  
                                       									 //ELSE WE GO WRITE ON LCD			
											  end		
					else begin
						LCD_DB<=LCD_DB;
						State<=WRITE;
						end

			end	
	//WRITE DELAYS SAME AS ABOVE BUT DIFFERENT FLAG IS USED FOR SECOND DELAY			
	WAIT_WRITE1:begin
					LCD_E<=1'b1;
	            if(!flag_500ns)begin
											flag_rst<=1'b0;
											State <= WAIT_WRITE1; 
										end 
					else begin					  
						  flag_rst<=1'b1;
						  State<=WAIT_WRITE2;
						  end	
				end		  
     WAIT_WRITE2:begin
                 LCD_RS<=1'b0;	  
					  LCD_E<=1'b0;
	              if(!flag_500ns)begin
											flag_rst<=1'b0;
											State <= WAIT_WRITE2; 
										end 
					else begin
									flag_rst<=1'b1;
									State <=WRITE;
								 end	
						  end	
	IDLE_FINAL:begin 
	            kappa<=1'b1;
					State<=IDLE_FINAL; //STATE FOR TESTING PURPOSES NOT USED IN PROPER OPERATION
				  end		
  	
			  
           	  
      default: begin State  <= IDLE; end
    endcase
  end
 end
endmodule			