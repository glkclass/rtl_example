/******************************************************************************************************************************
    Project         :   usb_bridge_flash
    Creation Date   :   June 2024
    Description     :   Contain debug macros used.
******************************************************************************************************************************/


// ****************************************************************************************************************************
`ifndef USB_CDC_BRIDGE_SPI_FLASH_MACRO_SVH
`define USB_CDC_BRIDGE_SPI_FLASH_MACRO_SVH


`ifdef DUTB
    `define log_debug(a="",b=1)     log_debug(a,b)
    `define log_error(a="",b=1)     log_error(a,b,$sformatf("in \"%s\" Line %0d", `__FILE__, `__LINE__))
    `define log_fatal(a="")         log_fatal(a,$sformatf("in \"%s\" Line %0d", `__FILE__, `__LINE__))

`else 
    `define log_debug(a="",b=1)
    `define log_error(a="",b=1)
    `define log_fatal(a="")    
`endif

`endif
// ****************************************************************************************************************************

