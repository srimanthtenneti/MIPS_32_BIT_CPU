module AHB_MUX (
  // Slave Read Data
  input [31:0] hRdata0,
  input [31:0] hRdata1,
  input [31:0] hRdata2,
  input [31:0] hRdata3,
  // Slave Ready Signal
  input hReadyout0,
  input hReadyout1,
  input hReadyout2,
  input hReadyout3,
  // Slave Select 
  input [1:0] ss,
  // Muxed Output
  output reg [31:0] hRdata,
  output reg hReadyout
);
  
  always @ *
    begin
      case(ss)
        2'b00 : begin
           hRdata = hRdata0;
           hReadyout = hReadyout0;
        end
        2'b01 : begin
           hRdata = hRdata1;
           hReadyout = hReadyout1;
        end
        2'b10 : begin
           hRdata = hRdata2;
           hReadyout = hReadyout2;
        end
        2'b11 : begin
           hRdata = hRdata3;
           hReadyout = hReadyout3;
        end
      endcase
    
    end
  
endmodule
  
  
