`timescale 1ns/1ns

module tb_spi_simple();

// Parameters
parameter WORD_SIZE = 8;
parameter CLK_PERIOD = 20; // 50MHz clock

// Signals
reg                     sclk;
reg                     rst_n;
reg                     tx_en;
reg                     rx_en;
reg [WORD_SIZE-1:0]     data_in;
reg                     data_vaild;
wire [WORD_SIZE-1:0]    data_out;
wire                    tx_done;
wire                    rx_done;
wire                    spi_cs_n;
wire                    spi_clk;
wire                    spi_mosi;
reg                     spi_miso;

// Instantiate DUT
spi_module #(
    .WORD_SIZE(WORD_SIZE)
) dut (
    .sclk(sclk),
    .rst_n(rst_n),
    .tx_en(tx_en),
    .rx_en(rx_en),
    .data_in(data_in),
    .data_vaild(data_vaild),
    .data_out(data_out),
    .tx_done(tx_done),
    .rx_done(rx_done),
    .spi_cs_n(spi_cs_n),
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_miso(spi_miso)
);

// Clock generation
initial begin
    sclk = 0;
    forever #(CLK_PERIOD/2) sclk = ~sclk;
end

// Test stimulus
initial begin
    // Initialize signals
    rst_n = 0;
    tx_en = 0;
    rx_en = 0;
    data_in = 0;
    data_vaild = 0;
    spi_miso = 0;
    
    // Reset
    #(CLK_PERIOD*2);
    rst_n = 1;
    #(CLK_PERIOD*2);
    
    // Test 1: Transmit data (LSB first: 0xA5 = 10100101)
    $display("========== Test 1: TX Mode (LSB First) ==========");
    $display("Transmitting data: 0x%h (binary: %b)", 8'hA5, 8'hA5);
    data_in = 8'hA5;
    data_vaild = 1;
    #(CLK_PERIOD);
    data_vaild = 0;
    tx_en = 1;
    
    // Wait for transmission to complete
    wait(tx_done);
    #(CLK_PERIOD*2);
    tx_en = 0;
    #(CLK_PERIOD*5);
    $display("TX Done!");
    $display("");
    
    // Test 2: Transmit another data (0x3C = 00111100)
    $display("========== Test 2: TX Mode (Another Data) ==========");
    $display("Transmitting data: 0x%h (binary: %b)", 8'h3C, 8'h3C);
    data_in = 8'h3C;
    data_vaild = 1;
    #(CLK_PERIOD);
    data_vaild = 0;
    tx_en = 1;
    
    wait(tx_done);
    #(CLK_PERIOD*2);
    tx_en = 0;
    #(CLK_PERIOD*5);
    $display("TX Done!");
    $display("");
    
    // Test 3: Receive data (simulate receiving 0xC6 = 11000110, LSB first)
    $display("========== Test 3: RX Mode (LSB First) ==========");
    $display("Receiving data: 0x%h (binary: %b)", 8'hC6, 8'hC6);
    rx_en = 1;
    
    // Simulate slave sending data LSB first: C6 = 11000110
    // LSB first order: 0,1,1,0,0,0,1,1
    fork
        begin
            @(negedge spi_clk) spi_miso = 0; // bit 0
            @(negedge spi_clk) spi_miso = 1; // bit 1
            @(negedge spi_clk) spi_miso = 1; // bit 2
            @(negedge spi_clk) spi_miso = 0; // bit 3
            @(negedge spi_clk) spi_miso = 0; // bit 4
            @(negedge spi_clk) spi_miso = 0; // bit 5
            @(negedge spi_clk) spi_miso = 1; // bit 6
            @(negedge spi_clk) spi_miso = 1; // bit 7
        end
    join_none
    
    wait(rx_done);
    #(CLK_PERIOD*2);
    $display("Received data: 0x%h (binary: %b)", data_out, data_out);
    if(data_out == 8'hC6) begin
        $display("RX Test PASSED!");
    end
    else begin
        $display("RX Test FAILED! Expected: 0xC6, Got: 0x%h", data_out);
    end
    $display("");
    
    rx_en = 0;
    #(CLK_PERIOD*5);
    
    // Test 4: Receive another data (0x5A = 01011010)
    $display("========== Test 4: RX Mode (Another Data) ==========");
    $display("Receiving data: 0x%h (binary: %b)", 8'h5A, 8'h5A);
    rx_en = 1;
    
    // LSB first order for 5A = 01011010: 0,1,0,1,1,0,1,0
    fork
        begin
            @(negedge spi_clk) spi_miso = 0; // bit 0
            @(negedge spi_clk) spi_miso = 1; // bit 1
            @(negedge spi_clk) spi_miso = 0; // bit 2
            @(negedge spi_clk) spi_miso = 1; // bit 3
            @(negedge spi_clk) spi_miso = 1; // bit 4
            @(negedge spi_clk) spi_miso = 0; // bit 5
            @(negedge spi_clk) spi_miso = 1; // bit 6
            @(negedge spi_clk) spi_miso = 0; // bit 7
        end
    join_none
    
    wait(rx_done);
    #(CLK_PERIOD*2);
    $display("Received data: 0x%h (binary: %b)", data_out, data_out);
    if(data_out == 8'h5A) begin
        $display("RX Test PASSED!");
    end
    else begin
        $display("RX Test FAILED! Expected: 0x5A, Got: 0x%h", data_out);
    end
    $display("");
    
    rx_en = 0;
    #(CLK_PERIOD*10);
    
    $display("========== All Tests Completed ==========");
    $finish;
end

// Monitor SPI signals
initial begin
    $monitor("Time=%0t | rst_n=%b | tx_en=%b | rx_en=%b | spi_cs_n=%b | spi_clk=%b | spi_mosi=%b | spi_miso=%b | tx_done=%b | rx_done=%b", 
             $time, rst_n, tx_en, rx_en, spi_cs_n, spi_clk, spi_mosi, spi_miso, tx_done, rx_done);
end

// Generate waveform dump
// initial begin
//     $dumpfile("tb_spi_simple.vcd");
//     $dumpvars(0, tb_spi_simple);
// end

endmodule
