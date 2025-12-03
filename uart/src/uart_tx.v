module uart_tx
#(
    parameter UART_BPS = 115200,        //串口波特率
    parameter CLK_FREQ = 50_000_000   //时钟频率
)
(
    input wire sys_clk,      //系统时钟50MHz
    input wire sys_rst_n,    //全局复位
    input wire [7:0] pi_data,//模块输入的8bit数据
    input wire pi_flag,      //并行数据有效标志信号
    output reg tx,           //串转并后的1bit数据
    output reg work_en       // 发送模块工作状态输出
);

//localparam define
localparam BAUD_CNT_MAX = CLK_FREQ/UART_BPS;

//reg define
reg [12:0] baud_cnt;
reg bit_flag;
reg [3:0] bit_cnt;

//work_en:发送数据工作使能信号
always@(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)
        work_en <= 1'b0;
    else if(pi_flag == 1'b1)
        work_en <= 1'b1;
    else if((bit_flag == 1'b1) && (bit_cnt == 4'd9))
        work_en <= 1'b0;
end

//baud_cnt:波特率计数器计数
always@(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)
        baud_cnt <= 13'b0;
    else if((baud_cnt == BAUD_CNT_MAX - 1) || (work_en == 1'b0))
        baud_cnt <= 13'b0;
    else if(work_en == 1'b1)
        baud_cnt <= baud_cnt + 1'b1;
end

//bit_flag:当baud_cnt计数器计数到1时让bit_flag拉高一个时钟的高电平
always@(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)
        bit_flag <= 1'b0;
    else if(baud_cnt == 13'd1)
        bit_flag <= 1'b1;
    else
        bit_flag <= 1'b0;
end

//bit_cnt:数据位数个数计数，10个有效数据（含起始位和停止位）到来后计数器清零
always@(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)
        bit_cnt <= 4'b0;
    else if((bit_flag == 1'b1) && (bit_cnt == 4'd9))
        bit_cnt <= 4'b0;
    else if((bit_flag == 1'b1) && (work_en == 1'b1))
        bit_cnt <= bit_cnt + 1'b1;
end

//tx:输出数据在满足rs232协议（起始位为0，停止位为1）的情况下一位一位输出
always@(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)
        tx <= 1'b1; //空闲状态时为高电平
    else if(bit_flag == 1'b1)
        case(bit_cnt)
            0 : tx <= 1'b0;          // 起始位
            1 : tx <= pi_data[0];     // 数据位0
            2 : tx <= pi_data[1];     // 数据位1
            3 : tx <= pi_data[2];     // 数据位2
            4 : tx <= pi_data[3];     // 数据位3
            5 : tx <= pi_data[4];     // 数据位4
            6 : tx <= pi_data[5];     // 数据位5
            7 : tx <= pi_data[6];     // 数据位6
            8 : tx <= pi_data[7];     // 数据位7
            9 : tx <= 1'b1;          // 停止位
            default : tx <= 1'b1;
        endcase
end

endmodule
