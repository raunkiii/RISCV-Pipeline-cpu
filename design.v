module RISCV (clk1, clk2);

    input clk1, clk2;

    //  PIPELINE REGISTERS 

    reg [7:0]  PC;
    reg [31:0] IF_ID_IR;
    reg [7:0]  IF_ID_NPC;

    reg [31:0] ID_EX_IR;
    reg [7:0]  ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;
    reg [2:0]  ID_EX_TYPE;

    reg [31:0] EX_MEM_IR;
    reg [7:0]  EX_MEM_ALUOut, EX_MEM_B;
    reg        EX_MEM_cond;
    reg [2:0]  EX_MEM_TYPE;

    reg [31:0] MEM_WB_IR;
    reg [7:0]  MEM_WB_ALUOut, MEM_WB_LMD;
    reg [2:0]  MEM_WB_TYPE;

    //  REGISTER FILES

    reg [7:0] Reg [0:31];

    //  MEMORY 

    reg [31:0] Mem [0:255];

    //  OPCODES 

    parameter ADD   = 6'b000000,
              SUB   = 6'b000001,
              ANDD  = 6'b000010,
              ORR   = 6'b000011,
              SLT   = 6'b000100,
              MUL   = 6'b000101,
              HLT   = 6'b111111,
              LW    = 6'b001000,
              SW    = 6'b001001,
              ADDI  = 6'b001010,
              SUBI  = 6'b001011,
              SLTI  = 6'b001100,
              BNEQZ = 6'b001101,
              BEQZ  = 6'b001110;

    //  TYPES 

    parameter RR_ALU = 3'b000,
              RM_ALU = 3'b001,
              LOAD   = 3'b010,
              STORE  = 3'b011,
              BRANCH = 3'b100,
              HALT   = 3'b101;

    reg HALTED;
    reg TAKEN_BRANCH;

    // IF STAGE

    always @(posedge clk1) begin

        if (HALTED == 0) begin

            if (((EX_MEM_IR[31:26] == BEQZ)  && (EX_MEM_cond == 1)) ||
                ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_cond == 0))) begin

                IF_ID_IR      <= #2 Mem[EX_MEM_ALUOut];
                IF_ID_NPC     <= #2 EX_MEM_ALUOut + 1;
                PC            <= #2 EX_MEM_ALUOut + 1;
                TAKEN_BRANCH  <= #2 1'b1;

            end
            else begin

                IF_ID_IR      <= #2 Mem[PC];
                IF_ID_NPC     <= #2 PC + 1;
                PC            <= #2 PC + 1;
                TAKEN_BRANCH  <= #2 1'b0;

            end
        end
    end


    // ID STAGE

    always @(posedge clk2) begin

        if (HALTED == 0) begin

            if (IF_ID_IR[25:21] == 0)
                ID_EX_A <= #2 0;
            else
                ID_EX_A <= #2 Reg[IF_ID_IR[25:21]];

            if (IF_ID_IR[20:16] == 0)
                ID_EX_B <= #2 0;
            else
                ID_EX_B <= #2 Reg[IF_ID_IR[20:16]];

            ID_EX_IR   <= #2 IF_ID_IR;
            ID_EX_NPC  <= #2 IF_ID_NPC;
            ID_EX_Imm  <= #2 IF_ID_IR[7:0];

            case (IF_ID_IR[31:26])

                ADD, SUB, ANDD, ORR, SLT, MUL:
                    ID_EX_TYPE <= #2 RR_ALU;

                ADDI, SUBI, SLTI:
                    ID_EX_TYPE <= #2 RM_ALU;

                LW:
                    ID_EX_TYPE <= #2 LOAD;

                SW:
                    ID_EX_TYPE <= #2 STORE;

                BNEQZ, BEQZ:
                    ID_EX_TYPE <= #2 BRANCH;

                HLT:
                    ID_EX_TYPE <= #2 HALT;

                default:
                    ID_EX_TYPE <= #2 HALT;

            endcase
        end
    end

    
    // EX STAGE

    always @(posedge clk1) begin

        if (HALTED == 0) begin

            EX_MEM_TYPE <= #2 ID_EX_TYPE;
            EX_MEM_IR   <= #2 ID_EX_IR;

            case (ID_EX_TYPE)

                RR_ALU: begin

                    case (ID_EX_IR[31:26])

                        ADD:
                            EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_B;

                        SUB:
                            EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_B;

                        ANDD:
                            EX_MEM_ALUOut <= #2 ID_EX_A & ID_EX_B;

                        ORR:
                            EX_MEM_ALUOut <= #2 ID_EX_A | ID_EX_B;

                        SLT:
                            EX_MEM_ALUOut <= #2 (ID_EX_A < ID_EX_B);

                        MUL:
                            EX_MEM_ALUOut <= #2 ID_EX_A * ID_EX_B;

                    endcase
                end

                RM_ALU: begin

                    case (ID_EX_IR[31:26])

                        ADDI:
                            EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm;

                        SUBI:
                            EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_Imm;

                        SLTI:
                            EX_MEM_ALUOut <= #2 (ID_EX_A < ID_EX_Imm);

                    endcase
                end

                LOAD, STORE: begin

                    EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm;
                    EX_MEM_B      <= #2 ID_EX_B;

                end

                BRANCH: begin

                    EX_MEM_ALUOut <= #2 ID_EX_NPC + ID_EX_Imm;
                    EX_MEM_cond   <= #2 (ID_EX_A == 0);

                end

            endcase
        end
    end


    // MEM STAGE

    always @(posedge clk2) begin

        if (HALTED == 0) begin

            MEM_WB_TYPE <= #2 EX_MEM_TYPE;
            MEM_WB_IR   <= #2 EX_MEM_IR;

            case (EX_MEM_TYPE)

                RR_ALU,
                RM_ALU:
                    MEM_WB_ALUOut <= #2 EX_MEM_ALUOut;

                LOAD:
                    MEM_WB_LMD <= #2 Mem[EX_MEM_ALUOut][7:0];

                STORE:
                    if (TAKEN_BRANCH == 0)
                        Mem[EX_MEM_ALUOut][7:0] <= #2 EX_MEM_B;

            endcase
        end
    end

    
    // WB STAGE
    

    always @(posedge clk1) begin

        if (TAKEN_BRANCH == 0) begin

            case (MEM_WB_TYPE)

                RR_ALU:
                    Reg[MEM_WB_IR[15:11]] <= #2 MEM_WB_ALUOut;

                RM_ALU:
                    Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_ALUOut;

                LOAD:
                    Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_LMD;

                HALT:
                    HALTED <= #2 1'b1;

            endcase
        end
    end

endmodule


