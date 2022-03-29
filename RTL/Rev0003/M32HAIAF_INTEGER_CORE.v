//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// Design        : M32HAIAF INTEGER CORE
// Aarch         : MIPS32
// Organization  : Harvard  
// Designer      : Srimanth Tenneti 
// Revision      : Rev0003
// Date          : 29th March 2022
// Instr Types   : R,I,J 
// I/Os          : VGA, UART
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   

module M32HAIAF_INTEGER_CORE (
// Global Signals -> Clock and Reset
input coreClk,
input coreRst,
// Instruction
input [31:0] instr,
// Data from memory
input [31:0] dfm, 
// Program Counter
output reg [31:0] pc,
// Memory or I/O Address
output [31:0] maddr,
// Data to Store
output [31:0] data2mem,
// Data Memory Write Signal
output write,
// Video RAM Write Signal
output wVram,
// Video RAM Read Signal
output rVram,
// I/O Write
output ioWr,
// I/O Read
output ioRd
);

// CPU Internal Signals
// Control
// Write regfile
reg wreg;
// Write Memory
reg wmem;
// Read Memory
reg rmem;
// ALU Output
reg [31:0] alu_out;
// Destination Register
reg [4:0] destRn;
// Next PC
reg [31:0] nxtPc;
// PC -> PC + 4
wire [31:0] pc_plus_4 = pc + 4;

// Instruction Format
// OPCODE
wire [5:0] opcode = instr[31:26];
// RS 
wire [4:0] rs     = instr[25:21];
// RT
wire [4:0] rt     = instr[20:16]; 
// RD
wire [4:0] rd     = instr[15:11];
// SA
wire [4:0] sa     = instr[10:6];
// FUNC
wire [5:0] func   = instr[5:0];
// Immediate Data
wire [15:0] imm   = instr[15:0];
// Jump Address
wire [25:0] addr   = instr[25:0];
// Sign Bit
wire sign          = instr[15];
// Address Offset
wire [31:0] offset  = {{14{sign}}, imm, 2'b00};
// Final jump address
wire [31:0] j_addr = {pc_plus_4[31:28], addr, 2'b00};

// Instruction Decode 
// Integer Add
wire iadd = (opcode == 6'h00) & (func == 6'h20); 
// Integer Subtract
wire isub = (opcode == 6'h00) & (func == 6'h22);
// Integer AND
wire iand = (opcode == 6'h00) & (func == 6'h24);
// Integer OR
wire ior  = (opcode == 6'h00) & (func == 6'h25);
// Integer XOR
wire ixor = (opcode == 6'h00) & (func == 6'h26); 
// Integer Shift Left Logical
wire isll = (opcode == 6'h00) & (func == 6'h00);
// Integer Shift Right Logical
wire isrl = (opcode == 6'h00) & (func == 6'h02);
// Integer Shift Right Arithmetic
wire isra = (opcode == 6'h00) & (func == 6'h03);
// Integer Jump Register
wire ijr  = (opcode == 6'h00) & (func == 6'h08);
// Integer Add Immediate
wire iaddi = (opcode == 6'h08); 
// Integer AND Immediate
wire iandi = (opcode == 6'h0c);
// Integer OR Immediate
wire iori  = (opcode == 6'h0d);
// Integer XOR Immediate
wire ixori = (opcode == 6'h0e); 
// Integer Load Word
wire ilw   = (opcode == 6'h23); 
// Integer Store Word
wire isw   = (opcode == 6'h2b);
// Integer Branch on Not Equal 
wire ibne  = (opcode == 6'h05);
// Integer Branch on Equal 
wire ibeq  = (opcode == 6'h04);
// Integer Load Upper Immediate
wire ilui  = (opcode == 6'h0f);
// Integer Jump
wire ij    = (opcode == 6'h02);
// Integer Jump and Link
wire ijal  = (opcode == 6'h03);

// *******************************************************
// Program Counter Logic
// *******************************************************

always @ (posedge coreClk or negedge coreRst)
  begin
     if (~coreRst)
        pc <= 0;
     else
        pc <= nxtPc;
  end  

// ********************************************************
//  Data to Register File logic
// ********************************************************

wire [31:0] d2rf = ilw ? dfm : alu_out;

// Register File
reg [31:0] regFile [1:31]; 

wire [31:0] a = (rs == 0) ? 0 : regFile[rs]; // Read Port 1
wire [31:0] b = (rt == 0) ? 0 : regFile[rt]; // Read Port 2

// ***********************************************************
// Register File Write Port Logic
// ***********************************************************

always @ (posedge coreClk)
  begin
     if (wreg && (destRn != 0))
       regFile[destRn] <= d2rf; 
  end
  
// I/O Space -> a0000000 to bfffffff
wire io_space = alu_out[31] & ~alu_out[30] & alu_out[29]; 

// Video RAM Space -> c0000000 to dfffffff
wire vr_space = alu_out[31] & alu_out[30] & ~alu_out[29];
  
// ************************************************************
//  Output Logic
// ************************************************************

// Data Memory Write Logic
assign write = wmem & ~ io_space & ~vr_space; 

// Data to store
assign data2mem = b;

// Memory Address
assign maddr = alu_out;

// I/O Read
assign ioRd = ~(rmem & io_space); 
// I/O Write
assign ioWr = ~(wmem & io_space);
// Video RAM Write
assign wVram = (wmem & vr_space);
// Video RAM Read
assign rVram = (rmem & vr_space);

// ******************************************************************
// ALU Core Logic 
// ******************************************************************


always @ (*) 
  begin
    alu_out = 0;
    destRn  = rd;
    wreg    = 0;
    wmem    = 0;
    rmem    = 0;
    nxtPc   = pc_plus_4;
    case(1'b1)
      iadd : begin
        alu_out = a + b;
        wreg = 1; 
      end
      isub : begin
        alu_out = a - b;
        wreg = 1;
      end
      iand : begin
        alu_out = a & b;
        wreg = 1;
      end
      ior : begin
        alu_out = a | b;
        wreg = 1;
      end
      ixor : begin
        alu_out = a ^ b;
        wreg = 1;
      end
      isll : begin
        alu_out = b << sa;
        wreg = 1;
      end
      isrl : begin
       alu_out = b >> sa;
       wreg = 1;
      end
      isra : begin
       alu_out = $signed(b) >>> sa;
       wreg = 1;
      end
      ijr : begin
        nxtPc = a;
      end
      iaddi : begin
        alu_out = a + {{16{sign}}, imm};
        destRn = rt;
        wreg = 1;
      end
      iandi : begin
        alu_out = a & {16'h0,imm};
        destRn = rt;
        wreg = 1;
      end
      iori : begin
        alu_out = a | {16'h0,imm};
        destRn = rt;
        wreg = 1;
      end
      ixori : begin
        alu_out = a ^ {16'h0,imm};
        destRn = rt;
        wreg = 1;
      end
      ilw : begin
        alu_out = a + {{16{sign}}, imm};
        destRn = rt;
        rmem = 1;
        wreg = 1;
      end
      isw : begin
        alu_out = a + {{16{sign}}, imm};
        wmem = 1;
      end
      ibeq : begin
        if (a == b)
           nxtPc = pc_plus_4 + offset;
      end
      ibne : begin
        if (a != b)
           nxtPc = pc_plus_4 + offset;
      end
      ilui : begin
        alu_out = {imm, 16'h0};
        destRn = rt;
        wreg = 1;
      end
      ij   : begin
        nxtPc = j_addr;
      end
      ijal : begin 
        alu_out = pc_plus_4;
        wreg = 1;
        destRn = 5'd31;
        nxtPc = j_addr;
      end
      default : ;
     endcase
  end
endmodule
