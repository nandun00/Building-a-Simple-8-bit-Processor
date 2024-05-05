/* Lab 5 : Part 3 CPU
   Group 27
*/

//include ALU and register moduless
`include "alu.v"        
`include "Register_file.v"

/////////////////////////////////////////////////// CPU_tb/////////////////////////////////////////////////////////////////

module cpu_tb;

    reg CLK, RESET;
    wire [31:0] PC;
    reg [31:0] INSTRUCTION;
    integer i;
    
    /* 
    ------------------------
     SIMPLE INSTRUCTION MEM
    ------------------------
    */
    
    // TODO: Initialize an array of registers (8x1024) named 'instr_mem' to be used as instruction memory
    reg [7:0] instr_mem[0:1023];
    
    // TODO: Create combinational logic to support CPU instruction fetching, given the Program Counter(PC) value 
    //       (make sure you include the delay for instruction fetching here)
    always @(PC) begin
        #2
        INSTRUCTION = {instr_mem[PC+3], instr_mem[PC+2], instr_mem[PC+1], instr_mem[PC]};
    end
    
    initial
    begin
        // Initialize instruction memory with the set of instructions you need execute on CPU
        
        // METHOD 1: manually loading instructions to instr_mem
        //{instr_mem[10'd3], instr_mem[10'd2], instr_mem[10'd1], instr_mem[10'd0]} = 32'b00000000000001000000000000000101;
        //{instr_mem[10'd7], instr_mem[10'd6], instr_mem[10'd5], instr_mem[10'd4]} = 32'b00000000000000100000000000001001;
        //{instr_mem[10'd11], instr_mem[10'd10], instr_mem[10'd9], instr_mem[10'd8]} = 32'b00000010000001100000010000000010;
        
        // METHOD 2: loading instr_mem content from instr_mem.mem file
       $readmemb("instr_mem.mem", instr_mem);
    end
    
    /* 
    -----
     CPU
    -----
    */
    cpu mycpu(PC, INSTRUCTION, CLK, RESET);

    initial
    begin
    
        // generate files needed to plot the waveform using GTKWaves
        $dumpfile("cpu_wavedata.vcd");
		$dumpvars(0, cpu_tb);

        for(i=0;i<8;i=i+1)
        begin
            $dumpvars(1,cpu_tb.mycpu.r1.Register[i]);
        end 
        
        CLK = 1'b0;
        RESET = 1'b0;
        
        // TODO: Reset the CPU (by giving a pulse to RESET signal) to start the program execution
        #2
        RESET = 1'b1;

        #4
        RESET= 1'b0;
        
        // finish simulation after some time
        #100
        $finish;
        
    end
    
    // clock signal generation
    always
        #4 CLK = ~CLK;
        

endmodule


//////////////////////////////////////////////////   CPU     ////////////////////////////////////////////////////////////////
module cpu(PC, INSTRUCTION, CLK, RESET);
    output reg [31:0] PC;
    input [31:0] INSTRUCTION;
    input CLK, RESET;

    //Connections for Register File
    reg [2:0] WRITE_ADRS,READ_ADRS1, READ_ADRS2;
    reg WRITE;
    wire [7:0] RESULT;
    
    //connections for ALU
    reg [2:0] SEL;
    wire [7:0]  OUT1, OUT4;

    //Connections for negation MUX
    reg isNEGATIVE;
    wire [7:0]  NEGATIVE,OUT2;

    //Connections for immediate MUX
    reg  isIMMEDIATE;
    wire [7:0]  OUT3;

    //connection for PC adder
    wire [31:0] NEXT_INS;
    



    //instantiate all sub modules
    alu a1(OUT1, OUT4, RESULT, SEL);
    register_file r1(RESULT, OUT1, OUT2, WRITE_ADRS,READ_ADRS1, READ_ADRS2, WRITE, CLK, RESET);
    PC_adder add(PC, NEXT_INS); 
    twosCompliment t1(OUT2, NEGATIVE); // get 2's compliment
    MUX isNeg(NEGATIVE, OUT2, OUT3, isNEGATIVE); //select negative value for sub instruction and positive value for add instruction
    MUX isIMM(INSTRUCTION[7:0], OUT3, OUT4, isIMMEDIATE); //select immediate value or register value 
    

    always @(posedge CLK) begin
        if (RESET == 1'b1) 
		begin
			#1
			PC = 0;		 //When  the reset is 1 PC should be 0
		end
        else #1 PC = NEXT_INS;         //PC update (delay 1 unit)
            
    end

    always @(INSTRUCTION) begin

        //assign instuction to reg_file inputs
        WRITE_ADRS = INSTRUCTION[18:16];
        READ_ADRS1 = INSTRUCTION[10:8];
        READ_ADRS2 = INSTRUCTION[2:0];

        //Control Unit
        //check opcode and decode
        #1
        case(INSTRUCTION[31:24]) 
            8'd0 : //loadi
                begin 
                    WRITE = 1;          //enable write 
                    isNEGATIVE = 1'b0;  //no need for subtraction
                    isIMMEDIATE = 1'b1; //loadi instruction contain immediate value
                    SEL = 3'b000;       //select alu FORWARD operation

                end
            8'd1 : //mov instruction
                begin
                    WRITE = 1;          //enable write
                    isNEGATIVE = 1'b0;  //no need for subtraction
                    isIMMEDIATE = 1'b0; //no immediate value
                    SEL = 3'b000;       //select alu FORWARD operation

                end
            8'd2 : //add instruction 
                begin
                    WRITE = 1;          //enable write
                    isNEGATIVE = 1'b0;  //no need for subtraction
                    isIMMEDIATE = 1'b0; //no immediate value
                    SEL = 3'b001;       //select alu ADD operation
                    
                end
            8'd3 : //sub instruction
                begin
                    WRITE = 1;          //enable write
                    isNEGATIVE = 1'b1;  //need to substract value so isNegative is high
                    isIMMEDIATE = 1'b0; //no immediate value
                    SEL = 3'b001;       //select alu ADD operation
                    
                end
            8'd4 : //and instruction 
                begin
                    WRITE = 1;           //enable write
                    isNEGATIVE = 1'b0;   //no need for subtraction
                    isIMMEDIATE = 1'b0;  //no immediate value
                    SEL = 3'b010;        //select alu AND operation
                    
                end
            8'd5 : //or instruction
                begin
                    WRITE = 1;           //enable write
                    isNEGATIVE = 1'b0;   //no need for subtraction
                    isIMMEDIATE = 1'b0;  //no immediate value
                    SEL = 3'b011;        //select alu OR operation 
                    
                end
            
        endcase
    
    end

    

endmodule

/////////////////////////////////////////

 //module for 2's compliment
module twosCompliment(DATAIN, OUT);
   //declare input and output
   input [7:0] DATAIN;
   output [7:0] OUT;
   assign #1 OUT = ~DATAIN + 1;  //get 2's compliment by negating and adding 1
endmodule

//module for the selector MUX
module MUX(IN1, IN2, OUT, SELECT);
    input [7:0] IN1, IN2;
    input SELECT;
    output reg [7:0] OUT;

    always@(*) begin
        case(SELECT)
            1'b1: OUT <= IN1;
            1'b0: OUT <= IN2;
            default: OUT <= 8'd0;
        endcase
    end
endmodule

// dedicated adder for PC 
module PC_adder(IN, NEXT_INS);
    input [31:0] IN; // input address (current instruction)
    output [31:0] NEXT_INS; // output address (NEXT_INS instruction)

    assign #1 NEXT_INS = IN + 32'd4; // increment the PC value by 4 (delay 1 time unit)
  
endmodule


