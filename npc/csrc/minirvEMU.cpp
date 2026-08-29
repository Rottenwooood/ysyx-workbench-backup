#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define PMEM_BASE  0x80000000u
#define PMEM_SIZE  (128u * 1024u * 1024u)
#define REF_M(addr) M[(addr) - PMEM_BASE]

static uint32_t PC = PMEM_BASE;
static uint32_t R[32];
static uint8_t M[PMEM_SIZE];

void ref_load_mem(const uint8_t *img, int size){
	for(int i = 0;i < size && i < PMEM_SIZE;i++) M[i] = img[i];
}

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
	uint32_t inst = REF_M(PC) | (REF_M(PC+1) << 8) | (REF_M(PC+2) << 16) | (REF_M(PC+3) << 24);
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
				uint32_t target = (R[rs1] + imm_i(inst)) & ~1;  // 先算目标(用旧 rs1), 避免 rd==rs1 时被覆盖
				R[rd] = PC + 4;
				PC = target;
				jumped = 1;
			}
			break;
		case 0x33:								//op
			if(func3 == 0) R[rd] = R[rs1] + R[rs2];        //add
			break;
		case 0x37:								//lui
			R[rd] = imm_u(inst);
			break;
		case 0x03:								//load
			if(func3 == 2){						//lw
				uint32_t a = R[rs1] + imm_i(inst);
				R[rd] = REF_M(a) | REF_M(a+1)<<8 | REF_M(a+2)<<16 | REF_M(a+3)<<24;
			}else if(func3 == 4){				//lbu
				R[rd] = REF_M(R[rs1] + imm_i(inst));
			}
			break;
		case 0x23:								//store
			if(func3 == 2){						//sw
				uint32_t a = R[rs1] + imm_s(inst);
				for(int i = 0;i < 4;i++) REF_M(a + i) = (R[rs2] >> (i*8)) & 0xFF;
			}else if(func3 == 0){				//sb
				REF_M(R[rs1] + imm_s(inst)) = R[rs2] & 0xFF;
			}
			break;
		case 0x73:								//SYSTEM
			if(inst == 0x00100073){				//ebreak
				printf("EBREAK: program terminates correctly\n");
				// 结束仿真由 RTL 通过 DPI-C 的 sim_finish() 通知,
				// 这里不再 exit()
			}
			break;
	}
#ifdef NPC_TRACE
	printf("PC = %08x inst = %08x R1=%08x R2=%08x R3=%08x R4=%08x R5=%08x R6=%08x R7=%08x\n",
			PC, inst, R[1], R[2], R[3], R[4], R[5], R[6], R[7]);
#endif
	//PC+4
	if(!jumped) PC = PC + 4;
}


uint32_t *ref_get_regs(){
	return R;
}

uint32_t ref_get_pc(){
	return PC;
}


