# arty_audio
ARTY Rev C with Pmod I2S2, volume knob, gain select

## Details
Audio pass-through. Extends @[artvvb](https://github.com/artvvb)'s work on [Pmod-I2S2](https://github.com/Digilent/Pmod-I2S2). 
- Adds a potentiometer + XADC input for volume control, instead of the switch-based volume control
- Adds a parameterizable-gain amplifier (DSP48-based) with on/off control via SW0
- Maps output magnitude to ARTY's 2x4 LED array (left channel on LD[3:0], right channel on LD[7:4])

## SW/HW
Xilinx Vivado 2021.1<br/>
Digilent ARTY Rev. C (XC7A35T)<br/>
Digilent Pmod I2S2

## Usage
`make vivado_project` <br/>
`cd arty_audio && vivado arty_audio.xpr` <br/>
Synthesis, implementation, and bitstream generation may be run from the GUI

## Block Diagram
![bd_2](https://user-images.githubusercontent.com/18313961/132789122-b3eeb91a-795a-4a93-a268-e9e52463c3b7.png)

