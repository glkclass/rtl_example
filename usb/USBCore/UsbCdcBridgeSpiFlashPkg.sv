/******************************************************************************************************************************
    Project         :   bridge_spi_flash
    Creation Date   :   Jun 2024
    Package         :   bridge_spi_flash_pkg
    Description     :   Params
******************************************************************************************************************************/


// ****************************************************************************************************************************
package UsbCdcBridgeSpiFlashPkg;

    `include "UsbCdcBridgeSpiFlashMacro.svh"
`ifdef DUTB
    import dutb_util_pkg::*;
`endif

    parameter
        BYTE_WIDTH                      =   8,
        SPI_BIT_WIDTH                   =   8,
        SPI_BYTE_WIDTH                  =   (BYTE_WIDTH * SPI_BIT_WIDTH),

        BRIDGE_PACKET_SIZE              =   8,      //  Size of 'bridge cmd_packet' which is used for bridge <-> host communicattion
        BRIDGE_PACKET_HEADER            =   8'h5A,  // 1 byte header of input 'bridge cmd_packet'

        FLASH_PAGE_SIZE                 =   256,
        MAX_FLASH_PACKET_SIZE           =   (FLASH_PAGE_SIZE + 4),


        USB_CDC_READY_RATE              =   39,     // pause between USB CDC send/recieve transactions (in clk cycles)

        // Bridge command
        READ_BRIDGE_STATUS_REG_BCMD     =   3'h1,
        EXECUTE_FLASH_WR_REG_BCMD       =   3'h2,
        EXECUTE_FLASH_PROGRAM_MEM_BCMD  =   3'h3,
        EXECUTE_FLASH_RD_REG_BCMD       =   3'h4,
        EXECUTE_FLASH_RD_MEM_BCMD       =   3'h5,
        RESERVE_0                       =   3'h6,
        RESERVE_1                       =   3'h7,
        RESERVE_2                       =   3'h0,



        
        // Length of flash spi cmd_packet in bytes (including cmd byte)

        //  EXECUTE_FLASH_WR_REG_BCMD: Write 1 Byte command
        //  EXECUTE_FLASH_RD_REG_BCMD: Forbidden
        L_1B                            =   5'h01,

        //  EXECUTE_FLASH_WR_REG_BCMD: Write 1 Byte command, Write 1 Byte data
        //  EXECUTE_FLASH_RD_REG_BCMD: Write 1 Byte command, Read 1 Bytes data
        L_2B                            =   5'h02,
        
        L_3B                            =   5'h03,
        L_4B                            =   5'h04,
        L_5B                            =   5'h05,
        L_21B                           =   5'h06,        
        L_256B                          =   5'h1F,

        //  Flash command
        RESET_ENABLE                                    =   8'h66,
        RELEASE_FROM_DEEP_POWER_DOWN                    =   8'hAB,
        WRITE_ENABLE                                    =   8'h06,
        WRITE_DISABLE                                   =   8'h04,
        BULK_ERASE                                      =   8'hC7,
        ENTER_4B_ADDRESS_MODE                           =   8'hB7,
        EXIT_4B_ADDRESS_MODE                            =   8'hE9,

        //  Write reg
        WRITE_STATUS_REGISTER                           =   8'h01,
        WRITE_VOLATILE_CONFIGURATION_REGISTER           =   8'h81,
        WRITE_NONVOLATILE_CONFIGURATION_REGISTER        =   8'hB1,

        //  Read reg
        READ_STATUS_REGISTER                            =   8'h05,
        READ_FLAG_STATUS_REGISTER                       =   8'h70,
        READ_VOLATILE_CONFIGURATION_REGISTER            =   8'h85,
        READ_NONVOLATILE_CONFIGURATION_REGISTER         =   8'hB5,
        READ_ID                                         =   8'h9E,

        // Mem program
        PAGE_PROGRAM_4B                                 =   8'h12,

        SECTOR_64KB_ERASE_4B                            =   8'hDC,
        SUBSECTOR_32KB_ERASE_4B                         =   8'h5C,
        SUBSECTOR_4KB_ERASE_4B                          =   8'h21,

        // Read mem
        READ_MEM_4B                                     =   8'h13,

        FOO                                             =   8'h45;


typedef     byte    t_cmd_packet[BRIDGE_PACKET_SIZE];

typedef     byte    t_mem_data[FLASH_PAGE_SIZE];


typedef struct {
    t_cmd_packet        cmd_packet;
    t_mem_data          mem_data;
    byte                mem_data_crc;
    int                 mem_data_size, data_in_len, data_out_len;
    } t_bridge_txn;

t_bridge_txn    txns[byte] = {

        // header,                          bcmd,                                       fcmd,                                       addr_h/data_l ... addr_l/data_l     crc;
    8'hFF: {
        cmd_packet: {BRIDGE_PACKET_HEADER,  {5'hXX, READ_BRIDGE_STATUS_REG_BCMD},       8'hXX,                                      8'hXX, 8'hXX, 8'hXX, 8'hXX,         8'h53},
        mem_data:{default:0}, mem_data_size:0, mem_data_crc: 8'h37,
        data_in_len: 0, data_out_len: 0},

    RESET_ENABLE: {
        cmd_packet:{BRIDGE_PACKET_HEADER,   {L_1B, EXECUTE_FLASH_WR_REG_BCMD},          RESET_ENABLE,                               8'hXX, 8'hXX, 8'hXX, 8'hXX,         8'h53},
        mem_data:{default:0}, mem_data_size:0, mem_data_crc: 8'h37,
        data_in_len:0, data_out_len:0},

    WRITE_ENABLE: {
        cmd_packet:{BRIDGE_PACKET_HEADER,   {L_1B, EXECUTE_FLASH_WR_REG_BCMD},          WRITE_ENABLE,                               8'hXX, 8'hXX, 8'hXX, 8'hXX,         8'h53},
        mem_data:{default:0}, mem_data_size:0, mem_data_crc: 8'h37,
        data_in_len:0, data_out_len:0},

    WRITE_DISABLE: {
        cmd_packet:{BRIDGE_PACKET_HEADER,   {L_1B, EXECUTE_FLASH_WR_REG_BCMD},          WRITE_DISABLE,                              8'hXX, 8'hXX, 8'hXX, 8'hXX,         8'h53},
        mem_data:{default:0}, mem_data_size:0, mem_data_crc: 8'h37,
        data_in_len:0, data_out_len:0},

    WRITE_STATUS_REGISTER: {
        cmd_packet:{BRIDGE_PACKET_HEADER,   {L_2B, EXECUTE_FLASH_WR_REG_BCMD},          WRITE_STATUS_REGISTER,                      8'h57, 8'hXX, 8'hXX, 8'hXX,         8'h53},
        mem_data:{default:0}, mem_data_size:0, mem_data_crc: 8'h37,
        data_in_len:1, data_out_len:0},

    WRITE_VOLATILE_CONFIGURATION_REGISTER: {
        cmd_packet:{BRIDGE_PACKET_HEADER,   {L_2B, EXECUTE_FLASH_WR_REG_BCMD},          WRITE_VOLATILE_CONFIGURATION_REGISTER,      8'h57, 8'hXX, 8'hXX, 8'hXX,         8'h53},
        mem_data:{default:0}, mem_data_size:0, mem_data_crc: 8'h37,
        data_in_len:1, data_out_len:0},

    WRITE_NONVOLATILE_CONFIGURATION_REGISTER: {
        cmd_packet:{BRIDGE_PACKET_HEADER,   {L_3B, EXECUTE_FLASH_WR_REG_BCMD},          WRITE_NONVOLATILE_CONFIGURATION_REGISTER,   8'h57, 8'h75, 8'hXX, 8'hXX,         8'h53},
        mem_data:{default:0}, mem_data_size:0, mem_data_crc: 8'h37,
        data_in_len:2, data_out_len:0},

    READ_STATUS_REGISTER: {
        cmd_packet:{BRIDGE_PACKET_HEADER,   {L_2B, EXECUTE_FLASH_RD_REG_BCMD},          READ_STATUS_REGISTER,                       8'hXX, 8'hXX, 8'hXX, 8'hXX,         8'h53},
        mem_data:{default:0}, mem_data_size:0, mem_data_crc: 8'h37,
        data_in_len:0, data_out_len:1},

    READ_NONVOLATILE_CONFIGURATION_REGISTER: {
        cmd_packet:{BRIDGE_PACKET_HEADER,   {L_3B, EXECUTE_FLASH_RD_REG_BCMD},          READ_NONVOLATILE_CONFIGURATION_REGISTER,    8'hXX, 8'hXX, 8'hXX, 8'hXX,         8'h53},
        mem_data:{default:0}, mem_data_size:0, mem_data_crc: 8'h37,
        data_in_len:0, data_out_len:2},

    PAGE_PROGRAM_4B: {
        cmd_packet:{BRIDGE_PACKET_HEADER,   {L_256B, EXECUTE_FLASH_PROGRAM_MEM_BCMD},   PAGE_PROGRAM_4B,                        8'h01, 8'h02, 8'h03, 8'h04,         8'h53},
        mem_data:{default:0}, mem_data_size:0, mem_data_crc: 8'h37,
        data_in_len:(4 + 256), data_out_len:0},
    
    READ_MEM_4B: {
        cmd_packet:{BRIDGE_PACKET_HEADER,   {L_256B, EXECUTE_FLASH_RD_MEM_BCMD},        READ_MEM_4B,                                8'h02, 8'h03, 8'h04, 8'h05,         8'h53},
        mem_data:{default:0}, mem_data_size:0, mem_data_crc: 8'hxx,
        data_in_len:4, data_out_len:256}
        

        // header,                          bcmd,                                       fcmd,                                       addr_h/data_l ... addr_l/data_l     crc;
    };

function bit cmd_is_correct(byte cmd);
    return (txns.exists(cmd));
endfunction
   
function int get_cmd_data_in_len(byte cmd);
    int foo;
    assert(txns.exists(cmd)) else `log_fatal("Txn doesn't exist");
    foo = txns[cmd].data_in_len;
    assert(foo >= 0 && foo <= (256 + 4)) else `log_fatal($sformatf("Wrong Txn data_in_len: %0d", foo));
    return (foo);
endfunction

function int get_cmd_data_out_len(byte cmd);
    int foo;
    assert(txns.exists(cmd)) else `log_fatal("Txn doesn't exist");
    foo = txns[cmd].data_out_len;
    assert(foo >= 0 && foo <= 256) else `log_fatal($sformatf("Wrong Txn data_in_len: %0d", foo));
    return (foo);
endfunction

endpackage  
// ****************************************************************************************************************************
    
