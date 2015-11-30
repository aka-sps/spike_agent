//////////////////////////
// Test Bench for Spike
// authors: Dmitri Pavlov
//////////////////////////

module spike_tb (
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



logic               rst_n       = 1'b1;
logic               clk         = 1'b0;
int                 spikeCmd;
int                 spikeAddr;
int                 spikeSize;
int                 spikeWdata;
int                 spikeRdata;

logic               io_req;
logic               io_wr;
logic   [3:0]       io_wen;
logic   [31:0]      io_addr;
logic   [31:0]      io_wdata;
logic               io_req_ack;
logic   [31:0]      io_rdata;
logic               io_data_ack;


logic   [7:0]      io_memory [0:255];

// Reset Logic
initial begin
    $display("TB: start");
    rst_n   = 1'b0;
    #100ns rst_n    = 1'b1;

    // Start Spike
    spikeSetReset(1'b0);
    
    #100ms;    
    $display("TB: finish");
    $finish;       
end

always begin
    #5ns clk = ~clk;
end




initial begin
    io_req   = 1'b0;
    io_wr    = 1'bx;
    io_wen   = 'x;
    io_addr  = 'x;
    io_wdata = 'x;
    @(posedge rst_n);
    while (rst_n == 1'b1) begin
        @(negedge clk);
        spikeCmd = spikeClock();
        case (spikeCmd)
            0 : begin
                // Todo Nothing
            end
            1 : begin
                // Read from IO
                spikeAddr  = spikeGetAddress();
                spikeSize  = spikeGetSize();
                
                // Convert to logic
                io_addr = unsigned'(spikeAddr);
                if (io_addr[31:28] != 4'hF) begin
                    $error("Wrong address to read from IO");
                end
                // Check allignment
                case (spikeSize)
                    1 : begin 
                        // It is ok
                    end
                    2 : begin
                        assert (io_addr[0] == 1'b0) else $error("Unaligned addres for read HWORD");
                    end
                    4 : begin
                        assert (io_addr[1:0] == 2'b00) else $error("Unaligned addres for read WORD");
                    end
                    default : begin
                        assert (0) else $error("Wrong size accesss for Reading");
                    end
                endcase
                // Start reading
                io_req = 1'b1;
                io_wr  = 1'b0;
                @(posedge clk);
                while (io_req_ack == 1'b0) begin
                    @(posedge clk);
                end
                @(negedge clk);
                io_req = 1'b0;
                io_wr  = 1'bx;
                io_addr = 'x;
                
                // Wait for RDATA
                @(posedge clk);
                while (io_data_ack == 1'b0) begin
                    @(posedge clk);
                end

                // Return RDATA
                spikeSetData(int'(io_rdata));
            end    

            2 : begin
                // Write to IO
                spikeAddr  = spikeGetAddress();
                spikeSize  = spikeGetSize();
                spikeWdata = spikeGetData();
                
                // Convert to logic
                io_addr = unsigned'(spikeAddr);
                if (io_addr[31:28] != 4'hF) begin
                    $error("Wrong address to read from IO");
                end
                io_wdata = unsigned'(spikeWdata);
                // Check allignment
                case (spikeSize)
                    1 : begin 
                        // It is ok
                        io_wen = 4'b0001;
                    end
                    2 : begin
                        assert (io_addr[0] == 1'b0) else $error("Unaligned addres for read HWORD");
                        io_wen = 4'b0011;
                    end
                    4 : begin
                        assert (io_addr[1:0] == 2'b00) else $error("Unaligned addres for read WORD");
                        io_wen = 4'b1111;
                    end
                    default : begin
                        $display("spikeSize: %d",spikeSize);
                        assert (0) else $error("Wrong size accesss for Reading"); 
                    end
                endcase
                // Start reading
                io_req = 1'b1;
                io_wr  = 1'b1;
                @(posedge clk);
                while (io_req_ack == 1'b0) begin
                    @(posedge clk);
                end
                @(negedge clk);
                io_req = 1'b0;
                io_wr  = 1'bx;
                io_wen = 'x;
                io_addr = 'x;
                
                // Wait for RDATA
                @(posedge clk);
                while (io_data_ack == 1'b0) begin
                    @(posedge clk);
                end

            end    
            default : begin
                assert (0) else $error("Wrong command from Spike");
            end
        endcase
        spikeEndClock();
    end
end


//// Memory 
assign io_req_ack = io_req;

always_ff @(negedge rst_n, posedge clk) begin
    if (rst_n == 1'b0) begin
        io_data_ack <= 1'b0;
    end else begin
        io_data_ack <= io_req & io_req_ack;
    end
end



always_ff @(posedge clk) begin
    if ((io_req == 1'b1) && (io_req_ack == 1'b1) && (io_wr == 1'b0)) begin
        for (int unsigned i=0; i<4; ++i) begin
            io_rdata[(i+1)*8-1-:8] <= io_memory[io_addr[7:0]+i];
        end
    end else begin
        io_rdata <= 'x;
    end
end

always_ff @(posedge clk) begin
    if ((io_req == 1'b1) && (io_req_ack == 1'b1) && (io_wr == 1'b1)) begin
        for (int unsigned i=0; i<4; ++i) begin
            io_memory[io_addr[7:0]+i] <= io_rdata[(i+1)*8-1-:8];
        end
    end
end







endmodule : spike_tb

