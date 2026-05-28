module testbench;

    reg clk1, clk2;
    integer k;

    RISCV uut (.clk1(clk1), .clk2(clk2));

    //  CLOCK 

    initial begin

        clk1 = 0;
        clk2 = 0;

        repeat (20) begin

            #5 clk1 = 1;
            #5 clk1 = 0;

            #5 clk2 = 1;
            #5 clk2 = 0;

        end
    end

    //  MONITOR

    initial begin

        $display("\n CPU EXECUTION \n");

        $monitor(
        "TIME=%0t | PC=%0d | IR=%h | A=%0d | B=%0d | ALUOUT=%0d | WB=%0d | R1=%0d | R2=%0d | R3=%0d",
        $time,
        uut.PC,
        uut.IF_ID_IR,
        uut.ID_EX_A,
        uut.ID_EX_B,
        uut.EX_MEM_ALUOut,
        uut.MEM_WB_ALUOut,
        uut.Reg[1],
        uut.Reg[2],
        uut.Reg[3]
        );

    end


    initial begin

        for (k = 0; k < 32; k = k + 1)
            uut.Reg[k] = k;

        uut.HALTED = 0;
        uut.PC = 0;
        uut.TAKEN_BRANCH = 0;


        // ADDI R1, R0, 10
        uut.Mem[0] = {6'b001010, 5'd0, 5'd1, 16'd10};

        // ADDI R2, R0, 20
        uut.Mem[1] = {6'b001010, 5'd0, 5'd2, 16'd20};

        // ADD R3, R1, R2
        uut.Mem[2] = {6'b000000, 5'd1, 5'd2, 5'd3, 11'd0};

        // SUB R4, R2, R1
        uut.Mem[3] = {6'b000001, 5'd2, 5'd1, 5'd4, 11'd0};

        // MUL R5, R2, R1
        uut.Mem[4] = {6'b000101, 5'd1, 5'd2, 5'd5, 11'd0};

        // HALT
        uut.Mem[5] = {6'b111111, 26'd0};

        #300;

        $display("\n FINAL REGISTER VALUES \n");

        for (k = 0; k < 8; k = k + 1)
            $display("R%0d = %0d", k, uut.Reg[k]);

        $finish;

    end

    initial begin
    $dumpfile("riscv.vcd");
    $dumpvars(1, uut);
end

endmodule
