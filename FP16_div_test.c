#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include "FP16_div_algorithim.c"

float FP162float(unsigned short FP16);
int verify(unsigned short data_in1,unsigned short data_in2,FILE * p);
unsigned short float2FP16(float a);
float floatabs(float data);

int main()
{
    unsigned short data_in1,data_in2;
    int count2,error_count;
    FILE *p = fopen("report.txt","w");

    error_count = 0;                        //错误计数初始化
    data_in1 = 0x0000;
    data_in2 = 0x0001;

    while(1)
    {

        while(1)
        {
            error_count += verify(data_in1,data_in2,p);

            if(error_count >= 10)
                return 0;

            if(data_in2 == 0x7bff)
                data_in2 = 0x8001;
            else if(data_in2 == 0xfbff)
            {
                data_in2 = 0x0001;
                break;
            }
            else
                data_in2 ++;
        }

        if(data_in1 == 0x7bff)
            data_in1 = 0x8001;
        else if(data_in1 == 0xfbff)
            break;
        else
            data_in1 ++;
    }

    fprintf(p,"\nover,there are %d errors\n",error_count);
    fclose(p);

    return 0;
}



//用于验证两个操作数是否正确并将验证结果写入文件
int verify(unsigned short data_in1,unsigned short data_in2,FILE * p)
{
    float data1 = FP162float(data_in1);
    float data2 = FP162float(data_in2);
    float data_standard = FP162float(float2FP16(data1 / data2));
    float mistake;
    unsigned short data_my;
    float data_mycache;

    data_my = FP16_div(data_in1,data_in2);
    data_mycache = FP162float(data_my);

    mistake = floatabs(data_standard - data_mycache);       //计算误差

    if((mistake <= floatabs(data_standard * 0.01)))     //误差在1%以内
    {
        //fprintf(p,"inputs are %f(0x%04x),%f(0x%04x),my output is %f(0x%04x),it should be %f,pass1\n",data1,data_in1,data2,data_in2,data_mycache,data_my,data_standard);
        return 0;
    }
    else if((floatabs(data_standard) == 65504) && ((data_my & 0x7fff) == 0x7fff))     //上溢出
    {
        //fprintf(p,"inputs are %f(0x%04x),%f(0x%04x),my output is %f(0x%04x),it should overflow,pass2\n",data1,data_in1,data2,data_in2,data_mycache,data_my,data_standard);
        return 0;
    }
    else if(((data_my & 0x7fff) == 0x7fff) && (((data_in1 & 0x7fff)== 0x7fff) || ((data_in2 & 0x7fff)== 0x7fff)))       //非法操作数
    {
        //fprintf(p,"inputs are %f(0x%04x),%f(0x%04x),my output is %f(0x%04x),it has invalid input,pass3\n",data1,data_in1,data2,data_in2,data_mycache,data_my,data_standard);
        return 0;
    }
    // else if((floatabs(data_standard) <= 0000610352) && ((data_my == 0x0000) ||(data_my & 0x7fff) == 0x0400))  //下溢出
    // {
    //     return 0;
    // }
    else                                            //错误
    {
        fprintf(p,"X=%.10f(0x%04x),D=%.10f(0x%04x),Q=%.10f(0x%04x),it should be %.10f(0x%04x),fail!!!!!!!!!!\n",data1,data_in1,data2,data_in2,data_mycache,data_my,data_standard,float2FP16(data_standard));
        return 1;
    }

}



//将16位short存储的FP16转换成结构相同的float(符号、阶数、尾数相同，而不是值相同)
float FP162float(unsigned short FP16)
{
    float result;
    
    short sign = FP16 >> 15;
    short exp = (FP16 >> 10) & 0x1f;
    short rm = FP16 & 0x03ff;
    if(exp == 0)
    {
        if(rm == 0)
            exp = exp;      //exp = 0,rm = 0,0
        else
            exp = 1;        //exp = 0,rm !=0,denormal
    }
    else
    {
        rm = rm | 0x400;    //exp !=0,normal
    }

    result = rm * pow(2.0,(float)(exp - 25));
    result = sign ? -1*result : result;

    if(exp == 0)      //0x0000 is 0
    {
        //printf("FP162float:0\n");
        return 0;
    }
    else if(exp >= 31)   //0xffff is overflow、NaN
    {
        //printf("FP162float:NaN\n");
        return NAN;
    }
    else
    {
        //printf("FP162float:%f\n",result);
        return result;
    }
}

unsigned short float2FP16(float a)
{
    unsigned short rm;
    bool ifround;
    unsigned char* p = (unsigned char*)&a;
    unsigned short sign = *(p+3) >> 7;

    if(((a > 65504) || (a < -65504)))
    {
        //printf("float2FP16:overflow\n");
        return (sign << 15) | 0x7bff;
    }
    
    if(a == 0)
    {
        //printf("float2FP16:0x0000\n");
        return 0x0000;
    }

    char exp = ((*(p+3) << 1) | (*(p+2) >> 7)) - 112;

    rm = ((*(p+2) & 0x7f) << 3) | (*(p+1) >> 5) | 0x400;

    if(exp >= 1)    //normal
    {
        rm = rm;
        ifround = *(p+1) & 0x10;
    }
    else if(exp >= -10)      //denormal
    {
        switch (exp)
        {
            case 0:{ifround = rm & 0x01;rm = rm >> 1;}break;
            case -1:{ifround = (rm >> 1) & 0x01;rm = rm >> 2;}break;
            case -2:{ifround = (rm >> 2) & 0x01;rm = rm >> 3;}break;
            case -3:{ifround = (rm >> 3) & 0x01;rm = rm >> 4;}break;
            case -4:{ifround = (rm >> 4) & 0x01;rm = rm >> 5;}break;
            case -5:{ifround = (rm >> 5) & 0x01;rm = rm >> 6;}break;
            case -6:{ifround = (rm >> 6) & 0x01;rm = rm >> 7;}break;
            case -7:{ifround = (rm >> 7) & 0x01;rm = rm >> 8;}break;
            case -8:{ifround = (rm >> 8) & 0x01;rm = rm >> 9;}break;
            case -9:{ifround = (rm >> 9) & 0x01;rm = rm >> 10;}break;
            case -10:{ifround = (rm >> 10) & 0x01;rm = rm >> 11;}break;
        }
        exp = 0;
    }
    else
    {
        exp = 0;sign = 0;rm = 0;ifround = 0;
    }

    if(ifround)         //round
        rm += 1;

    if((exp == 0) && ((rm >> 10) == 0x01))  //denormal to normal
    {
        exp = 1;
    }
    else if((rm >> 11) == 0x01)          //carry
    {
        exp +=1;
        rm = rm >> 1;
    }

    unsigned short result = (rm & 0x3ff) | ((exp & 0x1f) << 10) | (sign << 15);

    //printf("float2FP16:0x%x\n",result);


    return result;
}


float floatabs(float data)     //c自带的abs只适用于整形
{
    return (data < 0) ? -1*data : data;
}