
module instruction_cache(
    clock, 
    reset,
    pc,
    busywait,
    instruction,

    mem_busywait,
    mem_read,
    mem_readdata,
    mem_readaddress

);
    input clock;
    input reset;
    input[31:0] pc;
    output reg busywait;   // ?
    output reg[31:0] instruction;

    input mem_busywait;
    output reg mem_read;
    input[127:0] mem_readdata;
    output reg[5:0] mem_readaddress;

    reg[24:0] tag;   // 25 bit tag
    reg[2:0] index;  // 3 bit index
    reg[1:0] offset; // 2 bit offset
    reg hit;

    reg[24:0] tag_array[7:0];
    reg[7:0] valid;
    reg[127:0] data_block[7:0];

    reg[24:0] tag_from_cache;
    reg valid_bit_from_cache;
    reg[127:0] data_block_from_cache;


    always @(pc) 
    begin
        tag = pc[31:7];
        index = pc[6:4];
        offset = pc[3:2];   // least 2 bits discarded, incremented by 4        
    end


    always @(*) // extracting stored values
    begin
        tag_from_cache = tag_array[index];
        valid_bit_from_cache = valid[index];
        #1
        data_block_from_cache = data_block[index]; // extracting data block parallel to tag comparison
    end

    always @(*)  // cache read hit
    begin
        if(hit)
        begin
            #1
            case(offset)  // selecting correct data word
                2'b00 : instruction = data_block_from_cache[31:0];
                2'b01 : instruction = data_block_from_cache[63:32];
                2'b10 : instruction = data_block_from_cache[95:64];
                2'b11 : instruction = data_block_from_cache[127:96];
            endcase 
            hit = 1'bx; // if we do not make this x, the next instruction is sensitive to hit, so there will not be a #2 time unit delay
        end
    end

    always @(*) 
    begin 
        #1
        if($signed(pc) < $signed(32'd0)) // skipping the -4 value of pc 
            hit = 1'bx; // neither hit or miss
        else if(tag_from_cache == tag && valid_bit_from_cache)  // comparing tag and checking valid bit
            hit = 1;
        else 
            hit = 0;    
    end


    always @(posedge clock)
    begin
        if(hit && !mem_busywait) // in the event of hit and there is no instruction memory access, no need to stall the cpu
            busywait = 0;
    end

    /* fsm for instruction cache control */

    parameter IDLE_STATE = 2'b00, MEM_READ_STATE = 2'b01,
                WRITE_TO_CACHE_ON_MISS = 2'b11;

    reg[1:0] state, next_state;

    always @(*)
    begin
        case(state)
            IDLE_STATE:
                begin
                    if(!hit) // if any kind of miss happens go to instruction memory read state
                        next_state = MEM_READ_STATE;
                    else 
                        next_state = IDLE_STATE;
                end
            MEM_READ_STATE: // after instruction memory read, write to instruction cache
                begin
                    next_state = WRITE_TO_CACHE_ON_MISS;
                end
            WRITE_TO_CACHE_ON_MISS: // after write to cache, go to idle
                begin
                    next_state = IDLE_STATE;
                end
        endcase
    end


    // state definition
    always @(*)
    begin
        case(state)
            IDLE_STATE :
                begin
                    mem_readaddress = 6'dx; // no read happens
                    mem_read = 0;
                    busywait = 0;
                end

            MEM_READ_STATE :
                begin
                    mem_readaddress = {tag[2:0], index}; // read using 6 bit block address
                    mem_read = 1;
                    busywait = 1;
                end

            WRITE_TO_CACHE_ON_MISS : 
                begin
                    if(!hit) 
                    begin
                        #1
                        data_block[index] = mem_readdata; // write the read data to cache
                        tag_array[index] = tag; 
                        busywait = 1;   
                        valid[index] = 1;
                    end
                end
        endcase
    end



    // state transition


    always @(posedge clock, reset)
    begin
        if(reset) 
            state = IDLE_STATE;
        else if(!mem_busywait) // if there is no memory reading, go to next state
            state = next_state;
    end

    integer i;

    always @(posedge reset) 
    begin
        if(reset) 
        begin
            for(i=0; i<8; i=i+1)
                valid[i] = 0;

            busywait = 0; 
        end

    end

endmodule
