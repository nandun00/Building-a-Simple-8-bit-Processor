loadi 0 0x05   // r0 = 5
loadi 1 0x09   // r1 = 9 
loadi 5 0x01   //r5 =1
or 7 0 1       //r7 = r0 | r1 = 13
mov 2 1        // r2 = r1=9
mov 6 1      //r6 = r1 = 9

beq 0x03 2 6 //branch to 3 ins forward

add 4 2 0      // r3 = r2 + r1 //skip
sub 4 3 1      // r4 = r3 - r1  //skip
add 3 2 5     // r3 = r2 +r5 = 9 +1  //skip

add 3 0 1     //5+9 =14

j 0x02        //jump 2 ins forward

loadi 0 0x75   // r0 = 0x75  //skip
loadi 1 0x92   // r1 = 0x92  //skip

loadi 0 0x02   //r0 =2
loadi 1 0x01   //r1 =1
and 5 1 0      // r5 = r1 & r0 0
or 7 0 1       // r7 = r1 | r2 3
sub 4 3 5     // r4 = 14-0
