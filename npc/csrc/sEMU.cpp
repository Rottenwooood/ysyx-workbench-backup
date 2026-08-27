#include <stdint.h>
#include <stdio.h>
static uint8_t PC = 0;
static uint8_t R[4];
static uint8_t M[16] = {
	0x8A, // li r0 10
	0x91, // li r1 1
	0xA1, // li r2 1
	0xB1, // li r3 1
	0x2B, // add r2 r2 r3
	0x16, // add r1 r1 r2
	0xD2, // bner0 r2 04
	0x41, // out r1
};

void ref_inst_cycle(){
	//取指
	uint8_t inst = M[PC];
	//译码
	uint8_t opcode = (inst >> 6) & 0x03;
	switch(opcode){
		case 0:R[(inst >> 4) & 0x03] = R[(inst >> 2) & 0x03] + R[(inst) & 0x03];break;
		case 1:printf("%d\n", R[inst & 0x03]);break;
		case 2:R[(inst >> 4) & 0x03] = inst & 0x0F;break;
		case 3:{if(R[0]!=R[inst & 0x03]) PC = (inst >> 2) & 0x0F;
		        else PC = PC + 1;}break;
	}
	//更新PC
	if(opcode != 3)PC = PC + 1;
}

uint8_t *ref_get_regs(){
	return R;
}

uint8_t ref_get_pc(){
	return PC;
}
