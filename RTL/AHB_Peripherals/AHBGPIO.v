module AHB2IO(
   input wire HCLK,
   input wire HRESETn,
	input wire HREADY,
	input wire [31:0] HADDR,
	input wire [1:0] HTRANS,
	input wire HWRITE,
	input wire [2:0] HSIZE,
	input wire [31:0] HWDATA,
	output wire HREADYOUT,
	output wire [31:0] HRDATA,
	output wire [7:0] LED
);

//Address Phase Sampling Registers
  reg [31:0] rHADDR;
  reg [1:0] rHTRANS;
  reg rHWRITE;
  reg [2:0] rHSIZE;

  reg [7:0] rLED;
 
//Address Phase Sampling
  always @(posedge HCLK or negedge HRESETn)
  begin
	 if(!HRESETn)
	 begin
		rHADDR	<= 32'h0;
		rHTRANS	<= 2'b00;
		rHWRITE	<= 1'b0;
		rHSIZE	<= 3'b000;
	 end
    else if(HREADY)
    begin
		rHADDR	<= HADDR;
		rHTRANS	<= HTRANS;
		rHWRITE	<= HWRITE;
		rHSIZE	<= HSIZE;
    end
  end

//Data Phase data transfer
  always @(posedge HCLK or negedge HRESETn)
  begin
    if(!HRESETn)
      rLED <= 8'b0000_0000;
    else if(rHWRITE & ~rHTRANS[1])
      rLED <= HWDATA[7:0];
  end

//Transfer Response
  assign HREADYOUT = 1'b1; //Single cycle Write & Read. Zero Wait state operations

//Read Data  
  assign HRDATA = {24'h0000_00,rLED};

  assign LED = rLED;

endmodule
