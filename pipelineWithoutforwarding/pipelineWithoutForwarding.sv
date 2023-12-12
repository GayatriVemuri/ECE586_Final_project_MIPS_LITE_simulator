/*
 * **********************************************************
 * # Final Project 486/586 Computer Architecture Spring 2022
 * # Filename: Functional Simulator + Pipeline Without Forwarding
 * # Written by: Sumanth Saggurthi, Vemuri Kousalya Gayatri,
     Sasi kiran Nalluri, Ronaldo Leon, Dang Nguyen
 * **********************************************************
*/


`include "mipspkgf.sv";
`include "../FunctionalSimulator/FunctionalSimulator.sv"

module PipelineWithoutForwarding();

import mipspkgf:: *;

bit halt=0;
int i=0;
bit exit;
bit fex;

non_pipeline non(fex);

defparam non.fun = 0;

// Fetching instructions from the trace file.
 initial
 begin:file_block
	//$display("Hello");
	fetchData = $fopen ("./sample_memory_image.txt", "r");
	if(fetchData ==0)
		disable file_block;

	while (!($feof(fetchData)))
		begin
		$fscanf(fetchData, "%32h",{memory[i], memory[i+1], memory[i+2], memory[i+3]});
		i=i+4;
		end
	#60;
	$fclose(fetchData);
end:file_block


// clock generation
bit clk=0;
always
	#10 clk=~clk;


// Instruction fetch stage
always@(posedge clk)
 begin
	if(exit==0)
	begin
		if(fetchWait==0)
		begin
			for(int i=0; i<5; i++)
			begin
			if(instructionStage[i]==0 )
				begin
				instructionStage[i] <=1;
				instructionLine[i].Ir ={memory[pc], memory[pc+1], memory[pc+2], memory[pc+3] }  ;
				instructionLine[i].pcValue     = pc;
				pc=pc+4;
				break;
				end
			end
		end
	end
end


// Instruction decode stage and checking the stalls
always@(posedge clk)
begin
	if(exit==0 )
	begin
		#0;
		for(int i=0; i<5; i++)
		begin
			if(instructionStage[i]==4'd1)
			begin
				decode_stage(i) ;
				decodeStall = check_decodeStall(i);
				decodeWait =0;
				if(decodeStall!=0 && halt==0 )
				begin
					rawStalls=rawStalls+1;
					repeat(decodeStall)
					begin
						decodeWait<=1;
						fetchWait <=1;
						@(posedge clk);
						fetchWait<=0;
					end
				decode_stage(i) ;
				decodeWait<=0;
				end
				instructionStage[i]<=2;
				break;
			end
		end
	end
end


// Instruction execute stage
always@(posedge clk)
begin
	if(exit==0)
	begin
		for(int i=0; i<5; i++)
		begin
			if(instructionStage[i]==4'd2)
			begin
				instructionStage[i]<=3;
				if(branchTaken ==0 )
				begin
				case(instructionLine[i].opcode)
				ADD :    instructionLine[i].result = instructionLine[i].Rs + instructionLine[i].Rt;
				ADDI :  instructionLine[i].result = instructionLine[i].Rs + instructionLine[i].imm;
				SUB :     instructionLine[i].result = instructionLine[i].Rs - instructionLine[i].Rt;
				SUBI :   instructionLine[i].result = instructionLine[i].Rs - instructionLine[i].imm;
				MUL :   instructionLine[i].result = instructionLine[i].Rs * instructionLine[i].Rt;
				MULI :  instructionLine[i].result = instructionLine[i].Rs * instructionLine[i].imm;
				OR :        instructionLine[i].result = instructionLine[i].Rs | instructionLine[i].Rt;
				ORI :    instructionLine[i].result = instructionLine[i].Rs | instructionLine[i].imm;
				AND :     instructionLine[i].result = instructionLine[i].Rs & instructionLine[i].Rt;
				ANDI :   instructionLine[i].result = instructionLine[i].Rs & instructionLine[i].imm;
				XOR :     instructionLine[i].result = instructionLine[i].Rs ^ instructionLine[i].Rt;
				XORI :   instructionLine[i].result = instructionLine[i].Rs ^ instructionLine[i].imm;
				LOAD  :   instructionLine[i].loadAdd = instructionLine[i].Rs + instructionLine[i].imm;
				STORE :   instructionLine[i].storeAdd = instructionLine[i].Rs + instructionLine[i].imm;
				BZ : 	 begin
						if(instructionLine[i].Rs==0)
							begin
							pc<= (instructionLine[i].xInstruction*4 )+instructionLine[i].pcValue;
							branchTaken<=1;
							temporary=1;
							branchCount= branchCount +1;
							end
						end
				BEQ : 	begin
						if(instructionLine[i].Rs==instructionLine[i].Rt)
							begin
							pc<= (instructionLine[i].xInstruction*4) +instructionLine[i].pcValue ;
							branchTaken<=1;
							temporary=1;
							branchCount= branchCount +1;
							end
						end
				JR : 	begin
						pc<=instructionLine[i].Rs;
						branchTaken<=1;
						temporary=1;
						branchCount= branchCount +1;
						 end
				HALT : halt=1;
				endcase
				end
				else
				begin
				instructionLine[i].opcode=6'd22;
				count=count+1;
				if(count>1)
					begin
					count=0;
					branchTaken<=0;
					temporary=0;
					end
				end
				break;
			end
		end
	end
end


// Instruction memory stage
always@(posedge clk)
begin
	if(exit==0)
	begin
		for(int i=0; i<5; i++)
		begin
			if(instructionStage[i]==4'd3)
			begin
				instructionStage[i]<=4;
				case(instructionLine[i].opcode)
				LOAD : 	instructionLine[i].loadData =  {memory[instructionLine[i].loadAdd],memory[instructionLine[i].loadAdd+1], memory[instructionLine[i].loadAdd+2], 	memory[instructionLine[i].loadAdd+3]};
				STORE :	{memory[instructionLine[i].storeAdd],memory[instructionLine[i].storeAdd+1], memory[instructionLine[i].storeAdd+2], memory[instructionLine[i].storeAdd+3]} = instructionLine[i].Rt;
				endcase
				break;
                       end
		end
	end
end


// Instuction write back stage
always@(posedge clk)
begin
	if(exit==0)
	begin
		for(int i=0; i<5; i++)
		begin
			if(instructionStage[i]==4'd4)
			begin
				if(instructionLine[i].opcode <= 6'd18)
					instructionCount =instructionCount+1;
				instructionStage[i]<=0;
				case(instructionLine[i].opcode)
				ADD :	registers[instructionLine[i].rdAdd] = instructionLine[i].result;
				ADDI : 	registers[instructionLine[i].rtAdd] = instructionLine[i].result;
				SUB :     registers[instructionLine[i].rdAdd] = instructionLine[i].result;
				SUBI :   registers[instructionLine[i].rtAdd] = instructionLine[i].result;
				MUL :   registers[instructionLine[i].rdAdd] = instructionLine[i].result;
				MULI:   registers[instructionLine[i].rtAdd] = instructionLine[i].result;
				OR:      	registers[instructionLine[i].rdAdd] = instructionLine[i].result;
				ORI:    	registers[instructionLine[i].rtAdd] = instructionLine[i].result;
				AND:     registers[instructionLine[i].rdAdd] = instructionLine[i].result;
				ANDI:   registers[instructionLine[i].rtAdd] = instructionLine[i].result;
				XOR:     registers[instructionLine[i].rdAdd] = instructionLine[i].result;
				XORI:   registers[instructionLine[i].rtAdd] = instructionLine[i].result;
				LOAD :   registers[instructionLine[i].rtAdd] = instructionLine[i].loadData;
				HALT:    begin exit<=1;  end
				endcase
				break;
                       end
		end
	end
end

//END OF STAGES
always@(posedge clk)
begin
	if(exit==0)
		begin countCycles=countCycles+1;  end
	if(decodeWait && halt==0)
		totalStall=totalStall+1;
	if(exit&&fex)
        begin
        statistics();
		$finish;
        end
end

endmodule

