//! @title Digilent Pmod I2S2 Transceiver
//! @file axis_i2s2.v (uses SV system calls)
//! @author JA (current), Arthur Brown (03/23/2018)
//! @version 0.02
//! @date 05/25/2021
//! @details
//! - Digilent I2S2 (Cirrus CS5343 ADC, CS4344 DAC) at 24-bit depth / 88.2 kHz sampling rate 
//! - The PCB jumper should be set to SLV (applies 10k pulldown to CS5343 SDOUT)
//! - Deserializes ADC I2S input, outputs L/R channel data at AXIS M port
//! - Serializes input at AXIS S port, outputs I2S stream to the DAC
//! - Drives ADC/DAC clocks for setting 256x MCLK/LRCLK ratio & 64x SCLK/LRCLK ratio:
//! - *_mclk = i_clk/1   = 22.591 MHz
//! - *_sclk = i_clk/4   =  5.640 MHz
//! - *_lrck = i_clk/256 = 88.200 kHz = fs (audio sampling rate)
//! - M AXIS: presents L/R channel data as a 2-word packet (left first) at the end of each I2S frame. Further packets will be dropped until current packet is consumed
//! - S AXIS: when a 2-word packet is valid on this port, it is transmitted in the next I2S frame
//! - Note: L/R words are 24-bit (left-aligned to 32-bit AXI), shifted one serial clock right from the LRCK boundaries.


`timescale 1ns / 1ps
`default_nettype none

module axis_i2s2 (

    // control
    input  wire         i_clk,
    input  wire         i_rst_n,

    // external I2S interface; receive data from ADC
    output wire         i2s_adc_mclk, // JA[4]
    output wire         i2s_adc_lrck, // JA[5]
    output wire         i2s_adc_sclk, // JA[6]
    input  wire         i2s_adc_din,  // JA[7]

    // external I2S interface; transmit data to DAC
    output wire         i2s_dac_mclk, // JA[0]
    output wire         i2s_dac_lrck, // JA[1]
    output wire         i2s_dac_sclk, // JA[2]
    output reg          i2s_dac_dout, // JA[3]

    // internal AXIS master interface; to vol ctrl
    output wire [31:0]  axis_m_data,
    output reg          axis_m_vld = 1'b0,
    input  wire         axis_m_rdy,
    output reg          axis_m_last = 1'b0,

    // internal AXIS slave interface; from vol ctrl
    input  wire [31:0]  axis_s_data,
    input  wire         axis_s_vld,
    output reg          axis_s_rdy = 1'b0,
    input  wire         axis_s_last

);

    localparam EOF_COUNT = 9'd455; // end of full I2S frame

    reg [8:0]  clk_count = 9'd0; // 9-bit up-counter
    
    reg [2:0]  sr_adc_din = 3'd0; // shift reg synchronizer for ADC serial input 
    wire       adc_din_sync;      // synchronized serial input

    reg [23:0] sr_adc_data_l = 24'b0; // shift reg for parallelizing input data from ADC; left channel
    reg [23:0] sr_adc_data_r = 24'b0; // shift reg for parallelizing input data from ADC; right channel

    reg [31:0] adc_data_l = 32'b0; // ADC data received; parallelized; left channel
    reg [31:0] adc_data_r = 32'b0; // ADC data received; parallelized; right channel

    reg [31:0] dac_data_l = 0; // DAC data to transmit; parallelized; left channel
    reg [31:0] dac_data_r = 0; // DAC data to transmit; parallelized; right channel

    reg [23:0] sr_dac_data_l = 24'b0; // shift reg for serializing output data to DAC; left channel
    reg [23:0] sr_dac_data_r = 24'b0; // shift reg for serializing output data to DAC; right channel


    //! free-running up-counter
    always@(posedge i_clk) begin : CLOCK_COUNTER
        clk_count <= clk_count + 1;
    end
    assign i2s_adc_mclk = i_clk; // wire system clock to mclk
    assign i2s_dac_mclk = i_clk; // wire system clock to mclk
    assign i2s_adc_sclk = clk_count[2]; // mclk divide-by-4
    assign i2s_dac_sclk = clk_count[2]; // mclk divide-by-4
    assign i2s_adc_lrck = clk_count[8]; // mclk divide-by-256
    assign i2s_dac_lrck = clk_count[8]; // mclk divide-by-256   


    //! ADC serial input synchronizer; shift register based 
    always@(posedge i_clk) begin : I2S_ADC_INPUT_SR_SYNC
        sr_adc_din <= {sr_adc_din[$high(sr_adc_din)-1:0], i2s_adc_din};
    end
    assign adc_din_sync = sr_adc_din[$high(sr_adc_din)];
        

    //! 
    always@(posedge i_clk) begin : I2S_ADC_INPUT_DESERIALIZE
        if (clk_count[2:0] == 3'b011 && clk_count[7:3] <= 5'd24 && clk_count[7:3] >= 5'd1)
            if (i2s_adc_lrck == 1'b1)
                sr_adc_data_r <= {sr_adc_data_r, adc_din_sync};
            else
                sr_adc_data_l <= {sr_adc_data_l, adc_din_sync};
    end


    always@(posedge i_clk) begin : M_AXIS_PUSH_DATA
        if (i_rst_n == 1'b0) begin
            adc_data_l <= 32'b0;
            adc_data_r <= 32'b0;
        end else if (clk_count == EOF_COUNT && axis_m_vld == 1'b0) begin
            adc_data_l <= {8'b0, sr_adc_data_l};
            adc_data_r <= {8'b0, sr_adc_data_r};
        end
    end


    always@(posedge i_clk) begin : M_AXIS_ASSIGN_CTRLS
        if (i_rst_n == 1'b0) begin    
            axis_m_last <= 1'b0;
            axis_m_vld <= 1'b0;
        end else if (clk_count == EOF_COUNT && axis_m_vld == 1'b0) begin
            axis_m_last <= 1'b0;
            axis_m_vld <= 1'b1;
        end else if (axis_m_vld == 1'b1 && axis_m_rdy == 1'b1) begin
            axis_m_last <= ~axis_m_last;
            if (axis_m_last == 1'b1)
                axis_m_vld <= 1'b0;
        end
    end


    always@(posedge i_clk) begin : S_AXIS_ASSIGN_CTRLS
        if (i_rst_n == 1'b0)
            axis_s_rdy <= 1'b0;

        // end of packet, cannot accept data until current one has been transmitted
        else if (axis_s_rdy == 1'b1 && axis_s_vld == 1'b1 && axis_s_last == 1'b1) 
            axis_s_rdy <= 1'b0;

        // beginning of I2S frame; in order to avoid tearing, cannot accept data until frame complete
        else if (clk_count == 9'b0) 
            axis_s_rdy <= 1'b0;

        // end of I2S frame, can accept data
        else if (clk_count == EOF_COUNT) 
            axis_s_rdy <= 1'b1;
    end


    always@(posedge i_clk) begin : S_AXIS_PULL_DATA
        if (i_rst_n == 1'b0) begin
            dac_data_r <= 32'b0;
            dac_data_l <= 32'b0;
        end else if (axis_s_vld == 1'b1 && axis_s_rdy == 1'b1)
            if (axis_s_last == 1'b1)
                dac_data_r <= axis_s_data;
            else
                dac_data_l <= axis_s_data;
    end


    always@(posedge i_clk) begin : I2S_DAC_OUTPUT_SHIFT_LEFT
        if (clk_count == 3'b000000111) begin
            sr_dac_data_l <= dac_data_l[23:0]; // init SR with AXIS left channel word
            sr_dac_data_r <= dac_data_r[23:0]; // init SR with AXIS right channel word
        end else if (clk_count[2:0] == 3'b111 && clk_count[7:3] >= 5'd1 && clk_count[7:3] <= 5'd24) begin
            if (i2s_dac_lrck == 1'b1)
                sr_dac_data_r <= {sr_dac_data_r[$high(sr_dac_data_r)-1:0], 1'b0};
            else
                sr_dac_data_l <= {sr_dac_data_l[$high(sr_dac_data_l)-1:0], 1'b0};
        end
    end
        

    always@(clk_count, sr_dac_data_l, sr_dac_data_r, i2s_dac_lrck) begin : I2S_DAC_OUTPUT_SERIALIZE
        if (clk_count[7:3] <= 5'd24 && clk_count[7:3] >= 4'd1)
            if (i2s_dac_lrck == 1'b1)
                i2s_dac_dout = sr_dac_data_r[$high(sr_dac_data_r)]; // shift out MSb first
            else
                i2s_dac_dout = sr_dac_data_l[$high(sr_dac_data_l)];
        else
            i2s_dac_dout = 1'b0;
    end

    assign axis_m_data = (axis_m_last == 1'b1) ? adc_data_r : adc_data_l; // if last =1, data out is right channel, else left

endmodule