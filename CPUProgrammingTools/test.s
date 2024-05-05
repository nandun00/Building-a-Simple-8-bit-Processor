loadi 1 0x01    // r1 = 1
loadi 2 0x05    // r2 = 5
loadi 3 0x09 // r3 = 9
swd 2 1 // store 5 in memory[1]
swd 3 2 // store 9 in memory[5]
lwd 4 1 // r4 = memory[1] = 5
lwi 1 0x05 // r4 = memory[5] = 9
lwi 3 0x05 // r3 = memory[5] = 9