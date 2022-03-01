`timescale 1ns/1ns

module CPU_TB();
  // Global Inputs
  reg clk;
  reg rst;
  // Output
  wire halt;
  
  initial
    begin
       clk = 0;
       rst = 0;
       #6;
       rst = 1;
       forever #2 clk = ~clk;
    end
  
  CPU core0 (
    .clk(clk),
    .rst(rst),
    .halt(halt)
  );
  
  initial
    begin
      $readmemb("instr_mem.bin", core0.mem_instr);
      $readmemb("data_mem.bin", core0.mem_data);
    end 
  
  initial
    begin
      $dumpfile("Test.vcd");
      $dumpvars();
       #10;
       core0.wmem = 1;
       $display("Instruction : %b, Opcode : %b, PC : %b", core0.instr, core0.opcode, core0.pc);
       #200 $finish;
    end
endmodule
