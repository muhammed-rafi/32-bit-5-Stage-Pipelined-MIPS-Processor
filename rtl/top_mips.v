`timescale 1 ps / 100 fs


module MIPSpipeline (
    input clk,
    input reset
);

    /* ================= IF STAGE ================= */
    wire [31:0] PC, PCin, PC4;
    wire [31:0] Instruction;

    /* ================= IF/ID ================= */
    wire [31:0] ID_PC4, ID_Instruction;
    wire IFID_WriteEn, IFID_flush;

    /* ================= ID STAGE ================= */
    wire [5:0] Opcode, Function;
    wire [4:0] rs, rt, rd;
    wire [15:0] imm16;
    wire [31:0] ReadData1, ReadData2;
    wire [31:0] ReadData1Out, ReadData2Out;
    wire [31:0] sign_ext_out, zero_ext_out, Im16_Ext;

    /* ================= CONTROL ================= */
    wire RegDst, ALUSrc, MemtoReg, RegWrite;
    wire MemRead, MemWrite, Branch, Jump;
    wire SignZero, JRControl;
    wire [1:0] ALUOp;

    /* ================= ID/EX ================= */
    wire [31:0] EX_PC4, EX_ReadData1, EX_ReadData2;
    wire [31:0] EX_Im16_Ext, EX_Instruction;
    wire [4:0] EX_rs, EX_rt, EX_rd;
    wire EX_RegDst, EX_ALUSrc, EX_MemtoReg;
    wire EX_RegWrite, EX_MemRead, EX_MemWrite;
    wire EX_Branch, EX_JRControl;
    wire [1:0] EX_ALUOp;

    /* ================= EX STAGE ================= */
    wire [31:0] Bus_A_ALU, Bus_B_ALU, Bus_B_forwarded;
    wire [31:0] EX_ALUResult;
    wire ZeroFlag, CarryFlag, OverflowFlag, NegativeFlag;
    wire [1:0] ForwardA, ForwardB;
    wire [3:0] ALUControl;
    wire [4:0] EX_WriteRegister;

    /* ================= EX/MEM ================= */
    wire [31:0] MEM_ALUResult, WriteDataOfMem;
    wire [4:0] MEM_WriteRegister;
    wire MEM_MemtoReg, MEM_RegWrite;
    wire MEM_MemRead, MEM_MemWrite;

    /* ================= MEM STAGE ================= */
    wire [31:0] MEM_ReadDataOfMem;

    /* ================= MEM/WB ================= */
    wire [31:0] WB_ReadDataOfMem, WB_ALUResult;
    wire [4:0] WB_WriteRegister;
    wire WB_MemtoReg, WB_RegWrite;

    /* ================= WB ================= */
    wire [31:0] WB_WriteData;

    /* ================= PC LOGIC ================= */
    register PC_Reg(PC, PCin, PC_WriteEn, reset, clk);
    Add Add_PC4(PC4, PC, 32'd4);
    InstructionMem IM(Instruction, PC);

    /* ================= IF/ID ================= */
    register IFID_PC4(ID_PC4, PC4, IFID_WriteEn, reset, clk);
    register IFID_Instruction(ID_Instruction, Instruction, IFID_WriteEn, reset, clk);
    RegBit IFID_FlushBit(IFID_flush, IF_flush, IFID_WriteEn, reset, clk);

    /* ================= ID ================= */
    assign Opcode   = ID_Instruction[31:26];
    assign rs       = ID_Instruction[25:21];
    assign rt       = ID_Instruction[20:16];
    assign rd       = ID_Instruction[15:11];
    assign imm16    = ID_Instruction[15:0];
    assign Function = ID_Instruction[5:0];

    Control MainControl(
        RegDst, ALUSrc, MemtoReg, RegWrite,
        MemRead, MemWrite, Branch,
        ALUOp, Jump, SignZero, Opcode
    );

    regfile RF(
        ReadData1, ReadData2,
        WB_WriteData,
        rs, rt,
        WB_WriteRegister,
        WB_RegWrite,
        reset, clk
    );

    WB_forward WB_FWD(
        ReadData1Out, ReadData2Out,
        ReadData1, ReadData2,
        rs, rt,
        WB_WriteRegister,
        WB_WriteData,
        WB_RegWrite
    );

    sign_extend SE(sign_ext_out, imm16);
    zero_extend ZE(zero_ext_out, imm16);
    mux2x32to32 MUX_EXT(Im16_Ext, sign_ext_out, zero_ext_out, SignZero);

    /* ================= ID/EX ================= */
    register IDEX_PC4(EX_PC4, ID_PC4, 1'b1, reset, clk);
    register IDEX_RD1(EX_ReadData1, ReadData1Out, 1'b1, reset, clk);
    register IDEX_RD2(EX_ReadData2, ReadData2Out, 1'b1, reset, clk);
    register IDEX_IMM(EX_Im16_Ext, Im16_Ext, 1'b1, reset, clk);
    register IDEX_INST(EX_Instruction, ID_Instruction, 1'b1, reset, clk);

    assign EX_rs = EX_Instruction[25:21];
    assign EX_rt = EX_Instruction[20:16];
    assign EX_rd = EX_Instruction[15:11];

    RegBit IDEX_RegDst(EX_RegDst, ID_RegDst, 1'b1, reset, clk);
    RegBit IDEX_ALUSrc(EX_ALUSrc, ID_ALUSrc, 1'b1, reset, clk);
    RegBit IDEX_MemtoReg(EX_MemtoReg, ID_MemtoReg, 1'b1, reset, clk);
    RegBit IDEX_RegWrite(EX_RegWrite, ID_RegWrite, 1'b1, reset, clk);
    RegBit IDEX_MemRead(EX_MemRead, ID_MemRead, 1'b1, reset, clk);
    RegBit IDEX_MemWrite(EX_MemWrite, ID_MemWrite, 1'b1, reset, clk);
    RegBit IDEX_Branch(EX_Branch, ID_Branch, 1'b1, reset, clk);
    RegBit IDEX_JR(EX_JRControl, ID_JRControl, 1'b1, reset, clk);
    RegBit IDEX_ALUOp1(EX_ALUOp[1], ID_ALUOp[1], 1'b1, reset, clk);
    RegBit IDEX_ALUOp0(EX_ALUOp[0], ID_ALUOp[0], 1'b1, reset, clk);

    /* ================= EX ================= */
    ForwardingUnit FU(
        ForwardA, ForwardB,
        MEM_RegWrite, WB_RegWrite,
        MEM_WriteRegister, WB_WriteRegister,
        EX_rs, EX_rt
    );

    mux3x32to32 MUXA(Bus_A_ALU, EX_ReadData1, MEM_ALUResult, WB_WriteData, ForwardA);
    mux3x32to32 MUXB(Bus_B_forwarded, EX_ReadData2, MEM_ALUResult, WB_WriteData, ForwardB);
    mux2x32to32 MUXALU(Bus_B_ALU, Bus_B_forwarded, EX_Im16_Ext, EX_ALUSrc);

    ALUControl_Block ALUCTRL(ALUControl, EX_ALUOp, EX_Im16_Ext[5:0]);
    alu ALU(EX_ALUResult, CarryFlag, ZeroFlag, OverflowFlag, NegativeFlag,
            Bus_A_ALU, Bus_B_ALU, ALUControl);

    mux2x5to5 MUXDST(EX_WriteRegister, EX_rt, EX_rd, EX_RegDst);

    /* ================= MEM ================= */
    register EXMEM_ALU(MEM_ALUResult, EX_ALUResult, 1'b1, reset, clk);
    register EXMEM_WD(WriteDataOfMem, Bus_B_forwarded, 1'b1, reset, clk);
    RegBit EXMEM_MemtoReg(MEM_MemtoReg, EX_MemtoReg, 1'b1, reset, clk);
    RegBit EXMEM_RegWrite(MEM_RegWrite, EX_RegWrite, 1'b1, reset, clk);
    RegBit EXMEM_MemRead(MEM_MemRead, EX_MemRead, 1'b1, reset, clk);
    RegBit EXMEM_MemWrite(MEM_MemWrite, EX_MemWrite, 1'b1, reset, clk);

    dataMem DM(
        MEM_ReadDataOfMem,
        MEM_ALUResult,
        WriteDataOfMem,
        MEM_MemWrite,
        MEM_MemRead,
        clk
    );

    /* ================= WB ================= */
    register MEMWB_RD(WB_ReadDataOfMem, MEM_ReadDataOfMem, 1'b1, reset, clk);
    register MEMWB_ALU(WB_ALUResult, MEM_ALUResult, 1'b1, reset, clk);
    RegBit MEMWB_RegWrite(WB_RegWrite, MEM_RegWrite, 1'b1, reset, clk);
    RegBit MEMWB_MemtoReg(WB_MemtoReg, MEM_MemtoReg, 1'b1, reset, clk);

    mux2x32to32 MUXWB(WB_WriteData, WB_ALUResult, WB_ReadDataOfMem, WB_MemtoReg);

endmodule
