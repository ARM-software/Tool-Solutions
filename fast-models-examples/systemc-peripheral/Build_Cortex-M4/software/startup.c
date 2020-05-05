/*
** Copyright (c) 2018 Arm Limited. All rights reserved.
*/

// Initial Setup
//----------------------------------------------------------------
extern unsigned int Image$$ARM_LIB_STACKHEAP$$ZI$$Limit;            /* for (default) One Region model */
typedef void(* const ExecFuncPtr)(void) __attribute__((interrupt)); /* typedef for the function pointers in the vector table */
extern int __main(void);


// Reset Handler
//---------------------------------------------------------------- 
__attribute__((interrupt))          void ResetHandler(void)
{    
    __main();
}

// Exception Vector Table & Handlers
//----------------------------------------------------------------
__attribute__((interrupt))          void NMIException(void)          {while(1);}
__attribute__((interrupt))          void HardFaultException(void)    {while(1);}
__attribute__((interrupt))          void SVCHandler(void)            {while(1);}
__attribute__((interrupt))          void PendSVC(void)               {while(1);}
__attribute__((interrupt))          void InterruptHandler(void)      {while(1);}

ExecFuncPtr vector_table[] __attribute__((section("BOOT"))) = {   
    (ExecFuncPtr)&Image$$ARM_LIB_STACKHEAP$$ZI$$Limit,  // initial SP       
    ResetHandler,                                       // initial PC/Reset         
    NMIException,                                       
    HardFaultException,                                 
    0,                                                  // Memory Manage Fault 
    0,                                                  // Bus Fault           
    0,                                                  // Usage Fault         
    0,                                                  // RESERVED                         
    0,                                                  // RESERVED                 
    0,                                                  // RESERVED                
    0,                                                  // RESERVED             
    SVCHandler,                                         
    0,                                                  // RESERVED for debug        
    0,                                                  // RESERVED              
    PendSVC,                                            
    InterruptHandler,                                   
    InterruptHandler,                                  
    InterruptHandler,                                   
    InterruptHandler,                                   
    InterruptHandler
};
