#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "fixedptc.h"

void fixedpt_print(fixedpt A)
{
	char num[20];

	fixedpt_str(A, num, -2);
	printf("%s",num);
}

void fixedpt_printn(fixedpt A)
{
	fixedpt_print(A);
	printf("\n");
}

int main() {

	fixedpt A,B,C;
	printf("Using %d-bit precision, %d for int, %d for frac.\n", FIXEDPT_BITS, FIXEDPT_WBITS, FIXEDPT_FBITS);

	puts("");

	printf("The most precise number: "); fixedpt_printn(1);	// 最大精度
	printf("The biggest integer: "); fixedpt_printn(0x7fffff00);	//最大数。
	printf("The biggest number(NaN): "); fixedpt_printn(0x7fffffff);	//最大数。
	printf("Random number: "); fixedpt_printn(fixedpt_rconst(143.125));
	printf("PI: "); fixedpt_printn(FIXEDPT_PI);
	printf("e: "); fixedpt_printn(FIXEDPT_E);

	puts("");

	A = fixedpt_rconst(2.5); B = fixedpt_fromint(3); C = fixedpt_add(A, B);
	fixedpt_print(A); printf("+"); fixedpt_print(B); printf("="); fixedpt_printn(C);
	
	A = fixedpt_rconst(3.91); B = fixedpt_rconst(22.7); C = fixedpt_muli(A, 22.7);
	fixedpt_print(A); printf("*"); fixedpt_print(B); printf("="); fixedpt_printn(C);

	A = fixedpt_rconst(1.979); B = fixedpt_rconst(4.023); C = fixedpt_divi(A, 4.023);
	fixedpt_print(A); printf("/"); fixedpt_print(B); printf("="); fixedpt_printn(C);

	printf("exp(1)="); fixedpt_printn(fixedpt_exp(FIXEDPT_ONE));
	printf("sqrt(pi)="); fixedpt_printn(fixedpt_sqrt(FIXEDPT_PI));
	printf("sqrt(25)="); fixedpt_printn(fixedpt_sqrt(fixedpt_rconst(25)));
	printf("sin(pi/2)="); fixedpt_printn(fixedpt_sin(FIXEDPT_HALF_PI));
	printf("sin(3.5*pi)="); fixedpt_printn(fixedpt_sin(fixedpt_mul(fixedpt_rconst(3.5), FIXEDPT_PI)));
	printf("4^3.5="); fixedpt_printn(fixedpt_pow(fixedpt_rconst(4), fixedpt_rconst(3.5)));
	printf("4^0.5="); fixedpt_printn(fixedpt_pow(fixedpt_rconst(4), fixedpt_rconst(0.5)));

	puts("");

	printf("ceil(0.979)=");fixedpt_print(fixedpt_ceil(fixedpt_rconst(0.979)));
	printf(",ceil(-0.979)=");fixedpt_printn(fixedpt_ceil(fixedpt_rconst(-0.979)));
	printf("floor(0.979)=");fixedpt_print(fixedpt_floor(fixedpt_rconst(0.979)));
	printf(",floor(-0.979)=");fixedpt_printn(fixedpt_floor(fixedpt_rconst(-0.979)));

	printf("floor(-Nan)=");fixedpt_printn(fixedpt_floor(0x80000001));
	printf("floor(+Nan)=");fixedpt_printn(fixedpt_floor(0x7fffffff));
	printf("floor(-0)=");fixedpt_printn(fixedpt_floor(fixedpt_rconst(-0)));
	printf("floor(+0)=");fixedpt_printn(fixedpt_floor(fixedpt_rconst(+0)));
	printf("floor(-3)=");fixedpt_printn(fixedpt_floor(fixedpt_rconst(-3)));	// integer
	printf("floor(+3)=");fixedpt_printn(fixedpt_floor(fixedpt_rconst(+3))); // integer

	printf("ceil(-Nan)=");fixedpt_printn(fixedpt_ceil(0x80000001));
	printf("ceil(+Nan)=");fixedpt_printn(fixedpt_ceil(0x7fffffff));
	printf("ceil(-0)=");fixedpt_printn(fixedpt_ceil(fixedpt_rconst(-0)));
	printf("ceil(+0)=");fixedpt_printn(fixedpt_ceil(fixedpt_rconst(+0)));
	printf("ceil(-3)=");fixedpt_printn(fixedpt_ceil(fixedpt_rconst(-3))); // integer
	printf("ceil(+3)=");fixedpt_printn(fixedpt_ceil(fixedpt_rconst(+3))); // integer

	puts("");
	
	printf("abs(-3.291238)=");fixedpt_printn(fixedpt_abs(fixedpt_rconst(-3.291238)));
	printf("abs(-2138.438)=");fixedpt_printn(fixedpt_abs(fixedpt_rconst(-2138.438)));
	
	return (0);
}