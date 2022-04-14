`timescale 1ns/1ns

module AHB_TOP_TEST ();
  // Global Signals
  reg Clk;
  reg Rst;
  // User Inferace Signals
  reg [31:0] gpioW;
  reg [31:0] cAddr;
  reg en;
  reg cWr;
  reg [1:0] ss;
  // Data Out
  wire [31:0] dout;
  wire [7:0] LED;
  
  // Clocking and Reset Block
  
  initial
    begin
       Clk = 0;
       Rst = 0;
       #12;
       Rst = 1;
       gpioW = 0;
       cAddr = 0;
       en = 0;
       cWr = 0;
       ss = 0;
       forever #2 Clk = ~Clk;
    end
  
  // Design under Test
  
  AHB_TOP DUT (
    .Clk(Clk),
    .Rst(Rst),
    .gpioW(gpioW),
    .cAddr(cAddr),
    .en(en),
    .cWr(cWr),
    .ss(ss),
    .dout(dout),
    .LED(LED)
  );
  
  // GPIO Read
  task GPIO_R ();
    begin
      en  = 1;
      cWr = 0;
      ss  = 2'b00; 
    end
  endtask
  
  // GPIO Write
  task GPIO_W (input [7:0] led);
    begin
       en = 1;
       cWr = 1;
       ss = 2'b00;
      gpioW = {24'b0, led};
    end
  endtask
  
  // Main Loop Block
  
  
  initial
    begin
      $dumpfile ("AHB_Lite_Bus_IO1.vcd");
      $dumpvars();
      #24;
      GPIO_R();
      #20;
      GPIO_W(8'b0000_1010);
      #20;
      GPIO_R();
      #100 $finish;
    end
endmodule
