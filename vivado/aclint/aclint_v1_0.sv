
`timescale 1 ns / 1 ps

	module aclint_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S_AXI_TIMER
		parameter integer C_S_AXI_TIMER_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_TIMER_ADDR_WIDTH	= 4,

		// Parameters of Axi Slave Bus Interface S_AXI_IPI
		parameter integer C_S_AXI_IPI_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_IPI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
		output logic timer_interrupt_out,

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S_AXI_TIMER
		input wire  s_axi_timer_aclk,
		input wire  s_axi_timer_aresetn,
		input wire [C_S_AXI_TIMER_ADDR_WIDTH-1 : 0] s_axi_timer_awaddr,
		input wire [2 : 0] s_axi_timer_awprot,
		input wire  s_axi_timer_awvalid,
		output wire  s_axi_timer_awready,
		input wire [C_S_AXI_TIMER_DATA_WIDTH-1 : 0] s_axi_timer_wdata,
		input wire [(C_S_AXI_TIMER_DATA_WIDTH/8)-1 : 0] s_axi_timer_wstrb,
		input wire  s_axi_timer_wvalid,
		output wire  s_axi_timer_wready,
		output wire [1 : 0] s_axi_timer_bresp,
		output wire  s_axi_timer_bvalid,
		input wire  s_axi_timer_bready,
		input wire [C_S_AXI_TIMER_ADDR_WIDTH-1 : 0] s_axi_timer_araddr,
		input wire [2 : 0] s_axi_timer_arprot,
		input wire  s_axi_timer_arvalid,
		output wire  s_axi_timer_arready,
		output wire [C_S_AXI_TIMER_DATA_WIDTH-1 : 0] s_axi_timer_rdata,
		output wire [1 : 0] s_axi_timer_rresp,
		output wire  s_axi_timer_rvalid,
		input wire  s_axi_timer_rready,

		// Ports of Axi Slave Bus Interface S_AXI_IPI
		input wire  s_axi_ipi_aclk,
		input wire  s_axi_ipi_aresetn,
		input wire [C_S_AXI_IPI_ADDR_WIDTH-1 : 0] s_axi_ipi_awaddr,
		input wire [2 : 0] s_axi_ipi_awprot,
		input wire  s_axi_ipi_awvalid,
		output wire  s_axi_ipi_awready,
		input wire [C_S_AXI_IPI_DATA_WIDTH-1 : 0] s_axi_ipi_wdata,
		input wire [(C_S_AXI_IPI_DATA_WIDTH/8)-1 : 0] s_axi_ipi_wstrb,
		input wire  s_axi_ipi_wvalid,
		output wire  s_axi_ipi_wready,
		output wire [1 : 0] s_axi_ipi_bresp,
		output wire  s_axi_ipi_bvalid,
		input wire  s_axi_ipi_bready,
		input wire [C_S_AXI_IPI_ADDR_WIDTH-1 : 0] s_axi_ipi_araddr,
		input wire [2 : 0] s_axi_ipi_arprot,
		input wire  s_axi_ipi_arvalid,
		output wire  s_axi_ipi_arready,
		output wire [C_S_AXI_IPI_DATA_WIDTH-1 : 0] s_axi_ipi_rdata,
		output wire [1 : 0] s_axi_ipi_rresp,
		output wire  s_axi_ipi_rvalid,
		input wire  s_axi_ipi_rready
	);

	logic [63:0] timer_counter = 0;

// Instantiation of Axi Bus Interface S_AXI_TIMER
	aclint_v1_0_S_AXI_TIMER # ( 
		.C_S_AXI_DATA_WIDTH(C_S_AXI_TIMER_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_TIMER_ADDR_WIDTH)
	) aclint_v1_0_S_AXI_TIMER_inst (
		.timer_counter_in(timer_counter),
		.timer_interrupt_out(timer_interrupt_out),

		.S_AXI_ACLK(s_axi_timer_aclk),
		.S_AXI_ARESETN(s_axi_timer_aresetn),
		.S_AXI_AWADDR(s_axi_timer_awaddr),
		.S_AXI_AWPROT(s_axi_timer_awprot),
		.S_AXI_AWVALID(s_axi_timer_awvalid),
		.S_AXI_AWREADY(s_axi_timer_awready),
		.S_AXI_WDATA(s_axi_timer_wdata),
		.S_AXI_WSTRB(s_axi_timer_wstrb),
		.S_AXI_WVALID(s_axi_timer_wvalid),
		.S_AXI_WREADY(s_axi_timer_wready),
		.S_AXI_BRESP(s_axi_timer_bresp),
		.S_AXI_BVALID(s_axi_timer_bvalid),
		.S_AXI_BREADY(s_axi_timer_bready),
		.S_AXI_ARADDR(s_axi_timer_araddr),
		.S_AXI_ARPROT(s_axi_timer_arprot),
		.S_AXI_ARVALID(s_axi_timer_arvalid),
		.S_AXI_ARREADY(s_axi_timer_arready),
		.S_AXI_RDATA(s_axi_timer_rdata),
		.S_AXI_RRESP(s_axi_timer_rresp),
		.S_AXI_RVALID(s_axi_timer_rvalid),
		.S_AXI_RREADY(s_axi_timer_rready)
	);

// Instantiation of Axi Bus Interface S_AXI_IPI
	aclint_v1_0_S_AXI_IPI # ( 
		.C_S_AXI_DATA_WIDTH(C_S_AXI_IPI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_IPI_ADDR_WIDTH)
	) aclint_v1_0_S_AXI_IPI_inst (
		.S_AXI_ACLK(s_axi_ipi_aclk),
		.S_AXI_ARESETN(s_axi_ipi_aresetn),
		.S_AXI_AWADDR(s_axi_ipi_awaddr),
		.S_AXI_AWPROT(s_axi_ipi_awprot),
		.S_AXI_AWVALID(s_axi_ipi_awvalid),
		.S_AXI_AWREADY(s_axi_ipi_awready),
		.S_AXI_WDATA(s_axi_ipi_wdata),
		.S_AXI_WSTRB(s_axi_ipi_wstrb),
		.S_AXI_WVALID(s_axi_ipi_wvalid),
		.S_AXI_WREADY(s_axi_ipi_wready),
		.S_AXI_BRESP(s_axi_ipi_bresp),
		.S_AXI_BVALID(s_axi_ipi_bvalid),
		.S_AXI_BREADY(s_axi_ipi_bready),
		.S_AXI_ARADDR(s_axi_ipi_araddr),
		.S_AXI_ARPROT(s_axi_ipi_arprot),
		.S_AXI_ARVALID(s_axi_ipi_arvalid),
		.S_AXI_ARREADY(s_axi_ipi_arready),
		.S_AXI_RDATA(s_axi_ipi_rdata),
		.S_AXI_RRESP(s_axi_ipi_rresp),
		.S_AXI_RVALID(s_axi_ipi_rvalid),
		.S_AXI_RREADY(s_axi_ipi_rready)
	);

	// Add user logic here
	always_ff @(posedge s_axi_timer_aclk) begin
		if( !s_axi_timer_aresetn ) begin
			timer_counter <= 0;
		end
		else begin
			timer_counter <= timer_counter + 64'd1;
		end
	end

	// User logic ends

	endmodule
