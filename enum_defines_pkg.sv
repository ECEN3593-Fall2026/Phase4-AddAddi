package enum_defines_pkg;


typedef enum logic  [0:0] {
    ALU_NOP=0,
    ALU_ADD=1
} alu_op_t;


typedef enum logic  [0:0] {
    ALU2_REG=0,
    ALU2_IMM=1
} alu_src2_sel_t;


endpackage : enum_defines_pkg   