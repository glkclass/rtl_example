//-----------------------------------------------------------------------------------------------------------------------------
// Module   : bridge_spi_flash
// Type     : synthesizable
// Standard : SystemVerilog
//-----------------------------------------------------------------------------------------------------------------------------

import UsbCdcBridgeSpiFlashPkg::*;

`include "UsbCdcBridgeSpiFlashMacro.svh"


// ============================================================================================================================
module SpiFlashFace (
    input   
        logic                                   clk, rst_n,

    // fifo -> bridge
    input   logic   [9  :   0]                  rx_fifo_size,
    input   logic   [BYTE_WIDTH- 1      :   0]  rx_fifo_data,
    input   logic                               rx_fifo_valid,
    output  reg                                 rx_fifo_rd_en,


    // bridge -> fifo
    input   logic   [9  :   0]                  tx_fifo_size,
    output  logic   [BYTE_WIDTH- 1      :   0]  tx_fifo_data,
    output  logic                               tx_fifo_valid,
    input   logic                               tx_fifo_full,


    // SPI User Flash -----------------------------------------
    output  reg                                 spi_sck,
                                                spi_cs,
    output  reg                                 spi_sio_0,
    input   logic                               spi_sio_1
    // End ----------------------------------------------------
);
// ============================================================================================================================

    // params
        localparam
            BRIDGE_IN_PACKET_SIZE               =   8,      // size of input 'bridge packet'
            BRIDGE_IN_PACKET_N_REGS             =   6,      // number of stored regs from input 'bridge packet'

            BRIDGE_OUT_PACKET_SIZE              =   2,      // size of output 'bridge packet' wo crc byte

            // 
            BRIDGE_STATUS_REG_FAULT_OFFSET      =   7,

            // 
            FSM_WIDTH                           =   5;




        typedef enum reg [FSM_WIDTH - 1   :   0] {
            IDLE_ST,
            INIT_ST,
            READ_CMD_PACKET_ST,
            ANALYZE_CMD_PACKET_ST,
            RETURN_BRIDGE_STATUS_REG_ST,
            
            EXECUTE_FLASH_WR_REG_ST,
            EXECUTE_FLASH_RD_REG_ST,
            WAIT_FOR_MEM_PACKET_READY_ST,
            EXECUTE_FLASH_PROGRAM_MEM_ST,
            EXECUTE_FLASH_RD_MEM_ST,

            CHECK_MEM_PACKET_CRC_ST,
            RETURN_BRIDGE_STATUS_REG_AND_CRC_ST,
            FINISH_ST,
            FAULT_ST 
        } t_fsm_states;



        
    // logic
        t_fsm_states                                            pr_state, next_state;

        logic                                                   spi_cs_f;
        
        logic   [BYTE_WIDTH - 1 :   0]                          bridge_status_reg,
                                                                packet_flash_addr_0,
                                                                packet_flash_addr_1,
                                                                packet_flash_addr_2,
                                                                packet_flash_addr_3,
                                                                packet_flash_cmd,
                                                                packet_flash_cmd_shifted,
                                                                flash_response;

        logic   [2              :   0]                          packet_bridge_cmd;
        logic   [4              :   0]                          packet_flash_wr_rd_len;            //  packet field to define flash read out length (in bytes)
        
        //  flash write-in/read-out packet length (in bits):    256 x BYTE_WIDTH(8) x SPI_BIT_WIDTH(8)
        logic   [14             :   0]                          
                                                                cnt,
                                                                spi_bit_cnt,
                                                                flash_packet_len,
                                                                flash_packet_len_r;   

        logic   [BRIDGE_IN_PACKET_N_REGS * BYTE_WIDTH - 1  :   0]  bridge_packet_regs;

        logic   [BYTE_WIDTH - 1  :   0]                         crc;


        // FSM stage flags
        logic
                                                                bridge_idle,
                                                                bridge_init,
                                                                bridge_finish,
                                                                bridge_fault_detected,

                                                                read_cmd_packet,
                                                                analyze_cmd_packet,
                                                                
                                                                return_bridge_status_reg,
                                                                execute_flash_wr_reg,
                                                                wait_for_mem_packet_ready,
                                                                execute_flash_program_mem,
                                                                execute_flash_rd_reg,
                                                                execute_flash_rd_mem,
                                                                check_mem_packet_crc,
                                                                return_bridge_status_reg_and_crc;


        logic    
                                                                rx_fifo_contain_cmd_packet,
                                                                rx_fifo_contain_mem_packet,
                                                                packet_header_error,
                                                                packet_crc_error,
                                                                packet_cmd_error,
                                                                bcmd_packet_store,

                                                                cnt_en;

// ============================================================================================================================

    //          
        assign  crc                             =   8'h35;
        assign  packet_crc_error                =   1'b0;
        assign  packet_cmd_error                =   1'b0;

        assign  packet_flash_addr_0             =   bridge_packet_regs[BYTE_WIDTH - 1       :   0];                     // 8 bits
        assign  packet_flash_addr_1             =   bridge_packet_regs[BYTE_WIDTH * 2 - 1   :   BYTE_WIDTH];            // 8 bits
        assign  packet_flash_addr_2             =   bridge_packet_regs[BYTE_WIDTH * 3 - 1   :   BYTE_WIDTH * 2];        // 8 bits
        assign  packet_flash_addr_3             =   bridge_packet_regs[BYTE_WIDTH * 4 - 1   :   BYTE_WIDTH * 3];        // 8 bits
        assign  packet_flash_cmd                =   bridge_packet_regs[BYTE_WIDTH * 5 - 1   :   BYTE_WIDTH * 4];        // 8 bits
        assign  packet_flash_cmd_shifted        =   {spi_sio_0, bridge_packet_regs[BYTE_WIDTH * 5 - 1   :   BYTE_WIDTH * 4 + 1]};        // 8 bits

        assign  packet_flash_wr_rd_len          =   bridge_packet_regs[BYTE_WIDTH * 6 - 1   :   BYTE_WIDTH * 6 - 5 ];   // high 5 bits
        assign  packet_bridge_cmd               =   bridge_packet_regs[BYTE_WIDTH * 6 - 6   :   BYTE_WIDTH * 5];        // low 3 bits

 
        assign  flash_packet_len                =   (EXECUTE_FLASH_WR_REG_BCMD      == packet_bridge_cmd        && L_1B     == packet_flash_wr_rd_len) ?    SPI_BYTE_WIDTH - 1  : 
                                                    (EXECUTE_FLASH_WR_REG_BCMD      == packet_bridge_cmd        && L_2B     == packet_flash_wr_rd_len) ?    SPI_BYTE_WIDTH * 2 - 1  : 
                                                    (EXECUTE_FLASH_WR_REG_BCMD      == packet_bridge_cmd        && L_3B     == packet_flash_wr_rd_len) ?    SPI_BYTE_WIDTH * 3 - 1  : 
                                                    (EXECUTE_FLASH_WR_REG_BCMD      == packet_bridge_cmd        && L_4B     == packet_flash_wr_rd_len) ?    SPI_BYTE_WIDTH * 4 - 1  : 
                                                    (EXECUTE_FLASH_WR_REG_BCMD      == packet_bridge_cmd        && L_5B     == packet_flash_wr_rd_len) ?    SPI_BYTE_WIDTH * 5 - 1  :                                                     
                                                    (EXECUTE_FLASH_RD_REG_BCMD      == packet_bridge_cmd        && L_2B     == packet_flash_wr_rd_len) ?    SPI_BYTE_WIDTH * 2 - 1  : 
                                                    (EXECUTE_FLASH_RD_REG_BCMD      == packet_bridge_cmd        && L_3B     == packet_flash_wr_rd_len) ?    SPI_BYTE_WIDTH * 3 - 1  : 
                                                    (EXECUTE_FLASH_RD_REG_BCMD      == packet_bridge_cmd        && L_4B     == packet_flash_wr_rd_len) ?    SPI_BYTE_WIDTH * 4 - 1  : 
                                                    (EXECUTE_FLASH_RD_REG_BCMD      == packet_bridge_cmd        && L_5B     == packet_flash_wr_rd_len) ?    SPI_BYTE_WIDTH * 5 - 1  : 
                                                    (EXECUTE_FLASH_RD_REG_BCMD      == packet_bridge_cmd        && L_21B    == packet_flash_wr_rd_len) ?    SPI_BYTE_WIDTH * 21 - 1  : 
                                                    (EXECUTE_FLASH_PROGRAM_MEM_BCMD == packet_bridge_cmd        && L_256B   == packet_flash_wr_rd_len) ?    SPI_BYTE_WIDTH * (1 + 4 + FLASH_PAGE_SIZE) - 1  : 
                                                    (EXECUTE_FLASH_RD_MEM_BCMD      == packet_bridge_cmd        && L_256B   == packet_flash_wr_rd_len) ?    SPI_BYTE_WIDTH * (1 + 4 + FLASH_PAGE_SIZE) - 1  : 
                                                                                                                                                            SPI_BYTE_WIDTH - 1;



        assign  rx_fifo_contain_cmd_packet  =   (BRIDGE_IN_PACKET_SIZE <= rx_fifo_size)                     ? 1'b1 : 1'b0;

        assign  rx_fifo_contain_mem_packet  =   (FLASH_PAGE_SIZE <= rx_fifo_size)                           ? 1'b1 : 1'b0;

        assign  bcmd_packet_store           =   (0 < cnt && BRIDGE_IN_PACKET_SIZE - 1  > cnt)               ? 1'b1 : 1'b0;   

        assign  rx_fifo_rd_en               =   (read_cmd_packet    ||
                                                (1'b1 == execute_flash_program_mem && 
                                                5*BYTE_WIDTH  <= spi_bit_cnt && 
                                                3'h0  == spi_bit_cnt[2:0] && 
                                                3'h1 == cnt[2 : 0]))                                        ? 1'b1 :1'b0;
                                                

        assign  tx_fifo_data            =   (~tx_fifo_valid)                                                                                        ?   8'hXX : 
                                            (1'b1 == return_bridge_status_reg)                                                                      ?   BRIDGE_PACKET_HEADER :
                                            (1'b1 == return_bridge_status_reg_and_crc               && 0 == cnt)                                    ?   bridge_status_reg :
                                            (1'b1 == return_bridge_status_reg_and_crc               && 1 == cnt)                                    ?   crc :

                                            (1'b1 ==    (execute_flash_wr_reg | execute_flash_program_mem |
                                                        execute_flash_rd_reg | execute_flash_rd_mem)
                                                        && 0 == cnt)                                                                                ?   BRIDGE_PACKET_HEADER :
                                            
                                            (1'b1 ==    (execute_flash_wr_reg | execute_flash_program_mem |
                                                        execute_flash_rd_reg | execute_flash_rd_mem)
                                                        && 1 == cnt)                                                                                ?   {packet_flash_wr_rd_len, packet_bridge_cmd} :
                                            
                                            (1'b1 ==    (execute_flash_wr_reg | execute_flash_program_mem |
                                                        execute_flash_rd_reg | execute_flash_rd_mem)
                                                        && 2 == cnt)                                                                                ?   packet_flash_cmd_shifted :
                                            
                                            (1'b1 == execute_flash_rd_reg   && BYTE_WIDTH < spi_bit_cnt 
                                            && 3'h0 == spi_bit_cnt[2 : 0]   && 3'h7 == cnt[2:0])                                                    ?   flash_response :
                                            
                                            (1'b1 == execute_flash_rd_mem   && 5*BYTE_WIDTH < spi_bit_cnt 
                                            && 3'h0 == spi_bit_cnt[2 : 0]   && 3'h7 == cnt[2:0])                                                    ?   flash_response : 8'hXX;
                                            

        assign  tx_fifo_valid           =   ((1'b1  == (return_bridge_status_reg | return_bridge_status_reg_and_crc))                               ||

                                            (1'b1   == (execute_flash_wr_reg | execute_flash_program_mem | 
                                                        execute_flash_rd_reg | execute_flash_rd_mem) 
                                                        && 3 > cnt)                                                                                 ||
                                            
                                            (1'b1   == execute_flash_rd_reg    && BYTE_WIDTH < spi_bit_cnt 
                                            && 3'h0 == spi_bit_cnt[2 : 0]  && 3'h7 == cnt[2:0])                                                     ?   1'b1 :

                                            (1'b1   == execute_flash_rd_mem    && 5*BYTE_WIDTH < spi_bit_cnt 
                                            && 3'h0 == spi_bit_cnt[2 : 0]  && 3'h7 == cnt[2:0]))                                                    ?   1'b1 : 1'b0;




        assign  cnt_en                  =   (rst_n & ~bridge_idle & (pr_state == next_state))                                                       ?   1'b1 : 1'b0;

    // 
        // FSM main
        always @ (  pr_state,
                    rx_fifo_contain_cmd_packet,
                    rx_fifo_contain_mem_packet,
                    cnt,
                    packet_header_error,
                    packet_crc_error,
                    packet_cmd_error,
                    packet_bridge_cmd,
                    packet_flash_cmd) 
            begin
                // cnt_en                              =   1'b0;

                bridge_idle                         =   1'b0;
                bridge_init                         =   1'b0;
                bridge_finish                       =   1'b0;
                bridge_fault_detected               =   1'b0;
                
                read_cmd_packet                     =   1'b0;
                analyze_cmd_packet                  =   1'b0;
                return_bridge_status_reg            =   1'b0;
                execute_flash_wr_reg                =   1'b0;
                execute_flash_program_mem           =   1'b0;
                wait_for_mem_packet_ready           =   1'b0;
                execute_flash_rd_reg                =   1'b0;
                execute_flash_rd_mem                =   1'b0;
                check_mem_packet_crc                =   1'b0;

                return_bridge_status_reg_and_crc    =   1'b0;

                `log_debug($sformatf("%s", pr_state.name()), 0);

                case(pr_state)
                    IDLE_ST:   
                        begin
                            if (1'b1 == rx_fifo_contain_cmd_packet)
                                begin
                                    next_state  = INIT_ST;
                                end
                            else
                                begin
                                    next_state  = IDLE_ST;
                                end
                            bridge_idle                 =   1'b1;
                        end

                    INIT_ST:   
                        begin
                            `log_debug($sformatf("%s", pr_state.name()), 1);
                            next_state              = READ_CMD_PACKET_ST;
                            bridge_init             =   1'b1;
                        end

                    READ_CMD_PACKET_ST:   
                        begin
                            if ((BRIDGE_IN_PACKET_SIZE - 1) == cnt) 
                                begin
                                    next_state      = ANALYZE_CMD_PACKET_ST;
                                end
                            else
                                begin
                                    next_state      = READ_CMD_PACKET_ST;
                                end
                            read_cmd_packet         =   1'b1;
                        end

                    ANALYZE_CMD_PACKET_ST:   
                        begin
                            `log_debug($sformatf("%s:\t%Xh_%Xh_%Xh_%Xh", pr_state.name(), packet_bridge_cmd, packet_flash_cmd, flash_packet_len, packet_header_error | packet_crc_error | packet_cmd_error));

                            if (packet_header_error | packet_crc_error | packet_cmd_error )
                                begin
                                    `log_error("Packet content error");
                                    next_state = FAULT_ST;
                                end
                            else 
                                begin
                                    case (packet_bridge_cmd)
                                        READ_BRIDGE_STATUS_REG_BCMD:
                                            begin
                                                next_state = RETURN_BRIDGE_STATUS_REG_ST;
                                            end

                                        EXECUTE_FLASH_WR_REG_BCMD:
                                            begin
                                                if ((RESET_ENABLE                               == packet_flash_cmd)    ||
                                                    (RELEASE_FROM_DEEP_POWER_DOWN               == packet_flash_cmd)    ||
                                                    (WRITE_ENABLE                               == packet_flash_cmd)    ||
                                                    (WRITE_DISABLE                              == packet_flash_cmd)    ||
                                                    (ENTER_4B_ADDRESS_MODE                      == packet_flash_cmd)    ||
                                                    (EXIT_4B_ADDRESS_MODE                       == packet_flash_cmd)    ||

                                                    (SECTOR_64KB_ERASE_4B                       == packet_flash_cmd)    ||
                                                    (SUBSECTOR_4KB_ERASE_4B                     == packet_flash_cmd)    ||
                                                    (SUBSECTOR_32KB_ERASE_4B                    == packet_flash_cmd)    ||
                                                    
                                                    (WRITE_STATUS_REGISTER                      == packet_flash_cmd)    ||
                                                    (WRITE_VOLATILE_CONFIGURATION_REGISTER      == packet_flash_cmd)    ||
                                                    (WRITE_NONVOLATILE_CONFIGURATION_REGISTER   == packet_flash_cmd)    ||
                                                    (BULK_ERASE                                 == packet_flash_cmd))

                                                    begin
                                                        next_state = EXECUTE_FLASH_WR_REG_ST;
                                                    end
                                                else
                                                    begin
                                                        `log_error("Packet content error: wrong flash cmd");
                                                        next_state = FAULT_ST;
                                                    end 
                                                
                                            end

                                        EXECUTE_FLASH_RD_REG_BCMD:
                                            begin
                                                if ((READ_ID                                    == packet_flash_cmd)    ||
                                                    (READ_STATUS_REGISTER                       == packet_flash_cmd)    ||
                                                    (READ_FLAG_STATUS_REGISTER                  == packet_flash_cmd)    ||
                                                    (READ_VOLATILE_CONFIGURATION_REGISTER       == packet_flash_cmd)    || 
                                                    (READ_NONVOLATILE_CONFIGURATION_REGISTER    == packet_flash_cmd))
                                                    begin
                                                        next_state = EXECUTE_FLASH_RD_REG_ST;
                                                    end
                                                else
                                                    begin
                                                        `log_error("Packet content error: wrong flash cmd");
                                                        next_state = FAULT_ST;
                                                    end 
                                                
                                            end


                                        EXECUTE_FLASH_PROGRAM_MEM_BCMD:
                                            begin
                                                if (PAGE_PROGRAM_4B                         == packet_flash_cmd)
                                                    begin
                                                        next_state = WAIT_FOR_MEM_PACKET_READY_ST;
                                                    end
                                                else
                                                    begin
                                                        `log_error("Packet content error: wrong flash cmd");
                                                        next_state = FAULT_ST;
                                                    end
                                            end

                                        EXECUTE_FLASH_RD_MEM_BCMD:
                                            begin
                                                if (READ_MEM_4B                             == packet_flash_cmd)
                                                    begin
                                                        next_state = EXECUTE_FLASH_RD_MEM_ST;
                                                    end
                                                else
                                                    begin
                                                        `log_error("Packet content error: wrong flash cmd");
                                                        next_state = FAULT_ST;
                                                    end
                                            end


                                        default : 
                                            begin
                                                `log_error("Packet content error: wrong bcmd");
                                                next_state = FAULT_ST;
                                            end
                                    endcase

                                end

                            analyze_cmd_packet          =   1'b1;
                        end

                    RETURN_BRIDGE_STATUS_REG_ST: 
                        begin
                            // actually we only send a packet header here, bridge status reg and crc are send in couple during appropriate state
                            `log_debug($sformatf("%s", pr_state.name()), 1);
                            next_state      = RETURN_BRIDGE_STATUS_REG_AND_CRC_ST;
                            return_bridge_status_reg            =   1'b1;
                        end

                    EXECUTE_FLASH_WR_REG_ST: 
                        begin
                            if (flash_packet_len_r == cnt) 
                                begin
                                    `log_debug($sformatf("%s", pr_state.name()), 1);
                                    next_state                  = RETURN_BRIDGE_STATUS_REG_AND_CRC_ST;
                                end
                            else
                                begin
                                    next_state                  = EXECUTE_FLASH_WR_REG_ST;
                                end

                            execute_flash_wr_reg                =   1'b1;
                        end

                    EXECUTE_FLASH_RD_REG_ST: 
                        begin
                            if (flash_packet_len_r == cnt) 
                                begin
                                    `log_debug($sformatf("%s", pr_state.name()), 1);
                                    next_state      = RETURN_BRIDGE_STATUS_REG_AND_CRC_ST;
                                end
                            else
                                begin
                                    next_state      = EXECUTE_FLASH_RD_REG_ST;
                                end

                            execute_flash_rd_reg                        =   1'b1;
                        end

                    WAIT_FOR_MEM_PACKET_READY_ST:   
                        begin
                            if (1'b1 == rx_fifo_contain_mem_packet)
                                begin
                                    next_state  = EXECUTE_FLASH_PROGRAM_MEM_ST;
                                end
                            else
                                begin
                                    next_state  = WAIT_FOR_MEM_PACKET_READY_ST;
                                end
                            wait_for_mem_packet_ready                   =   1'b1;
                        end

                    EXECUTE_FLASH_PROGRAM_MEM_ST: 
                        begin
                            if (flash_packet_len_r == cnt) 
                                begin
                                    `log_debug($sformatf("%s", pr_state.name()), 1);
                                    next_state      = CHECK_MEM_PACKET_CRC_ST;
                                end
                            else
                                begin
                                    next_state      = EXECUTE_FLASH_PROGRAM_MEM_ST;
                                end
                            execute_flash_program_mem                   =   1'b1;
                        end

                    EXECUTE_FLASH_RD_MEM_ST: 
                        begin
                            if (flash_packet_len_r == cnt) 
                                begin
                                    `log_debug($sformatf("%s", pr_state.name()), 1);
                                    next_state      = RETURN_BRIDGE_STATUS_REG_AND_CRC_ST;
                                end
                            else
                                begin
                                    next_state      = EXECUTE_FLASH_RD_MEM_ST;
                                end
                            execute_flash_rd_mem                        =   1'b1;
                        end

                    CHECK_MEM_PACKET_CRC_ST: 
                        begin
                            `log_debug($sformatf("%s", pr_state.name()), 1);
                            next_state              = RETURN_BRIDGE_STATUS_REG_AND_CRC_ST;
                            check_mem_packet_crc                        =   1'b1;
                        end

                    RETURN_BRIDGE_STATUS_REG_AND_CRC_ST: 
                        begin
                            if (1 == cnt) 
                                begin
                                    `log_debug($sformatf("%s", pr_state.name()), 1);
                                    next_state      = FINISH_ST;
                                end
                            else
                                begin
                                    next_state      = RETURN_BRIDGE_STATUS_REG_AND_CRC_ST;
                                end
                            return_bridge_status_reg_and_crc            =   1'b1;
                        end

                    FINISH_ST: 
                        begin
                            `log_debug($sformatf("%s", pr_state.name()), 1);
                            next_state      =  IDLE_ST;
                            bridge_finish   =   1'b1;
                        end

                    FAULT_ST: 
                        begin
                            `log_debug($sformatf("%s", pr_state.name()), 1);
                            `log_fatal();
                            next_state      =  IDLE_ST;
                            bridge_fault_detected                       =   1'b1;
                        end

                    default:    
                        begin
                            next_state      =  IDLE_ST;
                        end
                endcase
            end

        // FSM sync and other...
        always @ (posedge clk, negedge rst_n)
            begin
                if (!rst_n)
                    begin
                        pr_state                        <=  IDLE_ST;
                        
                        spi_sck                         <=  1'b1;

                        bridge_packet_regs              <=  48'h00_00_00_00_00_00;

                        cnt                             <=  0;
                        spi_bit_cnt                     <=  0;

                        packet_header_error             <=  1'b0;
                        bridge_status_reg               <=  8'h40;

                        spi_cs                          <=  1'b1;
                        spi_cs_f                        <=  1'b1;
                        flash_packet_len_r              <=  13'h000;
                        flash_response                  <=  8'h00;
                    end
                else
                    begin
                        pr_state                                <=  next_state;

                        if ((1'b1 == execute_flash_rd_reg && BYTE_WIDTH  < spi_bit_cnt && 3'h4 == cnt[2 : 0]) ||
                            (1'b1 == execute_flash_rd_mem && BYTE_WIDTH  < spi_bit_cnt && 3'h4 == cnt[2 : 0]))
                            begin
                                flash_response[BYTE_WIDTH - 1 :   0]    <=  {flash_response[BYTE_WIDTH - 2 :   0], spi_sio_1};                                
                            end

                        if (1'b1 == (execute_flash_wr_reg | execute_flash_program_mem | execute_flash_rd_reg | execute_flash_rd_mem))
                            begin
                                spi_cs_f                        <=  1'b0;
                            end
                        else 
                            begin
                                spi_cs_f                        <=  1'b1;
                            end
                        spi_cs                                  <=  spi_cs_f;   //  shift 'spi_cs' relative to 'spi_sck' by 1 'clk'


                        if (1'b1 == (execute_flash_wr_reg | execute_flash_rd_reg | execute_flash_program_mem | execute_flash_rd_mem))
                            begin
                                if (2'h0 == cnt[1:0])
                                    begin
                                        spi_sck                 <=  ~spi_sck;
                                    end
                            end
                        else 
                            begin
                                spi_sck                         <=  1'b1;
                            end





                        if (analyze_cmd_packet) 
                            begin
                                flash_packet_len_r     <=  flash_packet_len;
                            end

                        if (bridge_fault_detected) 
                            begin
                                bridge_status_reg[BRIDGE_STATUS_REG_FAULT_OFFSET]     <=  1'b1;                                
                            end

                        if (bridge_init)
                            begin
                                packet_header_error     <=  1'b0;
                            end
                        else if ((1'b1 == read_cmd_packet) && (0 == cnt) && (BRIDGE_PACKET_HEADER != rx_fifo_data))
                            begin
                                packet_header_error     <=  1'b1;
                            end


                        case ({read_cmd_packet, execute_flash_wr_reg, execute_flash_program_mem, execute_flash_rd_reg, execute_flash_rd_mem})
                            5'b10000:    //  read_cmd_packet
                                begin
                                    if (bcmd_packet_store)
                                        begin
                                            // shift in 'bridge packet' (6 bytes)
                                            bridge_packet_regs[BYTE_WIDTH * 6 - 1   :   BYTE_WIDTH * 5]     <=  bridge_packet_regs[BYTE_WIDTH * 5 - 1   :   BYTE_WIDTH * 4];    // {len, bcmd}
                                            bridge_packet_regs[BYTE_WIDTH * 5 - 1   :   BYTE_WIDTH * 4]     <=  bridge_packet_regs[BYTE_WIDTH * 4 - 1   :   BYTE_WIDTH * 3];    // fcmd
                                            bridge_packet_regs[BYTE_WIDTH * 4 - 1   :   BYTE_WIDTH * 3]     <=  bridge_packet_regs[BYTE_WIDTH * 3 - 1   :   BYTE_WIDTH * 2];    // msb: addr/data
                                            bridge_packet_regs[BYTE_WIDTH * 3 - 1   :   BYTE_WIDTH * 2]     <=  bridge_packet_regs[BYTE_WIDTH * 2 - 1   :   BYTE_WIDTH];        //      addr/data
                                            bridge_packet_regs[BYTE_WIDTH * 2 - 1   :   BYTE_WIDTH]         <=  bridge_packet_regs[BYTE_WIDTH - 1       :   0];                 //      addr/data
                                            bridge_packet_regs[BYTE_WIDTH - 1       :   0]                  <=  rx_fifo_data;                                                   // lsb: addr/data
                                        end
                                end

                            5'b01000:    //  execute_flash_wr_reg
                                begin
                                    if (BYTE_WIDTH  <= spi_bit_cnt && 3'h0  == spi_bit_cnt[2:0] && 3'h1 == cnt[2 : 0])
                                        begin
                                            // shift out 'bridge packet' flash content ('cmd' and 'data/addr'(max 5 bytes))
                                            bridge_packet_regs[BYTE_WIDTH * 5 - 1   :   BYTE_WIDTH * 4]     <=  bridge_packet_regs[BYTE_WIDTH * 4 - 1   :   BYTE_WIDTH * 3];    // fcmd
                                            bridge_packet_regs[BYTE_WIDTH * 4 - 1   :   BYTE_WIDTH * 3]     <=  bridge_packet_regs[BYTE_WIDTH * 3 - 1   :   BYTE_WIDTH * 2];    // msb: addr/data
                                            bridge_packet_regs[BYTE_WIDTH * 3 - 1   :   BYTE_WIDTH * 2]     <=  bridge_packet_regs[BYTE_WIDTH * 2 - 1   :   BYTE_WIDTH];        //      addr/data
                                            bridge_packet_regs[BYTE_WIDTH * 2 - 1   :   BYTE_WIDTH]         <=  bridge_packet_regs[BYTE_WIDTH - 1       :   0];                 //      addr/data
                                            bridge_packet_regs[BYTE_WIDTH - 1       :   0]                  <=  rx_fifo_data;                                                   // lsb: addr/data
                                        end                                    
                                    else if (3'h0 == cnt[2 : 0])
                                        begin
                                            // shift out cmd or data/addr bridge regs to spi_sio
                                            {spi_sio_0, bridge_packet_regs[5 * BYTE_WIDTH - 1   :   BYTE_WIDTH * 4]}                <=  {bridge_packet_regs[5 * BYTE_WIDTH - 1   :   BYTE_WIDTH * 4], 1'bx};
                                        end
                                end

                            5'b00100:    //  execute_flash_program_mem
                                begin
                                    if (BYTE_WIDTH  <= spi_bit_cnt && 5*BYTE_WIDTH  > spi_bit_cnt && 3'h0  == spi_bit_cnt[2:0] && 3'h1 == cnt[2 : 0])
                                        begin
                                            // shift out flash content: 'cmd' and 'data/addr'(max 5 bytes))
                                            bridge_packet_regs[BYTE_WIDTH * 5 - 1   :   BYTE_WIDTH * 4]     <=  bridge_packet_regs[BYTE_WIDTH * 4 - 1   :   BYTE_WIDTH * 3];    // fcmd
                                            bridge_packet_regs[BYTE_WIDTH * 4 - 1   :   BYTE_WIDTH * 3]     <=  bridge_packet_regs[BYTE_WIDTH * 3 - 1   :   BYTE_WIDTH * 2];    // msb: addr/data
                                            bridge_packet_regs[BYTE_WIDTH * 3 - 1   :   BYTE_WIDTH * 2]     <=  bridge_packet_regs[BYTE_WIDTH * 2 - 1   :   BYTE_WIDTH];        //      addr/data
                                            bridge_packet_regs[BYTE_WIDTH * 2 - 1   :   BYTE_WIDTH]         <=  bridge_packet_regs[BYTE_WIDTH - 1       :   0];                 //      addr/data
                                            bridge_packet_regs[BYTE_WIDTH - 1       :   0]                  <=  rx_fifo_data;                                                   // lsb: addr/data
                                        end
                                    else if (5*BYTE_WIDTH  <= spi_bit_cnt && 3'h0  == spi_bit_cnt[2:0] && 3'h1 == cnt[2 : 0])
                                        begin
                                            // shift out flash mem content
                                            bridge_packet_regs[BYTE_WIDTH * 5 - 1   :   BYTE_WIDTH * 4]     <=  rx_fifo_data;                                                   // lsb: addr/data
                                        end
                                    else if (3'h0 == cnt[2 : 0])
                                        begin
                                            // shift out flash cmd, data/addr or mem content to spi_sio
                                            {spi_sio_0, bridge_packet_regs[5 * BYTE_WIDTH - 1   :   BYTE_WIDTH * 4]}                <=  {bridge_packet_regs[5 * BYTE_WIDTH - 1   :   BYTE_WIDTH * 4], 1'bx};
                                        end
                                end

                            5'b00010:    //  execute_flash_rd_reg
                                begin
                                   if (BYTE_WIDTH  > spi_bit_cnt && 3'h0 == cnt[2 : 0])
                                    begin
                                        // shift out cmd bridge reg to spi_sio
                                        {spi_sio_0, bridge_packet_regs[5 * BYTE_WIDTH - 1   :   BYTE_WIDTH * 4]}                    <=  {bridge_packet_regs[5 * BYTE_WIDTH - 1   :   BYTE_WIDTH * 4], 1'bx};                                        
                                    end
                                end
                        
                            5'b00001:    //  execute_flash_rd_mem
                                begin
                                    if (BYTE_WIDTH  <= spi_bit_cnt && 3'h0  == spi_bit_cnt[2:0] && 3'h1 == cnt[2 : 0])
                                        begin
                                            // shift out 'bridge packet' flash content ('cmd' and 'data/addr'(max 5 bytes))
                                            bridge_packet_regs[BYTE_WIDTH * 5 - 1   :   BYTE_WIDTH * 4]     <=  bridge_packet_regs[BYTE_WIDTH * 4 - 1   :   BYTE_WIDTH * 3];    // fcmd
                                            bridge_packet_regs[BYTE_WIDTH * 4 - 1   :   BYTE_WIDTH * 3]     <=  bridge_packet_regs[BYTE_WIDTH * 3 - 1   :   BYTE_WIDTH * 2];    // msb: addr/data
                                            bridge_packet_regs[BYTE_WIDTH * 3 - 1   :   BYTE_WIDTH * 2]     <=  bridge_packet_regs[BYTE_WIDTH * 2 - 1   :   BYTE_WIDTH];        //      addr/data
                                            bridge_packet_regs[BYTE_WIDTH * 2 - 1   :   BYTE_WIDTH]         <=  bridge_packet_regs[BYTE_WIDTH - 1       :   0];                 //      addr/data
                                            bridge_packet_regs[BYTE_WIDTH - 1       :   0]                  <=  rx_fifo_data;                                                   // lsb: addr/data
                                        end                                    
                                   else if (5*BYTE_WIDTH  > spi_bit_cnt && 3'h0 == cnt[2 : 0])
                                    begin
                                        // shift out cmd bridge reg to spi_sio
                                        {spi_sio_0, bridge_packet_regs[5 * BYTE_WIDTH - 1   :   BYTE_WIDTH * 4]}                    <=  {bridge_packet_regs[5 * BYTE_WIDTH - 1   :   BYTE_WIDTH * 4], 1'bx};                                        
                                    end
                                end

                            default : 
                                begin

                                end
                        endcase

                        if (cnt_en)
                            begin
                                cnt                     <=  cnt + 1'b1;

                                if (3'h0 == cnt[2 : 0])
                                    begin
                                        spi_bit_cnt     <=  spi_bit_cnt + 1'b1;                                        
                                    end
                            end
                        else 
                            begin
                                cnt                     <=  0;
                                spi_bit_cnt             <=  0;
                            end

                    end
            end


endmodule
// ============================================================================================================================~