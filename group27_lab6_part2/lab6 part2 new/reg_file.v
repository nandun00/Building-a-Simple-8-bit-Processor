/* Lab 5 : Part 4 Flow Control Instructions - reg file
   Group 27
*/

///////////////////////////    register file      ///////////////////////////////////
module reg_file (IN, OUT1, OUT2, INADDRESS, OUT1ADDRESS, OUT2ADDRESS, WRITE, CLK, RESET);

    input[7:0] IN; // input data
    output reg [7:0] OUT1, OUT2; // data output
    input[2:0] INADDRESS, OUT1ADDRESS, OUT2ADDRESS; // 3bit addressess corresponding to register numbers
    input WRITE, CLK, RESET;

    output reg[7:0] registers[0:7]; // 8bit eight registers

    integer l; // for the loop, l is for the loop for clearing registers(if reset enabled)

    // since reading happening always, when either one of the register's content is change, it should show the output
    // 2 times units after change happens(after resetting and writing)
    always @(registers[0] or registers[1] or registers[2] or registers[3] or registers[4] or registers[5] or registers[6] or registers[7]) begin
        
        #2
        OUT1 <= registers[OUT1ADDRESS];
        OUT2 <= registers[OUT2ADDRESS];
        // $monitor($time, " reg[%d]: %d reg[%d]: %d", OUT1ADDRESS, OUT1, OUT2ADDRESS, OUT2);
        
    end

    // except the content changing of the register, if either one of read address changes it should give the
    // corresponding output.
    // but if the reset is happening we should give priority to the reset. 
    // since it will be already displaying the output after reset(resetting is like writing 0s)
    always @(OUT1ADDRESS or OUT2ADDRESS) begin 
        if(!RESET) begin
            #2
            OUT1 <= registers[OUT1ADDRESS];
            OUT2 <= registers[OUT2ADDRESS];
            // $monitor($time, " reg[%d]: %d reg[%d]: %d", OUT1ADDRESS, OUT1, OUT2ADDRESS, OUT2);
        end          
    end

    // at each pos edge of the clock writing to the register after 2 time units
    always @(posedge CLK) begin  
        #1  
        if(WRITE) begin
        //    #1 // changed -- preparation lab 6
            registers[INADDRESS] = IN;     
            // $monitor($time, " reg[%d]: %d", INADDRESS, IN);                   
        end        
    end

    // if the reset enabled, making all registers to zeroes
    always @ (RESET) begin   
        if(RESET) begin
            #1  // changed -- preparation lab 6
            for(l=0; l<8; l=l+1) begin
                registers[l] <= 8'd0;
            end
        end
    end
endmodule


//////////////////////////////////////////////////////////////////////////////////////////////////

