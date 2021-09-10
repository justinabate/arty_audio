//! @title AXIS Volume Controller
//! @file axis_volume_controller.v (file has system calls, use SV compiler)
//! @author JA (current), Arthur Brown (03/23/2018)
//! @version 0.02
//! @date 05/27/2021
//! @details
//! - Accepts an input scale word to control volume of an audio stream
//! - Tested with Digilent Pmod I2S2 Transceiver (axis_i2s2.v)
//! - Tested with scale word input from samples of ARTY XADC 
//! - Scale word is translated to an 18-bit scale factor
//! - Scale factor is fed to the multiplier net (B) of a DSP48E1
//! - S AXIS: raw audio samples are input at this port and fed to the multiplicand net (A) of a DSP48E1
//! - M AXIS: scaled audio samples are ouput at this port 3 cycles after a valid S AXIS input
//! - Note: 'm_axis_valid' does not follow IHI 0051A specification 2.2.1 ("Once TVALID is asserted it must remain asserted until the handshake occurs"). If the downstream S AXIS interface is not ready, the scaled sample will be dropped.


`timescale 1ns / 1ps
`default_nettype none


module axis_volume_controller #(
    parameter                    SCALE_WIDTH = 16,
    parameter                    DATA_WIDTH = 24
) (
    //! ctrl
    input wire                   ila_clk,
    input wire                   clk,
    input wire [SCALE_WIDTH-1:0] i_scale, //! scale word
    
    //! AXIS SLAVE INTERFACE
    input wire [DATA_WIDTH-1:0]  s_axis_data,
    input wire                   s_axis_valid,
    output wire                  s_axis_ready,
    input wire                   s_axis_last,
    
    //! AXIS MASTER INTERFACE
    output wire [DATA_WIDTH-1:0] m_axis_data,
    output wire                  m_axis_valid,
    input wire                   m_axis_ready,
    output wire                  m_axis_last
);


    //! DSP48E1 multiplier
    localparam               c_port_a_width = 24; //! multiplicand
    localparam               c_port_b_width = 18; //! multiplier
    localparam               c_result_width = c_port_a_width+c_port_b_width; //! product
    reg [c_result_width-1:0] r_audio_scaled; //! 41 downto 0
    localparam               c_latency = 3;  //! 3 cycle multiplier latency
    reg  [c_latency-1:0]     sr_timing;      //! shift reg for s_axis_valid


    //! synchronizer array for input scale word; 3xSCALE_WIDTH
    reg  [SCALE_WIDTH-1:0]                 sr_scale [2:0]; 
    //! full-scale value of input scalar word
    localparam                             c_full_scale_input = {SCALE_WIDTH{1'b1}}; 
    //! integer part of scale factor; 1 bit wide
    localparam                             c_sf_i_width = 1; 
    //! fractional part of scale factor; 17 bits wide
    localparam                             c_sf_f_width = 17; 
    //! 18-bit scaling factor multiplier; range 0x0_0000 - 0x2_0000
    reg [c_sf_i_width+c_sf_f_width-1:0]    r_scale_factor;  


    always @ (posedge clk) begin : SET_SCALE_AND_UPDATE_SR
        
        //! shift array for input scalar   
        sr_scale       <= { sr_scale[$high(sr_scale)-1:0], i_scale };  

        //! set SF; left-shift synchronized scalar word by 'c_sf_f_width', then divide-by-full-scale; 
        r_scale_factor <= { sr_scale[$high(sr_scale)], {c_sf_f_width{1'b0}} } / c_full_scale_input;

        //! S AXIS input valid shift register
        sr_timing <= { sr_timing[$high(sr_timing)-1:0], s_axis_valid }; 

    end


    //! multiply audio sample by scale factor
    MULT_MACRO #(
         .DEVICE("7SERIES")   //! Target Device: "7SERIES" 
       , .LATENCY(c_latency)            //! Desired clock cycle latency, 0-4
       , .WIDTH_A(c_port_a_width) //! Multiplier A-input bus width, 1-25
       , .WIDTH_B(c_port_b_width)   //! Multiplier B-input bus width, 1-18
    ) inst_mult (
         .CLK(clk)            //! 1-bit positive edge clock input
       , .CE(1'b1)            //! 1-bit active high input clock enable
       , .RST(1'b0)           //! 1-bit input active high reset     
       , .A(s_axis_data)      //! Multiplier input A bus, size = WIDTH_A parameter
       , .B(r_scale_factor)   //! Multiplier input B bus, size = WIDTH_B parameter
       , .P(r_audio_scaled)   //! Multiplier output bus
    );


    //! always ready; fully pipelined
    assign s_axis_ready = 1'b1; 
    //! right-shift product by taking top 24-bit slice; 42 downto 19;
    assign m_axis_data  = r_audio_scaled[$high(r_audio_scaled):$high(r_audio_scaled)-DATA_WIDTH+1]; 
    //! shift reg asserts 'm_axis_valid' at 'c_latency' cycles after 's_axis_valid'
    assign m_axis_valid = sr_timing[$high(sr_timing)];     
    //! assert 'm_axis_last' if 'm_axis_valid' is currently high, but will be pulled low on next cycle
    assign m_axis_last = (m_axis_valid == 1'b1 && sr_timing[$high(sr_timing)-1] == 1'b0) ? 1'b1 : 1'b0; 

/*
    ila_1 inst_ila (
          .clk      (ila_clk)          // : IN STD_LOGIC;
    
        , .probe0   (clk)              // : IN STD_LOGIC_VECTOR(0  DOWNTO 0);  1
        , .probe1   (i_scale)          // : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 16
    
        , .probe2   (s_axis_data)      // : IN STD_LOGIC_VECTOR(23 DOWNTO 0); 24
        , .probe3   (s_axis_valid)     // : IN STD_LOGIC_VECTOR(0  DOWNTO 0);  1
        , .probe4   (s_axis_ready)     // : IN STD_LOGIC_VECTOR(0  DOWNTO 0);  1
        , .probe5   (s_axis_last)      // : IN STD_LOGIC_VECTOR(0  DOWNTO 0);  1
    
        , .probe6   (m_axis_data)      // : IN STD_LOGIC_VECTOR(23 DOWNTO 0); 24
        , .probe7   (m_axis_valid)     // : IN STD_LOGIC_VECTOR(0  DOWNTO 0);  1
        , .probe8   (m_axis_ready)     // : IN STD_LOGIC_VECTOR(0  DOWNTO 0);  1
        , .probe9   (m_axis_last)      // : IN STD_LOGIC_VECTOR(0  DOWNTO 0);  1
  
        , .probe10  ({1'b0, s_axis_data}) // : IN STD_LOGIC_VECTOR(24 DOWNTO 0); 25
        , .probe11  (r_scale_factor)   // : IN STD_LOGIC_VECTOR(17 DOWNTO 0); 18
        , .probe12  ({1'b0, r_audio_scaled})   // : IN STD_LOGIC_VECTOR(42 DOWNTO 0); 43

    );
*/

endmodule