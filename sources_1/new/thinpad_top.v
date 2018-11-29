`default_nettype none
`timescale 1ns / 1ps
`include "defines.vh"

module thinpad_top 
    #(parameter clk_opt = `USE_CLOCK_11M0592) 
(
    input wire clk_50M,           //50MHz ʱ������
    input wire clk_11M0592,       //11.0592MHz ʱ������

    input wire clock_btn,         //BTN5�ֶ�ʱ�Ӱ�ť���أ���������·������ʱΪ1
    input wire reset_btn,         //BTN6�ֶ���λ��ť���أ���������·������ʱΪ1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4����ť���أ�����ʱΪ1
    input  wire[31:0] dip_sw,     //32λ���뿪�أ�������ON��ʱΪ1
    output wire[15:0] leds,       //16λLED�����ʱ1����
    output wire[7:0]  dpy0,       //����ܵ�λ�źţ�����С���㣬���1����
    output wire[7:0]  dpy1,       //����ܸ�λ�źţ�����С���㣬���1����

    //CPLD���ڿ������ź�
    output wire uart_rdn,         //�������źţ�����Ч
    output wire uart_wrn,         //д�����źţ�����Ч
    input wire uart_dataready,    //��������׼����
    input wire uart_tbre,         //�������ݱ�־
    input wire uart_tsre,         //���ݷ�����ϱ�־

    //BaseRAM�ź�
    inout wire[31:0] base_ram_data,  //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    output wire[19:0] base_ram_addr, //BaseRAM��ַ
    output wire[3:0] base_ram_be_n,  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire base_ram_ce_n,       //BaseRAMƬѡ������Ч
    output wire base_ram_oe_n,       //BaseRAM��ʹ�ܣ�����Ч
    output wire base_ram_we_n,       //BaseRAMдʹ�ܣ�����Ч

    //ExtRAM�ź�
    inout wire[31:0] ext_ram_data,  //ExtRAM����
    output wire[19:0] ext_ram_addr, //ExtRAM��ַ
    output wire[3:0] ext_ram_be_n,  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire ext_ram_ce_n,       //ExtRAMƬѡ������Ч
    output wire ext_ram_oe_n,       //ExtRAM��ʹ�ܣ�����Ч
    output wire ext_ram_we_n,       //ExtRAMдʹ�ܣ�����Ч

    //ֱ�������ź�
    output wire txd,  //ֱ�����ڷ��Ͷ�
    input  wire rxd,  //ֱ�����ڽ��ն�

    //Flash�洢���źţ��ο� JS28F640 оƬ�ֲ�
    output wire [22:0]flash_a,      //Flash��ַ��a0����8bitģʽ��Ч��16bitģʽ������
    inout  wire [15:0]flash_d,      //Flash����
    output wire flash_rp_n,         //Flash��λ�źţ�����Ч
    output wire flash_vpen,         //Flashд�����źţ��͵�ƽʱ���ܲ�������д
    output wire flash_ce_n,         //FlashƬѡ�źţ�����Ч
    output wire flash_oe_n,         //Flash��ʹ���źţ�����Ч
    output wire flash_we_n,         //Flashдʹ���źţ�����Ч
    output wire flash_byte_n,       //Flash 8bitģʽѡ�񣬵���Ч����ʹ��flash��16λģʽʱ����Ϊ1

    //USB �������źţ��ο� SL811 оƬ�ֲ�
    output wire sl811_a0,
    //inout  wire[7:0] sl811_d,     //USB�������������������dm9k_sd[7:0]����
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    //����������źţ��ο� DM9000A оƬ�ֲ�
    output wire dm9k_cmd,
    inout  wire[15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input  wire dm9k_int,

    //ͼ������ź�
    output wire[2:0] video_red,    //��ɫ���أ�3λ
    output wire[2:0] video_green,  //��ɫ���أ�3λ
    output wire[1:0] video_blue,   //��ɫ���أ�2λ
    output wire video_hsync,       //��ͬ����ˮƽͬ�����ź�
    output wire video_vsync,       //��ͬ������ֱͬ�����ź�
    output wire video_clk,         //����ʱ�����
    output wire video_de           //��������Ч�źţ���������������
);

    /* =========== Demo code begin =========== */
    
    //// PLL��Ƶʾ��
    //wire locked, clk_10M, clk_20M;
    //pll_example clock_gen 
    // (
    //  // Clock out ports
    //  .clk_out1(clk_10M), // ʱ�����1��Ƶ����IP���ý���������
    //  .clk_out2(clk_20M), // ʱ�����2��Ƶ����IP���ý���������
    //  // Status and control signals
    //  .reset(reset_btn), // PLL��λ����
    //  .locked(locked), // ���������"1"��ʾʱ���ȶ�������Ϊ�󼶵�·��λ
    // // Clock in ports
    //  .clk_in1(clk_50M) // �ⲿʱ������
    // );
    
    //reg reset_of_clk10M;
    //// �첽��λ��ͬ���ͷ�
    //always@(posedge clk_10M or negedge locked) begin
    //    if(~locked) reset_of_clk10M <= 1'b1;
    //    else        reset_of_clk10M <= 1'b0;
    //end
    
    //always@(posedge clk_10M or posedge reset_of_clk10M) begin
    //    if(reset_of_clk10M)begin
    //        // Your Code
    //    end
    //    else begin
    //        // Your Code
    //    end
    //end
    
    // ��������ӹ�ϵʾ��ͼ��dpy1ͬ��
    // p=dpy0[0] // ---a---
    // c=dpy0[1] // |     |
    // d=dpy0[2] // f     b
    // e=dpy0[3] // |     |
    // b=dpy0[4] // ---g---
    // a=dpy0[5] // |     |
    // f=dpy0[6] // e     c
    // g=dpy0[7] // |     |
    //           // ---d---  p
     
//    //ֱ�����ڽ��շ�����ʾ����ֱ�������յ��������ٷ��ͳ�ȥ
//    wire [7:0] ext_uart_rx;
//    reg  [7:0] ext_uart_buffer, ext_uart_tx;
//    wire ext_uart_ready, ext_uart_busy;
//    reg ext_uart_start, ext_uart_avai;
    
//    async_receiver #(.ClkFrequency(50000000),.Baud(9600)) //����ģ�飬9600�޼���λ
//        ext_uart_r(
//            .clk(clk_50M),                       //�ⲿʱ���ź�
//            .RxD(rxd),                           //�ⲿ�����ź�����
//            .RxD_data_ready(ext_uart_ready),  //���ݽ��յ���־
//            .RxD_clear(ext_uart_ready),       //������ձ�־
//            .RxD_data(ext_uart_rx)             //���յ���һ�ֽ�����
//        );
        
//    always @(posedge clk_50M) begin //���յ�������ext_uart_buffer
//        if(ext_uart_ready)begin
//            ext_uart_buffer <= ext_uart_rx;
//            ext_uart_avai <= 1;
//        end else if(!ext_uart_busy && ext_uart_avai)begin 
//            ext_uart_avai <= 0;
//        end
//    end
//    always @(posedge clk_50M) begin //��������ext_uart_buffer���ͳ�ȥ
//        if(!ext_uart_busy && ext_uart_avai)begin 
//            ext_uart_tx <= ext_uart_buffer;
//            ext_uart_start <= 1;
//        end else begin 
//            ext_uart_start <= 0;
//        end
//    end
    
//    async_transmitter #(.ClkFrequency(50000000),.Baud(9600)) //����ģ�飬9600�޼���λ
//        ext_uart_t(
//            .clk(clk_50M),                  //�ⲿʱ���ź�
//            .TxD(txd),                      //�����ź����
//            .TxD_busy(ext_uart_busy),       //������æ״ָ̬ʾ
//            .TxD_start(ext_uart_start),    //��ʼ�����ź�
//            .TxD_data(ext_uart_tx)        //�����͵�����
//        );
    
    //ͼ�������ʾ���ֱ���800x600@75Hz������ʱ��Ϊ50MHz
    wire [11:0] hdata;
    assign video_red = hdata < 266 ? 3'b111 : 0; //��ɫ����
    assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //��ɫ����
    assign video_blue = hdata >= 532 ? 2'b11 : 0; //��ɫ����
    assign video_clk = clk_50M;
    vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
        .clk(clk_50M), 
        .hdata(hdata), //������
        .vdata(),      //������
        .hsync(video_hsync),
        .vsync(video_vsync),
        .data_enable(video_de)
    );
    
    /* =========== Demo code end =========== */
    
    wire rst = reset_btn;
//    wire clk = clock_btn;
    
    reg clk_25M = 0;
    always @(posedge clk_50M)
        clk_25M = !clk_25M;    
    reg clk;
    always @(*) begin
        case (clk_opt)
        `USE_CLOCK_50M:     clk <= clk_50M;
        `USE_CLOCK_25M:     clk <= clk_25M;
        `USE_CLOCK_11M0592: clk <= clk_11M0592;
        `USE_CLOCK_BTN:     clk <= clock_btn;
        default:            clk <= clock_btn;
        endcase    
    end
    
    // Instruction memory
    wire[`InstAddrBus] inst_addr;
    wire rom_ce;
    wire rom_we;
    wire[`InstBus] rom_wr_data;
    wire[`InstBus] inst;
    wire[3:0] rom_sel;
    
    // Data memory
    wire mem_we_i;
    wire[`RegBus] mem_addr_i;
    wire[`RegBus] mem_data_i;
    wire[`RegBus] mem_data_o;
    wire[3:0] mem_sel_i; 
    wire mem_ce_i;  
    
    // Interrupt 
    wire timer_int;
    wire[5:0] interrupt = {5'b00000, timer_int};
//    wire[5:0] interrupt = {5'b00000, timer_int, gpio_int, uart_int};

    RAMWrapper rom_wrapper(
       .clk(clk),
       .addr_i(inst_addr),
       .ce_i(rom_ce),
       .we_i(rom_we),
       .data_i(rom_wr_data),
       .sel_i(rom_sel),    
       .data_o(inst),
       
       .ram_data(ext_ram_data),
       .ram_addr(ext_ram_addr),
       .ram_be_n(ext_ram_be_n),
       .ram_ce_n(ext_ram_ce_n),
       .ram_oe_n(ext_ram_oe_n),
       .ram_we_n(ext_ram_we_n)
    );

    RAMWrapper ram_wrapper(
        .clk(clk),
        .addr_i(mem_addr_i),
        .ce_i(mem_ce_i),
        .we_i(mem_we_i),
        .data_i(mem_data_i),
        .sel_i(mem_sel_i),   
        .data_o(mem_data_o),
        
        .ram_data(base_ram_data),
        .ram_addr(base_ram_addr),
        .ram_be_n(base_ram_be_n),
        .ram_ce_n(base_ram_ce_n),
        .ram_oe_n(base_ram_oe_n),
        .ram_we_n(base_ram_we_n),
        
        .tbre(uart_tbre),
        .tsre(uart_tsre),
        .data_ready(uart_dataready),
        .rdn(uart_rdn),
        .wrn(uart_wrn)
    );
    
    THCOMIPS32e cpu(
        .clk(clk),
        .rst(rst),
        
        .rom_addr_o(inst_addr),
        .rom_ce_o(rom_ce),
        .rom_we_o(rom_we),
        .rom_data_o(rom_wr_data),
        .rom_sel_o(rom_sel),
        .rom_data_i(inst),
        
        .ram_we_o(mem_we_i),
        .ram_addr_o(mem_addr_i),
        .ram_sel_o(mem_sel_i),
        .ram_data_o(mem_data_i),
        .ram_data_i(mem_data_o),
        .ram_ce_o(mem_ce_i),
        
        .int_i(interrupt),
        .timer_int_o(timer_int)			
    );
    
    SEG7_LUT hi_seg(dpy1, cpu.pc[7:4]),
            lo_seg(dpy0, cpu.pc[3:0]);
    
//    assign leds = {uart_dataready, uart_tbre, uart_tsre, cpu.pc[12:0]}; 
    assign leds = {
        uart_dataready, uart_tbre, uart_tsre,
        ram_wrapper.read_flag_prep, ram_wrapper.read_uart_prep, ram_wrapper.write_uart_prep,
        cpu.pc[9:0]
    };

endmodule
