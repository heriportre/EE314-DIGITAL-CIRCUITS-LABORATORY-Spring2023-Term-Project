module gamee(clk,bcd_in, out_mat);

    input clk;
    input [1:0][3:0] bcd_in; //coordinates bcd_in[0]=row(4bits), bcd_in[1]=column(4b)]
    output reg [2:0]out_mat[1:0][1:0] ;


initial begin

out_mat[0][0]=3'b000;
out_mat[0][1]=3'b000;
out_mat[1][0]=3'b000;
out_mat[1][1]=3'b000;



$display("matrix01: %0b",out_mat[0][1]);  

end

endmodule
