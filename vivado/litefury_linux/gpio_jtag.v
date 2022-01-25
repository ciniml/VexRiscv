`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/20/2022 03:19:19 AM
// Design Name: 
// Module Name: gpio_jtag
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module gpio_jtag(
    input wire [3:0] gpio_o,
    output wire [3:0] gpio_i,
    output wire tdi,
    input wire tdo,
    output wire tck,
    output wire tms
    );

assign tdi = gpio_o[0];
assign tms = gpio_o[1];
assign tck = gpio_o[2];

assign gpio_i[3] = tdo;
assign gpio_i[2:0] = 0;

endmodule
