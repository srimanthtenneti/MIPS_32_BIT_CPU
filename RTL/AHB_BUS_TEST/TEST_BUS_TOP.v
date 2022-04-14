  module AHB_TOP (
  // Global Signals
  input Clk,
  input Rst,
  // User Inferace Signals
  input [31:0] gpioW,
  input [31:0] cAddr,
  input en,
  input cWr, 
  input [1:0] ss,
  // Data Out
  output [31:0] dout,
  output [7:0] LED
  
);
  
  // Master Interface
  
  wire hReadyout;
  wire hResp;
  wire [31:0] hRdata;
  wire [1:0] sel;
  wire [31:0] hAddr;
  wire hWrite;
  wire [2:0] hSize;
  wire [1:0] hTrans;
  wire hMastlock;
  wire [31:0] hWdata;
  wire hReady;
  
  wire [31:0] hRdata_M;
  wire hReady_M;
  
  wire [31:0] hRdata_io;
  wire hReady_io;
  
 
  
  // Mux 
  
  wire [31:0] hRdata0;
  wire [31:0] hRdata1;
  wire [31:0] hRdata2;
  wire [31:0] hRdata3;
  
  wire hReadyout0;
  wire hReadyout1;
  wire hReadyout2;
  wire hReadyout3;
  
 
 
  
  AHB2IO IO32(
    .HCLK(Clk),
    .HRESETn(Rst),
    .HREADY(hReady),
    .HADDR(hAddr),
    .HTRANS(hTrans),
    .HWRITE(hWrite),
    .HSIZE(hSize),
    .HWDATA(hWdata),
    .HREADYOUT(hReady_io),
    .HRDATA(hRdata_io),
    .LED(LED)
);
  
   AHB_MUX Mux0(
  // Slave Read Data
     .hRdata0(hRdata_io),
    .hRdata1(hRdata1),
    .hRdata2(hRdata2),
    .hRdata3(hRdata3),
  // Slave Ready Signal
     .hReadyout0(hReady_io),
    .hReadyout1(hReadyout1),
    .hReadyout2(hReadyout2),
    .hReadyout3(hReadyout3),
  // Slave Select 
    .ss(ss),
  // Muxed Output
    .hRdata(hRdata_M),
    .hReadyout(hReady_M)
);
  
  
  ahb_master M0(
  // Global Clock & Rest
    .hClk(Clk),
    .hRst(Rst),
  // User Interface Signals
    .cData(gpioW),
    .cAddr(cAddr),
    .en(en),
    .cWr(cWr),
  // Slace Loopback Signals
    .hReadyout(hReady_M),
    .hResp(hResp),
    .hRdata(hRdata_M),
  // Slave Select Signal
    .ss(ss),
  // Slave Select
    .sel(sel),
  // Main AHB Address
    .hAddr(hAddr),
  // Read & Write Control Signal
    .hWrite(hWrite),
  // Transfer Size (Used to set transfer size)
    .hSize(hSize),
  // Transfer State signal
    .hTrans(hTrans),
  // Ready Signal
    .hReady(hReady),
  // Bus Write Data
    .hWdata(hWdata),
  // User Output
    .dout(dout)
);
  
endmodule
