该工程实现FP16(支持规格化和非规格化)相除，输入FP16规格化数
状态机式，工作37个周期

.v和_tb.v是v文件及其测试文件
.v模块端口功能如下
data_dividend	被除数
data_divisor	除数
clk		时钟，上升沿触发
rst		复位信号，高电平有效
idle		空闲信号，高电平有效
input_valid	输入有效信号，高电平有效
data_q		输出结果(商)
output_update	输出有效信号，高电平有效

_algorithim.c是算法的C语言实现，方便理解算法并提供测试雏形
_algorithim.docx是关于_algorithim.c的文档解释

_test.c是软件测试文件，调用_algorithim.c中的算法函数进行验证
report.txt是验证报告，穷尽所有合法输入的全覆盖验证，将错误信息写入report.txt，所以报告中没有任何信息才是正确的