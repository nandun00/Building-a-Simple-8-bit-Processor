/* Lab 6 : Part 2 Flow Control Instructions
   Group 27
*/

`include "alu.v"
`include "reg_file.v"
`include "dmem.v"
`include "dcache.v"


/////////////////////////////////////////////////////////////////////////////////////////////

//`timescale 1ns/100ps
module cpu_tb;
    reg[31:0] INSTRUCTION_t;                // 32'b10010 001 00000000 00000001 00000010;
    wire[31:0] PC_t;                         //     opcode    desti   source1   source2
    reg CLK, RESET;
    reg[31:0] PC_output;
    integer j;

    wire readcache_t;
    wire writecache_t;
    wire busywait_cache_t;
    wire[7:0] cacheReadOutput_t;
    wire[5:0] address_from_cache_t;


    wire readmem_t;
    wire writemem_t;
    wire busywait_mem_t;
    wire[7:0] aluResult_t;
    wire[31:0] read_data_from_mem_t;
    wire[31:0] writedata_to_mem_t;
    wire[7:0] reg1output_t; // input data to write for cache

                                       
    reg[7:0] instr_mem[0:1023]; // 1byte x 1024 word registers

    cpu cpu_(PC_t, INSTRUCTION_t, CLK, RESET, readcache_t, writecache_t, busywait_cache_t, aluResult_t, cacheReadOutput_t, reg1output_t);

    cache cache_(
        .clock(CLK),
        .reset(RESET),
        .read(readcache_t), 
        .write(writecache_t),
        .address(aluResult_t),
        .writedata(reg1output_t),
        .readdata(cacheReadOutput_t),
        .busywait(busywait_cache_t), 

        .mem_read(readmem_t),
        .mem_write(writemem_t),
        .mem_address(address_from_cache_t),
        .mem_writedata(writedata_to_mem_t),
        .mem_readdata(read_data_from_mem_t),
        .mem_busywait(busywait_mem_t)
    );

    data_memory memory_(
        .clock(CLK), 
        .reset(RESET), 
        .read(readmem_t), 
        .write(writemem_t), 
        .address(address_from_cache_t), 
        .writedata(writedata_to_mem_t), 
        .readdata(read_data_from_mem_t), 
        .busywait(busywait_mem_t)
    );

    initial
    begin
        $dumpfile("cpu_wavedata.vcd");
        $dumpvars(0, cpu_tb);
        for (j = 0; j < 8; j = j + 1) $dumpvars(0, cpu_.myreg_file.registers[j]); // printing registers 0-7
        for (j = 0; j < 8; j = j + 1) $dumpvars(0, cache_.tag_array[j]); // printing tag array
        for (j = 0; j < 8; j = j + 1) $dumpvars(0, cache_.data_block[j]); // printing data array
        for (j = 0; j < 256; j = j + 1) $dumpvars(0, memory_.memory_array[j]); // printing memory data array
        
    end

    always begin
        #4 CLK = ~CLK; // changed clock period to 8 units
    end

    initial begin

        CLK = 1'b1;
        RESET = 1'b0;
        #5
        RESET = 1'b1;
        #6
        RESET = ~RESET;
        
        #1400 $finish; 
    end
    always @(PC_t) begin
        PC_output = PC_t; // copy the updated pc value to new variable just for easyness
    end

    always @(posedge CLK) begin
        #2 // instruction memory read
        INSTRUCTION_t = {instr_mem[32'd0+PC_output], instr_mem[32'd1+PC_output], instr_mem[32'd2+PC_output],instr_mem[32'd3+PC_output]};
    end

    initial begin 
        // copying 32bit instruction to concatenated 1 byte four elements
        {instr_mem[32'd0], instr_mem[32'd1], instr_mem[32'd2],instr_mem[32'd3]} <= 32'b10000000000000010000000001100000; // loadi 1 0x60
        {instr_mem[32'd4], instr_mem[32'd5], instr_mem[32'd6],instr_mem[32'd7]} <= 32'b01111000000000000000000100101000; // swi 1 0x28      -- write hit
        {instr_mem[32'd8], instr_mem[32'd9], instr_mem[32'd10],instr_mem[32'd11]} <= 32'b10000000000000100000000001100001; // loadi 2 0x61  
        {instr_mem[32'd12], instr_mem[32'd13], instr_mem[32'd14],instr_mem[32'd15]} <= 32'b01111000000000000000001010001000; // swi 2 0x88  -- diff tag -- write miss
        {instr_mem[32'd16], instr_mem[32'd17], instr_mem[32'd18],instr_mem[32'd19]} <=32'b11101000000001000000000010001000; // lwi 4 0x88 -- read hit
        {instr_mem[32'd20], instr_mem[32'd21], instr_mem[32'd22],instr_mem[32'd23]} <=32'b11101000000000110000000000101000; // lwi 3 0x28  -- read miss and dirty
        {instr_mem[32'd24], instr_mem[32'd25], instr_mem[32'd26],instr_mem[32'd27]} <=32'b11101000000001010000000010001000; // lwi 5 0x88     read miss not dirty
        {instr_mem[32'd28], instr_mem[32'd29], instr_mem[32'd30],instr_mem[32'd31]} <=32'b01111000000000000000000101111110; // swi 1 0x7E     write hit
        {instr_mem[32'd32], instr_mem[32'd33], instr_mem[32'd34],instr_mem[32'd35]} <=32'b01111000000000000000001001111101; // swi 2 0x7D    write hit
        {instr_mem[32'd36], instr_mem[32'd37], instr_mem[32'd38],instr_mem[32'd39]} <= 32'b01111000000000000000000101011101; // swi 1 0x5D   write miss, dirty
        {instr_mem[32'd40], instr_mem[32'd41], instr_mem[32'd42],instr_mem[32'd43]} <= 32'b10001000000000000000000000000001; // mov 0 1
        {instr_mem[32'd44], instr_mem[32'd45], instr_mem[32'd46],instr_mem[32'd47]} <= 32'b10000000000000110000000001011101; // loadi 3 0x5D 
        {instr_mem[32'd48], instr_mem[32'd49], instr_mem[32'd50],instr_mem[32'd51]} <= 32'b11100000000001000000000000000011; // lwd 4 3
        {instr_mem[32'd52], instr_mem[32'd53], instr_mem[32'd54],instr_mem[32'd55]} <= 32'b01110000000000000000000000000010; // swd 0 2


       
    end
endmodule



//cpu module
module cpu(PC, INSTRUCTION, CLK, RESET, READMEM, WRITEMEM, BUSYWAIT, aluResult, memReadOutput, reg1output);  
    
    input[31:0] INSTRUCTION;  // 32 bit instruction
    output reg[31:0] PC; // 32 bit program counter
    input CLK, RESET;
    
    
    reg write;  // write enable signal
    reg[7:0] destination;
    reg[7:0] opcode; 
    reg[2:0] aluop;
    reg[7:0] source1;
    reg[7:0] source2;

    reg[7:0] immediate; // immediate value
    reg[7:0] alusrc1;  
    reg[7:0] registerIn;  // register input for writing data to register
    
    // these wires can be declared as "output"
    wire[7:0] aluResult_wire; // result of alu operation/module
    output reg[7:0] aluResult;
    wire[7:0] reg1output_wire; // getting the output from register file
    output reg[7:0] reg1output; // sending reg1output to memory module
    wire[7:0] reg2output;
    wire[7:0] twoscomplement; // twoscomplement second operand
    wire[31:0] pcUpdaterout;  // updated program counter value from dedicated adder
    wire[7:0] alusrc2; // this is generated by the source 2 mux(this is the output of that mux--immediate or register value)
    wire zerooutput; // zero result output for beq 

    input[7:0] memReadOutput;  // readed value from memory/ cache
    wire[7:0] registerInput; // either aluresult or memory read
    input BUSYWAIT;
    output reg WRITEMEM;  // memory write enable signal
    output reg READMEM;    // memory read enable signal

    wire[31:0] branchResult;

    always @(INSTRUCTION) begin
        destination <= INSTRUCTION[23:16];  // either the register to be written to in the register file,or an immediate value (jump or branch target offset).
        source1 <= INSTRUCTION[15:8]; // 1 st operand to be read from the register file.    
        source2 <= INSTRUCTION[7:0];  // 2 nd operand from the register file, or an immediate value (loadi).
        immediate <= INSTRUCTION[7:0]; // copy as immediate value    
        #1 // control signal generate
        write <= INSTRUCTION[31]; // first bit of my opcode is write enable signal
        opcode <= INSTRUCTION[31:24];
        aluop <= INSTRUCTION[26:24]; // aluop is the last 3 bits of my opcode -- opcode[2:0]
        
    end
    always @(BUSYWAIT) begin        
        write =(~BUSYWAIT & INSTRUCTION[31]);  // if busywait enabled, stop writing to register file
    end
    
    // instantiating submodules
    reg_file myreg_file(.IN(registerIn), .OUT1(reg1output_wire), .OUT2(reg2output), .INADDRESS(destination[2:0]), 
        .OUT1ADDRESS(source1[2:0]), .OUT2ADDRESS(source2[2:0]), .WRITE(write), .CLK(CLK), .RESET(RESET));

    alu myalu(.DATA1(alusrc1), .DATA2(alusrc2), .RESULT(aluResult_wire), .SELECT(aluop), .ZERO(zerooutput));

    twosComplement mytwo(.NUMBER(reg2output), .OUT(twoscomplement));

    pcUpdater mypcUpdater(.pc(PC), .clk(CLK), .reset(RESET), .pcout(pcUpdaterout));

    // this mux is selecting the source2 or immediate value depending on the opcode
    src2mux my_src2mux(.ALUOP(aluop), .OPCODE(opcode), .ALUSRC2(alusrc2), .IMMEDIATE(immediate), .TWOSCOMPLEMENT(twoscomplement), .REG2OUTPUT(reg2output));

    branchValue mybranchValue(.PC(PC), .OFFSET(destination), .OUT(branchResult));
    
    
    inputForRegisterIn my_inputForRegisterIn(.INSTRUCTION(INSTRUCTION), .OPCODE(opcode), .ALURESULT(aluResult_wire), .MEMREADOUTPUT(memReadOutput), .OUTPUTVALUE(registerInput));

    always@(INSTRUCTION) begin
        #1    // control signals are generating after 1 time unit
        READMEM = 1'b0; // resetting readmem, writemem at every new instruction
        WRITEMEM = 1'b0;
        // comparing opcodes
        if((INSTRUCTION[31:24] == 8'b11100000) || (INSTRUCTION[31:24] == 8'b11101000)) begin  // lwd, lwi 
            #2  // data memory access 2 units delay
            READMEM = 1'b1;
            WRITEMEM = 1'b0;
        end
        else if((INSTRUCTION[31:24] == 8'b01110000) || (INSTRUCTION[31:24] == 8'b01111000)) begin // swd, swi
            #2  // data memory access 2 units delay
            WRITEMEM = 1'b1;
            READMEM = 1'b0;
        end
        else begin
            WRITEMEM = 1'b0;
            READMEM = 1'b0;
        end
    end
    always@(*) begin
        aluResult <= aluResult_wire; // output alu result value from cpu to mem module
    end
    always@(*) begin
        alusrc1 <= reg1output_wire; // always providing the register output to alu source 1
        reg1output <= reg1output_wire; // also providing as output from cpu to memory module
    end
    always @(registerInput)
        registerIn <= registerInput;

    always @(posedge CLK) begin
        #1
    	if(!RESET && !BUSYWAIT) begin
            if (opcode == 8'b00001100) PC = branchResult; // new branch(pc value) for jump, if it is jump instruction no need to check the zero output
            else if(opcode == 8'b00000101) begin // branch value for beq
                if(zerooutput == 1'b1) PC = branchResult; 
                else PC = pcUpdaterout;
            end
            else if(opcode == 8'b00011101) begin // branch value for bne
                if(zerooutput == 1'b0) PC = branchResult; 
                else PC = pcUpdaterout;
            end
            else PC = pcUpdaterout;   // every other instruction is not jump or beq
        end    
    end

    always @(RESET) begin
    	if(RESET)
        	#1 PC = pcUpdaterout;  // pc update(write to pc)       
    end

endmodule

// this mux decides which value is passed to register write port
// either alu result or readed value from memory
module inputForRegisterIn(INSTRUCTION, OPCODE, ALURESULT, MEMREADOUTPUT, OUTPUTVALUE);
    input[31:0] INSTRUCTION;
    input[7:0] OPCODE;
    input[7:0] ALURESULT;
    input[7:0] MEMREADOUTPUT;
    output reg[7:0] OUTPUTVALUE;

    always @(INSTRUCTION, MEMREADOUTPUT, ALURESULT) begin
        if((OPCODE[6:3] == 4'b1100) || (OPCODE[6:3] == 4'b1101)) begin // those 4 bits are unique to lwd, lwi
            OUTPUTVALUE = MEMREADOUTPUT;                               // so when lwd, lwi memory readed value will be passed
        end
        else begin
            OUTPUTVALUE = ALURESULT; 
        end
    end

endmodule


// module for calculating branch value for jump, beq 
module branchValue(PC, OFFSET, OUT);
    input[31:0] PC;
    input[7:0] OFFSET; // offset provided as 8 bits
    output reg[31:0] OUT; 

    always @(PC, OFFSET)
        #2  // two times delay        
        OUT = (PC+ 32'd4) + {{24{OFFSET[7]}} , (OFFSET<<2)};  // left shift two times and concatenate to the sign extended MSB
        
endmodule


// module for deciding the alusrc2 is either immediate value or register output
module src2mux(ALUOP, OPCODE, ALUSRC2, IMMEDIATE, TWOSCOMPLEMENT, REG2OUTPUT);
    input[2:0] ALUOP;
    input[7:0] OPCODE;   
    input[7:0] IMMEDIATE;
    input[7:0] TWOSCOMPLEMENT;
    input[7:0] REG2OUTPUT;

    output reg[7:0] ALUSRC2;

    // these things are decided by 3-6 bits of my opcode, those are unique to each operation
    always @(*) begin
        case(ALUOP)
            // 3'b000 : ALUSRC2 <= OPCODE[6:3] == 4'b0000 ? IMMEDIATE : REG2OUTPUT;    // loadi, mov
            3'b000 : begin
                        if((OPCODE[6:3] == 4'b0000) || (OPCODE[6:3] == 4'b1101) || (OPCODE[6:3] == 4'b1111)) begin // loadi, lwi, swi
                            ALUSRC2 <= IMMEDIATE;
                        end
                        else begin   // mov, lwd, swd
                            ALUSRC2 <= REG2OUTPUT;
                        end
                    end


            3'b001 : ALUSRC2 <= OPCODE[6:3] == 4'b0011 ? TWOSCOMPLEMENT : REG2OUTPUT; // add, sub
            3'b010 : ALUSRC2 <= REG2OUTPUT; // and
            3'b011 : ALUSRC2 <= REG2OUTPUT; // or

            3'b101 : ALUSRC2 <= TWOSCOMPLEMENT; // beq, bne
            3'b110 : ALUSRC2 <= IMMEDIATE; // sll - logical left shift
            3'b111 : ALUSRC2 <= IMMEDIATE; // srl - logical right shift
        endcase
    end

endmodule

// dedicated adder for pc update.
module pcUpdater(pc, clk, reset, pcout);
    input[31:0] pc;
    input reset;
    input clk;
    output reg[31:0] pcout;

    always @(pc) begin
        #1 pcout = pc + 32'd4; // pc update delay changed to #1 according to lab6
    end

    always @(reset) begin
        if(reset)        
            pcout = -32'd4; // at the reset, writing -4
    end
endmodule

// two's complement module for substract operation
module twosComplement(NUMBER, OUT);
    input[7:0] NUMBER;
    output reg[7:0] OUT;
    integer i; 
    
    // outputting the two's complement of second operand
    always @(NUMBER) begin
        #1 // 1 time unit delay -- preparation lab6
        for(i=0; i<8; i=i+1) begin
            OUT[i] = NUMBER[i] == 1 ? 0 : 1;
        end
        OUT = OUT + 8'd1;
    end
endmodule