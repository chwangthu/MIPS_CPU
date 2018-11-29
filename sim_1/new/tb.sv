`timescale 1ns / 1ps
`include "defines.vh"

//`define LOAD_PREAMBLE
//`define REVERSE_ENDIAN    // Enable this when using bin files from the book

module tb;
    wire clk_50M, clk_11M0592;
    
    reg clock_btn = 0;         //BTN5�ֶ�ʱ�Ӱ�ť���أ���������·������ʱΪ1
    reg reset_btn = 0;         //BTN6�ֶ���λ��ť���أ���������·������ʱΪ1
    
    reg[3:0]  touch_btn;  //BTN1~BTN4����ť���أ�����ʱΪ1
    reg[31:0] dip_sw;     //32λ���뿪�أ�������ON��ʱΪ1
    
    wire[15:0] leds;       //16λLED�����ʱ1����
    wire[7:0]  dpy0;       //����ܵ�λ�źţ�����С���㣬���1����
    wire[7:0]  dpy1;       //����ܸ�λ�źţ�����С���㣬���1����
    
    wire txd;  //ֱ�����ڷ��Ͷ�
    wire rxd;  //ֱ�����ڽ��ն�
    
    wire[31:0] base_ram_data; //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    wire[19:0] base_ram_addr; //BaseRAM��ַ
    wire[3:0] base_ram_be_n;  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    wire base_ram_ce_n;       //BaseRAMƬѡ������Ч
    wire base_ram_oe_n;       //BaseRAM��ʹ�ܣ�����Ч
    wire base_ram_we_n;       //BaseRAMдʹ�ܣ�����Ч
    
    wire[31:0] ext_ram_data; //ExtRAM����
    wire[19:0] ext_ram_addr; //ExtRAM��ַ
    wire[3:0] ext_ram_be_n;  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    wire ext_ram_ce_n;       //ExtRAMƬѡ������Ч
    wire ext_ram_oe_n;       //ExtRAM��ʹ�ܣ�����Ч
    wire ext_ram_we_n;       //ExtRAMдʹ�ܣ�����Ч
    
    wire [22:0]flash_a;      //Flash��ַ��a0����8bitģʽ��Ч��16bitģʽ������
    wire [15:0]flash_d;      //Flash����
    wire flash_rp_n;         //Flash��λ�źţ�����Ч
    wire flash_vpen;         //Flashд�����źţ��͵�ƽʱ���ܲ�������д
    wire flash_ce_n;         //FlashƬѡ�źţ�����Ч
    wire flash_oe_n;         //Flash��ʹ���źţ�����Ч
    wire flash_we_n;         //Flashдʹ���źţ�����Ч
    wire flash_byte_n;       //Flash 8bitģʽѡ�񣬵���Ч����ʹ��flash��16λģʽʱ����Ϊ1
    
    //Windows��Ҫע��·���ָ�����ת�壬����"D:\\foo\\bar.bin"
    localparam BASE_RAM_INIT_FILE = "/tmp/main.bin"; //BaseRAM��ʼ���ļ������޸�Ϊʵ�ʵľ���·��
    localparam EXT_RAM_INIT_FILE = "kernel_rev.bin";    //ExtRAM��ʼ���ļ������޸�Ϊʵ�ʵľ���·��
    localparam FLASH_INIT_FILE = "/tmp/kernel.elf";    //Flash��ʼ���ļ������޸�Ϊʵ�ʵľ���·��
    
    assign rxd = 1'b1; //idle state
    
    initial begin 
    //    //����������Զ�������������У����磺
    //    dip_sw = 32'h2;
    //    touch_btn = 0;
    //    for (integer i = 0; i < 20; i = i++) begin
    //        #100; //�ȴ�100ns
    //        clock_btn = 1; //�����ֹ�ʱ�Ӱ�ť
    //        #100; //�ȴ�100ns
    //        clock_btn = 0; //�ɿ��ֹ�ʱ�Ӱ�ť
    //    end 
        reset_btn = 1;
        #100 reset_btn = 0;
    end
    
    always @(posedge clk_50M)
        clock_btn = !clock_btn; // 25M
    
    thinpad_top dut(
        .clk_50M(clk_50M),
        .clk_11M0592(clk_11M0592),
        .clock_btn(clock_btn),
        .reset_btn(reset_btn),
        .touch_btn(touch_btn),
        .dip_sw(dip_sw),
        .leds(leds),
        .dpy1(dpy1),
        .dpy0(dpy0),
        .txd(txd),
        .rxd(rxd),
        .base_ram_data(base_ram_data),
        .base_ram_addr(base_ram_addr),
        .base_ram_ce_n(base_ram_ce_n),
        .base_ram_oe_n(base_ram_oe_n),
        .base_ram_we_n(base_ram_we_n),
        .base_ram_be_n(base_ram_be_n),
        .ext_ram_data(ext_ram_data),
        .ext_ram_addr(ext_ram_addr),
        .ext_ram_ce_n(ext_ram_ce_n),
        .ext_ram_oe_n(ext_ram_oe_n),
        .ext_ram_we_n(ext_ram_we_n),
        .ext_ram_be_n(ext_ram_be_n),
        .flash_d(flash_d),
        .flash_a(flash_a),
        .flash_rp_n(flash_rp_n),
        .flash_vpen(flash_vpen),
        .flash_oe_n(flash_oe_n),
        .flash_ce_n(flash_ce_n),
        .flash_byte_n(flash_byte_n),
        .flash_we_n(flash_we_n)
    );
    clock osc(
        .clk_11M0592(clk_11M0592),
        .clk_50M    (clk_50M)
    );
    sram_model base1(/*autoinst*/
        .DataIO(base_ram_data[15:0]),
        .Address(base_ram_addr[19:0]),
        .OE_n(base_ram_oe_n),
        .CE_n(base_ram_ce_n),
        .WE_n(base_ram_we_n),
        .LB_n(base_ram_be_n[0]),
        .UB_n(base_ram_be_n[1]));
    sram_model base2(/*autoinst*/
        .DataIO(base_ram_data[31:16]),
        .Address(base_ram_addr[19:0]),
        .OE_n(base_ram_oe_n),
        .CE_n(base_ram_ce_n),
        .WE_n(base_ram_we_n),
        .LB_n(base_ram_be_n[2]),
        .UB_n(base_ram_be_n[3]));
    sram_model ext1(/*autoinst*/
        .DataIO(ext_ram_data[15:0]),
        .Address(ext_ram_addr[19:0]),
        .OE_n(ext_ram_oe_n),
        .CE_n(ext_ram_ce_n),
        .WE_n(ext_ram_we_n),
        .LB_n(ext_ram_be_n[0]),
        .UB_n(ext_ram_be_n[1]));
    sram_model ext2(/*autoinst*/
        .DataIO(ext_ram_data[31:16]),
        .Address(ext_ram_addr[19:0]),
        .OE_n(ext_ram_oe_n),
        .CE_n(ext_ram_ce_n),
        .WE_n(ext_ram_we_n),
        .LB_n(ext_ram_be_n[2]),
        .UB_n(ext_ram_be_n[3]));
    x28fxxxp30 #(.FILENAME_MEM(FLASH_INIT_FILE)) flash(
        .A(flash_a[1+:22]), 
        .DQ(flash_d), 
        .W_N(flash_we_n),    // Write Enable 
        .G_N(flash_oe_n),    // Output Enable
        .E_N(flash_ce_n),    // Chip Enable
        .L_N(1'b0),    // Latch Enable
        .K(1'b0),      // Clock
        .WP_N(flash_vpen),   // Write Protect
        .RP_N(flash_rp_n),   // Reset/Power-Down
        .VDD('d3300), 
        .VDDQ('d3300), 
        .VPP('d1800), 
        .Info(1'b1));
    
    initial begin 
        wait(flash_byte_n == 1'b0);
        $display("8-bit Flash interface is not supported in simulation!");
        $display("Please tie flash_byte_n to high");
        $stop;
    end
    
    initial begin 
        reg [31:0] tmp_array[0:1048575];
        integer n_File_ID, n_Init_Size;
        n_File_ID = $fopen(BASE_RAM_INIT_FILE, "rb");
        if(!n_File_ID)begin 
            n_Init_Size = 0;
            $display("Failed to open BaseRAM init file");
        end else begin
            n_Init_Size = $fread(tmp_array, n_File_ID);
            n_Init_Size /= 4;
            $fclose(n_File_ID);
        end
        $display("BaseRAM Init Size(words): %d",n_Init_Size);
        for (integer i = 0; i < n_Init_Size; i++) begin
`ifdef REVERSE_ENDIAN
            tmp_array[i] = reverse_endian(tmp_array[i]);        
`endif
            base1.mem_array0[i] = tmp_array[i][24+:8];
            base1.mem_array1[i] = tmp_array[i][16+:8];
            base2.mem_array0[i] = tmp_array[i][8+:8];
            base2.mem_array1[i] = tmp_array[i][0+:8];
        end
    end
    
    initial begin 
        reg [31:0] tmp_array[0:1048575];
        integer n_File_ID, n_Init_Size;
`ifdef LOAD_PREAMBLE
        integer preamble_len;
`endif
        n_File_ID = $fopen(EXT_RAM_INIT_FILE, "rb");
        if(!n_File_ID)begin 
            n_Init_Size = 0;
            $display("Failed to open ExtRAM init file");
        end else begin
`ifdef LOAD_PREAMBLE
            preamble_len = 11;
            tmp_array[0] = 0;
            tmp_array[1] = 'h3c01803f;  // lui $1, 0x803f
            tmp_array[2] = 'hac2000ff;  // sw $0, 0xff($1) 
            tmp_array[3] = 'h8c2000ff;  // lw $0, 0xff($1)
            tmp_array[4] = 0;
            tmp_array[5] = 0;
            tmp_array[6] = 'h3c01807f;  // lui $1, 0x807f
            tmp_array[7] = 'hac2000ff;  // sw $0, 0xff($1)
            tmp_array[8] = 'h8c2000ff;  // lw $0, 0xff($1)
            tmp_array[9] = 0;
            tmp_array[10] = 0;
            n_Init_Size = $fread(tmp_array, n_File_ID, preamble_len) / 4 + preamble_len;
            $display("With preamble");
`else
            n_Init_Size = $fread(tmp_array, n_File_ID) / 4;
            $display("Without preamble");
`endif
            $fclose(n_File_ID);
        end
        
        $display("ExtRAM Init Size(words): %d",n_Init_Size);
        for (integer i = 0; i < n_Init_Size; i++) begin
`ifdef REVERSE_ENDIAN
            tmp_array[i] = reverse_endian(tmp_array[i]);        
`endif
            ext1.mem_array0[i] = tmp_array[i][24+:8];
            ext1.mem_array1[i] = tmp_array[i][16+:8];
            ext2.mem_array0[i] = tmp_array[i][8+:8];
            ext2.mem_array1[i] = tmp_array[i][0+:8];
        end
        
        for (integer i = 0; i != (n_Init_Size < 16 ? n_Init_Size : 16); ++i) begin
            $display ("ROM[%h]: %h", i, tmp_array[i]);    
        end
    end
    
    function automatic [31:0] reverse_endian(input [31:0] x);
    begin
        reverse_endian = {x[7:0], x[15:8], x[23:16], x[31:24]};
    end
    endfunction
    
endmodule
