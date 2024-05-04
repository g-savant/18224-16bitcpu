# 16-bit Serial CPU
Gaurav Savant
18-224 Spring 2024 Final Tapeout Project

## Overview
This CPU interacts with an Arduino or Raspberry PI to accomplish standard CPU tasks. The microcontroller acts as a memory interface for the chip, and the chip interacts with the controller by sending a program counter value, data address, and memory address serially through the 8 bit bus (over 2 cycles). The microcontroller then responds with the requested values back serially through the input bus to the chip.
## How it Works
(deeper description of your project's internal operations, along with any
diagrams. large parts of this can likely be copied from your project
design plan and/or RTL checkpoint submission)
To add images, upload them into the repo and use the following format to
embed them in markdown:
![](image1.png)
## Inputs/Outputs
The 12 input pins are the input bus, ard_data_ready, ard_receive_ready, and ard_clk. Remaining are just grounded. The input bus is the bus that the arduino uses to send the values, the ard_data_ready and ard_receive_ready and signals to indicate the status of the Arduino, and ard_clk is controlling the clock on the chip so that it syncs with the clock on the arduino.
## Hardware Peripherals
The only hardware peripheral is the Arduino/Raspberry Pi
## Design Testing / Bringup
(explain how to test your design; if relevant, give examples of inputs and
expected outputs)
(if you would like your design to be tested after integration but before
tapeout, provide a Python script that uses the Debug Interface posted on
canvas and explain here how to run the testing script)
## Media
(optionally include any photos or videos of your design in action)
## (anything else)
If there is anything else you would like to document about your project
such as background information, design space exploration, future ideas,
verification details, references, etc etc. please add it here. This
template is meant to be a guideline, not an exact format that you're
required to follow.
