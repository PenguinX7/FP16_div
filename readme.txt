该工程实现FP16规格化数相除，输入FP16规格化数
状态机式，工作45个周期

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
report.txt是验证报告
由于全部验证内容太多txt写不下，采用半随机验证。即随机一个被除数data_dividend，除数data_divisor采用
所有FP16合理的可能（0，min~max，Inf，包括正负）进行运算验证然后将随机的data_dividend取反，再重复，
结果报告写入report.txt