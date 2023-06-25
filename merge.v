module inp( activity_counter,clk, b0, b1, activity, x_buff,y_buff);

input clk, b0, b1, activity;
input [1:0] activity_counter;
output reg [3:0] x_buff;
output reg [3:0] y_buff;
reg [3:0] count;


// input and Y counters for button debouncing
integer b0_counter, b1_counter, y_counter;
always @(posedge clk) begin
	if (b0 == 0 && b0_counter < 'd3) begin
			b0_counter <= b0_counter + 'd1;
	end else if (b0 == 1) begin
			b0_counter <= 0;
	end
	
	if (b1 == 0 && b1_counter < 'd3) begin
			b1_counter <= b1_counter + 'd1;
	end else if (b1 == 1) begin
			b1_counter <= 0;
	end
	
		
	if (y == 0 && y_counter < 'd3 ) begin
		y_counter <= y_counter + 'd1;
	end else if (y == 1) begin
		y_counter <= 'd0;
	end	
end

//serial input
wire y;
assign y = ((b0_counter==2)|(b1_counter==2));

always @(posedge clk) // 
	begin
	if (y) begin
	if(count<4)  //take first 4 inputs in Y
		if(b0_counter==2)  
		x_buff <= {1'b0,x_buff[3:1]};
		else if(b1_counter==2)
		x_buff <= {1'b1,x_buff[3:1]};
	if(4<=count && count<8)			//after 4 inputs take them in X
		if(b0_counter==2)
		y_buff <= {1'b0,y_buff[3:1]};
		else if(b1_counter==2)
		y_buff <= {1'b1,y_buff[3:1]};
	count <= count+1'b1;


	if(count==8) begin
			count <= 3'b000;

								end
				end
	end 
endmodule
	

// module game(clk, lgc0, lgc1, activity, out_coord, out_delete, out_winscore);

module game_logic(activity_counterr,clk, pos_x, pos_y, activity, out_arr,tr_mov_count,cr_mov_count,tr_win_count,cr_win_count,tr_recent,cr_recent,delete,last_turn);
    input clk;
	 input activity;
	 input [3:0] pos_x;
	 input [3:0] pos_y;
	 output reg [7:0] out_arr; //x-coordinates first 4, last 4 y coord
	 //output reg [1:0] delete;  out will deleted
	 //reg [3:0] tr_count; 6da sil 1, 12de 2
	 //reg [3:0] cr_count; 6da sil 1, 12de 2
	 reg [2:0] mat_val [0:9][0:9] ; // [2:0] - [tr,cr,filled]
	 output reg last_turn;
	 output reg [1:0] activity_counterr; 
//state variables
parameter triangle_turn = 'd0;
parameter circle_turn = 'd1;
parameter idle = 'd2;
parameter win_tour = 'd3;
parameter final = 'd4;

reg [2:0] state ;

initial begin
	tr_mov_count=4'b0000;
	cr_mov_count=4'b0000;
	tr_win_count=2'b00;
	cr_win_count=2'b00;
 	tr_recent=8'b00000000;
   cr_recent=8'b00000000;
  delete='b0;

	for(i=0;i<10;i=i+1)
		for(j=0;j<10;j=j+1)
		mat_val[i][j] <= 3'b000;
		
    state = triangle_turn;
	 last_turn= 1'b0; //last turn 0 indicates triangle played last
	 activity_counter=0;

end
// activity counter for button debouncing
integer activity_counter;
always @(posedge clk) begin

	if (activity == 0 && activity_counter < 'd3 ) begin
		activity_counter <= activity_counter + 'd1;
	end else if (activity == 1) begin
		activity_counter <= 'd0;
	end	
end





//winning algorithm variables
reg [3:0] h_catch,h_empty;  //'empty' variables are msb of poscheck array, 0 if empty
reg [3:0] v_catch,v_empty;
reg [3:0] dnex_catch,dnex_empty;
reg [3:0] dprev_catch,dprev_empty;
//if triangle win make it 1
reg triangle_win;
reg circle_win;
reg [4:0] movement_count;

output reg [1:0] tr_win_count;
output reg [1:0] cr_win_count;

output reg [3:0] tr_mov_count;
output reg [3:0] cr_mov_count;

output reg [8:0] delete;//delete[7:0](x-y coordinates of point that will be deleted) EXAMPLE:{0,delete[7:0]}->dont delete ** {0,delete[7:0]}->will be deleted **
output reg [7:0] tr_recent;
output reg [7:0] cr_recent;

reg [7:0] tr_first_mov;
reg [7:0] tr_second_mov;
reg [7:0] cr_first_mov;
reg [7:0] cr_second_mov;
integer i,j;


// state machine
always @(posedge clk) begin

    case (state)
	 idle:begin //make the matris zero
					
	 for(i=0;i<10;i=i+1)
		for(j=0;j<10;j=j+1)
		mat_val[i][j] <= 3'b000;
	 
	 
	 
	 state<=(last_turn=='b0) ? triangle_turn : circle_turn;
	 
	 end
	
	
    triangle_turn :  begin //give coordinates as output to vga module in here
	 if (activity_counter == 2) begin
		  if (mat_val [pos_x][pos_y] [0] == 'b1 || pos_x>4'b1001 || pos_y>4'b1001) state <= triangle_turn;
		  
		  else if (mat_val [pos_x][pos_y] [0] == 'b0 && pos_x<4'b1010 && pos_y<4'b1010) begin
		  mat_val [pos_x][pos_y] [0] <= 'b1; // filled 
		  mat_val [pos_x][pos_y] [2] <= 'b1; // only triangle,for score check
		  out_arr<={pos_x,pos_y}; //out to vga
		  tr_recent<= {pos_x,pos_y}; // triangle last movement
		  tr_mov_count<= tr_mov_count+1;
		  last_turn<=~last_turn;
		  state<= win_tour;
																		end
		 if (tr_mov_count == 0) tr_first_mov<= {pos_x,pos_y};
		 if (tr_mov_count == 1) tr_second_mov<= {pos_x,pos_y};
											end		 
								

							end 


    circle_turn : begin  //give coordinates as output to vga module in here
	 if (activity_counter == 2) begin
		  if (mat_val [pos_x][pos_y] [0] == 'b1 || pos_x>4'b1001 || pos_y>4'b1001) state <= circle_turn;
		  
		  else if (mat_val [pos_x][pos_y] [0] == 'b0 && pos_x<4'b1010 && pos_y<4'b1010) 	begin
		  mat_val [pos_x][pos_y] [0] <= 'b1;
		  mat_val [pos_x][pos_y] [1] <= 'b1; // only circle, for score check
		  out_arr<={pos_x,pos_y}; //out to vga
		  cr_recent<= {pos_x,pos_y};
		  cr_mov_count<= tr_mov_count+1;
		  last_turn<=~last_turn;
		  state<=win_tour;
		  
																		end

		 if (cr_mov_count == 0) cr_first_mov<= {pos_x,pos_y};
		 if (cr_mov_count == 1) cr_second_mov<= {pos_x,pos_y};
										end

						end

    win_tour : //give win counts and total movements as output to vga module in here
begin

for(i=0;i<7;i=i+1)begin
	for(j=0;j<7;j=j+1) begin
	
	h_catch={mat_val[i][j][1],mat_val[i][j+1][1],mat_val[i][j+2][1],mat_val[i][j+3][1]};
	h_empty={mat_val[i][j][2],mat_val[i][j+1][2],mat_val[i][j+2][2],mat_val[i][j+3][2]};
	
	v_catch={mat_val[i][j][1],mat_val[i+1][j][1],mat_val[i+2][j][1],mat_val[i+3][j][1]};
	v_empty={mat_val[i][j][2],mat_val[i+1][j][2],mat_val[i+2][j][2],mat_val[i+3][j][2]};
	
	dnex_catch={mat_val[i][j][1],mat_val[i+1][j+1][1],mat_val[i+2][j+2][1],mat_val[i+3][j+3][1]};
	dnex_empty={mat_val[i][j][2],mat_val[i+1][j+1][2],mat_val[i+2][j+2][2],mat_val[i+3][j+3][2]};
	
	dprev_catch={mat_val[i+3][j][1],mat_val[i+2][j+1][1],mat_val[i+1][j+2][1],mat_val[i][j+3][1]};
	dprev_empty={mat_val[i+3][j][2],mat_val[i+2][j+1][2],mat_val[i+1][j+2][2],mat_val[i][j+3][2]};
	end
	end
triangle_win <= ((&h_empty)&(~|h_catch))|((&v_empty)&(~|v_catch))|((&dnex_empty)&(~|dnex_catch))|((&dprev_empty)&(~|dprev_catch));
circle_win <= ((&h_empty)&(&h_catch))|((&v_empty)&(&v_catch))|((&dnex_empty)&(&dnex_catch))|((&dprev_empty)&(&dprev_catch));


movement_count<=movement_count +1 ;

if (triangle_win) begin
tr_win_count<= tr_win_count +1;
end

else if (circle_win) begin
cr_win_count<= cr_win_count + 1;
end

state<=final;
//(last_turn=='b0) ? triangle_turn : circle_turn;
end

    final : 
begin

	triangle_win<=0;
	circle_win<=0;
	
	if (tr_mov_count==6) begin
	delete <= (tr_mov_count==6) ? {1'b1,tr_first_mov} : {1'b0,tr_first_mov} ;
	state <= (last_turn=='b0) ? triangle_turn : circle_turn;
								end
								
	else if (tr_mov_count==12) begin						
	delete <= (tr_mov_count==12) ? {1'b1,tr_second_mov} : {1'b0,tr_second_mov} ;
	state <= (last_turn=='b0) ? triangle_turn : circle_turn;
										end
	if (cr_mov_count==6)begin
	delete <= (cr_mov_count==6) ? {1'b1,cr_first_mov} : {1'b0,cr_first_mov} ;	
	state <= (last_turn=='b0) ? triangle_turn : circle_turn;
								end
								
	else if (cr_mov_count==12) begin						
	delete <= (cr_mov_count==12) ? {1'b1,tr_second_mov} : {1'b0,tr_second_mov} ;
	state <= (last_turn=='b0) ? triangle_turn : circle_turn;
										end								
					
	else 	state <= (last_turn=='b0) ? triangle_turn : circle_turn;						
//	if (movement_count==25) begin
//	state <= idle;          end

//	wiping board(might be initial state where board is 0 and turn to that)
	
																		
end

    endcase

end

endmodule



module merge(clk, b0,b1,activity,out_arr,CLOCK_50, VGA_VS, VGA_HS, VGA_CLK, VGA_R, VGA_G, VGA_B);
input clk,b0,b1,activity;
output [7:0] out_arr;


//VGA regs
input CLOCK_50;
//input[1:0] SW;
//input[3:0] KEY;
output VGA_HS, VGA_VS; 
output reg VGA_CLK;
output reg[7:0] VGA_R, VGA_G, VGA_B;


//VGA related wires
wire READY;
wire[9:0] POS_H, POS_V;
//wire[11:0] RGB;
wire[11:0] RGB;

//regs are not tested
reg [3:0] x_b;
reg [3:0] y_b;

wire [3:0] x_buff;
wire [3:0] y_buff;


initial begin
	VGA_CLK = 1'b0;
	VGA_R = 8'h00;
	VGA_G = 8'h00;
	VGA_B = 8'h00;
end
always @(posedge CLOCK_50) begin 
	VGA_CLK = ~VGA_CLK;
end

//button debouncer for activity_counter
/*always @(posedge clk) begin
	if (activity == 0 && activity_counter < 'd3 ) begin
		activity_counter <= activity_counter + 'd1;
	end else if (activity == 1) begin
		activity_counter <= 'd0;
	end	
end

always @(posedge clk)begin
 if (activity_counter==2)
	 x_b <= x_buff;
	 y_b <= y_buff;

end
// untill here is not tested
*/
// VGA Scync'i ellemene gerek yok.
wire [3:0] tr_mov_count, cr_mov_count;
wire [1:0] tr_win_count, cr_win_count;
wire [7:0] tr_recent, cr_recent;
wire [8:0] delete;
wire last_turn;
VGA_Sync SYNC(.vga_CLK(VGA_CLK), .vga_VS(VGA_VS), .vga_HS(VGA_HS), .vga_Ready(READY), .pos_H(POS_H), .pos_V(POS_V));

wire [1:0] activity_counter;

//Interface IMAGE(.vga_CLK(VGA_CLK), .ready(READY), .pos_H(POS_H), .pos_V(POS_V), .RGB(RGB), .POS_SYMBOL(out_arr),.TURN(state),.tr_mov_count(tr_mov_count),.cr_mov_count(cr_mov_count),.tr_win_count(tr_win_count),.cr_win_count(cr_win_count),.tr_recent(tr_recent),.cr_recent(cr_recent),.delete(delete),.last_turn(last_turn));
interface_new IMAGE(.vga_CLK(VGA_CLK), .ready(READY), .pos_H(POS_H), .pos_V(POS_V), .RGB(RGB), .POS_SYMBOL(out_arr),.TURN(state),.tr_mov_count(tr_mov_count),.cr_mov_count(cr_mov_count),.tr_win_count(tr_win_count),.cr_win_count(cr_win_count),.tr_recent(tr_recent),.cr_recent(cr_recent),.delete(delete),.last_turn(last_turn));

inp dut(.activity_counter(activity_counter),.clk(clk), .b0(b0), .b1(b1), .activity(activity), .x_buff(x_buff),.y_buff(y_buff));
game_logic dut2(.activity_counterr(activity_counter),.clk(clk), .pos_x(x_buff), .pos_y(y_buff), .activity(activity), .out_arr(out_arr),.tr_mov_count(tr_mov_count),.cr_mov_count(cr_mov_count),.tr_win_count(tr_win_count),.cr_win_count(cr_win_count),.tr_recent(tr_recent),.cr_recent(cr_recent),.delete(delete),.last_turn(last_turn));




always @(posedge VGA_CLK) begin
	if(READY) begin
		VGA_R[3:0] <= 4'hF;  
		VGA_G[3:0] <= 4'hF;
		VGA_B[3:0] <= 4'hF;
			
		VGA_R[7:4] <= RGB[11:8];  
		VGA_G[7:4] <= RGB[7:4];
		VGA_B[7:4] <= RGB[3:0];
		
	end
	else begin
		VGA_R <= 8'h00;
		VGA_G <= 8'h00;
		VGA_B <= 8'h00;	
	end
end

endmodule

	
