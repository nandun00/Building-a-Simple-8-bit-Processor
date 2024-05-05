/* Lab 5 : Part 1 ALU
   Group 27
*/

//testbench for the ALU module
module alu_TB;
    //port declaration
    // inputs
    reg [7 : 0] DATA1 , DATA2;
    reg [2 : 0] SELECT;
    // outputs
    wire [7 : 0] RESULT;
   
    // instantiate the alu module
    alu ALU(DATA1, DATA2, RESULT, SELECT);

    // initial block
    initial 
    begin
        
        DATA1 = 25;
        DATA2 = 50;
        //Test FORWARD function
        #2 SELECT = 3'b000; 
        // print the results every time when a value changes
        $monitor ($time ," SELECT = %b DATA1 = %d  DATA2 = %d  RESULT = %d",SELECT, DATA1, DATA2, RESULT); 

        //Test ADD function
        #2 SELECT = 3'b001;

        // default RESULT 
        #2 SELECT = 3'b100;

        #2;
        DATA1 = 15;
        DATA2 = 1;
        //Test AND function
        #2 SELECT = 3'b010; 
        
        //Test OR function
        #2 SELECT = 3'b011; 
        
        // default RESULT 
        #2 SELECT = 3'b100; 
        

    end
endmodule

//defining ALU module and port list

module alu(DATA1, DATA2, RESULT, SELECT);

    //port declaration
    // inputs
    input [7 : 0] DATA1, DATA2;
    input [2 : 0] SELECT;
    // outputs
    output reg [7 : 0] RESULT;  
    wire [7 : 0] FWD_OUT, ADD_OUT, AND_OUT, OR_OUT; //get outputs from the function modules

    //instantiate function modules
    FORWARD fwd(DATA2, FWD_OUT);
    ADD add(DATA1, DATA2, ADD_OUT);
    AND And(DATA1, DATA2, AND_OUT);
    OR Or(DATA1, DATA2, OR_OUT);

     //selecting the relevant output result according to the SELECT input
    always @(SELECT)
    begin
        case (SELECT)
            3'b000 : RESULT <= FWD_OUT;   //SELECT 000 -> FORWARD
            3'b001 : RESULT <= ADD_OUT;  //SELECT 001 -> ADD
            3'b010 : RESULT <= AND_OUT;  //SELECT 010 -> AND
            3'b011 : RESULT <= OR_OUT;   //SELECT 011 -> OR
            default: RESULT <= 0;        
        endcase
        
    end

endmodule

// FORWARD module - for loadi, mov instructions
module FORWARD(DATA2, FWD_OUT);

    // port declaration
    input [7 : 0] DATA2;
    output [7 : 0] FWD_OUT;

    assign #1 FWD_OUT = DATA2; // wait for 1 time unit and assign value of DATA2 to FWD_OUT
endmodule


// ADD module - for add, sub instructions
module ADD(DATA1, DATA2, ADD_OUT);

    // port declaration
    input [7 : 0] DATA1;
    input [7 : 0] DATA2;
    output [7 : 0] ADD_OUT;

    assign #2 ADD_OUT = DATA1 + DATA2; // wait for 2 time unit and assign sum of DATA1 and DATA2 to ADD_OUT

endmodule

// AND module - for and instruction
module AND(DATA1, DATA2, AND_OUT);

    // port declaration
    input [7 : 0] DATA1;
    input [7 : 0] DATA2;
    output [7 : 0] AND_OUT;

    assign #1 AND_OUT = DATA1 & DATA2; // wait for 1 time unit and assign AND of DATA1 and DATA2 to AND_OUT

endmodule

// OR module - for or instruction
module OR(DATA1, DATA2, OR_OUT);

    // port declaration
    input [7 : 0] DATA1;
    input [7 : 0] DATA2;
    output [7 : 0] OR_OUT;

    assign #1 OR_OUT = DATA1 | DATA2; // wait for 1 time unit and assign OR of DATA1 and DATA2 to OR_OUT

endmodule