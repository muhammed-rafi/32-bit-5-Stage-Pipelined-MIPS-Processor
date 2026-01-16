`timescale 1ns / 1ps

module top_mips (
    input clk,
    input reset
);

    // ==============================================================================
    // WIRES & CONNECTIONS
    // ==============================================================================

    // --- IF Stage Signals ---
    wire [31:0] PC, PC_Next, PC_Plus4;
    wire [31:0] Instruction;
    wire        PCWrite; // From Hazard Unit

    // --- IF/ID Stage Signals ---
    wire [31:0] ID_PC4, ID_Instr;
    wire        IF_ID_Write; // From Hazard Unit
    wire        IF_Flush;    // Calculated in Top Level (Jump/Branch)

    // --- ID Stage Signals ---
    wire [5:0]  Opcode, Funct;
    wire [4:0]  ID_Rs, ID_Rt, ID_Rd;
    wire [15:0] ID_Imm16;
    wire [31:0] ID_SignExtImm, ID_ZeroExtImm, ID_ImmExt;
    wire [31:0] ID_ReadData1_Raw, ID_ReadData2_Raw; // From RegFile
    wire [31:0] ID_ReadData1, ID_ReadData2;         // After ID Forwarding
    wire [31:0] ID_JumpTarget;
    wire        ID_Flush; // Calculated (Hazard Flush || Branch Flush)

    // Control Signals (ID)
    wire ID_RegDst, ID_ALUSrc, ID_MemtoReg, ID_RegWrite;
    wire ID_MemRead, ID_MemWrite, ID_Branch, ID_Jump, ID_SignZero;
    wire [1:0] ID_ALUOp;
    wire Hazard_Flush;

    // --- ID/EX Stage Signals ---
    wire [31:0] EX_PC4, EX_ReadData1, EX_ReadData2, EX_ImmExt;
    wire [4:0]  EX_Rs, EX_Rt, EX_Rd;
    wire [4:0]  EX_WriteRegister; // Result of Mux (Rt vs Rd)
    
    // EX Control Signals
    wire EX_RegDst, EX_ALUSrc, EX_MemtoReg, EX_RegWrite;
    wire EX_MemRead, EX_MemWrite, EX_Branch;
    wire [1:0] EX_ALUOp;

    // --- EX Stage Logic Signals ---
    wire [31:0] ALU_InA, ALU_InB;
    wire [31:0] Bus_B_Forwarded; // Data for Store Word (after fwd)
    wire [31:0] EX_ALUResult;
    wire [31:0] EX_BranchTarget;
    wire        EX_Zero;
    wire [3:0]  ALU_Control_Sig;
    wire [1:0]  ForwardA, ForwardB;
    wire        PCSrc; // Logic for Branch Taken

    // --- EX/MEM Stage Signals ---
    wire [31:0] MEM_ALUResult, MEM_WriteData;
    wire [4:0]  MEM_Rd;
    wire        MEM_RegWrite, MEM_MemtoReg, MEM_MemRead, MEM_MemWrite;
    wire [31:0] MEM_ReadData; // Output from Data Memory

    // --- MEM/WB Stage Signals ---
    wire [31:0] WB_ALUResult, WB_MemData;
    wire [4:0]  WB_Rd;
    wire        WB_RegWrite, WB_MemtoReg;
    wire [31:0] WB_WriteData; // Final data to write back to RegFile


    // ==============================================================================
    // 1. INSTRUCTION FETCH (IF) STAGE
    // ==============================================================================

    // PC Mux Logic: Priority is Reset -> Branch (EX) -> Jump (ID) -> PC+4
    assign PC_Next = (PCSrc)   ? EX_BranchTarget :
                     (ID_Jump) ? ID_JumpTarget   : 
                                 PC_Plus4;

    pc PC_Module (
        .clk(clk),
        .rst(reset),
        .pc_write(PCWrite),
        .pc_next(PC_Next),
        .pc(PC)
    );

    adder PC_Adder (
        .a(PC),
        .b(32'd4),
        .y(PC_Plus4)
    );

    instruction_memory IM (
        .addr(PC),
        .instr(Instruction)
    );

    // ==============================================================================
    // 2. IF/ID PIPELINE REGISTER
    // ==============================================================================
    
    // Flush IF/ID if we Jump (in ID) or Branch (in EX)
    assign IF_Flush = ID_Jump || PCSrc;

    IF_ID_reg IF_ID_Register (
        .clk(clk),
        .rst(reset),
        .write_en(IF_ID_Write),
        .flush(IF_Flush),
        .pc_plus4_in(PC_Plus4),
        .instr_in(Instruction),
        .pc_plus4_out(ID_PC4),
        .instr_out(ID_Instr)
    );

    // ==============================================================================
    // 3. INSTRUCTION DECODE (ID) STAGE
    // ==============================================================================

    // Decode Fields
    assign Opcode   = ID_Instr[31:26];
    assign ID_Rs    = ID_Instr[25:21];
    assign ID_Rt    = ID_Instr[20:16];
    assign ID_Rd    = ID_Instr[15:11];
    assign ID_Imm16 = ID_Instr[15:0];
    assign Funct    = ID_Instr[5:0];

    // Main Control Unit
    Control Main_Control (
        .Opcode(Opcode),
        .RegDst(ID_RegDst),
        .ALUSrc(ID_ALUSrc),
        .MemtoReg(ID_MemtoReg),
        .RegWrite(ID_RegWrite),
        .MemRead(ID_MemRead),
        .MemWrite(ID_MemWrite),
        .Branch(ID_Branch),
        .ALUOp(ID_ALUOp),
        .Jump(ID_Jump),
        .SignZero(ID_SignZero)
    );

    // Register File
    regfile Register_File (
        .clk(clk),
        .we(WB_RegWrite),
        .ra1(ID_Rs),
        .ra2(ID_Rt),
        .wa(WB_Rd),
        .wd(WB_WriteData),
        .rd1(ID_ReadData1_Raw),
        .rd2(ID_ReadData2_Raw)
    );

    // WB to ID Forwarding (Solves data hazard if reading and writing same reg in one cycle)
    assign ID_ReadData1 = (WB_RegWrite && (WB_Rd != 0) && (WB_Rd == ID_Rs)) ? WB_WriteData : ID_ReadData1_Raw;
    assign ID_ReadData2 = (WB_RegWrite && (WB_Rd != 0) && (WB_Rd == ID_Rt)) ? WB_WriteData : ID_ReadData2_Raw;

    // Sign/Zero Extension
    sign_extend Sign_Extender (
        .in(ID_Imm16),
        .out(ID_SignExtImm)
    );
    assign ID_ZeroExtImm = {16'b0, ID_Imm16}; // Simple Zero Extension

    // Mux to choose between Sign Extended or Zero Extended Immediate
    mux2 #(.W(32)) Imm_Ext_Mux (
        .a(ID_SignExtImm),
        .b(ID_ZeroExtImm),
        .sel(ID_SignZero),
        .y(ID_ImmExt)
    );

    // Jump Address Calculation
    assign ID_JumpTarget = {ID_PC4[31:28], ID_Instr[25:0], 2'b00};

    // Hazard Detection Unit
    hazard_unit Hazard_Unit (
        .ID_EX_MemRead(EX_MemRead),
        .ID_EX_Rt(EX_Rt),
        .IF_ID_Rs(ID_Rs),
        .IF_ID_Rt(ID_Rt),
        .PCWrite(PCWrite),
        .IF_ID_Write(IF_ID_Write),
        .ID_EX_Flush(Hazard_Flush)
    );

    // ==============================================================================
    // 4. ID/EX PIPELINE REGISTER
    // ==============================================================================

    // Flush ID/EX if hazard detected OR if Branch taken (Control Hazard)
    assign ID_Flush = Hazard_Flush || PCSrc;

    ID_EX_reg ID_EX_Register (
        .clk(clk),
        .rst(reset),
        .flush(ID_Flush),
        
        // Inputs
        .RegWrite_in(ID_RegWrite),
        .MemRead_in(ID_MemRead),
        .MemWrite_in(ID_MemWrite),
        .MemToReg_in(ID_MemtoReg),
        .ALUSrc_in(ID_ALUSrc),
        .ALUOp_in(ID_ALUOp),
        .rd1_in(ID_ReadData1),
        .rd2_in(ID_ReadData2),
        .imm_in(ID_ImmExt),
        .rs_in(ID_Rs),
        .rt_in(ID_Rt),
        .rd_in(ID_Rd),
        .pc_plus4_in(ID_PC4), // Note: You might need to add this port to ID_EX_reg.v if missing, used for Branch

        // Outputs
        .RegWrite(EX_RegWrite),
        .MemRead(EX_MemRead),
        .MemWrite(EX_MemWrite),
        .MemToReg(EX_MemtoReg),
        .ALUSrc(EX_ALUSrc),
        .ALUOp(EX_ALUOp),
        .rd1(EX_ReadData1),
        .rd2(EX_ReadData2),
        .imm(EX_ImmExt),
        .rs(EX_Rs),
        .rt(EX_Rt),
        .rd(EX_Rd),
        .pc_plus4_out(EX_PC4) // Corresponding output
    );
    
    // Note: If your ID_EX_reg.v does not have pc_plus4 ports, you must add them 
    // to calculate branch target in EX stage properly. 
    // Assuming for now you will add them or they exist. 
    // If not, calculate branch target in ID and pass it through.

    // ==============================================================================
    // 5. EXECUTION (EX) STAGE
    // ==============================================================================

    // Forwarding Unit
    forwarding_unit Forwarding_Unit (
        .EX_MEM_RegWrite(MEM_RegWrite),
        .MEM_WB_RegWrite(WB_RegWrite),
        .EX_MEM_Rd(MEM_Rd),
        .MEM_WB_Rd(WB_Rd),
        .ID_EX_Rs(EX_Rs),
        .ID_EX_Rt(EX_Rt),
        .ForwardA(ForwardA),
        .ForwardB(ForwardB)
    );

    // ALU Source A Mux (Forwarding)
    // 00: ID/EX, 10: EX/MEM (from MEM stage), 01: MEM/WB (from WB stage)
    mux3 #(.W(32)) ALU_Input_A_Mux (
        .d0(EX_ReadData1),  // 00
        .d1(WB_WriteData),  // 01
        .d2(MEM_ALUResult), // 10
        .sel(ForwardA),
        .y(ALU_InA)
    );

    // ALU Source B Forwarding Mux
    mux3 #(.W(32)) ALU_Input_B_Forward_Mux (
        .d0(EX_ReadData2),  // 00
        .d1(WB_WriteData),  // 01
        .d2(MEM_ALUResult), // 10
        .sel(ForwardB),
        .y(Bus_B_Forwarded)
    );

    // ALU Source B Immediate Mux (ALUSrc)
    mux2 #(.W(32)) ALU_Input_B_Mux (
        .a(Bus_B_Forwarded),
        .b(EX_ImmExt),
        .sel(EX_ALUSrc),
        .y(ALU_InB)
    );

    // ALU Control
    alu_control ALU_Control_Unit (
        .ALUOp(EX_ALUOp),
        .funct(EX_ImmExt[5:0]),
        .alu_ctrl(ALU_Control_Sig)
    );

    // ALU
    alu Main_ALU (
        .a(ALU_InA),
        .b(ALU_InB),
        .alu_ctrl(ALU_Control_Sig),
        .result(EX_ALUResult),
        .zero(EX_Zero)
    );

    // Branch Target Adder
    adder Branch_Address_Adder (
        .a(EX_PC4),
        .b(EX_ImmExt << 2),
        .y(EX_BranchTarget)
    );

    // Destination Register Mux (Rt vs Rd)
    mux2 #(.W(5)) Dest_Reg_Mux (
        .a(EX_Rt),
        .b(EX_Rd),
        .sel(EX_RegDst),
        .y(EX_WriteRegister)
    );
    
    // Branch Logic: Currently supports BNE (Branch if Not Equal) based on Control.v
    // Control.v sets Branch=1 for BNE. ALU Zero=1 if Equal.
    // So for BNE, we branch if Branch=1 AND Zero=0.
    assign EX_Branch = ID_EX_Register.EX_Branch; // Or pass it through wires if you added port
    // NOTE: In the provided files, ID_EX_reg passes 'EX_Branch' but it is a wire above.
    // I am using the wire 'EX_Branch' derived from ID_EX_reg instantiation.
    
    assign PCSrc = EX_Branch && (~EX_Zero); 


    // ==============================================================================
    // 6. EX/MEM PIPELINE REGISTER
    // ==============================================================================

    EX_MEM_reg EX_MEM_Register (
        .clk(clk),
        .rst(reset),
        
        // Control Inputs
        .RegWrite_in(EX_RegWrite),
        .MemRead_in(EX_MemRead),
        .MemWrite_in(EX_MemWrite),
        .MemToReg_in(EX_MemtoReg),
        
        // Data Inputs
        .alu_out_in(EX_ALUResult),
        .rt_data_in(Bus_B_Forwarded), // Data to store in memory
        .rd_in(EX_WriteRegister),

        // Outputs
        .RegWrite(MEM_RegWrite),
        .MemRead(MEM_MemRead),
        .MemWrite(MEM_MemWrite),
        .MemToReg(MEM_MemtoReg),
        .alu_out(MEM_ALUResult),
        .rt_data(MEM_WriteData),
        .rd(MEM_Rd)
    );

    // ==============================================================================
    // 7. MEMORY (MEM) STAGE
    // ==============================================================================

    data_memory DM (
        .clk(clk),
        .MemRead(MEM_MemRead),
        .MemWrite(MEM_MemWrite),
        .addr(MEM_ALUResult),
        .wd(MEM_WriteData),
        .rd(MEM_ReadData)
    );

    // ==============================================================================
    // 8. MEM/WB PIPELINE REGISTER
    // ==============================================================================

    MEM_WB_reg MEM_WB_Register (
        .clk(clk),
        .rst(reset),
        
        // Control Inputs
        .RegWrite_in(MEM_RegWrite),
        .MemToReg_in(MEM_MemtoReg),
        
        // Data Inputs
        .mem_data_in(MEM_ReadData),
        .alu_out_in(MEM_ALUResult),
        .rd_in(MEM_Rd),

        // Outputs
        .RegWrite(WB_RegWrite),
        .MemToReg(WB_MemtoReg),
        .mem_data(WB_MemData),
        .alu_out(WB_ALUResult),
        .rd(WB_Rd)
    );

    // ==============================================================================
    // 9. WRITE BACK (WB) STAGE
    // ==============================================================================

    mux2 #(.W(32)) WB_Mux (
        .a(WB_ALUResult),
        .b(WB_MemData),
        .sel(WB_MemToReg),
        .y(WB_WriteData)
    );

endmodule