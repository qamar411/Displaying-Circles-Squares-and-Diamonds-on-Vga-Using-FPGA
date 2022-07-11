/* Assignment 1
 * ------------
 * Digital System Design
 * TASK3 
 * Three States S0,S1,S2 are Used in this task.
 * S0 is Idle State, Each time after resetting or drawing, Control shift to idle State.
 * S1 is Reset State, Whenever we move to this state it clear the sucreen by drawing black pixels on whole screen.
 * S2 is Drawing State, In this state I used the Bressnam Algorithm to draw circle.
 * Radius and colour of this circle are controlled by the user through SW[7:3] and SW[2:0].
 * SW[9] and SW[8] are both zero for Drawing Circle.
 * User Can Change SW[9:8] to 01 for drawing Diamond and 10 for drawing Square.
 * Pressing KEY[0] draw the circle.
 * Pressing KEy[3] will reset the sucreen to black.
 * Pressing and Holding KEY[1] will draw pixels slowly when KEY[0] is pressed.
 * Note that Whenever User release KEY[1] the Drawing mode will change from slow to fast. 
 * And selected object will be drawn almost instantaneously.
 * So if User Wants to Draw the object slowly on the screen then he should Press KEY[1] and then press KEY[0] and hold KEY[1] while cicle is being drawn slowly. 
 */

module TASK3(CLOCK_50, SW,KEY, VGA_R, VGA_G, VGA_B,
				VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_CLK);
	
	
		
	/*****************************************************************************/
	/*               Inputs and Outputs are Declared Here                        */
	/*****************************************************************************/
	input CLOCK_50;         // 50 MHz Clock
	input [9:0]SW; 	
	input [3:0]KEY;       
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
	wire resetn = KEY[3];
	wire draw = KEY[0];
	wire [4:0]r = SW[7:3];
	wire square = SW[9]&&~SW[8];
	wire diamond = ~SW[9]&&SW[8];
	wire draw_slow = !KEY[1];
	reg [7:0] x;
	reg [6:0] y;
	reg signed [9:0]d ;
	reg [5:0]xx,yy;
	reg [7:0]xcen = 80;
	reg [6:0]ycen = 60;
	reg [2:0]colour;
	reg [2:0]i;
	reg [1:0]State = 2'b00;
	reg plot;
	reg [25:0]count = 0;
	parameter S0 = 2'b00, S1 = 2'b01 , S2 = 2'b10;	
	
	
	/*****************************************************************************/
	/*                   Mealley Machine                                         */
	/*****************************************************************************/
	always @(posedge CLOCK_50)
	begin
		if(!resetn)
			 State <= S1;
		else
		begin
			case (State)
			S0:    // Idle state
			
				if(!draw)
					 State <= S2;
				else
					 State <= S0;	
			
			S1:  // Resetting state
			
				if(y==119&&x==159)
					State<=S0;	
			
			S2:  // Drawing state
			    if(xx > yy)
					State<=S0;
	           else 
		          State <= S2;		  
			endcase
		end
	end
	
	
	/*****************************************************************************/
	/*                            Data Path                                      */
	/*****************************************************************************/
	always @(posedge CLOCK_50)
	begin
	case (State)
	S0:  // idle state
	
	begin
		 // initializing all the variables in the idle state
		 plot <= 0;                // We don't want to draw pixel in the idle state  
		 x <= 0;                 
		 y <= 0;
		 xx <=0;
		 i <= 0;
		 yy <= (2*r>59) ? 59 : 2*r;
		 d <= 3 - 4*r;
		 colour <= 0; 
	end
	S1:
	begin 
		  plot <= 1;             // plot is 1 and colour is 0 to draw black pixels on whole screen
		  colour <= 3'b000;  
		  x <= x + 1;
		  if(x==159)
		  begin
			  x <=0;
			  y <= y + 1;
		  end
	end	  
	
	S2: 
	begin
			plot <= 1;            
			colour = SW[2:0];     // In Drawing state colour is controlled by the user
			count = count + 1;    // using counter to draw pixel slowly when draw_slow(!KEY[1]) is high
			if(draw_slow)
			begin
				if(count==1000000)      // delay of 0.02 second between each pixel is draw slow is high
				begin
				count <= 0;
				i <= i + 1;
				end
			end
			else
			begin
				 i <= i + 1;          // IF draw slow is low then draw pixel on each posedge of 50MHz clock
			end
			
			if(i==7)
			begin
				i<=0;
				xx <= xx + 1;
				
				if (d < 0 && !diamond)  // For Square and Circle if d<0 then add [4*(xx-yy)+6] to d. For diamond jump to else block
				begin
					d <= d + (4 * xx) + 6;
				end
				else
				begin
					d <= d + 4*(xx - yy) + 10;
					yy <= (square)?yy:(yy-1); // IF want to draw square then donot change y otherwise subtract one from y.
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
	
	end   
	endcase
	end
	
	/*****************************************************************************/
	/* Instance of modules for the VGA adapter Core.                             */
	/*****************************************************************************/
	
	vga_adapter VGA(
			.resetn(KEY[2]),
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
