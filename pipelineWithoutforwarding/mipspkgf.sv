package mipspkgf;

parameter  ADD       =6'd0;
parameter  ADDI     =6'd1;
parameter  SUB        =6'd2;
parameter  SUBI      =6'd3;
parameter  MUL      =6'd4;
parameter  MULI    =6'd5;
parameter  OR          =6'd6;
parameter  ORI        =6'd7;
parameter  AND      =6'd8;
parameter  ANDI    =6'd9;
parameter  XOR      =6'd10;
parameter  XORI    =6'd11;
parameter  LOAD   =6'd12;
parameter  STORE  =6'd13;
parameter  BZ          =6'd14;
parameter  BEQ       =6'd15;
parameter  JR           =6'd16;
parameter  HALT   =6'd17;

int fetchData, count, countCycles, rawStalls, instructionCount, branchCount ;
bit branchTaken;
int hit;
bit temporary;

bit signed [31:0] registers[32];
bit signed [7:0]memory[4096];
bit signed [31:0]pc;

typedef struct  {

  bit [31:0]Ir;
  bit [5:0]opcode;
  bit [4:0]rsAdd;
  bit [4:0]rtAdd;
  bit [4:0]rdAdd;
  int signed register1;
  int signed register2;
  int signed destinationAdd;
  bit signed[31:0]Rs;
  bit signed[31:0]Rt;
  bit signed[31:0]Rd;
  bit signed[16:0]imm;
  bit signed[31:0]result;
  bit signed[31:0]loadData;
  bit signed[31:0]pcValue;
  bit [31:0]loadAdd;
  bit [31:0]storeAdd;
  bit signed [31:0]xInstruction;
   } INSTRUCT;

INSTRUCT instructionLine[5];

bit [3:0] instructionStage[5];
bit fetchWait;
int totalStall;
int decodeStall;
bit decodeWait;


task decode_stage(int i);
bit [5:0] OPCODE;

instructionLine[i].opcode = instructionLine[i].Ir[31:26];
OPCODE =  instructionLine[i].Ir[31:26];

if ( (OPCODE==ADD) || (OPCODE==SUB) ||   (OPCODE==MUL) || (OPCODE==OR) ||(OPCODE==AND) ||(OPCODE==XOR))
	begin
        instructionLine[i].rsAdd     = instructionLine[i].Ir[25:21];
        instructionLine[i].rtAdd     = instructionLine[i].Ir[20:16];
        instructionLine[i].rdAdd     = instructionLine[i].Ir[15:11];
        instructionLine[i].register1 = instructionLine[i].Ir[25:21];
        instructionLine[i].register2     = instructionLine[i].Ir[20:16];
        instructionLine[i].destinationAdd     = instructionLine[i].Ir[15:11];
        instructionLine[i].Rs         = $signed(registers[instructionLine[i].Ir[25:21]]);
        instructionLine[i].Rt         = $signed(registers[instructionLine[i].Ir[20:16]]);
        instructionLine[i].Rd         = $signed(registers[instructionLine[i].Ir[15:11]]);
        end

else if ((OPCODE==ADDI) ||(OPCODE==SUBI) ||(OPCODE==MULI) ||(OPCODE==ORI) || (OPCODE==ANDI) ||(OPCODE==XORI) || (OPCODE==LOAD) || (OPCODE==STORE) )
	begin
	instructionLine[i].imm        = $signed(instructionLine[i].Ir[15:0]);
	instructionLine[i].rsAdd     = instructionLine[i].Ir[25:21];
	instructionLine[i].rtAdd     = instructionLine[i].Ir[20:16];
	instructionLine[i].register1 = instructionLine[i].Ir[25:21];
	instructionLine[i].destinationAdd     = instructionLine[i].Ir[20:16];
	instructionLine[i].register2  = 32'hffff;
	instructionLine[i].Rs         = $signed(registers[instructionLine[i].Ir[25:21]]);
	instructionLine[i].Rt         = $signed(registers[instructionLine[i].Ir[20:16]]);
        end

else if ((OPCODE== BZ))
	begin
        instructionLine[i].rsAdd     = instructionLine[i].Ir[25:21];
        instructionLine[i].xInstruction     = $signed(instructionLine[i].Ir[15:0]);
        instructionLine[i].Rs         = $signed(registers[instructionLine[i].Ir[25:21]]);
        instructionLine[i].register1 = instructionLine[i].Ir[25:21];
        instructionLine[i].destinationAdd    = 32'hffff;
        instructionLine[i].register2  = 32'hffff;
        end

else if ((OPCODE== BEQ))
	begin
	instructionLine[i].rsAdd     = instructionLine[i].Ir[25:21];
	instructionLine[i].rtAdd     = instructionLine[i].Ir[20:16];
	instructionLine[i].xInstruction     = $signed(instructionLine[i].Ir[15:0]);
	instructionLine[i].register1 = instructionLine[i].Ir[25:21];
	instructionLine[i].register2= instructionLine[i].Ir[20:16];
	instructionLine[i].destinationAdd  = 32'hffff;
	instructionLine[i].Rs         =$signed( registers[instructionLine[i].Ir[25:21]]);
	instructionLine[i].Rt         = $signed(registers[instructionLine[i].Ir[20:16]]);
        end

else if ((OPCODE== JR ))
	begin
	instructionLine[i].rsAdd     = instructionLine[i].Ir[25:21];
	instructionLine[i].Rs         = $signed(registers[instructionLine[i].Ir[25:21]]);
	instructionLine[i].register1 = instructionLine[i].Ir[25:21];
	instructionLine[i].destinationAdd    = 32'hffff;
	instructionLine[i].register2  = 32'hffff;
	end

else
	begin
	instructionLine[i].Rd         = 0;
	instructionLine[i].Rs         = 0;
	instructionLine[i].Rt         = 0;
	instructionLine[i].rdAdd     = 0;
	instructionLine[i].rsAdd     = 0;
	instructionLine[i].rtAdd     = 0;
	instructionLine[i].register1 =  32'hffff;
	instructionLine[i].destinationAdd    = 32'hffff;
	instructionLine[i].register2  = 32'hffff;
	end
endtask

function int check_decodeStall(int add );
hit=0;

for(int i=0; i<5; i++)
	begin
        if( ( ( instructionLine[add].register1== instructionLine[i].destinationAdd) || ( instructionLine[add].register2== instructionLine[i].destinationAdd) )    &&  ( instructionLine[i].destinationAdd != 32'hffff )  && instructionStage[i]==4'd2 && branchTaken==0 && temporary==0 )
		begin
		hit=1;
		break;
		end
	end

for(int i=0; i<5; i++)
	begin
	if ( ( ( instructionLine[add].register1== instructionLine[i].destinationAdd) || ( instructionLine[add].register2== instructionLine[i].destinationAdd) )   &&  ( instructionLine[i].destinationAdd != 32'hffff )  && instructionStage[i]==4'd3 && hit !=1 &&  branchTaken==0 && temporary==0)
                begin
                hit=2;
                break;
               end
	end

if(hit==0)
	return 0;
else if (hit==1)
	return 2;
else if (hit ==2)
	return 1 ;
  endfunction

function void statistics();
begin

	$display( "Total stalls  : %d" , totalStall );

	$display("\nTiming Simulator:");
	$display( "\nTotal number of clock cycles  : %d" , countCycles );
	$display("\n Program Halted");
end
endfunction

endpackage
