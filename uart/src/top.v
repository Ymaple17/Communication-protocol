module top
#(
    parameter UART_BPS = 115200,        //串口波特率
    parameter CLK_FREQ = 50_000_000   //时钟频率
)
(
    input wire sys_clk,      //系统时钟
    input wire sys_rst_n,    //全局复位
    input wire rx,           //串口接收
    output wire tx,          //串口发送1
    output wire tx2          //串口发送2
);

// 内部信号定义
wire [7:0] rx_data;
wire rx_flag;

// tx 通道信号
reg [7:0] tx_data;
reg tx_flag;

// tx2 通道信号
reg [7:0] tx2_data;
reg tx2_flag;

// 实例化串口接收模块
uart_rx #(
    .UART_BPS(UART_BPS),
    .CLK_FREQ(CLK_FREQ)
) u_uart_rx (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .rx(rx),
    .po_data(rx_data),
    .po_flag(rx_flag)
);

// 数据分流逻辑
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 1'b0) begin
        tx_data <= 8'b0;
        tx_flag <= 1'b0;
        tx2_data <= 8'b0;
        tx2_flag <= 1'b0;
    end
    else if (rx_flag == 1'b1) begin
        // 默认先拉低使能信号
        tx_flag <= 1'b0;
        tx2_flag <= 1'b0;

        // 如果是 0x2c 从 tx 发送
        if (rx_data == 8'h2c) begin
            tx_data <= rx_data;
            tx_flag <= 1'b1;
        end
        else if ( rx_data == 8'h37) begin
            tx2_data <= rx_data;
            tx2_flag <= 1'b1;
        end
    end
    else begin
        tx_flag <= 1'b0;
        tx2_flag <= 1'b0;
    end
end

// 实例化串口发送模块 1 (输出到 tx)
uart_tx #(
    .UART_BPS(UART_BPS),
    .CLK_FREQ(CLK_FREQ)
) u_uart_tx (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .pi_data(tx_data),
    .pi_flag(tx_flag),
    .tx(tx),
    .work_en() 
);

// 实例化串口发送模块 2 (输出到 tx2)
uart_tx #(
    .UART_BPS(UART_BPS),
    .CLK_FREQ(CLK_FREQ)
) u_uart_tx2 (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .pi_data(tx2_data),
    .pi_flag(tx2_flag),
    .tx(tx2),
    .work_en() 
);

endmodule
