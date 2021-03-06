`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: HPB
// Engineer: 
// 
// Create Date: 26.12.2017 
// Design Name: BOE.v
// Module Name: BOE
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


module BOE	(
// 212MHz clock input
input wire                         sys_clk_p,
input wire                         sys_clk_n,
// 200MHz reference clock input
input wire                         clk_ref_p,
input wire                         clk_ref_n,

//-SI5324 I2C programming interface
inout wire                         i2c_clk,
inout wire                         i2c_data,
output wire                        i2c_mux_rst_n,
output wire                        si5324_rst_n,

// 156.25 MHz clock in
input wire                         xphy_refclk_p,
input wire                         xphy_refclk_n,

output wire                         xphy0_txp,
output wire                         xphy0_txn,
input wire                          xphy0_rxp,
input wire                          xphy0_rxn,

input wire         button_north,
input wire         button_east,
input wire         button_west,

output wire[3:0] sfp_tx_disable,

  // Connection to SODIMM-A
  output wire [15:0]                  c0_ddr3_addr,             
  output wire [2:0]                   c0_ddr3_ba,               
  output wire                         c0_ddr3_cas_n,            
  output wire                         c0_ddr3_ck_p,               
  output wire                         c0_ddr3_ck_n,             
  output wire                         c0_ddr3_cke,              
  output wire                         c0_ddr3_cs_n,             
  output wire [7:0]                   c0_ddr3_dm,               
  inout  wire [63:0]                  c0_ddr3_dq,               
  inout  wire [7:0]                   c0_ddr3_dqs_p,              
  inout  wire [7:0]                   c0_ddr3_dqs_n,            
  output wire                         c0_ddr3_odt,              
  output wire                         c0_ddr3_ras_n,            
  output wire                         c0_ddr3_reset_n,          
  output wire                         c0_ddr3_we_n,             

    // Connection to SODIMM-B
  output wire [15:0]                  c1_ddr3_addr,             
  output wire [2:0]                   c1_ddr3_ba,               
  output wire                         c1_ddr3_cas_n,            
  output wire                         c1_ddr3_ck_p,               
  output wire                         c1_ddr3_ck_n,             
  output wire                         c1_ddr3_cke,              
  output wire                         c1_ddr3_cs_n,             
  output wire [7:0]                   c1_ddr3_dm,               
  inout  wire[63:0]                  c1_ddr3_dq,               
  inout  wire[7:0]                   c1_ddr3_dqs_p,              
  inout  wire[7:0]                   c1_ddr3_dqs_n,            
  output wire                         c1_ddr3_odt,              
  output wire                         c1_ddr3_ras_n,            
  output wire                         c1_ddr3_reset_n,          
  output wire                         c1_ddr3_we_n,
  
  input wire                         sys_rst_i,

  //PCIE signal
  output wire[7 : 0]  pci_exp_txp,
  output wire[7 : 0]  pci_exp_txn,
  input  wire[7 : 0]  pci_exp_rxp,
  input  wire[7 : 0]  pci_exp_rxn,
  input  wire        pcie_ref_clk_p,
  input  wire        pcie_ref_clk_n,
  input  wire        pcie_sys_rst_n,
    
  // UART
  //input wire                          RxD,
  //output wire                         TxD,
  input wire   [7:0]                  gpio_switch,
  output wire [7:0]                  led 
    );
    
wire reset;
wire network_init;
reg button_east_reg;
reg[7:0] led_reg;
wire[7:0] led_out;
assign reset = button_east_reg;

wire aresetn;

reg[15:0] wrCmdCounter;
reg[15:0] rdCmdCounter;
reg[15:0] rdAppCounter;

wire          upd_req_TVALID_out;
wire          upd_req_TREADY_out;
wire          upd_req_TDATA_out;
wire          upd_rsp_TVALID_out;
wire          upd_rsp_TREADY_out;
    
assign aresetn = network_init;
//assign sfp_on = 1'b1;
//assign dram_on = 2'b11;
//assign c0_ddr3_dm = 9'h0;
//assign c1_ddr3_dm = 9'h0;
//assign aresetn = init_calib_complete_r; //reset156_25_n;
wire axi_clk;
wire clk_ref_200;

/*
 * Network Signals
 */
wire        AXI_M_Stream_TVALID;
wire        AXI_M_Stream_TREADY;
wire[63:0]  AXI_M_Stream_TDATA;
wire[7:0]   AXI_M_Stream_TKEEP;
wire        AXI_M_Stream_TLAST;

wire        AXI_S_Stream_TVALID;
wire        AXI_S_Stream_TREADY;
wire[63:0]  AXI_S_Stream_TDATA;
wire[7:0]   AXI_S_Stream_TKEEP;
wire        AXI_S_Stream_TLAST;


/*
 * RX Memory Signals
 */
// memory cmd streams
wire        axis_rxread_cmd_TVALID;
wire        axis_rxread_cmd_TREADY;
wire[71:0]  axis_rxread_cmd_TDATA;
wire        axis_rxwrite_cmd_TVALID;
wire        axis_rxwrite_cmd_TREADY;
wire[71:0]  axis_rxwrite_cmd_TDATA;
// memory sts streams
wire        axis_rxread_sts_TVALID;
wire        axis_rxread_sts_TREADY;
wire[7:0]   axis_rxread_sts_TDATA;
wire        axis_rxwrite_sts_TVALID;
wire        axis_rxwrite_sts_TREADY;
wire[7:0]  axis_rxwrite_sts_TDATA;
// memory data streams
wire        axis_rxread_data_TVALID;
wire        axis_rxread_data_TREADY;
wire[63:0]  axis_rxread_data_TDATA;
wire[7:0]   axis_rxread_data_TKEEP;
wire        axis_rxread_data_TLAST;

wire        axis_rxwrite_data_TVALID;
wire        axis_rxwrite_data_TREADY;
wire[63:0]  axis_rxwrite_data_TDATA;
wire[7:0]   axis_rxwrite_data_TKEEP;
wire        axis_rxwrite_data_TLAST;

/*
 * TX Memory Signals
 */
// memory cmd streams
wire        axis_txread_cmd_TVALID;
wire        axis_txread_cmd_TREADY;
wire[71:0]  axis_txread_cmd_TDATA;
wire        axis_txwrite_cmd_TVALID;
wire        axis_txwrite_cmd_TREADY;
wire[71:0]  axis_txwrite_cmd_TDATA;
// memory sts streams
wire        axis_txread_sts_TVALID;
wire        axis_txread_sts_TREADY;
wire[7:0]   axis_txread_sts_TDATA;
wire        axis_txwrite_sts_TVALID;
wire        axis_txwrite_sts_TREADY;
wire[7:0]  axis_txwrite_sts_TDATA;
// memory data streams
wire        axis_txread_data_TVALID;
wire        axis_txread_data_TREADY;
wire[63:0]  axis_txread_data_TDATA;
wire[7:0]   axis_txread_data_TKEEP;
wire        axis_txread_data_TLAST;

wire        axis_txwrite_data_TVALID;
wire        axis_txwrite_data_TREADY;
wire[63:0]  axis_txwrite_data_TDATA;
wire[7:0]   axis_txwrite_data_TKEEP;
wire        axis_txwrite_data_TLAST;

/*
 * Application Signals
 */
 // listen&close port
  // open&close connection
wire        axis_listen_port_TVALID;
wire        axis_listen_port_TREADY;
wire[15:0]  axis_listen_port_TDATA;
wire        axis_listen_port_status_TVALID;
wire        axis_listen_port_status_TREADY;
wire[7:0]   axis_listen_port_status_TDATA;
//wire        axis_close_port_TVALID;
//wire        axis_close_port_TREADY;
//wire[15:0]  axis_close_port_TDATA;
 // notifications and pkg fetching
wire        axis_notifications_TVALID;
wire        axis_notifications_TREADY;
wire[87:0]  axis_notifications_TDATA;
wire        axis_read_package_TVALID;
wire        axis_read_package_TREADY;
wire[31:0]  axis_read_package_TDATA;
// open&close connection
wire        axis_open_connection_TVALID;
wire        axis_open_connection_TREADY;
wire[47:0]  axis_open_connection_TDATA;
wire        axis_open_status_TVALID;
wire        axis_open_status_TREADY;
wire[23:0]  axis_open_status_TDATA;
wire        axis_close_connection_TVALID;
wire        axis_close_connection_TREADY;
wire[15:0]  axis_close_connection_TDATA;
// rx data
wire        axis_rx_metadata_TVALID;
wire        axis_rx_metadata_TREADY;
wire[15:0]  axis_rx_metadata_TDATA;
wire        axis_rx_data_TVALID;
wire        axis_rx_data_TREADY;
wire[63:0]  axis_rx_data_TDATA;
wire[7:0]   axis_rx_data_TKEEP;
wire        axis_rx_data_TLAST;
// tx data
wire        axis_tx_metadata_TVALID;
wire        axis_tx_metadata_TREADY;
wire[31:0]  axis_tx_metadata_TDATA;
wire        axis_tx_data_TVALID;
wire        axis_tx_data_TREADY;
wire[63:0]  axis_tx_data_TDATA;
wire[7:0]   axis_tx_data_TKEEP;
wire        axis_tx_data_TLAST;
wire        axis_tx_status_TVALID;
wire        axis_tx_status_TREADY;
wire[23:0]  axis_tx_status_TDATA;

wire[15:0]  regSessionCount;
wire[15:0]  relSessionCount;

wire [47:0] myMac;
wire [31:0] myIP;
wire [47:0] myMac_to_network_stack;
wire [31:0] myIP_to_network_stack;

assign myMac=48'h002233445566;  //h000A35029DE5;  //;
assign myIP=32'h0A01D4D1; //c0a80205;
assign myMac_to_network_stack = {myMac[7:0],myMac[15:8],myMac[23:16],myMac[31:24],myMac[39:32],myMac[47:40]};
assign myIP_to_network_stack  = {myIP[7:0],myIP[15:8],myIP[23:16],myIP[31:24]};

always @(posedge axi_clk) begin
    button_east_reg <= button_east;
    led_reg <= led_out;
/*    runExperiment <= button_north | vio_cmd[0];
    dualModeEn <= vio_cmd[1];
    useConn <= vio_cmd[15:2];
    pkgWordCount <= vio_cmd[23:16];
	 regIpSub0 <= vio_cmd[31:24];
	 regIpSub1 <= vio_cmd[39:32];
	 regIpSub2 <= vio_cmd[47:40];
	 regIpSub3 <= vio_cmd[55:48];*/
    //regIpAddress1 <= vio_cmd[49:18];
    //numCons <= vio_cmd[33:18];
end
//assign led = led_reg;

clock_gen u_clk_gen(
.clk_ref_p(clk_ref_p),
.clk_ref_n(clk_ref_n),
.reset(reset),
.clk_ref_200_out(clk_ref_200),
.i2c_clk(i2c_clk),
.i2c_data(i2c_data),
.i2c_mux_rst_n(i2c_mux_rst_n),
.si5324_rst_n(si5324_rst_n)
);


//****************Network Interface Unit*************************
NIU  u_NIU (
 .reset(reset),
 .aresetn(aresetn),
 .xge_refclk_p(xphy_refclk_p),
 .xge_refclk_n(xphy_refclk_n),
 .xge_txp(xphy0_txp),
 .xge_txn(xphy0_txn),
 .xge_rxp(xphy0_rxp),
 .xge_rxn(xphy0_rxn),
 //master
 .rx_axis_tdata(AXI_S_Stream_TDATA),
 .rx_axis_tvalid(AXI_S_Stream_TVALID),
 .rx_axis_tlast(AXI_S_Stream_TLAST),
 .rx_axis_tkeep(AXI_S_Stream_TKEEP),
 .rx_axis_tready(AXI_S_Stream_TREADY),
 //slave
 .tx_axis_tdata(AXI_M_Stream_TDATA),
 .tx_axis_tvalid(AXI_M_Stream_TVALID),
 .tx_axis_tlast(AXI_M_Stream_TLAST),
 .tx_axis_tuser(0),
 .tx_axis_tkeep(AXI_M_Stream_TKEEP),
 .tx_axis_tready(AXI_M_Stream_TREADY),
     
 .sfp_tx_disable(sfp_tx_disable),
 .clk156_out(axi_clk),
 .network_reset_done(network_init),
 .led(led_out),
 .mac_id_filter_en(0),
 .mac_id_valid(1),
 .mac_id(myMac)
 );

// assign AXI_M_Stream_TDATA = AXI_S_Stream_TDATA;
// assign AXI_M_Stream_TVALID = AXI_S_Stream_TVALID;
// assign AXI_M_Stream_TLAST = AXI_S_Stream_TLAST;
// assign AXI_M_Stream_TKEEP = AXI_S_Stream_TKEEP;
// assign AXI_S_Stream_TREADY = AXI_M_Stream_TREADY;



/*
 * TCP/IP Wrapper Module
 */
wire [15:0] regSessionCount_V;
wire regSessionCount_V_ap_vld;

// UDP Loopback App to UDP App Mux wires
wire        shim2mux_requestPortOpenOut_V_TVALID;
wire        shim2mux_requestPortOpenOut_V_TREADY;
wire[15:0]  shim2mux_requestPortOpenOut_V_TDATA;    // Used to request the opening of a port by the App
wire        mux2shim_portOpenReplyIn_V_V_TVALID;
wire        mux2shim_portOpenReplyIn_V_V_TREADY;
wire[7:0]   mux2shim_portOpenReplyIn_V_V_TDATA;     // Reply to the open port request from the UDD Offload Engine
wire        mux2shimRxMetadataIn_V_TVALID;
wire        mux2shimRxMetadataIn_V_TREADY;
wire[95:0]  mux2shimRxMetadataIn_V_TDATA;           // Metadata output from the UDP App Mux
wire        mux2shimRxDataIn_TVALID;
wire        mux2shimRxDataIn_TREADY;
wire[63:0]  mux2shimRxDataIn_TDATA;                 // Packet data output from the UDP App Mux
wire        mux2shimRxDataIn_TLAST;
wire[7:0]   mux2shimRxDataIn_TKEEP;
wire        shim2mux_TVALID;
wire        shim2mux_TREADY;
wire[63:0]  shim2mux_TDATA;
wire[7:0]   shim2mux_TKEEP;
wire        shim2mux_TLAST;
wire        shim2muxTxMetadataOut_V_TVALID;
wire        shim2muxTxMetadataOut_V_TREADY;
wire[95:0]  shim2muxTxMetadataOut_V_TDATA;
wire        shim2muxTxLengthOut_V_V_TVALID;
wire        shim2muxTxLengthOut_V_V_TREADY;
wire[15:0]  shim2muxTxLengthOut_V_V_TDATA;

wire[31:0]  ipAddressOut;

network_stack network_stack_inst(
.aclk                           (axi_clk),
.aresetn                        (aresetn),
.myMacAddress			        (myMac_to_network_stack),
.inputIpAddress                 (myIP_to_network_stack),
.dhcpEnable                     (1'b0),
.ipAddressOut                   (ipAddressOut),
.regSessionCount                (regSessionCount),
.relSessionCount                (relSessionCount),
//////////////////////////////////////////////////
.upd_req_TVALID_out(upd_req_TVALID_out),
.upd_req_TREADY_out(upd_req_TREADY_out),
.upd_req_TDATA_out(upd_req_TDATA_out),
.upd_rsp_TVALID_out(upd_rsp_TVALID_out),
.upd_rsp_TREADY_out(upd_rsp_TREADY_out),
// Debug streams
.axi_debug1_tkeep  ( ),    
.axi_debug1_tdata  ( ),    
.axi_debug1_tvalid ( ),    
.axi_debug1_tready ( ),    
.axi_debug1_tlast  ( ),    
.axi_debug2_tkeep  ( ),    
.axi_debug2_tdata  ( ),    
.axi_debug2_tvalid ( ),    
.axi_debug2_tready ( ),    
.axi_debug2_tlast  ( ),    
// Debug signals //
.metadataFifo_din         ( ),
.metadataFifo_full        ( ),
.metadataFifo_write       ( ),
.metadataHandlerFifo_din  ( ),
.metadataHandlerFifo_full ( ),
.metadataHandlerFifo_write( ),
////////////////////
// network interface streams
.AXI_M_Stream_TVALID            (AXI_M_Stream_TVALID),
.AXI_M_Stream_TREADY            (AXI_M_Stream_TREADY),
.AXI_M_Stream_TDATA             (AXI_M_Stream_TDATA),
.AXI_M_Stream_TKEEP             (AXI_M_Stream_TKEEP),
.AXI_M_Stream_TLAST             (AXI_M_Stream_TLAST),

.AXI_S_Stream_TVALID            (AXI_S_Stream_TVALID),
.AXI_S_Stream_TREADY            (AXI_S_Stream_TREADY),
.AXI_S_Stream_TDATA             (AXI_S_Stream_TDATA),
.AXI_S_Stream_TKEEP             (AXI_S_Stream_TKEEP),
.AXI_S_Stream_TLAST             (AXI_S_Stream_TLAST),

// memory rx cmd streams
.m_axis_rxread_cmd_TVALID       (axis_rxread_cmd_TVALID),
.m_axis_rxread_cmd_TREADY       (axis_rxread_cmd_TREADY),
.m_axis_rxread_cmd_TDATA        (axis_rxread_cmd_TDATA),
.m_axis_rxwrite_cmd_TVALID      (axis_rxwrite_cmd_TVALID),
.m_axis_rxwrite_cmd_TREADY      (axis_rxwrite_cmd_TREADY),
.m_axis_rxwrite_cmd_TDATA       (axis_rxwrite_cmd_TDATA),
// memory rx status streams
//.s_axis_rxread_sts_TVALID       (axis_rxread_sts_TVALID),
//.s_axis_rxread_sts_TREADY       (axis_rxread_sts_TREADY),
//.s_axis_rxread_sts_TDATA        (axis_rxread_sts_TDATA),
.s_axis_rxwrite_sts_TVALID      (axis_rxwrite_sts_TVALID),
.s_axis_rxwrite_sts_TREADY      (axis_rxwrite_sts_TREADY),
.s_axis_rxwrite_sts_TDATA       (axis_rxwrite_sts_TDATA),
// memory rx data streams
.s_axis_rxread_data_TVALID      (axis_rxread_data_TVALID),
.s_axis_rxread_data_TREADY      (axis_rxread_data_TREADY),
.s_axis_rxread_data_TDATA       (axis_rxread_data_TDATA),
.s_axis_rxread_data_TKEEP       (axis_rxread_data_TKEEP),
.s_axis_rxread_data_TLAST       (axis_rxread_data_TLAST),
.m_axis_rxwrite_data_TVALID     (axis_rxwrite_data_TVALID),
.m_axis_rxwrite_data_TREADY     (axis_rxwrite_data_TREADY),
.m_axis_rxwrite_data_TDATA      (axis_rxwrite_data_TDATA),
.m_axis_rxwrite_data_TKEEP      (axis_rxwrite_data_TKEEP),
.m_axis_rxwrite_data_TLAST      (axis_rxwrite_data_TLAST),

// memory tx cmd streams
.m_axis_txread_cmd_TVALID       (axis_txread_cmd_TVALID),
.m_axis_txread_cmd_TREADY       (axis_txread_cmd_TREADY),
.m_axis_txread_cmd_TDATA        (axis_txread_cmd_TDATA),
.m_axis_txwrite_cmd_TVALID      (axis_txwrite_cmd_TVALID),
.m_axis_txwrite_cmd_TREADY      (axis_txwrite_cmd_TREADY),
.m_axis_txwrite_cmd_TDATA       (axis_txwrite_cmd_TDATA),
// memory tx status streams
//.s_axis_txread_sts_TVALID       (axis_txread_sts_TVALID),
//.s_axis_txread_sts_TREADY       (axis_txread_sts_TREADY),
//.s_axis_txread_sts_TDATA        (axis_txread_sts_TDATA),
.s_axis_txwrite_sts_TVALID      (axis_txwrite_sts_TVALID),
.s_axis_txwrite_sts_TREADY      (axis_txwrite_sts_TREADY),
.s_axis_txwrite_sts_TDATA       (axis_txwrite_sts_TDATA),
// memory tx data streams
.s_axis_txread_data_TVALID      (axis_txread_data_TVALID),
.s_axis_txread_data_TREADY      (axis_txread_data_TREADY),
.s_axis_txread_data_TDATA       (axis_txread_data_TDATA),
.s_axis_txread_data_TKEEP       (axis_txread_data_TKEEP),
.s_axis_txread_data_TLAST       (axis_txread_data_TLAST),
.m_axis_txwrite_data_TVALID     (axis_txwrite_data_TVALID),
.m_axis_txwrite_data_TREADY     (axis_txwrite_data_TREADY),
.m_axis_txwrite_data_TDATA      (axis_txwrite_data_TDATA),
.m_axis_txwrite_data_TKEEP      (axis_txwrite_data_TKEEP),
.m_axis_txwrite_data_TLAST      (axis_txwrite_data_TLAST),

//application interface streams
.m_axis_listen_port_status_TVALID       (axis_listen_port_status_TVALID),
.m_axis_listen_port_status_TREADY       (axis_listen_port_status_TREADY),
.m_axis_listen_port_status_TDATA        (axis_listen_port_status_TDATA),
.m_axis_notifications_TVALID            (axis_notifications_TVALID),
.m_axis_notifications_TREADY            (axis_notifications_TREADY),
.m_axis_notifications_TDATA             (axis_notifications_TDATA),
.m_axis_open_status_TVALID              (axis_open_status_TVALID),
.m_axis_open_status_TREADY              (axis_open_status_TREADY),
.m_axis_open_status_TDATA               (axis_open_status_TDATA),
.m_axis_rx_data_TVALID                  (axis_rx_data_TVALID),
.m_axis_rx_data_TREADY                  (axis_rx_data_TREADY),
.m_axis_rx_data_TDATA                   (axis_rx_data_TDATA),
.m_axis_rx_data_TKEEP                   (axis_rx_data_TKEEP),
.m_axis_rx_data_TLAST                   (axis_rx_data_TLAST),
.m_axis_rx_metadata_TVALID              (axis_rx_metadata_TVALID),
.m_axis_rx_metadata_TREADY              (axis_rx_metadata_TREADY),
.m_axis_rx_metadata_TDATA               (axis_rx_metadata_TDATA),
.m_axis_tx_status_TVALID                (axis_tx_status_TVALID),
.m_axis_tx_status_TREADY                (axis_tx_status_TREADY),
.m_axis_tx_status_TDATA                 (axis_tx_status_TDATA),
.s_axis_listen_port_TVALID              (axis_listen_port_TVALID),
.s_axis_listen_port_TREADY              (axis_listen_port_TREADY),
.s_axis_listen_port_TDATA               (axis_listen_port_TDATA),
//.s_axis_close_port_TVALID             (axis_close_port_TVALID),
//.s_axis_close_port_TREADY             (axis_close_port_TREADY),
//.s_axis_close_port_TDATA              (axis_close_port_TDATA),
.s_axis_close_connection_TVALID         (axis_close_connection_TVALID),
.s_axis_close_connection_TREADY         (axis_close_connection_TREADY),
.s_axis_close_connection_TDATA          (axis_close_connection_TDATA),
.s_axis_open_connection_TVALID          (axis_open_connection_TVALID),
.s_axis_open_connection_TREADY          (axis_open_connection_TREADY),
.s_axis_open_connection_TDATA           (axis_open_connection_TDATA),
.s_axis_read_package_TVALID             (axis_read_package_TVALID),
.s_axis_read_package_TREADY             (axis_read_package_TREADY),
.s_axis_read_package_TDATA              (axis_read_package_TDATA),
.s_axis_tx_data_TVALID                  (axis_tx_data_TVALID),
.s_axis_tx_data_TREADY                  (axis_tx_data_TREADY),
.s_axis_tx_data_TDATA                   (axis_tx_data_TDATA),
.s_axis_tx_data_TKEEP                   (axis_tx_data_TKEEP),
.s_axis_tx_data_TLAST                   (axis_tx_data_TLAST),
.s_axis_tx_metadata_TVALID              (axis_tx_metadata_TVALID),
.s_axis_tx_metadata_TREADY              (axis_tx_metadata_TREADY),
.s_axis_tx_metadata_TDATA               (axis_tx_metadata_TDATA),
.regSessionCount_V                      (regSessionCount_V),
.regSessionCount_V_ap_vld               (regSessionCount_V_ap_vld),

// UDP User I/F to Loopback module //
.lbPortOpenReplyIn_TVALID               (mux2shim_portOpenReplyIn_V_V_TVALID),         // output wire portOpenReplyIn_TVALID
.lbPortOpenReplyIn_TREADY               (mux2shim_portOpenReplyIn_V_V_TREADY),         // input wire portOpenReplyIn_TREADY
.lbPortOpenReplyIn_TDATA                (mux2shim_portOpenReplyIn_V_V_TDATA),          // output wire [7 : 0] portOpenReplyIn_TDATA
.lbRequestPortOpenOut_TVALID            (shim2mux_requestPortOpenOut_V_TVALID),        // input wire requestPortOpenOut_TVALID
.lbRequestPortOpenOut_TREADY            (shim2mux_requestPortOpenOut_V_TREADY),        // output wire requestPortOpenOut_TREADY
.lbRequestPortOpenOut_TDATA             (shim2mux_requestPortOpenOut_V_TDATA),         // input wire [15 : 0] requestPortOpenOut_TDATA
.lbRxDataIn_TVALID                      (mux2shimRxDataIn_TVALID),                     // output wire rxDataIn_TVALID
.lbRxDataIn_TREADY                      (mux2shimRxDataIn_TREADY),                     // input wire rxDataIn_TREADY
.lbRxDataIn_TDATA                       (mux2shimRxDataIn_TDATA),                      // output wire [63 : 0] rxDataIn_TDATA
.lbRxDataIn_TKEEP                       (mux2shimRxDataIn_TKEEP),                      // output wire [7 : 0] rxDataIn_TKEEP
.lbRxDataIn_TLAST                       (mux2shimRxDataIn_TLAST),                      // output wire [0 : 0] rxDataIn_TLAST
.lbRxMetadataIn_TVALID                  (mux2shimRxMetadataIn_V_TVALID),               // output wire rxMetadataIn_TVALID
.lbRxMetadataIn_TREADY                  (mux2shimRxMetadataIn_V_TREADY),               // input wire rxMetadataIn_TREADY
.lbRxMetadataIn_TDATA                   (mux2shimRxMetadataIn_V_TDATA),                // output wire [95 : 0] rxMetadataIn_TDATA
.lbTxDataOut_TVALID                     (shim2mux_TVALID),                             // input wire txDataOut_TVALID
.lbTxDataOut_TREADY                     (shim2mux_TREADY),                             // output wire txDataOut_TREADY
.lbTxDataOut_TDATA                      (shim2mux_TDATA),                              // input wire [63 : 0] txDataOut_TDATA
.lbTxDataOut_TKEEP                      (shim2mux_TKEEP),                              // input wire [7 : 0] txDataOut_TKEEP
.lbTxDataOut_TLAST                      (shim2mux_TLAST),                              // input wire [0 : 0] txDataOut_TLAST
.lbTxLengthOut_TVALID                   (shim2muxTxLengthOut_V_V_TVALID),              // input wire txLengthOut_TVALID
.lbTxLengthOut_TREADY                   (shim2muxTxLengthOut_V_V_TREADY),              // output wire txLengthOut_TREADY
.lbTxLengthOut_TDATA                    (shim2muxTxLengthOut_V_V_TDATA),               // input wire [15 : 0] txLengthOut_TDATA
.lbTxMetadataOut_TVALID                 (shim2muxTxMetadataOut_V_TVALID),              // input wire txMetadataOut_TVALID
.lbTxMetadataOut_TREADY                 (shim2muxTxMetadataOut_V_TREADY),              // output wire txMetadataOut_TREADY
.lbTxMetadataOut_TDATA                  (shim2muxTxMetadataOut_V_TDATA)                // input wire [95 : 0] txMetadataOut_TDATA
);

echo_server_application_ip myEchoServer (
  .m_axis_close_connection_TVALID(axis_close_connection_TVALID),      // output wire m_axis_close_connection_TVALID
  .m_axis_close_connection_TREADY(axis_close_connection_TREADY),      // input wire m_axis_close_connection_TREADY
  .m_axis_close_connection_TDATA(axis_close_connection_TDATA),        // output wire [15 : 0] m_axis_close_connection_TDATA
  .m_axis_listen_port_TVALID(axis_listen_port_TVALID),                // output wire m_axis_listen_port_TVALID
  .m_axis_listen_port_TREADY(axis_listen_port_TREADY),                // input wire m_axis_listen_port_TREADY
  .m_axis_listen_port_TDATA(axis_listen_port_TDATA),                  // output wire [15 : 0] m_axis_listen_port_TDATA
  .m_axis_open_connection_TVALID(axis_open_connection_TVALID),        // output wire m_axis_open_connection_TVALID
  .m_axis_open_connection_TREADY(axis_open_connection_TREADY),        // input wire m_axis_open_connection_TREADY
  .m_axis_open_connection_TDATA(axis_open_connection_TDATA),          // output wire [47 : 0] m_axis_open_connection_TDATA
//  .m_axis_read_package_TVALID(axis_read_package_TVALID),              // output wire m_axis_read_package_TVALID
//  .m_axis_read_package_TREADY(axis_read_package_TREADY),              // input wire m_axis_read_package_TREADY
//  .m_axis_read_package_TDATA(axis_read_package_TDATA),                // output wire [31 : 0] m_axis_read_package_TDATA
  .m_axis_read_package_TVALID(),              // output wire m_axis_read_package_TVALID
  .m_axis_read_package_TREADY(0),              // input wire m_axis_read_package_TREADY
  .m_axis_read_package_TDATA(),                // output wire [31 : 0] m_axis_read_package_TDATA
//  .m_axis_tx_data_TVALID(axis_tx_data_TVALID),                        // output wire m_axis_tx_data_TVALID
//  .m_axis_tx_data_TREADY(axis_tx_data_TREADY),                        // input wire m_axis_tx_data_TREADY
//  .m_axis_tx_data_TDATA(axis_tx_data_TDATA),                          // output wire [63 : 0] m_axis_tx_data_TDATA
//  .m_axis_tx_data_TKEEP(axis_tx_data_TKEEP),                          // output wire [7 : 0] m_axis_tx_data_TKEEP
//  .m_axis_tx_data_TLAST(axis_tx_data_TLAST),                          // output wire [0 : 0] m_axis_tx_data_TLAST
  .m_axis_tx_data_TVALID(),                        // output wire m_axis_tx_data_TVALID
  .m_axis_tx_data_TREADY(0),                        // input wire m_axis_tx_data_TREADY
  .m_axis_tx_data_TDATA(),                          // output wire [63 : 0] m_axis_tx_data_TDATA
  .m_axis_tx_data_TKEEP(),                          // output wire [7 : 0] m_axis_tx_data_TKEEP
  .m_axis_tx_data_TLAST(),                          // output wire [0 : 0] m_axis_tx_data_TLAST
//  .m_axis_tx_metadata_TVALID(axis_tx_metadata_TVALID),                // output wire m_axis_tx_metadata_TVALID
//  .m_axis_tx_metadata_TREADY(axis_tx_metadata_TREADY),                // input wire m_axis_tx_metadata_TREADY
//  .m_axis_tx_metadata_TDATA(axis_tx_metadata_TDATA),                  // output wire [15 : 0] m_axis_tx_metadata_TDATA
  .m_axis_tx_metadata_TVALID(),                // output wire m_axis_tx_metadata_TVALID
  .m_axis_tx_metadata_TREADY(0),                // input wire m_axis_tx_metadata_TREADY
  .m_axis_tx_metadata_TDATA(),                  // output wire [15 : 0] m_axis_tx_metadata_TDATA
  .s_axis_listen_port_status_TVALID(axis_listen_port_status_TVALID),  // input wire s_axis_listen_port_status_TVALID
  .s_axis_listen_port_status_TREADY(axis_listen_port_status_TREADY),  // output wire s_axis_listen_port_status_TREADY
  .s_axis_listen_port_status_TDATA(axis_listen_port_status_TDATA),    // input wire [7 : 0] s_axis_listen_port_status_TDATA
//  .s_axis_notifications_TVALID(axis_notifications_TVALID),            // input wire s_axis_notifications_TVALID
//  .s_axis_notifications_TREADY(axis_notifications_TREADY),            // output wire s_axis_notifications_TREADY
//  .s_axis_notifications_TDATA(axis_notifications_TDATA),              // input wire [87 : 0] s_axis_notifications_TDATA
  .s_axis_notifications_TVALID(0),            // input wire s_axis_notifications_TVALID
  .s_axis_notifications_TREADY(),            // output wire s_axis_notifications_TREADY
  .s_axis_notifications_TDATA(0),              // input wire [87 : 0] s_axis_notifications_TDATA
  .s_axis_open_status_TVALID(axis_open_status_TVALID),                // input wire s_axis_open_status_TVALID
  .s_axis_open_status_TREADY(axis_open_status_TREADY),                // output wire s_axis_open_status_TREADY
  .s_axis_open_status_TDATA(axis_open_status_TDATA),                  // input wire [23 : 0] s_axis_open_status_TDATA
//  .s_axis_rx_data_TVALID(axis_rx_data_TVALID),                        // input wire s_axis_rx_data_TVALID
//  .s_axis_rx_data_TREADY(axis_rx_data_TREADY),                        // output wire s_axis_rx_data_TREADY
//  .s_axis_rx_data_TDATA(axis_rx_data_TDATA),                          // input wire [63 : 0] s_axis_rx_data_TDATA
//  .s_axis_rx_data_TKEEP(axis_rx_data_TKEEP),                          // input wire [7 : 0] s_axis_rx_data_TKEEP
//  .s_axis_rx_data_TLAST(axis_rx_data_TLAST),                          // input wire [0 : 0] s_axis_rx_data_TLAST
//  .s_axis_rx_metadata_TVALID(axis_rx_metadata_TVALID),                // input wire s_axis_rx_metadata_TVALID
//  .s_axis_rx_metadata_TREADY(axis_rx_metadata_TREADY),                // output wire s_axis_rx_metadata_TREADY
//  .s_axis_rx_metadata_TDATA(axis_rx_metadata_TDATA),                  // input wire [15 : 0] s_axis_rx_metadata_TDATA
  .s_axis_rx_data_TVALID(0),                        // input wire s_axis_rx_data_TVALID
  .s_axis_rx_data_TREADY(),                        // output wire s_axis_rx_data_TREADY
  .s_axis_rx_data_TDATA(0),                          // input wire [63 : 0] s_axis_rx_data_TDATA
  .s_axis_rx_data_TKEEP(0),                          // input wire [7 : 0] s_axis_rx_data_TKEEP
  .s_axis_rx_data_TLAST(0),                          // input wire [0 : 0] s_axis_rx_data_TLAST
  .s_axis_rx_metadata_TVALID(0),                // input wire s_axis_rx_metadata_TVALID
  .s_axis_rx_metadata_TREADY(),                // output wire s_axis_rx_metadata_TREADY
  .s_axis_rx_metadata_TDATA(0),                  // input wire [15 : 0] s_axis_rx_metadata_TDATA
//  .s_axis_tx_status_TVALID(axis_tx_status_TVALID),                    // input wire s_axis_tx_status_TVALID
//  .s_axis_tx_status_TREADY(axis_tx_status_TREADY),                    // output wire s_axis_tx_status_TREADY
//  .s_axis_tx_status_TDATA(axis_tx_status_TDATA),                      // input wire [23 : 0] s_axis_tx_status_TDATA
  .s_axis_tx_status_TVALID(0),                    // input wire s_axis_tx_status_TVALID
  .s_axis_tx_status_TREADY(),                    // output wire s_axis_tx_status_TREADY
  .s_axis_tx_status_TDATA(0),                      // input wire [23 : 0] s_axis_tx_status_TDATA
  .aclk(axi_clk),                                                          // input wire aclk
  .aresetn(aresetn)                                                    // input wire aresetn
);


udpLoopback_0 udpLoopback_inst (
  .lbPortOpenReplyIn_TVALID(mux2shim_portOpenReplyIn_V_V_TVALID),       // input wire portOpenReplyIn_TVALID
  .lbPortOpenReplyIn_TREADY(mux2shim_portOpenReplyIn_V_V_TREADY),       // output wire portOpenReplyIn_TREADY
  .lbPortOpenReplyIn_TDATA(mux2shim_portOpenReplyIn_V_V_TDATA),         // input wire [7 : 0] portOpenReplyIn_TDATA
  .lbRequestPortOpenOut_TVALID(shim2mux_requestPortOpenOut_V_TVALID),   // output wire requestPortOpenOut_TVALID
  .lbRequestPortOpenOut_TREADY(shim2mux_requestPortOpenOut_V_TREADY),   // input wire requestPortOpenOut_TREADY
  .lbRequestPortOpenOut_TDATA(shim2mux_requestPortOpenOut_V_TDATA),     // output wire [15 : 0] requestPortOpenOut_TDATA
  .lbRxDataIn_TVALID(mux2shimRxDataIn_TVALID),                          // input wire rxDataIn_TVALID
  .lbRxDataIn_TREADY(mux2shimRxDataIn_TREADY),                          // output wire rxDataIn_TREADY
  .lbRxDataIn_TDATA(mux2shimRxDataIn_TDATA),                            // input wire [63 : 0] rxDataIn_TDATA
  .lbRxDataIn_TKEEP(mux2shimRxDataIn_TKEEP),                            // input wire [7 : 0] rxDataIn_TKEEP
  .lbRxDataIn_TLAST(mux2shimRxDataIn_TLAST),                            // input wire [0 : 0] rxDataIn_TLAST
  .lbRxMetadataIn_TVALID(mux2shimRxMetadataIn_V_TVALID),                // input wire rxMetadataIn_TVALID
  .lbRxMetadataIn_TREADY(mux2shimRxMetadataIn_V_TREADY),                // output wire rxMetadataIn_TREADY
  .lbRxMetadataIn_TDATA(mux2shimRxMetadataIn_V_TDATA),                  // input wire [95 : 0] rxMetadataIn_TDATA
  .lbTxDataOut_TVALID(shim2mux_TVALID),                                 // output wire txDataOut_TVALID
  .lbTxDataOut_TREADY(shim2mux_TREADY),                                 // input wire txDataOut_TREADY
  .lbTxDataOut_TDATA(shim2mux_TDATA),                                   // output wire [63 : 0] txDataOut_TDATA
  .lbTxDataOut_TKEEP(shim2mux_TKEEP),                                   // output wire [7 : 0] txDataOut_TKEEP
  .lbTxDataOut_TLAST(shim2mux_TLAST),                                   // output wire [0 : 0] txDataOut_TLAST
  .lbTxLengthOut_TVALID(shim2muxTxLengthOut_V_V_TVALID),                // output wire txLengthOut_TVALID
  .lbTxLengthOut_TREADY(shim2muxTxLengthOut_V_V_TREADY),                // input wire txLengthOut_TREADY
  .lbTxLengthOut_TDATA(shim2muxTxLengthOut_V_V_TDATA),                  // output wire [15 : 0] txLengthOut_TDATA
  .lbTxMetadataOut_TVALID(shim2muxTxMetadataOut_V_TVALID),              // output wire txMetadataOut_TVALID
  .lbTxMetadataOut_TREADY(shim2muxTxMetadataOut_V_TREADY),              // input wire txMetadataOut_TREADY
  .lbTxMetadataOut_TDATA(shim2muxTxMetadataOut_V_TDATA),                // output wire [95 : 0] txMetadataOut_TDATA
  .aclk(axi_clk),                                                       // input wire aclk
  .aresetn(aresetn)                                                     // input wire aresetn
);

//DRAM MEM interface

//wire clk156_25;
//wire reset156_25_n;
wire clk233;
wire clk200, clk200_i;
wire c0_init_calib_complete;
wire c1_init_calib_complete;

//toe stream interface signals
wire           toeTX_s_axis_read_cmd_tvalid;
wire          toeTX_s_axis_read_cmd_tready;
wire[71:0]     toeTX_s_axis_read_cmd_tdata;
//read status
wire          toeTX_m_axis_read_sts_tvalid;
wire           toeTX_m_axis_read_sts_tready;
wire[7:0]     toeTX_m_axis_read_sts_tdata;
//read stream
wire[63:0]    toeTX_m_axis_read_tdata;
wire[7:0]     toeTX_m_axis_read_tkeep;
wire          toeTX_m_axis_read_tlast;
wire          toeTX_m_axis_read_tvalid;
wire           toeTX_m_axis_read_tready;

//write commands
wire           toeTX_s_axis_write_cmd_tvalid;
wire          toeTX_s_axis_write_cmd_tready;
wire[71:0]     toeTX_s_axis_write_cmd_tdata;
//write status
wire          toeTX_m_axis_write_sts_tvalid;
wire           toeTX_m_axis_write_sts_tready;
wire[31:0]     toeTX_m_axis_write_sts_tdata;
//write stream
wire[63:0]     toeTX_s_axis_write_tdata;
wire[7:0]      toeTX_s_axis_write_tkeep;
wire           toeTX_s_axis_write_tlast;
wire           toeTX_s_axis_write_tvalid;
wire          toeTX_s_axis_write_tready;

//ht stream interface signals
wire           ht_s_axis_read_cmd_tvalid;
wire          ht_s_axis_read_cmd_tready;
wire[71:0]     ht_s_axis_read_cmd_tdata;
//read status
wire          ht_m_axis_read_sts_tvalid;
wire           ht_m_axis_read_sts_tready;
wire[7:0]     ht_m_axis_read_sts_tdata;
//read stream
wire[511:0]    ht_m_axis_read_tdata;
wire[63:0]     ht_m_axis_read_tkeep;
wire          ht_m_axis_read_tlast;
wire          ht_m_axis_read_tvalid;
wire           ht_m_axis_read_tready;

//write commands
wire           ht_s_axis_write_cmd_tvalid;
wire          ht_s_axis_write_cmd_tready;
wire[71:0]     ht_s_axis_write_cmd_tdata;
//write status
wire          ht_m_axis_write_sts_tvalid;
wire           ht_m_axis_write_sts_tready;
wire[31:0]     ht_m_axis_write_sts_tdata;
//write stream
wire[511:0]     ht_s_axis_write_tdata;
wire[63:0]      ht_s_axis_write_tkeep;
wire           ht_s_axis_write_tlast;
wire           ht_s_axis_write_tvalid;
wire          ht_s_axis_write_tready;

wire[511:0]     ht_s_axis_write_tdata_x;
wire[63:0]      ht_s_axis_write_tkeep_x;
wire           ht_s_axis_write_tlast_x;
wire           ht_s_axis_write_tvalid_x;
wire          ht_s_axis_write_tready_x;

//upd stream interface signals
wire           upd_s_axis_read_cmd_tvalid;
wire          upd_s_axis_read_cmd_tready;
wire[71:0]     upd_s_axis_read_cmd_tdata;
//read status
wire          upd_m_axis_read_sts_tvalid;
wire           upd_m_axis_read_sts_tready;
wire[7:0]     upd_m_axis_read_sts_tdata;
//read stream
wire[511:0]    upd_m_axis_read_tdata;
wire[63:0]     upd_m_axis_read_tkeep;
wire          upd_m_axis_read_tlast;
wire          upd_m_axis_read_tvalid;
wire           upd_m_axis_read_tready;

//write commands
wire           upd_s_axis_write_cmd_tvalid;
wire          upd_s_axis_write_cmd_tready;
wire[71:0]     upd_s_axis_write_cmd_tdata;
//write status
wire          upd_m_axis_write_sts_tvalid;
wire           upd_m_axis_write_sts_tready;
wire[31:0]     upd_m_axis_write_sts_tdata;
//write stream
wire[511:0]     upd_s_axis_write_tdata;
wire[63:0]      upd_s_axis_write_tkeep;
wire           upd_s_axis_write_tlast;
wire           upd_s_axis_write_tvalid;
wire          upd_s_axis_write_tready;

wire[511:0]     upd_s_axis_write_tdata_x;
wire[63:0]      upd_s_axis_write_tkeep_x;
wire           upd_s_axis_write_tlast_x;
wire           upd_s_axis_write_tvalid_x;
wire          upd_s_axis_write_tready_x;

wire ddr3_calib_complete, init_calib_complete;
wire toeTX_compare_error, ht_compare_error, upd_compare_error;

reg rst_n_r1, rst_n_r2, rst_n_r3;
//reg reset156_25_n_r1, reset156_25_n_r2, reset156_25_n_r3;

//registers for crossing clock domains (from 233MHz to 156.25MHz)
reg c0_init_calib_complete_r1, c0_init_calib_complete_r2;
reg c1_init_calib_complete_r1, c1_init_calib_complete_r2;

//localparam TOE_START_ADDR = 32'd0;
//localparam HT_START_ADDR = 32'd0;
//localparam UPD_START_ADDR = 32'd32;


//- 212MHz differential clock for 1866Mbps DDR3 controller
IBUFGDS #(
 .DIFF_TERM    ("TRUE"),
 .IBUF_LOW_PWR ("FALSE")
) clk_233_ibufg (
 .I            (sys_clk_p),
 .IB           (sys_clk_n),
 .O            (clk233)
);

// sys_rst
wire sys_rst;
IBUF clk_212_bufg
 (
     .I                              (sys_rst_i),
     .O                              (sys_rst) 
 );

   
//assign clk156_25 = axi_clk;
//assign clk200 = clk_ref_200;

   /*always @(posedge axi_clk) begin
        reset156_25_n_r1 <= perst_n & pok_dram & network_init;
        reset156_25_n_r2 <= reset156_25_n_r1;
        reset156_25_n_r3 <= reset156_25_n_r2;
   end
  
   assign reset156_25_n = reset156_25_n_r3;
    assign aresetn = reset156_25_n & network_init;*/
always @(posedge axi_clk) 
    if (~aresetn) begin
        c0_init_calib_complete_r1 <= 1'b0;
        c0_init_calib_complete_r2 <= 1'b0;
        c1_init_calib_complete_r1 <= 1'b0;
        c1_init_calib_complete_r2 <= 1'b0;
    end
    else begin
        c0_init_calib_complete_r1 <= c0_init_calib_complete;
        c0_init_calib_complete_r2 <= c0_init_calib_complete_r1;
        c1_init_calib_complete_r1 <= c1_init_calib_complete;
        c1_init_calib_complete_r2 <= c1_init_calib_complete_r1;
    end

assign ddr3_calib_complete = c0_init_calib_complete_r2 & c1_init_calib_complete_r2;
assign init_calib_complete = ddr3_calib_complete;
/*
 * TX Memory Signals
 */
// memory cmd streams
assign toeTX_s_axis_read_cmd_tvalid = axis_txread_cmd_TVALID;
assign axis_txread_cmd_TREADY = toeTX_s_axis_read_cmd_tready;
assign toeTX_s_axis_read_cmd_tdata = axis_txread_cmd_TDATA;
assign toeTX_s_axis_write_cmd_tvalid = axis_txwrite_cmd_TVALID;
assign axis_txwrite_cmd_TREADY = toeTX_s_axis_write_cmd_tready;
assign toeTX_s_axis_write_cmd_tdata = axis_txwrite_cmd_TDATA;
// memory sts streams
assign axis_txread_sts_TVALID         = toeTX_m_axis_read_sts_tvalid;
assign toeTX_m_axis_read_sts_tready   = 1'b1;
assign axis_txread_sts_TDATA          = toeTX_m_axis_read_sts_tdata;
assign axis_txwrite_sts_TVALID        = toeTX_m_axis_write_sts_tvalid;
assign toeTX_m_axis_write_sts_tready  = axis_txwrite_sts_TREADY;
assign axis_txwrite_sts_TDATA         = toeTX_m_axis_write_sts_tdata;
// memory data streams
assign axis_txread_data_TVALID = toeTX_m_axis_read_tvalid;
assign toeTX_m_axis_read_tready = axis_txread_data_TREADY;
assign axis_txread_data_TDATA = toeTX_m_axis_read_tdata;
assign axis_txread_data_TKEEP = toeTX_m_axis_read_tkeep;
assign axis_txread_data_TLAST = toeTX_m_axis_read_tlast;

assign toeTX_s_axis_write_tvalid = axis_txwrite_data_TVALID;
assign axis_txwrite_data_TREADY = toeTX_s_axis_write_tready;
assign toeTX_s_axis_write_tdata = axis_txwrite_data_TDATA;
assign toeTX_s_axis_write_tkeep = axis_txwrite_data_TKEEP;
assign toeTX_s_axis_write_tlast = axis_txwrite_data_TLAST;

wire           toeRX_s_axis_read_cmd_tvalid;
wire          toeRX_s_axis_read_cmd_tready;
wire[71:0]     toeRX_s_axis_read_cmd_tdata;
//read status
wire          toeRX_m_axis_read_sts_tvalid;
wire           toeRX_m_axis_read_sts_tready;
wire[7:0]     toeRX_m_axis_read_sts_tdata;
//read stream
wire[63:0]    toeRX_m_axis_read_tdata;
wire[7:0]     toeRX_m_axis_read_tkeep;
wire          toeRX_m_axis_read_tlast;
wire          toeRX_m_axis_read_tvalid;
wire           toeRX_m_axis_read_tready;

//write commands
wire           toeRX_s_axis_write_cmd_tvalid;
wire          toeRX_s_axis_write_cmd_tready;
wire[71:0]     toeRX_s_axis_write_cmd_tdata;
//write status
wire          toeRX_m_axis_write_sts_tvalid;
wire           toeRX_m_axis_write_sts_tready;
wire[7:0]     toeRX_m_axis_write_sts_tdata;
//write stream
wire[63:0]     toeRX_s_axis_write_tdata;
wire[7:0]      toeRX_s_axis_write_tkeep;
wire           toeRX_s_axis_write_tlast;
wire           toeRX_s_axis_write_tvalid;
wire          toeRX_s_axis_write_tready;

wire  toeRX_compare_error;
assign toeRX_compare_error = 1'b0;

/* RX Memory Signals
 */
// memory cmd streams
assign toeRX_s_axis_read_cmd_tvalid = axis_rxread_cmd_TVALID;
assign axis_rxread_cmd_TREADY = toeRX_s_axis_read_cmd_tready;
assign toeRX_s_axis_read_cmd_tdata = axis_rxread_cmd_TDATA;
assign toeRX_s_axis_write_cmd_tvalid = axis_rxwrite_cmd_TVALID;
assign axis_rxwrite_cmd_TREADY = toeRX_s_axis_write_cmd_tready;
assign toeRX_s_axis_write_cmd_tdata = axis_rxwrite_cmd_TDATA;
// memory sts streams
assign axis_rxread_sts_TVALID = toeRX_m_axis_read_sts_tvalid;
assign toeRX_m_axis_read_sts_tready = 1'b1;
assign axis_rxread_sts_TDATA = toeRX_m_axis_read_sts_tdata;
assign axis_rxwrite_sts_TVALID = toeRX_m_axis_write_sts_tvalid;
assign toeRX_m_axis_write_sts_tready = axis_rxwrite_sts_TREADY;
assign axis_rxwrite_sts_TDATA = toeRX_m_axis_write_sts_tdata;
// memory data streams
assign axis_rxread_data_TVALID = toeRX_m_axis_read_tvalid;
assign toeRX_m_axis_read_tready = axis_rxread_data_TREADY;
assign axis_rxread_data_TDATA = toeRX_m_axis_read_tdata;
assign axis_rxread_data_TKEEP = toeRX_m_axis_read_tkeep;
assign axis_rxread_data_TLAST = toeRX_m_axis_read_tlast;

assign toeRX_s_axis_write_tvalid = axis_rxwrite_data_TVALID;
assign axis_rxwrite_data_TREADY = toeRX_s_axis_write_tready;
assign toeRX_s_axis_write_tdata = axis_rxwrite_data_TDATA;
assign toeRX_s_axis_write_tkeep = axis_rxwrite_data_TKEEP;
assign toeRX_s_axis_write_tlast = axis_rxwrite_data_TLAST;

stream_tg #(
  .DATA_WIDTH(512),
  .KEEP_WIDTH(64),
  .START_ADDR(0),
  .START_DATA(8),
  .BTT(23'd64),
  .DRR(1'b0)
)
ht_stream_tg (
    .aclk(axi_clk),
    .aresetn(ddr3_calib_complete),
    .write_cmd(ht_s_axis_write_cmd_tdata),
    .write_cmd_valid(ht_s_axis_write_cmd_tvalid),
    .write_cmd_ready(ht_s_axis_write_cmd_tready),
    .write_data(ht_s_axis_write_tdata),
    .write_data_valid(ht_s_axis_write_tvalid),
    .write_data_ready(ht_s_axis_write_tready),
    .write_data_keep(ht_s_axis_write_tkeep),
    .write_data_last(ht_s_axis_write_tlast),
    .read_cmd(ht_s_axis_read_cmd_tdata),
    .read_cmd_valid(ht_s_axis_read_cmd_tvalid),
    .read_cmd_ready(ht_s_axis_read_cmd_tready),
    .read_data(ht_m_axis_read_tdata),
    .read_data_valid(ht_m_axis_read_tvalid),
    .read_data_keep(ht_m_axis_read_tkeep),
    .read_data_last(ht_m_axis_read_tlast),
    .read_data_ready(ht_m_axis_read_tready),
    .read_sts_data(ht_m_axis_read_sts_tdata),
    .read_sts_valid(ht_m_axis_read_sts_tvalid),
    .read_sts_ready(),
    .write_sts_data(ht_m_axis_write_sts_tdata),
    .write_sts_valid(ht_m_axis_write_sts_tvalid),
    .write_sts_ready(),
    .compare_error(ht_compare_error)
);


stream_tg #(
  .DATA_WIDTH(512),
  .KEEP_WIDTH(64),
  .START_ADDR(128),
  .START_DATA(32),
  .BTT(23'd64),
  .DRR(1'b0)
)
upd_stream_tg (
    .aclk(axi_clk),
    .aresetn(ddr3_calib_complete),
    .write_cmd(upd_s_axis_write_cmd_tdata),
    .write_cmd_valid(upd_s_axis_write_cmd_tvalid),
    .write_cmd_ready(upd_s_axis_write_cmd_tready),
    .write_data(upd_s_axis_write_tdata),
    .write_data_valid(upd_s_axis_write_tvalid),
    .write_data_ready(upd_s_axis_write_tready),
    .write_data_keep(upd_s_axis_write_tkeep),
    .write_data_last(upd_s_axis_write_tlast),
    .read_cmd(upd_s_axis_read_cmd_tdata),
    .read_cmd_valid(upd_s_axis_read_cmd_tvalid),
    .read_cmd_ready(upd_s_axis_read_cmd_tready),
    .read_data(upd_m_axis_read_tdata),
    .read_data_valid(upd_m_axis_read_tvalid),
    .read_data_keep(upd_m_axis_read_tkeep),
    .read_data_last(upd_m_axis_read_tlast),
    .read_data_ready(upd_m_axis_read_tready),
    .read_sts_data(upd_m_axis_read_sts_tdata),
    .read_sts_valid(upd_m_axis_read_sts_tvalid),
    .read_sts_ready(),
    .write_sts_data(upd_m_axis_write_sts_tdata),
    .write_sts_valid(upd_m_axis_write_sts_tvalid),
    .write_sts_ready(),
    .compare_error(upd_compare_error)
);

assign ht_m_axis_read_sts_tready = 1'b1;
assign ht_m_axis_write_sts_tready = 1'b1;

assign upd_m_axis_read_sts_tready = 1'b1;
assign upd_m_axis_write_sts_tready = 1'b1;

mem_inf  #(
    .C0_SIMULATION("FALSE"),
    .C1_SIMULATION("FALSE"),
    .C0_SIM_BYPASS_INIT_CAL("OFF"),
    .C1_SIM_BYPASS_INIT_CAL("OFF")
)
mem_inf_inst(
.clk156_25(axi_clk),
//.reset233_n(reset233_n), //active low reset signal for 233MHz clock domain
.reset156_25_n(ddr3_calib_complete),
.clk212(clk233),
.clk200(clk_ref_200),
.sys_rst(sys_rst),

//ddr3 pins
//SODIMM 0
// Inouts
.c0_ddr3_dq(c0_ddr3_dq),
.c0_ddr3_dqs_n(c0_ddr3_dqs_n),
.c0_ddr3_dqs_p(c0_ddr3_dqs_p),

// Outputs
.c0_ddr3_addr(c0_ddr3_addr),
.c0_ddr3_ba(c0_ddr3_ba),
.c0_ddr3_ras_n(c0_ddr3_ras_n),
.c0_ddr3_cas_n(c0_ddr3_cas_n),
.c0_ddr3_we_n(c0_ddr3_we_n),
.c0_ddr3_reset_n(c0_ddr3_reset_n),
.c0_ddr3_ck_p(c0_ddr3_ck_p),
.c0_ddr3_ck_n(c0_ddr3_ck_n),
.c0_ddr3_cke(c0_ddr3_cke),
.c0_ddr3_cs_n(c0_ddr3_cs_n),
.c0_ddr3_dm(c0_ddr3_dm),
.c0_ddr3_odt(c0_ddr3_odt),
.c0_ui_clk(),
.c0_init_calib_complete(c0_init_calib_complete),

//SODIMM 1
// Inouts
.c1_ddr3_dq(c1_ddr3_dq),
.c1_ddr3_dqs_n(c1_ddr3_dqs_n),
.c1_ddr3_dqs_p(c1_ddr3_dqs_p),

// Outputs
.c1_ddr3_addr(c1_ddr3_addr),
.c1_ddr3_ba(c1_ddr3_ba),
.c1_ddr3_ras_n(c1_ddr3_ras_n),
.c1_ddr3_cas_n(c1_ddr3_cas_n),
.c1_ddr3_we_n(c1_ddr3_we_n),
.c1_ddr3_reset_n(c1_ddr3_reset_n),
.c1_ddr3_ck_p(c1_ddr3_ck_p),
.c1_ddr3_ck_n(c1_ddr3_ck_n),
.c1_ddr3_cke(c1_ddr3_cke),
.c1_ddr3_cs_n(c1_ddr3_cs_n),
.c1_ddr3_dm(c1_ddr3_dm),
.c1_ddr3_odt(c1_ddr3_odt),
.c1_ui_clk(),
.c1_init_calib_complete(c1_init_calib_complete),

//toe stream interface signals
.toeTX_s_axis_read_cmd_tvalid(toeTX_s_axis_read_cmd_tvalid),
.toeTX_s_axis_read_cmd_tready(toeTX_s_axis_read_cmd_tready),
.toeTX_s_axis_read_cmd_tdata(toeTX_s_axis_read_cmd_tdata),
//read status
.toeTX_m_axis_read_sts_tvalid(toeTX_m_axis_read_sts_tvalid),
.toeTX_m_axis_read_sts_tready(toeTX_m_axis_read_sts_tready),
.toeTX_m_axis_read_sts_tdata(toeTX_m_axis_read_sts_tdata),
//read stream
.toeTX_m_axis_read_tdata(toeTX_m_axis_read_tdata),
.toeTX_m_axis_read_tkeep(toeTX_m_axis_read_tkeep),
.toeTX_m_axis_read_tlast(toeTX_m_axis_read_tlast),
.toeTX_m_axis_read_tvalid(toeTX_m_axis_read_tvalid),
.toeTX_m_axis_read_tready(toeTX_m_axis_read_tready),

//write commands
.toeTX_s_axis_write_cmd_tvalid(toeTX_s_axis_write_cmd_tvalid),
.toeTX_s_axis_write_cmd_tready(toeTX_s_axis_write_cmd_tready),
.toeTX_s_axis_write_cmd_tdata(toeTX_s_axis_write_cmd_tdata),
//write status
.toeTX_m_axis_write_sts_tvalid(toeTX_m_axis_write_sts_tvalid),
.toeTX_m_axis_write_sts_tready(toeTX_m_axis_write_sts_tready),
.toeTX_m_axis_write_sts_tdata(toeTX_m_axis_write_sts_tdata),
//write stream
.toeTX_s_axis_write_tdata(toeTX_s_axis_write_tdata),
.toeTX_s_axis_write_tkeep(toeTX_s_axis_write_tkeep),
.toeTX_s_axis_write_tlast(toeTX_s_axis_write_tlast),
.toeTX_s_axis_write_tvalid(toeTX_s_axis_write_tvalid),
.toeTX_s_axis_write_tready(toeTX_s_axis_write_tready),

.toeRX_s_axis_read_cmd_tvalid(toeRX_s_axis_read_cmd_tvalid),
.toeRX_s_axis_read_cmd_tready(toeRX_s_axis_read_cmd_tready),
.toeRX_s_axis_read_cmd_tdata(toeRX_s_axis_read_cmd_tdata),
//read status
.toeRX_m_axis_read_sts_tvalid(toeRX_m_axis_read_sts_tvalid),
.toeRX_m_axis_read_sts_tready(toeRX_m_axis_read_sts_tready),
.toeRX_m_axis_read_sts_tdata(toeRX_m_axis_read_sts_tdata),
//read stream
.toeRX_m_axis_read_tdata(toeRX_m_axis_read_tdata),
.toeRX_m_axis_read_tkeep(toeRX_m_axis_read_tkeep),
.toeRX_m_axis_read_tlast(toeRX_m_axis_read_tlast),
.toeRX_m_axis_read_tvalid(toeRX_m_axis_read_tvalid),
.toeRX_m_axis_read_tready(toeRX_m_axis_read_tready),

//write commands
.toeRX_s_axis_write_cmd_tvalid(toeRX_s_axis_write_cmd_tvalid),
.toeRX_s_axis_write_cmd_tready(toeRX_s_axis_write_cmd_tready),
.toeRX_s_axis_write_cmd_tdata(toeRX_s_axis_write_cmd_tdata),
//write status
.toeRX_m_axis_write_sts_tvalid(toeRX_m_axis_write_sts_tvalid),
.toeRX_m_axis_write_sts_tready(toeRX_m_axis_write_sts_tready),
.toeRX_m_axis_write_sts_tdata(toeRX_m_axis_write_sts_tdata),
//write stream
.toeRX_s_axis_write_tdata(toeRX_s_axis_write_tdata),
.toeRX_s_axis_write_tkeep(toeRX_s_axis_write_tkeep),
.toeRX_s_axis_write_tlast(toeRX_s_axis_write_tlast),
.toeRX_s_axis_write_tvalid(toeRX_s_axis_write_tvalid),
.toeRX_s_axis_write_tready(toeRX_s_axis_write_tready),

//ht stream interface signals
.ht_s_axis_read_cmd_tvalid(ht_s_axis_read_cmd_tvalid),
.ht_s_axis_read_cmd_tready(ht_s_axis_read_cmd_tready),
.ht_s_axis_read_cmd_tdata(ht_s_axis_read_cmd_tdata),
//read status
.ht_m_axis_read_sts_tvalid(ht_m_axis_read_sts_tvalid),
.ht_m_axis_read_sts_tready(ht_m_axis_read_sts_tready),
.ht_m_axis_read_sts_tdata(ht_m_axis_read_sts_tdata),
//read stream
.ht_m_axis_read_tdata(ht_m_axis_read_tdata),
.ht_m_axis_read_tkeep(ht_m_axis_read_tkeep),
.ht_m_axis_read_tlast(ht_m_axis_read_tlast),
.ht_m_axis_read_tvalid(ht_m_axis_read_tvalid),
.ht_m_axis_read_tready(ht_m_axis_read_tready),

//write commands
.ht_s_axis_write_cmd_tvalid(ht_s_axis_write_cmd_tvalid),
.ht_s_axis_write_cmd_tready(ht_s_axis_write_cmd_tready),
.ht_s_axis_write_cmd_tdata(ht_s_axis_write_cmd_tdata),
//write status
.ht_m_axis_write_sts_tvalid(ht_m_axis_write_sts_tvalid),
.ht_m_axis_write_sts_tready(ht_m_axis_write_sts_tready),
.ht_m_axis_write_sts_tdata(ht_m_axis_write_sts_tdata),
//write stream
.ht_s_axis_write_tdata(ht_s_axis_write_tdata),
.ht_s_axis_write_tkeep(ht_s_axis_write_tkeep),
.ht_s_axis_write_tlast(ht_s_axis_write_tlast),
.ht_s_axis_write_tvalid(ht_s_axis_write_tvalid),
.ht_s_axis_write_tready(ht_s_axis_write_tready),

//upd stream interface signals
.upd_s_axis_read_cmd_tvalid(upd_s_axis_read_cmd_tvalid),
.upd_s_axis_read_cmd_tready(upd_s_axis_read_cmd_tready),
.upd_s_axis_read_cmd_tdata(upd_s_axis_read_cmd_tdata),
//read status
.upd_m_axis_read_sts_tvalid(upd_m_axis_read_sts_tvalid),
.upd_m_axis_read_sts_tready(upd_m_axis_read_sts_tready),
.upd_m_axis_read_sts_tdata(upd_m_axis_read_sts_tdata),
//read stream
.upd_m_axis_read_tdata(upd_m_axis_read_tdata),
.upd_m_axis_read_tkeep(upd_m_axis_read_tkeep),
.upd_m_axis_read_tlast(upd_m_axis_read_tlast),
.upd_m_axis_read_tvalid(upd_m_axis_read_tvalid),
.upd_m_axis_read_tready(upd_m_axis_read_tready),

//write commands
.upd_s_axis_write_cmd_tvalid(upd_s_axis_write_cmd_tvalid),
.upd_s_axis_write_cmd_tready(upd_s_axis_write_cmd_tready),
.upd_s_axis_write_cmd_tdata(upd_s_axis_write_cmd_tdata),
//write status
.upd_m_axis_write_sts_tvalid(upd_m_axis_write_sts_tvalid),
.upd_m_axis_write_sts_tready(upd_m_axis_write_sts_tready),
.upd_m_axis_write_sts_tdata(upd_m_axis_write_sts_tdata),
//write stream
.upd_s_axis_write_tdata(upd_s_axis_write_tdata),
.upd_s_axis_write_tkeep(upd_s_axis_write_tkeep),
.upd_s_axis_write_tlast(upd_s_axis_write_tlast),
.upd_s_axis_write_tvalid(upd_s_axis_write_tvalid),
.upd_s_axis_write_tready(upd_s_axis_write_tready)
);


wire pcie_ref_clk;
   // AXI ST interface to user
 wire [63:0]      m_axis_h2c_tdata_0;
 wire             m_axis_h2c_tlast_0;
 wire             m_axis_h2c_tvalid_0;
 wire             m_axis_h2c_tready_0;
 wire [63:0]      m_axis_h2c_tdata_1;
 wire             m_axis_h2c_tlast_1;
 wire             m_axis_h2c_tvalid_1;
 wire             m_axis_h2c_tready_1;
 wire [63:0]      m_axis_h2c_tdata_2;
 wire             m_axis_h2c_tlast_2;
 wire             m_axis_h2c_tvalid_2;
 wire             m_axis_h2c_tready_2;
 wire [63:0]      m_axis_h2c_tdata_3;
 wire             m_axis_h2c_tlast_3;
 wire             m_axis_h2c_tvalid_3;
 wire             m_axis_h2c_tready_3;

 wire [63:0]      s_axis_c2h_tdata_0;
 wire             s_axis_c2h_tlast_0;
 wire             s_axis_c2h_tvalid_0;
 wire             s_axis_c2h_tready_0;
 wire [63:0]      s_axis_c2h_tdata_1;
 wire             s_axis_c2h_tlast_1;
 wire             s_axis_c2h_tvalid_1;
 wire             s_axis_c2h_tready_1;
 wire [63:0]      s_axis_c2h_tdata_2;
 wire             s_axis_c2h_tlast_2;
 wire             s_axis_c2h_tvalid_2;
 wire             s_axis_c2h_tready_2;
 wire [63:0]      s_axis_c2h_tdata_3;
 wire             s_axis_c2h_tlast_3;
 wire             s_axis_c2h_tvalid_3;
 wire             s_axis_c2h_tready_3;

   wire 		  pcie_user_clk;
   wire 		  pcie_user_resetn;
   wire 		  pcie_user_lnk_up;
   
   wire        axis_notifications_TVALID_64;
   wire        axis_notifications_TREADY_64;
   wire[63:0]  axis_notifications_TDATA_64;
   wire[7:0]   axis_notifications_TKEEP_64;
   wire[7:0]   axis_notifications_TLAST_64;


  IBUFDS_GTE2 refclk_ibuf (.O(pcie_ref_clk), .ODIV2(), .I(pcie_ref_clk_p), .CEB(1'b0), .IB(pcie_ref_clk_n));
  
assign m_axis_h2c_tready_3 = 0;

 axis_clock_converter_64b u_clk_conv_tx_req(
 .s_axis_aresetn (pcie_user_resetn       ),
 .m_axis_aresetn (aresetn                ),
 .s_axis_aclk    (pcie_user_clk          ),
 .s_axis_tvalid  (m_axis_h2c_tvalid_0    ),
 .s_axis_tready  (m_axis_h2c_tready_0    ),
 .s_axis_tdata   (m_axis_h2c_tdata_0     ),
 .s_axis_tkeep   (8'hff                  ),
 .s_axis_tlast   (m_axis_h2c_tlast_0     ),
 .m_axis_aclk    (axi_clk                ),
 .m_axis_tvalid  (axis_tx_metadata_TVALID),       
 .m_axis_tready  (axis_tx_metadata_TREADY),       
 .m_axis_tdata   (axis_tx_metadata_TDATA ),
 .m_axis_tkeep   (                       ),
 .m_axis_tlast   (                       )
);

 axis_clock_converter_64b u_clk_conv_tx_reponse(
 .s_axis_aresetn (aresetn                  ),
 .m_axis_aresetn (pcie_user_resetn         ),
 .s_axis_aclk    (axi_clk                  ),
 .s_axis_tvalid  (axis_tx_status_TVALID    ),
 .s_axis_tready  (axis_tx_status_TREADY    ),
 .s_axis_tdata   ({40'b0,axis_tx_status_TDATA} ),
 .s_axis_tlast   (1'b1                     ),
 .s_axis_tkeep   (8'hff                    ),
 .m_axis_aclk    (pcie_user_clk      ),
 .m_axis_tvalid  (s_axis_c2h_tvalid_0),       
 .m_axis_tready  (s_axis_c2h_tready_0),       
 .m_axis_tdata   (s_axis_c2h_tdata_0 ),
 .m_axis_tkeep   (                   ),
 .m_axis_tlast   (s_axis_c2h_tlast_0 )
);

 axis_clock_converter_64b u_clk_conv_tx_data(
 .s_axis_aresetn (pcie_user_resetn       ),
 .m_axis_aresetn (aresetn                ),
 .s_axis_aclk    (pcie_user_clk          ),
 .s_axis_tvalid  (m_axis_h2c_tvalid_1    ),
 .s_axis_tready  (m_axis_h2c_tready_1    ),
 .s_axis_tdata   (m_axis_h2c_tdata_1     ),
 .s_axis_tkeep   (8'hff                  ),
 .s_axis_tlast   (m_axis_h2c_tlast_1     ),
 .m_axis_aclk    (axi_clk                ),
 .m_axis_tvalid  (axis_tx_data_TVALID),       
 .m_axis_tready  (axis_tx_data_TREADY),       
 .m_axis_tdata   (axis_tx_data_TDATA ),
 .m_axis_tkeep   (axis_tx_data_TKEEP ),
 .m_axis_tlast   (axis_tx_data_TLAST )
);

 
 axis_dwidth_converter_128to64 u_data_conv_rx_notify(
.aclk           (axi_clk                ),
.aresetn        (aresetn                ),
.s_axis_tvalid  (axis_notifications_TVALID    ),
.s_axis_tready  (axis_notifications_TREADY    ),
.s_axis_tdata   ({40'b0,axis_notifications_TDATA} ),
.s_axis_tkeep   (16'hffff                     ),
.s_axis_tlast   (1'b1                         ),
.m_axis_tvalid  (axis_notifications_TVALID_64),       
.m_axis_tready  (axis_notifications_TREADY_64),       
.m_axis_tdata   (axis_notifications_TDATA_64 ),
.m_axis_tkeep   (axis_notifications_TKEEP_64 ),
.m_axis_tlast   (axis_notifications_TLAST_64 )
);

axis_clock_converter_64b u_clk_conv_rx_notify(
.s_axis_aresetn (aresetn                ),
.m_axis_aresetn (pcie_user_resetn       ),
.s_axis_aclk    (axi_clk                ),
.s_axis_tvalid  (axis_notifications_TVALID_64),
.s_axis_tready  (axis_notifications_TREADY_64),
.s_axis_tdata   (axis_notifications_TDATA_64 ),
.s_axis_tkeep   (axis_notifications_TKEEP_64 ),
.s_axis_tlast   (axis_notifications_TLAST_64 ),
.m_axis_aclk    (pcie_user_clk      ),
.m_axis_tvalid  (s_axis_c2h_tvalid_1),       
.m_axis_tready  (s_axis_c2h_tready_1),       
.m_axis_tdata   (s_axis_c2h_tdata_1 ),
.m_axis_tkeep   (                   ),
.m_axis_tlast   (s_axis_c2h_tlast_1 )
);


 axis_clock_converter_64b u_clk_conv_rx_req(
 .s_axis_aresetn (pcie_user_resetn       ),
 .m_axis_aresetn (aresetn                ),
 .s_axis_aclk    (pcie_user_clk          ),
 .s_axis_tvalid  (m_axis_h2c_tvalid_2    ),
 .s_axis_tready  (m_axis_h2c_tready_2    ),
 .s_axis_tdata   (m_axis_h2c_tdata_2     ),
 .s_axis_tkeep   (8'hff                  ),
 .s_axis_tlast   (m_axis_h2c_tlast_2     ),
 .m_axis_aclk    (axi_clk                ),
 .m_axis_tvalid  (axis_read_package_TVALID),       
 .m_axis_tready  (axis_read_package_TREADY),       
 .m_axis_tdata   (axis_read_package_TDATA ),
 .m_axis_tkeep   (                        ),
 .m_axis_tlast   (                        )
);


 axis_clock_converter_64b u_clk_conv_rx_data(
.s_axis_aresetn (aresetn                ),
.m_axis_aresetn (pcie_user_resetn       ),
.s_axis_aclk    (axi_clk                ),
.s_axis_tvalid  (axis_rx_data_TVALID    ),
.s_axis_tready  (axis_rx_data_TREADY    ),
.s_axis_tdata   (axis_rx_data_TDATA ),
.s_axis_tkeep   (axis_rx_data_TKEEP ),
.s_axis_tlast   (axis_rx_data_TLAST ),
.m_axis_aclk    (pcie_user_clk      ),
.m_axis_tvalid  (s_axis_c2h_tvalid_2),       
.m_axis_tready  (s_axis_c2h_tready_2),       
.m_axis_tdata   (s_axis_c2h_tdata_2 ),
.m_axis_tkeep   (                   ),
.m_axis_tlast   (s_axis_c2h_tlast_2 )
);
 
 axis_clock_converter_64b u_clk_conv_rx_reponse(
.s_axis_aresetn (aresetn                ),
.m_axis_aresetn (pcie_user_resetn       ),
.s_axis_aclk    (axi_clk                ),
.s_axis_tvalid  (axis_rx_metadata_TVALID    ),
.s_axis_tready  (axis_rx_metadata_TREADY    ),
.s_axis_tdata   ({48'b0,axis_rx_metadata_TDATA } ),
.s_axis_tkeep   (8'hff                      ),
.s_axis_tlast   (1'b1                       ),
.m_axis_aclk    (pcie_user_clk      ),
.m_axis_tvalid  (s_axis_c2h_tvalid_3),       
.m_axis_tready  (s_axis_c2h_tready_3),       
.m_axis_tdata   (s_axis_c2h_tdata_3 ),
.m_axis_tkeep   (                   ),
.m_axis_tlast   (s_axis_c2h_tlast_3 )
);
  


  xdma_0 xdma_0_i 
     (
      //---------------------------------------------------------------------------------------//
      //  PCI Express (pci_exp) Interface                                                      //
      //---------------------------------------------------------------------------------------//
      .sys_clk         ( pcie_ref_clk ),
      .sys_rst_n       ( pcie_sys_rst_n ),
      // Tx
      .pci_exp_txn     ( pci_exp_txn ),
      .pci_exp_txp     ( pci_exp_txp ),
      // Rx
      .pci_exp_rxn     ( pci_exp_rxn ),
      .pci_exp_rxp     ( pci_exp_rxp ),
      // AXI streaming ports
      .s_axis_c2h_tdata_0   (s_axis_c2h_tdata_0),
      .s_axis_c2h_tlast_0   (s_axis_c2h_tlast_0),
      .s_axis_c2h_tvalid_0  (s_axis_c2h_tvalid_0),
      .s_axis_c2h_tready_0  (s_axis_c2h_tready_0),
      .s_axis_c2h_tdata_1   (s_axis_c2h_tdata_1),
      .s_axis_c2h_tlast_1   (s_axis_c2h_tlast_1),
      .s_axis_c2h_tvalid_1  (s_axis_c2h_tvalid_1),
      .s_axis_c2h_tready_1  (s_axis_c2h_tready_1),
      .s_axis_c2h_tdata_2   (s_axis_c2h_tdata_2),
      .s_axis_c2h_tlast_2   (s_axis_c2h_tlast_2),
      .s_axis_c2h_tvalid_2  (s_axis_c2h_tvalid_2),
      .s_axis_c2h_tready_2  (s_axis_c2h_tready_2),
      .s_axis_c2h_tdata_3   (s_axis_c2h_tdata_3),
      .s_axis_c2h_tlast_3   (s_axis_c2h_tlast_3),
      .s_axis_c2h_tvalid_3  (s_axis_c2h_tvalid_3),
      .s_axis_c2h_tready_3  (s_axis_c2h_tready_3),
      .m_axis_h2c_tdata_0   (m_axis_h2c_tdata_0),
      .m_axis_h2c_tlast_0   (m_axis_h2c_tlast_0),
      .m_axis_h2c_tvalid_0  (m_axis_h2c_tvalid_0),
      .m_axis_h2c_tready_0  (m_axis_h2c_tready_0),
      .m_axis_h2c_tdata_1   (m_axis_h2c_tdata_1),
      .m_axis_h2c_tlast_1   (m_axis_h2c_tlast_1),
      .m_axis_h2c_tvalid_1  (m_axis_h2c_tvalid_1),
      .m_axis_h2c_tready_1  (m_axis_h2c_tready_1),
      .m_axis_h2c_tdata_2   (m_axis_h2c_tdata_2),
      .m_axis_h2c_tlast_2   (m_axis_h2c_tlast_2),
      .m_axis_h2c_tvalid_2  (m_axis_h2c_tvalid_2),
      .m_axis_h2c_tready_2  (m_axis_h2c_tready_2),
      .m_axis_h2c_tdata_3   (m_axis_h2c_tdata_3),
      .m_axis_h2c_tlast_3   (m_axis_h2c_tlast_3),
      .m_axis_h2c_tvalid_3  (m_axis_h2c_tvalid_3),
      .m_axis_h2c_tready_3  (m_axis_h2c_tready_3),

     .usr_irq_req       (0),
     .usr_irq_ack       (),
     //-- AXI Global
      .axi_aclk        ( pcie_user_clk ),
      .axi_aresetn     ( pcie_user_resetn ),
      .user_lnk_up     ( pcie_user_lnk_up )
     );



assign led = {pcie_user_lnk_up,1'b0,led_reg[5:0]};

endmodule

`default_nettype wire
 
 
