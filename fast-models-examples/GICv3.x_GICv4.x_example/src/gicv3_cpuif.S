// ------------------------------------------------------------
// ARMv8-A AArch64 - GICv3 CPU interface functions
//
// Copyright (C) Arm Limited, 2019 All rights reserved.
//
// The example code is provided to you as an aid to learning when working
// with Arm-based technology, including but not limited to programming tutorials.
// Arm hereby grants to you, subject to the terms and conditions of this Licence,
// a non-exclusive, non-transferable, non-sub-licensable, free-of-charge licence,
// to use and copy the Software solely for the purpose of demonstration and
// evaluation.
//
// You accept that the Software has not been tested by Arm therefore the Software
// is provided “as is”, without warranty of any kind, express or implied. In no
// event shall the authors or copyright holders be liable for any claim, damages
// or other liability, whether in action or contract, tort or otherwise, arising
// from, out of or in connection with the Software or the use of Software.
//
// ------------------------------------------------------------


 
  .section  v8_aarch64_gicv3_cpuif,"ax"

// ------------------------------------------------------------

  .global setICC_SRE_EL1
  // void setICC_SRE_EL1(unsigned int value)
  .type setICC_SRE_EL1, @function
setICC_SRE_EL1:
  MSR   ICC_SRE_EL1, x0
  ISB
  RET

   

// ------------------------------------------------------------

  .global getICC_SRE_EL1
  // unsigned int getICC_SRE_EL1(void)
  .type getICC_SRE_EL1, @function
getICC_SRE_EL1:
  MRS   x0, ICC_SRE_EL1
  RET

   

// ------------------------------------------------------------

  .global setICC_SRE_EL2
  // void setICC_SRE_EL2(unsigned int value)
  .type setICC_SRE_EL2, @function
setICC_SRE_EL2:
  MSR   ICC_SRE_EL2, x0
  ISB
  RET

   

// ------------------------------------------------------------

  .global getICC_SRE_EL2
  // unsigned int getICC_SRE_EL2(void)
  .type getICC_SRE_EL2, @function
getICC_SRE_EL2:
  MRS   x0, ICC_SRE_EL2
  RET

   
  
// ------------------------------------------------------------

  .global setICC_SRE_EL3
  // void setICC_SRE_EL3(unsigned int value)
  .type setICC_SRE_EL3, @function
setICC_SRE_EL3:
  MSR   ICC_SRE_EL3, x0
  ISB
  RET

   

// ------------------------------------------------------------

  .global getICC_SRE_EL3
  // unsigned int getICC_SRE_EL3(void)
  .type getICC_SRE_EL3, @function
getICC_SRE_EL3:
  MRS   x0, ICC_SRE_EL3
  RET

   

// ------------------------------------------------------------

  .global enableGroup0Ints
  // void enableGroup0Ints(void)
  .type enableGroup0Ints, @function
enableGroup0Ints:
  MOV   w0, #1
  MSR   ICC_IGRPEN0_EL1, x0
  ISB
  RET

   

// ------------------------------------------------------------

  .global disableGroup0Ints
  // void disableGroup0Ints(void)
  .type disableGroup0Ints, @function
disableGroup0Ints:

  MOV   w0, #0
  MSR   ICC_IGRPEN0_EL1, x0
  ISB
  RET

   

// ------------------------------------------------------------

  .global enableGroup1Ints
  // void enableGroup1Ints((void)//
  .type enableGroup1Ints, @function
enableGroup1Ints:
  MRS   x0, ICC_IGRPEN1_EL1
  ORR   w0, w0, #1
  MSR   ICC_IGRPEN1_EL1, x0
  ISB
  RET
   

// ------------------------------------------------------------

  .global disableGroup1Ints
  // void disableGroup1Ints(void)//
  .type disableGroup1Ints, @function
disableGroup1Ints:
  MOV   w1, #1
  MRS   x0, ICC_IGRPEN1_EL1
  BIC   x0, x0, x1
  MSR   ICC_IGRPEN1_EL1, x0
  ISB
  RET
   
  
// ------------------------------------------------------------

  .global enableNSGroup1Ints
  // void enableNSGroup1Ints(void)
  .type enableNSGroup1Ints, @function
enableNSGroup1Ints:
  MRS   x0, ICC_IGRPEN1_EL3
  ORR   w0, w0, #1
  MSR   ICC_IGRPEN1_EL3, x0
  ISB
  RET

   

// ------------------------------------------------------------

  .global disableNSGroup1Ints
  // void disableNSGroup1Ints(void)
  .type disableNSGroup1Ints, @function
disableNSGroup1Ints:
  MOV   w1, #0x1
  MRS   x0, ICC_IGRPEN1_EL3
  BIC   x0, x0, x1
  MSR   ICC_IGRPEN1_EL3, x0
  ISB
  RET

   

// ------------------------------------------------------------

  .global getICC_CTLR_EL3
  // unsigned int getICC_CTLR_EL3(void)//
  .type getICC_CTLR_EL3, @function
getICC_CTLR_EL3:
  MRS   x0, ICC_CTLR_EL3
  RET
   

// ------------------------------------------------------------
  .global setICC_CTLR_EL3
  // void setICC_CTLR_EL3(unsigned int value)
  .type setICC_CTLR_EL3, @function
setICC_CTLR_EL3:
  MSR   ICC_CTLR_EL3, x0
  ISB
  RET

   

// ------------------------------------------------------------

  .global getICC_CTLR_EL1
  // unsigned int getICC_CTLR_EL1(void)//
  .type getICC_CTLR_EL1, @function
getICC_CTLR_EL1:
  MRS   x0, ICC_CTLR_EL1
  RET
   

// ------------------------------------------------------------

  .global setICC_CTLR_EL1
  // void setICC_CTLR_EL1(unsigned int value)
  .type setICC_CTLR_EL1, @function
setICC_CTLR_EL1:
  MSR   ICC_CTLR_EL1, x0
  ISB
  RET

   

// ------------------------------------------------------------

  .global readIARGrp0
  // unsigned int readIARGrp0(void)//
  .type readIARGrp0, @function
readIARGrp0:
  MRS   x0, ICC_IAR0_EL1
  RET
   

// ------------------------------------------------------------

  .global writeEOIGrp0
  // void writeEOIGrp0(unsigned int ID)//
  .type writeEOIGrp0, @function
writeEOIGrp0:
  MSR   ICC_EOIR0_EL1, x0
  ISB
  RET
   

// ------------------------------------------------------------

  .global writeDIR
  // void writeDIR(unsigned int ID)//
  .type writeDIR, @function
writeDIR:
  MSR   ICC_DIR_EL1, x0
  ISB
  RET


// ------------------------------------------------------------

  .global readIARGrp1
  // unsigned int readIARGrp1(void)//
  .type readIARGrp1, @function
readIARGrp1:
  MRS   x0, ICC_IAR1_EL1
  RET


// ------------------------------------------------------------

  .global writeEOIGrp1
  // void writeEOIGrp1(unsigned int ID)//
  .type writeEOIGrp1, @function
writeEOIGrp1:
  MSR   ICC_EOIR1_EL1, x0
  DSB   SY
  RET
   
  
// ------------------------------------------------------------

  .global setPriorityMask
  // void setPriorityMask(unsigned int ID)//
  .type setPriorityMask, @function
setPriorityMask:
  MSR   ICC_PMR_EL1, x0
  RET
   

// ------------------------------------------------------------

  .global getBPR0
  // unsigned int getBPR0(void)//
  .type getBPR0, @function
getBPR0:
  MRS   x0, ICC_BPR0_EL1
  RET
   

// ------------------------------------------------------------

  .global setBPR0
  // void setBPR0(unsigned int INTID)//
  .type setBPR0, @function
setBPR0:
  MSR   ICC_BPR0_EL1, x0
  ISB
  RET
   

// ------------------------------------------------------------

  .global getBPR1
  // unsigned int getBPR1(void)//
  .type getBPR1, @function
getBPR1:
  MRS   x0, ICC_BPR1_EL1
  RET
   

// ------------------------------------------------------------

  .global setBPR1
  // void setBPR1(unsigned int ID)//
  .type setBPR1, @function
setBPR1:
  MSR   ICC_BPR1_EL1, x0
  ISB
  RET
   

// ------------------------------------------------------------

  .global getRunningPriority
  // unsigned int getRunningPriority(void)//
  .type getRunningPriority, @function
getRunningPriority:
  MRS   x0, ICC_RPR_EL1
  RET
   

// ------------------------------------------------------------
// SGIs
// ------------------------------------------------------------

  .global sendGroup0SGI
  // void sendGroup0SGI(unsigned int ID, unsigned int mode, unsigned target_list)//
  .type sendGroup0SGI, @function
sendGroup0SGI:
  ORR   x0, x0, x1
  ORR   x0, x0, x2
  MSR   ICC_SGI0R_EL1, x0
  RET
   
  
// ------------------------------------------------------------

  .global sendGroup1SGI
  // void sendGroup1SGI(unsigned int ID, unsigned int mode, unsigned target_list)//
  .type sendGroup1SGI, @function
sendGroup1SGI:
  ORR   x0, x0, x1
  ORR   x0, x0, x2
  MSR   ICC_SGI1R_EL1, x0
  RET
   

// ------------------------------------------------------------

  .global sendOtherGroup1SGI
  // void sendOtherGroup1SGI(unsigned int ID, unsigned int mode, unsigned target_list)//
  .type sendOtherGroup1SGI, @function
sendOtherGroup1SGI:
  ORR   x0, x0, x1
  ORR   x0, x0, x2
  MSR   ICC_ASGI1R_EL1, x0
  RET
   


// ------------------------------------------------------------
// End of code
// ------------------------------------------------------------

 
// ------------------------------------------------------------
// End of v8_aarch64_gicv3_cpuif.s
// ------------------------------------------------------------
