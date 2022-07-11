/* Assignment 1
 * ------------
 * Digital System Design
 * TASK4
 * Three States S0,S1,S2 are Used in this Task.
 * S0 is Holding State, Each time after drawing, Control shift to Hold State.
 * S1 is Reset State, Whenever we move to this state it clear the screen by drawing black pixels on whole screen.
 * Each Time After holding drawn object for some time control will shift to Reset State to clear the screen.
 * Also in S1 state colour and center of object(Circle,Square or Diamond) is changed randomly by using LFSR.
 * S2 is Drawing State, In this state Bressnam Algorithm is implemented to draw circle with newly generated center and colour.
 * Each Time After Resetting, Control Will shift to Draw state to draw the selected object on the screen.
 * KEY[0] is Asynchronous reset of VGA Display.
 * SW[2] and SW[1] are both zero for Drawing Circle.
 * User Can Change SW[2:1] to 01 for drawing Diamond and 10 for drawing Square.
 * Selected Object will be draw almost instantanously if SW[0] is low.
 * IF User wants to see the selected object drawn slowly then SW[0] should be High. 
 */



module TASK4(CLOCK_50, SW,KEY , VGA_R, VGA_G, VGA_B,
				VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_CLK);
				
	/*****************************************************************************/
	/*               Inputs and Outputs are Declared Here                        */
	/*****************************************************************************/
	input CLOCK_50;
	input [2:0]SW; 
	input [0:0]KEY;
	output [7:0] VGA_R;
	output [7:0] VGA_G;
	output [7:0] VGA_B;
	output VGA_HS;
	output VGA_VS;
	output VGA_BLANK;
	output VGA_SYNC;
	output VGA_CLK;
	
	/*****************************************************************************/
	/*                  Local signals are declared  here                         */
	/*****************************************************************************/
	reg [5:0]r = 44;
	reg [7:0] x;
	reg [6:0] y;
	reg signed [9:0]d ;
	reg [5:0]xx,yy;
	reg [7:0]xcc = 10000000;
	reg [6:0]ycc = 1111111;
	reg [7:0]xc,xcen;
	reg [6:0]yc,ycen;
   reg [2:0]color = 010;
	reg [2:0]colour;
	reg [2:0]i;
	reg [1:0]State = 2'b00;
	reg [26:0]count = 0;
	reg plot;
	wire square = SW[2]&&~SW[1];
	wire diamond = ~SW[2]&&SW[1];
	wire draw_slow = SW[0];
	parameter S0 = 2'b00, S1 = 2'b01 , S2 = 2'b10;


   /*****************************************************************************/
	/*                   Mealley Machine                                         */
	/*****************************************************************************/	
	always @(posedge CLOCK_50)
	begin
	case (State)
	S0:  // waiting state
		if(count==10000000)
			State<=S1;
		
	
	S1:  // resetting state
		if(x==159&&y==119)
			State<=S2;
		
	
	S2:  // Drawing state
		if(xx>yy)
			State<=S0;
			
	endcase
	end

	/*****************************************************************************/
	/*                            Data Path                                      */
	/*****************************************************************************/
	always @(posedge CLOCK_50)
	begin
	case (State)
	S0:  // wait state
	
	begin
		 plot = 0;
		 count <= count + 1;
		 if(count == 100000)
		 begin
		 x <= 0;                         // set x,y and colour to 0 as we have to do reset
		 y <= 0;
		 colour <= 3'b000; 
		 end
	
		 
	end
	S1:
	begin 
		  plot = 1; 
		  x <= x + 1;
		  if(x==159)
		  begin
			  x <=0;
			  y <= y + 1;
			  if(y == 119)                 // random number for ycc,xcc and color using LFSR
			  begin
				  ycc[5:0] <= ycc[6:1];          
				  ycc[6] <= ycc[1] ^ ycc[0];
				  
				  xcc[6:0] <= xcc[7:1];
				  xcc[7] <= xcc[1] ^ xcc[0];
				  
				  color[1:0] <= color[2:1];
				  color[2] <= color[1] ^ color [0];
				  
				  colour <= color;
				  xx <=0;
				  i <= 0;
				  ycen <= yc;
				  xcen <= xc;
				  yy <= (r>59) ? 59 : r;
				  d <= 3 - 2*r;
				 
			  end
		  end
	end	  
	
	S2: 
	begin 
			if(draw_slow)
			begin
				count <= count + 1;
				if(count==1000000)              
					 i <= i+1;   
			end
			else
				 i <= i + 1;
			if(i==7)
			begin
				i<=0;
				xx <= xx + 1;
				
				if (d < 0 | !diamond)
				begin
					d <= d + (4 * xx) + 6;
				end
				else
				begin
					d <= d + 4*(xx - yy) + 10;
					yy <= (square)? yy:(yy - 1);
				end
			end
			case(i)
			0:  
			begin	x <= (xcen + xx); 
					y <= (ycen + yy);
			end
			1:   
			begin x <= (xcen - xx);
					y <= (ycen + yy);
			end
			2: 
			begin	x <= (xcen + xx);
					y <= (ycen - yy);
			end
			3:  
			begin	x <= (xcen - xx);
					y <= (ycen - yy);
			end
			4: 
			begin x <= (xcen + yy);
					y <= (ycen + xx);
			end
			5: 
			begin	x <= (xcen - yy);
					y <= (ycen + xx);
			end
			6:  
			begin	x <= (xcen + yy);
					y <= (ycen - xx);
			end
			7:  
			begin	x <= (xcen - yy);
					y <= (ycen - xx);
			end
			endcase
						
			if(xx>yy)
			count <=0;
	
	end   
	endcase
	end


	/*In this always block we check if center is outside the sucreen then change center to the mid point 
	 *of sucreen And also find the maximum possible radius for given center */
	always @(*)
	begin
		xc <= (xcc>159)? 80:xcc;
		yc <= (ycc>119)? 60:ycc;
	
	  
	  if (yc<(119-yc))
	  begin
		  if(xc<(159-xc))
		  begin
			  r <= (xc<yc)? xc:yc;
		  end
		  else
		  begin
			  r <=((159 - xc) < yc)? (159 - xc):yc;
		  end
	  
	  end
	  else
	  begin
		  if(xc<(159-xc))
		  begin
			  r <= (xc < (119-yc)? xc:(119-yc));
		  end
		  else
		  begin
			  r <= ((159 - xc) < (119-yc))? (159 - xc):(119-yc);
		  end
	  end
	
	end


	/*****************************************************************************/
	/* Instance of modules for the VGA adapter Core.                             */
	/*****************************************************************************/	

	vga_adapter VGA(
			.resetn(KEY[0]),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(plot),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
			
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "image.colour.mif";
		defparam VGA.USING_DE1 = "TRUE";
		
endmodule
