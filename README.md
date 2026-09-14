# Phase 4: Full implementation of Add and Addi instructions

In this phase, you'll extend your Phase 3 code to support the full implementation of the add and addi instructions.  

## Overview 

To start, copy SystemVerilog files (except cpu.sv, enum_defines_pkg.sv, regfile.sv, and regfile_tb.sv) from your Phase 3 code to your phase 4 directory and add to the repo.  IMPORTANT: We provide a new cpu.sv fully completed, that connects the pipeline stages together -- note, you'll need to match the input/output ports defined there in the modules you create.  We also updated regfile.sv to handle a condition when you read and write to the same register in the same cycle (testcase updated in regfile_tb.sv).

Note: in Linux, you can use cp with the --update=none flag to copy files from set of source files to a destination directory without overwriting.  If you do accidentially overwrite files in the phase4-repo that we provide, you can delete that file and do ```git pull```, which should just get the original file.
```
cp --update=none phase3-repo/* phase4-repo
```

### Changes to Make

In Phase 3, the decode stage did determine what specific instruction was being executed and the different components (e.g., rs1, rs2, rd, immed) and read from the register file. In Phase 4 you also need to determine some control signals used in the execute stage (so, should be added to the pipeline register).  

The new interface for decode includes the following. idex_rd is passing the decoded destination register through the pipeline, which we didn't do in Phase 3.  Also note, we no longer need to pass the idex_instr_str (so, just comment it out).  The new control signals are alu_op, alu_src2_sel, and regwrite (each prefixed with idex_ to indicate it goes between the ID and EX stages).  The control signals are described below.

```
    // output instr_strings_pkg::instr_op_t idex_instr_str


    // Phase 4 control signals
        // Decoder outputs
    output enum_defines_pkg::alu_op_t      idex_alu_op, // selects what operation the ALU performs
    output enum_defines_pkg::alu_src2_sel_t    idex_alu_src2_sel,  // selects what the ALU input should be (reg or imm)
    output logic         idex_regwrite, // set to 1 for instructions that write to the regfile

    // Phase 4 additional decoded output
    output logic [4:0]    idex_rd   // destination register address, so WB stage can know destination register
```

In Phase 3, the execute stage didn't implement any instructions.  In addition to needing (as inputs) the outputs that were passed from the decode stage (i.e., the outpus labeled idex_), there are three new outputs.  rd and regwrite are just passing along values from the decode stage (in the pipeline register -- so, assign in an always_ff block).  The other is alu_result -- that's the output from the alu (passed in a pipeline register).  The ALU is described below.

```
    // Phase 4: outputs to memory stage (to pass to the wb stage)
    output logic [31:0] exme_alu_result, // the output of the ALU
    output logic [4:0]    exme_rd,   // destination register address, so WB stage can know destination register
    output logic exme_regwrite // the regwrite signal passed through (pipelined)
```

The memory stage just needs to pass through the alu_result, rd, and regwrite signals (input from the EX stage, prefixed exme_, and output to the writeback stage, prefixed mewb_).

The writeback stage in Phase 4 needs to be updated to set the signals to write to the register file (s_wb_rd, s_wb_writedata, s_wb_regwrite).  In Phase 3, these were all just set to 0.  In Phase 4, you will set them based on values passed in (you need to add the input ports) from the memory stage.  Set them either with an assign stagement (outside of an an always block), or in an always_comb block.  Only tricky bit is that x0 is to never be written to.  So, if rd is 0 (for x0), regwrite should be set to 0, otherwise set regwrite to whatever was input from the mem stage.  


### ALU design (ex stage), and control signals (decode stage) 

The ALU needs to be capable of performing an add or addi instruction (or do nothing).  But, it doesn't support instructions directly -- instead, it supports a set of operations (that might be used by multiple instructions).  In this case, the ALU needs to support only the ADD operation to support both add and addi.  

For this, we defined an enum in package enum_defines_pkg of type alu_op_t.   You'll note it defines two operations (ALU_NOP to tell the ALU to do nothing, and ALU_ADD to tell the ALU to perform an addition).  

With the ALU supporting ADD, the main way to differentiate add and addi is the second input to the ALU.  With add, the second input is reg2 (what was read from the regfile), with addi, the input is immed.  For this, we defined another enum in enum_defines_pkg of type alu_src2_sel_t (set to ALU2_REG when the second input should come from the register file, and ALU2_IMM when the second input should come from the immed extracted from the instruction).

So, in the decode stage, you'll need to set the three main control signals (regwrite, alusrc2, and aluop) based on what the instruction it is.  Set them inside of an always_comb block where you're currently setting instr_string.  And then register in a pipeline register in an always_ff block (assigning to the output ports).  Helpful will be to set a default value at the top of the always_comb block (regwrite=0, aluop=ALU_NOPm alusrc2=ALU_REG), then only set to values for the add and addi instructions.

Then, in the execute stage, you'll need to implement the mux to select between reg2 and immed, outputting to a new signal, say s_ex_src2 (this can be as an always_comb block with an if/else).  Then implement the ALU.  This can be its own always_comb block, with a case statement (instead of if/else since more operation types will come in future phases) and for OP_ADD, set a signal, say s_ex_alu_result, as idex_reg1 + s_ex_src2.

Note: in decode, you can still assign to instr_string and have it print out.  In execute, you can update the print statement.  Here's what I updated to (removed the instr_str, but added a couple others I was interested in).  We won't use the log, other than for the register print outs in the log (you can grep "Register" the output to see that)
```
   always_ff @(posedge clk) begin
        if (!reset) begin
            $display("(%0d) Execute Stage: PC = %h, Instruction = %h, Reg1 = %h, Reg2 = %h, Immediate = %h, idex_alu_op=%h, idex_alu_src2_sel=%h",
                     $time, idex_pc, idex_instr, idex_reg1, idex_reg2, idex_immed, idex_alu_op, idex_alu_src2_sel);
        end
    end
```

### Testing

Provided is phase4-sample.S that we will be basing the correctness on.  make_init_mem.sh can be used (as with past phases) to create init.mem.  The init.mem provided matches phase4-sample.S.

You'll note a lot of lines in phase4-sample.S that just have nop.  That's a no operation instructions (pseudo instruction for add x0, x0, x0).  We need it because we haven't dealt with hazards yet (we need time for the instruction that updates a register to work its way through the pipeline and get written to the register file before we can read it).

iverilog -g2012 -o system_tb.out -c file_list.txt





## AI Use

You need to create a new file AI-use-statement.md and include a statement on how exactly you used AI (tools, prompt examples).

Note -- acceptable uses:
* Learning SystemVerilog -- e.g., provide an example of slicing in SystemVerilog.
* Code completion e.g., if I start typing something and it recognisizes a pattern, it will suggest some code to use that matches that pattern.

Note -- unacceptable uses:
* Asking it to create whole verilog code
* Proving the instructions (or code) from the assignment as asking it to complete all or part.

If in doubt, ask.  


## Submission / Grading

Add any new files you created to the git repo (at least mytest.S), and commit/push all changes.  Do not include temporary files.  We include a .gitignore that should catch these.

Submit the URL in canvas as the submission when you are completed. 

We will hold interview grading for this phase.  This will not be a rigorous grilling to test your knowledge.  It will be more like forced 1-1 office hours with a TA to ensure you're on the right track for future phases.  You should understand your code, including the why of your code.  You should be prepared to run it, and be able to show that it's operating correctly by looking at the waveforms.  


Rubric:
20 points total

If your System Verilog code does not compile and run without errors, you will be assigned a 0.  You will be given 1 opportunity, and 24 hours, to correct and notify the TA that let you know.

with a solution that does compile/run, below is the rubric:

1 point for file AI_use_statement.md

10 points for code that looks right (they exist and look reasonable to the TA).  2.5 pt each for:
* decode -- set control signals (eyeball)
* execute -- mux
* execute -- alu
* writeback -- regfile signals

4 points for correct execution.  We will use phase4-sample.S to test for correctness.  We define correctness as the writes to the register files (and not writing, in the case of anything that attempts to assign to x0).  We will give 1 point each for the test of each of the following conditions (which we will test by looking at x0, x2, x3, and x4).  So, you can check your program for correctness the same way we'll check.  The test program writes to x1-x6, so you should make sure all of those are correct.  You can grep "Register" the output log file to see what registers get written to, with what value, and when.
* addi with pos number 
* addi with neg num
* setting x0 (should not set)
* setting to another register

5 points for interview grading.  Instructions will follow as a separate communication.


