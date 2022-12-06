#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>



//不恢复余数除法
int FP16_div1(short data_dividend,short data_divisor)  //11bit
{
    short n = 11;
    long D = data_divisor << n;//23bit
    long A = data_dividend;     //23bit

    while(n > 0)
    {
        if(A < 0)
        {
            A = A << 1;
            A = A + D;
        }
        else
        {
            A = A << 1;
            A = A - D;
        }
        if(A < 0)
        {
            A = A & 0xfffffffe;
        }
        else
        {
            A = A | 0x00000001;
        }
        n = n - 1;
    }

    return (long)(A & 0x7ff);
}



//SRT除法
long FP16_div2(long long data_dividend,long long data_divisor)  //11bit
{
    short n = 21;
    long long D = data_divisor << n;//23bit//long overflow
    long long A = data_dividend;     //23bit
    long q = 0;

    while(n > 0)
    {
        if((A) < (-1 * D >> 1))
        {
            A = A << 1;
            A = A + D;
            q = (q << 1) - 1;
        }
        else if((A) >= (D >> 1))
        {
            A = A << 1;
            A = A - D;
            q = (q << 1) + 1;
        }
        else
        {
            A = A << 1;
            q = q << 1;
        }
        
        n = n - 1;
        
    }

    //return (long)(A & 0x00f);
    return q;
}



//FP16规格化格式的除法
unsigned short FP16_div(unsigned short data_dividend,unsigned short data_divisor)
{
    unsigned short sign_x,sign_d,sign_q;
    short exp_x,exp_d,exp_q;
    long long rm_x,rm_d;
    bool overflow;
    short n = 21;
    short rm_q = 0;

    //state2:input check
    sign_x = data_dividend >> 15;
    sign_d = data_divisor >> 15;
    exp_x = (data_dividend >> 10) & 0x001f;
    exp_d = (data_divisor >> 10) & 0x001f;
    if(((data_divisor & 0x7fff) == 0x0000) || (((data_dividend >> 10) & 0x1f) == 0x1f) || (((data_divisor >> 10) & 0x1f) == 0x1f))  //data_divisor = 0 || data_dividend overflow || data_divisor overflow
    {
        overflow = 1;
    }
    else if((data_dividend & 0x7fff) == 0x0000) //data_dividend = 0
    {
        overflow = 0;
        rm_x = 0;
        rm_d = (data_divisor & 0x03ff | 0x0400) << 21;
    }
    else
    {
        overflow = 0;
        rm_x = (long long)(data_dividend & 0x03ff | 0x0400) << 10;
        rm_d = (long long)(data_divisor & 0x03ff | 0x0400) << 21;
    }

    //state3:calculate exp,sign
    if(overflow)
    {}
    else
    {
        sign_q = (unsigned short)((bool)sign_x ^ (bool)sign_d);     //sign_x ^ sign_d
        exp_q = exp_x - exp_d + 15;
    }

    //state4 & 5:calculate rm
    while(n > 0)
    {
        if((rm_x) < (-1 * rm_d >> 1))
        {
            rm_x = rm_x << 1;
            rm_x = rm_x + rm_d;
            rm_q = (rm_q << 1) - 1;
        }
        else if((rm_x) >= (rm_d >> 1))
        {
            rm_x = rm_x << 1;
            rm_x = rm_x - rm_d;
            rm_q = (rm_q << 1) + 1;
        }
        else
        {
            rm_x = rm_x << 1;
            rm_q = rm_q << 1;
        }     
        n = n - 1;   
    }



    //state6:normalize
    if(overflow)
    {

    }
    else
    {
        if(((rm_q >> 10) & 0x0001)==0x0001)     //rm_q[10] = 1
        {
            rm_q = rm_q;
            exp_q = exp_q;
        }
        else if(((rm_q >> 9) & 0x0001)==0x0001)                                   //rm_q[10] = 0,rm_q[9] = 1
        {
            rm_q = rm_q << 1;
            exp_q = exp_q - 1;
        }
        else                                                //rm_q = 0
        {
            rm_q = 0;
            exp_q = 0;
        }
    }

    //state7:output
    if(overflow || (exp_q >30))
        return (sign_q << 15) | 0x7fff;
    else if((exp_q < 1) || (rm_q == 0x000))
        return 0x0000;
    else
        return (sign_q << 15) | ((exp_q & 0x1f) << 10) | (rm_q & 0x3ff);

}

int main()
{
    long result = FP16_div(0x5543 ,0x3e82);
    return 0;

}