/* Lab 5 : Part 4 Flow Control Instructions
   Group 27
*/

`include "alu.v"
`include "reg_file.v"
`include "dmem.v"

/////////////////////////////////////////////////// CPU_tb /////////////////////////////////////////////////////////////////

module cpu_tb;

    reg CLK, RESET;
    wire [31:0] PC;
    reg [31:0] INSTRUCTION;
    integer i;

    wire Write,Read;
    wire [7:0] READDATA, ADDRESS, WRITEDATA;
    wire BUSYWAIT;
    
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
    cpu mycpu(PC, INSTRUCTION, CLK, RESET, Read, Write, ADDRESS, WRITEDATA, READDATA, BUSYWAIT);

     /* 
    -----
     MEMORY
    -----
    */
    data_memory dmem(CLK, RESET, Read, Write, ADDRESS, WRITEDATA, READDATA, BUSYWAIT);

    initial
    begin
    
        // generate files needed to plot the waveform using GTKWave
        $dumpfile("cpu_wavedata.vcd");
		$dumpvars(0, cpu_tb);

        for(i=0;i<8;i=i+1)
        begin
            $dumpvars(1,cpu_tb.mycpu.r1.Register[i]);
        end 
        for(i=0;i<256;i=i+1)
        begin
            $dumpvars(1,cpu_tb.dmem.memory_array[i]);
        end 
        
        CLK = 1'b0;
        RESET = 1'b0;
        
        // TODO: Reset the CPU (by giving a pulse to RESET signal) to start the program execution
        #2
        RESET = 1'b1;

        #4
        RESET= 1'b0;
        
        // finish simulation after some time
        #500
        $finish;
        
    end
    
    // clock signal generation
    always
        #4 CLK = ~CLK;
        
endmodule

//////////////////////////////////////////////////   CPU     ////////////////////////////////////////////////////////////////
module cpu(PC, INSTRUCTION, CLK, RESET, ReadDmem, WriteDmem, ALURESULT, OUT1, READDATA, BUSYWAIT);
    output reg [31:0] PC;
    input [31:0] INSTRUCTION;
    input CLK, RESET;

    wire [7:0] OUT2, OUT3, OUT4, NEGATIVE, RESULT;
    reg [2:0] WRITE_ADRS,READ_ADRS1, READ_ADRS2, SEL;
    reg [1:0] SHIFT_SEL;
    reg [7:0] BRANCH;
    reg WRITE , isNEGATIVE, isIMMEDIATE, isBRANCH, isJUMP, isNEqBRANCH, isMEM;

    wire [31:0] NEXT_INS,EXTENDED, SHIFTED, BRANCHto, PCbranch, PCNEXT;
    wire ZERO,AND_OUT,AND_OUT2, OR_OUT;

    output reg WriteDmem, ReadDmem;
    input [7:0] READDATA;
    input BUSYWAIT;

    output [7:0] OUT1, ALURESULT;  //ADDRESS = ALU Result, WRITEDATA = Reg out 1


    //instantiate all sub modules
    alu a1(OUT1, OUT4, ALURESULT, SEL, ZERO, SHIFT_SEL);
    register_file r1(RESULT, OUT1, OUT2, WRITE_ADRS,READ_ADRS1, READ_ADRS2, WRITE && !BUSYWAIT, CLK, RESET);
    PC_adder add(PC, NEXT_INS); 
    twosCompliment t1(OUT2, NEGATIVE); // get 2's compliment
    MUX isNeg(NEGATIVE, OUT2, OUT3, isNEGATIVE); //select negative value for sub instruction and positive value for add instruction
    MUX isIMM(INSTRUCTION[7:0], OUT3, OUT4, isIMMEDIATE); //select immediate value or register value 

    AND2 and_gate(ZERO, isBRANCH, AND_OUT); //get the AND value of Zero and isBranch to do beq instruction
    PC_MUX m1(BRANCHto, NEXT_INS, PCbranch, OR_OUT); // select next pc value according to OR output
    Sign_extend s1(INSTRUCTION[23:16], EXTENDED); // sign extend given value to 32 bit before find the offset
    shift shift_2(EXTENDED, SHIFTED); // multiply the sign extended value by 4.(shift 2)
    Branch_ADD brAdd(NEXT_INS, SHIFTED, BRANCHto); // calculate the new PC value using shifted value
    PC_MUX m2(BRANCHto, PCbranch, PCNEXT, isJUMP); // select jump or branch to decide next PC value


    AND2 and_gate2(~ZERO, isNEqBRANCH, AND_OUT2);
    OR_GT or1(AND_OUT,AND_OUT2,OR_OUT);

    MUX writeSel(READDATA,ALURESULT,RESULT,isMEM); //select value to write to register form alu or data memory


    always @(posedge CLK) begin
        if (BUSYWAIT == 1'b0) begin  // PC update only if BUSYWAIT is 0 otherwise keep same PC value
            if (RESET == 1'b1) 
            begin
                #1
                PC = 0;		 //When  the reset is 1 PC should be 0
            end
            else #1 PC = PCNEXT;         //PC update (delay 1 unit)
        end
            
    end

    //Clearing READ/WRITE controls for Data Memory when BUSYWAIT is de-asserted
	always @ (BUSYWAIT)
	begin
		if (BUSYWAIT == 1'b0)
		begin
			ReadDmem = 0;
			WriteDmem = 0;
		end
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
            8'd0 : //loadi instruction
                begin
                    WRITE = 1'b1;          //enable write 
                    isNEGATIVE = 1'b0;  //no need for subtraction
                    isIMMEDIATE = 1'b1; //loadi instruction contain immediate value
                    SEL = 3'b000;       //select alu FORWARD operation
                    isJUMP = 1'b0;      //no instruction jumps
                    isBRANCH = 1'b0;    //no branchings
                    isNEqBRANCH = 1'b0; 
                    isMEM = 1'b0; // do not select data from data memory

                end
            8'd1 : //mov instruction
                begin
                    WRITE = 1'b1;          //enable write
                    isNEGATIVE = 1'b0;  //no need for subtraction
                    isIMMEDIATE = 1'b0; //no immediate value
                    SEL = 3'b000;       //select alu FORWARD operation
                    isJUMP = 1'b0;
                    isBRANCH = 1'b0;
                    isNEqBRANCH = 1'b0;
                    isMEM = 1'b0;

                end
            8'd2 : //add instruction 
                begin
                    WRITE = 1'b1;          //enable write
                    isNEGATIVE = 1'b0;  //no need for subtraction
                    isIMMEDIATE = 1'b0; //no immediate value
                    SEL = 3'b001;       //select alu ADD operation
                    isJUMP = 1'b0;
                    isBRANCH = 1'b0;
                    isNEqBRANCH = 1'b0;
                    isMEM = 1'b0;
                    
                end
            8'd3 : //sub instruction
                begin
                    WRITE = 1'b1;          //enable write
                    isNEGATIVE = 1'b1;  //need to substract value so isNegative is high
                    isIMMEDIATE = 1'b0; //no immediate value
                    SEL = 3'b001;       //select alu ADD operation
                    isJUMP = 1'b0;
                    isBRANCH = 1'b0;
                    isNEqBRANCH = 1'b0;
                    isMEM = 1'b0;
                end
            8'd4 : //and instruction 
                begin
                    WRITE = 1'b1;           //enable write
                    isNEGATIVE = 1'b0;   //no need for subtraction
                    isIMMEDIATE = 1'b0;  //no immediate value
                    SEL = 3'b010;        //select alu AND operation
                    isJUMP = 1'b0;
                    isBRANCH = 1'b0;
                    isNEqBRANCH = 1'b0;
                    isMEM = 1'b0;
                    
                end
            8'd5 : //or instruction
                begin
                    WRITE = 1'b1;           //enable write
                    isNEGATIVE = 1'b0;   //no need for subtraction
                    isIMMEDIATE = 1'b0;  //no immediate value
                    SEL = 3'b011;        //select alu OR operation 
                    isJUMP = 1'b0;
                    isBRANCH = 1'b0;
                    isNEqBRANCH = 1'b0;
                    isMEM = 1'b0;
                    
                end
            8'd6 : //jump instruction
                begin
                    WRITE = 1'b0;          // not writing to the register
                    isNEGATIVE = 1'b0;  //no need for subtraction
                    isIMMEDIATE = 1'b0; // no immidiate value
                    SEL = 3'b000;       //no need alu operation
                    isJUMP = 1'b1;      // jump signal is high
                    isBRANCH = 1'b0;    // no branchings
                    isNEqBRANCH = 1'b0;
                    isMEM = 1'b0;
                    
                end
            8'd7 : //branch instruction
                begin
                    WRITE = 1'b0;          // not writing to the register 
                    isNEGATIVE = 1'b1;  // get negative value for subtraction
                    isIMMEDIATE = 1'b0; // dont need immidiate values
                    isJUMP = 1'b0;      // jump is low
                    isBRANCH = 1'b1;    // branch signal is high
                    SEL = 3'b001;       //select alu ADD operation
                    isNEqBRANCH = 1'b0;
                    isMEM = 1'b0;
                    
                end
            8'd8 : //lwd instruction
                begin
                    WRITE = 1'b1; // need to write into register 
                    isNEGATIVE = 1'b0; // no need negative values
                    isIMMEDIATE = 1'b0; //no need immidiate values 
                    isJUMP = 1'b0; // jump signal low
                    isBRANCH = 1'b0; //no branchings
                    SEL = 3'b000; //select alu forward operation
                    isNEqBRANCH = 1'b0;
                    isMEM = 1'b1; //select data from memory
                    ReadDmem = 1'b1; //read from data memory
                    WriteDmem = 1'b0;
                    
                end
            8'd9 : //lwi instruction
                begin
                    WRITE = 1'b1; // need to write into register
                    isNEGATIVE = 1'b0; // no need negative values
                    isIMMEDIATE = 1'b1; //use immidiate values 
                    isJUMP = 1'b0; // jump signal low
                    isBRANCH = 1'b0; //no branchings
                    SEL = 3'b000; //select alu forward operation
                    isNEqBRANCH = 1'b0;
                    isMEM = 1'b1; //select data from memory
                    ReadDmem = 1'b1; //read from data memory
                    WriteDmem = 1'b0;
                    
                end
            8'd10 : //swd instruction
                begin
                    WRITE = 1'b0; // no need to write into register 
                    isNEGATIVE = 1'b0; // no need negative values
                    isIMMEDIATE = 1'b0; // no need immidiate values 
                    isJUMP = 1'b0; // jump signal low
                    isBRANCH = 1'b0; // no branchings
                    SEL = 3'b000; //select alu forward operation
                    isNEqBRANCH = 1'b0;
                    isMEM = 1'b0; // do not select data from memory
                    ReadDmem = 1'b0;
                    WriteDmem = 1'b1; // write to data memory
                    
                end
            8'd11 : //swi instruction
                begin
                    WRITE = 1'b0; // no need to write into register
                    isNEGATIVE = 1'b0; // no need negative values
                    isIMMEDIATE = 1'b1; // use immidiate values 
                    isJUMP = 1'b0; // jump is low
                    isBRANCH = 1'b0; // branch is low
                    SEL = 3'b000; //set alu to forward operation
                    isNEqBRANCH = 1'b0;
                    isMEM = 1'b0;
                    ReadDmem = 1'b0;
                    WriteDmem = 1'b1; //write to data memory
                    
                end

            8'd12 : //logical shift left
                begin
                    WRITE = 1;          // write final result to the register 
                    isNEGATIVE = 1'b0;  // no need negative value
                    isIMMEDIATE = 1'b1; // need immidiate values
                    isJUMP = 1'b0;      // jump signal  is low
                    isBRANCH = 1'b0;    // branch signal is low
                    SEL = 3'b100;       //select alu shift operation
                    SHIFT_SEL = 2'b01;  //select sll operation
                    isNEqBRANCH = 1'b0; 
                    isMEM = 1'b0;
                    
                end
            8'd13 : //logical shift right
                begin
                    WRITE = 1;          // write final result to the register 
                    isNEGATIVE = 1'b0;  // no need negative value
                    isIMMEDIATE = 1'b1; // need immidiate values
                    isJUMP = 1'b0;      // jump signal  is low
                    isBRANCH = 1'b0;    // branch signal is low
                    SEL = 3'b100;       //select alu shift operation
                    SHIFT_SEL = 2'b00;  //select srl operation
                    isNEqBRANCH = 1'b0; 
                    isMEM = 1'b0;
                    
                end
           8'd14 : //arithmatic shift right
                begin
                    WRITE = 1;          // write final result to the register 
                    isNEGATIVE = 1'b0;  // no need negative value
                    isIMMEDIATE = 1'b1; // need immidiate values
                    isJUMP = 1'b0;      // jump signal  is low
                    isBRANCH = 1'b0;    // branch signal is low
                    SEL = 3'b100;       //select alu shift operation
                    SHIFT_SEL = 2'b10;  //select sra operation
                    isNEqBRANCH = 1'b0; 
                    isMEM = 1'b0;
                    
                end
            8'd15 : //rotate right
                begin
                    WRITE = 1;          // write final result to the register 
                    isNEGATIVE = 1'b0;  // no need negative value
                    isIMMEDIATE = 1'b1; // need immidiate values
                    isJUMP = 1'b0;      // jump signal  is low
                    isBRANCH = 1'b0;    // branch signal is low
                    SEL = 3'b100;       //select alu shift operation
                    SHIFT_SEL = 2'b11;  //select ror operation
                    isNEqBRANCH = 1'b0; 
                    isMEM = 1'b0;
                    
                end
            8'd16 : //branch not equal
                begin
                    WRITE = 0;          // not writing results to the register 
                    isNEGATIVE = 1'b1;  // make second operand to negative
                    isIMMEDIATE = 1'b0; // don't need immidiate values
                    isJUMP = 1'b0;      // jump signal  is low
                    isBRANCH = 1'b0;    // branch signal is low
                    SEL = 3'b001;       //select alu sub operation
                    isNEqBRANCH = 1'b1;  // not equal branch signal is high
                    isMEM = 1'b0;
                     
                end
           8'd17 : //multiply
                begin
                    WRITE = 1;          // write final result to the register 
                    isNEGATIVE = 1'b0;  // no need negative value
                    isIMMEDIATE = 1'b0; // don't need immidiate values
                    isJUMP = 1'b0;      // jump signal  is low
                    isBRANCH = 1'b0;    // branch signal is low
                    SEL = 3'b101;       //select alu multi operation
                    isNEqBRANCH = 1'b0;  
                    isMEM = 1'b0;
                     
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

// AND gate module
module AND2(INPUT1,INPUT2,OUTPUT);
    input INPUT1,INPUT2;
    output OUTPUT;

    and(OUTPUT,INPUT1,INPUT2); 
endmodule

//OR gate module
module OR_GT(IN1, IN2, OUT);
    input IN1, IN2;
    output OUT;

    or(OUT, IN1, IN2);

endmodule

///////////////////////////////////////
//module for Add offset value to PC value for branching
module Branch_ADD(pcNext, offset, out);
    input [31:0] pcNext, offset;
    output [31:0] out;

    assign #2 out = pcNext + offset;

endmodule

//module for sign extend
module Sign_extend(IN, OUT);
    input [7:0] IN; //8 bit input
    output [31:0] OUT; //32 bit output

    assign OUT[7:0] = IN[7:0];
    assign OUT[31:8] = {24{IN[7]}};
    initial begin
    end
endmodule

//module for shift 2 times
module shift(IN, OUT);
    input signed[31:0] IN;
    output signed[31:0] OUT;

    assign OUT = IN << 2; // multiply by 4

endmodule

//mux module for select right pc value
module PC_MUX(IN1, IN2, OUT, SELECT);
    input [31:0] IN1, IN2;
    input SELECT;
    output reg [31:0] OUT;

    always@(*) begin
        case(SELECT)
            1'b1: OUT <= IN1;
            1'b0: OUT <= IN2;
        endcase
    end
endmodule

