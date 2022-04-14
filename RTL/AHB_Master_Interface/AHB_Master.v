/* 
  Design : AHB Master (CPU)
  Designer : Srimanth Tenneti
  Date : 14th April 2o22
*/

module ahb_master (
  // Global Clock & Rest
  input hClk,
  input hRst,
  // User Interface Signals
  input [31:0] cData,
  input [31:0] cAddr,
  input en,
  input cWr,
  // Slace Loopback Signals
  input hReadyout,
  input hResp,
  input [31:0] hRdata,
  // Slave Select Signal
  input [1:0] ss,
  

  // Slave Select
  output reg [1:0] sel,
  // Main AHB Address
  output reg [31:0] hAddr,
  // Read & Write Control Signal
  output reg hWrite,
  // Transfer Size (Used to set transfer size)
  output reg [2:0] hSize,
  // Transfer State signal
  output reg [1:0] hTrans,
  // Ready Signal
  output reg hReady,
  // Bus Write Data
  output reg [31:0] hWdata,
  // User Output
  output reg [31:0] dout
);
  
  // Master State Machine Declarations
  
  reg [1:0] state, next_state;
  
  parameter IDLE  = 2'b00;
  parameter BASE  = 2'b01;
  parameter ST2   = 2'b10;
  parameter ST3   = 2'b11;
  
  // Master State Machine
  
  
  // Present State Logic
  always @ (posedge hClk or negedge hRst)
    begin
      if (~hRst)
        begin
          state = IDLE;
        end
      else
        begin
           state = next_state;
        end
    end
  
  
  // Next State Decoder Logic
  always @ (*)
    begin
      case(state)
        // IDLE State Logic
        IDLE : begin
          if (en)
            next_state = BASE;
          else
            next_state = IDLE;
        end
        
        BASE : begin
          if (cWr)
            next_state = ST2;
          else
            next_state = ST3;
        end
        
        ST2 : begin
          if (en)
            next_state = BASE;
          else
            next_state = IDLE;
        end
        
        ST3 : begin
          if (en)
            next_state = BASE;
          else
            next_state = IDLE;
        end      
        
        default : next_state = IDLE;
        
      endcase
      
    end
  
  
  // Output Logic
  always @ (posedge hClk or negedge hRst)
    begin
      if (~hRst)
        begin
           sel       <= 0;
           hAddr     <= 0;
           hWrite    <= 0;
           hSize     <= 0;
           hTrans    <= 0;
           hReady    <= 0;
           hWdata    <= 0;
           dout      <= 0;
        end
      
      else
        begin
          case (next_state)
             IDLE : begin
                sel    <= ss;
                hAddr  <= cAddr;
                hWrite <= hWrite;
                hReady <= 0;
                hWdata <= hWdata;
                dout   <= dout;
             end
            
            BASE : begin
               sel    <= ss;
               hAddr  <= cAddr;
               hWrite <= cWr;
               hReady <= 1;
               hWdata <= cData;
               dout   <= dout;
            end
            
            ST2 : begin
               sel    <= sel;
               hAddr  <= cAddr;
               hWrite <= cWr;
               hReady <= 1;
               hWdata <= cData;
               dout   <= dout;
            end
            
            ST3 : begin
               sel    <= sel;
               hAddr  <= cAddr;
               hWrite <= cWr;
               hReady <= 1;
               hWdata <= hWdata;
               dout   <= hRdata;
            end
            
            default : begin
               sel    <= ss;
               hAddr  <= hAddr;
               hWrite <= hWrite;
               hReady <= 0;
               hWdata <= hWdata;
               dout   <= dout;
            end
            
          endcase
          
        end
    end
  
endmodule
  
