

#define S3C2440_MPLL_200MHZ     ((0x5c<<12)|(0x04<<4)|(0x02))
#define S3C2440_MPLL_400MHZ     ((0x5c<<12)|(0x01<<4)|(0x01))

#define MEM_CTL_BASE            0x48000000
.text
.global _start

_start:
    /* 1.关闭看门狗 */
	ldr r0, =0x53000000
	mov r1, #0
	str r1, [r0]
	/* 2.设置时钟 CLKDIVN = 0x4c000014*/
	ldr r0, =0x4c000014
	mov r1, #0x05	//FCLK : HCLK:PCLK = 1:2:4, HDIVN = 1, PDIVN = 1
	str r1, [r0]
	/* 设置成异步模式 */
	mrc p15, 0, r1, c1, c0, 0
	orr r1, r1, #0xc000000
	mcr p15, 0, r1, c1, c0, 0

	/* MPLL 0x4c000004 */
	ldr r0, =0x4c000004
	ldr r1, =S3C2440_MPLL_400MHZ
	str r1, [r0]

	/* 启动ICACHE */
	mrc p15, 0, r0, c1, c0, 0	@ read control reg
	orr r0, r0, #(1<<12)
	mcr	p15, 0, r0, c1, c0, 0   @ write it back
	
	/* 3.初始化SDRAM */
	ldr r0, =MEM_CTL_BASE
	adr r1, sdram_config /* 得到当前地址 */
	add r3, r0, #(13*4)
1:	
	ldr r2, [r1], #4	/* r1地址里面的内容写到r2里面， r1加4 */
	str r2, [r0], #4	/* r2-> r0地址， r0 + 4 */
	cmp r0, r3
	bne 1b				/* f代表跳到前面的1标号， b跳到后面的1标号 */
	/* 4.重定位 :把代码从flash拷贝到他的连接地址*/
	ldr sp, =0x34000000 
	bl nand_init
	/* r0表示第一个参数, r1表示第二个参数, r2表示第三个参数 */
	mov r0, #0
	ldr r1, =_start
	ldr r2, =__bss_start
	sub r2, r2, r1
	bl copy_code_sdram
	bl clear_bss
	/* 5.执行main */
	//bl main /* 相对跳转 */
	ldr lr, =halt	/* 假设main可以返回 */
	ldr pc, =main
halt:
	b halt

sdram_config:
	.long 0x22011110	 //BWSCON
	.long 0x00000700	 //BANKCON0
	.long 0x00000700	 //BANKCON1
	.long 0x00000700	 //BANKCON2
	.long 0x00000700	 //BANKCON3  
	.long 0x00000700	 //BANKCON4
	.long 0x00000700	 //BANKCON5
	.long 0x00018005	 //BANKCON6
	.long 0x00018005	 //BANKCON7
	.long 0x008C04F4	 //REFLAH
	.long 0x000000B1	 //BANKSIZE
	.long 0x00000030	 //MRSRB6
	.long 0x00000030	 //MRSRB7
	
	
