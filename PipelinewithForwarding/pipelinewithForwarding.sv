/*
 * **********************************************************
 * # Final Project 486/586 Computer Architecture Spring 2022
 * # Filename: Functional Simulator + Pipeline With Forwarding
 * # Written by: Sumanth Saggurthi, Vemuri Kousalya Gayatri,
     Sasi kiran Nalluri, Ronaldo Leon, Dang Nguyen
 * **********************************************************
*/


`include "mipspkg_withforwarding.sv"
`include "../FunctionalSimulator/FunctionalSimulator.sv"


module pipeline_forward();


import withforwarding::*;


non_pipeline non(exit);

defparam non.fun = 0;

assign fex = exit;

// Memory fill

 initial begin : file_block
        fetchDecode = $fopen ("./sample_memory_image.txt", "r");
  if(fetchDecode ==0)
    disable file_block;
  while (!($feof(fetchDecode))) begin
    $fscanf(fetchDecode, "%32h",{memory[i], memory[i+1], memory[i+2], memory[i+3]});
     i=i+4;
   begin
  end
    end
  #25;
//  $finish();
  $fclose(fetchDecode);
end : file_block

// clock generation
bit clk=0;
always begin
#10 clk=~clk;
end

//Instrecution fetch stage
always@(posedge clk)  begin
if(done==0) begin
 if(fetchWait==0) begin
   for(int i=0; i<5; i++) begin
            if(instructionStage[i]==0 ) begin
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

//Instrecution decode stage
always@(posedge clk) begin
if(done==0) begin
#0;
   for(int i=0; i<5; i++) begin
            if(instructionStage[i]==4'd1) begin
                          decode_stage(i) ;
                          decodeStall = check_decodeStall(i);
                          if(decodeStall==1) begin
                          rawStalls=rawStalls+1;
                           fetchWait <=1;
                            @(posedge clk);
                            fetchWait<=0;
                           decode_stage(i) ;
                             end
                          instructionStage[i]<=2;
                       break;
		       end
           end
 end
end

 // Instrecution execute stage
always@(posedge clk) begin
if(done==0) begin
       for(i=0; i<5; i++) begin
            if(instructionStage[i]==4'd2) begin
                          instructionLine[i].Rs=$signed(registerUpdated[instructionLine[i].rsAdd]);
                          instructionLine[i].Rt=$signed(registerUpdated[instructionLine[i].rtAdd]);
                          instructionLine[i].Rd=$signed(registerUpdated[instructionLine[i].rdAdd]);
                          instructionStage[i]<=3;
                     if(branchTaken ==0 ) begin
                         case(instructionLine[i].opcode)

                           ADD :  begin  instructionLine[i].result = instructionLine[i].Rs + instructionLine[i].Rt;
                                         registerUpdated[instructionLine[i].rdAdd] =  $signed(instructionLine[i].result);
                                  end
                           ADDI:  begin  instructionLine[i].result = instructionLine[i].Rs + instructionLine[i].imm ;
                                         registerUpdated[instructionLine[i].rtAdd] =  $signed(instructionLine[i].result) ;
                                  end
                           SUB:   begin  instructionLine[i].result = instructionLine[i].Rs - instructionLine[i].Rt;
                                         registerUpdated[instructionLine[i].rdAdd] =  $signed(instructionLine[i].result) ;
                                  end
                           SUBI:  begin instructionLine[i].result = instructionLine[i].Rs - instructionLine[i].imm ;
                                        registerUpdated[instructionLine[i].rtAdd] =  $signed(instructionLine[i].result) ;
                                  end
                           MUL:   begin  instructionLine[i].result = instructionLine[i].Rs * instructionLine[i].Rt;
                                         registerUpdated[instructionLine[i].rdAdd] =  $signed(instructionLine[i].result) ;
                                  end
                           MULI:  begin instructionLine[i].result = instructionLine[i].Rs * instructionLine[i].imm ;
                                         registerUpdated[instructionLine[i].rtAdd] =  $signed(instructionLine[i].result) ;
                                  end
                           OR:    begin instructionLine[i].result = instructionLine[i].Rs | instructionLine[i].Rt;
                                        registerUpdated[instructionLine[i].rdAdd] =  $signed(instructionLine[i].result) ;
                                  end
                           ORI:   begin instructionLine[i].result = instructionLine[i].Rs | instructionLine[i].imm ;
                                        registerUpdated[instructionLine[i].rtAdd] =  $signed(instructionLine[i].result );
                                  end
                           AND:   begin  instructionLine[i].result = instructionLine[i].Rs & instructionLine[i].Rt;
                                         registerUpdated[instructionLine[i].rdAdd] =  $signed(instructionLine[i].result) ;
                                  end
                           ANDI:  begin instructionLine[i].result = instructionLine[i].Rs & instructionLine[i].imm ;
                                        registerUpdated[instructionLine[i].rtAdd] =  $signed(instructionLine[i].result );
                                  end
                           XOR:   begin  instructionLine[i].result = instructionLine[i].Rs ^ instructionLine[i].Rt;
                                         registerUpdated[instructionLine[i].rdAdd] =  $signed(instructionLine[i].result) ;
                                  end
                           XORI:  begin instructionLine[i].result = instructionLine[i].Rs ^ instructionLine[i].imm ;
                                        registerUpdated[instructionLine[i].rtAdd] =  $signed(instructionLine[i].result) ;
                                  end
                           LOAD :   instructionLine[i].loadAdd=instructionLine[i].Rs+instructionLine[i].imm;
                           STORE:   instructionLine[i].storeAdd= instructionLine[i].Rs+instructionLine[i].imm;
                           BZ:      begin if(instructionLine[i].Rs==0)  begin pc<= (instructionLine[i].x_inst*4 )+instructionLine[i].pcValue;  branchTaken<=1; branchCount= branchCount +1;  end end
                           BEQ:    begin if(instructionLine[i].Rs==instructionLine[i].Rt) begin  pc<= (instructionLine[i].x_inst*4) +instructionLine[i].pcValue ; branchTaken<=1; branchCount= branchCount +1; end end
                           JR:     begin pc<=instructionLine[i].Rs; branchTaken<=1; branchCount= branchCount +1; end

                           endcase
                        end
                      else begin

                           instructionLine[i].opcode=6'd22;
                           count=count+1;
                           if(count>1) begin
                              count=0;
                              branchTaken<=0;
                            end
                        end

                           break;
               end
        end
  end
end
//----------------------------------------- Instruction memory stage --------------------------------------------------------------//

always@(posedge clk) begin
if(done==0) begin
      for(i=0; i<5; i++) begin
            if(instructionStage[i]==4'd3) begin
                         instructionStage[i]<=4;
                        case(instructionLine[i].opcode)

                           LOAD : begin
                             instructionLine[i].loadData= {memory[instructionLine[i].loadAdd],memory[instructionLine[i].loadAdd+1], memory[instructionLine[i].loadAdd+2], memory[instructionLine[i].loadAdd+3]};
                                registerUpdated[ instructionLine[i].rtAdd] = $signed(instructionLine[i].loadData);
                           	   end

                           STORE: begin
                             {memory[instructionLine[i].storeAdd],memory[instructionLine[i].storeAdd+1], memory[instructionLine[i].storeAdd+2], memory[instructionLine[i].storeAdd+3]}=instructionLine[i].Rt;
                           	   end
                           endcase
                           break;
                       end
         end
  end
end

// Instuction write back stage
always@(posedge clk) begin
if(done==0) begin
      for(i=0; i<5; i++) begin

            if(instructionStage[i]==4'd4)  begin
                         if(instructionLine[i].opcode <= 6'd18)
                         instructionCount =instructionCount+1;
                         instructionStage[i]<=0;
                         case(instructionLine[i].opcode)

                           ADD :    registers[instructionLine[i].rdAdd] = instructionLine[i].result;
                           ADDI:   registers[instructionLine[i].rtAdd] = instructionLine[i].result;
                           SUB:     registers[instructionLine[i].rdAdd] = instructionLine[i].result;
                           SUBI:   registers[instructionLine[i].rtAdd] = instructionLine[i].result;
                           MUL:     registers[instructionLine[i].rdAdd] = instructionLine[i].result;
                           MULI:   registers[instructionLine[i].rtAdd] = instructionLine[i].result;
                           OR:      registers[instructionLine[i].rdAdd] = instructionLine[i].result;
                           ORI:    registers[instructionLine[i].rtAdd] = instructionLine[i].result;
                           AND:     registers[instructionLine[i].rdAdd] = instructionLine[i].result;
                           ANDI:   registers[instructionLine[i].rtAdd] = instructionLine[i].result;
                           XOR:     registers[instructionLine[i].rdAdd] = instructionLine[i].result;
                           XORI:   registers[instructionLine[i].rtAdd] = instructionLine[i].result;
                           LOAD :   registers[instructionLine[i].rtAdd] = instructionLine[i].loadData;
                           HALT:    done<=1;

                           endcase
                           break;
                       end
         end
  end

end

// END OF STAGES
always@(posedge clk)
begin
if(done==0) countCycles=countCycles+1;
else if(done && fex) begin stat();$finish; end
end

endmodule
