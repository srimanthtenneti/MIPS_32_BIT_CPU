/*
   Design : Single Cycle MIPS CPU
   Description : 32 Bit , Harvard Style Design
   Engineer : Srimanth Tenneti
   Date : 01/03/2022
*/

`timescale 1ns/1ns

module CPU (
  // Global Signals
  input clk,
  input rst,
  // Output 
  output halt
);
  
  // Memory Enable
  reg wmem;
  
  // CPU Instr Memory 
  reg [31:0] mem_instr [0:31];
  
  // CPU Data Memory
  reg [31:0] mem_data [1:31];
  
  // Program Counter
  reg [4:0] pc;
  wire [31:0] instr = mem_instr[pc];
  
  // Alu Data
  reg [31:0] alu_out;
  reg [31:0] a;
  reg [31:0] b;
  
  // Flags
  reg z;
  reg ov;
  reg hlt;
  
  // Instruction Decode
  wire [5:0]  opcode = instr[31:26]; // Opcode
  wire [4:0]  rs     = instr[25:21]; // Source Register 1
  wire [4:0]  rt     = instr[20:16]; // Source Register 2
  wire [4:0]  rd     = instr[15:11]; // Destination Register
  wire [4:0]  sa     = instr[10:06]; // Shift Amount
  wire [5:0]  func   = instr[05:00]; // Funtion for Register type instructions
  wire [15:0] imm    = instr[15:00]; // Immediate Data
  
  wire        sign   = instr[15];    // Sign 
  wire [31:0] imm_d  = {{16{sign}}, imm};  // Sign Extention of immediate data
  
  
  // Instruction Type Variables
  reg R;  // R Type
  reg I;  // I Type
  reg J;  // J Type
  reg LS; // Load & Store Type
  reg BR; // Branch 
  
  // Instruction Type Decode
  always @ *
    begin
      case(opcode)
           6'b000_000 : begin 
             R  = 1;
             I  = 0;
             J  = 0;
             LS = 0;
             BR = 0;
           end
           6'b001_000,6'b001_100,6'b001_101,6'b001_110,6'b001_111 : begin
             R  = 0;
             I  = 1;
             J  = 0;
             LS = 0;
             BR = 0;
           end
           6'b100_011,6'b101_011 : begin
             R  = 0;
             I  = 0;
             J  = 0;
             LS = 1;
             BR = 0;
           end
           6'b000_100,6'b000_101 : begin
             R  = 0;
             I  = 0;
             J  = 0;
             LS = 0;
             BR = 1;
           end
           6'b000_010,6'b000_011 : begin
             R  = 0;
             I  = 0;
             J  = 1;
             LS = 0;
             BR = 0;
           end
      endcase
    end
  
  always @ (posedge clk, negedge rst)
    begin
      if(~rst)
        pc <= 0;
      else
        begin
           pc <= pc + 1;
        end
    end
  
  // R - Type Instruction ALU Unit
  
  always @ (posedge clk, negedge rst)
    begin
      if (~rst)
        alu_out = 0;
      else 
        begin
          if (R)
            begin
              a = (rs == 0) ? 0 : mem_data[rs];
              b = (rt == 0) ? 0 : mem_data[rt];
              case(func)
                 6'b100_000 : {ov, alu_out} = a + b;
                 6'b100_010 : {ov, alu_out} = a - b;
                 6'b100_100 : alu_out = a & b;
                 6'b100_101 : alu_out = a | b;
                 6'b100_110 : alu_out = a ^ b;
                 6'b000_000 : alu_out = a << sa;
                 6'b000_010 : alu_out = a >> sa;
                 6'b000_011 : alu_out = a >>> sa;
                 6'b001_000 : pc = rs;
              endcase
               mem_data[rd] = (wmem) ? alu_out : 32'hxx;
               z = (alu_out == 32'b0) ? 1 : 0;
            end
        end
    end 
endmodule
