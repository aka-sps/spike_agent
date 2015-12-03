//////////////////////////
// Test Bench for Spike
// authors: Dmitri Pavlov
//////////////////////////
`timescale 1ns/100ps
module spike_agent #(
    parameter MEM_POWER_SIZE = 12,
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ADDR_WIDTH = (MEM_POWER_SIZE),
    parameter AXI_MASK_WIDTH = (AXI_DATA_WIDTH/8)
)
(
    // System
    input   logic                           CPUNC_ARESETn,
    input   logic                           CPUNC_ACLK,
    
    // Slave interface
    // Write Address Channel:
    output  logic   [7:0]                   CPUNC_AWID,    //
    output  logic   [AXI_ADDR_WIDTH-1:0]    CPUNC_AWADDR,  //
    output  logic   [7:0]                   CPUNC_AWLN,    //
    output  logic   [1:0]                   CPUNC_AWSIZE,  // always 10
    output  logic   [1:0]                   CPUNC_AWBURST, //
    output  logic                           CPUNC_AWLOCK,  // always 0
    output  logic   [2:0]                   CPUNC_AWCACHE, // always 000
    output  logic                           CPUNC_AWPROT,  // always 0
    output  logic   [2:0]                   CPUNC_AWQOS,   // always 000
    output  logic                           CPUNC_AWVALID, //
    input   logic                           CPUNC_AWREADY, // <-- SLAVE
    // Write Data Channel:
    output  logic   [7:0]                   CPUNC_WID,
    output  logic   [AXI_DATA_WIDTH-1:0]    CPUNC_WDATA,   // Write Data
    output  logic   [AXI_MASK_WIDTH-1:0]    CPUNC_WSTRB,   // Byte mask
    output  logic                           CPUNC_WLAST,   //
    output  logic                           CPUNC_WVALID,  //
    input   logic                           CPUNC_WREADY,  // <-- SLAVE
    // Write Response Channel:
    input   logic   [7:0]                   CPUNC_BID,     // <-- SLAVE
    input   logic                           CPUNC_BRESP,   // <-- SLAVE
    input   logic                           CPUNC_BVALID,  // <-- SLAVE
    output  logic                           CPUNC_BREADY,  //
    // Read Address Channel:
    output  logic   [7:0]                   CPUNC_ARID,    //
    output  logic   [AXI_ADDR_WIDTH-1:0]    CPUNC_ARADDR,  //
    output  logic   [7:0]                   CPUNC_ARLN,    // 
    output  logic   [1:0]                   CPUNC_ARSIZE,  // always 10
    output  logic   [1:0]                   CPUNC_ARBURST, //
    output  logic                           CPUNC_ARLOCK,  // always 0
    output  logic   [2:0]                   CPUNC_ARCACHE, // always 000
    output  logic                           CPUNC_ARPROT,  // always 0
    output  logic   [2:0]                   CPUNC_ARQOS,   // always 000
    output  logic                           CPUNC_ARVALID, //
    input   logic                           CPUNC_ARREADY, // <-- SLAVE
    // Read Address Channel:
    input   logic   [7:0]                   CPUNC_RID,     // <-- SLAVE
    input   logic   [AXI_DATA_WIDTH-1:0]    CPUNC_RDATA,   // <-- SLAVE
    input   logic                           CPUNC_RRESP,   // <-- SLAVE
    input   logic                           CPUNC_RLAST,   // <-- SLAVE
    input   logic                           CPUNC_RVALID,  // <-- SLAVE
    output  logic                           CPUNC_RREADY    
);

/// Send of 0 enables spike execution, send 1 stop spike execution
/// No return until connect to spike
import "DPI-C" function void spikeSetReset(logic a);

/// Need call each clock 
/// \return 0 - no transaction in this clock, 1 - read transaction, 2 - write transaction 
import "DPI-C" context function int spikeClock();

/// If spikeClock() != 0 then there is transaction from spike to vcs
/// \return transaction address
//import "DPI-C" context function longint spikeGetAddress();
import "DPI-C" context function int spikeGetAddress();

/// If spikeClock() != 0 then there is transaction from spike to vcs
/// \return transaction size
import "DPI-C" context function int spikeGetSize();

/// If spikeClock() != 2 then there is write transaction from spike to vcs
/// \return data to write
//import "DPI-C" context function longint spikeGetData();
import "DPI-C" context function int spikeGetData();

/// If spikeClock() != 1 then there is read transaction from spike to vcs
/// \param data read data
//import "DPI-C" context function void spikeSetData(longint data);
import "DPI-C" context function void spikeSetData(int data);

/// Each clock with or without transaction should be finished with call of this function
import "DPI-C" context function void spikeEndClock();

// ------------------------------
int                             spikeCmd;
int                             spikeAddr;
int                             spikeSize;
int                             spikeWdata;
int                             spikeRdata;
//-------------------------------
initial begin
    #1
    @(posedge CPUNC_ARESETn);
    $display("Spike Agent: Start Spike after reset");
    spikeSetReset(1'b0);
   
    @(negedge CPUNC_ARESETn);
    $display("Spike Agent: Reset is coming!!!");
end

assign CPUNC_AWID    = '0;     //
assign CPUNC_AWLN    = '0;     //
assign CPUNC_AWSIZE  = 2'b10;  // always 10
assign CPUNC_AWBURST = '0;     //
assign CPUNC_AWLOCK  = '0;     // always 0
assign CPUNC_AWCACHE = '0;     // always 000
assign CPUNC_AWPROT  = '0;     // always 0
assign CPUNC_AWQOS   = '0;     // always 000
assign CPUNC_WID     = '0;

assign CPUNC_ARID    = '0;     //
assign CPUNC_ARLN    = '0;     // 
assign CPUNC_ARSIZE  = 2'b10;   // always 10
assign CPUNC_ARBURST = '0;     //
assign CPUNC_ARLOCK  = '0;     // always 0
assign CPUNC_ARCACHE = '0;     // always 000
assign CPUNC_ARPROT  = '0;     // always 0
assign CPUNC_ARQOS   = '0;     // always 000

logic [1:0]             access_offset;
logic [31:0]            access_address;

initial begin

    CPUNC_AWADDR    = 'x;  //
    CPUNC_AWVALID   = 1'b0; //
    CPUNC_WDATA     = 'x;   // Write Data
    CPUNC_WSTRB     = 'x;   // Byte mask
    CPUNC_WLAST     = 'x;   //
    CPUNC_WVALID    = 1'b0;  //
    CPUNC_BREADY    = 1'b0;  //

    
    CPUNC_ARADDR    = 'x;  //
    CPUNC_ARVALID   = 1'b0; //
    CPUNC_RREADY    = 1'b0;
    @(posedge CPUNC_ARESETn);

    while (CPUNC_ARESETn == 1'b1) begin
        @(posedge CPUNC_ACLK);
        spikeCmd = spikeClock();
        #1
        case (spikeCmd)
            0 : begin
                // Todo Nothing
            end
            1 : begin
                // Read from IO
                spikeAddr  = spikeGetAddress();
                spikeSize  = spikeGetSize();
                
                // Convert to logic
                access_address = unsigned'(spikeAddr);
                CPUNC_ARADDR  = access_address;
                access_offset = access_address[1:0];
                CPUNC_ARADDR[1:0] = 2'b00;
                // Check allignment
                case (spikeSize)
                    1 : begin 
                        // It is ok
                    end
                    2 : begin
                        assert (access_offset[0] == 1'b0) else $error("Spike Agent: Unaligned addres for read HWORD");
                    end
                    4 : begin
                        assert (access_offset[1:0] == 2'b00) else $error("Spike Agent: Unaligned addres for read WORD");
                    end
                    default : begin
                        assert (0) else $error("Spike Agent: Wrong size accesss for Reading: %d",spikeSize); 
                    end
                endcase
                // Start reading
                CPUNC_ARVALID = 1'b1;
                @(posedge CPUNC_ACLK);
                while (CPUNC_ARREADY == 1'b0) begin
                    @(posedge CPUNC_ACLK);
                end
                #1
                CPUNC_ARVALID = 1'b0;
                CPUNC_ARADDR  = 'x;
                
                // Wait for RDATA
                CPUNC_RREADY = 1'b1;
                @(posedge CPUNC_ACLK);
                while (CPUNC_RVALID == 1'b0) begin
                    @(posedge CPUNC_ACLK);
                end
                #1
                assert (CPUNC_RRESP == '0) else $error("Spike Agent: Read transaction completed with Error Response");
                CPUNC_RREADY = 1'b0;
                // Return RDATA
                case (spikeSize)
                    1: begin
                        case (access_offset)
                            2'b00 : spikeSetData(int'({24'h000000, CPUNC_RDATA[7:0]}));
                            2'b01 : spikeSetData(int'({24'h000000, CPUNC_RDATA[15:8]}));
                            2'b10 : spikeSetData(int'({24'h000000, CPUNC_RDATA[23:16]}));
                            2'b11 : spikeSetData(int'({24'h000000, CPUNC_RDATA[31:24]}));
                            default : begin
                            end
                        endcase
                    end
                    2: begin
                        if (access_offset[1] == 1'b0) begin
                            spikeSetData(int'({16'h0000, CPUNC_RDATA[15:0]}));
                        end else begin
                            spikeSetData(int'({16'h0000, CPUNC_RDATA[31:16]}));
                        end
                    end
                    4: begin
                        spikeSetData(int'(CPUNC_RDATA));
                    end

                endcase

            end    

            2 : begin
                // Write to IO
                spikeAddr  = spikeGetAddress();
                spikeSize  = spikeGetSize();
                spikeWdata = spikeGetData();
                
                // Convert to logic
                access_address = unsigned'(spikeAddr);
                CPUNC_AWADDR  = access_address;
                access_offset = access_address[1:0];
                CPUNC_AWADDR[1:0] = 2'b00;

                // Check alignment
                case (spikeSize)
                    1 : begin 
                        // It is ok
                    end
                    2 : begin
                        assert (access_offset[0] == 1'b0) else $error("Spike Agent: Unaligned addres for read HWORD; Addr = %x, size = %d", spikeAddr, spikeSize);
                    end
                    4 : begin
                        assert (access_offset[1:0] == 2'b00) else $error("Spike Agent: Unaligned addres for read WORD; Addr = %x, size = %d", spikeAddr, spikeSize);
                    end
                    default : begin
                        assert (0) else $error("Spike Agent: Wrong size accesss for Rading; Addr = %x, size = %d", spikeAddr, spikeSize);
                    end
                endcase

                // Start writing
                CPUNC_AWVALID = 1'b1;
                @(posedge CPUNC_ACLK);
                while (CPUNC_AWREADY == 1'b0) begin
                    @(posedge CPUNC_ACLK);
                end
                #1
                CPUNC_AWVALID = 1'b0;
                CPUNC_AWADDR  = 'x;


                //--
                CPUNC_WVALID = 1'b1;
                CPUNC_WLAST  = 1'b1;
                CPUNC_WDATA  = unsigned'(spikeWdata);
                case (spikeSize)
                    1 : begin 
                        // It is ok
                        CPUNC_WSTRB = 4'b0001;
                    end
                    2 : begin
                        CPUNC_WSTRB = 4'b0011;
                    end
                    4 : begin
                        CPUNC_WSTRB = 4'b1111;
                    end
                    default : begin
                    end
                endcase
                case (spikeSize)
                    1 : begin 
                        // It is ok
                    end
                    2 : begin
                        assert (access_offset[0] == 1'b0) else $error("Spike Agent: Unaligned addres for write HWORD; Addr = %x, size = %d", spikeAddr, spikeSize);
                    end
                    4 : begin
                        assert (access_offset[1:0] == 2'b00) else $error("Spike Agent: Unaligned addres for write WORD; Addr = %x, size = %d", spikeAddr, spikeSize);
                    end
                    default : begin
                        assert (0) else $error("Spike Agent: Wrong size accesss for Writing; Addr = %x, size = %d", spikeAddr, spikeSize);
                    end
                endcase
                @(posedge CPUNC_ACLK);
                while (CPUNC_WREADY == 1'b0) begin
                    @(posedge CPUNC_ACLK);
                end
                #1
                CPUNC_WVALID = 1'b0;
                CPUNC_WSTRB  = 'x;
                CPUNC_WDATA  = 'x;
                CPUNC_WLAST  = 1'bx;

                //--
                CPUNC_BREADY = 1'b1;
                @(posedge CPUNC_ACLK);
                while (CPUNC_BVALID == 1'b0) begin
                    @(posedge CPUNC_ACLK);
                end
                #1
                CPUNC_BREADY = 1'b0;
            end    
            default : begin
                assert (0) else $error("Wrong command from Spike");
            end

        endcase
        spikeEndClock();
    end
end

// ------------------------------------------------
endmodule : spike_agent

