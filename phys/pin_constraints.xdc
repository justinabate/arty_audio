##  https://reference.digilentinc.com/reference/programmable-logic/arty/start

# Clock signal
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { i_clk }]; #IO_L12P_T1_MRCC_35 Sch=gclk[100]; 100 MHz
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { i_clk }];

## Misc. ChipKit Ports
#set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports { ck_ioa }]; #IO_L10N_T1_D15_14 Sch=ck_ioa
set_property -dict { PACKAGE_PIN C2    IOSTANDARD LVCMOS33 } [get_ports { i_rst }]; #IO_L16P_T2_35 Sch=ck_rst


# Switches
set_property -dict { PACKAGE_PIN A8    IOSTANDARD LVCMOS33 } [get_ports { sw[0] }]; #IO_L12N_T1_MRCC_16 Sch=sw[0]
set_property -dict { PACKAGE_PIN C11   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }]; #IO_L13P_T2_MRCC_16 Sch=sw[1]
set_property -dict { PACKAGE_PIN C10   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }]; #IO_L13N_T2_MRCC_16 Sch=sw[2]
set_property -dict { PACKAGE_PIN A10   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }]; #IO_L14P_T2_SRCC_16 Sch=sw[3]


# Pmod Header JA - I2S2
# set_property -dict { PACKAGE_PIN G13   IOSTANDARD LVCMOS33 } [get_ports { tx_mclk }]; #IO_0_15 Sch=ja[1]
# set_property -dict { PACKAGE_PIN B11   IOSTANDARD LVCMOS33 } [get_ports { tx_lrck }]; #IO_L4P_T0_15 Sch=ja[2]
# set_property -dict { PACKAGE_PIN A11   IOSTANDARD LVCMOS33 } [get_ports { tx_sclk }]; #IO_L4N_T0_15 Sch=ja[3]
# set_property -dict { PACKAGE_PIN D12   IOSTANDARD LVCMOS33 } [get_ports { tx_data }]; #IO_L6P_T0_15 Sch=ja[4]
# set_property -dict { PACKAGE_PIN D13   IOSTANDARD LVCMOS33 } [get_ports { rx_mclk }]; #IO_L6N_T0_VREF_15 Sch=ja[7]
# set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS33 } [get_ports { rx_lrck }]; #IO_L10P_T1_AD11P_15 Sch=ja[8]
# set_property -dict { PACKAGE_PIN A18   IOSTANDARD LVCMOS33 } [get_ports { rx_sclk }]; #IO_L10N_T1_AD11N_15 Sch=ja[9]
# set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports { rx_data }]; #IO_25_15 Sch=ja[10]

##Pmod Header JD
set_property -dict { PACKAGE_PIN D4    IOSTANDARD LVCMOS33 } [get_ports { tx_mclk }]; #IO_L11N_T1_SRCC_35 Sch=jd[1]
set_property -dict { PACKAGE_PIN D3    IOSTANDARD LVCMOS33 } [get_ports { tx_lrck }]; #IO_L12N_T1_MRCC_35 Sch=jd[2]
set_property -dict { PACKAGE_PIN F4    IOSTANDARD LVCMOS33 } [get_ports { tx_sclk }]; #IO_L13P_T2_MRCC_35 Sch=jd[3]
set_property -dict { PACKAGE_PIN F3    IOSTANDARD LVCMOS33 } [get_ports { tx_data }]; #IO_L13N_T2_MRCC_35 Sch=jd[4]
set_property -dict { PACKAGE_PIN E2    IOSTANDARD LVCMOS33 } [get_ports { rx_mclk }]; #IO_L14P_T2_SRCC_35 Sch=jd[7]
set_property -dict { PACKAGE_PIN D2    IOSTANDARD LVCMOS33 } [get_ports { rx_lrck }]; #IO_L14N_T2_SRCC_35 Sch=jd[8]
set_property -dict { PACKAGE_PIN H2    IOSTANDARD LVCMOS33 } [get_ports { rx_sclk }]; #IO_L15P_T2_DQS_35 Sch=jd[9]
set_property -dict { PACKAGE_PIN G2    IOSTANDARD LVCMOS33 } [get_ports { rx_data }]; #IO_L15N_T2_DQS_35 Sch=jd[10]


## LEDs
set_property -dict { PACKAGE_PIN F6    IOSTANDARD LVCMOS33 } [get_ports { LED[0] }]; #IO_L19N_T3_VREF_35    Sch=led0_g
set_property -dict { PACKAGE_PIN J4    IOSTANDARD LVCMOS33 } [get_ports { LED[1] }]; #IO_L21P_T3_DQS_35     Sch=led1_g
set_property -dict { PACKAGE_PIN J2    IOSTANDARD LVCMOS33 } [get_ports { LED[2] }]; #IO_L22N_T3_35         Sch=led2_g
set_property -dict { PACKAGE_PIN H6    IOSTANDARD LVCMOS33 } [get_ports { LED[3] }]; #IO_L24P_T3_35         Sch=led3_g
set_property -dict { PACKAGE_PIN H5    IOSTANDARD LVCMOS33 } [get_ports { LED[4] }]; #IO_L24N_T3_35         Sch=led[4]
set_property -dict { PACKAGE_PIN J5    IOSTANDARD LVCMOS33 } [get_ports { LED[5] }]; #IO_25_35              Sch=led[5]
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports { LED[6] }]; #IO_L24P_T3_A01_D17_14 Sch=led[6]
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { LED[7] }]; #IO_L24N_T3_A00_D16_14 Sch=led[7]


##ChipKit Signals

#ChipKit Single Ended Analog Inputs
#The ck_an_p pins can be used as single ended analog inputs with voltages from 0-3.3V (Chipkit Analog pins A0-A5). These signals
#should only be connected to the XADC core. When using these pins as digital I/O, use pins ck_io[14-19].

set_property -dict { PACKAGE_PIN C5    IOSTANDARD LVCMOS33 } [get_ports { ck_an_n[0] }]; #IO_L1N_T0_AD4N_35 Sch=ck_an_n[0]
set_property -dict { PACKAGE_PIN C6    IOSTANDARD LVCMOS33 } [get_ports { ck_an_p[0] }]; #IO_L1P_T0_AD4P_35 Sch=ck_an_p[0]
set_property -dict { PACKAGE_PIN A5    IOSTANDARD LVCMOS33 } [get_ports { ck_an_n[1] }]; #IO_L3N_T0_DQS_AD5N_35 Sch=ck_an_n[1]
set_property -dict { PACKAGE_PIN A6    IOSTANDARD LVCMOS33 } [get_ports { ck_an_p[1] }]; #IO_L3P_T0_DQS_AD5P_35 Sch=ck_an_p[1]
set_property -dict { PACKAGE_PIN B4    IOSTANDARD LVCMOS33 } [get_ports { ck_an_n[2] }]; #IO_L7N_T1_AD6N_35 Sch=ck_an_n[2]
set_property -dict { PACKAGE_PIN C4    IOSTANDARD LVCMOS33 } [get_ports { ck_an_p[2] }]; #IO_L7P_T1_AD6P_35 Sch=ck_an_p[2]
set_property -dict { PACKAGE_PIN A1    IOSTANDARD LVCMOS33 } [get_ports { ck_an_n[3] }]; #IO_L9N_T1_DQS_AD7N_35 Sch=ck_an_n[3]
set_property -dict { PACKAGE_PIN B1    IOSTANDARD LVCMOS33 } [get_ports { ck_an_p[3] }]; #IO_L9P_T1_DQS_AD7P_35 Sch=ck_an_p[3]
set_property -dict { PACKAGE_PIN B2    IOSTANDARD LVCMOS33 } [get_ports { ck_an_n[4] }]; #IO_L10N_T1_AD15N_35 Sch=ck_an_n[4]
set_property -dict { PACKAGE_PIN B3    IOSTANDARD LVCMOS33 } [get_ports { ck_an_p[4] }]; #IO_L10P_T1_AD15P_35 Sch=ck_an_p[4]
set_property -dict { PACKAGE_PIN C14   IOSTANDARD LVCMOS33 } [get_ports { ck_an_n[5] }]; #IO_L1N_T0_AD0N_15 Sch=ck_an_n[5]
set_property -dict { PACKAGE_PIN D14   IOSTANDARD LVCMOS33 } [get_ports { ck_an_p[5] }]; #IO_L1P_T0_AD0P_15 Sch=ck_an_p[5]

#ChipKit Digital I/O On Inner Analog Header
#Note: These pins will need to be connected to the XADC core when used as differential analog inputs (Chipkit analog pins A6-A11)

set_property -dict { PACKAGE_PIN B7    IOSTANDARD LVCMOS33 } [get_ports { ck_an_p[6] }]; #IO_L2P_T0_AD12P_35 Sch=ad_p[12]
set_property -dict { PACKAGE_PIN B6    IOSTANDARD LVCMOS33 } [get_ports { ck_an_n[6] }]; #IO_L2N_T0_AD12N_35 Sch=ad_n[12]
set_property -dict { PACKAGE_PIN E6    IOSTANDARD LVCMOS33 } [get_ports { ck_an_p[7] }]; #IO_L5P_T0_AD13P_35 Sch=ad_p[13]
set_property -dict { PACKAGE_PIN E5    IOSTANDARD LVCMOS33 } [get_ports { ck_an_n[7] }]; #IO_L5N_T0_AD13N_35 Sch=ad_n[13]
set_property -dict { PACKAGE_PIN A4    IOSTANDARD LVCMOS33 } [get_ports { ck_an_p[8] }]; #IO_L8P_T1_AD14P_35 Sch=ad_p[14]
set_property -dict { PACKAGE_PIN A3    IOSTANDARD LVCMOS33 } [get_ports { ck_an_n[8] }]; #IO_L8N_T1_AD14N_35 Sch=ad_n[14]