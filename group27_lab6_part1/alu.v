/* Lab 5 : Part 4 Flow Control Instructions - ALU
   Group 27
*/


//////////////////////////       ALU          /////////////////////////////////////////////////////////////////
module alu(DATAIN1, DATAIN2, RESULT, SELECT, ZERO, SHIFT_SEL);

    //port declaration
    // inputs
    input [7 : 0] DATAIN1, DATAIN2;
    input [2 : 0] SELECT;
    input [1:0] SHIFT_SEL;
    // outputs
    output reg signed[7 : 0] RESULT;  
    wire [7 : 0] FWD_OUT, ADD_OUT, AND_OUT, OR_OUT, SHIFT_OUT, MULTI_OUT; //get outputs from the function modules
    output reg ZERO;

    //instantiate function modules
    FORWARD fwd(DATAIN2, FWD_OUT);
    ADD add(DATAIN1, DATAIN2, ADD_OUT);
    AND And(DATAIN1, DATAIN2, AND_OUT);
    OR Or(DATAIN1, DATAIN2, OR_OUT);
    SHIFT shift(DATAIN1, DATAIN2, SHIFT_OUT, SHIFT_SEL);
    MULTI mult(DATAIN1, DATAIN2, MULTI_OUT);

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
            3'b100 : assign RESULT = SHIFT_OUT; // SELECT 100 -> SHIFTED RESULT
            3'b101 : assign RESULT = MULTI_OUT; // SELECT 101 -> DATA1 x DATA2
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

//module for shifting
module SHIFT(DATA, SHIFT_AMOUNT, OUT, Shift_SEL);
    input [7:0]DATA, SHIFT_AMOUNT;
    output reg[7:0] OUT;
    input [1:0] Shift_SEL;

    always@(*) begin
        #1
        //logical right shift
        case(Shift_SEL)
        2'b00 : begin 
            case(SHIFT_AMOUNT)
            8'd0 : OUT = DATA;   
            8'd1 : OUT = {{1{1'b0}}, DATA[7:1]}; //append 0 to front and select necessary bits according to shift amount
            8'd2 : OUT = {{2{1'b0}}, DATA[7:2]};
            8'd3 : OUT = {{3{1'b0}}, DATA[7:3]};
            8'd4 : OUT = {{4{1'b0}}, DATA[7:4]};
            8'd5 : OUT = {{5{1'b0}}, DATA[7:5]};
            8'd6 : OUT = {{6{1'b0}}, DATA[7:6]};
            8'd7 : OUT = {{7{1'b0}}, DATA[7:7]};
            default : OUT = {7{1'b0}};  
            endcase
            end

        //logical left shift
        2'b01 : begin 
            
            case(SHIFT_AMOUNT)
            8'd0 : OUT = DATA;
            8'd1 : OUT = {DATA[6:0], {1{1'b0}}}; //append 0 to back and select necessary bits according to shift amount
            8'd2 : OUT = {DATA[5:0], {2{1'b0}}};
            8'd3 : OUT = {DATA[4:0], {3{1'b0}}};
            8'd4 : OUT = {DATA[3:0], {4{1'b0}}};
            8'd5 : OUT = {DATA[2:0], {5{1'b0}}};
            8'd6 : OUT = {DATA[1:0], {6{1'b0}}};
            8'd7 : OUT = {DATA[0:0], {7{1'b0}}};
            default : OUT = {7{1'b0}};  
            endcase
            end

        //arithmetic right shift
        2'b10 : begin 
            case(SHIFT_AMOUNT)
            8'd0 : OUT = DATA;
            8'd1 : OUT = {{1{DATA[7]}}, DATA[7:1]}; //append msb to front and select necessary bits according to shift amount
            8'd2 : OUT = {{2{DATA[7]}}, DATA[7:2]};
            8'd3 : OUT = {{3{DATA[7]}}, DATA[7:3]};
            8'd4 : OUT = {{4{DATA[7]}}, DATA[7:4]};
            8'd5 : OUT = {{5{DATA[7]}}, DATA[7:5]};
            8'd6 : OUT = {{6{DATA[7]}}, DATA[7:6]};
            8'd7 : OUT = {{7{DATA[7]}}, DATA[7:7]};
            default : OUT = {7{DATA[7]}}; 
            endcase
            end

        //rotate shift
        2'b11 : begin 
            case(SHIFT_AMOUNT%8)
            8'd0 : OUT = DATA;
            8'd1 : OUT = {DATA[0], DATA[7:1]}; //rotate necessary bits according to shift amount
            8'd2 : OUT = {DATA[1:0], DATA[7:2]};
            8'd3 : OUT = {DATA[2:0], DATA[7:3]};
            8'd4 : OUT = {DATA[3:0], DATA[7:4]};
            8'd5 : OUT = {DATA[4:0], DATA[7:5]};
            8'd6 : OUT = {DATA[5:0], DATA[7:6]};
            8'd7 : OUT = {DATA[6:0], DATA[7:7]};
            endcase
            end
        endcase
    end
endmodule

//module for multiply
module MULTI(DATA1, DATA2, OUT);
    input [7:0] DATA1, DATA2;
    output [7:0] OUT;
    wire [7:0] p0, p1, p2, p3, p4, p5, p6, p7;
    reg [7:0] pr;
    
  always @* begin
    pr = 8'd0;  //product is initially zero
                // check for each bit in the multiplier while right shifting. if the bit is 1 add the multiplicand to the 
                // the product. then left shift the multiplicand 
    
    if (DATA2[0] == 1) pr = pr + DATA1;
    if (DATA2[1] == 1) pr = pr + {DATA1[6:0], 1'b0};
    if (DATA2[2] == 1) pr = pr + {DATA1[5:0], 2'b00};
    if (DATA2[3] == 1) pr = pr + {DATA1[4:0], 3'b000};
    if (DATA2[4] == 1) pr = pr + {DATA1[4:0], 4'b0000};
    if (DATA2[5] == 1) pr = pr + {DATA1[2:0], 5'b00000};
    if (DATA2[6] == 1) pr = pr + {DATA1[1:0], 6'b000000};
    if (DATA2[7] == 1) pr = pr + {DATA1[0], 7'b0000000};
  end
    

       assign #2 OUT = pr;  //output of the product

endmodule
///////////////////////////////////////////////////////////////////////////////////////////////////

