`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc
// Engineer: Arthur Brown
// 
// Create Date: 03/23/2018 11:53:54 AM
// Design Name: Arty-A7-100-Pmod-I2S2
// Module Name: top
// Project Name: 
// Target Devices: Arty A7 100
// Tool Versions: Vivado 2017.4
// Description: Implements a volume control stream from Line In to Line Out of a Pmod I2S2 on port JA
// 
// Revision:
// Revision 0.01 - File Created
// 
//////////////////////////////////////////////////////////////////////////////////


module top #(
	parameter NUMBER_OF_SWITCHES = 4,
	parameter RESET_POLARITY = 0
) (
    // ctrl
    input wire                          i_clk,
    input wire [NUMBER_OF_SWITCHES-1:0] sw,
    input wire                          i_rst,
    
    // XADC analog inputs
    input wire [8:0] ck_an_p,
    input wire [8:0] ck_an_n,
    input wire vp_in,
    input wire vn_in,

    // ARTY 8x SMT LED vector
    output reg [7:0] LED, 

    // ADC wires
    output wire rx_mclk, // A/D MCLK
    output wire rx_lrck, // A/D LRCLK
    output wire rx_sclk, // A/D SCLK
    input  wire rx_data,  // A/D SDOUT
    
    // DAC wires
    output wire tx_mclk, // D/A MCLK
    output wire tx_lrck, // D/A LRCLK
    output wire tx_sclk, // D/A SCLK
    output wire tx_data  // D/A SDIN
    
);
    
    wire        sys_clk;
	  wire        w_rst_n = (i_rst == RESET_POLARITY) ? 1'b0 : 1'b1; // if reset input = polarity, set resetn=0, else set resetn=1

    // AXIS master data output from ADC
    wire [31:0] m_axis_adc_rx_tdata; // 24 LSbs are used
    wire        m_axis_adc_rx_tvalid;
    wire        m_axis_adc_rx_tready;
    wire        m_axis_adc_rx_tlast;

    // AXIS master data output from volume control module
    wire [23:0] m_axis_vol_tx_tdata; 
    wire        m_axis_vol_tx_tvalid;
    wire        m_axis_vol_tx_tready;
    wire        m_axis_vol_tx_tlast;

    // AXIS master data output from amplifier module
    wire [31:0] m_axis_amp_tx_tdata; // 24 LSbs are used
    wire        m_axis_amp_tx_tvalid;
    wire        m_axis_amp_tx_tready;
    wire        m_axis_amp_tx_tlast;
    
    // XADC DRP port
    wire [6:0]  drp_addr = 8'h14; // tie to A0
    wire        drp_addr_vld;  
    wire [15:0] drp_dout;   
    wire        drp_dout_vld;


    // generate AXIS clock; will drive ADC & DAC clocks 
    clk_wiz_0 inst_mmcm (
          .clk_in1(i_clk)    // 100 M PCB clock
        , .axis_clk(sys_clk) // 22.59 M
    );


    // I2S transceiver
    axis_i2s2 i_axis_i2s2 (
        // ctrl
          .i_clk(sys_clk)
        , .i_rst_n(w_rst_n)

        // I2S RX from ADC
        , .i2s_adc_mclk(rx_mclk)
        , .i2s_adc_lrck(rx_lrck)
        , .i2s_adc_sclk(rx_sclk)
        , .i2s_adc_din(rx_data)

        // I2S TX to DAC
        , .i2s_dac_mclk(tx_mclk)
        , .i2s_dac_lrck(tx_lrck)
        , .i2s_dac_sclk(tx_sclk)
        , .i2s_dac_dout(tx_data)

        // M AXIS output from ADC
        , .axis_m_data(m_axis_adc_rx_tdata)
        , .axis_m_vld(m_axis_adc_rx_tvalid)
        , .axis_m_rdy(m_axis_adc_rx_tready)
        , .axis_m_last(m_axis_adc_rx_tlast)

        // S AXIS input to ADC
        , .axis_s_data(m_axis_amp_tx_tdata)
        , .axis_s_vld(m_axis_amp_tx_tvalid)
        , .axis_s_rdy(m_axis_amp_tx_tready)
        , .axis_s_last(m_axis_amp_tx_tlast)
    );


    // XADC samples 'A0' pin at DRP address 0x14
    // eoc trig drives 'drp_addr_vld' for streaming updates 
    xadc_wiz_0 i_xadc_wiz_0 (
      // ctrl
        .reset_in(0)              // Reset signal for the System Monitor control logic    
      // DRP port output
      , .dclk_in  (i_clk)         // input;  clock driver
      , .daddr_in (drp_addr)      // input;  address input data
      , .den_in   (drp_addr_vld)  // input;  address input valid
      , .dwe_in   (0)             // input;  write enable; 0=read, 1=write
      , .di_in    (0)             // input;  data input for write transactions
      , .do_out   (drp_dout)      // output; data output for read transactions
      , .drdy_out (drp_dout_vld)  // output; data output valid
      
      // analog inputs
      , .vp_in(vp_in)             // Dedicated Analog Input Pair; full resolution bandwidth = 500kHz
      , .vn_in(vn_in)
      , .vauxp4 (ck_an_p[0])      // drp_addr <= 8'h14; // read from pin      A00 single ended; FRBW=250kHz; range 0-3V3;
      , .vauxn4 (ck_an_n[0])    
      , .vauxp5 (ck_an_p[1])      // drp_addr <= 8'h15; // read from pin      A01 single ended; FRBW=250kHz; range 0-3V3;
      , .vauxn5 (ck_an_n[1])    
      , .vauxp6 (ck_an_p[2])      // drp_addr <= 8'h16; // read from pin      A02 single ended; FRBW=250kHz; range 0-3V3;
      , .vauxn6 (ck_an_n[2])    
      , .vauxp7 (ck_an_p[3])      // drp_addr <= 8'h17; // read from pin      A03 single ended; FRBW=250kHz; range 0-3V3;
      , .vauxn7 (ck_an_n[3])    
      , .vauxp15(ck_an_p[4])      // drp_addr <= 8'h1F; // read from pin      A04 single ended; FRBW=250kHz; range 0-3V3;
      , .vauxn15(ck_an_n[4])    
      , .vauxp0 (ck_an_p[5])      // drp_addr <= 8'h10; // read from pin      A05 single ended; FRBW=250kHz; range 0-3V3;
      , .vauxn0 (ck_an_n[5])
      , .vauxp12(ck_an_p[6])      // drp_addr <= 8'h1C; // read from pins A06-A07 differential; FRBW=250kHz; range 0-1V; 
      , .vauxn12(ck_an_n[6]) 
      , .vauxp13(ck_an_p[7])      // drp_addr <= 8'h1D; // read from pins A08-A09 differential; FRBW=250kHz; range 0-1V; 
      , .vauxn13(ck_an_n[7]) 
      , .vauxp14(ck_an_p[8])      // drp_addr <= 8'h1E; // read from pins A10-A11 differential; FRBW=250kHz; range 0-1V; 
      , .vauxn14(ck_an_n[8])          
      
      // channel out
      , .channel_out()           // Channel Selection Outputs
      // status discretes
      , .busy_out()              // ADC Busy signal
      , .eos_out()               // End of Sequence Signal
      , .eoc_out(drp_addr_vld)   // End of Conversion Signal
      // alarm discretes
      , .alarm_out()             // OR'ed output of all the Alarms  
    );

    
  axis_volume_controller #(
		.SCALE_WIDTH($size(drp_dout)),
		.DATA_WIDTH(24)
  ) i_axis_volume_controller (
        // ctrl
          .ila_clk(i_clk)
        , .clk(sys_clk)
        , .i_scale(drp_dout)
        // AXIS slave; receive-side
        , .s_axis_data(m_axis_adc_rx_tdata[23:0])
        , .s_axis_valid(m_axis_adc_rx_tvalid)
        , .s_axis_ready(m_axis_adc_rx_tready)
        , .s_axis_last(m_axis_adc_rx_tlast)
        // AXIS master; transmit-side
        , .m_axis_data(m_axis_vol_tx_tdata)
        , .m_axis_valid(m_axis_vol_tx_tvalid)
        , .m_axis_ready(m_axis_vol_tx_tready)
        , .m_axis_last(m_axis_vol_tx_tlast)
  );


  axis_amplifier #(
    .DB_GAIN(6.0),
		.DATA_WIDTH(24)
  ) i_axis_amplifier (
        // ctrl
          .clk(sys_clk)
        , .ena(sw[0])
        // AXIS slave; receive-side
        , .s_axis_data(m_axis_vol_tx_tdata)
        , .s_axis_valid(m_axis_vol_tx_tvalid)
        , .s_axis_ready(m_axis_vol_tx_tready)
        , .s_axis_last(m_axis_vol_tx_tlast)
        // AXIS master; transmit-side
        , .m_axis_data(m_axis_amp_tx_tdata[23:0])
        , .m_axis_valid(m_axis_amp_tx_tvalid)
        , .m_axis_ready(m_axis_amp_tx_tready)
        , .m_axis_last(m_axis_amp_tx_tlast)
  );


  led_magnitude_driver #(
    .g_data_width(24)
  ) i_led_magnitude_driver (
          .ila_clk      (i_clk)
        , .clk          (sys_clk) // : in std_logic
        , .s_axis_data  (m_axis_amp_tx_tdata[23:0]) // : in std_logic_vector(g_data_width-1 downto 0)
        , .s_axis_valid (m_axis_amp_tx_tvalid) // : in std_logic
        , .s_axis_last  (m_axis_amp_tx_tlast) // : in std_logic
        , .o_led_l      (LED[3:0]) // : out std_logic_vector(3 downto 0)
        , .o_led_r      (LED[7:4]) // : out std_logic_vector(3 downto 0)
  );


/*
    ila_0 inst_chipscope (
          .clk(i_clk) // 100 M
        , .probe0(sys_clk) // 22.59 M
        , .probe1(m_axis_adc_rx_tdata[23:0]) // IN STD_LOGIC_VECTOR(23 DOWNTO 0);
        , .probe2(m_axis_adc_rx_tvalid) // IN STD_LOGIC
        , .probe3(m_axis_amp_tx_tdata[23:0]) // IN STD_LOGIC_VECTOR(23 DOWNTO 0);
        , .probe4(m_axis_amp_tx_tvalid) // IN STD_LOGIC
        , .probe5(drp_dout)      // IN STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
*/


endmodule