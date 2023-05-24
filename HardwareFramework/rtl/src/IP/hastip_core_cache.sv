// default_nettype of none prevents implicit wire declaration.
`default_nettype none
module hastip_core_cache #(
  parameter integer C_M00_AXI_ADDR_WIDTH = 0,
  parameter integer C_M00_AXI_DATA_WIDTH = 0,
  parameter integer HAST_IP_DATA_WIDTH   = 0
)
(
  // System Signals
  input  wire                              ap_clk         ,
  input  wire                              ap_rst_n       ,
  // AXI4 master interface m00_axi
  output reg                               m00_axi_awvalid = 0,
  input  wire                              m00_axi_awready,
  output reg  [C_M00_AXI_ADDR_WIDTH-1:0]   m00_axi_awaddr  = 0,
  output reg  [8-1:0]                      m00_axi_awlen   = 0,
  output reg                               m00_axi_wvalid  = 0,
  input  wire                              m00_axi_wready ,
  output reg  [C_M00_AXI_DATA_WIDTH-1:0]   m00_axi_wdata   = 0,
  output reg  [C_M00_AXI_DATA_WIDTH/8-1:0] m00_axi_wstrb   = 0,
  output reg                               m00_axi_wlast   = 0,
  input  wire                              m00_axi_bvalid ,
  output reg                               m00_axi_bready  = 0,
  output reg                               m00_axi_arvalid = 0,
  input  wire                              m00_axi_arready,
  output reg  [C_M00_AXI_ADDR_WIDTH-1:0]   m00_axi_araddr  = 0,
  output reg  [8-1:0]                      m00_axi_arlen   = 0,
  input  wire                              m00_axi_rvalid ,
  output reg                               m00_axi_rready  = 0,
  input  wire [C_M00_AXI_DATA_WIDTH-1:0]   m00_axi_rdata  ,
  input  wire                              m00_axi_rlast  ,
  // Hast_IP Signals
  output reg [HAST_IP_DATA_WIDTH-1:0] hastipDataIn,
  input wire [HAST_IP_DATA_WIDTH-1:0] hastipDataOut,
  input wire [31:0] hastipCellIndex,
  input wire hastipReadEnable,
  input wire hastipWriteEnable,
  output reg hastipReadsDone,
  output reg hastipWritesDone,
  input wire [64-1:0] axi00_ptr0,
  input wire cacheFlush,
  input wire cacheWriteEnable,
  input wire cacheReadEnable,
  output wire cacheDirty
);

timeunit 1ps;
timeprecision 1ps;

(* KEEP = "yes" *)
logic areset = 1'b0;

// Register and invert reset signal.
always @(posedge ap_clk) begin
  areset <= ~ap_rst_n;
end

typedef enum {
  IDLE,
  WRB_ADDR,
  WRB_DATA,
  WR_ADDR,
  WR_DATA,
  WR_DONE,
  RD_ADDR,
  RD_DATA,
  RD_DONE,
  LAST
} AXI_State_Type;

AXI_State_Type axi_state = IDLE;

wire [C_M00_AXI_ADDR_WIDTH-1:0] current_axi_addr;
assign current_axi_addr = axi00_ptr0 + 4 * hastipCellIndex;

wire [C_M00_AXI_ADDR_WIDTH-1:0] current_cache_line_addr;
assign current_cache_line_addr = current_axi_addr & ~(C_M00_AXI_DATA_WIDTH/8-1);

wire [4:0] current_cache_line_index;
assign current_cache_line_index = (current_axi_addr & (C_M00_AXI_DATA_WIDTH/8-1)) / 4;

reg [C_M00_AXI_ADDR_WIDTH-1:0] stored_cache_line_addr;
reg [C_M00_AXI_DATA_WIDTH-1:0] stored_cache_line_data;
reg stored_cache_line_dirty;

assign cacheDirty = stored_cache_line_dirty;

always @(posedge ap_clk) begin
  if (areset) begin
    axi_state <= IDLE;
    stored_cache_line_addr <= -1;
    stored_cache_line_dirty <= 0;
  end
  else begin
    // stored_cache_line_addr <= -2; // disable cache
    case (axi_state)

      IDLE:
        begin
            hastipDataIn <= 32'b0;
            hastipReadsDone <= 1'b0;
            hastipWritesDone <= 1'b0;

            m00_axi_awvalid <= 1'b0;
            m00_axi_awaddr <= 0;
            m00_axi_awlen <= 0;
            m00_axi_wvalid <= 1'b0;
            m00_axi_wdata  <= 0;
            m00_axi_wstrb <= 0;
            m00_axi_wlast <= 1'b1;
            m00_axi_bready <= 1'b1;

            m00_axi_arvalid <= 1'b0;
            m00_axi_araddr <= 0;
            m00_axi_arlen <= 0;
            m00_axi_rready <= 1'b0;

            if (cacheFlush && stored_cache_line_dirty) begin
              $display("%0d:  ... cache_writeback: %x", $time, stored_cache_line_data);
              axi_state <= WRB_ADDR;
            end else if (hastipWriteEnable) begin
                $display("%0d: CACHE-WR-req: %x, %x", $time, hastipCellIndex, hastipDataOut);
                if (cacheWriteEnable == 0) begin
                  $display("%0d:  ... axi_nocachewrite: %x, %x, %x", $time, current_cache_line_addr, current_cache_line_index, hastipDataOut);
                  axi_state <= WR_ADDR;
                end else if (current_cache_line_addr == stored_cache_line_addr) begin
                  stored_cache_line_data[32*current_cache_line_index+:32] <= hastipDataOut;
                  stored_cache_line_dirty <= 1;
                  $display("%0d:  ... cache_write: %x, %x", $time, current_cache_line_index, hastipDataOut);
                  hastipWritesDone <= 1'b1;
                  axi_state <= WR_DONE;
                end else if (stored_cache_line_dirty) begin
                  $display("%0d:  ... cache_writeback: %x", $time, stored_cache_line_data);
                  axi_state <= WRB_ADDR;
                end else begin
                  $display("%0d:  ... axi_read: %x, %x", $time, current_cache_line_addr, current_cache_line_index);
                  axi_state <= RD_ADDR;
                end
            end else if (hastipReadEnable) begin
                $display("%0d: CACHE-RD-req: %x", $time, hastipCellIndex);
                if (cacheReadEnable == 0) begin
                  $display("%0d:  ... axi_nocache-read: %x, %x", $time, current_cache_line_addr, current_cache_line_index);
                  axi_state <= RD_ADDR;
                end else if (current_cache_line_addr == stored_cache_line_addr) begin
                  hastipDataIn <= stored_cache_line_data[32*current_cache_line_index+:32];
                  hastipReadsDone <= 1'b1;
                  $display("%0d:  ... cache_read: %x, %x", $time, current_cache_line_index, stored_cache_line_data[32*current_cache_line_index+:32]);
                  axi_state <= RD_DONE;
                end else if (stored_cache_line_dirty) begin
                  $display("%0d:  ... cache_writeback: %x", $time, stored_cache_line_data);
                  axi_state <= WRB_ADDR;
                end else begin
                  $display("%0d:  ... axi_read: %x, %x", $time, current_cache_line_addr, current_cache_line_index);
                  axi_state <= RD_ADDR;
                end
            end
        end

      WRB_ADDR:
          begin
              m00_axi_awaddr <= stored_cache_line_addr;
              m00_axi_awvalid <= 1'b1;
              if (m00_axi_awvalid && m00_axi_awready) begin
                  m00_axi_awvalid <= 1'b0;
                  axi_state <= WRB_DATA;
              end
          end

      WRB_DATA:
          begin
              m00_axi_wdata <= stored_cache_line_data;
              m00_axi_wstrb <= -1;
              m00_axi_wvalid <= 1'b1;
              if (m00_axi_wvalid && m00_axi_wready) begin
                  m00_axi_wvalid <= 1'b0;
                  stored_cache_line_addr <= -1;
                  stored_cache_line_data <= 0;
                  stored_cache_line_dirty <= 0;
                  axi_state <= IDLE;
              end
          end

      WR_ADDR:
          begin
              m00_axi_awaddr <= current_cache_line_addr;
              m00_axi_awvalid <= 1'b1;
              if (m00_axi_awvalid && m00_axi_awready) begin
                  m00_axi_awvalid <= 1'b0;
                  axi_state <= WR_DATA;
              end
          end

      WR_DATA:
          begin
              m00_axi_wdata <= 0;
              m00_axi_wdata[32*current_cache_line_index+:32] <= hastipDataOut;
              m00_axi_wstrb <= 0;
              m00_axi_wstrb[4*current_cache_line_index+:4] <= 4'b1111;
              m00_axi_wvalid <= 1'b1;
              if (m00_axi_wvalid && m00_axi_wready) begin
                  m00_axi_wvalid <= 1'b0;
                  hastipWritesDone <= 1'b1;
                  axi_state <= WR_DONE;
              end
          end

      WR_DONE:
          begin
              if (hastipWriteEnable == 0) begin
                  hastipWritesDone <= 1'b0;
                  axi_state <= IDLE;
              end
          end

      RD_ADDR:
          begin
              m00_axi_araddr <= current_cache_line_addr;
              m00_axi_arvalid <= 1'b1;
              if (m00_axi_arvalid && m00_axi_arready) begin
                  m00_axi_arvalid <= 1'b0;
                  axi_state <= RD_DATA;
              end
          end

      RD_DATA:
          begin
            if (m00_axi_rvalid) begin
              stored_cache_line_addr <= current_cache_line_addr;
              stored_cache_line_data <= m00_axi_rdata;
              stored_cache_line_dirty <= 0;
              m00_axi_rready <= 1'b1;
              hastipDataIn <= m00_axi_rdata[32*current_cache_line_index+:32];
              hastipReadsDone <= 1'b1;
              // $display("%0d: axi_read: %x", $time, m00_axi_rdata[32*current_cache_line_index+:32]);
              $display("%0d:  ... axi_read: %x", $time, m00_axi_rdata);
              axi_state <= RD_DONE;
            end
          end

      RD_DONE:
          begin
            m00_axi_rready <= 1'b0;
            if (hastipReadEnable == 0) begin
                hastipReadsDone <= 1'b0;
                axi_state <= IDLE;
            end
          end

      default:
          begin
              axi_state <= IDLE;
          end
    endcase
  end
end // always

endmodule : hastip_core_cache
`default_nettype wire
