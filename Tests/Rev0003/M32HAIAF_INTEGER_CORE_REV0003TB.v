//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// Design        : M32HAIAF INTEGER CORE TEST
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

module instrMem (             
  input  [31:0] a,                     // address
  output [31:0] inst                   // instruction
);   
          
// rom cells: 32 words * 32 bits

wire   [31:0] rom [0:31];

    // rom[word_addr] = instruction      // (pc) label   instruction
    
    assign rom[5'h00] = 32'h3c010000;    // (00) main:   lui  $1, 0
    assign rom[5'h01] = 32'h34240050;    // (04)         ori  $4, $1, 80
    assign rom[5'h02] = 32'h20050004;    // (08)         addi $5, $0,  4
    assign rom[5'h03] = 32'h0c000018;    // (0c) call:   jal  sum
    assign rom[5'h04] = 32'hac820000;    // (10)         sw   $2, 0($4)
    assign rom[5'h05] = 32'h8c890000;    // (14)         lw   $9, 0($4)
    assign rom[5'h06] = 32'h01244022;    // (18)         sub  $8, $9, $4
    assign rom[5'h07] = 32'h20050003;    // (1c)         addi $5, $0,  3
    assign rom[5'h08] = 32'h20a5ffff;    // (20) loop2:  addi $5, $5, -1
    assign rom[5'h09] = 32'h34a8ffff;    // (24)         ori  $8, $5, 0xffff
    assign rom[5'h0A] = 32'h39085555;    // (28)         xori $8, $8, 0x5555
    assign rom[5'h0B] = 32'h2009ffff;    // (2c)         addi $9, $0, -1
    assign rom[5'h0C] = 32'h312affff;    // (30)         andi $10,$9, 0xffff
    assign rom[5'h0D] = 32'h01493025;    // (34)         or   $6, $10, $9
    assign rom[5'h0E] = 32'h01494026;    // (38)         xor  $8, $10, $9
    assign rom[5'h0F] = 32'h01463824;    // (3c)         and  $7, $10, $6
    assign rom[5'h10] = 32'h10a00001;    // (40)         beq  $5, $0, shift
    assign rom[5'h11] = 32'h08000008;    // (44)         j    loop2
    assign rom[5'h12] = 32'h2005ffff;    // (48) shift:  addi $5, $0, -1
    assign rom[5'h13] = 32'h000543c0;    // (4c)         sll  $8, $5, 15
    assign rom[5'h14] = 32'h00084400;    // (50)         sll  $8, $8, 16
    assign rom[5'h15] = 32'h00084403;    // (54)         sra  $8, $8, 16
    assign rom[5'h16] = 32'h000843c2;    // (58)         srl  $8, $8, 15
    assign rom[5'h17] = 32'h08000017;    // (5c) finish: j    finish
    assign rom[5'h18] = 32'h00004020;    // (60) sum:    add  $8, $0, $0
    assign rom[5'h19] = 32'h8c890000;    // (64) loop:   lw   $9, 0($4)
    assign rom[5'h1A] = 32'h20840004;    // (68)         addi $4, $4,  4
    assign rom[5'h1B] = 32'h01094020;    // (6c)         add  $8, $8, $9
    assign rom[5'h1C] = 32'h20a5ffff;    // (70)         addi $5, $5, -1
    assign rom[5'h1D] = 32'h14a0fffb;    // (74)         bne  $5, $0, loop
    assign rom[5'h1E] = 32'h00081000;    // (78)         sll  $2, $8, 0
    assign rom[5'h1F] = 32'h03e00008;    // (7c)         jr   $31
    assign inst = rom[a[6:2]];           // use word address to read rom
endmodule


module dataMem (          
input         clk,                  // clock
input         we,                    // write enable
input  [31:0] datain,                // data in (to memory)
input  [31:0] addr,                  // ram address
output [31:0] dataout               // data out (from memory)
);
    
reg    [31:0] ram [0:31];            // ram cells: 32 words * 32 bits
    
    assign dataout = ram[addr[6:2]];     // use word address to read ram
    
    always @ (posedge clk)
        if (we) ram[addr[6:2]] = datain; // use word address to write ram
        
    integer i;
    
    initial begin                        // initialize memory
        for (i = 0; i < 32; i = i + 1)
            ram[i] = 0;
        // ram[word_addr] = data         // (byte_addr) item in data array
        ram[5'h14] = 32'h000000a3;       // (50)  data[0]    0 +  A3 =  A3
        ram[5'h15] = 32'h00000027;       // (54)  data[1]   a3 +  27 =  ca
        ram[5'h16] = 32'h00000079;       // (58)  data[2]   ca +  79 = 143
        ram[5'h17] = 32'h00000115;       // (5c)  data[3]  143 + 115 = 258
        // ram[5'h18] should be 0x00000258, the sum stored by sw instruction
    end
endmodule




module TOP (

input         clk, 
input         clrn,                     // clock and reset
output [31:0] pc,                            // program counter
output [31:0] inst,                           // instruction
output [31:0] memout

);        
                 // data memory output
    wire   [31:0] data;                           // data to data memory
    wire          wmem;                           // write data memory
    wire   [31:0] maddr;
    
    wire w1,w2,w3,w4;
    
M32HAIAF_INTEGER_CORE cpu0(clk,clrn,inst,memout,pc,maddr,data,wmem,w1,w2,w3,w4);   // cpu
instrMem imem (pc,inst);                               // inst memory
dataMem  dmem (clk,wmem,data,maddr,memout);           // data memory

endmodule


module TOP_TB();

reg coreClk;
reg coreRst;

wire [31:0] pc;
wire [31:0] inst;
wire [31:0] memout;

initial
 begin
   coreClk = 0;
   coreRst = 0;
   #10;
   coreRst = 1;
   forever #1 coreClk = ~coreClk;
 end
 
 TOP corec0 (
  .clk(coreClk),
  .clrn(coreRst),
  .pc(pc),
  .inst(inst),
  .memout(memout)
);

initial
 begin
   #200 $finish;
 end
 
endmodule
