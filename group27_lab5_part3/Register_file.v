/* Lab 5 : Part 3 CPU - REG file
   Group 27
*/
///////////////////////////    register file      ///////////////////////////////////
module register_file(DATAINIn, Output_1, Output_2, DATAINInAddress, OutputAddress_1, OutputAddress_2, WRITE, CLK, RESET);

    reg [7:0] Register[0:7]; //8, 8 bit registers inside

    //declaration of inputs and ouputs
    input [7:0] DATAINIn;
    input [2:0] OutputAddress_1, OutputAddress_2, DATAINInAddress;
    input CLK, RESET, WRITE;
    output [7:0] Output_1, Output_2;

    integer i;

    //read asynchronously and load values into Output_1 and Output_2 
    assign #2 Output_1 = Register[OutputAddress_1];
    assign #2 Output_2 = Register[OutputAddress_2];

    //always block only teriggerd in the positive edge of clock
    always@(posedge CLK)
    begin
        if(WRITE & !RESET) begin// if write port is set to high and reset is low then IN port is write into register named as DATAINInAddress
           #1 Register[DATAINInAddress] <= DATAINIn;
        end
        if(RESET) begin // if reset is high, all values in registers are written as 0
            #1
            for(i = 0; i < 8; i += 1) begin // make for loop for access each element in an array
                Register[i] = 8'd0;
            end
        end

    end

endmodule
//////////////////////////////////////////////////////////////////////////////////////////////////
