//! @title AXIS Amplifier
//! @file axis_amplifier.sv
//! @author JA 
//! @version 0.01
//! @date 05/27/2021
//! @details
//! - Accepts a gain value (dB) parameter for boosting magnitude of audio samples
//! - Uses an enable switch to toggle between 'dry' vs 'wet' output
//! - S AXIS: raw audio samples are input at this port and fed to the multiplicand net (A) of a DSP48E1
//! - M AXIS: dry or wet audio samples are ouput at this port 3 cycles after a valid S AXIS input
//! - Note: 'm_axis_valid' does not follow IHI 0051A specification 2.2.1 ("Once TVALID is asserted it must remain asserted until the handshake occurs"). If the downstream S AXIS interface is not ready, the output sample will be dropped.


`timescale 1ns / 1ps
`default_nettype none


module axis_amplifier #(
    parameter real               DB_GAIN = 3.0,
    parameter                    DATA_WIDTH = 24
) (
    //! ctrl
    input wire                   clk,
    input wire                   ena,
    
    //! AXIS slave input
    input wire [DATA_WIDTH-1:0]  s_axis_data,
    input wire                   s_axis_valid,
    output wire                  s_axis_ready,
    input wire                   s_axis_last,
    
    //! AXIS master output
    output wire [DATA_WIDTH-1:0] m_axis_data,
    output wire                  m_axis_valid,
    input wire                   m_axis_ready,
    output wire                  m_axis_last
);


    //! DSP48E1 multiplicand size
    localparam               c_a_width = $size(s_axis_data); 
    //! DSP48E1 multiplier size
    localparam               c_b_width = 18; 
    //! DSP48E1 product size
    localparam               c_p_width = c_a_width+c_b_width; 
    //! DSP48E1 product vector
    logic [c_p_width-1:0]    r_product; 
    //! DSP48E1 multiplier latency
    localparam               c_latency = 3;  
    //! shift reg for s_axis_valid
    logic  [c_latency-1:0]   sr_timing;      
    //! shift reg synchronizer for amp enable control
    logic  [          1:0]   sr_enable;      
    //! wire for wet sample (amplified product)
    logic  [DATA_WIDTH-1:0]  wet_sample; 
    //! shift array for dry data
    logic  [DATA_WIDTH-1:0]  sr_dry [c_latency-1:0] ; //! DxW = 3x24        


    //! 3dB=1.41V/V; 6dB=1.99V/V;  (sengpielaudio.com/calculator-gainloss.htm)
  	const real                  c_volt_gain = 10.0**(DB_GAIN/20.0); 
  	//! 1 sign bit, 17 magnitude bits
  	localparam                  c_shift_size = 16;
    //! left-shift the multiplier by 'c_shift_size'; result is truncated to int and stored to logic vector
    const logic [c_b_width-1:0] c_multiplier =  c_volt_gain * 2**c_shift_size; 


    //! shift register for S AXIS valid input, synchronizer for enable control
    always_ff @ (posedge clk) begin : SHREGS
        sr_timing <= { sr_timing[$high(sr_timing)-1:0], s_axis_valid }; 
        sr_enable <= { sr_enable[$high(sr_enable)-1:0], ena }; 
        sr_dry <= { sr_dry[$high(sr_dry)-1:0], s_axis_data };         
    end


    //! multiply audio sample by scale factor
    MULT_MACRO #(
         .DEVICE("7SERIES")  //! Target Device: "7SERIES" 
       , .LATENCY(c_latency) //! Desired clock cycle latency, 0-4
       , .WIDTH_A(c_a_width) //! Multiplier A-input bus width, 1-25
       , .WIDTH_B(c_b_width) //! Multiplier B-input bus width, 1-18
    ) inst_mult (
         .CLK(clk)        //! 1-bit positive edge clock input
       , .CE(1'b1)        //! 1-bit active high input clock enable
       , .RST(1'b0)       //! 1-bit input active high reset     
       , .A(s_axis_data)  //! Multiplier input A bus, size = WIDTH_A parameter
       , .B(c_multiplier) //! Multiplier input B bus, size = WIDTH_B parameter
       , .P(r_product)    //! Multiplier output bus
    );


    //! take 24-bit slice at a right offset, in order to right-shift the product by 'c_shift_size'
    assign wet_sample = r_product[c_shift_size+DATA_WIDTH-1:c_shift_size];
    //! is enable control high ? if so, output the wet sample : if not, output the dry sample
    assign m_axis_data  = (sr_enable[$high(sr_enable)] == 1'b1) ? wet_sample : sr_dry[$high(sr_dry)]; 
    //! shift reg asserts 'm_axis_valid' at 'c_latency' cycles after 's_axis_valid'
    assign m_axis_valid = sr_timing[$high(sr_timing)];     
    //! assert 'm_axis_last' if 'm_axis_valid' is currently high, but will be pulled low on next cycle
    assign m_axis_last = (m_axis_valid == 1'b1 && sr_timing[$high(sr_timing)-1] == 1'b0) ? 1'b1 : 1'b0; 
    //! always ready; fully pipelined
    assign s_axis_ready = 1'b1; 


endmodule