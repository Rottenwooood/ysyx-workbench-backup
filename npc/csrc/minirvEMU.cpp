#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

static uint32_t PC = 0;
static uint32_t R[32];
static uint8_t M[64];

// I型：bits[31:20]）
static int32_t imm_i(uint32_t inst){
	uint32_t imm = inst >> 20;
	if(imm & 0x800) imm |= 0xFFFFF000; // 符号扩展为负数
	return (int32_t)imm;
}
// S型：bits[31:25] | bits[11:7]
static int32_t imm_s(uint32_t inst){
	uint32_t imm = ((inst >> 25) << 5) | ((inst >> 7) & 0x1F);
	if(imm & 0x800) imm |= 0xFFFFF000; // 符号扩展为负数
	return (int32_t)imm;
}
// U型：bits[31:12]
static int32_t imm_u(uint32_t inst){
	return (int32_t)(inst & 0xFFFFF000);
}

void ref_inst_cycle(){
	//取指
	uint32_t inst = M[PC] | (M[PC+1] << 8) | (M[PC+2] << 16) | (M[PC+3] << 24);
	//译码
	uint8_t opcode = inst & 0x7F;
	uint8_t func3 = (inst >> 12) & 0x07;
	uint8_t rd  = (inst >> 7)  & 0x1F;
	uint8_t rs1 = (inst >> 15) & 0x1F;
	uint8_t rs2 = (inst >> 20) & 0x1F;

	int jumped = 0;

	switch(opcode){
		case 0x13:								//op-imm
			if(func3 == 0) R[rd] = R[rs1] + imm_i(inst);   //addi
			break;
		case 0x67:								//jalr
			if(func3 == 0){
				R[rd] = PC + 4;
				PC = (R[rs1] + imm_i(inst)) & ~1;
				jumped = 1;
			}
			break;
		case 0x33:								//op
			if(func3 == 0) R[rd] = R[rs1] + R[rs2];        //add
			break;
		case 0x37:								//lui
			R[rd] = (inst & 0xFFFFF000);
			break;
		case 0x03:								//load
			if(func3 == 2){						//lw
				uint32_t a = R[rs1] + imm_i(inst);
				R[rd] = M[a] | M[a+1]<<8 | M[a+2]<<16 | M[a+3]<<24;
			}else if(func3 == 4){				//lbu
				R[rd] = M[R[rs1] + imm_i(inst)];
			}
			break;
		case 0x23:								//store
			if(func3 == 2){						//sw
				uint32_t a = R[rs1] + imm_s(inst);
				for(int i = 0;i < 4;i++) M[a + i] = (R[rs2] >> (i*8)) & 0xFF;
			}else if(func3 == 0){				//sb
				M[R[rs1] + imm_s(inst)] = R[rs2] & 0xFF;
			}
			break;
		case 0x73:								//SYSTEM
			if(inst == 0x00100073){				//ebreak
				printf("EBREAK: program terminates correctly\n");
				exit(0);
			}
			break;
	}
	printf("PC = %03u inst = %08x R1=%03x R2=%03x R3=%03x R4=%03x R5=%03x R6=%03x R7=%03x  M30=%03x M34=%02x%02x%02x%02x\n",
			PC, inst, R[1], R[2], R[3], R[4], R[5], R[6], R[7],
			M[0x30], M[0x34], M[0x35], M[0x36], M[0x37]);
	//PC+4
	if(!jumped) PC = PC + 4;
}


uint32_t *ref_get_regs(){
	return R;
}

uint32_t ref_get_pc(){
	return PC;
}


