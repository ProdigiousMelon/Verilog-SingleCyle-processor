// Project 3
// 3-2-16
// Team 4




// opcodes
`define ADD 4'b0000
`define AND 4'b0001
`define ANY 4'b0010
`define OR 4'b0011
`define SHR 4'b0100
`define XOR 4'b0101
`define DUP 4'b0110
`define JZ 4'b0111
`define LD 4'b1000
`define ST 4'b1001
`define LI 4'b1010
`define ADDF 4'b1011
`define F2I 4'b1100
`define I2F 4'b1101
`define INVF 4'b1110
`define MULF 4'b1111


//substates
`define pc_set 2'b00
`define pc_inc 2'b01
`define pc_inc2 2'b10
`define pc_out 2'b11
`define reg_getval 2'b00
`define reg_setadd 2'b01
`define reg_setval 2'b10
`define reg_null 2'b1
`define ir_getval 2'b00
`define ir_setadd 2'b01
`define ir_setval 2'b10
`define ir_null 2'b1
`define mem_getval 2'b00
`define mem_setadd 2'b01
`define mem_setval 2'b10
`define mem_null 2'b1


//controller states
`define startseq 3'b000
`define instruction 3'b001
`define ALUOP 3'b010 
`define JZSYSSZ 3'b011
`define LDAT 3'b100
`define STAT 3'b101
`define LIOP 3'b110
`define HALT 3'b111


//substates
`define first 4'b0000
`define fetchinstr 4'b0001
`define fetchregval 4'b0010
`define fetchaluout 4'b0011
`define pushregadd `first
`define syscheck 4'b0100
`define compare0 4'b0101
`define pcjump 4'b0110
`define getstuff 4'b0111
`define storestuff 4'b1000
`define fetchpc `first
`define setadd `first
`define loadr1add `first
`define pushir 4'b1001
`define parseop 4'b1010
`define pushaluval 4'b1011
`define pcwait 4'b1100
`define fetchimm 4'b1101
`define waitforpcinc 4'b1110
`define pushtempval 4'b1111


module controller();
        wire clock;
        reg [3:0] op;
        reg [1:0] pcstate, irstate, memstate, regstate1, regstate2;
        reg [15:0] pcset, memin, irin, r1in, r2in, temp1, temp2;
        wire [15:0] irout, memout, r1out, r2out, result, pcout;
        reg [3:0] state, aluop;
        reg [3:0] subcase;
        reg [5:0] reg1, reg2;
        reg [15:0] ALU_A, ALU_B;
        masterclock paws(clock);
        PC pongo(clock, pcset, pcstate, pcout);
        IR lassie(clock, irstate, irin, irout);
        REGFILE reggie(clock, regstate1, regstate2, r1in, r2in, r1out, r2out);   
        MEM atlas(clock, memstate, memin, memout);                        // they're good names
        ALU creativename(clock, aluop, ALU_A, ALU_B, result);
        
        initial begin
                state = `startseq;
                subcase = `first;
        end
        
        always @ (posedge clock)
        begin
                case (state)        
                        `startseq: begin        
                                                case (subcase)
                                                        `fetchpc: begin
                                                                        irstate = `ir_setadd;
                                                                        pcstate = `pc_out;
                                                                        subcase = `pushir;
                                                                        end
                                                        `pushir: begin
                                                                        subcase = `fetchinstr;
                                                                        irin = pcout;
                                                                        end
                                                        `fetchinstr: begin        
                                                                        irstate = `ir_getval;        
                                                                        subcase = `parseop;
                                                                        end
                                                        `parseop: begin
                                                                        op = irout[15:12];
                                                                        reg1 = irout[11:6];
                                                                        reg2 = irout[5:0];
                                                                        state = `instruction;
                                                                        subcase = `first;
                                                                        end
                                                endcase
                                        end
                        `instruction: begin        
                                                        case (op)
                                                                `ADD: state = `ALUOP;
                                                                `AND: state = `ALUOP;
                                                                `OR:  state = `ALUOP;
                                                                `ANY: state = `ALUOP;
                                                                `SHR: state = `ALUOP;
                                                                `XOR: state = `ALUOP;
                                                                `DUP: state = `ALUOP;
                                                                `JZ: state = `JZSYSSZ;
                                                                `LD: state = `LDAT;
                                                                `ST: state = `STAT;
                                                                `LI: state = `LIOP;
                                                                `ADDF: state = `HALT;
                                                                `F2I: state = `HALT;
                                                                `I2F: state = `HALT;
                                                                `INVF: state = `HALT;
                                                                `MULF: state = `HALT;
                                                        endcase
                                                end
                        `ALUOP: begin        
                                                case (subcase)
                                                `pushregadd: begin
                                                                                regstate1 = `reg_setadd;
                                                                                regstate2 = `reg_setadd;
                                                                                r1in = reg1;
                                                                                r2in = reg2;
                                                                                subcase = `fetchregval;
                                                                        end
                                                `fetchregval: begin
                                                                                regstate1 = `reg_getval;
                                                                                regstate2 = `reg_getval;
                                                                                subcase = `pushaluval;
                                                                        end
                                                `pushaluval: begin
                                                                                aluop = op;
                                                                                ALU_A = r1out;
                                                                                ALU_B = r2out;
                                                                                subcase = `fetchaluout;
                                                                        end
                                                `fetchaluout: begin        
                                                                                regstate1 = `reg_setval;
                                                                                subcase = `storestuff;
                                                                                pcstate = `pc_inc;
                                                                        end
                                                `storestuff: begin
                                                                                subcase = `first;
                                                                                state = `startseq;
                                                                                pcstate = `pc_out;
                                                                                r1in = result;
                                                                        end
                                                endcase
                                        end
                        `JZSYSSZ: begin        
                                                case (subcase)        
                                                `pushregadd: begin
                                                        regstate1 = `reg_setadd;
                                                        regstate2 = `reg_setadd;
                                                        r1in = reg1;
                                                        r2in = reg2;
                                                        subcase = `fetchregval;
                                                        end
                                                `fetchregval: begin
                                                        regstate1 = `reg_getval;
                                                        regstate2 = `reg_getval;
                                                        subcase = `pushtempval;
                                                        end
                                                `pushtempval: begin
                                                        temp1 = r1out;
                                                        temp2 = r2out;
                                                        subcase = `syscheck;
                                                        end
                                                `syscheck: begin
                                                                                if (temp2 == 0)
                                                                                        state = `HALT;
                                                                                else
                                                                                        subcase = `compare0;
                                                                        end
                                                `compare0: begin        
                                                                        if (temp1 == 0)
                                                                        begin
                                                                                if (temp2 == 1)
                                                                                begin
                                                                                        pcstate = `pc_inc2;
                                                                                        subcase = `waitforpcinc;
                                                                                end
                                                                                else
                                                                                        subcase = `pcjump;
                                                                        end
                                                                        else        begin
                                                                                state = `startseq;
                                                                                pcstate = `pc_inc;
                                                                                subcase = `first;
                                                                                end
                                                                end
                                                `waitforpcinc: begin
                                                                                pcstate = `pc_out;
                                                                                state = `startseq;
                                                                                subcase = `first;
                                                                        end
                                                `pcjump: begin        
                                                                        pcstate = `pc_set;
                                                                        pcset = temp2;
                                                                        state = `startseq;
                                                                        subcase = `first;
                                                                end
                                                endcase
                                        end
                        `HALT: pcstate = `pc_out;
                        `LDAT: begin
                                        case(subcase)
                                                `setadd: begin
                                                                        r1in = reg1;
                                                                        regstate1 = `reg_setadd;
                                                                        memin = reg2;
                                                                        memstate = `mem_setadd;
                                                                        subcase = `getstuff;
                                                                end
                                                `getstuff: begin
                                                                        memstate = `mem_getval;
                                                                        subcase = `storestuff;
                                                                        regstate1 = `reg_setval;
                                                                end
                                                `storestuff: begin
                                                                        r1in = memout;
                                                                        pcstate = `pc_inc;
                                                                        state = `startseq;
                                                                        subcase = `first;
                                                                end
                                        endcase
                                end
                        `STAT: begin
                                        case(subcase)
                                                `setadd: begin
                                                                        r1in = reg1;
                                                                        regstate1 = `reg_setadd;
                                                                        memin = reg2;
                                                                        memstate = `mem_setadd;
                                                                        subcase = `getstuff;
                                                                end
                                                `getstuff: begin
                                                                        regstate1 = `reg_getval;
                                                                        subcase = `storestuff;
                                                                        memstate = `mem_setval;
                                                                end
                                                `storestuff: begin        
                                                                        memin = r1out;
                                                                        pcstate = `pc_inc;
                                                                        state = `startseq;
                                                                        subcase = `first;
                                                                end
                                        endcase
                                end
                        `LIOP: begin
                                        case (subcase)
                                                `loadr1add: begin
                                                                        regstate1 = `reg_setadd;
                                                                        r1in = reg1;
                                                                        pcstate = `pc_inc;
                                                                        subcase = `pcwait;
                                                                        end
                                                `pcwait:        begin
                                                                        irstate = `ir_setadd;
                                                                        pcstate = `pc_out;
                                                                        subcase = `fetchimm;
                                                                        end
                                                `fetchimm: begin
                                                                        irin = pcout;
                                                                        irstate = `ir_getval;
                                                                        subcase = `fetchinstr;
                                                                        end
                                                `fetchinstr: begin        
                                                                        regstate1 = `reg_setval;
                                                                        r1in = irout;
                                                                        pcstate = `pc_inc;
                                                                        state = `startseq;
                                                                        subcase = `first;
                                                                        end
                                        endcase
                                end
                        default: state = `HALT;
                endcase
        end
endmodule




module masterclock(clock);
        output reg clock;
        initial 
                clock = 0;
        always 
        begin 
                #5 clock = ~clock;
        end


endmodule




module IR(clock, state, IRin, IRout);
        input clock;
        input [15:0] IRin;
        input [1:0] state;
        output reg [15:0] IRout;
        reg [15:0] IRreg [65535:0];
        reg [5:0] IRaddress;
        initial begin
        $readmemh("instruction.txt", IRreg);
        end
        always @ (negedge clock)
        begin        
                case (state)
                        `ir_getval: IRout = IRreg [IRin];
                        `ir_setval: IRreg [IRaddress] = IRin;
                        `ir_setadd: IRaddress = IRin;
                endcase
        end
endmodule


module PC(clock, pcset, state, pcout);
        input clock;
        reg [15:0] pc;
        input [15:0] pcset;
        output reg [15:0] pcout;
        input [1:0]        state;
        initial begin
                pc = 0;        
        end
        always @ (negedge clock)
        begin
                case (state)
                        `pc_set: pc = pcset;
                        `pc_inc: pc = pc + 1;
                        `pc_inc2:pc = pc + 2;
                        `pc_out: pcout = pc;
                endcase
        end
endmodule
        


module REGFILE(clock, state1, state2, R1in, R2in, R1out, R2out);
        input clock;
        input [15:0] R1in, R2in;
        input [1:0] state1, state2;
        output reg [15:0] R1out, R2out;
        reg [15:0] register [65535:0];
        reg [5:0] RA1, RA2;


        initial begin
                $readmemh("meminit.txt", register);
        end
        
        always @(posedge clock)
        begin
                register [0] = 0;
                register [1] = 1;
                register [2] = 16'h8000;
                register [3] = 16'hffff;
        end
        always @ (negedge clock)
        begin        
                case (state1)
                        `reg_getval: R1out = register [R1in];
                        `reg_setval: begin
                                                        if (RA1 > 4)
                                                                register [RA1] = R1in;
                                                end
                        `reg_setadd: RA1 = R1in;
                endcase
        end


        
        always @ (negedge clock)
        begin        
                case (state2)
                        `reg_getval: R2out = register [R2in];
                        `reg_setval: begin
                                                        if (RA2 > 4)
                                                                register [RA2] = R2in;
                                                end
                        `reg_setadd: RA2 = R2in;
                endcase
        end
endmodule


module MEM(clock, state, Memin, Memout);
        input clock;
        input [15:0] Memin;
        input [1:0] state;
        output reg [15:0] Memout;
        reg [15:0] data [65535:0];
        reg [5:0] Memaddress;
        initial begin
                $readmemh("meminit.txt", data);
        end
        always @ (negedge clock)
        begin        
                case (state)        
                        `mem_getval: Memout = data [Memaddress];
                        `mem_setval: data [Memaddress] = Memin;
                        `mem_setadd: Memaddress = Memin;
                endcase
        end
endmodule


module ALU(clock, aluop, ALU_A, ALU_B, ALU_out);
        input clock;
        input [3:0] aluop;
        input [15:0] ALU_A, ALU_B;
        output reg [15:0] ALU_out;
        
        always @(posedge clock)
        begin
                case(aluop)
                        `ADD: ALU_out = ALU_A + ALU_B;
                        `AND: ALU_out = ALU_A & ALU_B;
                        `ANY: begin        
                                        if (ALU_B != 0)
                                                ALU_out = 1;
                                        else
                                                ALU_out = 0;
                                        end
                        `OR: ALU_out = ALU_A | ALU_B;
                        `SHR: ALU_out = ALU_A >> 1;
                        `XOR: ALU_out = ALU_A ^ ALU_B;
                        `DUP: ALU_out = ALU_A;
                        default: ALU_out = 0;
                 endcase
        end
endmodule


module testbench;
        controller c1();
        initial begin
                $dumpfile("dump.txt");
                $dumpvars(0, testbench);
        end
endmodule