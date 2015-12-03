//////////////////////////
// Test Bench for Spike
// authors: Dmitri Pavlov
//////////////////////////
`timescale 1ns/100ps
module spike_tb (
);
localparam AXI_ADDR_WIDTH = 32; 
localparam AXI_DATA_WIDTH = 32;
localparam AXI_MASK_WIDTH = (AXI_DATA_WIDTH/8);

localparam MEM0_POWER_SIZE = 12;
localparam AXI0_DATA_WIDTH = 32;
localparam AXI0_ADDR_WIDTH = (MEM0_POWER_SIZE);
localparam AXI0_MASK_WIDTH = (AXI0_DATA_WIDTH/8);

//------ Signal Declaration ----------
// System
logic               rst_n       = 1'b1;
logic               clk         = 1'b0;

// ------ Spike agent instance -------
logic   [7:0]                   CPUNC_AWID;    //
logic   [AXI_ADDR_WIDTH-1:0]    CPUNC_AWADDR;  //
logic   [7:0]                   CPUNC_AWLN;    //
logic   [1:0]                   CPUNC_AWSIZE;  // always 10
logic   [1:0]                   CPUNC_AWBURST; //
logic                           CPUNC_AWLOCK;  // always 0
logic   [2:0]                   CPUNC_AWCACHE; // always 000
logic                           CPUNC_AWPROT;  // always 0
logic   [2:0]                   CPUNC_AWQOS;   // always 000
logic                           CPUNC_AWVALID; //
logic                           CPUNC_AWREADY; // <-- SLAVE
// Write Data Channel:
logic   [7:0]                   CPUNC_WID;
logic   [AXI_DATA_WIDTH-1:0]    CPUNC_WDATA;   // Write Data
logic   [AXI_MASK_WIDTH-1:0]    CPUNC_WSTRB;   // Byte mask
logic                           CPUNC_WLAST;   //
logic                           CPUNC_WVALID;  //
logic                           CPUNC_WREADY;  // <-- SLAVE
// Write Response Channel:
logic   [7:0]                   CPUNC_BID;     // <-- SLAVE
logic                           CPUNC_BRESP;   // <-- SLAVE
logic                           CPUNC_BVALID;  // <-- SLAVE
logic                           CPUNC_BREADY;  //
// Read Address Channel:
logic   [7:0]                   CPUNC_ARID;    //
logic   [AXI_ADDR_WIDTH-1:0]    CPUNC_ARADDR;  //
logic   [7:0]                   CPUNC_ARLN;    // 
logic   [1:0]                   CPUNC_ARSIZE;  // always 10
logic   [1:0]                   CPUNC_ARBURST; //
logic                           CPUNC_ARLOCK;  // always 0
logic   [2:0]                   CPUNC_ARCACHE; // always 000
logic                           CPUNC_ARPROT;  // always 0
logic   [2:0]                   CPUNC_ARQOS;   // always 000
logic                           CPUNC_ARVALID; //
logic                           CPUNC_ARREADY; // <-- SLAVE
// Read Address Channel:
logic   [7:0]                   CPUNC_RID;     // <-- SLAVE
logic   [AXI_DATA_WIDTH-1:0]    CPUNC_RDATA;   // <-- SLAVE
logic                           CPUNC_RRESP;   // <-- SLAVE
logic                           CPUNC_RLAST;   // <-- SLAVE
logic                           CPUNC_RVALID;  // <-- SLAVE
logic                           CPUNC_RREADY;
// ------ MEM0 instance --------------
// Write Address Channel:
logic   [7:0]                   CPUNC0_AWID;    //
logic   [AXI0_ADDR_WIDTH-1:0]   CPUNC0_AWADDR;  //
logic   [7:0]                   CPUNC0_AWLN;    //
logic   [1:0]                   CPUNC0_AWSIZE;  // always 10
logic   [1:0]                   CPUNC0_AWBURST; //
logic                           CPUNC0_AWLOCK;  // always 0
logic   [2:0]                   CPUNC0_AWCACHE; // always 000
logic                           CPUNC0_AWPROT;  // always 0
logic   [2:0]                   CPUNC0_AWQOS;   // always 000
logic                           CPUNC0_AWVALID; //
logic                           CPUNC0_AWREADY; // <-- SLAVE
// Write Data Channel:
logic   [7:0]                   CPUNC0_WID;
logic   [AXI0_DATA_WIDTH-1:0]   CPUNC0_WDATA;   // Write Data
logic   [AXI0_MASK_WIDTH-1:0]   CPUNC0_WSTRB;   // Byte mask
logic                           CPUNC0_WLAST;   //
logic                           CPUNC0_WVALID;  //
logic                           CPUNC0_WREADY;  // <-- SLAVE
// Write Response Channel:
logic   [7:0]                   CPUNC0_BID;     // <-- SLAVE
logic                           CPUNC0_BRESP;   // <-- SLAVE
logic                           CPUNC0_BVALID;  // <-- SLAVE
logic                           CPUNC0_BREADY;  //
// Read Address Channel:
logic   [7:0]                   CPUNC0_ARID;    //
logic   [AXI0_ADDR_WIDTH-1:0]   CPUNC0_ARADDR;  //
logic   [7:0]                   CPUNC0_ARLN;    // 
logic   [1:0]                   CPUNC0_ARSIZE;  // always 10
logic   [1:0]                   CPUNC0_ARBURST; //
logic                           CPUNC0_ARLOCK;  // always 0
logic   [2:0]                   CPUNC0_ARCACHE; // always 000
logic                           CPUNC0_ARPROT;  // always 0
logic   [2:0]                   CPUNC0_ARQOS;   // always 000
logic                           CPUNC0_ARVALID; //
logic                           CPUNC0_ARREADY; // <-- SLAVE
// Read Address Channel:
logic   [7:0]                   CPUNC0_RID;     // <-- SLAVE
logic   [AXI0_DATA_WIDTH-1:0]   CPUNC0_RDATA;   // <-- SLAVE
logic                           CPUNC0_RRESP;   // <-- SLAVE
logic                           CPUNC0_RLAST;   // <-- SLAVE
logic                           CPUNC0_RVALID;  // <-- SLAVE
logic                           CPUNC0_RREADY;

//------ System Logic ----------------
// Reset Logic
initial begin
    $display("TB: start");
    rst_n        = 1'b0;
    #100ns rst_n = 1'b1;

    #1ms
    #100ns rst_n = 1'b0;
    $display("TB: finish");
    #100 ns
    $finish;       
end

always begin
    #5ns clk = ~clk;
end

// ------ Spike Agent instance --------
spike_agent 
#(
    .AXI_DATA_WIDTH     (AXI_DATA_WIDTH), 
    .AXI_ADDR_WIDTH     (AXI_ADDR_WIDTH), 
    .AXI_MASK_WIDTH     (AXI_MASK_WIDTH) 
)    
i_spike_agent
(
    // System
    .CPUNC_ARESETn      (rst_n), 
    .CPUNC_ACLK         (clk),
    
    // Slave interface
    // Write Address Channel:
    .CPUNC_AWID         (CPUNC_AWID   ),
    .CPUNC_AWADDR       (CPUNC_AWADDR ),
    .CPUNC_AWLN         (CPUNC_AWLN   ),
    .CPUNC_AWSIZE       (CPUNC_AWSIZE ),
    .CPUNC_AWBURST      (CPUNC_AWBURST),
    .CPUNC_AWLOCK       (CPUNC_AWLOCK ),
    .CPUNC_AWCACHE      (CPUNC_AWCACHE),
    .CPUNC_AWPROT       (CPUNC_AWPROT ),
    .CPUNC_AWQOS        (CPUNC_AWQOS  ),
    .CPUNC_AWVALID      (CPUNC_AWVALID),
    .CPUNC_AWREADY      (CPUNC_AWREADY),
    // Write Data Channel:
    .CPUNC_WID          (CPUNC_WID   ),
    .CPUNC_WDATA        (CPUNC_WDATA ),
    .CPUNC_WSTRB        (CPUNC_WSTRB ),
    .CPUNC_WLAST        (CPUNC_WLAST ),
    .CPUNC_WVALID       (CPUNC_WVALID),
    .CPUNC_WREADY       (CPUNC_WREADY),
    // Write Response Channel:
    .CPUNC_BID          (CPUNC_BID   ),
    .CPUNC_BRESP        (CPUNC_BRESP ),
    .CPUNC_BVALID       (CPUNC_BVALID),
    .CPUNC_BREADY       (CPUNC_BREADY),
    // Read Address Channel:
    .CPUNC_ARID         (CPUNC_ARID   ),
    .CPUNC_ARADDR       (CPUNC_ARADDR ),
    .CPUNC_ARLN         (CPUNC_ARLN   ),
    .CPUNC_ARSIZE       (CPUNC_ARSIZE ),
    .CPUNC_ARBURST      (CPUNC_ARBURST),
    .CPUNC_ARLOCK       (CPUNC_ARLOCK ),
    .CPUNC_ARCACHE      (CPUNC_ARCACHE),
    .CPUNC_ARPROT       (CPUNC_ARPROT ),
    .CPUNC_ARQOS        (CPUNC_ARQOS  ),
    .CPUNC_ARVALID      (CPUNC_ARVALID),
    .CPUNC_ARREADY      (CPUNC_ARREADY),
    // Read Address Channel:
    .CPUNC_RID          (CPUNC_RID   ),
    .CPUNC_RDATA        (CPUNC_RDATA ),
    .CPUNC_RRESP        (CPUNC_RRESP ),
    .CPUNC_RLAST        (CPUNC_RLAST ),
    .CPUNC_RVALID       (CPUNC_RVALID),
    .CPUNC_RREADY       (CPUNC_RREADY) 
);


// ------ Memory arbiter --------------
// Write Address Channel:
assign CPUNC0_AWID    = CPUNC_AWID   ;
assign CPUNC0_AWADDR  = CPUNC_AWADDR[AXI0_ADDR_WIDTH-1:0] ;
assign CPUNC0_AWLN    = CPUNC_AWLN   ;
assign CPUNC0_AWSIZE  = CPUNC_AWSIZE ;
assign CPUNC0_AWBURST = CPUNC_AWBURST;
assign CPUNC0_AWLOCK  = CPUNC_AWLOCK ;
assign CPUNC0_AWCACHE = CPUNC_AWCACHE;
assign CPUNC0_AWPROT  = CPUNC_AWPROT ;
assign CPUNC0_AWQOS   = CPUNC_AWQOS  ;
// Write Data Channel:
assign CPUNC0_WID     = CPUNC_WID  ;
assign CPUNC0_WDATA   = CPUNC_WDATA;
assign CPUNC0_WSTRB   = CPUNC_WSTRB;
assign CPUNC0_WLAST   = CPUNC_WLAST;
// Write Response Channel:
assign CPUNC_BID      = CPUNC0_BID  ;
assign CPUNC_BRESP    = CPUNC0_BRESP;
// Read Address Channel:
assign CPUNC0_ARID    = CPUNC_ARID   ;
assign CPUNC0_ARADDR  = CPUNC_ARADDR[AXI0_ADDR_WIDTH-1:0] ;
assign CPUNC0_ARLN    = CPUNC_ARLN   ;
assign CPUNC0_ARSIZE  = CPUNC_ARSIZE ;
assign CPUNC0_ARBURST = CPUNC_ARBURST;
assign CPUNC0_ARLOCK  = CPUNC_ARLOCK ;
assign CPUNC0_ARCACHE = CPUNC_ARCACHE;
assign CPUNC0_ARPROT  = CPUNC_ARPROT ;
assign CPUNC0_ARQOS   = CPUNC_ARQOS  ;
// Read Address Channel:
assign CPUNC_RID      = CPUNC0_RID  ;
assign CPUNC_RDATA    = CPUNC0_RDATA;
assign CPUNC_RRESP    = CPUNC0_RRESP;
assign CPUNC_RLAST    = CPUNC0_RLAST;

logic   [1:0]       axi_w_state0;
logic               axi_aw_access0;
logic               axi_dw_access0;
assign axi_aw_access0 = (axi_w_state0[0] == 1'b0) && (CPUNC_AWADDR[31:AXI0_ADDR_WIDTH] == 20'hFEED0);
assign axi_dw_access0 = (axi_w_state0[1] == 1'b0) && (CPUNC_WVALID  == 1'b1);



logic               axi_r_state0;
logic               axi_ar_access0;
assign axi_ar_access0 = (axi_r_state0 == 1'b0) & (CPUNC_ARVALID == 1'b1)  && (CPUNC_ARADDR[31:AXI0_ADDR_WIDTH] == 20'hFEED0);

always_comb begin
    // Write Address Channel
    CPUNC0_AWVALID  = '0;
    CPUNC_AWREADY   = '0;
    if (axi_aw_access0 == 1'b1) begin
        CPUNC0_AWVALID  = CPUNC_AWVALID;
        CPUNC_AWREADY   = CPUNC0_AWREADY;
    end
    // Write Data Channel:
    CPUNC0_WVALID   = '0;
    CPUNC_WREADY    = '0;
    if (axi_dw_access0 == 1'b1) begin
        CPUNC0_WVALID  = CPUNC_WVALID;
        CPUNC_WREADY   = CPUNC0_WREADY;
    end
    // Write Response Channel:
    CPUNC_BVALID    = '0;
    CPUNC0_BREADY   = '0;
    if (axi_w_state0 == 2'b11) begin
        CPUNC_BVALID    = CPUNC0_BVALID;
        CPUNC0_BREADY   = CPUNC_BREADY;
    end

    // Read Address Channel:
    CPUNC0_ARVALID  = '0;
    CPUNC_ARREADY   = '0;
    if (axi_ar_access0 == 1'b1) begin
        CPUNC0_ARVALID  = CPUNC_ARVALID;
        CPUNC_ARREADY   = CPUNC0_ARREADY;
    end
    // Read Data Channel:
    CPUNC_RVALID    = '0;
    CPUNC0_RREADY   = '0;
    if (axi_r_state0 == 1'b1) begin
        CPUNC_RVALID    = CPUNC0_RVALID;
        CPUNC0_RREADY   = CPUNC_RREADY;
    end
end


always_ff @(negedge rst_n, posedge clk) begin
    if (rst_n == 1'b0) begin
        axi_r_state0 <= 1'b0;
        axi_w_state0 <= 2'b00;
    end else begin
        if (axi_r_state0 == 1'b0) begin
            axi_r_state0 <= CPUNC_ARVALID & CPUNC0_ARREADY & axi_ar_access0;
        end else begin
            axi_r_state0 <= ~(CPUNC0_RVALID & CPUNC_RREADY);
        end

        if (axi_w_state0[0] == 1'b0) begin
            axi_w_state0[0] <= CPUNC_AWVALID & CPUNC0_AWREADY & axi_aw_access0;
        end
        if (axi_w_state0[1] == 1'b0) begin
            axi_w_state0[1] <= CPUNC_WVALID & CPUNC0_WREADY & axi_dw_access0;
        end
        if (axi_w_state0 == 2'b11) begin
            if ((CPUNC0_BVALID == 1'b1) && (CPUNC_BREADY == 1'b1)) begin
                axi_w_state0 <= '0;
            end
        end
    end
end


// ------ Memory agent instances ------
axi_mem
#(
    .MEM_POWER_SIZE     (MEM0_POWER_SIZE), 
    .AXI_DATA_WIDTH     (AXI0_DATA_WIDTH), 
    .AXI_ADDR_WIDTH     (AXI0_ADDR_WIDTH), 
    .AXI_MASK_WIDTH     (AXI0_MASK_WIDTH) 
)
i_axi_mem0
(
    // System
    .CPUNC_ARESETn      (rst_n), 
    .CPUNC_ACLK         (clk),
    
    // Slave interface
    // Write Address Channel:
    .CPUNC_AWID         (CPUNC0_AWID   ),
    .CPUNC_AWADDR       (CPUNC0_AWADDR ),
    .CPUNC_AWLN         (CPUNC0_AWLN   ),
    .CPUNC_AWSIZE       (CPUNC0_AWSIZE ),
    .CPUNC_AWBURST      (CPUNC0_AWBURST),
    .CPUNC_AWLOCK       (CPUNC0_AWLOCK ),
    .CPUNC_AWCACHE      (CPUNC0_AWCACHE),
    .CPUNC_AWPROT       (CPUNC0_AWPROT ),
    .CPUNC_AWQOS        (CPUNC0_AWQOS  ),
    .CPUNC_AWVALID      (CPUNC0_AWVALID),
    .CPUNC_AWREADY      (CPUNC0_AWREADY),
    // Write Data Channel:
    .CPUNC_WID          (CPUNC0_WID   ),
    .CPUNC_WDATA        (CPUNC0_WDATA ),
    .CPUNC_WSTRB        (CPUNC0_WSTRB ),
    .CPUNC_WLAST        (CPUNC0_WLAST ),
    .CPUNC_WVALID       (CPUNC0_WVALID),
    .CPUNC_WREADY       (CPUNC0_WREADY),
    // Write Response Channel:
    .CPUNC_BID          (CPUNC0_BID   ),
    .CPUNC_BRESP        (CPUNC0_BRESP ),
    .CPUNC_BVALID       (CPUNC0_BVALID),
    .CPUNC_BREADY       (CPUNC0_BREADY),
    // Read Address Channel:
    .CPUNC_ARID         (CPUNC0_ARID   ),
    .CPUNC_ARADDR       (CPUNC0_ARADDR ),
    .CPUNC_ARLN         (CPUNC0_ARLN   ),
    .CPUNC_ARSIZE       (CPUNC0_ARSIZE ),
    .CPUNC_ARBURST      (CPUNC0_ARBURST),
    .CPUNC_ARLOCK       (CPUNC0_ARLOCK ),
    .CPUNC_ARCACHE      (CPUNC0_ARCACHE),
    .CPUNC_ARPROT       (CPUNC0_ARPROT ),
    .CPUNC_ARQOS        (CPUNC0_ARQOS  ),
    .CPUNC_ARVALID      (CPUNC0_ARVALID),
    .CPUNC_ARREADY      (CPUNC0_ARREADY),
    // Read Address Channel:
    .CPUNC_RID          (CPUNC0_RID   ),
    .CPUNC_RDATA        (CPUNC0_RDATA ),
    .CPUNC_RRESP        (CPUNC0_RRESP ),
    .CPUNC_RLAST        (CPUNC0_RLAST ),
    .CPUNC_RVALID       (CPUNC0_RVALID),
    .CPUNC_RREADY       (CPUNC0_RREADY) 
);





///// Send of 0 enables spike execution, send 1 stop spike execution
///// No return until connect to spike
//import "DPI-C" function void spikeSetReset(logic a);
//
///// Need call each clock 
///// \return 0 - no transaction in this clock, 1 - read transaction, 2 - write transaction 
//import "DPI-C" context function int spikeClock();
//
///// If spikeClock() != 0 then there is transaction from spike to vcs
///// \return transaction address
////import "DPI-C" context function longint spikeGetAddress();
//import "DPI-C" context function int spikeGetAddress();
//
///// If spikeClock() != 0 then there is transaction from spike to vcs
///// \return transaction size
//import "DPI-C" context function int spikeGetSize();
//
///// If spikeClock() != 2 then there is write transaction from spike to vcs
///// \return data to write
////import "DPI-C" context function longint spikeGetData();
//import "DPI-C" context function int spikeGetData();
//
///// If spikeClock() != 1 then there is read transaction from spike to vcs
///// \param data read data
////import "DPI-C" context function void spikeSetData(longint data);
//import "DPI-C" context function void spikeSetData(int data);
//
///// Each clock with or without transaction should be finished with call of this function
//import "DPI-C" context function void spikeEndClock();
//
//
//
//logic               rst_n       = 1'b1;
//logic               clk         = 1'b0;
//int                 spikeCmd;
//int                 spikeAddr;
//int                 spikeSize;
//int                 spikeWdata;
//int                 spikeRdata;
//
//logic               io_req;
//logic               io_wr;
//logic   [3:0]       io_wen;
//logic   [31:0]      io_addr;
//logic   [31:0]      io_wdata;
//logic               io_req_ack;
//logic   [31:0]      io_rdata;
//logic               io_data_ack;
//
//
//logic   [7:0]      io_memory [0:255];
//
//// Reset Logic
//initial begin
//    $display("TB: start");
//    rst_n   = 1'b0;
//    #100ns rst_n    = 1'b1;
//
//    // Start Spike
//    spikeSetReset(1'b0);
//    
//    #1us;    
//    $display("TB: finish");
//    $finish;       
//end
//
//always begin
//    #5ns clk = ~clk;
//end
//
//
//
//
//initial begin
//    io_req   = 1'b0;
//    io_wr    = 1'bx;
//    io_wen   = 'x;
//    io_addr  = 'x;
//    io_wdata = 'x;
//    @(posedge rst_n);
//    while (rst_n == 1'b1) begin
//        @(posedge clk);
//        spikeCmd = spikeClock();
//        #1
//        case (spikeCmd)
//            0 : begin
//                // Todo Nothing
//            end
//            1 : begin
//                // Read from IO
//                spikeAddr  = spikeGetAddress();
//                spikeSize  = spikeGetSize();
//                
//                // Convert to logic
//                io_addr = unsigned'(spikeAddr);
//                if (io_addr[31:28] != 4'hF) begin
//                    $error("Wrong address to read from IO");
//                end
//                // Check allignment
//                case (spikeSize)
//                    1 : begin 
//                        // It is ok
//                    end
//                    2 : begin
//                        assert (io_addr[0] == 1'b0) else $error("Unaligned addres for read HWORD");
//                    end
//                    4 : begin
//                        assert (io_addr[1:0] == 2'b00) else $error("Unaligned addres for read WORD");
//                    end
//                    default : begin
//                        assert (0) else $error("Wrong size accesss for Reading");
//                    end
//                endcase
//                // Start reading
//                io_req = 1'b1;
//                io_wr  = 1'b0;
//                @(posedge clk);
//                while (io_req_ack == 1'b0) begin
//                    @(posedge clk);
//                end
//                //@(posedge clk);
//                #1
//                io_req = 1'b0;
//                io_wr  = 1'bx;
//                io_addr = 'x;
//                
//                // Wait for RDATA
//                @(posedge clk);
//                while (io_data_ack == 1'b0) begin
//                    @(posedge clk);
//                end
//
//                // Return RDATA
//                spikeSetData(int'(io_rdata));
//            end    
//
//            2 : begin
//                // Write to IO
//                spikeAddr  = spikeGetAddress();
//                spikeSize  = spikeGetSize();
//                spikeWdata = spikeGetData();
//                
//                // Convert to logic
//                io_addr = unsigned'(spikeAddr);
//                if (io_addr[31:28] != 4'hF) begin
//                    $error("Wrong address to read from IO");
//                end
//                io_wdata = unsigned'(spikeWdata);
//                // Check allignment
//                case (spikeSize)
//                    1 : begin 
//                        // It is ok
//                        io_wen = 4'b0001;
//                    end
//                    2 : begin
//                        assert (io_addr[0] == 1'b0) else $error("Unaligned addres for read HWORD");
//                        io_wen = 4'b0011;
//                    end
//                    4 : begin
//                        assert (io_addr[1:0] == 2'b00) else $error("Unaligned addres for read WORD");
//                        io_wen = 4'b1111;
//                    end
//                    default : begin
//                        $display("spikeSize: %d",spikeSize);
//                        assert (0) else $error("Wrong size accesss for Reading"); 
//                    end
//                endcase
//                // Start reading
//                io_req = 1'b1;
//                io_wr  = 1'b1;
//                @(posedge clk);
//                while (io_req_ack == 1'b0) begin
//                    @(posedge clk);
//                end
//                //@(posedge clk);
//                #1
//                io_req = 1'b0;
//                io_wr  = 1'bx;
//                io_wen = 'x;
//                io_addr = 'x;
//                
//                // Wait for RDATA
//                @(posedge clk);
//                while (io_data_ack == 1'b0) begin
//                    @(posedge clk);
//                end
//
//            end    
//            default : begin
//                assert (0) else $error("Wrong command from Spike");
//            end
//        endcase
//        spikeEndClock();
//    end
//end
//
//
////// Memory 
//assign io_req_ack = io_req;
//
//always_ff @(negedge rst_n, posedge clk) begin
//    if (rst_n == 1'b0) begin
//        io_data_ack <= 1'b0;
//    end else begin
//        io_data_ack <= io_req & io_req_ack;
//    end
//end
//
//
//
//always_ff @(posedge clk) begin
//    if ((io_req == 1'b1) && (io_req_ack == 1'b1) && (io_wr == 1'b0)) begin
//        for (int unsigned i=0; i<4; ++i) begin
//            io_rdata[(i+1)*8-1-:8] <= io_memory[io_addr[7:0]+i];
//        end
//    end else begin
//        io_rdata <= 'x;
//    end
//end
//
//always_ff @(posedge clk) begin
//    if ((io_req == 1'b1) && (io_req_ack == 1'b1) && (io_wr == 1'b1)) begin
//        for (int unsigned i=0; i<4; ++i) begin
//            io_memory[io_addr[7:0]+i] <= io_wdata[(i+1)*8-1-:8];
//        end
//    end
//end
//
//
//
//
//
//

endmodule : spike_tb

