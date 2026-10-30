`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/27/2021 12:29:56 AM
// Design Name: 
// Module Name: image_processor
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module image_processor_with_MF(clk,clk_en,rstn,vsynch_in,hsynch_in,data_enable_in, vsynch_out,hsynch_out,data_in,valid_out
, column_cnt_r,filtered_out,line_cnt_r);
	 
	 parameter DISPARITY_BITS = 8;
    parameter WIDTH = 1920;
    parameter HEIGHT = 1080;
	 parameter LINE_CNT_BITS = $clog2(HEIGHT);
	 parameter COLUMN_CNT_BITS = $clog2(WIDTH);

	 input clk,clk_en,rstn, vsynch_in,hsynch_in, data_enable_in;
	 input [DISPARITY_BITS-1:0] data_in;
	 output reg vsynch_out, hsynch_out;
	 output reg valid_out;
	 reg valid_outNxt_r;

	 // LINE means ROW 
	 reg  hsynch_outNxt_r, vsynch_outNxt_r;
	output reg [LINE_CNT_BITS:0] line_cnt_r;
	 reg [LINE_CNT_BITS:0] line_cntNxt_r;
	 output reg [COLUMN_CNT_BITS:0] column_cnt_r;
	 reg [COLUMN_CNT_BITS:0]  column_cntNxt_r;
	 wire [DISPARITY_BITS - 1:0] median; 

	 
     // These are the median filter's window inputs
	 wire [DISPARITY_BITS -1 :0] w11,w12,w13,w21,w22,w23,w31,w32,w33; 

     // address values of the first and second line buffers   
	 reg [COLUMN_CNT_BITS:0] line0_adr, line1_adr;
     // write enable and reset signals of line buffers       
	 reg line0_we, line1_we,rstLB0,rstLB1;
	 // read and written values from line buffers
	 wire [DISPARITY_BITS - 1:0] line0_di, line1_di, line0_do, line1_do;
	 // delayed and current input disparities which will be used in the filter window
	 reg [DISPARITY_BITS - 1:0] data_in_r,data_in_rNxt,data_in_2d, data_in_2dNxt,data_in_3d,data_in_3dNxt ;
	 assign line0_di = data_in;
     assign line1_di = data_in;	 
     reg update,updateNxt;
	 


     // since we use  active-low reset in the top-module and the distributed RAM ( buffer) uses active-high
     // reset, we apply NOT gates between two resets.     
	 single_port_RAM LB0 (.clk(clk), .we(line0_we), .rst(~rstn), .a(line0_adr), .di(data_in_r), .do(line0_do)); 
	 single_port_RAM LB1 (.clk(clk), .we(line1_we), .rst(~rstn), .a(line0_adr), .di(data_in_r), .do(line1_do)); 
	// shift_reg is a simple sub-module that outputs each window row disparities by storing and 
	// shifting its input values ( Shift Register with throughput = 3 ) 
		shift_reg shift_reg_current_line(.data_in(data_in_2d),.clk(clk),.rstn(rstn),.reg_out({w31,w32,w33})
    );
	 	 
		shift_reg shift_reg_line0(.data_in(line0_do),.clk(clk),.rstn(rstn),.reg_out({w11,w12,w13})
    );
	 	 
		shift_reg shift_reg_line1(.data_in(line1_do),.clk(clk),.rstn(rstn),.reg_out({w21,w22,w23})
    );
	 	 


	 
     median_filter median_filter_i(.in0(w33),.in1(w32),.
     in2(w31),.in3(w23),.in4(w22)
     ,.in5(w21),.in6(w13),.in7(w12),.in8(w11),.out(median),.clk(clk));
	 reg do_filter,do_filterNxt; // this signal determiens when to use the input disparity value and when to use the median value
	 // In order to keep the each line (row)'s first value ( before writing new values to the buffer)
	 // we store the line headers in separated registers and do not filter them.  
	 reg [DISPARITY_BITS - 1:0] line_header,line_headerNxt,line_header_tmp,line_header_tmpNxt,line_end,line_endNxt,tmp_1,tmp_1Nxt,tmp_2,tmp_2Nxt;
	 output [DISPARITY_BITS - 1:0] filtered_out;
	 assign filtered_out = do_filter ? median : line_header_tmp;
	 reg trigger,triggerNxt;
	 always@(posedge clk ) begin

			if(clk_en) begin
				vsynch_out <= vsynch_outNxt_r;
				hsynch_out <= hsynch_outNxt_r;
				line_cnt_r <= line_cntNxt_r;
				column_cnt_r <= column_cntNxt_r;
				valid_out <= valid_outNxt_r;
				data_in_r <= data_in_rNxt;
				data_in_2d <= data_in_2dNxt;
				line_header <= line_headerNxt;
				line_header_tmp <= line_header_tmpNxt;
				data_in_3d <= data_in_3dNxt;
				line_end <= line_endNxt;
				update <= updateNxt;
				tmp_1 <= tmp_1Nxt;
				tmp_2 <= tmp_2Nxt;
				do_filter <= do_filterNxt;
				trigger <= triggerNxt;

								                      
			end

		 
	end	
	 always @(*) begin
			do_filterNxt = 0;	 	  
			vsynch_outNxt_r = 0;
			hsynch_outNxt_r = hsynch_in;
			valid_outNxt_r = 0;
			if(!trigger) line_cntNxt_r = 1; 
			else line_cntNxt_r = line_cnt_r;
			column_cntNxt_r = column_cnt_r;
			line0_we = 0;
			line1_we = 0;
			line0_adr = 0;
			line1_adr = 0;
			data_in_rNxt = data_in;
			data_in_2dNxt = data_in_r;
			line_headerNxt = line_header;
			line_header_tmpNxt = line_header_tmp;
			line_endNxt = line_end;
			updateNxt = 0;
			tmp_2Nxt = tmp_2;
			tmp_1Nxt = tmp_1;
			triggerNxt = 1;
	
			
         
		 if((rstn == 0) ) begin
			vsynch_outNxt_r = 0;
			hsynch_outNxt_r = 0;
			triggerNxt = 0;
			column_cntNxt_r = 0;
			valid_outNxt_r = 0;
			line_headerNxt = 0;
			line_header_tmpNxt = 0;
			line_endNxt = 0;
			tmp_1Nxt = 0;
			tmp_2Nxt = 0;
			
			
		 end
		 else begin
		    // we process the data when the ENABLE signal is HIGH, however, we have to turn off the ENABLE
		    // when no more inputs are left in the frame and we still processing the last line of the frame.
		    // Thus, such a condition is required.   				
			if( (data_enable_in) || ( !valid_out) || (line_cnt_r == HEIGHT)) begin

                vsynch_outNxt_r = 0;
              
                // Determining which buffer should be written currently depends on the line number and mod 2 operation result
                if((line_cnt_r % 2) != 0) line0_we = 1; 
                if((line_cnt_r % 2) == 0) line1_we = 1;	
                if (column_cnt_r == 0) begin // this is done since column counter becomes zero at the last address
                    line0_adr = WIDTH - 1;
                    line1_adr = WIDTH - 1;
                end
                else begin
                
                    line0_adr = column_cnt_r - 1;
                    line1_adr = column_cnt_r - 1;					 
                
                end
                // Setting each line header's value and its registers
                // line_end stores the last value of each column
                // tmp is a register that stores the value  line_end of each previous line (row)
                if ( column_cnt_r == 5) line_header_tmpNxt = tmp_1;

                if( column_cnt_r == 4)  line_header_tmpNxt = tmp_2; // new
                if(( column_cnt_r == 0  ) ) begin
                    line_headerNxt = data_in;
                   
               
                end
                if( column_cnt_r > 10) begin
                     tmp_1Nxt = line_header;
                     tmp_2Nxt = line_end;
                end       
 
                column_cntNxt_r = column_cnt_r + 1;
                if(column_cnt_r == (WIDTH - 1 )) begin
                    column_cntNxt_r = 0;
                    line_endNxt = data_in;
                end    
                if (hsynch_out && ( line_cnt_r < HEIGHT) ) line_cntNxt_r = line_cnt_r + 1;
                // we do NOT increase the line counter's value when it is equal to the frame's height
                // To switch to the next frame we set the global reset signal as LOW  
                if ((line_cnt_r == HEIGHT) && (hsynch_out == 1)) line_cntNxt_r = line_cnt_r;
                
                if( (line_cnt_r > 2)    && ( column_cnt_r < WIDTH)) begin
                    // before reaching the fourth disparity data in each line we cannot start filtering yet.
                    // Thus, the valid signal still ZERO at this stage. 
                    if( (line_cnt_r == 3) && ( column_cnt_r < 5 ) && ( hsynch_out != 1)) begin //  column_cnt_r < 4 idi
                        do_filterNxt = 0;
                        valid_outNxt_r = 0;
                    end
                    // Here, we send the last filtered data when the ENABLE signal is OFF
                    // Notice that  last disparity data of the frame should be unfiltered,i.e:
                    // we do NOT filter the first and last disparities of each row in the frame 
                    // Moreover, the output frame does NOT include the first and last rows of the input frame. 
                    else if( (line_cnt_r == HEIGHT) && ( column_cnt_r == 4) && ( data_enable_in == 0)) begin // column_cnt_r == 3 idi
                    
                        valid_outNxt_r = 1;
                        do_filterNxt = 0;
                        vsynch_outNxt_r = 1;
                    
                    end
                    // This condition shows that we have reached the end of one frame processing                    
                    else if( (line_cnt_r == HEIGHT) && ( column_cnt_r >= 5) && ( data_enable_in == 0)) begin // >= 4 idi
                        valid_outNxt_r = 0;
                        do_filterNxt = 0;
                        vsynch_outNxt_r = 0;
                        // Newly added ( to process multiple frames)
                        hsynch_outNxt_r = 0;
                        line_cntNxt_r = 1;
                        column_cntNxt_r = 0;
                        valid_outNxt_r = 0;
                        line_headerNxt = 0;
                        line_header_tmpNxt = 0;
                        line_endNxt = 0;
                        tmp_1Nxt = 0;                       
                        tmp_2Nxt = 0;
                    end
                    else begin
                         valid_outNxt_r = 1;    
                         // Do not filter the first and last disparity value of each line 
                         if( ( (column_cnt_r == 4 ) || (column_cnt_r == 5 ) )) do_filterNxt = 0; // bunlar 5 || 4 idi
                         
                         else do_filterNxt = 1;                         
                    
                    end    
                end
                
                
                if(column_cnt_r == (WIDTH - 1 )) column_cntNxt_r = 0;			  

			end
   
	 
	 end
end	 

endmodule  


