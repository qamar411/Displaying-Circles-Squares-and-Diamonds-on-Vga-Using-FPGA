/* Assignment 1
 * ------------
 * Digital System Design
 * TASK2
 * Two States S0,S1 are Used in this Task.
 * S0 is Holding State, Each time after filling screen, Control shift to Hold State.
 * S1 is Screen filling State, in this state screen will be filled either with black pixels or with coloured pixels.
 * Pressing KEY[0] will clear the screen by plotting black pixels on the screen.
 * After Resetting Control Signal Reset_done goes high indicating screen is currently cleared.
 * Releasing KEY[0] will fill the screen. Each row will be set to a different colour (repeating every 8 rows).
 * After Filling the screen with different colours Reset_done signal goes low indicating screen is not currently cleared.
 * If User press KEY[0] while reset_done signal is High then control will not jump to S1 state since screen is already 
 * cleared as indicated by reset_done signal.
 * KEY[1] is Asynchronous reset of VGA Display.
 * When SW[0] is low then screen will be filled and cleared instantanously.
 * If user wants to see plotting of pixels slowly then SW[0] should be High. 
 */
module vga_demo(CLOCK_50, KEY, SW, VGA_R, VGA_G, VGA_B,
				VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_CLK);
				
	/*****************************************************************************/
	/*                     Inputs and outputs are declared Here                  */
	/*****************************************************************************/			
	input CLOCK_50;	
	input [3:3] KEY;
	input [0:0] SW;
	output [7:0] VGA_R;
	output [7:0] VGA_G;
	output [7:0] VGA_B;
	output VGA_HS;
	output VGA_VS;
	output VGA_BLANK;
	output VGA_SYNC;
	output VGA_CLK;
	
	/*****************************************************************************/
	/*                     Local Variables are declared Here                     */
	/*****************************************************************************/
	wire resetn = KEY[3];
	wire draw_slow = SW[0];
	reg [23:0] count = 0;
	reg reset_done = 0;
	reg [7:0] x = 0;
	reg [6:0] y = 0;
	reg State = 0;
   parameter S0 = 1'b0, S1 = 1'b1;
	
	
   /*****************************************************************************/
	/*                              Mealy FSM                                    */
	/*****************************************************************************/
always @(posedge CLOCK_50)
begin
case (State)
	S0:  //idle state
	begin
		
			if(resetn ~^ reset_done)   
				 State <= S1;
			else    
				 State <= S0;    // stay idle
	end
	S1:  // resetting or screen filling state
	begin
	     if(x==159&&y==119)   
				 State <= S0;
			else    
				 State <= S1;    // stay idle
	end 
endcase
end


   /*****************************************************************************/
	/*                              Data Path                                    */
	/*****************************************************************************/
always @(posedge CLOCK_50)
begin
case (State)

	S0:  // idl state
		begin
			x <= 0;
			y <= 0;
			count <= 0;
		end	  
	S1: // screen filling state
		begin
		   if(draw_slow)
			begin
			  count <= count + 1;
			  if(count == 1000000)
			  begin
			      count <= 0;
			      x<= x + 1;
			  end
			end
			else
			begin
			   x <= x + 1;
			end
			if(x==159)
			begin
				 x <=0;
				 y <= y + 1;
				 if(y==119 && !resetn)
				      reset_done = 1;
				 else
				      reset_done = 0;
			end
		end	
		
endcase
end


   /*****************************************************************************/
	/*                          Instance of VGA_adapter Core                     */
	/*****************************************************************************/
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour((resetn)?(y%8):0), 
			.x(x),
			.y(y),
			.plot((State == 1)?1:0),      // plot pixel only in S1 (screen filling) state
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK),
			.VGA_SYNC(VGA_SYNC),
			.VGA_CLK(VGA_CLK));
			
			
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "image.colour.mif";
		defparam VGA.USING_DE1 = "TRUE";
		
endmodule

