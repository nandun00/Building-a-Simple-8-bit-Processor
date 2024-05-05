/* Lab 5 : Part 4 Flow Control Instructions - ALU
   Group 27
*/


//////////////////////////       ALU          /////////////////////////////////////////////////////////////////
module alu(DATAIN1, DATAIN2, RESULT, SELECT, ZERO);

    //port declaration
    // inputs
    input [7 : 0] DATAIN1, DATAIN2;
    input [2 : 0] SELECT;
    // outputs
    output reg [7 : 0] RESULT;  
    wire [7 : 0] FWD_OUT, ADD_OUT, AND_OUT, OR_OUT; //get outputs from the function modules
    output reg ZERO;

    //instantiate function modules
    FORWARD fwd(DATAIN2, FWD_OUT);
    ADD add(DATAIN1, DATAIN2, ADD_OUT);
    AND And(DATAIN1, DATAIN2, AND_OUT);
    OR Or(DATAIN1, DATAIN2, OR_OUT);

     always@(ADD_OUT) begin
       if(ADD_OUT == 0) ZERO = 1; //set ZERO signal to high if answer of subrtraction is ZERO
      else ZERO = 0; // otherwise set it to low
     end

     //selecting the relevant output result according to the SELECT input
    always @(DATAIN1,DATAIN2,SELECT)
    begin
        case (SELECT)
            3'b000 : assign RESULT = FWD_OUT;   //SELECT 000 -> FORWARD
            3'b001 : assign RESULT = ADD_OUT;  //SELECT 001 -> ADD
            3'b010 : assign RESULT = AND_OUT;  //SELECT 010 -> AND
            3'b011 : assign RESULT = OR_OUT;   //SELECT 011 -> OR
            default: assign RESULT = 8'd0;        
        endcase
        
    end

endmodule

// FORWARD module - for loadi, mov instructions
module FORWARD(DATAIN2, FWD_OUT);

    // port declaration
    input [7 : 0] DATAIN2;
    output [7 : 0] FWD_OUT;

    assign #1 FWD_OUT = DATAIN2; // wait for 1 time unit and assign value of DATAIN2 to FWD_OUT
endmodule


// ADD module - for add, sub instructions
module ADD(DATAIN1, DATAIN2, ADD_OUT);

    // port declaration
    input [7 : 0] DATAIN1;
    input [7 : 0] DATAIN2;
    output [7 : 0] ADD_OUT;

    assign #2 ADD_OUT = DATAIN1 + DATAIN2; // wait for 2 time unit and assign sum of DATAIN1 and DATAIN2 to ADD_OUT

endmodule

// AND module - for and instruction
module AND(DATAIN1, DATAIN2, AND_OUT);

    // port declaration
    input [7 : 0] DATAIN1;
    input [7 : 0] DATAIN2;
    output [7 : 0] AND_OUT;

    assign #1 AND_OUT = DATAIN1 & DATAIN2; // wait for 1 time unit and assign AND of DATAIN1 and DATAIN2 to AND_OUT

endmodule

// OR module - for or instruction
module OR(DATAIN1, DATAIN2, OR_OUT);

    // port declaration
    input [7 : 0] DATAIN1;
    input [7 : 0] DATAIN2;
    output [7 : 0] OR_OUT;

    assign #1 OR_OUT = DATAIN1 | DATAIN2; // wait for 1 time unit and assign OR of DATAIN1 and DATAIN2 to OR_OUT

endmodule
///////////////////////////////////////////////////////////////////////////////////////////////////