/*
 * ********************************************************** 
 * # Final Project 486/586 Computer Architecture Spring 2022
 * # Filename: Functional Simulator
 * # Written by: Sumanth Saggurthi, Vemuri Kousalya Gayatri, 
     Sasi kiran Nalluri, Ronaldo Leon, Dang Nguyen   
 * ********************************************************** 
*/


`include "mipspkg.sv"

module non_pipeline(output ex);


import mipspkg::*;

parameter fun = 1;

assign ex = exit;
// Fetching instructions from the trace file.
 initial begin : file_block

   fetchData = $fopen ("./sample_memory_image.txt", "r");
  if(fetchData ==0)
    disable file_block;  
  while (!($feof(fetchData))) begin
    $fscanf(fetchData, "%32h",{memory[i], memory[i+1], memory[i+2], memory[i+3]});
     i=i+4;
   begin
  end
    end
  $fclose(fetchData);

end : file_block


// clock generation
bit clk=0;
always 
    #10 clk=~clk;


        


// Execution of functional simulator.
always@(posedge clk) begin
begin
countCycles=countCycles+1;

Fetch();
Decode();
Execute();
Memory();
WriteBack(fun);
end
end

endmodule
