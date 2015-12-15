////////////////////////////////////////////////////
// Copyright 2015 Syntacore 
// See LICENSE for license details
// AXI memory block
////////////////////////////////////////////////////

module axi_mem  #(
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
    input   logic   [7:0]                   CPUNC_AWID,    //
    input   logic   [AXI_ADDR_WIDTH-1:0]    CPUNC_AWADDR,  //
    input   logic   [7:0]                   CPUNC_AWLN,    //
    input   logic   [1:0]                   CPUNC_AWSIZE,  // always 10
    input   logic   [1:0]                   CPUNC_AWBURST, //
    input   logic                           CPUNC_AWLOCK,  // always 0
    input   logic   [2:0]                   CPUNC_AWCACHE, // always 000
    input   logic                           CPUNC_AWPROT,  // always 0
    input   logic   [2:0]                   CPUNC_AWQOS,   // always 000
    input   logic                           CPUNC_AWVALID, //
    output  logic                           CPUNC_AWREADY, // <-- SLAVE
    // Write Data Channel:
    input   logic   [7:0]                   CPUNC_WID,
    input   logic   [AXI_DATA_WIDTH-1:0]    CPUNC_WDATA,   // Write Data
    input   logic   [AXI_MASK_WIDTH-1:0]    CPUNC_WSTRB,   // Byte mask
    input   logic                           CPUNC_WLAST,   //
    input   logic                           CPUNC_WVALID,  //
    output  logic                           CPUNC_WREADY,  // <-- SLAVE
    // Write Response Channel:
    output  logic   [7:0]                   CPUNC_BID,     // <-- SLAVE
    output  logic                           CPUNC_BRESP,   // <-- SLAVE
    output  logic                           CPUNC_BVALID,  // <-- SLAVE
    input   logic                           CPUNC_BREADY,  //
    // Read Address Channel:
    input   logic   [7:0]                   CPUNC_ARID,    //
    input   logic   [AXI_ADDR_WIDTH-1:0]    CPUNC_ARADDR,  //
    input   logic   [7:0]                   CPUNC_ARLN,    // 
    input   logic   [1:0]                   CPUNC_ARSIZE,  // always 10
    input   logic   [1:0]                   CPUNC_ARBURST, //
    input   logic                           CPUNC_ARLOCK,  // always 0
    input   logic   [2:0]                   CPUNC_ARCACHE, // always 000
    input   logic                           CPUNC_ARPROT,  // always 0
    input   logic   [2:0]                   CPUNC_ARQOS,   // always 000
    input   logic                           CPUNC_ARVALID, //
    output  logic                           CPUNC_ARREADY, // <-- SLAVE
    // Read Address Channel:
    output  logic   [7:0]                   CPUNC_RID,     // <-- SLAVE
    output  logic   [AXI_DATA_WIDTH-1:0]    CPUNC_RDATA,   // <-- SLAVE
    output  logic                           CPUNC_RRESP,   // <-- SLAVE
    output  logic                           CPUNC_RLAST,   // <-- SLAVE
    output  logic                           CPUNC_RVALID,  // <-- SLAVE
    input   logic                           CPUNC_RREADY    
);

/////////// Signal declarations //////////////////////////
// Memory
logic   [7:0]   axi_memory_array [0:(2**MEM_POWER_SIZE)-1];

// Read Interface
logic                           ar_ready;
logic                           dr_trans;
logic                           ar_trans;
logic   [AXI_DATA_WIDTH-1:0]    dr_data;
logic   [7:0]                   dr_id;
logic                           dr_valid;

// Write Interface
logic                           aw_ready;
logic                           aw_trans;
logic                           dw_ready;
logic                           dw_trans;
logic                           bw_trans;
logic   [7:0]                   aw_id;
logic   [7:0]                   dw_id;
logic   [AXI_ADDR_WIDTH-1:0]    aw_addr;
logic   [AXI_DATA_WIDTH-1:0]    dw_data;
logic   [AXI_MASK_WIDTH-1:0]    dw_wen;

//////////////////////////////////////////////////////
// Check parameters
// pragma synthesis_off
//assert (MEM_POWER_SIZE == AXI_ADDR_WIDTH) else $error("Wrong ADDR_WIDTH parameter!!!");

always_ff @(negedge CPUNC_ARESETn, posedge CPUNC_ACLK) begin
    if (CPUNC_ARESETn == 1'b0) begin
        assert (MEM_POWER_SIZE == AXI_ADDR_WIDTH) else $error("Wrong ADDR_WIDTH parameter!!!");
    end else begin
        if (CPUNC_ARVALID == 1'b1) begin
            assert (CPUNC_ARLN    == '0)     else $error("Read burst size should be 1: CPUNC_ARLN isn't 0!");
            assert (CPUNC_ARSIZE  == 2'b10)  else $error("Read transfer size should be 32-bit!");
            assert (CPUNC_ARBURST  == 2'b00) else $error("Read burst type should be Fixed");
            assert (CPUNC_ARLOCK  == 1'b0)   else $error("Read Lock atribute should be 0");
            assert (CPUNC_ARCACHE == 3'b000) else $error("Read Cache atribute should be 0");
            assert (CPUNC_ARPROT  == 1'b0)   else $error("Read PROT attribute should be 0");
            assert (CPUNC_ARQOS   == 3'b000) else $error("Read QS attribute should be 0");
            assert (CPUNC_ARADDR[$clog2(AXI_DATA_WIDTH/8)-1:0] == '0) else $error("Read Address is not aligned");
        end
        if (CPUNC_AWVALID == 1'b1) begin
            assert (CPUNC_AWLN    == '0)     else $error("Write burst size should be 1: CPUNC_ARLN isn't 0!");
            assert (CPUNC_AWSIZE  == 2'b10)  else $error("Write transfer size should be 32-bit!");
            assert (CPUNC_AWBURST  == 2'b00) else $error("Write burst type should be Fixed");
            assert (CPUNC_AWLOCK  == 1'b0)   else $error("Write Lock atribute should be 0");
            assert (CPUNC_AWCACHE == 3'b000) else $error("Write Cache atribute should be 0");
            assert (CPUNC_AWPROT  == 1'b0)   else $error("Write PROT attribute should be 0");
            assert (CPUNC_AWQOS   == 3'b000) else $error("Write QS attribute should be 0");
            assert (CPUNC_AWADDR[$clog2(AXI_DATA_WIDTH/8)-1:0] == '0) else $error("Write Address is not aligned");
        end
        if ((aw_ready == 1'b0) && (dw_ready == 1'b0)) begin
            assert (aw_id == dw_id) else $error("WID != AWID");
        end
    end
end

// pragma synthesis_on

//////////////////////////////////////////////////////
// Read Interface
always_ff @(negedge CPUNC_ARESETn, posedge CPUNC_ACLK) begin
    if (CPUNC_ARESETn == 1'b0) begin
        ar_ready <= 1'b1;
    end else begin
        if (ar_ready == 1'b1) begin
            ar_ready <= ~CPUNC_ARVALID;
        end else begin
            if (dr_trans == 1'b1) begin
                ar_ready <= 1'b1;
            end    
        end
    end
end

assign CPUNC_ARREADY = ar_ready;
assign ar_trans = ar_ready & CPUNC_ARVALID;

always_ff @(posedge CPUNC_ACLK) begin
    if (ar_trans == 1'b1) begin
        for (int unsigned i=0; i<AXI_MASK_WIDTH; ++i) begin
            dr_data[(i+1)*8-1-:8] <= axi_memory_array[CPUNC_ARADDR+i];
        end
        dr_id <= CPUNC_ARID;
    end else if (dr_trans == 1'b1) begin
        dr_data <= 'x;
        dr_id <= 'x;
    end
end

always_ff @(negedge CPUNC_ARESETn, posedge CPUNC_ACLK) begin
    if (CPUNC_ARESETn == 1'b0) begin
        dr_valid <= 1'b0;
    end else begin
        if (dr_valid == 1'b0) begin
            dr_valid <= ar_trans;

        end else begin
            if (CPUNC_RREADY == 1'b1) begin
                dr_valid <= 1'b0;
            end
        end
    end
end

assign dr_trans = dr_valid & CPUNC_RREADY;

assign CPUNC_RID   = dr_id;
assign CPUNC_RDATA = dr_data;
assign CPUNC_RRESP = '0;
assign CPUNC_RLAST = dr_valid;
assign CPUNC_RVALID = dr_valid;


//////////////////////////////////////////////////////
// Write Interface
always_ff @(negedge CPUNC_ARESETn, posedge CPUNC_ACLK) begin
    if (CPUNC_ARESETn == 1'b0) begin
        aw_ready <= 1'b1;
    end else begin
        if (aw_ready == 1'b1) begin
            aw_ready <= ~CPUNC_AWVALID;
        end else begin
            if (bw_trans == 1'b1) begin
                aw_ready <= 1'b1;
            end    
        end
    end
end

assign CPUNC_AWREADY = aw_ready;
assign aw_trans = aw_ready & CPUNC_AWVALID;

always_ff @(negedge CPUNC_ARESETn, posedge CPUNC_ACLK) begin
    if (CPUNC_ARESETn == 1'b0) begin
        dw_ready <= 1'b1;
    end else begin
        if (dw_ready == 1'b1) begin
            dw_ready <= ~CPUNC_WVALID;
        end else begin
            if (bw_trans == 1'b1) begin
                dw_ready <= 1'b1;
            end    
        end
    end
end

assign CPUNC_WREADY = dw_ready;
assign dw_trans = dw_ready & CPUNC_WVALID;

assign bw_trans = ~aw_ready & ~dw_ready & CPUNC_BREADY;

always_ff @(posedge CPUNC_ACLK) begin
    if (aw_trans == 1'b1) begin
        aw_id   <= CPUNC_AWID;
        aw_addr <= CPUNC_AWADDR;
    end
    if (dw_trans == 1'b1) begin
        dw_id   <= CPUNC_WID;
        dw_data <= CPUNC_WDATA;
        dw_wen  <= CPUNC_WSTRB;
    end
end

always_ff @(negedge CPUNC_ARESETn, posedge CPUNC_ACLK) begin
    if (CPUNC_ARESETn == 1'b0) begin
        for (int unsigned i=0; i<2**MEM_POWER_SIZE-1; ++i) begin
            axi_memory_array[i] <= 'x;
        end
    end else begin
        if ((bw_trans == 1'b1) && (aw_ready == 1'b0) && (dw_ready == 1'b0)) begin
            for (int unsigned i=0; i<AXI_MASK_WIDTH; ++i) begin
                if (dw_wen[i] == 1'b1) begin
                    axi_memory_array[aw_addr+i] <= dw_data[(i+1)*8-1-:8];
                end
            end
        end
    end
end

assign CPUNC_BID = aw_id;
assign CPUNC_BRESP = '0;
assign CPUNC_BVALID = ~aw_ready & ~dw_ready;


endmodule : axi_mem
