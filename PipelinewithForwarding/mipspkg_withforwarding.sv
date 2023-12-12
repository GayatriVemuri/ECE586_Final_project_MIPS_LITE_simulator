package withforwarding;

parameter  ADD	=6'd0;
parameter  ADDI	=6'd1;
parameter  SUB	=6'd2;
parameter  SUBI	=6'd3;
parameter  MUL	=6'd4;
parameter  MULI	=6'd5;
parameter  OR	=6'd6;
parameter  ORI	=6'd7;
parameter  AND	=6'd8;
parameter  ANDI	=6'd9;
parameter  XOR	=6'd10;
parameter  XORI	=6'd11;
parameter  LOAD	=6'd12;
parameter  STORE	=6'd13;
parameter  BZ	=6'd14;
parameter  BEQ	=6'd15;
parameter  JR	=6'd16;
parameter  HALT	=6'd17;

bit signed [31:0]registers[32];
bit signed [31:0]registerUpdated[32];
bit signed [7:0]memory[4096];
bit signed [31:0]pc;
int fetchDecode;
int count;
int countCycles;
int rawStalls;
int instructionCount;
bit branchTaken;
int branchCount ;
int hit;
bit done;
struct             {

  bit [31:0]Ir;
  bit [5:0]opcode;
  bit [4:0]rsAdd;
  bit [4:0]rtAdd;
  bit [4:0]rdAdd;
  bit signed [31:0]Rs;
  bit signed [31:0]Rt;
  bit signed [31:0]Rd;
  bit signed [16:0]imm;
  bit signed [31:0]result;
  bit [31:0]loadAdd;
  bit [31:0]storeAdd;
  bit signed [31:0]loadData;
  bit signed [31:0]pcValue;
  int signed sourceRegister1;
  int signed sourceRegister2;
  int signed destinationRegister;
  bit signed [31:0]x_inst; } instructionLine[5];
bit [3:0] instructionStage[5];
int i=0;
int decodeStall;
bit fetchWait;

wire fex,exit;

task decode_stage(int i);
	instructionLine[i].opcode = instructionLine[i].Ir[31:26];

        if ( (instructionLine[i].opcode==ADD) || (instructionLine[i].opcode==SUB) ||   (instructionLine[i].opcode==MUL) || (instructionLine[i].opcode==OR) ||(instructionLine[i].opcode==AND) ||(instructionLine[i].opcode==XOR))
        begin
                instructionLine[i].rsAdd     = instructionLine[i].Ir[25:21];
                instructionLine[i].rtAdd     = instructionLine[i].Ir[20:16];
                instructionLine[i].rdAdd     = instructionLine[i].Ir[15:11];
                instructionLine[i].sourceRegister1 = instructionLine[i].Ir[25:21];
                instructionLine[i].sourceRegister2     = instructionLine[i].Ir[20:16];
                instructionLine[i].destinationRegister     = instructionLine[i].Ir[15:11];
                instructionLine[i].Rs         = $signed(registers[instructionLine[i].Ir[25:21]]);
                instructionLine[i].Rt         = $signed(registers[instructionLine[i].Ir[20:16]]);
                instructionLine[i].Rd         = $signed(registers[instructionLine[i].Ir[15:11]]);
        end

        else if ((instructionLine[i].opcode==ADDI) ||(instructionLine[i].opcode==SUBI) ||(instructionLine[i].opcode==MULI) ||(instructionLine[i].opcode==ORI) ||(instructionLine[i].opcode==ANDI) ||(instructionLine[i].opcode==XORI) || (instructionLine[i].opcode==LOAD) || (instructionLine[i].opcode==STORE))
        begin
		instructionLine[i].imm        = $signed(instructionLine[i].Ir[15:0]);
		instructionLine[i].rsAdd     = instructionLine[i].Ir[25:21];
		instructionLine[i].rtAdd     = instructionLine[i].Ir[20:16];
		instructionLine[i].sourceRegister1 = instructionLine[i].Ir[25:21];
		instructionLine[i].destinationRegister     = instructionLine[i].Ir[20:16];
		instructionLine[i].sourceRegister2  = 32'hffff;
		instructionLine[i].Rs         = $signed(registers[instructionLine[i].Ir[25:21]]);
		instructionLine[i].Rt         = $signed(registers[instructionLine[i].Ir[20:16]]);
        end

        else if ((instructionLine[i].opcode== BZ))
        begin
		instructionLine[i].rsAdd     = instructionLine[i].Ir[25:21];
		instructionLine[i].x_inst     = $signed(instructionLine[i].Ir[15:0]);
		instructionLine[i].Rs         = $signed(registers[instructionLine[i].Ir[25:21]]);
		instructionLine[i].sourceRegister1 = instructionLine[i].Ir[25:21];
		instructionLine[i].destinationRegister    = 32'hffff;
		instructionLine[i].sourceRegister2  = 32'hffff;
	end

	else if ((instructionLine[i].opcode== BEQ))
	begin
		instructionLine[i].rsAdd     = instructionLine[i].Ir[25:21];
		instructionLine[i].rtAdd     = instructionLine[i].Ir[20:16];
		instructionLine[i].x_inst     = $signed(instructionLine[i].Ir[15:0]);
		instructionLine[i].sourceRegister1 = instructionLine[i].Ir[25:21];
		instructionLine[i].sourceRegister2= instructionLine[i].Ir[20:16];
		instructionLine[i].destinationRegister  = 32'hffff;
		instructionLine[i].Rs         = $signed(registers[instructionLine[i].Ir[25:21]]);
		instructionLine[i].Rt         = $signed(registers[instructionLine[i].Ir[20:16]]);
	end

                         else if ((instructionLine[i].opcode== JR)) begin
                                     instructionLine[i].rsAdd     = instructionLine[i].Ir[25:21];
                                     instructionLine[i].Rs         = $signed(registers[instructionLine[i].Ir[25:21]]);
                                     instructionLine[i].sourceRegister1 = instructionLine[i].Ir[25:21];
                                     instructionLine[i].destinationRegister    = 32'hffff;
                                     instructionLine[i].sourceRegister2  = 32'hffff;
                                     end
                           else begin
                                      instructionLine[i].Rd         = 0;
                                      instructionLine[i].Rs         = 0;
                                      instructionLine[i].Rt         = 0;
                                      instructionLine[i].rdAdd     = 0;
                                      instructionLine[i].rsAdd     = 0;
                                      instructionLine[i].rtAdd     = 0;
                                      instructionLine[i].sourceRegister1 =  32'hffff;
                                      instructionLine[i].destinationRegister    = 32'hffff;
                                      instructionLine[i].sourceRegister2  = 32'hffff;
				   end
endtask


function int check_decodeStall(int add );
	for(int i=0; i<5; i++)
	begin
		if( ( ( instructionLine[add].sourceRegister1== instructionLine[i].destinationRegister) || ( instructionLine[add].sourceRegister2== instructionLine[i].destinationRegister) )    &&  ( instructionLine[i].destinationRegister != 32'hffff )  && instructionStage[i]==4'd2 && branchTaken==0 &&  instructionLine[i].opcode == 6'd12 )
		begin
			hit=1; 	break;
		end
	end
	if(hit==1)
	begin
		hit=0;  	return 1;
	end
	else
		return 0 ;
endfunction


function void stat();

$display( "Total stalls: %d" ,rawStalls );

$display("\nTiming Simulator:");

$display( "\nTotal number of clock cycles : %d" , countCycles );
$display("\nProgram Halted\n");

endfunction

endpackage
