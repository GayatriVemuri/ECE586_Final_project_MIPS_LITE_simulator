package mipspkg;

parameter  ADD       =6'd0;
parameter  ADDI    =6'd1;
parameter  SUB       =6'd2;
parameter  SUBI    =6'd3;
parameter  MUL       =6'd4;
parameter  MULI    =6'd5;
parameter  OR      =6'd6;
parameter  ORI   =6'd7;
parameter  AND     =6'd8;
parameter  ANDI  =6'd9;
parameter  XOR     =6'd10;
parameter  XORI  =6'd11;
parameter  LOAD    =6'd12;
parameter  STORE   =6'd13;
parameter  BZ      =6'd14;
parameter  BEQ     =6'd15;
parameter  JR      =6'd16;
parameter  HALT    =6'd17;
bit exit;
bit  signed  [31:0]registers[32];
bit signed  [7:0]memory[4096];
bit signed  [31:0]pc;
int fetchData;
int count;
int countCycles;
int instructionCount;
int arithmetic;
int logical;
int branches;
int branchTaken;
int memCount;
int i;
int registerTrack[32];
int memTrack[4096];
bit  signed [31:0]Ir;
bit  [5:0]opcode;
bit  [4:0]rsAdd;
bit  [4:0]rtAdd;
bit  [4:0]rdAdd;
bit signed  [31:0]Rs;
bit signed  [31:0]Rt;
bit signed  [31:0]Rd;
bit signed  [16:0]imm;
bit signed  [31:0]result;
bit  [31:0]loadAdd;
bit  [31:0]storeAdd;
bit signed  [31:0]loadData;
bit signed [31:0]x_inst;


function void Fetch();

          begin
             Ir ={memory[pc], memory[pc+1], memory[pc+2], memory[pc+3] }  ;
             pc=pc+4;
          end

endfunction


function void Decode( );

     opcode = Ir[31:26];
                         if ( (opcode==ADD) || (opcode==SUB) || (opcode==MUL) || (opcode==OR) || (opcode==AND) || (opcode==XOR))

                                    begin
                                      rsAdd     = Ir[25:21];
                                      rtAdd     = Ir[20:16];
                                      rdAdd     = Ir[15:11];
                                      Rs         = $signed(registers[Ir[25:21]]);
                                      Rt         = $signed(registers[Ir[20:16]]);
                                      Rd         = $signed(registers[Ir[15:11]]);
                         	   end

                         else if ((opcode==ADDI) || (opcode==SUBI) || (opcode==MULI) || (opcode==ORI) || (opcode==ANDI) || ( opcode==XORI) || (opcode==LOAD) || (opcode==STORE))
                                    begin
                                      imm        = $signed(Ir[15:0]);
                                      rsAdd     = Ir[25:21];
                                      rtAdd     = Ir[20:16];
                                      Rs         = $signed(registers[Ir[25:21]]);
                                      Rt         = $signed(registers[Ir[20:16]]);
                         	   end

                         else if ((opcode== BZ))
                                   begin
                                     rsAdd     = Ir[25:21];
                                     x_inst     = $signed(Ir[15:0]);
                                     Rs         = $signed(registers[Ir[25:21]]);
                                     end

                         else if (opcode== BEQ)

                                     begin
                                     rsAdd     = Ir[25:21];
                                     rtAdd     = Ir[20:16];
                                       x_inst   = $signed(Ir[15:0]);
                                       Rs       = $signed(registers[Ir[25:21]]);
                                       Rt       = $signed(registers[Ir[20:16]]);
                                     end

                         else if (opcode== JR)

                                     begin
                                     rsAdd     = Ir[25:21];
                                       Rs         = $signed(registers[Ir[25:21]]);
                                     end
                          else
                                   begin
                                      Rd         = 0;
                                      Rs         = 0;
                                      Rt         = 0;
                                      rdAdd     = 0;
                                      rsAdd     = 0;
                                      rtAdd     = 0;
				   end

                        registerTrack[rsAdd]=1;
                        registerTrack[rtAdd]=1;
                        registerTrack[rdAdd]=1;

endfunction


function void Execute();

                         case(opcode)
                           ADD        : result = Rs + Rt;
                           ADDI     : result = Rs + imm;
                           SUB        : result = Rs - Rt;
                           SUBI     : result = Rs - imm;
                           MUL        : result = Rs * Rt;
                           MULI     : result = Rs * imm;
                           OR       : result = Rs | Rt;
                           ORI    : result = Rs | imm;
                           AND      : result = Rs & Rt;
                           ANDI   : result = Rs & imm;
                           XOR      : result = Rs ^ Rt;
                           XORI   : result = Rs ^ imm;
                           LOAD     : begin loadAdd=Rs+imm;  memCount=memCount+1;   end
                           STORE    : begin storeAdd=Rs+imm; memCount=memCount+1; memTrack[ storeAdd]=1; end
                           BZ       : begin branches=branches+1; if(Rs==0)  begin branchTaken=branchTaken+1; pc<= (x_inst*4 )+ pc-4; end end
                           BEQ      : begin branches=branches+1; if( Rs == Rt) begin pc<= (x_inst*4) + pc-4 ;  branchTaken=branchTaken+1; end end
                           JR       : begin pc<= Rs;   branches=branches+1; branchTaken=branchTaken+1;  end
                           endcase
 endfunction


 function void Memory();

             case(opcode)
              LOAD  : loadData= $signed({memory[loadAdd],memory[loadAdd+1], memory[loadAdd+2], memory[loadAdd+3]});
              STORE : {memory[storeAdd],memory[storeAdd+1], memory[storeAdd+2], memory[storeAdd+3]}=$signed(Rt);
             endcase


endfunction


function void stat();
begin
$display( "\n\n                     \n\n"  );
$display("Instruction counts:\n");
$display( "Total number of instructions:           : %d" , instructionCount );
$display( "arithmetic instructions:                : %d" , arithmetic );
$display( "Logical instructions:                   : %d" , logical );
$display( "Memory access instructions:             : %d" , memCount );
$display( "Control transfer instructions:          : %d" , branches + 1);
$display( " \nFinal register state:\n"  );
$display ( "Program counter:    : %d" , pc );
foreach(registerTrack[i])
begin
if(registerTrack[i]==1)
$display( "R%0d are              : %d" , i, registers[i]);
end
$display("\nFinal memory state\n");
foreach(memTrack[i])
begin
if(memTrack[i]==1)
$display( "Address: %0d, Contents: %0d" ,i, {memory[i],memory[i+1],memory[i+2],memory[i+3] });
end
end
endfunction



function void WriteBack(bit fun);

                         instructionCount =instructionCount+1;
                         case(opcode)
                           ADD : begin registers[rdAdd] = result; arithmetic=arithmetic+1; end
                           ADDI: begin registers[rtAdd] = result; arithmetic=arithmetic+1; end
                           SUB: begin registers[rdAdd] = result; arithmetic=arithmetic+1; end
                           SUBI: begin registers[rtAdd] = result; arithmetic=arithmetic+1; end
                           MUL: begin registers[rdAdd] = result; arithmetic=arithmetic+1; end
                           MULI: begin registers[rtAdd] = result; arithmetic=arithmetic+1; end
                           OR: begin registers[rdAdd] = result; logical=logical+1;end
                           ORI: begin registers[rtAdd] = result; logical=logical+1; end
                           AND: begin registers[rdAdd] = result; logical=logical+1;end
                           ANDI: begin registers[rtAdd] = result; logical=logical+1; end
                           XOR: begin registers[rdAdd] = result; logical=logical+1; end
                           XORI: begin registers[rtAdd] =result; logical=logical+1; end
                           LOAD : begin registers[rtAdd] = loadData; end
                           HALT: begin stat(); exit = 1; if(fun == 1) $finish; end

                           endcase

 endfunction


endpackage
