/* Lab 5 : Part 4 Flow Control Instructions - ALU
   Group 27
*/


//////////////////////////       ALU          /////////////////////////////////////////////////////////////////
module alu(DATA1, DATA2, RESULT, SELECT, ZERO);

    input[7:0] DATA1, DATA2; // declaring 8bit input ports
    input[2:0] SELECT;  // 3bit input port for ALUOp code
    output reg[7:0] RESULT; // 8bit output
    output reg ZERO;
    integer i, a;
    
    always @(DATA2) begin
        a = DATA2;  // making shifting amount as a integer to make operations in for loop
    end


    
    always @ (DATA1 or DATA2 or SELECT)begin  // always block execute if either of inputs are changed
        case (SELECT)
            3'b001 : #2 begin RESULT = DATA1 + DATA2; ZERO = 1'b0; end // add-sub operation aluopcode 001                              
            3'b000 : #1 begin RESULT = DATA2; ZERO = 1'b0; end         // mov-loadi aluopcode 000, moving data2 to result
            3'b010 : #1 begin RESULT = DATA1 & DATA2; ZERO = 1'b0; end  // bitwise and aluopcode 010
            3'b011 : #1 begin RESULT = DATA1 | DATA2; ZERO = 1'b0; end  // bitwise or aluopcode 011
            3'b101 : #2 begin RESULT = DATA1 + DATA2; // beq aluopcode 101
                              if(~(RESULT[0]|RESULT[1]|RESULT[2]|RESULT[3]|RESULT[4]|RESULT[5]|RESULT[6]|RESULT[7])) ZERO = 1'b1; // checking if the result is zero
                              else ZERO = 1'b0;                              
                        end  
            3'b110 : #1 begin // sll - logical shift left
                                if(a > 7) begin // if shifting amount is greater than 7, answer should be 0
                                    RESULT = 8'd0; 
                                end
                                else begin
                                    for(i=0; i<8-a; i=i+1) begin
                                        RESULT[i+a] = DATA1[i];
                                    end
                                    for(i=0; i<a; i=i+1) begin // making LSB as 0s
                                        RESULT[i] = 1'b0;
                                    end
                                end
                                ZERO = 1'b0; 
                        end 
            3'b111 : #1 begin // srl - logical shift right
                                if(a > 7) begin // if shifting amount is greater than 7, answer should be 0
                                    RESULT = 8'd0; 
                                end
                                else begin
                                    for(i=7; i>=a; i=i-1) begin
                                        RESULT[i-a] = DATA1[i];
                                    end
                                    for(i=7; i>7-a; i=i-1) begin // filling MSB as 0s
                                        RESULT[i] = 1'b0;
                                    end

                                end
                                ZERO = 1'b0; 
                        end 
            default : ZERO = 1'b0;  // since aluopcode for jump is not used in here, the zero output is disabled by default
        endcase        
    end

endmodule
///////////////////////////////////////////////////////////////////////////////////////////////////

