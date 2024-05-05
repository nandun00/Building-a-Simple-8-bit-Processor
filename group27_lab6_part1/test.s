loadi 0 0x05   // r0 = 5
loadi 1 0x00  // r1 = 0
loadi 2 0x07 //r2 = 7
loadi 3 0x04  //r3 = 4

swd 0 1   // write value from reg 0 to the data address given by reg 1 mem[0] = 5

swi 2 0x04  // write value from reg 2 to the data address 0x04  mem[4] = 7

lwd 4 3 // read from address given in reg 3 and load that value to reg 4 = 7

lwi 5 0x00 //read memory address at 0x00 and load it the register 5 = 5

