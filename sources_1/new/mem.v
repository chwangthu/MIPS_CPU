//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2014 leishangwen@163.com                       ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
// Module:  mem
// File:    mem.v
// Author:  Lei Silei
// E-mail:  leishangwen@163.com
// Description: �ô�׶�
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module mem(

	input wire					  rst,
	
	//����
	input wire                    clk,
	
	//����ִ�н׶ε���Ϣ	
	input wire[`RegAddrBus]       wd_i,
	input wire                    wreg_i,
	input wire[`RegBus]			  wdata_i,
	input wire[`RegBus]           hi_i,
	input wire[`RegBus]           lo_i,
	input wire                    whilo_i,	

  	input wire[`AluOpBus]        aluop_i,
	input wire[`RegBus]          mem_addr_i,
	input wire[`RegBus]          reg2_i,
	
	//����memory����Ϣ
	input wire[`RegBus]          mem_data_i,

	//LLbit_i��LLbit�Ĵ�����ֵ
	input wire                  LLbit_i,
	//����һ��������ֵ����д�׶ο���ҪдLLbit�����Ի�Ҫ��һ���ж�
	input wire                  wb_LLbit_we_i,
	input wire                  wb_LLbit_value_i,

	//Э������CP0��д�ź�
	input wire                   cp0_reg_we_i,
	input wire[4:0]              cp0_reg_write_addr_i,
	input wire[`RegBus]          cp0_reg_data_i,
	
	input wire[31:0]             excepttype_i,
	input wire                   is_in_delayslot_i,
	input wire[`RegBus]          current_inst_address_i,	
	
	//CP0�ĸ����Ĵ�����ֵ������һ�������µ�ֵ��Ҫ��ֹ��д�׶�ָ��дCP0
	input wire[`RegBus]          cp0_status_i,
	input wire[`RegBus]          cp0_cause_i,
	input wire[`RegBus]          cp0_epc_i,

	//��д�׶ε�ָ���Ƿ�ҪдCP0����������������
  	input wire                    wb_cp0_reg_we,
	input wire[4:0]               wb_cp0_reg_write_addr,
	input wire[`RegBus]           wb_cp0_reg_data,
	
	//�͵���д�׶ε���Ϣ
	output reg[`RegAddrBus]      wd_o,
	output reg                   wreg_o,
	output reg[`RegBus]			 wdata_o,
	output reg[`RegBus]          hi_o,
	output reg[`RegBus]          lo_o,
	output reg                   whilo_o,

	output reg                   LLbit_we_o,
	output reg                   LLbit_value_o,

	output reg                   cp0_reg_we_o,
	output reg[4:0]              cp0_reg_write_addr_o,
	output reg[`RegBus]          cp0_reg_data_o,
	
	//�͵�memory����Ϣ
	output reg[`RegBus]          mem_addr_o,
	output wire					 mem_we_o,
	output reg[3:0]              mem_sel_o,
	output reg[`RegBus]          mem_data_o,
	output reg                   mem_ce_o,
	
	output reg[31:0]             excepttype_o,
	output wire[`RegBus]          cp0_epc_o,
	output wire                  is_in_delayslot_o,
	
	output wire[`RegBus]         current_inst_address_o,

	// ��д�����й�(base_ram)
	input wire					 tbre,
	input wire					 tsre,
	input wire					 data_ready,
	inout wire[`ByteWidth]		 base_ram_data,
	output reg 				     base_ram_ce_n,
    output reg 		       		 base_ram_oe_n,
    output reg					 base_ram_we_n,
	output reg     				 rdn,
	output reg  				 wrn
);

  	reg LLbit;
	wire[`RegBus] zero32;
	reg[`RegBus]          cp0_status;
	reg[`RegBus]          cp0_cause;
	reg[`RegBus]          cp0_epc;	
	reg                   mem_we;

	// ���ڲ���
	reg write_prep;
	reg read_prep;
	reg[`RegBus] wdata_o_temp;
	reg wdata_flag = 1'b0;
	reg[`ByteWidth] final_base_ram_data;
    
    assign base_ram_data = final_base_ram_data;
    

	assign mem_we_o = mem_we & (~(|excepttype_o));
	assign zero32 = `ZeroWord;

	assign is_in_delayslot_o = is_in_delayslot_i;
	assign current_inst_address_o = current_inst_address_i;
	assign cp0_epc_o = cp0_epc;

	//���������wdata_o�����ո�ֵ
	always @ (wdata_o_temp or base_ram_data) begin
		if(wdata_flag == 1'b0) begin
			wdata_o <= wdata_o_temp;
		end else if(wdata_flag == 1'b1) begin
			wdata_o <= base_ram_data;
			wdata_flag <= 1'b0;
		end
	end	
	
	// ram_we control
	always @ (posedge rst or posedge clk) begin
		if(rst == `RstEnable) begin
			base_ram_we_n <= 1'b1;
		end else begin
			base_ram_we_n <= 1'b1;
		end
	end

	// wrn control
	always @ (posedge rst or posedge clk or write_prep) begin
		if(rst == `RstEnable) begin
			wrn <= 1'b1;
		end else if(write_prep == `ChipEnable) begin
			wrn <= clk;
		end else begin
			wrn <= 1'b1;
		end
	end

	// rdn control
	always @ (posedge rst or posedge clk or read_prep) begin
		if(rst == `RstEnable) begin
			rdn <= 1'b1;
		end else if(read_prep == `ChipEnable) begin
			rdn <= clk;
		end else begin
			rdn <= 1'b1;
		end
	end

  	//��ȡ���µ�LLbit��ֵ
	always @ (*) begin
		if(rst == `RstEnable) begin
			LLbit <= 1'b0;
		end else begin
			if(wb_LLbit_we_i == 1'b1) begin
				LLbit <= wb_LLbit_value_i;
			end else begin
				LLbit <= LLbit_i;
			end
		end
	end
	
	always @ (*) begin
		if(rst == `RstEnable) begin
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
		  wdata_o_temp <= `ZeroWord;
		  hi_o <= `ZeroWord;
		  lo_o <= `ZeroWord;
		  whilo_o <= `WriteDisable;		
		  mem_addr_o <= `ZeroWord;
		  mem_we <= `WriteDisable;
		  mem_sel_o <= 4'b0000;
		  mem_data_o <= `ZeroWord;		
		  mem_ce_o <= `ChipDisable;
		  LLbit_we_o <= 1'b0;
		  LLbit_value_o <= 1'b0;		
		  cp0_reg_we_o <= `WriteDisable;
		  cp0_reg_write_addr_o <= 5'b00000;
		  cp0_reg_data_o <= `ZeroWord;		        
		end else begin
		  wd_o <= wd_i;
			wreg_o <= wreg_i;
			wdata_o_temp <= wdata_i;
			hi_o <= hi_i;
			lo_o <= lo_i;
			whilo_o <= whilo_i;		
			mem_we <= `WriteDisable;
			mem_addr_o <= `ZeroWord;
			mem_sel_o <= 4'b1111;
			mem_ce_o <= `ChipDisable;
		  LLbit_we_o <= 1'b0;
		  LLbit_value_o <= 1'b0;		
		  cp0_reg_we_o <= cp0_reg_we_i;
		  cp0_reg_write_addr_o <= cp0_reg_write_addr_i;
		  cp0_reg_data_o <= cp0_reg_data_i;		 		  	
			case (aluop_i)
				`EXE_LB_OP:		begin
					// ������
					if(mem_addr_i == 32'hBFD003F8) begin
						base_ram_ce_n <= 1'b1;
						base_ram_oe_n <= 1'b1;
						final_base_ram_data <= 8'bz;
						read_prep <= `ChipEnable;
						write_prep <= `ChipDisable;

						mem_ce_o <= `ChipDisable;
						wdata_flag <= 1'b1;
						
					//�����ڱ�־λ
					end else if(mem_addr_i == 32'hBFD003FC) begin
						base_ram_ce_n <= 1'b0;
						base_ram_oe_n <= 1'b1;
						read_prep <= `ChipDisable;
						write_prep <= `ChipDisable;

						if(data_ready == 1'b1 && tbre == 1'b1 && tsre == 1'b1) begin
							// ���ڿɶ���д
							wdata_o_temp <= 8'b00000011;
						end else if (tbre == 1'b1 && tsre == 1'b1) begin
							// ����ֻд
							wdata_o_temp <= 8'b00000001;
						end else if(data_ready == 1'b1) begin
							// ����ֻ��
							wdata_o_temp <= 8'b00000010;
						end else begin
							// ���ڲ�����д
						  	wdata_o_temp <= 8'b00000000;
						end
						
						mem_ce_o <= `ChipDisable;
					end else begin
						mem_addr_o <= mem_addr_i;
						mem_we <= `WriteDisable;
						mem_ce_o <= `ChipEnable;
						case (mem_addr_i[1:0])
							2'b00:	begin
								wdata_o_temp <= {{24{mem_data_i[31]}},mem_data_i[31:24]};
								mem_sel_o <= 4'b1000;
							end
							2'b01:	begin
								wdata_o_temp <= {{24{mem_data_i[23]}},mem_data_i[23:16]};
								mem_sel_o <= 4'b0100;
							end
							2'b10:	begin
								wdata_o_temp <= {{24{mem_data_i[15]}},mem_data_i[15:8]};
								mem_sel_o <= 4'b0010;
							end
							2'b11:	begin
								wdata_o_temp <= {{24{mem_data_i[7]}},mem_data_i[7:0]};
								mem_sel_o <= 4'b0001;
							end
							default:	begin
								wdata_o_temp <= `ZeroWord;
							end
						endcase
					end
				end
				`EXE_LBU_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							wdata_o_temp <= {{24{1'b0}},mem_data_i[31:24]};
							mem_sel_o <= 4'b1000;
						end
						2'b01:	begin
							wdata_o_temp <= {{24{1'b0}},mem_data_i[23:16]};
							mem_sel_o <= 4'b0100;
						end
						2'b10:	begin
							wdata_o_temp <= {{24{1'b0}},mem_data_i[15:8]};
							mem_sel_o <= 4'b0010;
						end
						2'b11:	begin
							wdata_o_temp <= {{24{1'b0}},mem_data_i[7:0]};
							mem_sel_o <= 4'b0001;
						end
						default:	begin
							wdata_o_temp <= `ZeroWord;
						end
					endcase				
				end
				`EXE_LH_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							wdata_o_temp <= {{16{mem_data_i[31]}},mem_data_i[31:16]};
							mem_sel_o <= 4'b1100;
						end
						2'b10:	begin
							wdata_o_temp <= {{16{mem_data_i[15]}},mem_data_i[15:0]};
							mem_sel_o <= 4'b0011;
						end
						default:	begin
							wdata_o_temp <= `ZeroWord;
						end
					endcase					
				end
				`EXE_LHU_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							wdata_o_temp <= {{16{1'b0}},mem_data_i[31:16]};
							mem_sel_o <= 4'b1100;
						end
						2'b10:	begin
							wdata_o_temp <= {{16{1'b0}},mem_data_i[15:0]};
							mem_sel_o <= 4'b0011;
						end
						default:	begin
							wdata_o_temp <= `ZeroWord;
						end
					endcase				
				end
				`EXE_LW_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					wdata_o_temp <= mem_data_i;
					mem_sel_o <= 4'b1111;		
					mem_ce_o <= `ChipEnable;
				end
				`EXE_LWL_OP:		begin
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteDisable;
					mem_sel_o <= 4'b1111;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							wdata_o_temp <= mem_data_i[31:0];
						end
						2'b01:	begin
							wdata_o_temp <= {mem_data_i[23:0],reg2_i[7:0]};
						end
						2'b10:	begin
							wdata_o_temp <= {mem_data_i[15:0],reg2_i[15:0]};
						end
						2'b11:	begin
							wdata_o_temp <= {mem_data_i[7:0],reg2_i[23:0]};	
						end
						default:	begin
							wdata_o_temp <= `ZeroWord;
						end
					endcase				
				end
				`EXE_LWR_OP:		begin
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteDisable;
					mem_sel_o <= 4'b1111;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							wdata_o_temp <= {reg2_i[31:8],mem_data_i[31:24]};
						end
						2'b01:	begin
							wdata_o_temp <= {reg2_i[31:16],mem_data_i[31:16]};
						end
						2'b10:	begin
							wdata_o_temp <= {reg2_i[31:24],mem_data_i[31:8]};
						end
						2'b11:	begin
							wdata_o_temp <= mem_data_i;	
						end
						default:	begin
							wdata_o_temp <= `ZeroWord;
						end
					endcase					
				end
				`EXE_LL_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					wdata_o_temp <= mem_data_i;	
		  		LLbit_we_o <= 1'b1;
		  		LLbit_value_o <= 1'b1;
		  		mem_sel_o <= 4'b1111;					
		  		mem_ce_o <= `ChipEnable;				
				end				
				`EXE_SB_OP:		begin
					// д����
					if(mem_addr_i == 8'hBFD003F8) begin
						base_ram_ce_n <= 1'b1;
						base_ram_oe_n <= 1'b1;
						final_base_ram_data <= reg2_i[7:0];
						read_prep <= `ChipDisable;
						write_prep <= `ChipEnable;

						mem_ce_o <= `ChipDisable;
					end else begin
						mem_addr_o <= mem_addr_i;
						mem_we <= `WriteEnable;
						mem_data_o <= {reg2_i[7:0],reg2_i[7:0],reg2_i[7:0],reg2_i[7:0]};
						mem_ce_o <= `ChipEnable;
						case (mem_addr_i[1:0])
							2'b00:	begin
								mem_sel_o <= 4'b1000;
							end
							2'b01:	begin
								mem_sel_o <= 4'b0100;
							end
							2'b10:	begin
								mem_sel_o <= 4'b0010;
							end
							2'b11:	begin
								mem_sel_o <= 4'b0001;	
							end
							default:	begin
								mem_sel_o <= 4'b0000;
							end
						endcase	
					end			
				end
				`EXE_SH_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_data_o <= {reg2_i[15:0],reg2_i[15:0]};
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							mem_sel_o <= 4'b1100;
						end
						2'b10:	begin
							mem_sel_o <= 4'b0011;
						end
						default:	begin
							mem_sel_o <= 4'b0000;
						end
					endcase						
				end
				`EXE_SW_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_data_o <= reg2_i;
					mem_sel_o <= 4'b1111;			
					mem_ce_o <= `ChipEnable;
				end
				`EXE_SWL_OP:		begin
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteEnable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin						  
							mem_sel_o <= 4'b1111;
							mem_data_o <= reg2_i;
						end
						2'b01:	begin
							mem_sel_o <= 4'b0111;
							mem_data_o <= {zero32[7:0],reg2_i[31:8]};
						end
						2'b10:	begin
							mem_sel_o <= 4'b0011;
							mem_data_o <= {zero32[15:0],reg2_i[31:16]};
						end
						2'b11:	begin
							mem_sel_o <= 4'b0001;	
							mem_data_o <= {zero32[23:0],reg2_i[31:24]};
						end
						default:	begin
							mem_sel_o <= 4'b0000;
						end
					endcase							
				end
				`EXE_SWR_OP:		begin
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteEnable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin						  
							mem_sel_o <= 4'b1000;
							mem_data_o <= {reg2_i[7:0],zero32[23:0]};
						end
						2'b01:	begin
							mem_sel_o <= 4'b1100;
							mem_data_o <= {reg2_i[15:0],zero32[15:0]};
						end
						2'b10:	begin
							mem_sel_o <= 4'b1110;
							mem_data_o <= {reg2_i[23:0],zero32[7:0]};
						end
						2'b11:	begin
							mem_sel_o <= 4'b1111;	
							mem_data_o <= reg2_i[31:0];
						end
						default:	begin
							mem_sel_o <= 4'b0000;
						end
					endcase											
				end 
				`EXE_SC_OP:		begin
					if(LLbit == 1'b1) begin
						LLbit_we_o <= 1'b1;
						LLbit_value_o <= 1'b0;
						mem_addr_o <= mem_addr_i;
						mem_we <= `WriteEnable;
						mem_data_o <= reg2_i;
						wdata_o_temp <= 32'b1;
						mem_sel_o <= 4'b1111;		
						mem_ce_o <= `ChipEnable;				
					end else begin
						wdata_o_temp <= 32'b0;
					end
				end				
				default:		begin
          //ʲôҲ����
				end
			endcase							
		end    //if
	end      //always

	always @ (*) begin
		if(rst == `RstEnable) begin
			cp0_status <= `ZeroWord;
		end else if((wb_cp0_reg_we == `WriteEnable) && 
								(wb_cp0_reg_write_addr == `CP0_REG_STATUS ))begin
			cp0_status <= wb_cp0_reg_data;
		end else begin
		  cp0_status <= cp0_status_i;
		end
	end
	
	always @ (*) begin
		if(rst == `RstEnable) begin
			cp0_epc <= `ZeroWord;
		end else if((wb_cp0_reg_we == `WriteEnable) && 
								(wb_cp0_reg_write_addr == `CP0_REG_EPC ))begin
			cp0_epc <= wb_cp0_reg_data;
		end else begin
		  cp0_epc <= cp0_epc_i;
		end
	end

  always @ (*) begin
		if(rst == `RstEnable) begin
			cp0_cause <= `ZeroWord;
		end else if((wb_cp0_reg_we == `WriteEnable) && 
								(wb_cp0_reg_write_addr == `CP0_REG_CAUSE ))begin
			cp0_cause[9:8] <= wb_cp0_reg_data[9:8];
			cp0_cause[22] <= wb_cp0_reg_data[22];
			cp0_cause[23] <= wb_cp0_reg_data[23];
		end else begin
		  cp0_cause <= cp0_cause_i;
		end
	end

	always @ (*) begin
		if(rst == `RstEnable) begin
			excepttype_o <= `ZeroWord;
		end else begin
			excepttype_o <= `ZeroWord;
			
			if(current_inst_address_i != `ZeroWord) begin
				if(((cp0_cause[15:8] & (cp0_status[15:8])) != 8'h00) && (cp0_status[1] == 1'b0) && 
							(cp0_status[0] == 1'b1)) begin
					excepttype_o <= 32'h00000001;        //interrupt
				end else if(excepttype_i[8] == 1'b1) begin
			  	excepttype_o <= 32'h00000008;        //syscall
				end else if(excepttype_i[9] == 1'b1) begin
					excepttype_o <= 32'h0000000a;        //inst_invalid
				end else if(excepttype_i[10] ==1'b1) begin
					excepttype_o <= 32'h0000000d;        //trap
				end else if(excepttype_i[11] == 1'b1) begin  //ov
					excepttype_o <= 32'h0000000c;
				end else if(excepttype_i[12] == 1'b1) begin  //����ָ��
					excepttype_o <= 32'h0000000e;
				end
			end
				
		end
	end			

endmodule