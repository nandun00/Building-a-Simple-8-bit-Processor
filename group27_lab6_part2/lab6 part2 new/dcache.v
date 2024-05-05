module cache(
    clock,
    reset,
    read,
    write,
    address,
    writedata,
    readdata,
	busywait, 

    mem_read,
    mem_write,
    mem_address,
    mem_writedata,
    mem_readdata,
    mem_busywait
);

    input clock;
    input reset;
    input read;
    input write;
    input[7:0] address;
    input[7:0] writedata;
    output reg[7:0] readdata;
    output reg busywait;

    output reg mem_read;
    output reg mem_write;
    output reg[5:0] mem_address;   // 6 bit address for main memory access
    output reg[31:0] mem_writedata;  // data block for write to main mem
    input[31:0] mem_readdata;       // block read from main mem
    input mem_busywait;

    reg[7:0] valid;
    reg[7:0] dirty;
    reg[2:0] tag_array [7:0];  // array with 3 bit tag
    reg[31:0] data_block[7:0];   // 4 byte data blocks

    reg[2:0] tag;
    reg[2:0] index;
    reg[1:0] offset;

    reg readhit;  // read hit signal
    reg writehit; // write hit signal -- two seperate hit signals used to be more explicit

    always @(address) // seperate address into tag, index, offset
    begin
        tag = address[7:5];
        index = address[4:2];
        offset = address[1:0];
    end


    //Detecting an incoming cache memory access
    reg readaccess, writeaccess;
    always @(read, write)
    begin
        busywait = (read || write)? 1 : 0;
        readaccess = (read && !write)? 1 : 0;
        writeaccess = (!read && write)? 1 : 0;
    end

    always @(*) // read hit determine
    begin
        if(readaccess) 
        begin
            #0.9
            if(valid[index] && tag_array[index] == tag)  // comparing tag and valid bit
                readhit = 1;
            else
                readhit = 0;            
        end
        else  // if the instruction is not a cache read, then readhit is de-asserted
            readhit = 0;
    end

    always @(*)  // write hit determine
    begin
        if(writeaccess)
        begin
            #0.9
            if(!valid[index]) // very first write, not need to compare other things
                writehit = 1;
            else if(tag_array[index] == tag && valid[index])  // comparing tag and valid bit
                writehit = 1;
            else
                writehit = 0;
        end
        else  // if the instruction is not a cache write, then write hit is de-asserted
            writehit = 0;
    end


    always @(readhit, readaccess)  
    begin
        #1
        if(readaccess) 
        begin        
            if(readhit) // read hit
            begin    
                case(offset)      // extracting the correct block using offset   
                    2'b00 : readdata = data_block[index][7:0];
                    2'b01 : readdata = data_block[index][15:8];
                    2'b10 : readdata = data_block[index][23:16];
                    2'b11 : readdata = data_block[index][31:24];
                endcase
                // busywait = 0;
            end
        end
        
    end

    always @(writehit)
    begin
        if(writeaccess) 
        begin
            #1
            if(writehit)
            begin
                valid[index] = 1;
                dirty[index] = 1'b1;
                tag_array[index] = tag; 

                case(offset) // write to correct block using offset
                    2'b00 : data_block[index][7:0] = writedata;
                    2'b01 : data_block[index][15:8] = writedata;
                    2'b10 : data_block[index][23:16] = writedata;
                    2'b11 : data_block[index][31:24] = writedata;
                endcase
                // busywait = 0; 
            end           
        end
    end

    // when a hit occured, resetting busywait at next positive edge

    always @(posedge clock)
    begin
        if((readhit || writehit) && !mem_busywait)
            busywait = 0;
    end


    /* Cache controller FSM */

    parameter IDLE_STATE = 3'b000, MEM_READ_STATE = 3'b001, MEM_WRITE_STATE = 3'b010,
                                   WRITE_TO_CACHE_ON_MISS = 3'b011;
    reg[2:0] state, next_state;


    always @(*)
    begin
        case (state) 
            IDLE_STATE: 
                if(busywait && readaccess && !writeaccess && valid[index] && !readhit && !dirty[index]) begin // read miss but not dirty-- read from memory 
                    next_state = MEM_READ_STATE;
                end
                else if(busywait && readaccess && !writeaccess && valid[index] && !readhit && dirty[index]) begin // read miss and dirty -- write old block to memory
                    next_state = MEM_WRITE_STATE;
                end
                else if(busywait && writeaccess && !readaccess && !writehit && tag_array[index] != tag && !dirty[index]) begin // write miss, tag mismatch and not dirty -- read new block from memory
                    next_state = MEM_READ_STATE;
                end
                else if(busywait && writeaccess && !readaccess && !writehit && tag_array[index] != tag && dirty[index]) begin  // tag not match and dirty  -- write old block to memory
                    next_state = MEM_WRITE_STATE;
                end

                else begin
                    next_state = IDLE_STATE;
                end


            MEM_READ_STATE:  // if memory read is done always write to cache(newly readed block)
                if(readaccess) 
                    next_state = WRITE_TO_CACHE_ON_MISS;
                else if(writeaccess)
                    next_state = WRITE_TO_CACHE_ON_MISS;

            MEM_WRITE_STATE:              
                if(readaccess && !writeaccess && valid[index] && !readhit && !dirty[index]) // read miss and dirty 2nd step 
                    next_state = MEM_READ_STATE; // after writing old block, now fetch the new block from memory
                else if(writeaccess && !readaccess && !writehit && tag_array[index] != tag && !dirty[index]) // write miss -tag not match and dirty 2nd step
                    next_state = MEM_READ_STATE;  // after writing the old block, fetch new block from memory

            WRITE_TO_CACHE_ON_MISS:
                next_state = IDLE_STATE;  // after each memory read, fetched data need to write to cache, then go to idle state
        endcase
    end

    always @(*) 
    begin
        case (state)
            IDLE_STATE: 
            begin
                mem_read = 0;
                mem_write = 0;
                mem_address = 8'dx;
                mem_writedata = 8'dx;
                busywait = 0;
            end

            MEM_READ_STATE:
            begin
                mem_read = 1;
                mem_write =  0;
                mem_address = {tag, index};  // reading new block
                mem_writedata = 32'dx;
                busywait = 1;
                // dirty[index] = 0;
            end

            MEM_WRITE_STATE:    
            begin
                mem_read = 0;
                mem_write = 1;
                mem_address = {tag_array[index], index};   // old tag should be write
                mem_writedata = data_block[index]; 
                dirty[index] = 0;
                busywait = 1;
            end

            WRITE_TO_CACHE_ON_MISS:
            begin
                if(!writehit) // by asynchronous logic when there is write hit, this will prevent overwriting dirty bit and data again
                begin
                    #1
                    data_block[index] = mem_readdata;
                    dirty[index] = 0;
                    tag_array[index] = tag; // updating tag
                    busywait = 1;
                end
            end
            

        endcase
    end

    // state transitioning
    always @(posedge clock, reset)
    begin
        if(reset)
            state = IDLE_STATE;
        else if(!mem_busywait)   // if memory operation is pending, do not change the state
            state = next_state;
    end


    integer i;

    //Reset cache
    always @(posedge reset)
    begin
        if (reset) 
        begin
            for (i=0;i<8; i=i+1)
                valid[i] = 0;
            
            busywait = 0;
            // readaccess = 0;
            // writeaccess = 0;
        end
    end

endmodule