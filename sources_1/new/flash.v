`include "defines.vh"

module flash(
    input wire rst, clk,
    input wire[22:0] addr,
    inout wire[15:0] flash_data,
    
    output reg flash_ce,
    output reg flash_we,
    output reg flash_oe,
    output wire flash_rp,   //0���ã�1����
    output wire flash_byte, //0�ֽڷ�ʽ��1�ַ�ʽ
    output wire flash_vpen, //д����������1
    output reg[22:0] flash_addr,
    output reg[15:0] data_out
);

    // Ӧ������վƽ̨ʵ��
    /*reg[15:0] data_flash[0:4194303];
    initial $readmemh ("flash.data", data_flash);
    assign flash_data = { data_flash[addr][7:0], data_flash[addr][15:8] };*/

    assign flash_rp = 1'b1;
//    assign flash_ce = 1'b0;
    assign flash_vpen = 1'b1;
    assign flash_byte = 1'b1;

    reg[2:0] cur_state = 3'b000;
    reg[15:0] flash_data_tep;
    
    assign flash_data = flash_data_tep;
    
    always @(posedge clk or posedge rst) begin
		if (rst) begin
		    flash_ce <= 1'b1;
			flash_oe <= 1'b1;
			flash_we <= 1'b1;
			cur_state <= 3'b000;
			flash_data_tep <= 16'bz;
            //ctl_read_last <= ctl_read;
        end
		else begin
			case(cur_state)
				3'b000:begin
				    flash_ce <= 1'b0;   //Ƭѡ
                    flash_we <= 1'b0;
                    cur_state <= 3'b001;
                    //if (ctl_read /= ctl_read_last) then
                    //ctl_read_last <= ctl_read;
				end
                3'b001:begin
					flash_data_tep <= 4'h00FF;
					cur_state <= 3'b010;
                end
                3'b010:begin
					flash_we <= 1'b1;
					cur_state <= 3'b011;
                end
                3'b011:begin
					flash_oe <= 1'b0;
					flash_addr <= addr;
					flash_data_tep <= 16'bz;
					cur_state <= 3'b100;
                end
                3'b100:begin
					data_out <= flash_data_tep;
					cur_state <= 3'b101;        // ��ִ��default
                end
				3'b101:begin
					flash_oe <= 1'b1;
					flash_we <= 1'b1;
					flash_data_tep <= 16'bz;
					cur_state <= 3'b000;
                end
                default:begin
                    cur_state <= 3'b000;
                end
			endcase
		end
	end

endmodule