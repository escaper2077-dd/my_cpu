
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
_entry:
        # set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + ((hartid + 1) * 4096)
        la sp, stack0
    80000000:	0000b117          	auipc	sp,0xb
    80000004:	9d010113          	addi	sp,sp,-1584 # 8000a9d0 <stack0>
        li a0, 1024*4
    80000008:	00001537          	lui	a0,0x1
        csrr a1, mhartid
    8000000c:	f14025f3          	csrr	a1,mhartid
        addi a1, a1, 1
    80000010:	00158593          	addi	a1,a1,1
        mul a0, a0, a1
    80000014:	02b50533          	mul	a0,a0,a1
        add sp, sp, a0
    80000018:	00a10133          	add	sp,sp,a0
        # jump to start() in start.c
        call start
    8000001c:	04c000ef          	jal	ra,80000068 <start>

0000000080000020 <spin>:
spin:
        j spin
    80000020:	0000006f          	j	80000020 <spin>

0000000080000024 <timerinit>:
}

// ask each hart to generate timer interrupts.
void
timerinit()
{
    80000024:	ff010113          	addi	sp,sp,-16
    80000028:	00813423          	sd	s0,8(sp)
    8000002c:	01010413          	addi	s0,sp,16
#define MIE_STIE (1L << 5)  // supervisor timer
static inline uint64
r_mie()
{
  uint64 x;
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000030:	304027f3          	csrr	a5,mie
  // enable supervisor-mode timer interrupts.
  w_mie(r_mie() | MIE_STIE);
    80000034:	0207e793          	ori	a5,a5,32
}

static inline void 
w_mie(uint64 x)
{
  asm volatile("csrw mie, %0" : : "r" (x));
    80000038:	30479073          	csrw	mie,a5
static inline uint64
r_menvcfg()
{
  uint64 x;
  // asm volatile("csrr %0, menvcfg" : "=r" (x) );
  asm volatile("csrr %0, 0x30a" : "=r" (x) );
    8000003c:	30a027f3          	csrr	a5,0x30a
  
  // enable the sstc extension (i.e. stimecmp).
  w_menvcfg(r_menvcfg() | (1L << 63)); 
    80000040:	fff00713          	li	a4,-1
    80000044:	03f71713          	slli	a4,a4,0x3f
    80000048:	00e7e7b3          	or	a5,a5,a4

static inline void 
w_menvcfg(uint64 x)
{
  // asm volatile("csrw menvcfg, %0" : : "r" (x));
  asm volatile("csrw 0x30a, %0" : : "r" (x));
    8000004c:	30a79073          	csrw	0x30a,a5

static inline uint64
r_mcounteren()
{
  uint64 x;
  asm volatile("csrr %0, mcounteren" : "=r" (x) );
    80000050:	306027f3          	csrr	a5,mcounteren
  
  // allow supervisor to use stimecmp and time.
  w_mcounteren(r_mcounteren() | 2);
    80000054:	0027e793          	ori	a5,a5,2
  asm volatile("csrw mcounteren, %0" : : "r" (x));
    80000058:	30679073          	csrw	mcounteren,a5
  
  // ask for the very first timer interrupt.
//  w_stimecmp(r_time() + 1000000);
}
    8000005c:	00813403          	ld	s0,8(sp)
    80000060:	01010113          	addi	sp,sp,16
    80000064:	00008067          	ret

0000000080000068 <start>:
{
    80000068:	ff010113          	addi	sp,sp,-16
    8000006c:	00113423          	sd	ra,8(sp)
    80000070:	00813023          	sd	s0,0(sp)
    80000074:	01010413          	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000078:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000007c:	ffffe737          	lui	a4,0xffffe
    80000080:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdab27>
    80000084:	00e7f7b3          	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000088:	00001737          	lui	a4,0x1
    8000008c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80000090:	00e7e7b3          	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000094:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000098:	00001797          	auipc	a5,0x1
    8000009c:	40c78793          	addi	a5,a5,1036 # 800014a4 <main>
    800000a0:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000a4:	00000793          	li	a5,0
    800000a8:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000ac:	000107b7          	lui	a5,0x10
    800000b0:	fff78793          	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000b4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000b8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000bc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE);
    800000c0:	2207e793          	ori	a5,a5,544
  asm volatile("csrw sie, %0" : : "r" (x));
    800000c4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000c8:	fff00793          	li	a5,-1
    800000cc:	00a7d793          	srli	a5,a5,0xa
    800000d0:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000d4:	00f00793          	li	a5,15
    800000d8:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000dc:	00000097          	auipc	ra,0x0
    800000e0:	f48080e7          	jalr	-184(ra) # 80000024 <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e4:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e8:	0007879b          	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000ec:	00078213          	mv	tp,a5
  asm volatile("mret");
    800000f0:	30200073          	mret
}
    800000f4:	00813083          	ld	ra,8(sp)
    800000f8:	00013403          	ld	s0,0(sp)
    800000fc:	01010113          	addi	sp,sp,16
    80000100:	00008067          	ret

0000000080000104 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000104:	f9010113          	addi	sp,sp,-112
    80000108:	06113423          	sd	ra,104(sp)
    8000010c:	06813023          	sd	s0,96(sp)
    80000110:	04913c23          	sd	s1,88(sp)
    80000114:	05213823          	sd	s2,80(sp)
    80000118:	05313423          	sd	s3,72(sp)
    8000011c:	05413023          	sd	s4,64(sp)
    80000120:	03513c23          	sd	s5,56(sp)
    80000124:	03613823          	sd	s6,48(sp)
    80000128:	03713423          	sd	s7,40(sp)
    8000012c:	03813023          	sd	s8,32(sp)
    80000130:	07010413          	addi	s0,sp,112
  char buf[32];
  int i = 0;

  while(i < n){
    80000134:	06c05463          	blez	a2,8000019c <consolewrite+0x98>
    80000138:	00050a13          	mv	s4,a0
    8000013c:	00058a93          	mv	s5,a1
    80000140:	00060993          	mv	s3,a2
  int i = 0;
    80000144:	00000913          	li	s2,0
    int nn = sizeof(buf);
    if(nn > n - i)
    80000148:	01f00b93          	li	s7,31
    int nn = sizeof(buf);
    8000014c:	02000c13          	li	s8,32
      nn = n - i;
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    80000150:	fff00b13          	li	s6,-1
    80000154:	0380006f          	j	8000018c <consolewrite+0x88>
    80000158:	00048693          	mv	a3,s1
    8000015c:	01590633          	add	a2,s2,s5
    80000160:	000a0593          	mv	a1,s4
    80000164:	f9040513          	addi	a0,s0,-112
    80000168:	00003097          	auipc	ra,0x3
    8000016c:	560080e7          	jalr	1376(ra) # 800036c8 <either_copyin>
    80000170:	03650863          	beq	a0,s6,800001a0 <consolewrite+0x9c>
      break;
    uartwrite(buf, nn);
    80000174:	00048593          	mv	a1,s1
    80000178:	f9040513          	addi	a0,s0,-112
    8000017c:	00001097          	auipc	ra,0x1
    80000180:	9f8080e7          	jalr	-1544(ra) # 80000b74 <uartwrite>
    i += nn;
    80000184:	0124893b          	addw	s2,s1,s2
  while(i < n){
    80000188:	01395c63          	bge	s2,s3,800001a0 <consolewrite+0x9c>
    if(nn > n - i)
    8000018c:	412984bb          	subw	s1,s3,s2
    80000190:	fc9bd4e3          	bge	s7,s1,80000158 <consolewrite+0x54>
    int nn = sizeof(buf);
    80000194:	000c0493          	mv	s1,s8
    80000198:	fc1ff06f          	j	80000158 <consolewrite+0x54>
  int i = 0;
    8000019c:	00000913          	li	s2,0
  }

  return i;
}
    800001a0:	00090513          	mv	a0,s2
    800001a4:	06813083          	ld	ra,104(sp)
    800001a8:	06013403          	ld	s0,96(sp)
    800001ac:	05813483          	ld	s1,88(sp)
    800001b0:	05013903          	ld	s2,80(sp)
    800001b4:	04813983          	ld	s3,72(sp)
    800001b8:	04013a03          	ld	s4,64(sp)
    800001bc:	03813a83          	ld	s5,56(sp)
    800001c0:	03013b03          	ld	s6,48(sp)
    800001c4:	02813b83          	ld	s7,40(sp)
    800001c8:	02013c03          	ld	s8,32(sp)
    800001cc:	07010113          	addi	sp,sp,112
    800001d0:	00008067          	ret

00000000800001d4 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    800001d4:	f9010113          	addi	sp,sp,-112
    800001d8:	06113423          	sd	ra,104(sp)
    800001dc:	06813023          	sd	s0,96(sp)
    800001e0:	04913c23          	sd	s1,88(sp)
    800001e4:	05213823          	sd	s2,80(sp)
    800001e8:	05313423          	sd	s3,72(sp)
    800001ec:	05413023          	sd	s4,64(sp)
    800001f0:	03513c23          	sd	s5,56(sp)
    800001f4:	03613823          	sd	s6,48(sp)
    800001f8:	03713423          	sd	s7,40(sp)
    800001fc:	03813023          	sd	s8,32(sp)
    80000200:	01913c23          	sd	s9,24(sp)
    80000204:	01a13823          	sd	s10,16(sp)
    80000208:	07010413          	addi	s0,sp,112
    8000020c:	00050a93          	mv	s5,a0
    80000210:	00058a13          	mv	s4,a1
    80000214:	00060993          	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000218:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000021c:	00012517          	auipc	a0,0x12
    80000220:	7b450513          	addi	a0,a0,1972 # 800129d0 <cons>
    80000224:	00001097          	auipc	ra,0x1
    80000228:	e94080e7          	jalr	-364(ra) # 800010b8 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000022c:	00012497          	auipc	s1,0x12
    80000230:	7a448493          	addi	s1,s1,1956 # 800129d0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000234:	00013917          	auipc	s2,0x13
    80000238:	83490913          	addi	s2,s2,-1996 # 80012a68 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    8000023c:	00400b93          	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000240:	fff00c13          	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    80000244:	00a00c93          	li	s9,10
  while(n > 0){
    80000248:	09305463          	blez	s3,800002d0 <consoleread+0xfc>
    while(cons.r == cons.w){
    8000024c:	0984a783          	lw	a5,152(s1)
    80000250:	09c4a703          	lw	a4,156(s1)
    80000254:	02f71a63          	bne	a4,a5,80000288 <consoleread+0xb4>
      if(killed(myproc())){
    80000258:	00002097          	auipc	ra,0x2
    8000025c:	490080e7          	jalr	1168(ra) # 800026e8 <myproc>
    80000260:	00003097          	auipc	ra,0x3
    80000264:	1f0080e7          	jalr	496(ra) # 80003450 <killed>
    80000268:	08051063          	bnez	a0,800002e8 <consoleread+0x114>
      sleep(&cons.r, &cons.lock);
    8000026c:	00048593          	mv	a1,s1
    80000270:	00090513          	mv	a0,s2
    80000274:	00003097          	auipc	ra,0x3
    80000278:	e2c080e7          	jalr	-468(ra) # 800030a0 <sleep>
    while(cons.r == cons.w){
    8000027c:	0984a783          	lw	a5,152(s1)
    80000280:	09c4a703          	lw	a4,156(s1)
    80000284:	fcf70ae3          	beq	a4,a5,80000258 <consoleread+0x84>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    80000288:	0017871b          	addiw	a4,a5,1
    8000028c:	08e4ac23          	sw	a4,152(s1)
    80000290:	07f7f713          	andi	a4,a5,127
    80000294:	00e48733          	add	a4,s1,a4
    80000298:	01874703          	lbu	a4,24(a4)
    8000029c:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800002a0:	097d0a63          	beq	s10,s7,80000334 <consoleread+0x160>
    cbuf = c;
    800002a4:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800002a8:	00100693          	li	a3,1
    800002ac:	f9f40613          	addi	a2,s0,-97
    800002b0:	000a0593          	mv	a1,s4
    800002b4:	000a8513          	mv	a0,s5
    800002b8:	00003097          	auipc	ra,0x3
    800002bc:	380080e7          	jalr	896(ra) # 80003638 <either_copyout>
    800002c0:	01850863          	beq	a0,s8,800002d0 <consoleread+0xfc>
    dst++;
    800002c4:	001a0a13          	addi	s4,s4,1
    --n;
    800002c8:	fff9899b          	addiw	s3,s3,-1
    if(c == '\n'){
    800002cc:	f79d1ee3          	bne	s10,s9,80000248 <consoleread+0x74>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    800002d0:	00012517          	auipc	a0,0x12
    800002d4:	70050513          	addi	a0,a0,1792 # 800129d0 <cons>
    800002d8:	00001097          	auipc	ra,0x1
    800002dc:	ed8080e7          	jalr	-296(ra) # 800011b0 <release>

  return target - n;
    800002e0:	413b053b          	subw	a0,s6,s3
    800002e4:	0180006f          	j	800002fc <consoleread+0x128>
        release(&cons.lock);
    800002e8:	00012517          	auipc	a0,0x12
    800002ec:	6e850513          	addi	a0,a0,1768 # 800129d0 <cons>
    800002f0:	00001097          	auipc	ra,0x1
    800002f4:	ec0080e7          	jalr	-320(ra) # 800011b0 <release>
        return -1;
    800002f8:	fff00513          	li	a0,-1
}
    800002fc:	06813083          	ld	ra,104(sp)
    80000300:	06013403          	ld	s0,96(sp)
    80000304:	05813483          	ld	s1,88(sp)
    80000308:	05013903          	ld	s2,80(sp)
    8000030c:	04813983          	ld	s3,72(sp)
    80000310:	04013a03          	ld	s4,64(sp)
    80000314:	03813a83          	ld	s5,56(sp)
    80000318:	03013b03          	ld	s6,48(sp)
    8000031c:	02813b83          	ld	s7,40(sp)
    80000320:	02013c03          	ld	s8,32(sp)
    80000324:	01813c83          	ld	s9,24(sp)
    80000328:	01013d03          	ld	s10,16(sp)
    8000032c:	07010113          	addi	sp,sp,112
    80000330:	00008067          	ret
      if(n < target){
    80000334:	0009871b          	sext.w	a4,s3
    80000338:	f9677ce3          	bgeu	a4,s6,800002d0 <consoleread+0xfc>
        cons.r--;
    8000033c:	00012717          	auipc	a4,0x12
    80000340:	72f72623          	sw	a5,1836(a4) # 80012a68 <cons+0x98>
    80000344:	f8dff06f          	j	800002d0 <consoleread+0xfc>

0000000080000348 <consputc>:
{
    80000348:	ff010113          	addi	sp,sp,-16
    8000034c:	00113423          	sd	ra,8(sp)
    80000350:	00813023          	sd	s0,0(sp)
    80000354:	01010413          	addi	s0,sp,16
  if(c == BACKSPACE){
    80000358:	10000793          	li	a5,256
    8000035c:	00f50e63          	beq	a0,a5,80000378 <consputc+0x30>
    uartputc_sync(c);
    80000360:	00001097          	auipc	ra,0x1
    80000364:	90c080e7          	jalr	-1780(ra) # 80000c6c <uartputc_sync>
}
    80000368:	00813083          	ld	ra,8(sp)
    8000036c:	00013403          	ld	s0,0(sp)
    80000370:	01010113          	addi	sp,sp,16
    80000374:	00008067          	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000378:	00800513          	li	a0,8
    8000037c:	00001097          	auipc	ra,0x1
    80000380:	8f0080e7          	jalr	-1808(ra) # 80000c6c <uartputc_sync>
    80000384:	02000513          	li	a0,32
    80000388:	00001097          	auipc	ra,0x1
    8000038c:	8e4080e7          	jalr	-1820(ra) # 80000c6c <uartputc_sync>
    80000390:	00800513          	li	a0,8
    80000394:	00001097          	auipc	ra,0x1
    80000398:	8d8080e7          	jalr	-1832(ra) # 80000c6c <uartputc_sync>
    8000039c:	fcdff06f          	j	80000368 <consputc+0x20>

00000000800003a0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800003a0:	fe010113          	addi	sp,sp,-32
    800003a4:	00113c23          	sd	ra,24(sp)
    800003a8:	00813823          	sd	s0,16(sp)
    800003ac:	00913423          	sd	s1,8(sp)
    800003b0:	01213023          	sd	s2,0(sp)
    800003b4:	02010413          	addi	s0,sp,32
    800003b8:	00050493          	mv	s1,a0
  acquire(&cons.lock);
    800003bc:	00012517          	auipc	a0,0x12
    800003c0:	61450513          	addi	a0,a0,1556 # 800129d0 <cons>
    800003c4:	00001097          	auipc	ra,0x1
    800003c8:	cf4080e7          	jalr	-780(ra) # 800010b8 <acquire>

  switch(c){
    800003cc:	01500793          	li	a5,21
    800003d0:	0cf48663          	beq	s1,a5,8000049c <consoleintr+0xfc>
    800003d4:	0497c263          	blt	a5,s1,80000418 <consoleintr+0x78>
    800003d8:	00800793          	li	a5,8
    800003dc:	10f48a63          	beq	s1,a5,800004f0 <consoleintr+0x150>
    800003e0:	01000793          	li	a5,16
    800003e4:	12f49e63          	bne	s1,a5,80000520 <consoleintr+0x180>
  case C('P'):  // Print process list.
    procdump();
    800003e8:	00003097          	auipc	ra,0x3
    800003ec:	370080e7          	jalr	880(ra) # 80003758 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800003f0:	00012517          	auipc	a0,0x12
    800003f4:	5e050513          	addi	a0,a0,1504 # 800129d0 <cons>
    800003f8:	00001097          	auipc	ra,0x1
    800003fc:	db8080e7          	jalr	-584(ra) # 800011b0 <release>
}
    80000400:	01813083          	ld	ra,24(sp)
    80000404:	01013403          	ld	s0,16(sp)
    80000408:	00813483          	ld	s1,8(sp)
    8000040c:	00013903          	ld	s2,0(sp)
    80000410:	02010113          	addi	sp,sp,32
    80000414:	00008067          	ret
  switch(c){
    80000418:	07f00793          	li	a5,127
    8000041c:	0cf48a63          	beq	s1,a5,800004f0 <consoleintr+0x150>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000420:	00012717          	auipc	a4,0x12
    80000424:	5b070713          	addi	a4,a4,1456 # 800129d0 <cons>
    80000428:	0a072783          	lw	a5,160(a4)
    8000042c:	09872703          	lw	a4,152(a4)
    80000430:	40e787bb          	subw	a5,a5,a4
    80000434:	07f00713          	li	a4,127
    80000438:	faf76ce3          	bltu	a4,a5,800003f0 <consoleintr+0x50>
      c = (c == '\r') ? '\n' : c;
    8000043c:	00d00793          	li	a5,13
    80000440:	0ef48463          	beq	s1,a5,80000528 <consoleintr+0x188>
      consputc(c);
    80000444:	00048513          	mv	a0,s1
    80000448:	00000097          	auipc	ra,0x0
    8000044c:	f00080e7          	jalr	-256(ra) # 80000348 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000450:	00012797          	auipc	a5,0x12
    80000454:	58078793          	addi	a5,a5,1408 # 800129d0 <cons>
    80000458:	0a07a683          	lw	a3,160(a5)
    8000045c:	0016871b          	addiw	a4,a3,1
    80000460:	0007061b          	sext.w	a2,a4
    80000464:	0ae7a023          	sw	a4,160(a5)
    80000468:	07f6f693          	andi	a3,a3,127
    8000046c:	00d787b3          	add	a5,a5,a3
    80000470:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000474:	00a00793          	li	a5,10
    80000478:	0ef48263          	beq	s1,a5,8000055c <consoleintr+0x1bc>
    8000047c:	00400793          	li	a5,4
    80000480:	0cf48e63          	beq	s1,a5,8000055c <consoleintr+0x1bc>
    80000484:	00012797          	auipc	a5,0x12
    80000488:	5e47a783          	lw	a5,1508(a5) # 80012a68 <cons+0x98>
    8000048c:	40f7073b          	subw	a4,a4,a5
    80000490:	08000793          	li	a5,128
    80000494:	f4f71ee3          	bne	a4,a5,800003f0 <consoleintr+0x50>
    80000498:	0c40006f          	j	8000055c <consoleintr+0x1bc>
    while(cons.e != cons.w &&
    8000049c:	00012717          	auipc	a4,0x12
    800004a0:	53470713          	addi	a4,a4,1332 # 800129d0 <cons>
    800004a4:	0a072783          	lw	a5,160(a4)
    800004a8:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800004ac:	00012497          	auipc	s1,0x12
    800004b0:	52448493          	addi	s1,s1,1316 # 800129d0 <cons>
    while(cons.e != cons.w &&
    800004b4:	00a00913          	li	s2,10
    800004b8:	f2f70ce3          	beq	a4,a5,800003f0 <consoleintr+0x50>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800004bc:	fff7879b          	addiw	a5,a5,-1
    800004c0:	07f7f713          	andi	a4,a5,127
    800004c4:	00e48733          	add	a4,s1,a4
    while(cons.e != cons.w &&
    800004c8:	01874703          	lbu	a4,24(a4)
    800004cc:	f32702e3          	beq	a4,s2,800003f0 <consoleintr+0x50>
      cons.e--;
    800004d0:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800004d4:	10000513          	li	a0,256
    800004d8:	00000097          	auipc	ra,0x0
    800004dc:	e70080e7          	jalr	-400(ra) # 80000348 <consputc>
    while(cons.e != cons.w &&
    800004e0:	0a04a783          	lw	a5,160(s1)
    800004e4:	09c4a703          	lw	a4,156(s1)
    800004e8:	fcf71ae3          	bne	a4,a5,800004bc <consoleintr+0x11c>
    800004ec:	f05ff06f          	j	800003f0 <consoleintr+0x50>
    if(cons.e != cons.w){
    800004f0:	00012717          	auipc	a4,0x12
    800004f4:	4e070713          	addi	a4,a4,1248 # 800129d0 <cons>
    800004f8:	0a072783          	lw	a5,160(a4)
    800004fc:	09c72703          	lw	a4,156(a4)
    80000500:	eef708e3          	beq	a4,a5,800003f0 <consoleintr+0x50>
      cons.e--;
    80000504:	fff7879b          	addiw	a5,a5,-1
    80000508:	00012717          	auipc	a4,0x12
    8000050c:	56f72423          	sw	a5,1384(a4) # 80012a70 <cons+0xa0>
      consputc(BACKSPACE);
    80000510:	10000513          	li	a0,256
    80000514:	00000097          	auipc	ra,0x0
    80000518:	e34080e7          	jalr	-460(ra) # 80000348 <consputc>
    8000051c:	ed5ff06f          	j	800003f0 <consoleintr+0x50>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000520:	ec0488e3          	beqz	s1,800003f0 <consoleintr+0x50>
    80000524:	efdff06f          	j	80000420 <consoleintr+0x80>
      consputc(c);
    80000528:	00a00513          	li	a0,10
    8000052c:	00000097          	auipc	ra,0x0
    80000530:	e1c080e7          	jalr	-484(ra) # 80000348 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000534:	00012797          	auipc	a5,0x12
    80000538:	49c78793          	addi	a5,a5,1180 # 800129d0 <cons>
    8000053c:	0a07a703          	lw	a4,160(a5)
    80000540:	0017069b          	addiw	a3,a4,1
    80000544:	0006861b          	sext.w	a2,a3
    80000548:	0ad7a023          	sw	a3,160(a5)
    8000054c:	07f77713          	andi	a4,a4,127
    80000550:	00e787b3          	add	a5,a5,a4
    80000554:	00a00713          	li	a4,10
    80000558:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000055c:	00012797          	auipc	a5,0x12
    80000560:	50c7a823          	sw	a2,1296(a5) # 80012a6c <cons+0x9c>
        wakeup(&cons.r);
    80000564:	00012517          	auipc	a0,0x12
    80000568:	50450513          	addi	a0,a0,1284 # 80012a68 <cons+0x98>
    8000056c:	00003097          	auipc	ra,0x3
    80000570:	bc4080e7          	jalr	-1084(ra) # 80003130 <wakeup>
    80000574:	e7dff06f          	j	800003f0 <consoleintr+0x50>

0000000080000578 <consoleinit>:

void
consoleinit(void)
{
    80000578:	ff010113          	addi	sp,sp,-16
    8000057c:	00113423          	sd	ra,8(sp)
    80000580:	00813023          	sd	s0,0(sp)
    80000584:	01010413          	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000588:	0000a597          	auipc	a1,0xa
    8000058c:	a8858593          	addi	a1,a1,-1400 # 8000a010 <etext+0x10>
    80000590:	00012517          	auipc	a0,0x12
    80000594:	44050513          	addi	a0,a0,1088 # 800129d0 <cons>
    80000598:	00001097          	auipc	ra,0x1
    8000059c:	a3c080e7          	jalr	-1476(ra) # 80000fd4 <initlock>

  uartinit();
    800005a0:	00000097          	auipc	ra,0x0
    800005a4:	570080e7          	jalr	1392(ra) # 80000b10 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    800005a8:	00022797          	auipc	a5,0x22
    800005ac:	59878793          	addi	a5,a5,1432 # 80022b40 <devsw>
    800005b0:	00000717          	auipc	a4,0x0
    800005b4:	c2470713          	addi	a4,a4,-988 # 800001d4 <consoleread>
    800005b8:	00e7b823          	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    800005bc:	00000717          	auipc	a4,0x0
    800005c0:	b4870713          	addi	a4,a4,-1208 # 80000104 <consolewrite>
    800005c4:	00e7bc23          	sd	a4,24(a5)
}
    800005c8:	00813083          	ld	ra,8(sp)
    800005cc:	00013403          	ld	s0,0(sp)
    800005d0:	01010113          	addi	sp,sp,16
    800005d4:	00008067          	ret

00000000800005d8 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(long long xx, int base, int sign)
{
    800005d8:	fc010113          	addi	sp,sp,-64
    800005dc:	02113c23          	sd	ra,56(sp)
    800005e0:	02813823          	sd	s0,48(sp)
    800005e4:	02913423          	sd	s1,40(sp)
    800005e8:	03213023          	sd	s2,32(sp)
    800005ec:	04010413          	addi	s0,sp,64
  char buf[20];
  int i;
  unsigned long long x;

  if(sign && (sign = (xx < 0)))
    800005f0:	00060463          	beqz	a2,800005f8 <printint+0x20>
    800005f4:	0a054463          	bltz	a0,8000069c <printint+0xc4>
    x = -xx;
  else
    x = xx;
    800005f8:	00000893          	li	a7,0
    800005fc:	fc840693          	addi	a3,s0,-56

  i = 0;
    80000600:	00000793          	li	a5,0
  do {
    buf[i++] = digits[x % base];
    80000604:	0000a617          	auipc	a2,0xa
    80000608:	a3460613          	addi	a2,a2,-1484 # 8000a038 <digits>
    8000060c:	00078813          	mv	a6,a5
    80000610:	0017879b          	addiw	a5,a5,1
    80000614:	02b57733          	remu	a4,a0,a1
    80000618:	00e60733          	add	a4,a2,a4
    8000061c:	00074703          	lbu	a4,0(a4)
    80000620:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    80000624:	00050713          	mv	a4,a0
    80000628:	02b55533          	divu	a0,a0,a1
    8000062c:	00168693          	addi	a3,a3,1
    80000630:	fcb77ee3          	bgeu	a4,a1,8000060c <printint+0x34>

  if(sign)
    80000634:	00088c63          	beqz	a7,8000064c <printint+0x74>
    buf[i++] = '-';
    80000638:	fe078793          	addi	a5,a5,-32
    8000063c:	008787b3          	add	a5,a5,s0
    80000640:	02d00713          	li	a4,45
    80000644:	fee78423          	sb	a4,-24(a5)
    80000648:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
    8000064c:	02f05c63          	blez	a5,80000684 <printint+0xac>
    80000650:	fc840713          	addi	a4,s0,-56
    80000654:	00f704b3          	add	s1,a4,a5
    80000658:	fff70913          	addi	s2,a4,-1
    8000065c:	00f90933          	add	s2,s2,a5
    80000660:	fff7879b          	addiw	a5,a5,-1
    80000664:	02079793          	slli	a5,a5,0x20
    80000668:	0207d793          	srli	a5,a5,0x20
    8000066c:	40f90933          	sub	s2,s2,a5
    consputc(buf[i]);
    80000670:	fff4c503          	lbu	a0,-1(s1)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	cd4080e7          	jalr	-812(ra) # 80000348 <consputc>
  while(--i >= 0)
    8000067c:	fff48493          	addi	s1,s1,-1
    80000680:	ff2498e3          	bne	s1,s2,80000670 <printint+0x98>
}
    80000684:	03813083          	ld	ra,56(sp)
    80000688:	03013403          	ld	s0,48(sp)
    8000068c:	02813483          	ld	s1,40(sp)
    80000690:	02013903          	ld	s2,32(sp)
    80000694:	04010113          	addi	sp,sp,64
    80000698:	00008067          	ret
    x = -xx;
    8000069c:	40a00533          	neg	a0,a0
  if(sign && (sign = (xx < 0)))
    800006a0:	00100893          	li	a7,1
    x = -xx;
    800006a4:	f59ff06f          	j	800005fc <printint+0x24>

00000000800006a8 <printf>:
}

// Print to the console.
int
printf(char *fmt, ...)
{
    800006a8:	f4010113          	addi	sp,sp,-192
    800006ac:	06113c23          	sd	ra,120(sp)
    800006b0:	06813823          	sd	s0,112(sp)
    800006b4:	06913423          	sd	s1,104(sp)
    800006b8:	07213023          	sd	s2,96(sp)
    800006bc:	05313c23          	sd	s3,88(sp)
    800006c0:	05413823          	sd	s4,80(sp)
    800006c4:	05513423          	sd	s5,72(sp)
    800006c8:	05613023          	sd	s6,64(sp)
    800006cc:	03713c23          	sd	s7,56(sp)
    800006d0:	03813823          	sd	s8,48(sp)
    800006d4:	03913423          	sd	s9,40(sp)
    800006d8:	03a13023          	sd	s10,32(sp)
    800006dc:	01b13c23          	sd	s11,24(sp)
    800006e0:	08010413          	addi	s0,sp,128
    800006e4:	00050a13          	mv	s4,a0
    800006e8:	00b43423          	sd	a1,8(s0)
    800006ec:	00c43823          	sd	a2,16(s0)
    800006f0:	00d43c23          	sd	a3,24(s0)
    800006f4:	02e43023          	sd	a4,32(s0)
    800006f8:	02f43423          	sd	a5,40(s0)
    800006fc:	03043823          	sd	a6,48(s0)
    80000700:	03143c23          	sd	a7,56(s0)
  va_list ap;
  int i, cx, c0, c1, c2;
  char *s;

  if(panicking == 0)
    80000704:	0000a797          	auipc	a5,0xa
    80000708:	2a07a783          	lw	a5,672(a5) # 8000a9a4 <panicking>
    8000070c:	02078e63          	beqz	a5,80000748 <printf+0xa0>
    acquire(&pr.lock);

  va_start(ap, fmt);
    80000710:	00840793          	addi	a5,s0,8
    80000714:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000718:	000a4503          	lbu	a0,0(s4)
    8000071c:	30050263          	beqz	a0,80000a20 <printf+0x378>
    80000720:	00000993          	li	s3,0
    if(cx != '%'){
    80000724:	02500a93          	li	s5,37
    i++;
    c0 = fmt[i+0] & 0xff;
    c1 = c2 = 0;
    if(c0) c1 = fmt[i+1] & 0xff;
    if(c1) c2 = fmt[i+2] & 0xff;
    if(c0 == 'd'){
    80000728:	06400b13          	li	s6,100
      printint(va_arg(ap, int), 10, 1);
    } else if(c0 == 'l' && c1 == 'd'){
    8000072c:	06c00c13          	li	s8,108
      printint(va_arg(ap, uint64), 10, 1);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
      printint(va_arg(ap, uint64), 10, 1);
      i += 2;
    } else if(c0 == 'u'){
    80000730:	07500c93          	li	s9,117
      printint(va_arg(ap, uint64), 10, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
      printint(va_arg(ap, uint64), 10, 0);
      i += 2;
    } else if(c0 == 'x'){
    80000734:	07800d13          	li	s10,120
      printint(va_arg(ap, uint64), 16, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
      printint(va_arg(ap, uint64), 16, 0);
      i += 2;
    } else if(c0 == 'p'){
    80000738:	07000d93          	li	s11,112
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000073c:	0000ab97          	auipc	s7,0xa
    80000740:	8fcb8b93          	addi	s7,s7,-1796 # 8000a038 <digits>
    80000744:	0340006f          	j	80000778 <printf+0xd0>
    acquire(&pr.lock);
    80000748:	00012517          	auipc	a0,0x12
    8000074c:	33050513          	addi	a0,a0,816 # 80012a78 <pr>
    80000750:	00001097          	auipc	ra,0x1
    80000754:	968080e7          	jalr	-1688(ra) # 800010b8 <acquire>
    80000758:	fb9ff06f          	j	80000710 <printf+0x68>
      consputc(cx);
    8000075c:	00000097          	auipc	ra,0x0
    80000760:	bec080e7          	jalr	-1044(ra) # 80000348 <consputc>
      continue;
    80000764:	00098493          	mv	s1,s3
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000768:	0014899b          	addiw	s3,s1,1
    8000076c:	013a07b3          	add	a5,s4,s3
    80000770:	0007c503          	lbu	a0,0(a5)
    80000774:	2a050663          	beqz	a0,80000a20 <printf+0x378>
    if(cx != '%'){
    80000778:	ff5512e3          	bne	a0,s5,8000075c <printf+0xb4>
    i++;
    8000077c:	0019849b          	addiw	s1,s3,1
    c0 = fmt[i+0] & 0xff;
    80000780:	009a07b3          	add	a5,s4,s1
    80000784:	0007c903          	lbu	s2,0(a5)
    if(c0) c1 = fmt[i+1] & 0xff;
    80000788:	28090c63          	beqz	s2,80000a20 <printf+0x378>
    8000078c:	0017c783          	lbu	a5,1(a5)
    c1 = c2 = 0;
    80000790:	00078693          	mv	a3,a5
    if(c1) c2 = fmt[i+2] & 0xff;
    80000794:	00078663          	beqz	a5,800007a0 <printf+0xf8>
    80000798:	009a0733          	add	a4,s4,s1
    8000079c:	00274683          	lbu	a3,2(a4)
    if(c0 == 'd'){
    800007a0:	03690c63          	beq	s2,s6,800007d8 <printf+0x130>
    } else if(c0 == 'l' && c1 == 'd'){
    800007a4:	05890c63          	beq	s2,s8,800007fc <printf+0x154>
    } else if(c0 == 'u'){
    800007a8:	11990463          	beq	s2,s9,800008b0 <printf+0x208>
    } else if(c0 == 'x'){
    800007ac:	17a90c63          	beq	s2,s10,80000924 <printf+0x27c>
    } else if(c0 == 'p'){
    800007b0:	1db90063          	beq	s2,s11,80000970 <printf+0x2c8>
      printptr(va_arg(ap, uint64));
    } else if(c0 == 'c'){
    800007b4:	06300793          	li	a5,99
    800007b8:	20f90463          	beq	s2,a5,800009c0 <printf+0x318>
      consputc(va_arg(ap, uint));
    } else if(c0 == 's'){
    800007bc:	07300793          	li	a5,115
    800007c0:	20f90e63          	beq	s2,a5,800009dc <printf+0x334>
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
    } else if(c0 == '%'){
    800007c4:	05591663          	bne	s2,s5,80000810 <printf+0x168>
      consputc('%');
    800007c8:	000a8513          	mv	a0,s5
    800007cc:	00000097          	auipc	ra,0x0
    800007d0:	b7c080e7          	jalr	-1156(ra) # 80000348 <consputc>
    800007d4:	f95ff06f          	j	80000768 <printf+0xc0>
      printint(va_arg(ap, int), 10, 1);
    800007d8:	f8843783          	ld	a5,-120(s0)
    800007dc:	00878713          	addi	a4,a5,8
    800007e0:	f8e43423          	sd	a4,-120(s0)
    800007e4:	00100613          	li	a2,1
    800007e8:	00a00593          	li	a1,10
    800007ec:	0007a503          	lw	a0,0(a5)
    800007f0:	00000097          	auipc	ra,0x0
    800007f4:	de8080e7          	jalr	-536(ra) # 800005d8 <printint>
    800007f8:	f71ff06f          	j	80000768 <printf+0xc0>
    } else if(c0 == 'l' && c1 == 'd'){
    800007fc:	03678863          	beq	a5,s6,8000082c <printf+0x184>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    80000800:	05878a63          	beq	a5,s8,80000854 <printf+0x1ac>
    } else if(c0 == 'l' && c1 == 'u'){
    80000804:	0d978863          	beq	a5,s9,800008d4 <printf+0x22c>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    80000808:	05878863          	beq	a5,s8,80000858 <printf+0x1b0>
    } else if(c0 == 'l' && c1 == 'x'){
    8000080c:	13a78e63          	beq	a5,s10,80000948 <printf+0x2a0>
    } else if(c0 == 0){
      break;
    } else {
      // Print unknown % sequence to draw attention.
      consputc('%');
    80000810:	000a8513          	mv	a0,s5
    80000814:	00000097          	auipc	ra,0x0
    80000818:	b34080e7          	jalr	-1228(ra) # 80000348 <consputc>
      consputc(c0);
    8000081c:	00090513          	mv	a0,s2
    80000820:	00000097          	auipc	ra,0x0
    80000824:	b28080e7          	jalr	-1240(ra) # 80000348 <consputc>
    80000828:	f41ff06f          	j	80000768 <printf+0xc0>
      printint(va_arg(ap, uint64), 10, 1);
    8000082c:	f8843783          	ld	a5,-120(s0)
    80000830:	00878713          	addi	a4,a5,8
    80000834:	f8e43423          	sd	a4,-120(s0)
    80000838:	00100613          	li	a2,1
    8000083c:	00a00593          	li	a1,10
    80000840:	0007b503          	ld	a0,0(a5)
    80000844:	00000097          	auipc	ra,0x0
    80000848:	d94080e7          	jalr	-620(ra) # 800005d8 <printint>
      i += 1;
    8000084c:	0029849b          	addiw	s1,s3,2
    80000850:	f19ff06f          	j	80000768 <printf+0xc0>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    80000854:	03668a63          	beq	a3,s6,80000888 <printf+0x1e0>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    80000858:	0b968263          	beq	a3,s9,800008fc <printf+0x254>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
    8000085c:	fba69ae3          	bne	a3,s10,80000810 <printf+0x168>
      printint(va_arg(ap, uint64), 16, 0);
    80000860:	f8843783          	ld	a5,-120(s0)
    80000864:	00878713          	addi	a4,a5,8
    80000868:	f8e43423          	sd	a4,-120(s0)
    8000086c:	00000613          	li	a2,0
    80000870:	01000593          	li	a1,16
    80000874:	0007b503          	ld	a0,0(a5)
    80000878:	00000097          	auipc	ra,0x0
    8000087c:	d60080e7          	jalr	-672(ra) # 800005d8 <printint>
      i += 2;
    80000880:	0039849b          	addiw	s1,s3,3
    80000884:	ee5ff06f          	j	80000768 <printf+0xc0>
      printint(va_arg(ap, uint64), 10, 1);
    80000888:	f8843783          	ld	a5,-120(s0)
    8000088c:	00878713          	addi	a4,a5,8
    80000890:	f8e43423          	sd	a4,-120(s0)
    80000894:	00100613          	li	a2,1
    80000898:	00a00593          	li	a1,10
    8000089c:	0007b503          	ld	a0,0(a5)
    800008a0:	00000097          	auipc	ra,0x0
    800008a4:	d38080e7          	jalr	-712(ra) # 800005d8 <printint>
      i += 2;
    800008a8:	0039849b          	addiw	s1,s3,3
    800008ac:	ebdff06f          	j	80000768 <printf+0xc0>
      printint(va_arg(ap, uint32), 10, 0);
    800008b0:	f8843783          	ld	a5,-120(s0)
    800008b4:	00878713          	addi	a4,a5,8
    800008b8:	f8e43423          	sd	a4,-120(s0)
    800008bc:	00000613          	li	a2,0
    800008c0:	00a00593          	li	a1,10
    800008c4:	0007e503          	lwu	a0,0(a5)
    800008c8:	00000097          	auipc	ra,0x0
    800008cc:	d10080e7          	jalr	-752(ra) # 800005d8 <printint>
    800008d0:	e99ff06f          	j	80000768 <printf+0xc0>
      printint(va_arg(ap, uint64), 10, 0);
    800008d4:	f8843783          	ld	a5,-120(s0)
    800008d8:	00878713          	addi	a4,a5,8
    800008dc:	f8e43423          	sd	a4,-120(s0)
    800008e0:	00000613          	li	a2,0
    800008e4:	00a00593          	li	a1,10
    800008e8:	0007b503          	ld	a0,0(a5)
    800008ec:	00000097          	auipc	ra,0x0
    800008f0:	cec080e7          	jalr	-788(ra) # 800005d8 <printint>
      i += 1;
    800008f4:	0029849b          	addiw	s1,s3,2
    800008f8:	e71ff06f          	j	80000768 <printf+0xc0>
      printint(va_arg(ap, uint64), 10, 0);
    800008fc:	f8843783          	ld	a5,-120(s0)
    80000900:	00878713          	addi	a4,a5,8
    80000904:	f8e43423          	sd	a4,-120(s0)
    80000908:	00000613          	li	a2,0
    8000090c:	00a00593          	li	a1,10
    80000910:	0007b503          	ld	a0,0(a5)
    80000914:	00000097          	auipc	ra,0x0
    80000918:	cc4080e7          	jalr	-828(ra) # 800005d8 <printint>
      i += 2;
    8000091c:	0039849b          	addiw	s1,s3,3
    80000920:	e49ff06f          	j	80000768 <printf+0xc0>
      printint(va_arg(ap, uint32), 16, 0);
    80000924:	f8843783          	ld	a5,-120(s0)
    80000928:	00878713          	addi	a4,a5,8
    8000092c:	f8e43423          	sd	a4,-120(s0)
    80000930:	00000613          	li	a2,0
    80000934:	01000593          	li	a1,16
    80000938:	0007e503          	lwu	a0,0(a5)
    8000093c:	00000097          	auipc	ra,0x0
    80000940:	c9c080e7          	jalr	-868(ra) # 800005d8 <printint>
    80000944:	e25ff06f          	j	80000768 <printf+0xc0>
      printint(va_arg(ap, uint64), 16, 0);
    80000948:	f8843783          	ld	a5,-120(s0)
    8000094c:	00878713          	addi	a4,a5,8
    80000950:	f8e43423          	sd	a4,-120(s0)
    80000954:	00000613          	li	a2,0
    80000958:	01000593          	li	a1,16
    8000095c:	0007b503          	ld	a0,0(a5)
    80000960:	00000097          	auipc	ra,0x0
    80000964:	c78080e7          	jalr	-904(ra) # 800005d8 <printint>
      i += 1;
    80000968:	0029849b          	addiw	s1,s3,2
    8000096c:	dfdff06f          	j	80000768 <printf+0xc0>
      printptr(va_arg(ap, uint64));
    80000970:	f8843783          	ld	a5,-120(s0)
    80000974:	00878713          	addi	a4,a5,8
    80000978:	f8e43423          	sd	a4,-120(s0)
    8000097c:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000980:	03000513          	li	a0,48
    80000984:	00000097          	auipc	ra,0x0
    80000988:	9c4080e7          	jalr	-1596(ra) # 80000348 <consputc>
  consputc('x');
    8000098c:	000d0513          	mv	a0,s10
    80000990:	00000097          	auipc	ra,0x0
    80000994:	9b8080e7          	jalr	-1608(ra) # 80000348 <consputc>
    80000998:	01000913          	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000099c:	03c9d793          	srli	a5,s3,0x3c
    800009a0:	00fb87b3          	add	a5,s7,a5
    800009a4:	0007c503          	lbu	a0,0(a5)
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	9a0080e7          	jalr	-1632(ra) # 80000348 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800009b0:	00499993          	slli	s3,s3,0x4
    800009b4:	fff9091b          	addiw	s2,s2,-1
    800009b8:	fe0912e3          	bnez	s2,8000099c <printf+0x2f4>
    800009bc:	dadff06f          	j	80000768 <printf+0xc0>
      consputc(va_arg(ap, uint));
    800009c0:	f8843783          	ld	a5,-120(s0)
    800009c4:	00878713          	addi	a4,a5,8
    800009c8:	f8e43423          	sd	a4,-120(s0)
    800009cc:	0007a503          	lw	a0,0(a5)
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	978080e7          	jalr	-1672(ra) # 80000348 <consputc>
    800009d8:	d91ff06f          	j	80000768 <printf+0xc0>
      if((s = va_arg(ap, char*)) == 0)
    800009dc:	f8843783          	ld	a5,-120(s0)
    800009e0:	00878713          	addi	a4,a5,8
    800009e4:	f8e43423          	sd	a4,-120(s0)
    800009e8:	0007b903          	ld	s2,0(a5)
    800009ec:	02090263          	beqz	s2,80000a10 <printf+0x368>
      for(; *s; s++)
    800009f0:	00094503          	lbu	a0,0(s2)
    800009f4:	d6050ae3          	beqz	a0,80000768 <printf+0xc0>
        consputc(*s);
    800009f8:	00000097          	auipc	ra,0x0
    800009fc:	950080e7          	jalr	-1712(ra) # 80000348 <consputc>
      for(; *s; s++)
    80000a00:	00190913          	addi	s2,s2,1
    80000a04:	00094503          	lbu	a0,0(s2)
    80000a08:	fe0518e3          	bnez	a0,800009f8 <printf+0x350>
    80000a0c:	d5dff06f          	j	80000768 <printf+0xc0>
        s = "(null)";
    80000a10:	00009917          	auipc	s2,0x9
    80000a14:	60890913          	addi	s2,s2,1544 # 8000a018 <etext+0x18>
      for(; *s; s++)
    80000a18:	02800513          	li	a0,40
    80000a1c:	fddff06f          	j	800009f8 <printf+0x350>
    }

  }
  va_end(ap);

  if(panicking == 0)
    80000a20:	0000a797          	auipc	a5,0xa
    80000a24:	f847a783          	lw	a5,-124(a5) # 8000a9a4 <panicking>
    80000a28:	04078263          	beqz	a5,80000a6c <printf+0x3c4>
    release(&pr.lock);

  return 0;
}
    80000a2c:	00000513          	li	a0,0
    80000a30:	07813083          	ld	ra,120(sp)
    80000a34:	07013403          	ld	s0,112(sp)
    80000a38:	06813483          	ld	s1,104(sp)
    80000a3c:	06013903          	ld	s2,96(sp)
    80000a40:	05813983          	ld	s3,88(sp)
    80000a44:	05013a03          	ld	s4,80(sp)
    80000a48:	04813a83          	ld	s5,72(sp)
    80000a4c:	04013b03          	ld	s6,64(sp)
    80000a50:	03813b83          	ld	s7,56(sp)
    80000a54:	03013c03          	ld	s8,48(sp)
    80000a58:	02813c83          	ld	s9,40(sp)
    80000a5c:	02013d03          	ld	s10,32(sp)
    80000a60:	01813d83          	ld	s11,24(sp)
    80000a64:	0c010113          	addi	sp,sp,192
    80000a68:	00008067          	ret
    release(&pr.lock);
    80000a6c:	00012517          	auipc	a0,0x12
    80000a70:	00c50513          	addi	a0,a0,12 # 80012a78 <pr>
    80000a74:	00000097          	auipc	ra,0x0
    80000a78:	73c080e7          	jalr	1852(ra) # 800011b0 <release>
  return 0;
    80000a7c:	fb1ff06f          	j	80000a2c <printf+0x384>

0000000080000a80 <panic>:

void
panic(char *s)
{
    80000a80:	fe010113          	addi	sp,sp,-32
    80000a84:	00113c23          	sd	ra,24(sp)
    80000a88:	00813823          	sd	s0,16(sp)
    80000a8c:	00913423          	sd	s1,8(sp)
    80000a90:	01213023          	sd	s2,0(sp)
    80000a94:	02010413          	addi	s0,sp,32
    80000a98:	00050493          	mv	s1,a0
  panicking = 1;
    80000a9c:	00100913          	li	s2,1
    80000aa0:	0000a797          	auipc	a5,0xa
    80000aa4:	f127a223          	sw	s2,-252(a5) # 8000a9a4 <panicking>
  printf("panic: ");
    80000aa8:	00009517          	auipc	a0,0x9
    80000aac:	57850513          	addi	a0,a0,1400 # 8000a020 <etext+0x20>
    80000ab0:	00000097          	auipc	ra,0x0
    80000ab4:	bf8080e7          	jalr	-1032(ra) # 800006a8 <printf>
  printf("%s\n", s);
    80000ab8:	00048593          	mv	a1,s1
    80000abc:	00009517          	auipc	a0,0x9
    80000ac0:	56c50513          	addi	a0,a0,1388 # 8000a028 <etext+0x28>
    80000ac4:	00000097          	auipc	ra,0x0
    80000ac8:	be4080e7          	jalr	-1052(ra) # 800006a8 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000acc:	0000a797          	auipc	a5,0xa
    80000ad0:	ed27aa23          	sw	s2,-300(a5) # 8000a9a0 <panicked>
  for(;;)
    80000ad4:	0000006f          	j	80000ad4 <panic+0x54>

0000000080000ad8 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000ad8:	ff010113          	addi	sp,sp,-16
    80000adc:	00113423          	sd	ra,8(sp)
    80000ae0:	00813023          	sd	s0,0(sp)
    80000ae4:	01010413          	addi	s0,sp,16
  initlock(&pr.lock, "pr");
    80000ae8:	00009597          	auipc	a1,0x9
    80000aec:	54858593          	addi	a1,a1,1352 # 8000a030 <etext+0x30>
    80000af0:	00012517          	auipc	a0,0x12
    80000af4:	f8850513          	addi	a0,a0,-120 # 80012a78 <pr>
    80000af8:	00000097          	auipc	ra,0x0
    80000afc:	4dc080e7          	jalr	1244(ra) # 80000fd4 <initlock>
}
    80000b00:	00813083          	ld	ra,8(sp)
    80000b04:	00013403          	ld	s0,0(sp)
    80000b08:	01010113          	addi	sp,sp,16
    80000b0c:	00008067          	ret

0000000080000b10 <uartinit>:
extern volatile int panicking; // from printf.c
extern volatile int panicked; // from printf.c

void
uartinit(void)
{
    80000b10:	ff010113          	addi	sp,sp,-16
    80000b14:	00113423          	sd	ra,8(sp)
    80000b18:	00813023          	sd	s0,0(sp)
    80000b1c:	01010413          	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000b20:	100007b7          	lui	a5,0x10000
    80000b24:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000b28:	f8000713          	li	a4,-128
    80000b2c:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000b30:	00300713          	li	a4,3
    80000b34:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000b38:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000b3c:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000b40:	00700693          	li	a3,7
    80000b44:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000b48:	00e780a3          	sb	a4,1(a5)

  initlock(&tx_lock, "uart");
    80000b4c:	00009597          	auipc	a1,0x9
    80000b50:	50458593          	addi	a1,a1,1284 # 8000a050 <digits+0x18>
    80000b54:	00012517          	auipc	a0,0x12
    80000b58:	f3c50513          	addi	a0,a0,-196 # 80012a90 <tx_lock>
    80000b5c:	00000097          	auipc	ra,0x0
    80000b60:	478080e7          	jalr	1144(ra) # 80000fd4 <initlock>
}
    80000b64:	00813083          	ld	ra,8(sp)
    80000b68:	00013403          	ld	s0,0(sp)
    80000b6c:	01010113          	addi	sp,sp,16
    80000b70:	00008067          	ret

0000000080000b74 <uartwrite>:
// transmit buf[] to the uart. it blocks if the
// uart is busy, so it cannot be called from
// interrupts, only from write() system calls.
void
uartwrite(char buf[], int n)
{
    80000b74:	fb010113          	addi	sp,sp,-80
    80000b78:	04113423          	sd	ra,72(sp)
    80000b7c:	04813023          	sd	s0,64(sp)
    80000b80:	02913c23          	sd	s1,56(sp)
    80000b84:	03213823          	sd	s2,48(sp)
    80000b88:	03313423          	sd	s3,40(sp)
    80000b8c:	03413023          	sd	s4,32(sp)
    80000b90:	01513c23          	sd	s5,24(sp)
    80000b94:	01613823          	sd	s6,16(sp)
    80000b98:	01713423          	sd	s7,8(sp)
    80000b9c:	05010413          	addi	s0,sp,80
    80000ba0:	00050493          	mv	s1,a0
    80000ba4:	00058913          	mv	s2,a1
  acquire(&tx_lock);
    80000ba8:	00012517          	auipc	a0,0x12
    80000bac:	ee850513          	addi	a0,a0,-280 # 80012a90 <tx_lock>
    80000bb0:	00000097          	auipc	ra,0x0
    80000bb4:	508080e7          	jalr	1288(ra) # 800010b8 <acquire>

  int i = 0;
  while(i < n){ 
    80000bb8:	07205c63          	blez	s2,80000c30 <uartwrite+0xbc>
    80000bbc:	00048a13          	mv	s4,s1
    80000bc0:	00148493          	addi	s1,s1,1
    80000bc4:	fff9079b          	addiw	a5,s2,-1
    80000bc8:	02079793          	slli	a5,a5,0x20
    80000bcc:	0207d793          	srli	a5,a5,0x20
    80000bd0:	00f48ab3          	add	s5,s1,a5
    while(tx_busy != 0){
    80000bd4:	0000a497          	auipc	s1,0xa
    80000bd8:	dd848493          	addi	s1,s1,-552 # 8000a9ac <tx_busy>
      // wait for a UART transmit-complete interrupt
      // to set tx_busy to 0.
      sleep(&tx_chan, &tx_lock);
    80000bdc:	00012997          	auipc	s3,0x12
    80000be0:	eb498993          	addi	s3,s3,-332 # 80012a90 <tx_lock>
    80000be4:	0000a917          	auipc	s2,0xa
    80000be8:	dc490913          	addi	s2,s2,-572 # 8000a9a8 <tx_chan>
    }   
      
    WriteReg(THR, buf[i]);
    80000bec:	10000bb7          	lui	s7,0x10000
    i += 1;
    tx_busy = 1;
    80000bf0:	00100b13          	li	s6,1
    80000bf4:	0300006f          	j	80000c24 <uartwrite+0xb0>
      sleep(&tx_chan, &tx_lock);
    80000bf8:	00098593          	mv	a1,s3
    80000bfc:	00090513          	mv	a0,s2
    80000c00:	00002097          	auipc	ra,0x2
    80000c04:	4a0080e7          	jalr	1184(ra) # 800030a0 <sleep>
    while(tx_busy != 0){
    80000c08:	0004a783          	lw	a5,0(s1)
    80000c0c:	fe0796e3          	bnez	a5,80000bf8 <uartwrite+0x84>
    WriteReg(THR, buf[i]);
    80000c10:	000a4783          	lbu	a5,0(s4)
    80000c14:	00fb8023          	sb	a5,0(s7) # 10000000 <_entry-0x70000000>
    tx_busy = 1;
    80000c18:	0164a023          	sw	s6,0(s1)
  while(i < n){ 
    80000c1c:	001a0a13          	addi	s4,s4,1
    80000c20:	015a0863          	beq	s4,s5,80000c30 <uartwrite+0xbc>
    while(tx_busy != 0){
    80000c24:	0004a783          	lw	a5,0(s1)
    80000c28:	fc0798e3          	bnez	a5,80000bf8 <uartwrite+0x84>
    80000c2c:	fe5ff06f          	j	80000c10 <uartwrite+0x9c>
  }

  release(&tx_lock);
    80000c30:	00012517          	auipc	a0,0x12
    80000c34:	e6050513          	addi	a0,a0,-416 # 80012a90 <tx_lock>
    80000c38:	00000097          	auipc	ra,0x0
    80000c3c:	578080e7          	jalr	1400(ra) # 800011b0 <release>
}
    80000c40:	04813083          	ld	ra,72(sp)
    80000c44:	04013403          	ld	s0,64(sp)
    80000c48:	03813483          	ld	s1,56(sp)
    80000c4c:	03013903          	ld	s2,48(sp)
    80000c50:	02813983          	ld	s3,40(sp)
    80000c54:	02013a03          	ld	s4,32(sp)
    80000c58:	01813a83          	ld	s5,24(sp)
    80000c5c:	01013b03          	ld	s6,16(sp)
    80000c60:	00813b83          	ld	s7,8(sp)
    80000c64:	05010113          	addi	sp,sp,80
    80000c68:	00008067          	ret

0000000080000c6c <uartputc_sync>:
// interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000c6c:	fe010113          	addi	sp,sp,-32
    80000c70:	00113c23          	sd	ra,24(sp)
    80000c74:	00813823          	sd	s0,16(sp)
    80000c78:	00913423          	sd	s1,8(sp)
    80000c7c:	02010413          	addi	s0,sp,32
    80000c80:	00050493          	mv	s1,a0
  if(panicking == 0)
    80000c84:	0000a797          	auipc	a5,0xa
    80000c88:	d207a783          	lw	a5,-736(a5) # 8000a9a4 <panicking>
    80000c8c:	00078c63          	beqz	a5,80000ca4 <uartputc_sync+0x38>
    push_off();

  if(panicked){
    80000c90:	0000a797          	auipc	a5,0xa
    80000c94:	d107a783          	lw	a5,-752(a5) # 8000a9a0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000c98:	10000737          	lui	a4,0x10000
  if(panicked){
    80000c9c:	00078a63          	beqz	a5,80000cb0 <uartputc_sync+0x44>
    for(;;)
    80000ca0:	0000006f          	j	80000ca0 <uartputc_sync+0x34>
    push_off();
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	3a0080e7          	jalr	928(ra) # 80001044 <push_off>
    80000cac:	fe5ff06f          	j	80000c90 <uartputc_sync+0x24>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000cb0:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000cb4:	0207f793          	andi	a5,a5,32
    80000cb8:	fe078ce3          	beqz	a5,80000cb0 <uartputc_sync+0x44>
    ;
  WriteReg(THR, c);
    80000cbc:	0ff4f513          	zext.b	a0,s1
    80000cc0:	100007b7          	lui	a5,0x10000
    80000cc4:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  if(panicking == 0)
    80000cc8:	0000a797          	auipc	a5,0xa
    80000ccc:	cdc7a783          	lw	a5,-804(a5) # 8000a9a4 <panicking>
    80000cd0:	00078c63          	beqz	a5,80000ce8 <uartputc_sync+0x7c>
    pop_off();
}
    80000cd4:	01813083          	ld	ra,24(sp)
    80000cd8:	01013403          	ld	s0,16(sp)
    80000cdc:	00813483          	ld	s1,8(sp)
    80000ce0:	02010113          	addi	sp,sp,32
    80000ce4:	00008067          	ret
    pop_off();
    80000ce8:	00000097          	auipc	ra,0x0
    80000cec:	448080e7          	jalr	1096(ra) # 80001130 <pop_off>
}
    80000cf0:	fe5ff06f          	j	80000cd4 <uartputc_sync+0x68>

0000000080000cf4 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000cf4:	ff010113          	addi	sp,sp,-16
    80000cf8:	00813423          	sd	s0,8(sp)
    80000cfc:	01010413          	addi	s0,sp,16
  if(ReadReg(LSR) & LSR_RX_READY){
    80000d00:	100007b7          	lui	a5,0x10000
    80000d04:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000d08:	0017f793          	andi	a5,a5,1
    80000d0c:	00078c63          	beqz	a5,80000d24 <uartgetc+0x30>
    // input data is ready.
    return ReadReg(RHR);
    80000d10:	100007b7          	lui	a5,0x10000
    80000d14:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000d18:	00813403          	ld	s0,8(sp)
    80000d1c:	01010113          	addi	sp,sp,16
    80000d20:	00008067          	ret
    return -1;
    80000d24:	fff00513          	li	a0,-1
    80000d28:	ff1ff06f          	j	80000d18 <uartgetc+0x24>

0000000080000d2c <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000d2c:	fe010113          	addi	sp,sp,-32
    80000d30:	00113c23          	sd	ra,24(sp)
    80000d34:	00813823          	sd	s0,16(sp)
    80000d38:	00913423          	sd	s1,8(sp)
    80000d3c:	02010413          	addi	s0,sp,32
  ReadReg(ISR); // acknowledge the interrupt
    80000d40:	100004b7          	lui	s1,0x10000
    80000d44:	0024c783          	lbu	a5,2(s1) # 10000002 <_entry-0x6ffffffe>

  acquire(&tx_lock);
    80000d48:	00012517          	auipc	a0,0x12
    80000d4c:	d4850513          	addi	a0,a0,-696 # 80012a90 <tx_lock>
    80000d50:	00000097          	auipc	ra,0x0
    80000d54:	368080e7          	jalr	872(ra) # 800010b8 <acquire>
  if(ReadReg(LSR) & LSR_TX_IDLE){
    80000d58:	0054c783          	lbu	a5,5(s1)
    80000d5c:	0207f793          	andi	a5,a5,32
    80000d60:	00079e63          	bnez	a5,80000d7c <uartintr+0x50>
    // UART finished transmitting; wake up sending thread.
    tx_busy = 0;
    wakeup(&tx_chan);
  }
  release(&tx_lock);
    80000d64:	00012517          	auipc	a0,0x12
    80000d68:	d2c50513          	addi	a0,a0,-724 # 80012a90 <tx_lock>
    80000d6c:	00000097          	auipc	ra,0x0
    80000d70:	444080e7          	jalr	1092(ra) # 800011b0 <release>

  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000d74:	fff00493          	li	s1,-1
    80000d78:	0280006f          	j	80000da0 <uartintr+0x74>
    tx_busy = 0;
    80000d7c:	0000a797          	auipc	a5,0xa
    80000d80:	c207a823          	sw	zero,-976(a5) # 8000a9ac <tx_busy>
    wakeup(&tx_chan);
    80000d84:	0000a517          	auipc	a0,0xa
    80000d88:	c2450513          	addi	a0,a0,-988 # 8000a9a8 <tx_chan>
    80000d8c:	00002097          	auipc	ra,0x2
    80000d90:	3a4080e7          	jalr	932(ra) # 80003130 <wakeup>
    80000d94:	fd1ff06f          	j	80000d64 <uartintr+0x38>
      break;
    consoleintr(c);
    80000d98:	fffff097          	auipc	ra,0xfffff
    80000d9c:	608080e7          	jalr	1544(ra) # 800003a0 <consoleintr>
    int c = uartgetc();
    80000da0:	00000097          	auipc	ra,0x0
    80000da4:	f54080e7          	jalr	-172(ra) # 80000cf4 <uartgetc>
    if(c == -1)
    80000da8:	fe9518e3          	bne	a0,s1,80000d98 <uartintr+0x6c>
  }
}
    80000dac:	01813083          	ld	ra,24(sp)
    80000db0:	01013403          	ld	s0,16(sp)
    80000db4:	00813483          	ld	s1,8(sp)
    80000db8:	02010113          	addi	sp,sp,32
    80000dbc:	00008067          	ret

0000000080000dc0 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000dc0:	fe010113          	addi	sp,sp,-32
    80000dc4:	00113c23          	sd	ra,24(sp)
    80000dc8:	00813823          	sd	s0,16(sp)
    80000dcc:	00913423          	sd	s1,8(sp)
    80000dd0:	01213023          	sd	s2,0(sp)
    80000dd4:	02010413          	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000dd8:	03451793          	slli	a5,a0,0x34
    80000ddc:	06079a63          	bnez	a5,80000e50 <kfree+0x90>
    80000de0:	00050493          	mv	s1,a0
    80000de4:	00023797          	auipc	a5,0x23
    80000de8:	ef478793          	addi	a5,a5,-268 # 80023cd8 <end>
    80000dec:	06f56263          	bltu	a0,a5,80000e50 <kfree+0x90>
    80000df0:	01100793          	li	a5,17
    80000df4:	01b79793          	slli	a5,a5,0x1b
    80000df8:	04f57c63          	bgeu	a0,a5,80000e50 <kfree+0x90>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);  //1个4KB，
    80000dfc:	00001637          	lui	a2,0x1
    80000e00:	00100593          	li	a1,1
    80000e04:	00000097          	auipc	ra,0x0
    80000e08:	40c080e7          	jalr	1036(ra) # 80001210 <memset>

  r = (struct run*)pa;
  acquire(&kmem.lock);
    80000e0c:	00012917          	auipc	s2,0x12
    80000e10:	c9c90913          	addi	s2,s2,-868 # 80012aa8 <kmem>
    80000e14:	00090513          	mv	a0,s2
    80000e18:	00000097          	auipc	ra,0x0
    80000e1c:	2a0080e7          	jalr	672(ra) # 800010b8 <acquire>
  r->next = kmem.freelist;
    80000e20:	01893783          	ld	a5,24(s2)
    80000e24:	00f4b023          	sd	a5,0(s1)
  kmem.freelist = r;
    80000e28:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000e2c:	00090513          	mv	a0,s2
    80000e30:	00000097          	auipc	ra,0x0
    80000e34:	380080e7          	jalr	896(ra) # 800011b0 <release>
}
    80000e38:	01813083          	ld	ra,24(sp)
    80000e3c:	01013403          	ld	s0,16(sp)
    80000e40:	00813483          	ld	s1,8(sp)
    80000e44:	00013903          	ld	s2,0(sp)
    80000e48:	02010113          	addi	sp,sp,32
    80000e4c:	00008067          	ret
    panic("kfree");
    80000e50:	00009517          	auipc	a0,0x9
    80000e54:	20850513          	addi	a0,a0,520 # 8000a058 <digits+0x20>
    80000e58:	00000097          	auipc	ra,0x0
    80000e5c:	c28080e7          	jalr	-984(ra) # 80000a80 <panic>

0000000080000e60 <freerange>:
{
    80000e60:	fd010113          	addi	sp,sp,-48
    80000e64:	02113423          	sd	ra,40(sp)
    80000e68:	02813023          	sd	s0,32(sp)
    80000e6c:	00913c23          	sd	s1,24(sp)
    80000e70:	01213823          	sd	s2,16(sp)
    80000e74:	01313423          	sd	s3,8(sp)
    80000e78:	01413023          	sd	s4,0(sp)
    80000e7c:	03010413          	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000e80:	000017b7          	lui	a5,0x1
    80000e84:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000e88:	00e504b3          	add	s1,a0,a4
    80000e8c:	fffff737          	lui	a4,0xfffff
    80000e90:	00e4f4b3          	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000e94:	00f484b3          	add	s1,s1,a5
    80000e98:	0295e263          	bltu	a1,s1,80000ebc <freerange+0x5c>
    80000e9c:	00058913          	mv	s2,a1
    kfree(p);
    80000ea0:	fffffa37          	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ea4:	000019b7          	lui	s3,0x1
    kfree(p);
    80000ea8:	01448533          	add	a0,s1,s4
    80000eac:	00000097          	auipc	ra,0x0
    80000eb0:	f14080e7          	jalr	-236(ra) # 80000dc0 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000eb4:	013484b3          	add	s1,s1,s3
    80000eb8:	fe9978e3          	bgeu	s2,s1,80000ea8 <freerange+0x48>
}
    80000ebc:	02813083          	ld	ra,40(sp)
    80000ec0:	02013403          	ld	s0,32(sp)
    80000ec4:	01813483          	ld	s1,24(sp)
    80000ec8:	01013903          	ld	s2,16(sp)
    80000ecc:	00813983          	ld	s3,8(sp)
    80000ed0:	00013a03          	ld	s4,0(sp)
    80000ed4:	03010113          	addi	sp,sp,48
    80000ed8:	00008067          	ret

0000000080000edc <kinit>:
{
    80000edc:	ff010113          	addi	sp,sp,-16
    80000ee0:	00113423          	sd	ra,8(sp)
    80000ee4:	00813023          	sd	s0,0(sp)
    80000ee8:	01010413          	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000eec:	00009597          	auipc	a1,0x9
    80000ef0:	17458593          	addi	a1,a1,372 # 8000a060 <digits+0x28>
    80000ef4:	00012517          	auipc	a0,0x12
    80000ef8:	bb450513          	addi	a0,a0,-1100 # 80012aa8 <kmem>
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	0d8080e7          	jalr	216(ra) # 80000fd4 <initlock>
  printf("freerange开始执行\n");
    80000f04:	00009517          	auipc	a0,0x9
    80000f08:	16450513          	addi	a0,a0,356 # 8000a068 <digits+0x30>
    80000f0c:	fffff097          	auipc	ra,0xfffff
    80000f10:	79c080e7          	jalr	1948(ra) # 800006a8 <printf>
  freerange(end, (void*)PHYSTOP);
    80000f14:	01100593          	li	a1,17
    80000f18:	01b59593          	slli	a1,a1,0x1b
    80000f1c:	00023517          	auipc	a0,0x23
    80000f20:	dbc50513          	addi	a0,a0,-580 # 80023cd8 <end>
    80000f24:	00000097          	auipc	ra,0x0
    80000f28:	f3c080e7          	jalr	-196(ra) # 80000e60 <freerange>
  printf("freerange执行完毕\n");
    80000f2c:	00009517          	auipc	a0,0x9
    80000f30:	15450513          	addi	a0,a0,340 # 8000a080 <digits+0x48>
    80000f34:	fffff097          	auipc	ra,0xfffff
    80000f38:	774080e7          	jalr	1908(ra) # 800006a8 <printf>
}
    80000f3c:	00813083          	ld	ra,8(sp)
    80000f40:	00013403          	ld	s0,0(sp)
    80000f44:	01010113          	addi	sp,sp,16
    80000f48:	00008067          	ret

0000000080000f4c <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000f4c:	fe010113          	addi	sp,sp,-32
    80000f50:	00113c23          	sd	ra,24(sp)
    80000f54:	00813823          	sd	s0,16(sp)
    80000f58:	00913423          	sd	s1,8(sp)
    80000f5c:	02010413          	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);            //fence
    80000f60:	00012497          	auipc	s1,0x12
    80000f64:	b4848493          	addi	s1,s1,-1208 # 80012aa8 <kmem>
    80000f68:	00048513          	mv	a0,s1
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	14c080e7          	jalr	332(ra) # 800010b8 <acquire>
  r = kmem.freelist;
    80000f74:	0184b483          	ld	s1,24(s1)
  if(r)
    80000f78:	04048463          	beqz	s1,80000fc0 <kalloc+0x74>
    kmem.freelist = r->next;
    80000f7c:	0004b783          	ld	a5,0(s1)
    80000f80:	00012517          	auipc	a0,0x12
    80000f84:	b2850513          	addi	a0,a0,-1240 # 80012aa8 <kmem>
    80000f88:	00f53c23          	sd	a5,24(a0)
  release(&kmem.lock);
    80000f8c:	00000097          	auipc	ra,0x0
    80000f90:	224080e7          	jalr	548(ra) # 800011b0 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000f94:	00001637          	lui	a2,0x1
    80000f98:	00500593          	li	a1,5
    80000f9c:	00048513          	mv	a0,s1
    80000fa0:	00000097          	auipc	ra,0x0
    80000fa4:	270080e7          	jalr	624(ra) # 80001210 <memset>
  return (void*)r;
}
    80000fa8:	00048513          	mv	a0,s1
    80000fac:	01813083          	ld	ra,24(sp)
    80000fb0:	01013403          	ld	s0,16(sp)
    80000fb4:	00813483          	ld	s1,8(sp)
    80000fb8:	02010113          	addi	sp,sp,32
    80000fbc:	00008067          	ret
  release(&kmem.lock);
    80000fc0:	00012517          	auipc	a0,0x12
    80000fc4:	ae850513          	addi	a0,a0,-1304 # 80012aa8 <kmem>
    80000fc8:	00000097          	auipc	ra,0x0
    80000fcc:	1e8080e7          	jalr	488(ra) # 800011b0 <release>
  if(r)
    80000fd0:	fd9ff06f          	j	80000fa8 <kalloc+0x5c>

0000000080000fd4 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000fd4:	ff010113          	addi	sp,sp,-16
    80000fd8:	00813423          	sd	s0,8(sp)
    80000fdc:	01010413          	addi	s0,sp,16
  lk->name = name;
    80000fe0:	00b53423          	sd	a1,8(a0)
  lk->locked = 0;
    80000fe4:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000fe8:	00053823          	sd	zero,16(a0)
}
    80000fec:	00813403          	ld	s0,8(sp)
    80000ff0:	01010113          	addi	sp,sp,16
    80000ff4:	00008067          	ret

0000000080000ff8 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000ff8:	00052783          	lw	a5,0(a0)
    80000ffc:	00079663          	bnez	a5,80001008 <holding+0x10>
    80001000:	00000513          	li	a0,0
  return r;
}
    80001004:	00008067          	ret
{
    80001008:	fe010113          	addi	sp,sp,-32
    8000100c:	00113c23          	sd	ra,24(sp)
    80001010:	00813823          	sd	s0,16(sp)
    80001014:	00913423          	sd	s1,8(sp)
    80001018:	02010413          	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    8000101c:	01053483          	ld	s1,16(a0)
    80001020:	00001097          	auipc	ra,0x1
    80001024:	698080e7          	jalr	1688(ra) # 800026b8 <mycpu>
    80001028:	40a48533          	sub	a0,s1,a0
    8000102c:	00153513          	seqz	a0,a0
}
    80001030:	01813083          	ld	ra,24(sp)
    80001034:	01013403          	ld	s0,16(sp)
    80001038:	00813483          	ld	s1,8(sp)
    8000103c:	02010113          	addi	sp,sp,32
    80001040:	00008067          	ret

0000000080001044 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80001044:	fe010113          	addi	sp,sp,-32
    80001048:	00113c23          	sd	ra,24(sp)
    8000104c:	00813823          	sd	s0,16(sp)
    80001050:	00913423          	sd	s1,8(sp)
    80001054:	02010413          	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001058:	100024f3          	csrr	s1,sstatus
    8000105c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001060:	ffd7f793          	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001064:	10079073          	csrw	sstatus,a5

  // disable interrupts to prevent an involuntary context
  // switch while using mycpu().
  intr_off();

  if(mycpu()->noff == 0)
    80001068:	00001097          	auipc	ra,0x1
    8000106c:	650080e7          	jalr	1616(ra) # 800026b8 <mycpu>
    80001070:	07852783          	lw	a5,120(a0)
    80001074:	02078663          	beqz	a5,800010a0 <push_off+0x5c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80001078:	00001097          	auipc	ra,0x1
    8000107c:	640080e7          	jalr	1600(ra) # 800026b8 <mycpu>
    80001080:	07852783          	lw	a5,120(a0)
    80001084:	0017879b          	addiw	a5,a5,1
    80001088:	06f52c23          	sw	a5,120(a0)
}
    8000108c:	01813083          	ld	ra,24(sp)
    80001090:	01013403          	ld	s0,16(sp)
    80001094:	00813483          	ld	s1,8(sp)
    80001098:	02010113          	addi	sp,sp,32
    8000109c:	00008067          	ret
    mycpu()->intena = old;
    800010a0:	00001097          	auipc	ra,0x1
    800010a4:	618080e7          	jalr	1560(ra) # 800026b8 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    800010a8:	0014d493          	srli	s1,s1,0x1
    800010ac:	0014f493          	andi	s1,s1,1
    800010b0:	06952e23          	sw	s1,124(a0)
    800010b4:	fc5ff06f          	j	80001078 <push_off+0x34>

00000000800010b8 <acquire>:
{
    800010b8:	fe010113          	addi	sp,sp,-32
    800010bc:	00113c23          	sd	ra,24(sp)
    800010c0:	00813823          	sd	s0,16(sp)
    800010c4:	00913423          	sd	s1,8(sp)
    800010c8:	02010413          	addi	s0,sp,32
    800010cc:	00050493          	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    800010d0:	00000097          	auipc	ra,0x0
    800010d4:	f74080e7          	jalr	-140(ra) # 80001044 <push_off>
  if(holding(lk))
    800010d8:	00048513          	mv	a0,s1
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	f1c080e7          	jalr	-228(ra) # 80000ff8 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    800010e4:	00100713          	li	a4,1
  if(holding(lk))
    800010e8:	02051c63          	bnez	a0,80001120 <acquire+0x68>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    800010ec:	00070793          	mv	a5,a4
    800010f0:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    800010f4:	0007879b          	sext.w	a5,a5
    800010f8:	fe079ae3          	bnez	a5,800010ec <acquire+0x34>
  __sync_synchronize();
    800010fc:	0ff0000f          	fence
  lk->cpu = mycpu();
    80001100:	00001097          	auipc	ra,0x1
    80001104:	5b8080e7          	jalr	1464(ra) # 800026b8 <mycpu>
    80001108:	00a4b823          	sd	a0,16(s1)
}
    8000110c:	01813083          	ld	ra,24(sp)
    80001110:	01013403          	ld	s0,16(sp)
    80001114:	00813483          	ld	s1,8(sp)
    80001118:	02010113          	addi	sp,sp,32
    8000111c:	00008067          	ret
    panic("acquire");
    80001120:	00009517          	auipc	a0,0x9
    80001124:	f7850513          	addi	a0,a0,-136 # 8000a098 <digits+0x60>
    80001128:	00000097          	auipc	ra,0x0
    8000112c:	958080e7          	jalr	-1704(ra) # 80000a80 <panic>

0000000080001130 <pop_off>:

void
pop_off(void)
{
    80001130:	ff010113          	addi	sp,sp,-16
    80001134:	00113423          	sd	ra,8(sp)
    80001138:	00813023          	sd	s0,0(sp)
    8000113c:	01010413          	addi	s0,sp,16
  struct cpu *c = mycpu();
    80001140:	00001097          	auipc	ra,0x1
    80001144:	578080e7          	jalr	1400(ra) # 800026b8 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001148:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000114c:	0027f793          	andi	a5,a5,2
  if(intr_get())
    80001150:	04079063          	bnez	a5,80001190 <pop_off+0x60>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80001154:	07852783          	lw	a5,120(a0)
    80001158:	04f05463          	blez	a5,800011a0 <pop_off+0x70>
    panic("pop_off");
  c->noff -= 1;
    8000115c:	fff7879b          	addiw	a5,a5,-1
    80001160:	0007871b          	sext.w	a4,a5
    80001164:	06f52c23          	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80001168:	00071c63          	bnez	a4,80001180 <pop_off+0x50>
    8000116c:	07c52783          	lw	a5,124(a0)
    80001170:	00078863          	beqz	a5,80001180 <pop_off+0x50>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001174:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001178:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000117c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80001180:	00813083          	ld	ra,8(sp)
    80001184:	00013403          	ld	s0,0(sp)
    80001188:	01010113          	addi	sp,sp,16
    8000118c:	00008067          	ret
    panic("pop_off - interruptible");
    80001190:	00009517          	auipc	a0,0x9
    80001194:	f1050513          	addi	a0,a0,-240 # 8000a0a0 <digits+0x68>
    80001198:	00000097          	auipc	ra,0x0
    8000119c:	8e8080e7          	jalr	-1816(ra) # 80000a80 <panic>
    panic("pop_off");
    800011a0:	00009517          	auipc	a0,0x9
    800011a4:	f1850513          	addi	a0,a0,-232 # 8000a0b8 <digits+0x80>
    800011a8:	00000097          	auipc	ra,0x0
    800011ac:	8d8080e7          	jalr	-1832(ra) # 80000a80 <panic>

00000000800011b0 <release>:
{
    800011b0:	fe010113          	addi	sp,sp,-32
    800011b4:	00113c23          	sd	ra,24(sp)
    800011b8:	00813823          	sd	s0,16(sp)
    800011bc:	00913423          	sd	s1,8(sp)
    800011c0:	02010413          	addi	s0,sp,32
    800011c4:	00050493          	mv	s1,a0
  if(!holding(lk))
    800011c8:	00000097          	auipc	ra,0x0
    800011cc:	e30080e7          	jalr	-464(ra) # 80000ff8 <holding>
    800011d0:	02050863          	beqz	a0,80001200 <release+0x50>
  lk->cpu = 0;
    800011d4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    800011d8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    800011dc:	0f50000f          	fence	iorw,ow
    800011e0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f4c080e7          	jalr	-180(ra) # 80001130 <pop_off>
}
    800011ec:	01813083          	ld	ra,24(sp)
    800011f0:	01013403          	ld	s0,16(sp)
    800011f4:	00813483          	ld	s1,8(sp)
    800011f8:	02010113          	addi	sp,sp,32
    800011fc:	00008067          	ret
    panic("release");
    80001200:	00009517          	auipc	a0,0x9
    80001204:	ec050513          	addi	a0,a0,-320 # 8000a0c0 <digits+0x88>
    80001208:	00000097          	auipc	ra,0x0
    8000120c:	878080e7          	jalr	-1928(ra) # 80000a80 <panic>

0000000080001210 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80001210:	ff010113          	addi	sp,sp,-16
    80001214:	00813423          	sd	s0,8(sp)
    80001218:	01010413          	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    8000121c:	02060063          	beqz	a2,8000123c <memset+0x2c>
    80001220:	00050793          	mv	a5,a0
    80001224:	02061613          	slli	a2,a2,0x20
    80001228:	02065613          	srli	a2,a2,0x20
    8000122c:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80001230:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80001234:	00178793          	addi	a5,a5,1
    80001238:	fee79ce3          	bne	a5,a4,80001230 <memset+0x20>
  }
  return dst;
}
    8000123c:	00813403          	ld	s0,8(sp)
    80001240:	01010113          	addi	sp,sp,16
    80001244:	00008067          	ret

0000000080001248 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80001248:	ff010113          	addi	sp,sp,-16
    8000124c:	00813423          	sd	s0,8(sp)
    80001250:	01010413          	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80001254:	04060463          	beqz	a2,8000129c <memcmp+0x54>
    80001258:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    8000125c:	02069693          	slli	a3,a3,0x20
    80001260:	0206d693          	srli	a3,a3,0x20
    80001264:	00168693          	addi	a3,a3,1
    80001268:	00d506b3          	add	a3,a0,a3
    if(*s1 != *s2)
    8000126c:	00054783          	lbu	a5,0(a0)
    80001270:	0005c703          	lbu	a4,0(a1)
    80001274:	00e79c63          	bne	a5,a4,8000128c <memcmp+0x44>
      return *s1 - *s2;
    s1++, s2++;
    80001278:	00150513          	addi	a0,a0,1
    8000127c:	00158593          	addi	a1,a1,1
  while(n-- > 0){
    80001280:	fed516e3          	bne	a0,a3,8000126c <memcmp+0x24>
  }

  return 0;
    80001284:	00000513          	li	a0,0
    80001288:	0080006f          	j	80001290 <memcmp+0x48>
      return *s1 - *s2;
    8000128c:	40e7853b          	subw	a0,a5,a4
}
    80001290:	00813403          	ld	s0,8(sp)
    80001294:	01010113          	addi	sp,sp,16
    80001298:	00008067          	ret
  return 0;
    8000129c:	00000513          	li	a0,0
    800012a0:	ff1ff06f          	j	80001290 <memcmp+0x48>

00000000800012a4 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    800012a4:	ff010113          	addi	sp,sp,-16
    800012a8:	00813423          	sd	s0,8(sp)
    800012ac:	01010413          	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    800012b0:	02060663          	beqz	a2,800012dc <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    800012b4:	02a5ea63          	bltu	a1,a0,800012e8 <memmove+0x44>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    800012b8:	02061613          	slli	a2,a2,0x20
    800012bc:	02065613          	srli	a2,a2,0x20
    800012c0:	00c587b3          	add	a5,a1,a2
{
    800012c4:	00050713          	mv	a4,a0
      *d++ = *s++;
    800012c8:	00158593          	addi	a1,a1,1
    800012cc:	00170713          	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdb329>
    800012d0:	fff5c683          	lbu	a3,-1(a1)
    800012d4:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    800012d8:	fef598e3          	bne	a1,a5,800012c8 <memmove+0x24>

  return dst;
}
    800012dc:	00813403          	ld	s0,8(sp)
    800012e0:	01010113          	addi	sp,sp,16
    800012e4:	00008067          	ret
  if(s < d && s + n > d){
    800012e8:	02061693          	slli	a3,a2,0x20
    800012ec:	0206d693          	srli	a3,a3,0x20
    800012f0:	00d58733          	add	a4,a1,a3
    800012f4:	fce572e3          	bgeu	a0,a4,800012b8 <memmove+0x14>
    d += n;
    800012f8:	00d506b3          	add	a3,a0,a3
    while(n-- > 0)
    800012fc:	fff6079b          	addiw	a5,a2,-1
    80001300:	02079793          	slli	a5,a5,0x20
    80001304:	0207d793          	srli	a5,a5,0x20
    80001308:	fff7c793          	not	a5,a5
    8000130c:	00f707b3          	add	a5,a4,a5
      *--d = *--s;
    80001310:	fff70713          	addi	a4,a4,-1
    80001314:	fff68693          	addi	a3,a3,-1
    80001318:	00074603          	lbu	a2,0(a4)
    8000131c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80001320:	fee798e3          	bne	a5,a4,80001310 <memmove+0x6c>
    80001324:	fb9ff06f          	j	800012dc <memmove+0x38>

0000000080001328 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80001328:	ff010113          	addi	sp,sp,-16
    8000132c:	00113423          	sd	ra,8(sp)
    80001330:	00813023          	sd	s0,0(sp)
    80001334:	01010413          	addi	s0,sp,16
  return memmove(dst, src, n);
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	f6c080e7          	jalr	-148(ra) # 800012a4 <memmove>
}
    80001340:	00813083          	ld	ra,8(sp)
    80001344:	00013403          	ld	s0,0(sp)
    80001348:	01010113          	addi	sp,sp,16
    8000134c:	00008067          	ret

0000000080001350 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80001350:	ff010113          	addi	sp,sp,-16
    80001354:	00813423          	sd	s0,8(sp)
    80001358:	01010413          	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    8000135c:	02060663          	beqz	a2,80001388 <strncmp+0x38>
    80001360:	00054783          	lbu	a5,0(a0)
    80001364:	02078663          	beqz	a5,80001390 <strncmp+0x40>
    80001368:	0005c703          	lbu	a4,0(a1)
    8000136c:	02f71263          	bne	a4,a5,80001390 <strncmp+0x40>
    n--, p++, q++;
    80001370:	fff6061b          	addiw	a2,a2,-1
    80001374:	00150513          	addi	a0,a0,1
    80001378:	00158593          	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    8000137c:	fe0612e3          	bnez	a2,80001360 <strncmp+0x10>
  if(n == 0)
    return 0;
    80001380:	00000513          	li	a0,0
    80001384:	01c0006f          	j	800013a0 <strncmp+0x50>
    80001388:	00000513          	li	a0,0
    8000138c:	0140006f          	j	800013a0 <strncmp+0x50>
  if(n == 0)
    80001390:	00060e63          	beqz	a2,800013ac <strncmp+0x5c>
  return (uchar)*p - (uchar)*q;
    80001394:	00054503          	lbu	a0,0(a0)
    80001398:	0005c783          	lbu	a5,0(a1)
    8000139c:	40f5053b          	subw	a0,a0,a5
}
    800013a0:	00813403          	ld	s0,8(sp)
    800013a4:	01010113          	addi	sp,sp,16
    800013a8:	00008067          	ret
    return 0;
    800013ac:	00000513          	li	a0,0
    800013b0:	ff1ff06f          	j	800013a0 <strncmp+0x50>

00000000800013b4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    800013b4:	ff010113          	addi	sp,sp,-16
    800013b8:	00813423          	sd	s0,8(sp)
    800013bc:	01010413          	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    800013c0:	00050713          	mv	a4,a0
    800013c4:	00060813          	mv	a6,a2
    800013c8:	fff6061b          	addiw	a2,a2,-1
    800013cc:	01005c63          	blez	a6,800013e4 <strncpy+0x30>
    800013d0:	00170713          	addi	a4,a4,1
    800013d4:	0005c783          	lbu	a5,0(a1)
    800013d8:	fef70fa3          	sb	a5,-1(a4)
    800013dc:	00158593          	addi	a1,a1,1
    800013e0:	fe0792e3          	bnez	a5,800013c4 <strncpy+0x10>
    ;
  while(n-- > 0)
    800013e4:	00070693          	mv	a3,a4
    800013e8:	00c05e63          	blez	a2,80001404 <strncpy+0x50>
    *s++ = 0;
    800013ec:	00168693          	addi	a3,a3,1
    800013f0:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    800013f4:	40d707bb          	subw	a5,a4,a3
    800013f8:	fff7879b          	addiw	a5,a5,-1
    800013fc:	010787bb          	addw	a5,a5,a6
    80001400:	fef046e3          	bgtz	a5,800013ec <strncpy+0x38>
  return os;
}
    80001404:	00813403          	ld	s0,8(sp)
    80001408:	01010113          	addi	sp,sp,16
    8000140c:	00008067          	ret

0000000080001410 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80001410:	ff010113          	addi	sp,sp,-16
    80001414:	00813423          	sd	s0,8(sp)
    80001418:	01010413          	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    8000141c:	02c05a63          	blez	a2,80001450 <safestrcpy+0x40>
    80001420:	fff6069b          	addiw	a3,a2,-1
    80001424:	02069693          	slli	a3,a3,0x20
    80001428:	0206d693          	srli	a3,a3,0x20
    8000142c:	00d586b3          	add	a3,a1,a3
    80001430:	00050793          	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80001434:	00d58c63          	beq	a1,a3,8000144c <safestrcpy+0x3c>
    80001438:	00158593          	addi	a1,a1,1
    8000143c:	00178793          	addi	a5,a5,1
    80001440:	fff5c703          	lbu	a4,-1(a1)
    80001444:	fee78fa3          	sb	a4,-1(a5)
    80001448:	fe0716e3          	bnez	a4,80001434 <safestrcpy+0x24>
    ;
  *s = 0;
    8000144c:	00078023          	sb	zero,0(a5)
  return os;
}
    80001450:	00813403          	ld	s0,8(sp)
    80001454:	01010113          	addi	sp,sp,16
    80001458:	00008067          	ret

000000008000145c <strlen>:

int
strlen(const char *s)
{
    8000145c:	ff010113          	addi	sp,sp,-16
    80001460:	00813423          	sd	s0,8(sp)
    80001464:	01010413          	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80001468:	00054783          	lbu	a5,0(a0)
    8000146c:	02078863          	beqz	a5,8000149c <strlen+0x40>
    80001470:	00150513          	addi	a0,a0,1
    80001474:	00050793          	mv	a5,a0
    80001478:	00100693          	li	a3,1
    8000147c:	40a686bb          	subw	a3,a3,a0
    80001480:	00f6853b          	addw	a0,a3,a5
    80001484:	00178793          	addi	a5,a5,1
    80001488:	fff7c703          	lbu	a4,-1(a5)
    8000148c:	fe071ae3          	bnez	a4,80001480 <strlen+0x24>
    ;
  return n;
}
    80001490:	00813403          	ld	s0,8(sp)
    80001494:	01010113          	addi	sp,sp,16
    80001498:	00008067          	ret
  for(n = 0; s[n]; n++)
    8000149c:	00000513          	li	a0,0
    800014a0:	ff1ff06f          	j	80001490 <strlen+0x34>

00000000800014a4 <main>:
// start() jumps here in supervisor mode on all CPUs.


void
main()
{
    800014a4:	ff010113          	addi	sp,sp,-16
    800014a8:	00113423          	sd	ra,8(sp)
    800014ac:	00813023          	sd	s0,0(sp)
    800014b0:	01010413          	addi	s0,sp,16
  if(cpuid() == 0){
    800014b4:	00001097          	auipc	ra,0x1
    800014b8:	1e4080e7          	jalr	484(ra) # 80002698 <cpuid>

    printf("__sync_synchronize start \n");
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    800014bc:	00009717          	auipc	a4,0x9
    800014c0:	4f470713          	addi	a4,a4,1268 # 8000a9b0 <started>
  if(cpuid() == 0){
    800014c4:	04050863          	beqz	a0,80001514 <main+0x70>
    while(started == 0)
    800014c8:	00072783          	lw	a5,0(a4)
    800014cc:	0007879b          	sext.w	a5,a5
    800014d0:	fe078ce3          	beqz	a5,800014c8 <main+0x24>
      ;
    __sync_synchronize();
    800014d4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    800014d8:	00001097          	auipc	ra,0x1
    800014dc:	1c0080e7          	jalr	448(ra) # 80002698 <cpuid>
    800014e0:	00050593          	mv	a1,a0
    800014e4:	00009517          	auipc	a0,0x9
    800014e8:	d3c50513          	addi	a0,a0,-708 # 8000a220 <digits+0x1e8>
    800014ec:	fffff097          	auipc	ra,0xfffff
    800014f0:	1bc080e7          	jalr	444(ra) # 800006a8 <printf>
    kvminithart();    // turn on paging
    800014f4:	00000097          	auipc	ra,0x0
    800014f8:	1bc080e7          	jalr	444(ra) # 800016b0 <kvminithart>
    trapinithart();   // install kernel trap vector
    800014fc:	00002097          	auipc	ra,0x2
    80001500:	3fc080e7          	jalr	1020(ra) # 800038f8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001504:	00007097          	auipc	ra,0x7
    80001508:	e84080e7          	jalr	-380(ra) # 80008388 <plicinithart>
  }

  scheduler();        
    8000150c:	00002097          	auipc	ra,0x2
    80001510:	920080e7          	jalr	-1760(ra) # 80002e2c <scheduler>
    consoleinit();          
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	064080e7          	jalr	100(ra) # 80000578 <consoleinit>
    printfinit();           
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	5bc080e7          	jalr	1468(ra) # 80000ad8 <printfinit>
    printf("\n");             
    80001524:	00009517          	auipc	a0,0x9
    80001528:	d0c50513          	addi	a0,a0,-756 # 8000a230 <digits+0x1f8>
    8000152c:	fffff097          	auipc	ra,0xfffff
    80001530:	17c080e7          	jalr	380(ra) # 800006a8 <printf>
    printf("xv6 kernel is booting\n");     
    80001534:	00009517          	auipc	a0,0x9
    80001538:	b9450513          	addi	a0,a0,-1132 # 8000a0c8 <digits+0x90>
    8000153c:	fffff097          	auipc	ra,0xfffff
    80001540:	16c080e7          	jalr	364(ra) # 800006a8 <printf>
    printf("\n");  
    80001544:	00009517          	auipc	a0,0x9
    80001548:	cec50513          	addi	a0,a0,-788 # 8000a230 <digits+0x1f8>
    8000154c:	fffff097          	auipc	ra,0xfffff
    80001550:	15c080e7          	jalr	348(ra) # 800006a8 <printf>
    printf("kinit start \n");
    80001554:	00009517          	auipc	a0,0x9
    80001558:	b8c50513          	addi	a0,a0,-1140 # 8000a0e0 <digits+0xa8>
    8000155c:	fffff097          	auipc	ra,0xfffff
    80001560:	14c080e7          	jalr	332(ra) # 800006a8 <printf>
    kinit();         // physical page allocator，   
    80001564:	00000097          	auipc	ra,0x0
    80001568:	978080e7          	jalr	-1672(ra) # 80000edc <kinit>
    printf("kvminit start \n");
    8000156c:	00009517          	auipc	a0,0x9
    80001570:	b8450513          	addi	a0,a0,-1148 # 8000a0f0 <digits+0xb8>
    80001574:	fffff097          	auipc	ra,0xfffff
    80001578:	134080e7          	jalr	308(ra) # 800006a8 <printf>
    kvminit();       // create kernel page table
    8000157c:	00000097          	auipc	ra,0x0
    80001580:	568080e7          	jalr	1384(ra) # 80001ae4 <kvminit>
    printf("kvminithart start \n");
    80001584:	00009517          	auipc	a0,0x9
    80001588:	b7c50513          	addi	a0,a0,-1156 # 8000a100 <digits+0xc8>
    8000158c:	fffff097          	auipc	ra,0xfffff
    80001590:	11c080e7          	jalr	284(ra) # 800006a8 <printf>
    kvminithart();   // turn on paging             //------->
    80001594:	00000097          	auipc	ra,0x0
    80001598:	11c080e7          	jalr	284(ra) # 800016b0 <kvminithart>
    printf("procinit start \n");
    8000159c:	00009517          	auipc	a0,0x9
    800015a0:	b7c50513          	addi	a0,a0,-1156 # 8000a118 <digits+0xe0>
    800015a4:	fffff097          	auipc	ra,0xfffff
    800015a8:	104080e7          	jalr	260(ra) # 800006a8 <printf>
    procinit();      // process table
    800015ac:	00001097          	auipc	ra,0x1
    800015b0:	000080e7          	jalr	ra # 800025ac <procinit>
    printf("trapinit start \n");
    800015b4:	00009517          	auipc	a0,0x9
    800015b8:	b7c50513          	addi	a0,a0,-1156 # 8000a130 <digits+0xf8>
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	0ec080e7          	jalr	236(ra) # 800006a8 <printf>
    trapinit();      // trap vectors
    800015c4:	00002097          	auipc	ra,0x2
    800015c8:	2fc080e7          	jalr	764(ra) # 800038c0 <trapinit>
    printf("trapinithart start \n");
    800015cc:	00009517          	auipc	a0,0x9
    800015d0:	b7c50513          	addi	a0,a0,-1156 # 8000a148 <digits+0x110>
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	0d4080e7          	jalr	212(ra) # 800006a8 <printf>
    trapinithart();  // install kernel trap vector
    800015dc:	00002097          	auipc	ra,0x2
    800015e0:	31c080e7          	jalr	796(ra) # 800038f8 <trapinithart>
    printf("plicinit start \n");
    800015e4:	00009517          	auipc	a0,0x9
    800015e8:	b7c50513          	addi	a0,a0,-1156 # 8000a160 <digits+0x128>
    800015ec:	fffff097          	auipc	ra,0xfffff
    800015f0:	0bc080e7          	jalr	188(ra) # 800006a8 <printf>
    plicinit();      // set up interrupt controller
    800015f4:	00007097          	auipc	ra,0x7
    800015f8:	d6c080e7          	jalr	-660(ra) # 80008360 <plicinit>
    printf("plicinithart start \n");
    800015fc:	00009517          	auipc	a0,0x9
    80001600:	b7c50513          	addi	a0,a0,-1156 # 8000a178 <digits+0x140>
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	0a4080e7          	jalr	164(ra) # 800006a8 <printf>
    plicinithart();  // ask PLIC for device interrupts
    8000160c:	00007097          	auipc	ra,0x7
    80001610:	d7c080e7          	jalr	-644(ra) # 80008388 <plicinithart>
    printf("binit start \n");
    80001614:	00009517          	auipc	a0,0x9
    80001618:	b7c50513          	addi	a0,a0,-1156 # 8000a190 <digits+0x158>
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	08c080e7          	jalr	140(ra) # 800006a8 <printf>
    binit();         // buffer cache
    80001624:	00003097          	auipc	ra,0x3
    80001628:	d70080e7          	jalr	-656(ra) # 80004394 <binit>
    printf("iinit start \n");
    8000162c:	00009517          	auipc	a0,0x9
    80001630:	b7450513          	addi	a0,a0,-1164 # 8000a1a0 <digits+0x168>
    80001634:	fffff097          	auipc	ra,0xfffff
    80001638:	074080e7          	jalr	116(ra) # 800006a8 <printf>
    iinit();         // inode table
    8000163c:	00003097          	auipc	ra,0x3
    80001640:	59c080e7          	jalr	1436(ra) # 80004bd8 <iinit>
    printf("fileinit start \n");
    80001644:	00009517          	auipc	a0,0x9
    80001648:	b6c50513          	addi	a0,a0,-1172 # 8000a1b0 <digits+0x178>
    8000164c:	fffff097          	auipc	ra,0xfffff
    80001650:	05c080e7          	jalr	92(ra) # 800006a8 <printf>
    fileinit();      // file table
    80001654:	00005097          	auipc	ra,0x5
    80001658:	d8c080e7          	jalr	-628(ra) # 800063e0 <fileinit>
    printf("virtio_disk_init start \n");
    8000165c:	00009517          	auipc	a0,0x9
    80001660:	b6c50513          	addi	a0,a0,-1172 # 8000a1c8 <digits+0x190>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	044080e7          	jalr	68(ra) # 800006a8 <printf>
    virtio_disk_init(); // emulated hard disk
    8000166c:	00007097          	auipc	ra,0x7
    80001670:	e88080e7          	jalr	-376(ra) # 800084f4 <virtio_disk_init>
    printf("userinit start \n");
    80001674:	00009517          	auipc	a0,0x9
    80001678:	b7450513          	addi	a0,a0,-1164 # 8000a1e8 <digits+0x1b0>
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	02c080e7          	jalr	44(ra) # 800006a8 <printf>
    userinit();      // first user process
    80001684:	00001097          	auipc	ra,0x1
    80001688:	514080e7          	jalr	1300(ra) # 80002b98 <userinit>
    printf("__sync_synchronize start \n");
    8000168c:	00009517          	auipc	a0,0x9
    80001690:	b7450513          	addi	a0,a0,-1164 # 8000a200 <digits+0x1c8>
    80001694:	fffff097          	auipc	ra,0xfffff
    80001698:	014080e7          	jalr	20(ra) # 800006a8 <printf>
    __sync_synchronize();
    8000169c:	0ff0000f          	fence
    started = 1;
    800016a0:	00100793          	li	a5,1
    800016a4:	00009717          	auipc	a4,0x9
    800016a8:	30f72623          	sw	a5,780(a4) # 8000a9b0 <started>
    800016ac:	e61ff06f          	j	8000150c <main+0x68>

00000000800016b0 <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    800016b0:	ff010113          	addi	sp,sp,-16
    800016b4:	00813423          	sd	s0,8(sp)
    800016b8:	01010413          	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800016bc:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    800016c0:	00009797          	auipc	a5,0x9
    800016c4:	2f87b783          	ld	a5,760(a5) # 8000a9b8 <kernel_pagetable>
    800016c8:	00c7d793          	srli	a5,a5,0xc
    800016cc:	fff00713          	li	a4,-1
    800016d0:	03f71713          	slli	a4,a4,0x3f
    800016d4:	00e7e7b3          	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800016d8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800016dc:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    800016e0:	00813403          	ld	s0,8(sp)
    800016e4:	01010113          	addi	sp,sp,16
    800016e8:	00008067          	ret

00000000800016ec <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800016ec:	fc010113          	addi	sp,sp,-64
    800016f0:	02113c23          	sd	ra,56(sp)
    800016f4:	02813823          	sd	s0,48(sp)
    800016f8:	02913423          	sd	s1,40(sp)
    800016fc:	03213023          	sd	s2,32(sp)
    80001700:	01313c23          	sd	s3,24(sp)
    80001704:	01413823          	sd	s4,16(sp)
    80001708:	01513423          	sd	s5,8(sp)
    8000170c:	01613023          	sd	s6,0(sp)
    80001710:	04010413          	addi	s0,sp,64
    80001714:	00050493          	mv	s1,a0
    80001718:	00058993          	mv	s3,a1
    8000171c:	00060a93          	mv	s5,a2
  if(va >= MAXVA)
    80001720:	fff00793          	li	a5,-1
    80001724:	01a7d793          	srli	a5,a5,0x1a
    80001728:	01e00a13          	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000172c:	00c00b13          	li	s6,12
  if(va >= MAXVA)
    80001730:	04b7f863          	bgeu	a5,a1,80001780 <walk+0x94>
    panic("walk");
    80001734:	00009517          	auipc	a0,0x9
    80001738:	b0450513          	addi	a0,a0,-1276 # 8000a238 <digits+0x200>
    8000173c:	fffff097          	auipc	ra,0xfffff
    80001740:	344080e7          	jalr	836(ra) # 80000a80 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001744:	080a8e63          	beqz	s5,800017e0 <walk+0xf4>
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	804080e7          	jalr	-2044(ra) # 80000f4c <kalloc>
    80001750:	00050493          	mv	s1,a0
    80001754:	06050263          	beqz	a0,800017b8 <walk+0xcc>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001758:	00001637          	lui	a2,0x1
    8000175c:	00000593          	li	a1,0
    80001760:	00000097          	auipc	ra,0x0
    80001764:	ab0080e7          	jalr	-1360(ra) # 80001210 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001768:	00c4d793          	srli	a5,s1,0xc
    8000176c:	00a79793          	slli	a5,a5,0xa
    80001770:	0017e793          	ori	a5,a5,1
    80001774:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001778:	ff7a0a1b          	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdb31f>
    8000177c:	036a0663          	beq	s4,s6,800017a8 <walk+0xbc>
    pte_t *pte = &pagetable[PX(level, va)];
    80001780:	0149d933          	srl	s2,s3,s4
    80001784:	1ff97913          	andi	s2,s2,511
    80001788:	00391913          	slli	s2,s2,0x3
    8000178c:	01248933          	add	s2,s1,s2
    if(*pte & PTE_V) {
    80001790:	00093483          	ld	s1,0(s2)
    80001794:	0014f793          	andi	a5,s1,1
    80001798:	fa0786e3          	beqz	a5,80001744 <walk+0x58>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000179c:	00a4d493          	srli	s1,s1,0xa
    800017a0:	00c49493          	slli	s1,s1,0xc
    800017a4:	fd5ff06f          	j	80001778 <walk+0x8c>
    }
  }
  return &pagetable[PX(0, va)];
    800017a8:	00c9d513          	srli	a0,s3,0xc
    800017ac:	1ff57513          	andi	a0,a0,511
    800017b0:	00351513          	slli	a0,a0,0x3
    800017b4:	00a48533          	add	a0,s1,a0
}
    800017b8:	03813083          	ld	ra,56(sp)
    800017bc:	03013403          	ld	s0,48(sp)
    800017c0:	02813483          	ld	s1,40(sp)
    800017c4:	02013903          	ld	s2,32(sp)
    800017c8:	01813983          	ld	s3,24(sp)
    800017cc:	01013a03          	ld	s4,16(sp)
    800017d0:	00813a83          	ld	s5,8(sp)
    800017d4:	00013b03          	ld	s6,0(sp)
    800017d8:	04010113          	addi	sp,sp,64
    800017dc:	00008067          	ret
        return 0;
    800017e0:	00000513          	li	a0,0
    800017e4:	fd5ff06f          	j	800017b8 <walk+0xcc>

00000000800017e8 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800017e8:	fff00793          	li	a5,-1
    800017ec:	01a7d793          	srli	a5,a5,0x1a
    800017f0:	00b7f663          	bgeu	a5,a1,800017fc <walkaddr+0x14>
    return 0;
    800017f4:	00000513          	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800017f8:	00008067          	ret
{
    800017fc:	ff010113          	addi	sp,sp,-16
    80001800:	00113423          	sd	ra,8(sp)
    80001804:	00813023          	sd	s0,0(sp)
    80001808:	01010413          	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000180c:	00000613          	li	a2,0
    80001810:	00000097          	auipc	ra,0x0
    80001814:	edc080e7          	jalr	-292(ra) # 800016ec <walk>
  if(pte == 0)
    80001818:	02050a63          	beqz	a0,8000184c <walkaddr+0x64>
  if((*pte & PTE_V) == 0)
    8000181c:	00053783          	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001820:	0117f693          	andi	a3,a5,17
    80001824:	01100713          	li	a4,17
    return 0;
    80001828:	00000513          	li	a0,0
  if((*pte & PTE_U) == 0)
    8000182c:	00e68a63          	beq	a3,a4,80001840 <walkaddr+0x58>
}
    80001830:	00813083          	ld	ra,8(sp)
    80001834:	00013403          	ld	s0,0(sp)
    80001838:	01010113          	addi	sp,sp,16
    8000183c:	00008067          	ret
  pa = PTE2PA(*pte);
    80001840:	00a7d793          	srli	a5,a5,0xa
    80001844:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001848:	fe9ff06f          	j	80001830 <walkaddr+0x48>
    return 0;
    8000184c:	00000513          	li	a0,0
    80001850:	fe1ff06f          	j	80001830 <walkaddr+0x48>

0000000080001854 <mappages>:
// va and size MUST be page-aligned.
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001854:	fb010113          	addi	sp,sp,-80
    80001858:	04113423          	sd	ra,72(sp)
    8000185c:	04813023          	sd	s0,64(sp)
    80001860:	02913c23          	sd	s1,56(sp)
    80001864:	03213823          	sd	s2,48(sp)
    80001868:	03313423          	sd	s3,40(sp)
    8000186c:	03413023          	sd	s4,32(sp)
    80001870:	01513c23          	sd	s5,24(sp)
    80001874:	01613823          	sd	s6,16(sp)
    80001878:	01713423          	sd	s7,8(sp)
    8000187c:	05010413          	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001880:	03459793          	slli	a5,a1,0x34
    80001884:	06079c63          	bnez	a5,800018fc <mappages+0xa8>
    80001888:	00050a93          	mv	s5,a0
    8000188c:	00070b13          	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    80001890:	03461793          	slli	a5,a2,0x34
    80001894:	06079c63          	bnez	a5,8000190c <mappages+0xb8>
    panic("mappages: size not aligned");

  if(size == 0)
    80001898:	08060263          	beqz	a2,8000191c <mappages+0xc8>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE;
    8000189c:	fffff7b7          	lui	a5,0xfffff
    800018a0:	00f60633          	add	a2,a2,a5
    800018a4:	00b609b3          	add	s3,a2,a1
  a = va;
    800018a8:	00058913          	mv	s2,a1
    800018ac:	40b68a33          	sub	s4,a3,a1
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800018b0:	00001bb7          	lui	s7,0x1
    800018b4:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800018b8:	00100613          	li	a2,1
    800018bc:	00090593          	mv	a1,s2
    800018c0:	000a8513          	mv	a0,s5
    800018c4:	00000097          	auipc	ra,0x0
    800018c8:	e28080e7          	jalr	-472(ra) # 800016ec <walk>
    800018cc:	06050863          	beqz	a0,8000193c <mappages+0xe8>
    if(*pte & PTE_V)
    800018d0:	00053783          	ld	a5,0(a0)
    800018d4:	0017f793          	andi	a5,a5,1
    800018d8:	04079a63          	bnez	a5,8000192c <mappages+0xd8>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800018dc:	00c4d493          	srli	s1,s1,0xc
    800018e0:	00a49493          	slli	s1,s1,0xa
    800018e4:	0164e4b3          	or	s1,s1,s6
    800018e8:	0014e493          	ori	s1,s1,1
    800018ec:	00953023          	sd	s1,0(a0)
    if(a == last)
    800018f0:	07390e63          	beq	s2,s3,8000196c <mappages+0x118>
    a += PGSIZE;
    800018f4:	01790933          	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800018f8:	fbdff06f          	j	800018b4 <mappages+0x60>
    panic("mappages: va not aligned");
    800018fc:	00009517          	auipc	a0,0x9
    80001900:	94450513          	addi	a0,a0,-1724 # 8000a240 <digits+0x208>
    80001904:	fffff097          	auipc	ra,0xfffff
    80001908:	17c080e7          	jalr	380(ra) # 80000a80 <panic>
    panic("mappages: size not aligned");
    8000190c:	00009517          	auipc	a0,0x9
    80001910:	95450513          	addi	a0,a0,-1708 # 8000a260 <digits+0x228>
    80001914:	fffff097          	auipc	ra,0xfffff
    80001918:	16c080e7          	jalr	364(ra) # 80000a80 <panic>
    panic("mappages: size");
    8000191c:	00009517          	auipc	a0,0x9
    80001920:	96450513          	addi	a0,a0,-1692 # 8000a280 <digits+0x248>
    80001924:	fffff097          	auipc	ra,0xfffff
    80001928:	15c080e7          	jalr	348(ra) # 80000a80 <panic>
      panic("mappages: remap");
    8000192c:	00009517          	auipc	a0,0x9
    80001930:	96450513          	addi	a0,a0,-1692 # 8000a290 <digits+0x258>
    80001934:	fffff097          	auipc	ra,0xfffff
    80001938:	14c080e7          	jalr	332(ra) # 80000a80 <panic>
      return -1;
    8000193c:	fff00513          	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001940:	04813083          	ld	ra,72(sp)
    80001944:	04013403          	ld	s0,64(sp)
    80001948:	03813483          	ld	s1,56(sp)
    8000194c:	03013903          	ld	s2,48(sp)
    80001950:	02813983          	ld	s3,40(sp)
    80001954:	02013a03          	ld	s4,32(sp)
    80001958:	01813a83          	ld	s5,24(sp)
    8000195c:	01013b03          	ld	s6,16(sp)
    80001960:	00813b83          	ld	s7,8(sp)
    80001964:	05010113          	addi	sp,sp,80
    80001968:	00008067          	ret
  return 0;
    8000196c:	00000513          	li	a0,0
    80001970:	fd1ff06f          	j	80001940 <mappages+0xec>

0000000080001974 <kvmmap>:
{
    80001974:	ff010113          	addi	sp,sp,-16
    80001978:	00113423          	sd	ra,8(sp)
    8000197c:	00813023          	sd	s0,0(sp)
    80001980:	01010413          	addi	s0,sp,16
    80001984:	00068793          	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001988:	00060693          	mv	a3,a2
    8000198c:	00078613          	mv	a2,a5
    80001990:	00000097          	auipc	ra,0x0
    80001994:	ec4080e7          	jalr	-316(ra) # 80001854 <mappages>
    80001998:	00051a63          	bnez	a0,800019ac <kvmmap+0x38>
}
    8000199c:	00813083          	ld	ra,8(sp)
    800019a0:	00013403          	ld	s0,0(sp)
    800019a4:	01010113          	addi	sp,sp,16
    800019a8:	00008067          	ret
    panic("kvmmap");
    800019ac:	00009517          	auipc	a0,0x9
    800019b0:	8f450513          	addi	a0,a0,-1804 # 8000a2a0 <digits+0x268>
    800019b4:	fffff097          	auipc	ra,0xfffff
    800019b8:	0cc080e7          	jalr	204(ra) # 80000a80 <panic>

00000000800019bc <kvmmake>:
{
    800019bc:	fe010113          	addi	sp,sp,-32
    800019c0:	00113c23          	sd	ra,24(sp)
    800019c4:	00813823          	sd	s0,16(sp)
    800019c8:	00913423          	sd	s1,8(sp)
    800019cc:	01213023          	sd	s2,0(sp)
    800019d0:	02010413          	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	578080e7          	jalr	1400(ra) # 80000f4c <kalloc>
    800019dc:	00050493          	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800019e0:	00001637          	lui	a2,0x1
    800019e4:	00000593          	li	a1,0
    800019e8:	00000097          	auipc	ra,0x0
    800019ec:	828080e7          	jalr	-2008(ra) # 80001210 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800019f0:	00600713          	li	a4,6
    800019f4:	000016b7          	lui	a3,0x1
    800019f8:	10000637          	lui	a2,0x10000
    800019fc:	100005b7          	lui	a1,0x10000
    80001a00:	00048513          	mv	a0,s1
    80001a04:	00000097          	auipc	ra,0x0
    80001a08:	f70080e7          	jalr	-144(ra) # 80001974 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001a0c:	00600713          	li	a4,6
    80001a10:	000016b7          	lui	a3,0x1
    80001a14:	10001637          	lui	a2,0x10001
    80001a18:	100015b7          	lui	a1,0x10001
    80001a1c:	00048513          	mv	a0,s1
    80001a20:	00000097          	auipc	ra,0x0
    80001a24:	f54080e7          	jalr	-172(ra) # 80001974 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x4000000, PTE_R | PTE_W);
    80001a28:	00600713          	li	a4,6
    80001a2c:	040006b7          	lui	a3,0x4000
    80001a30:	0c000637          	lui	a2,0xc000
    80001a34:	0c0005b7          	lui	a1,0xc000
    80001a38:	00048513          	mv	a0,s1
    80001a3c:	00000097          	auipc	ra,0x0
    80001a40:	f38080e7          	jalr	-200(ra) # 80001974 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001a44:	00008917          	auipc	s2,0x8
    80001a48:	5bc90913          	addi	s2,s2,1468 # 8000a000 <etext>
    80001a4c:	00a00713          	li	a4,10
    80001a50:	80008697          	auipc	a3,0x80008
    80001a54:	5b068693          	addi	a3,a3,1456 # a000 <_entry-0x7fff6000>
    80001a58:	00100613          	li	a2,1
    80001a5c:	01f61613          	slli	a2,a2,0x1f
    80001a60:	00060593          	mv	a1,a2
    80001a64:	00048513          	mv	a0,s1
    80001a68:	00000097          	auipc	ra,0x0
    80001a6c:	f0c080e7          	jalr	-244(ra) # 80001974 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001a70:	00600713          	li	a4,6
    80001a74:	01100693          	li	a3,17
    80001a78:	01b69693          	slli	a3,a3,0x1b
    80001a7c:	412686b3          	sub	a3,a3,s2
    80001a80:	00090613          	mv	a2,s2
    80001a84:	00090593          	mv	a1,s2
    80001a88:	00048513          	mv	a0,s1
    80001a8c:	00000097          	auipc	ra,0x0
    80001a90:	ee8080e7          	jalr	-280(ra) # 80001974 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001a94:	00a00713          	li	a4,10
    80001a98:	000016b7          	lui	a3,0x1
    80001a9c:	00007617          	auipc	a2,0x7
    80001aa0:	56460613          	addi	a2,a2,1380 # 80009000 <_trampoline>
    80001aa4:	040005b7          	lui	a1,0x4000
    80001aa8:	fff58593          	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001aac:	00c59593          	slli	a1,a1,0xc
    80001ab0:	00048513          	mv	a0,s1
    80001ab4:	00000097          	auipc	ra,0x0
    80001ab8:	ec0080e7          	jalr	-320(ra) # 80001974 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001abc:	00048513          	mv	a0,s1
    80001ac0:	00001097          	auipc	ra,0x1
    80001ac4:	a18080e7          	jalr	-1512(ra) # 800024d8 <proc_mapstacks>
}
    80001ac8:	00048513          	mv	a0,s1
    80001acc:	01813083          	ld	ra,24(sp)
    80001ad0:	01013403          	ld	s0,16(sp)
    80001ad4:	00813483          	ld	s1,8(sp)
    80001ad8:	00013903          	ld	s2,0(sp)
    80001adc:	02010113          	addi	sp,sp,32
    80001ae0:	00008067          	ret

0000000080001ae4 <kvminit>:
{
    80001ae4:	ff010113          	addi	sp,sp,-16
    80001ae8:	00113423          	sd	ra,8(sp)
    80001aec:	00813023          	sd	s0,0(sp)
    80001af0:	01010413          	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001af4:	00000097          	auipc	ra,0x0
    80001af8:	ec8080e7          	jalr	-312(ra) # 800019bc <kvmmake>
    80001afc:	00009797          	auipc	a5,0x9
    80001b00:	eaa7be23          	sd	a0,-324(a5) # 8000a9b8 <kernel_pagetable>
}
    80001b04:	00813083          	ld	ra,8(sp)
    80001b08:	00013403          	ld	s0,0(sp)
    80001b0c:	01010113          	addi	sp,sp,16
    80001b10:	00008067          	ret

0000000080001b14 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001b14:	fe010113          	addi	sp,sp,-32
    80001b18:	00113c23          	sd	ra,24(sp)
    80001b1c:	00813823          	sd	s0,16(sp)
    80001b20:	00913423          	sd	s1,8(sp)
    80001b24:	02010413          	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	424080e7          	jalr	1060(ra) # 80000f4c <kalloc>
    80001b30:	00050493          	mv	s1,a0
  if(pagetable == 0)
    80001b34:	00050a63          	beqz	a0,80001b48 <uvmcreate+0x34>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001b38:	00001637          	lui	a2,0x1
    80001b3c:	00000593          	li	a1,0
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	6d0080e7          	jalr	1744(ra) # 80001210 <memset>
  return pagetable;
}
    80001b48:	00048513          	mv	a0,s1
    80001b4c:	01813083          	ld	ra,24(sp)
    80001b50:	01013403          	ld	s0,16(sp)
    80001b54:	00813483          	ld	s1,8(sp)
    80001b58:	02010113          	addi	sp,sp,32
    80001b5c:	00008067          	ret

0000000080001b60 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. It's OK if the mappings don't exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001b60:	fc010113          	addi	sp,sp,-64
    80001b64:	02113c23          	sd	ra,56(sp)
    80001b68:	02813823          	sd	s0,48(sp)
    80001b6c:	02913423          	sd	s1,40(sp)
    80001b70:	03213023          	sd	s2,32(sp)
    80001b74:	01313c23          	sd	s3,24(sp)
    80001b78:	01413823          	sd	s4,16(sp)
    80001b7c:	01513423          	sd	s5,8(sp)
    80001b80:	01613023          	sd	s6,0(sp)
    80001b84:	04010413          	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001b88:	03459793          	slli	a5,a1,0x34
    80001b8c:	04079463          	bnez	a5,80001bd4 <uvmunmap+0x74>
    80001b90:	00050a13          	mv	s4,a0
    80001b94:	00058913          	mv	s2,a1
    80001b98:	00068a93          	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001b9c:	00c61613          	slli	a2,a2,0xc
    80001ba0:	00b609b3          	add	s3,a2,a1
    80001ba4:	00001b37          	lui	s6,0x1
    80001ba8:	0535e463          	bltu	a1,s3,80001bf0 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001bac:	03813083          	ld	ra,56(sp)
    80001bb0:	03013403          	ld	s0,48(sp)
    80001bb4:	02813483          	ld	s1,40(sp)
    80001bb8:	02013903          	ld	s2,32(sp)
    80001bbc:	01813983          	ld	s3,24(sp)
    80001bc0:	01013a03          	ld	s4,16(sp)
    80001bc4:	00813a83          	ld	s5,8(sp)
    80001bc8:	00013b03          	ld	s6,0(sp)
    80001bcc:	04010113          	addi	sp,sp,64
    80001bd0:	00008067          	ret
    panic("uvmunmap: not aligned");
    80001bd4:	00008517          	auipc	a0,0x8
    80001bd8:	6d450513          	addi	a0,a0,1748 # 8000a2a8 <digits+0x270>
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	ea4080e7          	jalr	-348(ra) # 80000a80 <panic>
    *pte = 0;
    80001be4:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001be8:	01690933          	add	s2,s2,s6
    80001bec:	fd3970e3          	bgeu	s2,s3,80001bac <uvmunmap+0x4c>
    if((pte = walk(pagetable, a, 0)) == 0) // leaf page table entry allocated?
    80001bf0:	00000613          	li	a2,0
    80001bf4:	00090593          	mv	a1,s2
    80001bf8:	000a0513          	mv	a0,s4
    80001bfc:	00000097          	auipc	ra,0x0
    80001c00:	af0080e7          	jalr	-1296(ra) # 800016ec <walk>
    80001c04:	00050493          	mv	s1,a0
    80001c08:	fe0500e3          	beqz	a0,80001be8 <uvmunmap+0x88>
    if((*pte & PTE_V) == 0)  // has physical page been allocated?
    80001c0c:	00053783          	ld	a5,0(a0)
    80001c10:	0017f713          	andi	a4,a5,1
    80001c14:	fc070ae3          	beqz	a4,80001be8 <uvmunmap+0x88>
    if(do_free){
    80001c18:	fc0a86e3          	beqz	s5,80001be4 <uvmunmap+0x84>
      uint64 pa = PTE2PA(*pte);
    80001c1c:	00a7d793          	srli	a5,a5,0xa
      kfree((void*)pa);
    80001c20:	00c79513          	slli	a0,a5,0xc
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	19c080e7          	jalr	412(ra) # 80000dc0 <kfree>
    80001c2c:	fb9ff06f          	j	80001be4 <uvmunmap+0x84>

0000000080001c30 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001c30:	fe010113          	addi	sp,sp,-32
    80001c34:	00113c23          	sd	ra,24(sp)
    80001c38:	00813823          	sd	s0,16(sp)
    80001c3c:	00913423          	sd	s1,8(sp)
    80001c40:	02010413          	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001c44:	00058493          	mv	s1,a1
  if(newsz >= oldsz)
    80001c48:	02b67463          	bgeu	a2,a1,80001c70 <uvmdealloc+0x40>
    80001c4c:	00060493          	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001c50:	000017b7          	lui	a5,0x1
    80001c54:	fff78793          	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001c58:	00f60733          	add	a4,a2,a5
    80001c5c:	fffff6b7          	lui	a3,0xfffff
    80001c60:	00d77733          	and	a4,a4,a3
    80001c64:	00f587b3          	add	a5,a1,a5
    80001c68:	00d7f7b3          	and	a5,a5,a3
    80001c6c:	00f76e63          	bltu	a4,a5,80001c88 <uvmdealloc+0x58>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001c70:	00048513          	mv	a0,s1
    80001c74:	01813083          	ld	ra,24(sp)
    80001c78:	01013403          	ld	s0,16(sp)
    80001c7c:	00813483          	ld	s1,8(sp)
    80001c80:	02010113          	addi	sp,sp,32
    80001c84:	00008067          	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001c88:	40e787b3          	sub	a5,a5,a4
    80001c8c:	00c7d793          	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001c90:	00100693          	li	a3,1
    80001c94:	0007861b          	sext.w	a2,a5
    80001c98:	00070593          	mv	a1,a4
    80001c9c:	00000097          	auipc	ra,0x0
    80001ca0:	ec4080e7          	jalr	-316(ra) # 80001b60 <uvmunmap>
    80001ca4:	fcdff06f          	j	80001c70 <uvmdealloc+0x40>

0000000080001ca8 <uvmalloc>:
  if(newsz < oldsz)
    80001ca8:	10b66863          	bltu	a2,a1,80001db8 <uvmalloc+0x110>
{
    80001cac:	fc010113          	addi	sp,sp,-64
    80001cb0:	02113c23          	sd	ra,56(sp)
    80001cb4:	02813823          	sd	s0,48(sp)
    80001cb8:	02913423          	sd	s1,40(sp)
    80001cbc:	03213023          	sd	s2,32(sp)
    80001cc0:	01313c23          	sd	s3,24(sp)
    80001cc4:	01413823          	sd	s4,16(sp)
    80001cc8:	01513423          	sd	s5,8(sp)
    80001ccc:	01613023          	sd	s6,0(sp)
    80001cd0:	04010413          	addi	s0,sp,64
    80001cd4:	00050a93          	mv	s5,a0
    80001cd8:	00060a13          	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001cdc:	000017b7          	lui	a5,0x1
    80001ce0:	fff78793          	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001ce4:	00f585b3          	add	a1,a1,a5
    80001ce8:	fffff7b7          	lui	a5,0xfffff
    80001cec:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001cf0:	0cc9f863          	bgeu	s3,a2,80001dc0 <uvmalloc+0x118>
    80001cf4:	00098913          	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001cf8:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001cfc:	fffff097          	auipc	ra,0xfffff
    80001d00:	250080e7          	jalr	592(ra) # 80000f4c <kalloc>
    80001d04:	00050493          	mv	s1,a0
    if(mem == 0){
    80001d08:	04050463          	beqz	a0,80001d50 <uvmalloc+0xa8>
    memset(mem, 0, PGSIZE);
    80001d0c:	00001637          	lui	a2,0x1
    80001d10:	00000593          	li	a1,0
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	4fc080e7          	jalr	1276(ra) # 80001210 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001d1c:	000b0713          	mv	a4,s6
    80001d20:	00048693          	mv	a3,s1
    80001d24:	00001637          	lui	a2,0x1
    80001d28:	00090593          	mv	a1,s2
    80001d2c:	000a8513          	mv	a0,s5
    80001d30:	00000097          	auipc	ra,0x0
    80001d34:	b24080e7          	jalr	-1244(ra) # 80001854 <mappages>
    80001d38:	04051c63          	bnez	a0,80001d90 <uvmalloc+0xe8>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001d3c:	000017b7          	lui	a5,0x1
    80001d40:	00f90933          	add	s2,s2,a5
    80001d44:	fb496ce3          	bltu	s2,s4,80001cfc <uvmalloc+0x54>
  return newsz;
    80001d48:	000a0513          	mv	a0,s4
    80001d4c:	01c0006f          	j	80001d68 <uvmalloc+0xc0>
      uvmdealloc(pagetable, a, oldsz);
    80001d50:	00098613          	mv	a2,s3
    80001d54:	00090593          	mv	a1,s2
    80001d58:	000a8513          	mv	a0,s5
    80001d5c:	00000097          	auipc	ra,0x0
    80001d60:	ed4080e7          	jalr	-300(ra) # 80001c30 <uvmdealloc>
      return 0;
    80001d64:	00000513          	li	a0,0
}
    80001d68:	03813083          	ld	ra,56(sp)
    80001d6c:	03013403          	ld	s0,48(sp)
    80001d70:	02813483          	ld	s1,40(sp)
    80001d74:	02013903          	ld	s2,32(sp)
    80001d78:	01813983          	ld	s3,24(sp)
    80001d7c:	01013a03          	ld	s4,16(sp)
    80001d80:	00813a83          	ld	s5,8(sp)
    80001d84:	00013b03          	ld	s6,0(sp)
    80001d88:	04010113          	addi	sp,sp,64
    80001d8c:	00008067          	ret
      kfree(mem);
    80001d90:	00048513          	mv	a0,s1
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	02c080e7          	jalr	44(ra) # 80000dc0 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001d9c:	00098613          	mv	a2,s3
    80001da0:	00090593          	mv	a1,s2
    80001da4:	000a8513          	mv	a0,s5
    80001da8:	00000097          	auipc	ra,0x0
    80001dac:	e88080e7          	jalr	-376(ra) # 80001c30 <uvmdealloc>
      return 0;
    80001db0:	00000513          	li	a0,0
    80001db4:	fb5ff06f          	j	80001d68 <uvmalloc+0xc0>
    return oldsz;
    80001db8:	00058513          	mv	a0,a1
}
    80001dbc:	00008067          	ret
  return newsz;
    80001dc0:	00060513          	mv	a0,a2
    80001dc4:	fa5ff06f          	j	80001d68 <uvmalloc+0xc0>

0000000080001dc8 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001dc8:	fd010113          	addi	sp,sp,-48
    80001dcc:	02113423          	sd	ra,40(sp)
    80001dd0:	02813023          	sd	s0,32(sp)
    80001dd4:	00913c23          	sd	s1,24(sp)
    80001dd8:	01213823          	sd	s2,16(sp)
    80001ddc:	01313423          	sd	s3,8(sp)
    80001de0:	01413023          	sd	s4,0(sp)
    80001de4:	03010413          	addi	s0,sp,48
    80001de8:	00050a13          	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001dec:	00050493          	mv	s1,a0
    80001df0:	00001937          	lui	s2,0x1
    80001df4:	01250933          	add	s2,a0,s2
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001df8:	00100993          	li	s3,1
    80001dfc:	0200006f          	j	80001e1c <freewalk+0x54>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001e00:	00a7d793          	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001e04:	00c79513          	slli	a0,a5,0xc
    80001e08:	00000097          	auipc	ra,0x0
    80001e0c:	fc0080e7          	jalr	-64(ra) # 80001dc8 <freewalk>
      pagetable[i] = 0;
    80001e10:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001e14:	00848493          	addi	s1,s1,8
    80001e18:	03248463          	beq	s1,s2,80001e40 <freewalk+0x78>
    pte_t pte = pagetable[i];
    80001e1c:	0004b783          	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001e20:	00f7f713          	andi	a4,a5,15
    80001e24:	fd370ee3          	beq	a4,s3,80001e00 <freewalk+0x38>
    } else if(pte & PTE_V){
    80001e28:	0017f793          	andi	a5,a5,1
    80001e2c:	fe0784e3          	beqz	a5,80001e14 <freewalk+0x4c>
      panic("freewalk: leaf");
    80001e30:	00008517          	auipc	a0,0x8
    80001e34:	49050513          	addi	a0,a0,1168 # 8000a2c0 <digits+0x288>
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	c48080e7          	jalr	-952(ra) # 80000a80 <panic>
    }
  }
  kfree((void*)pagetable);
    80001e40:	000a0513          	mv	a0,s4
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	f7c080e7          	jalr	-132(ra) # 80000dc0 <kfree>
}
    80001e4c:	02813083          	ld	ra,40(sp)
    80001e50:	02013403          	ld	s0,32(sp)
    80001e54:	01813483          	ld	s1,24(sp)
    80001e58:	01013903          	ld	s2,16(sp)
    80001e5c:	00813983          	ld	s3,8(sp)
    80001e60:	00013a03          	ld	s4,0(sp)
    80001e64:	03010113          	addi	sp,sp,48
    80001e68:	00008067          	ret

0000000080001e6c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001e6c:	fe010113          	addi	sp,sp,-32
    80001e70:	00113c23          	sd	ra,24(sp)
    80001e74:	00813823          	sd	s0,16(sp)
    80001e78:	00913423          	sd	s1,8(sp)
    80001e7c:	02010413          	addi	s0,sp,32
    80001e80:	00050493          	mv	s1,a0
  if(sz > 0)
    80001e84:	02059263          	bnez	a1,80001ea8 <uvmfree+0x3c>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001e88:	00048513          	mv	a0,s1
    80001e8c:	00000097          	auipc	ra,0x0
    80001e90:	f3c080e7          	jalr	-196(ra) # 80001dc8 <freewalk>
}
    80001e94:	01813083          	ld	ra,24(sp)
    80001e98:	01013403          	ld	s0,16(sp)
    80001e9c:	00813483          	ld	s1,8(sp)
    80001ea0:	02010113          	addi	sp,sp,32
    80001ea4:	00008067          	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001ea8:	000017b7          	lui	a5,0x1
    80001eac:	fff78793          	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001eb0:	00f585b3          	add	a1,a1,a5
    80001eb4:	00100693          	li	a3,1
    80001eb8:	00c5d613          	srli	a2,a1,0xc
    80001ebc:	00000593          	li	a1,0
    80001ec0:	00000097          	auipc	ra,0x0
    80001ec4:	ca0080e7          	jalr	-864(ra) # 80001b60 <uvmunmap>
    80001ec8:	fc1ff06f          	j	80001e88 <uvmfree+0x1c>

0000000080001ecc <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001ecc:	10060e63          	beqz	a2,80001fe8 <uvmcopy+0x11c>
{
    80001ed0:	fb010113          	addi	sp,sp,-80
    80001ed4:	04113423          	sd	ra,72(sp)
    80001ed8:	04813023          	sd	s0,64(sp)
    80001edc:	02913c23          	sd	s1,56(sp)
    80001ee0:	03213823          	sd	s2,48(sp)
    80001ee4:	03313423          	sd	s3,40(sp)
    80001ee8:	03413023          	sd	s4,32(sp)
    80001eec:	01513c23          	sd	s5,24(sp)
    80001ef0:	01613823          	sd	s6,16(sp)
    80001ef4:	01713423          	sd	s7,8(sp)
    80001ef8:	05010413          	addi	s0,sp,80
    80001efc:	00050a93          	mv	s5,a0
    80001f00:	00058b13          	mv	s6,a1
    80001f04:	00060a13          	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001f08:	00000493          	li	s1,0
    80001f0c:	0100006f          	j	80001f1c <uvmcopy+0x50>
    80001f10:	000017b7          	lui	a5,0x1
    80001f14:	00f484b3          	add	s1,s1,a5
    80001f18:	0b44f063          	bgeu	s1,s4,80001fb8 <uvmcopy+0xec>
    if((pte = walk(old, i, 0)) == 0)
    80001f1c:	00000613          	li	a2,0
    80001f20:	00048593          	mv	a1,s1
    80001f24:	000a8513          	mv	a0,s5
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	7c4080e7          	jalr	1988(ra) # 800016ec <walk>
    80001f30:	fe0500e3          	beqz	a0,80001f10 <uvmcopy+0x44>
      continue;   // page table entry hasn't been allocated
    if((*pte & PTE_V) == 0)
    80001f34:	00053703          	ld	a4,0(a0)
    80001f38:	00177793          	andi	a5,a4,1
    80001f3c:	fc078ae3          	beqz	a5,80001f10 <uvmcopy+0x44>
      continue;   // physical page hasn't been allocated
    pa = PTE2PA(*pte);
    80001f40:	00a75593          	srli	a1,a4,0xa
    80001f44:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001f48:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    80001f4c:	fffff097          	auipc	ra,0xfffff
    80001f50:	000080e7          	jalr	ra # 80000f4c <kalloc>
    80001f54:	00050993          	mv	s3,a0
    80001f58:	04050063          	beqz	a0,80001f98 <uvmcopy+0xcc>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001f5c:	00001637          	lui	a2,0x1
    80001f60:	000b8593          	mv	a1,s7
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	340080e7          	jalr	832(ra) # 800012a4 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001f6c:	00090713          	mv	a4,s2
    80001f70:	00098693          	mv	a3,s3
    80001f74:	00001637          	lui	a2,0x1
    80001f78:	00048593          	mv	a1,s1
    80001f7c:	000b0513          	mv	a0,s6
    80001f80:	00000097          	auipc	ra,0x0
    80001f84:	8d4080e7          	jalr	-1836(ra) # 80001854 <mappages>
    80001f88:	f80504e3          	beqz	a0,80001f10 <uvmcopy+0x44>
      kfree(mem);
    80001f8c:	00098513          	mv	a0,s3
    80001f90:	fffff097          	auipc	ra,0xfffff
    80001f94:	e30080e7          	jalr	-464(ra) # 80000dc0 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001f98:	00100693          	li	a3,1
    80001f9c:	00c4d613          	srli	a2,s1,0xc
    80001fa0:	00000593          	li	a1,0
    80001fa4:	000b0513          	mv	a0,s6
    80001fa8:	00000097          	auipc	ra,0x0
    80001fac:	bb8080e7          	jalr	-1096(ra) # 80001b60 <uvmunmap>
  return -1;
    80001fb0:	fff00513          	li	a0,-1
    80001fb4:	0080006f          	j	80001fbc <uvmcopy+0xf0>
  return 0;
    80001fb8:	00000513          	li	a0,0
}
    80001fbc:	04813083          	ld	ra,72(sp)
    80001fc0:	04013403          	ld	s0,64(sp)
    80001fc4:	03813483          	ld	s1,56(sp)
    80001fc8:	03013903          	ld	s2,48(sp)
    80001fcc:	02813983          	ld	s3,40(sp)
    80001fd0:	02013a03          	ld	s4,32(sp)
    80001fd4:	01813a83          	ld	s5,24(sp)
    80001fd8:	01013b03          	ld	s6,16(sp)
    80001fdc:	00813b83          	ld	s7,8(sp)
    80001fe0:	05010113          	addi	sp,sp,80
    80001fe4:	00008067          	ret
  return 0;
    80001fe8:	00000513          	li	a0,0
}
    80001fec:	00008067          	ret

0000000080001ff0 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001ff0:	ff010113          	addi	sp,sp,-16
    80001ff4:	00113423          	sd	ra,8(sp)
    80001ff8:	00813023          	sd	s0,0(sp)
    80001ffc:	01010413          	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80002000:	00000613          	li	a2,0
    80002004:	fffff097          	auipc	ra,0xfffff
    80002008:	6e8080e7          	jalr	1768(ra) # 800016ec <walk>
  if(pte == 0)
    8000200c:	02050063          	beqz	a0,8000202c <uvmclear+0x3c>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80002010:	00053783          	ld	a5,0(a0)
    80002014:	fef7f793          	andi	a5,a5,-17
    80002018:	00f53023          	sd	a5,0(a0)
}
    8000201c:	00813083          	ld	ra,8(sp)
    80002020:	00013403          	ld	s0,0(sp)
    80002024:	01010113          	addi	sp,sp,16
    80002028:	00008067          	ret
    panic("uvmclear");
    8000202c:	00008517          	auipc	a0,0x8
    80002030:	2a450513          	addi	a0,a0,676 # 8000a2d0 <digits+0x298>
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	a4c080e7          	jalr	-1460(ra) # 80000a80 <panic>

000000008000203c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000203c:	10068663          	beqz	a3,80002148 <copyinstr+0x10c>
{
    80002040:	fb010113          	addi	sp,sp,-80
    80002044:	04113423          	sd	ra,72(sp)
    80002048:	04813023          	sd	s0,64(sp)
    8000204c:	02913c23          	sd	s1,56(sp)
    80002050:	03213823          	sd	s2,48(sp)
    80002054:	03313423          	sd	s3,40(sp)
    80002058:	03413023          	sd	s4,32(sp)
    8000205c:	01513c23          	sd	s5,24(sp)
    80002060:	01613823          	sd	s6,16(sp)
    80002064:	01713423          	sd	s7,8(sp)
    80002068:	05010413          	addi	s0,sp,80
    8000206c:	00050a13          	mv	s4,a0
    80002070:	00058b13          	mv	s6,a1
    80002074:	00060b93          	mv	s7,a2
    80002078:	00068493          	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000207c:	fffffab7          	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80002080:	000019b7          	lui	s3,0x1
    80002084:	0480006f          	j	800020cc <copyinstr+0x90>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80002088:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000208c:	00100793          	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80002090:	fff7879b          	addiw	a5,a5,-1
    80002094:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80002098:	04813083          	ld	ra,72(sp)
    8000209c:	04013403          	ld	s0,64(sp)
    800020a0:	03813483          	ld	s1,56(sp)
    800020a4:	03013903          	ld	s2,48(sp)
    800020a8:	02813983          	ld	s3,40(sp)
    800020ac:	02013a03          	ld	s4,32(sp)
    800020b0:	01813a83          	ld	s5,24(sp)
    800020b4:	01013b03          	ld	s6,16(sp)
    800020b8:	00813b83          	ld	s7,8(sp)
    800020bc:	05010113          	addi	sp,sp,80
    800020c0:	00008067          	ret
    srcva = va0 + PGSIZE;
    800020c4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800020c8:	06048863          	beqz	s1,80002138 <copyinstr+0xfc>
    va0 = PGROUNDDOWN(srcva);
    800020cc:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800020d0:	00090593          	mv	a1,s2
    800020d4:	000a0513          	mv	a0,s4
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	710080e7          	jalr	1808(ra) # 800017e8 <walkaddr>
    if(pa0 == 0)
    800020e0:	06050063          	beqz	a0,80002140 <copyinstr+0x104>
    n = PGSIZE - (srcva - va0);
    800020e4:	417906b3          	sub	a3,s2,s7
    800020e8:	013686b3          	add	a3,a3,s3
    800020ec:	00d4f463          	bgeu	s1,a3,800020f4 <copyinstr+0xb8>
    800020f0:	00048693          	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800020f4:	01750533          	add	a0,a0,s7
    800020f8:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800020fc:	fc0684e3          	beqz	a3,800020c4 <copyinstr+0x88>
    80002100:	000b0793          	mv	a5,s6
      if(*p == '\0'){
    80002104:	41650633          	sub	a2,a0,s6
    80002108:	fff48593          	addi	a1,s1,-1
    8000210c:	00bb05b3          	add	a1,s6,a1
    while(n > 0){
    80002110:	00db06b3          	add	a3,s6,a3
      if(*p == '\0'){
    80002114:	00f60733          	add	a4,a2,a5
    80002118:	00074703          	lbu	a4,0(a4)
    8000211c:	f60706e3          	beqz	a4,80002088 <copyinstr+0x4c>
        *dst = *p;
    80002120:	00e78023          	sb	a4,0(a5)
      --max;
    80002124:	40f584b3          	sub	s1,a1,a5
      dst++;
    80002128:	00178793          	addi	a5,a5,1
    while(n > 0){
    8000212c:	fed794e3          	bne	a5,a3,80002114 <copyinstr+0xd8>
      dst++;
    80002130:	00078b13          	mv	s6,a5
    80002134:	f91ff06f          	j	800020c4 <copyinstr+0x88>
    80002138:	00000793          	li	a5,0
    8000213c:	f55ff06f          	j	80002090 <copyinstr+0x54>
      return -1;
    80002140:	fff00513          	li	a0,-1
    80002144:	f55ff06f          	j	80002098 <copyinstr+0x5c>
  int got_null = 0;
    80002148:	00000793          	li	a5,0
  if(got_null){
    8000214c:	fff7879b          	addiw	a5,a5,-1
    80002150:	0007851b          	sext.w	a0,a5
}
    80002154:	00008067          	ret

0000000080002158 <ismapped>:
  return mem;
}

int
ismapped(pagetable_t pagetable, uint64 va)
{
    80002158:	ff010113          	addi	sp,sp,-16
    8000215c:	00113423          	sd	ra,8(sp)
    80002160:	00813023          	sd	s0,0(sp)
    80002164:	01010413          	addi	s0,sp,16
  pte_t *pte = walk(pagetable, va, 0);
    80002168:	00000613          	li	a2,0
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	580080e7          	jalr	1408(ra) # 800016ec <walk>
  if (pte == 0) {
    80002174:	00050e63          	beqz	a0,80002190 <ismapped+0x38>
    return 0;
  }
  if (*pte & PTE_V){
    80002178:	00053503          	ld	a0,0(a0)
    return 0;
    8000217c:	00157513          	andi	a0,a0,1
    return 1;
  }
  return 0;
}
    80002180:	00813083          	ld	ra,8(sp)
    80002184:	00013403          	ld	s0,0(sp)
    80002188:	01010113          	addi	sp,sp,16
    8000218c:	00008067          	ret
    return 0;
    80002190:	00000513          	li	a0,0
    80002194:	fedff06f          	j	80002180 <ismapped+0x28>

0000000080002198 <vmfault>:
{
    80002198:	fd010113          	addi	sp,sp,-48
    8000219c:	02113423          	sd	ra,40(sp)
    800021a0:	02813023          	sd	s0,32(sp)
    800021a4:	00913c23          	sd	s1,24(sp)
    800021a8:	01213823          	sd	s2,16(sp)
    800021ac:	01313423          	sd	s3,8(sp)
    800021b0:	01413023          	sd	s4,0(sp)
    800021b4:	03010413          	addi	s0,sp,48
    800021b8:	00050993          	mv	s3,a0
    800021bc:	00058493          	mv	s1,a1
  struct proc *p = myproc();
    800021c0:	00000097          	auipc	ra,0x0
    800021c4:	528080e7          	jalr	1320(ra) # 800026e8 <myproc>
  if (va >= p->sz)
    800021c8:	04853783          	ld	a5,72(a0)
    800021cc:	02f4e663          	bltu	s1,a5,800021f8 <vmfault+0x60>
    return 0;
    800021d0:	00000993          	li	s3,0
}
    800021d4:	00098513          	mv	a0,s3
    800021d8:	02813083          	ld	ra,40(sp)
    800021dc:	02013403          	ld	s0,32(sp)
    800021e0:	01813483          	ld	s1,24(sp)
    800021e4:	01013903          	ld	s2,16(sp)
    800021e8:	00813983          	ld	s3,8(sp)
    800021ec:	00013a03          	ld	s4,0(sp)
    800021f0:	03010113          	addi	sp,sp,48
    800021f4:	00008067          	ret
    800021f8:	00050913          	mv	s2,a0
  va = PGROUNDDOWN(va);
    800021fc:	fffff7b7          	lui	a5,0xfffff
    80002200:	00f4f4b3          	and	s1,s1,a5
  if(ismapped(pagetable, va)) {
    80002204:	00048593          	mv	a1,s1
    80002208:	00098513          	mv	a0,s3
    8000220c:	00000097          	auipc	ra,0x0
    80002210:	f4c080e7          	jalr	-180(ra) # 80002158 <ismapped>
    return 0;
    80002214:	00000993          	li	s3,0
  if(ismapped(pagetable, va)) {
    80002218:	fa051ee3          	bnez	a0,800021d4 <vmfault+0x3c>
  mem = (uint64) kalloc();
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	d30080e7          	jalr	-720(ra) # 80000f4c <kalloc>
    80002224:	00050a13          	mv	s4,a0
  if(mem == 0)
    80002228:	fa0506e3          	beqz	a0,800021d4 <vmfault+0x3c>
  mem = (uint64) kalloc();
    8000222c:	00050993          	mv	s3,a0
  memset((void *) mem, 0, PGSIZE);
    80002230:	00001637          	lui	a2,0x1
    80002234:	00000593          	li	a1,0
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	fd8080e7          	jalr	-40(ra) # 80001210 <memset>
  if (mappages(p->pagetable, va, PGSIZE, mem, PTE_W|PTE_U|PTE_R) != 0) {
    80002240:	01600713          	li	a4,22
    80002244:	000a0693          	mv	a3,s4
    80002248:	00001637          	lui	a2,0x1
    8000224c:	00048593          	mv	a1,s1
    80002250:	05093503          	ld	a0,80(s2) # 1050 <_entry-0x7fffefb0>
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	600080e7          	jalr	1536(ra) # 80001854 <mappages>
    8000225c:	f6050ce3          	beqz	a0,800021d4 <vmfault+0x3c>
    kfree((void *)mem);
    80002260:	000a0513          	mv	a0,s4
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	b5c080e7          	jalr	-1188(ra) # 80000dc0 <kfree>
    return 0;
    8000226c:	00000993          	li	s3,0
    80002270:	f65ff06f          	j	800021d4 <vmfault+0x3c>

0000000080002274 <copyout>:
  while(len > 0){
    80002274:	10068663          	beqz	a3,80002380 <copyout+0x10c>
{
    80002278:	fa010113          	addi	sp,sp,-96
    8000227c:	04113c23          	sd	ra,88(sp)
    80002280:	04813823          	sd	s0,80(sp)
    80002284:	04913423          	sd	s1,72(sp)
    80002288:	05213023          	sd	s2,64(sp)
    8000228c:	03313c23          	sd	s3,56(sp)
    80002290:	03413823          	sd	s4,48(sp)
    80002294:	03513423          	sd	s5,40(sp)
    80002298:	03613023          	sd	s6,32(sp)
    8000229c:	01713c23          	sd	s7,24(sp)
    800022a0:	01813823          	sd	s8,16(sp)
    800022a4:	01913423          	sd	s9,8(sp)
    800022a8:	01a13023          	sd	s10,0(sp)
    800022ac:	06010413          	addi	s0,sp,96
    800022b0:	00050c13          	mv	s8,a0
    800022b4:	00058b13          	mv	s6,a1
    800022b8:	00060b93          	mv	s7,a2
    800022bc:	00068a13          	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    800022c0:	fffff4b7          	lui	s1,0xfffff
    800022c4:	0095f4b3          	and	s1,a1,s1
    if(va0 >= MAXVA)
    800022c8:	fff00793          	li	a5,-1
    800022cc:	01a7d793          	srli	a5,a5,0x1a
    800022d0:	0a97ec63          	bltu	a5,s1,80002388 <copyout+0x114>
    800022d4:	00001d37          	lui	s10,0x1
    800022d8:	00078c93          	mv	s9,a5
    800022dc:	0340006f          	j	80002310 <copyout+0x9c>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800022e0:	409b0533          	sub	a0,s6,s1
    800022e4:	0009861b          	sext.w	a2,s3
    800022e8:	000b8593          	mv	a1,s7
    800022ec:	01250533          	add	a0,a0,s2
    800022f0:	fffff097          	auipc	ra,0xfffff
    800022f4:	fb4080e7          	jalr	-76(ra) # 800012a4 <memmove>
    len -= n;
    800022f8:	413a0a33          	sub	s4,s4,s3
    src += n;
    800022fc:	013b8bb3          	add	s7,s7,s3
  while(len > 0){
    80002300:	060a0c63          	beqz	s4,80002378 <copyout+0x104>
    if(va0 >= MAXVA)
    80002304:	095ce663          	bltu	s9,s5,80002390 <copyout+0x11c>
    va0 = PGROUNDDOWN(dstva);
    80002308:	000a8493          	mv	s1,s5
    dstva = va0 + PGSIZE;
    8000230c:	000a8b13          	mv	s6,s5
    pa0 = walkaddr(pagetable, va0);
    80002310:	00048593          	mv	a1,s1
    80002314:	000c0513          	mv	a0,s8
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	4d0080e7          	jalr	1232(ra) # 800017e8 <walkaddr>
    80002320:	00050913          	mv	s2,a0
    if(pa0 == 0) {
    80002324:	02051063          	bnez	a0,80002344 <copyout+0xd0>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    80002328:	00000613          	li	a2,0
    8000232c:	00048593          	mv	a1,s1
    80002330:	000c0513          	mv	a0,s8
    80002334:	00000097          	auipc	ra,0x0
    80002338:	e64080e7          	jalr	-412(ra) # 80002198 <vmfault>
    8000233c:	00050913          	mv	s2,a0
    80002340:	04050c63          	beqz	a0,80002398 <copyout+0x124>
    pte = walk(pagetable, va0, 0);
    80002344:	00000613          	li	a2,0
    80002348:	00048593          	mv	a1,s1
    8000234c:	000c0513          	mv	a0,s8
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	39c080e7          	jalr	924(ra) # 800016ec <walk>
    if((*pte & PTE_W) == 0)
    80002358:	00053783          	ld	a5,0(a0)
    8000235c:	0047f793          	andi	a5,a5,4
    80002360:	04078063          	beqz	a5,800023a0 <copyout+0x12c>
    n = PGSIZE - (dstva - va0);
    80002364:	01a48ab3          	add	s5,s1,s10
    80002368:	416a89b3          	sub	s3,s5,s6
    8000236c:	f73a7ae3          	bgeu	s4,s3,800022e0 <copyout+0x6c>
    80002370:	000a0993          	mv	s3,s4
    80002374:	f6dff06f          	j	800022e0 <copyout+0x6c>
  return 0;
    80002378:	00000513          	li	a0,0
    8000237c:	0280006f          	j	800023a4 <copyout+0x130>
    80002380:	00000513          	li	a0,0
}
    80002384:	00008067          	ret
      return -1;
    80002388:	fff00513          	li	a0,-1
    8000238c:	0180006f          	j	800023a4 <copyout+0x130>
    80002390:	fff00513          	li	a0,-1
    80002394:	0100006f          	j	800023a4 <copyout+0x130>
        return -1;
    80002398:	fff00513          	li	a0,-1
    8000239c:	0080006f          	j	800023a4 <copyout+0x130>
      return -1;
    800023a0:	fff00513          	li	a0,-1
}
    800023a4:	05813083          	ld	ra,88(sp)
    800023a8:	05013403          	ld	s0,80(sp)
    800023ac:	04813483          	ld	s1,72(sp)
    800023b0:	04013903          	ld	s2,64(sp)
    800023b4:	03813983          	ld	s3,56(sp)
    800023b8:	03013a03          	ld	s4,48(sp)
    800023bc:	02813a83          	ld	s5,40(sp)
    800023c0:	02013b03          	ld	s6,32(sp)
    800023c4:	01813b83          	ld	s7,24(sp)
    800023c8:	01013c03          	ld	s8,16(sp)
    800023cc:	00813c83          	ld	s9,8(sp)
    800023d0:	00013d03          	ld	s10,0(sp)
    800023d4:	06010113          	addi	sp,sp,96
    800023d8:	00008067          	ret

00000000800023dc <copyin>:
  while(len > 0){
    800023dc:	0e068a63          	beqz	a3,800024d0 <copyin+0xf4>
{
    800023e0:	fb010113          	addi	sp,sp,-80
    800023e4:	04113423          	sd	ra,72(sp)
    800023e8:	04813023          	sd	s0,64(sp)
    800023ec:	02913c23          	sd	s1,56(sp)
    800023f0:	03213823          	sd	s2,48(sp)
    800023f4:	03313423          	sd	s3,40(sp)
    800023f8:	03413023          	sd	s4,32(sp)
    800023fc:	01513c23          	sd	s5,24(sp)
    80002400:	01613823          	sd	s6,16(sp)
    80002404:	01713423          	sd	s7,8(sp)
    80002408:	01813023          	sd	s8,0(sp)
    8000240c:	05010413          	addi	s0,sp,80
    80002410:	00050b93          	mv	s7,a0
    80002414:	00058a93          	mv	s5,a1
    80002418:	00060913          	mv	s2,a2
    8000241c:	00068a13          	mv	s4,a3
    va0 = PGROUNDDOWN(srcva);
    80002420:	fffffc37          	lui	s8,0xfffff
    n = PGSIZE - (srcva - va0);
    80002424:	00001b37          	lui	s6,0x1
    80002428:	03c0006f          	j	80002464 <copyin+0x88>
    8000242c:	412984b3          	sub	s1,s3,s2
    80002430:	016484b3          	add	s1,s1,s6
    80002434:	009a7463          	bgeu	s4,s1,8000243c <copyin+0x60>
    80002438:	000a0493          	mv	s1,s4
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000243c:	413905b3          	sub	a1,s2,s3
    80002440:	0004861b          	sext.w	a2,s1
    80002444:	00a585b3          	add	a1,a1,a0
    80002448:	000a8513          	mv	a0,s5
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	e58080e7          	jalr	-424(ra) # 800012a4 <memmove>
    len -= n;
    80002454:	409a0a33          	sub	s4,s4,s1
    dst += n;
    80002458:	009a8ab3          	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    8000245c:	01698933          	add	s2,s3,s6
  while(len > 0){
    80002460:	020a0e63          	beqz	s4,8000249c <copyin+0xc0>
    va0 = PGROUNDDOWN(srcva);
    80002464:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    80002468:	00098593          	mv	a1,s3
    8000246c:	000b8513          	mv	a0,s7
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	378080e7          	jalr	888(ra) # 800017e8 <walkaddr>
    if(pa0 == 0) {
    80002478:	fa051ae3          	bnez	a0,8000242c <copyin+0x50>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    8000247c:	00000613          	li	a2,0
    80002480:	00098593          	mv	a1,s3
    80002484:	000b8513          	mv	a0,s7
    80002488:	00000097          	auipc	ra,0x0
    8000248c:	d10080e7          	jalr	-752(ra) # 80002198 <vmfault>
    80002490:	f8051ee3          	bnez	a0,8000242c <copyin+0x50>
        return -1;
    80002494:	fff00513          	li	a0,-1
    80002498:	0080006f          	j	800024a0 <copyin+0xc4>
  return 0;
    8000249c:	00000513          	li	a0,0
}
    800024a0:	04813083          	ld	ra,72(sp)
    800024a4:	04013403          	ld	s0,64(sp)
    800024a8:	03813483          	ld	s1,56(sp)
    800024ac:	03013903          	ld	s2,48(sp)
    800024b0:	02813983          	ld	s3,40(sp)
    800024b4:	02013a03          	ld	s4,32(sp)
    800024b8:	01813a83          	ld	s5,24(sp)
    800024bc:	01013b03          	ld	s6,16(sp)
    800024c0:	00813b83          	ld	s7,8(sp)
    800024c4:	00013c03          	ld	s8,0(sp)
    800024c8:	05010113          	addi	sp,sp,80
    800024cc:	00008067          	ret
  return 0;
    800024d0:	00000513          	li	a0,0
}
    800024d4:	00008067          	ret

00000000800024d8 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    800024d8:	fc010113          	addi	sp,sp,-64
    800024dc:	02113c23          	sd	ra,56(sp)
    800024e0:	02813823          	sd	s0,48(sp)
    800024e4:	02913423          	sd	s1,40(sp)
    800024e8:	03213023          	sd	s2,32(sp)
    800024ec:	01313c23          	sd	s3,24(sp)
    800024f0:	01413823          	sd	s4,16(sp)
    800024f4:	01513423          	sd	s5,8(sp)
    800024f8:	01613023          	sd	s6,0(sp)
    800024fc:	04010413          	addi	s0,sp,64
    80002500:	00050993          	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80002504:	00011497          	auipc	s1,0x11
    80002508:	9f448493          	addi	s1,s1,-1548 # 80012ef8 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000250c:	00048b13          	mv	s6,s1
    80002510:	00008a97          	auipc	s5,0x8
    80002514:	af0a8a93          	addi	s5,s5,-1296 # 8000a000 <etext>
    80002518:	04000937          	lui	s2,0x4000
    8000251c:	fff90913          	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80002520:	00c91913          	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80002524:	00016a17          	auipc	s4,0x16
    80002528:	3d4a0a13          	addi	s4,s4,980 # 800188f8 <tickslock>
    char *pa = kalloc();
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	a20080e7          	jalr	-1504(ra) # 80000f4c <kalloc>
    80002534:	00050613          	mv	a2,a0
    if(pa == 0)
    80002538:	06050263          	beqz	a0,8000259c <proc_mapstacks+0xc4>
    uint64 va = KSTACK((int) (p - proc));
    8000253c:	416485b3          	sub	a1,s1,s6
    80002540:	4035d593          	srai	a1,a1,0x3
    80002544:	000ab783          	ld	a5,0(s5)
    80002548:	02f585b3          	mul	a1,a1,a5
    8000254c:	0015859b          	addiw	a1,a1,1
    80002550:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80002554:	00600713          	li	a4,6
    80002558:	000016b7          	lui	a3,0x1
    8000255c:	40b905b3          	sub	a1,s2,a1
    80002560:	00098513          	mv	a0,s3
    80002564:	fffff097          	auipc	ra,0xfffff
    80002568:	410080e7          	jalr	1040(ra) # 80001974 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000256c:	16848493          	addi	s1,s1,360
    80002570:	fb449ee3          	bne	s1,s4,8000252c <proc_mapstacks+0x54>
  }
}
    80002574:	03813083          	ld	ra,56(sp)
    80002578:	03013403          	ld	s0,48(sp)
    8000257c:	02813483          	ld	s1,40(sp)
    80002580:	02013903          	ld	s2,32(sp)
    80002584:	01813983          	ld	s3,24(sp)
    80002588:	01013a03          	ld	s4,16(sp)
    8000258c:	00813a83          	ld	s5,8(sp)
    80002590:	00013b03          	ld	s6,0(sp)
    80002594:	04010113          	addi	sp,sp,64
    80002598:	00008067          	ret
      panic("kalloc");
    8000259c:	00008517          	auipc	a0,0x8
    800025a0:	d4450513          	addi	a0,a0,-700 # 8000a2e0 <digits+0x2a8>
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	4dc080e7          	jalr	1244(ra) # 80000a80 <panic>

00000000800025ac <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800025ac:	fc010113          	addi	sp,sp,-64
    800025b0:	02113c23          	sd	ra,56(sp)
    800025b4:	02813823          	sd	s0,48(sp)
    800025b8:	02913423          	sd	s1,40(sp)
    800025bc:	03213023          	sd	s2,32(sp)
    800025c0:	01313c23          	sd	s3,24(sp)
    800025c4:	01413823          	sd	s4,16(sp)
    800025c8:	01513423          	sd	s5,8(sp)
    800025cc:	01613023          	sd	s6,0(sp)
    800025d0:	04010413          	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800025d4:	00008597          	auipc	a1,0x8
    800025d8:	d1458593          	addi	a1,a1,-748 # 8000a2e8 <digits+0x2b0>
    800025dc:	00010517          	auipc	a0,0x10
    800025e0:	4ec50513          	addi	a0,a0,1260 # 80012ac8 <pid_lock>
    800025e4:	fffff097          	auipc	ra,0xfffff
    800025e8:	9f0080e7          	jalr	-1552(ra) # 80000fd4 <initlock>
  initlock(&wait_lock, "wait_lock");
    800025ec:	00008597          	auipc	a1,0x8
    800025f0:	d0458593          	addi	a1,a1,-764 # 8000a2f0 <digits+0x2b8>
    800025f4:	00010517          	auipc	a0,0x10
    800025f8:	4ec50513          	addi	a0,a0,1260 # 80012ae0 <wait_lock>
    800025fc:	fffff097          	auipc	ra,0xfffff
    80002600:	9d8080e7          	jalr	-1576(ra) # 80000fd4 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002604:	00011497          	auipc	s1,0x11
    80002608:	8f448493          	addi	s1,s1,-1804 # 80012ef8 <proc>
      initlock(&p->lock, "proc");
    8000260c:	00008b17          	auipc	s6,0x8
    80002610:	cf4b0b13          	addi	s6,s6,-780 # 8000a300 <digits+0x2c8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80002614:	00048a93          	mv	s5,s1
    80002618:	00008a17          	auipc	s4,0x8
    8000261c:	9e8a0a13          	addi	s4,s4,-1560 # 8000a000 <etext>
    80002620:	04000937          	lui	s2,0x4000
    80002624:	fff90913          	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80002628:	00c91913          	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000262c:	00016997          	auipc	s3,0x16
    80002630:	2cc98993          	addi	s3,s3,716 # 800188f8 <tickslock>
      initlock(&p->lock, "proc");
    80002634:	000b0593          	mv	a1,s6
    80002638:	00048513          	mv	a0,s1
    8000263c:	fffff097          	auipc	ra,0xfffff
    80002640:	998080e7          	jalr	-1640(ra) # 80000fd4 <initlock>
      p->state = UNUSED;
    80002644:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80002648:	415487b3          	sub	a5,s1,s5
    8000264c:	4037d793          	srai	a5,a5,0x3
    80002650:	000a3703          	ld	a4,0(s4)
    80002654:	02e787b3          	mul	a5,a5,a4
    80002658:	0017879b          	addiw	a5,a5,1 # fffffffffffff001 <end+0xffffffff7ffdb329>
    8000265c:	00d7979b          	slliw	a5,a5,0xd
    80002660:	40f907b3          	sub	a5,s2,a5
    80002664:	04f4b023          	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80002668:	16848493          	addi	s1,s1,360
    8000266c:	fd3494e3          	bne	s1,s3,80002634 <procinit+0x88>
  }
}
    80002670:	03813083          	ld	ra,56(sp)
    80002674:	03013403          	ld	s0,48(sp)
    80002678:	02813483          	ld	s1,40(sp)
    8000267c:	02013903          	ld	s2,32(sp)
    80002680:	01813983          	ld	s3,24(sp)
    80002684:	01013a03          	ld	s4,16(sp)
    80002688:	00813a83          	ld	s5,8(sp)
    8000268c:	00013b03          	ld	s6,0(sp)
    80002690:	04010113          	addi	sp,sp,64
    80002694:	00008067          	ret

0000000080002698 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80002698:	ff010113          	addi	sp,sp,-16
    8000269c:	00813423          	sd	s0,8(sp)
    800026a0:	01010413          	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800026a4:	00020513          	mv	a0,tp
  int id = r_tp();
  return id;
}
    800026a8:	0005051b          	sext.w	a0,a0
    800026ac:	00813403          	ld	s0,8(sp)
    800026b0:	01010113          	addi	sp,sp,16
    800026b4:	00008067          	ret

00000000800026b8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800026b8:	ff010113          	addi	sp,sp,-16
    800026bc:	00813423          	sd	s0,8(sp)
    800026c0:	01010413          	addi	s0,sp,16
    800026c4:	00020793          	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800026c8:	0007879b          	sext.w	a5,a5
    800026cc:	00779793          	slli	a5,a5,0x7
  return c;
}
    800026d0:	00010517          	auipc	a0,0x10
    800026d4:	42850513          	addi	a0,a0,1064 # 80012af8 <cpus>
    800026d8:	00f50533          	add	a0,a0,a5
    800026dc:	00813403          	ld	s0,8(sp)
    800026e0:	01010113          	addi	sp,sp,16
    800026e4:	00008067          	ret

00000000800026e8 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800026e8:	fe010113          	addi	sp,sp,-32
    800026ec:	00113c23          	sd	ra,24(sp)
    800026f0:	00813823          	sd	s0,16(sp)
    800026f4:	00913423          	sd	s1,8(sp)
    800026f8:	02010413          	addi	s0,sp,32
  push_off();
    800026fc:	fffff097          	auipc	ra,0xfffff
    80002700:	948080e7          	jalr	-1720(ra) # 80001044 <push_off>
    80002704:	00020793          	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80002708:	0007879b          	sext.w	a5,a5
    8000270c:	00779793          	slli	a5,a5,0x7
    80002710:	00010717          	auipc	a4,0x10
    80002714:	3b870713          	addi	a4,a4,952 # 80012ac8 <pid_lock>
    80002718:	00f707b3          	add	a5,a4,a5
    8000271c:	0307b483          	ld	s1,48(a5)
  pop_off();
    80002720:	fffff097          	auipc	ra,0xfffff
    80002724:	a10080e7          	jalr	-1520(ra) # 80001130 <pop_off>
  return p;
}
    80002728:	00048513          	mv	a0,s1
    8000272c:	01813083          	ld	ra,24(sp)
    80002730:	01013403          	ld	s0,16(sp)
    80002734:	00813483          	ld	s1,8(sp)
    80002738:	02010113          	addi	sp,sp,32
    8000273c:	00008067          	ret

0000000080002740 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80002740:	fd010113          	addi	sp,sp,-48
    80002744:	02113423          	sd	ra,40(sp)
    80002748:	02813023          	sd	s0,32(sp)
    8000274c:	00913c23          	sd	s1,24(sp)
    80002750:	03010413          	addi	s0,sp,48
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();
    80002754:	00000097          	auipc	ra,0x0
    80002758:	f94080e7          	jalr	-108(ra) # 800026e8 <myproc>
    8000275c:	00050493          	mv	s1,a0

  // Still holding p->lock from scheduler.
  release(&p->lock);
    80002760:	fffff097          	auipc	ra,0xfffff
    80002764:	a50080e7          	jalr	-1456(ra) # 800011b0 <release>

  if (first) {
    80002768:	00008797          	auipc	a5,0x8
    8000276c:	2287a783          	lw	a5,552(a5) # 8000a990 <first.1>
    80002770:	04078863          	beqz	a5,800027c0 <forkret+0x80>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    80002774:	00100513          	li	a0,1
    80002778:	00003097          	auipc	ra,0x3
    8000277c:	be4080e7          	jalr	-1052(ra) # 8000535c <fsinit>

    first = 0;
    80002780:	00008797          	auipc	a5,0x8
    80002784:	2007a823          	sw	zero,528(a5) # 8000a990 <first.1>
    // ensure other cores see first=0.
    __sync_synchronize();
    80002788:	0ff0000f          	fence

    // We can invoke kexec() now that file system is initialized.
    // Put the return value (argc) of kexec into a0.
    p->trapframe->a0 = kexec("/init", (char *[]){ "/init", 0 });
    8000278c:	00008517          	auipc	a0,0x8
    80002790:	b7c50513          	addi	a0,a0,-1156 # 8000a308 <digits+0x2d0>
    80002794:	fca43823          	sd	a0,-48(s0)
    80002798:	fc043c23          	sd	zero,-40(s0)
    8000279c:	fd040593          	addi	a1,s0,-48
    800027a0:	00004097          	auipc	ra,0x4
    800027a4:	690080e7          	jalr	1680(ra) # 80006e30 <kexec>
    800027a8:	0584b783          	ld	a5,88(s1)
    800027ac:	06a7b823          	sd	a0,112(a5)
    if (p->trapframe->a0 == -1) {
    800027b0:	0584b783          	ld	a5,88(s1)
    800027b4:	0707b703          	ld	a4,112(a5)
    800027b8:	fff00793          	li	a5,-1
    800027bc:	04f70e63          	beq	a4,a5,80002818 <forkret+0xd8>
      panic("exec");
    }
  }

  // return to user space, mimicing usertrap()'s return.
  prepare_return();
    800027c0:	00001097          	auipc	ra,0x1
    800027c4:	15c080e7          	jalr	348(ra) # 8000391c <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    800027c8:	0504b503          	ld	a0,80(s1)
    800027cc:	00c55513          	srli	a0,a0,0xc
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800027d0:	04000737          	lui	a4,0x4000
    800027d4:	00007797          	auipc	a5,0x7
    800027d8:	8dc78793          	addi	a5,a5,-1828 # 800090b0 <userret>
    800027dc:	00007697          	auipc	a3,0x7
    800027e0:	82468693          	addi	a3,a3,-2012 # 80009000 <_trampoline>
    800027e4:	40d787b3          	sub	a5,a5,a3
    800027e8:	fff70713          	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    800027ec:	00c71713          	slli	a4,a4,0xc
    800027f0:	00e787b3          	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800027f4:	fff00713          	li	a4,-1
    800027f8:	03f71713          	slli	a4,a4,0x3f
    800027fc:	00e56533          	or	a0,a0,a4
    80002800:	000780e7          	jalr	a5
}
    80002804:	02813083          	ld	ra,40(sp)
    80002808:	02013403          	ld	s0,32(sp)
    8000280c:	01813483          	ld	s1,24(sp)
    80002810:	03010113          	addi	sp,sp,48
    80002814:	00008067          	ret
      panic("exec");
    80002818:	00008517          	auipc	a0,0x8
    8000281c:	af850513          	addi	a0,a0,-1288 # 8000a310 <digits+0x2d8>
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	260080e7          	jalr	608(ra) # 80000a80 <panic>

0000000080002828 <allocpid>:
{
    80002828:	fe010113          	addi	sp,sp,-32
    8000282c:	00113c23          	sd	ra,24(sp)
    80002830:	00813823          	sd	s0,16(sp)
    80002834:	00913423          	sd	s1,8(sp)
    80002838:	01213023          	sd	s2,0(sp)
    8000283c:	02010413          	addi	s0,sp,32
  acquire(&pid_lock);
    80002840:	00010917          	auipc	s2,0x10
    80002844:	28890913          	addi	s2,s2,648 # 80012ac8 <pid_lock>
    80002848:	00090513          	mv	a0,s2
    8000284c:	fffff097          	auipc	ra,0xfffff
    80002850:	86c080e7          	jalr	-1940(ra) # 800010b8 <acquire>
  pid = nextpid;
    80002854:	00008797          	auipc	a5,0x8
    80002858:	14078793          	addi	a5,a5,320 # 8000a994 <nextpid>
    8000285c:	0007a483          	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80002860:	0014871b          	addiw	a4,s1,1
    80002864:	00e7a023          	sw	a4,0(a5)
  release(&pid_lock);
    80002868:	00090513          	mv	a0,s2
    8000286c:	fffff097          	auipc	ra,0xfffff
    80002870:	944080e7          	jalr	-1724(ra) # 800011b0 <release>
}
    80002874:	00048513          	mv	a0,s1
    80002878:	01813083          	ld	ra,24(sp)
    8000287c:	01013403          	ld	s0,16(sp)
    80002880:	00813483          	ld	s1,8(sp)
    80002884:	00013903          	ld	s2,0(sp)
    80002888:	02010113          	addi	sp,sp,32
    8000288c:	00008067          	ret

0000000080002890 <proc_pagetable>:
{
    80002890:	fe010113          	addi	sp,sp,-32
    80002894:	00113c23          	sd	ra,24(sp)
    80002898:	00813823          	sd	s0,16(sp)
    8000289c:	00913423          	sd	s1,8(sp)
    800028a0:	01213023          	sd	s2,0(sp)
    800028a4:	02010413          	addi	s0,sp,32
    800028a8:	00050913          	mv	s2,a0
  pagetable = uvmcreate();
    800028ac:	fffff097          	auipc	ra,0xfffff
    800028b0:	268080e7          	jalr	616(ra) # 80001b14 <uvmcreate>
    800028b4:	00050493          	mv	s1,a0
  if(pagetable == 0)
    800028b8:	04050a63          	beqz	a0,8000290c <proc_pagetable+0x7c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800028bc:	00a00713          	li	a4,10
    800028c0:	00006697          	auipc	a3,0x6
    800028c4:	74068693          	addi	a3,a3,1856 # 80009000 <_trampoline>
    800028c8:	00001637          	lui	a2,0x1
    800028cc:	040005b7          	lui	a1,0x4000
    800028d0:	fff58593          	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800028d4:	00c59593          	slli	a1,a1,0xc
    800028d8:	fffff097          	auipc	ra,0xfffff
    800028dc:	f7c080e7          	jalr	-132(ra) # 80001854 <mappages>
    800028e0:	04054463          	bltz	a0,80002928 <proc_pagetable+0x98>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    800028e4:	00600713          	li	a4,6
    800028e8:	05893683          	ld	a3,88(s2)
    800028ec:	00001637          	lui	a2,0x1
    800028f0:	020005b7          	lui	a1,0x2000
    800028f4:	fff58593          	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    800028f8:	00d59593          	slli	a1,a1,0xd
    800028fc:	00048513          	mv	a0,s1
    80002900:	fffff097          	auipc	ra,0xfffff
    80002904:	f54080e7          	jalr	-172(ra) # 80001854 <mappages>
    80002908:	02054c63          	bltz	a0,80002940 <proc_pagetable+0xb0>
}
    8000290c:	00048513          	mv	a0,s1
    80002910:	01813083          	ld	ra,24(sp)
    80002914:	01013403          	ld	s0,16(sp)
    80002918:	00813483          	ld	s1,8(sp)
    8000291c:	00013903          	ld	s2,0(sp)
    80002920:	02010113          	addi	sp,sp,32
    80002924:	00008067          	ret
    uvmfree(pagetable, 0);
    80002928:	00000593          	li	a1,0
    8000292c:	00048513          	mv	a0,s1
    80002930:	fffff097          	auipc	ra,0xfffff
    80002934:	53c080e7          	jalr	1340(ra) # 80001e6c <uvmfree>
    return 0;
    80002938:	00000493          	li	s1,0
    8000293c:	fd1ff06f          	j	8000290c <proc_pagetable+0x7c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002940:	00000693          	li	a3,0
    80002944:	00100613          	li	a2,1
    80002948:	040005b7          	lui	a1,0x4000
    8000294c:	fff58593          	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80002950:	00c59593          	slli	a1,a1,0xc
    80002954:	00048513          	mv	a0,s1
    80002958:	fffff097          	auipc	ra,0xfffff
    8000295c:	208080e7          	jalr	520(ra) # 80001b60 <uvmunmap>
    uvmfree(pagetable, 0);
    80002960:	00000593          	li	a1,0
    80002964:	00048513          	mv	a0,s1
    80002968:	fffff097          	auipc	ra,0xfffff
    8000296c:	504080e7          	jalr	1284(ra) # 80001e6c <uvmfree>
    return 0;
    80002970:	00000493          	li	s1,0
    80002974:	f99ff06f          	j	8000290c <proc_pagetable+0x7c>

0000000080002978 <proc_freepagetable>:
{
    80002978:	fe010113          	addi	sp,sp,-32
    8000297c:	00113c23          	sd	ra,24(sp)
    80002980:	00813823          	sd	s0,16(sp)
    80002984:	00913423          	sd	s1,8(sp)
    80002988:	01213023          	sd	s2,0(sp)
    8000298c:	02010413          	addi	s0,sp,32
    80002990:	00050493          	mv	s1,a0
    80002994:	00058913          	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002998:	00000693          	li	a3,0
    8000299c:	00100613          	li	a2,1
    800029a0:	040005b7          	lui	a1,0x4000
    800029a4:	fff58593          	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800029a8:	00c59593          	slli	a1,a1,0xc
    800029ac:	fffff097          	auipc	ra,0xfffff
    800029b0:	1b4080e7          	jalr	436(ra) # 80001b60 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    800029b4:	00000693          	li	a3,0
    800029b8:	00100613          	li	a2,1
    800029bc:	020005b7          	lui	a1,0x2000
    800029c0:	fff58593          	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    800029c4:	00d59593          	slli	a1,a1,0xd
    800029c8:	00048513          	mv	a0,s1
    800029cc:	fffff097          	auipc	ra,0xfffff
    800029d0:	194080e7          	jalr	404(ra) # 80001b60 <uvmunmap>
  uvmfree(pagetable, sz);
    800029d4:	00090593          	mv	a1,s2
    800029d8:	00048513          	mv	a0,s1
    800029dc:	fffff097          	auipc	ra,0xfffff
    800029e0:	490080e7          	jalr	1168(ra) # 80001e6c <uvmfree>
}
    800029e4:	01813083          	ld	ra,24(sp)
    800029e8:	01013403          	ld	s0,16(sp)
    800029ec:	00813483          	ld	s1,8(sp)
    800029f0:	00013903          	ld	s2,0(sp)
    800029f4:	02010113          	addi	sp,sp,32
    800029f8:	00008067          	ret

00000000800029fc <freeproc>:
{
    800029fc:	fe010113          	addi	sp,sp,-32
    80002a00:	00113c23          	sd	ra,24(sp)
    80002a04:	00813823          	sd	s0,16(sp)
    80002a08:	00913423          	sd	s1,8(sp)
    80002a0c:	02010413          	addi	s0,sp,32
    80002a10:	00050493          	mv	s1,a0
  if(p->trapframe)
    80002a14:	05853503          	ld	a0,88(a0)
    80002a18:	00050663          	beqz	a0,80002a24 <freeproc+0x28>
    kfree((void*)p->trapframe);
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	3a4080e7          	jalr	932(ra) # 80000dc0 <kfree>
  p->trapframe = 0;
    80002a24:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80002a28:	0504b503          	ld	a0,80(s1)
    80002a2c:	00050863          	beqz	a0,80002a3c <freeproc+0x40>
    proc_freepagetable(p->pagetable, p->sz);
    80002a30:	0484b583          	ld	a1,72(s1)
    80002a34:	00000097          	auipc	ra,0x0
    80002a38:	f44080e7          	jalr	-188(ra) # 80002978 <proc_freepagetable>
  p->pagetable = 0;
    80002a3c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80002a40:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80002a44:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80002a48:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80002a4c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80002a50:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80002a54:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80002a58:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80002a5c:	0004ac23          	sw	zero,24(s1)
}
    80002a60:	01813083          	ld	ra,24(sp)
    80002a64:	01013403          	ld	s0,16(sp)
    80002a68:	00813483          	ld	s1,8(sp)
    80002a6c:	02010113          	addi	sp,sp,32
    80002a70:	00008067          	ret

0000000080002a74 <allocproc>:
{
    80002a74:	fe010113          	addi	sp,sp,-32
    80002a78:	00113c23          	sd	ra,24(sp)
    80002a7c:	00813823          	sd	s0,16(sp)
    80002a80:	00913423          	sd	s1,8(sp)
    80002a84:	01213023          	sd	s2,0(sp)
    80002a88:	02010413          	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80002a8c:	00010497          	auipc	s1,0x10
    80002a90:	46c48493          	addi	s1,s1,1132 # 80012ef8 <proc>
    80002a94:	00016917          	auipc	s2,0x16
    80002a98:	e6490913          	addi	s2,s2,-412 # 800188f8 <tickslock>
    acquire(&p->lock);
    80002a9c:	00048513          	mv	a0,s1
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	618080e7          	jalr	1560(ra) # 800010b8 <acquire>
    if(p->state == UNUSED) {
    80002aa8:	0184a783          	lw	a5,24(s1)
    80002aac:	02078063          	beqz	a5,80002acc <allocproc+0x58>
      release(&p->lock);
    80002ab0:	00048513          	mv	a0,s1
    80002ab4:	ffffe097          	auipc	ra,0xffffe
    80002ab8:	6fc080e7          	jalr	1788(ra) # 800011b0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002abc:	16848493          	addi	s1,s1,360
    80002ac0:	fd249ee3          	bne	s1,s2,80002a9c <allocproc+0x28>
  return 0;
    80002ac4:	00000493          	li	s1,0
    80002ac8:	0740006f          	j	80002b3c <allocproc+0xc8>
  p->pid = allocpid();
    80002acc:	00000097          	auipc	ra,0x0
    80002ad0:	d5c080e7          	jalr	-676(ra) # 80002828 <allocpid>
    80002ad4:	02a4a823          	sw	a0,48(s1)
  p->state = USED;
    80002ad8:	00100793          	li	a5,1
    80002adc:	00f4ac23          	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002ae0:	ffffe097          	auipc	ra,0xffffe
    80002ae4:	46c080e7          	jalr	1132(ra) # 80000f4c <kalloc>
    80002ae8:	00050913          	mv	s2,a0
    80002aec:	04a4bc23          	sd	a0,88(s1)
    80002af0:	06050463          	beqz	a0,80002b58 <allocproc+0xe4>
  p->pagetable = proc_pagetable(p);
    80002af4:	00048513          	mv	a0,s1
    80002af8:	00000097          	auipc	ra,0x0
    80002afc:	d98080e7          	jalr	-616(ra) # 80002890 <proc_pagetable>
    80002b00:	00050913          	mv	s2,a0
    80002b04:	04a4b823          	sd	a0,80(s1)
  if(p->pagetable == 0){
    80002b08:	06050863          	beqz	a0,80002b78 <allocproc+0x104>
  memset(&p->context, 0, sizeof(p->context));
    80002b0c:	07000613          	li	a2,112
    80002b10:	00000593          	li	a1,0
    80002b14:	06048513          	addi	a0,s1,96
    80002b18:	ffffe097          	auipc	ra,0xffffe
    80002b1c:	6f8080e7          	jalr	1784(ra) # 80001210 <memset>
  p->context.ra = (uint64)forkret;
    80002b20:	00000797          	auipc	a5,0x0
    80002b24:	c2078793          	addi	a5,a5,-992 # 80002740 <forkret>
    80002b28:	06f4b023          	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002b2c:	0404b783          	ld	a5,64(s1)
    80002b30:	00001737          	lui	a4,0x1
    80002b34:	00e787b3          	add	a5,a5,a4
    80002b38:	06f4b423          	sd	a5,104(s1)
}
    80002b3c:	00048513          	mv	a0,s1
    80002b40:	01813083          	ld	ra,24(sp)
    80002b44:	01013403          	ld	s0,16(sp)
    80002b48:	00813483          	ld	s1,8(sp)
    80002b4c:	00013903          	ld	s2,0(sp)
    80002b50:	02010113          	addi	sp,sp,32
    80002b54:	00008067          	ret
    freeproc(p);
    80002b58:	00048513          	mv	a0,s1
    80002b5c:	00000097          	auipc	ra,0x0
    80002b60:	ea0080e7          	jalr	-352(ra) # 800029fc <freeproc>
    release(&p->lock);
    80002b64:	00048513          	mv	a0,s1
    80002b68:	ffffe097          	auipc	ra,0xffffe
    80002b6c:	648080e7          	jalr	1608(ra) # 800011b0 <release>
    return 0;
    80002b70:	00090493          	mv	s1,s2
    80002b74:	fc9ff06f          	j	80002b3c <allocproc+0xc8>
    freeproc(p);
    80002b78:	00048513          	mv	a0,s1
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	e80080e7          	jalr	-384(ra) # 800029fc <freeproc>
    release(&p->lock);
    80002b84:	00048513          	mv	a0,s1
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	628080e7          	jalr	1576(ra) # 800011b0 <release>
    return 0;
    80002b90:	00090493          	mv	s1,s2
    80002b94:	fa9ff06f          	j	80002b3c <allocproc+0xc8>

0000000080002b98 <userinit>:
{
    80002b98:	fe010113          	addi	sp,sp,-32
    80002b9c:	00113c23          	sd	ra,24(sp)
    80002ba0:	00813823          	sd	s0,16(sp)
    80002ba4:	00913423          	sd	s1,8(sp)
    80002ba8:	02010413          	addi	s0,sp,32
  p = allocproc();
    80002bac:	00000097          	auipc	ra,0x0
    80002bb0:	ec8080e7          	jalr	-312(ra) # 80002a74 <allocproc>
    80002bb4:	00050493          	mv	s1,a0
  initproc = p;
    80002bb8:	00008797          	auipc	a5,0x8
    80002bbc:	e0a7b423          	sd	a0,-504(a5) # 8000a9c0 <initproc>
  p->cwd = namei("/");
    80002bc0:	00007517          	auipc	a0,0x7
    80002bc4:	75850513          	addi	a0,a0,1880 # 8000a318 <digits+0x2e0>
    80002bc8:	00003097          	auipc	ra,0x3
    80002bcc:	fbc080e7          	jalr	-68(ra) # 80005b84 <namei>
    80002bd0:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80002bd4:	00300793          	li	a5,3
    80002bd8:	00f4ac23          	sw	a5,24(s1)
  release(&p->lock);
    80002bdc:	00048513          	mv	a0,s1
    80002be0:	ffffe097          	auipc	ra,0xffffe
    80002be4:	5d0080e7          	jalr	1488(ra) # 800011b0 <release>
}
    80002be8:	01813083          	ld	ra,24(sp)
    80002bec:	01013403          	ld	s0,16(sp)
    80002bf0:	00813483          	ld	s1,8(sp)
    80002bf4:	02010113          	addi	sp,sp,32
    80002bf8:	00008067          	ret

0000000080002bfc <growproc>:
{
    80002bfc:	fe010113          	addi	sp,sp,-32
    80002c00:	00113c23          	sd	ra,24(sp)
    80002c04:	00813823          	sd	s0,16(sp)
    80002c08:	00913423          	sd	s1,8(sp)
    80002c0c:	01213023          	sd	s2,0(sp)
    80002c10:	02010413          	addi	s0,sp,32
    80002c14:	00050913          	mv	s2,a0
  struct proc *p = myproc();
    80002c18:	00000097          	auipc	ra,0x0
    80002c1c:	ad0080e7          	jalr	-1328(ra) # 800026e8 <myproc>
    80002c20:	00050493          	mv	s1,a0
  sz = p->sz;
    80002c24:	04853583          	ld	a1,72(a0)
  if(n > 0){
    80002c28:	03204463          	bgtz	s2,80002c50 <growproc+0x54>
  } else if(n < 0){
    80002c2c:	04094463          	bltz	s2,80002c74 <growproc+0x78>
  p->sz = sz;
    80002c30:	04b4b423          	sd	a1,72(s1)
  return 0;
    80002c34:	00000513          	li	a0,0
}
    80002c38:	01813083          	ld	ra,24(sp)
    80002c3c:	01013403          	ld	s0,16(sp)
    80002c40:	00813483          	ld	s1,8(sp)
    80002c44:	00013903          	ld	s2,0(sp)
    80002c48:	02010113          	addi	sp,sp,32
    80002c4c:	00008067          	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80002c50:	00400693          	li	a3,4
    80002c54:	00b90633          	add	a2,s2,a1
    80002c58:	05053503          	ld	a0,80(a0)
    80002c5c:	fffff097          	auipc	ra,0xfffff
    80002c60:	04c080e7          	jalr	76(ra) # 80001ca8 <uvmalloc>
    80002c64:	00050593          	mv	a1,a0
    80002c68:	fc0514e3          	bnez	a0,80002c30 <growproc+0x34>
      return -1;
    80002c6c:	fff00513          	li	a0,-1
    80002c70:	fc9ff06f          	j	80002c38 <growproc+0x3c>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002c74:	00b90633          	add	a2,s2,a1
    80002c78:	05053503          	ld	a0,80(a0)
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	fb4080e7          	jalr	-76(ra) # 80001c30 <uvmdealloc>
    80002c84:	00050593          	mv	a1,a0
    80002c88:	fa9ff06f          	j	80002c30 <growproc+0x34>

0000000080002c8c <kfork>:
{
    80002c8c:	fc010113          	addi	sp,sp,-64
    80002c90:	02113c23          	sd	ra,56(sp)
    80002c94:	02813823          	sd	s0,48(sp)
    80002c98:	02913423          	sd	s1,40(sp)
    80002c9c:	03213023          	sd	s2,32(sp)
    80002ca0:	01313c23          	sd	s3,24(sp)
    80002ca4:	01413823          	sd	s4,16(sp)
    80002ca8:	01513423          	sd	s5,8(sp)
    80002cac:	04010413          	addi	s0,sp,64
  struct proc *p = myproc();
    80002cb0:	00000097          	auipc	ra,0x0
    80002cb4:	a38080e7          	jalr	-1480(ra) # 800026e8 <myproc>
    80002cb8:	00050a93          	mv	s5,a0
  if((np = allocproc()) == 0){
    80002cbc:	00000097          	auipc	ra,0x0
    80002cc0:	db8080e7          	jalr	-584(ra) # 80002a74 <allocproc>
    80002cc4:	16050063          	beqz	a0,80002e24 <kfork+0x198>
    80002cc8:	00050a13          	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002ccc:	048ab603          	ld	a2,72(s5)
    80002cd0:	05053583          	ld	a1,80(a0)
    80002cd4:	050ab503          	ld	a0,80(s5)
    80002cd8:	fffff097          	auipc	ra,0xfffff
    80002cdc:	1f4080e7          	jalr	500(ra) # 80001ecc <uvmcopy>
    80002ce0:	06054063          	bltz	a0,80002d40 <kfork+0xb4>
  np->sz = p->sz;
    80002ce4:	048ab783          	ld	a5,72(s5)
    80002ce8:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80002cec:	058ab683          	ld	a3,88(s5)
    80002cf0:	00068793          	mv	a5,a3
    80002cf4:	058a3703          	ld	a4,88(s4)
    80002cf8:	12068693          	addi	a3,a3,288
    80002cfc:	0007b803          	ld	a6,0(a5)
    80002d00:	0087b503          	ld	a0,8(a5)
    80002d04:	0107b583          	ld	a1,16(a5)
    80002d08:	0187b603          	ld	a2,24(a5)
    80002d0c:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80002d10:	00a73423          	sd	a0,8(a4)
    80002d14:	00b73823          	sd	a1,16(a4)
    80002d18:	00c73c23          	sd	a2,24(a4)
    80002d1c:	02078793          	addi	a5,a5,32
    80002d20:	02070713          	addi	a4,a4,32
    80002d24:	fcd79ce3          	bne	a5,a3,80002cfc <kfork+0x70>
  np->trapframe->a0 = 0;
    80002d28:	058a3783          	ld	a5,88(s4)
    80002d2c:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80002d30:	0d0a8493          	addi	s1,s5,208
    80002d34:	0d0a0913          	addi	s2,s4,208
    80002d38:	150a8993          	addi	s3,s5,336
    80002d3c:	0300006f          	j	80002d6c <kfork+0xe0>
    freeproc(np);
    80002d40:	000a0513          	mv	a0,s4
    80002d44:	00000097          	auipc	ra,0x0
    80002d48:	cb8080e7          	jalr	-840(ra) # 800029fc <freeproc>
    release(&np->lock);
    80002d4c:	000a0513          	mv	a0,s4
    80002d50:	ffffe097          	auipc	ra,0xffffe
    80002d54:	460080e7          	jalr	1120(ra) # 800011b0 <release>
    return -1;
    80002d58:	fff00913          	li	s2,-1
    80002d5c:	0a00006f          	j	80002dfc <kfork+0x170>
  for(i = 0; i < NOFILE; i++)
    80002d60:	00848493          	addi	s1,s1,8
    80002d64:	00890913          	addi	s2,s2,8
    80002d68:	01348e63          	beq	s1,s3,80002d84 <kfork+0xf8>
    if(p->ofile[i])
    80002d6c:	0004b503          	ld	a0,0(s1)
    80002d70:	fe0508e3          	beqz	a0,80002d60 <kfork+0xd4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002d74:	00003097          	auipc	ra,0x3
    80002d78:	730080e7          	jalr	1840(ra) # 800064a4 <filedup>
    80002d7c:	00a93023          	sd	a0,0(s2)
    80002d80:	fe1ff06f          	j	80002d60 <kfork+0xd4>
  np->cwd = idup(p->cwd);
    80002d84:	150ab503          	ld	a0,336(s5)
    80002d88:	00002097          	auipc	ra,0x2
    80002d8c:	0b4080e7          	jalr	180(ra) # 80004e3c <idup>
    80002d90:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002d94:	01000613          	li	a2,16
    80002d98:	158a8593          	addi	a1,s5,344
    80002d9c:	158a0513          	addi	a0,s4,344
    80002da0:	ffffe097          	auipc	ra,0xffffe
    80002da4:	670080e7          	jalr	1648(ra) # 80001410 <safestrcpy>
  pid = np->pid;
    80002da8:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80002dac:	000a0513          	mv	a0,s4
    80002db0:	ffffe097          	auipc	ra,0xffffe
    80002db4:	400080e7          	jalr	1024(ra) # 800011b0 <release>
  acquire(&wait_lock);
    80002db8:	00010497          	auipc	s1,0x10
    80002dbc:	d2848493          	addi	s1,s1,-728 # 80012ae0 <wait_lock>
    80002dc0:	00048513          	mv	a0,s1
    80002dc4:	ffffe097          	auipc	ra,0xffffe
    80002dc8:	2f4080e7          	jalr	756(ra) # 800010b8 <acquire>
  np->parent = p;
    80002dcc:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80002dd0:	00048513          	mv	a0,s1
    80002dd4:	ffffe097          	auipc	ra,0xffffe
    80002dd8:	3dc080e7          	jalr	988(ra) # 800011b0 <release>
  acquire(&np->lock);
    80002ddc:	000a0513          	mv	a0,s4
    80002de0:	ffffe097          	auipc	ra,0xffffe
    80002de4:	2d8080e7          	jalr	728(ra) # 800010b8 <acquire>
  np->state = RUNNABLE;
    80002de8:	00300793          	li	a5,3
    80002dec:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80002df0:	000a0513          	mv	a0,s4
    80002df4:	ffffe097          	auipc	ra,0xffffe
    80002df8:	3bc080e7          	jalr	956(ra) # 800011b0 <release>
}
    80002dfc:	00090513          	mv	a0,s2
    80002e00:	03813083          	ld	ra,56(sp)
    80002e04:	03013403          	ld	s0,48(sp)
    80002e08:	02813483          	ld	s1,40(sp)
    80002e0c:	02013903          	ld	s2,32(sp)
    80002e10:	01813983          	ld	s3,24(sp)
    80002e14:	01013a03          	ld	s4,16(sp)
    80002e18:	00813a83          	ld	s5,8(sp)
    80002e1c:	04010113          	addi	sp,sp,64
    80002e20:	00008067          	ret
    return -1;
    80002e24:	fff00913          	li	s2,-1
    80002e28:	fd5ff06f          	j	80002dfc <kfork+0x170>

0000000080002e2c <scheduler>:
{
    80002e2c:	fb010113          	addi	sp,sp,-80
    80002e30:	04113423          	sd	ra,72(sp)
    80002e34:	04813023          	sd	s0,64(sp)
    80002e38:	02913c23          	sd	s1,56(sp)
    80002e3c:	03213823          	sd	s2,48(sp)
    80002e40:	03313423          	sd	s3,40(sp)
    80002e44:	03413023          	sd	s4,32(sp)
    80002e48:	01513c23          	sd	s5,24(sp)
    80002e4c:	01613823          	sd	s6,16(sp)
    80002e50:	01713423          	sd	s7,8(sp)
    80002e54:	01813023          	sd	s8,0(sp)
    80002e58:	05010413          	addi	s0,sp,80
    80002e5c:	00020793          	mv	a5,tp
  int id = r_tp();
    80002e60:	0007879b          	sext.w	a5,a5
  c->proc = 0;
    80002e64:	00779b13          	slli	s6,a5,0x7
    80002e68:	00010717          	auipc	a4,0x10
    80002e6c:	c6070713          	addi	a4,a4,-928 # 80012ac8 <pid_lock>
    80002e70:	01670733          	add	a4,a4,s6
    80002e74:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002e78:	00010717          	auipc	a4,0x10
    80002e7c:	c8870713          	addi	a4,a4,-888 # 80012b00 <cpus+0x8>
    80002e80:	00eb0b33          	add	s6,s6,a4
        p->state = RUNNING;
    80002e84:	00400c13          	li	s8,4
        c->proc = p;
    80002e88:	00779793          	slli	a5,a5,0x7
    80002e8c:	00010a17          	auipc	s4,0x10
    80002e90:	c3ca0a13          	addi	s4,s4,-964 # 80012ac8 <pid_lock>
    80002e94:	00fa0a33          	add	s4,s4,a5
        found = 1;
    80002e98:	00100b93          	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80002e9c:	00016997          	auipc	s3,0x16
    80002ea0:	a5c98993          	addi	s3,s3,-1444 # 800188f8 <tickslock>
    80002ea4:	0580006f          	j	80002efc <scheduler+0xd0>
      release(&p->lock);
    80002ea8:	00048513          	mv	a0,s1
    80002eac:	ffffe097          	auipc	ra,0xffffe
    80002eb0:	304080e7          	jalr	772(ra) # 800011b0 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002eb4:	16848493          	addi	s1,s1,360
    80002eb8:	03348e63          	beq	s1,s3,80002ef4 <scheduler+0xc8>
      acquire(&p->lock);
    80002ebc:	00048513          	mv	a0,s1
    80002ec0:	ffffe097          	auipc	ra,0xffffe
    80002ec4:	1f8080e7          	jalr	504(ra) # 800010b8 <acquire>
      if(p->state == RUNNABLE) {
    80002ec8:	0184a783          	lw	a5,24(s1)
    80002ecc:	fd279ee3          	bne	a5,s2,80002ea8 <scheduler+0x7c>
        p->state = RUNNING;
    80002ed0:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80002ed4:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002ed8:	06048593          	addi	a1,s1,96
    80002edc:	000b0513          	mv	a0,s6
    80002ee0:	00001097          	auipc	ra,0x1
    80002ee4:	96c080e7          	jalr	-1684(ra) # 8000384c <swtch>
        c->proc = 0;
    80002ee8:	020a3823          	sd	zero,48(s4)
        found = 1;
    80002eec:	000b8a93          	mv	s5,s7
    80002ef0:	fb9ff06f          	j	80002ea8 <scheduler+0x7c>
    if(found == 0) {
    80002ef4:	000a9463          	bnez	s5,80002efc <scheduler+0xd0>
      asm volatile("wfi");
    80002ef8:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002efc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002f00:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f04:	10079073          	csrw	sstatus,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f08:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002f0c:	ffd7f793          	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f10:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002f14:	00000a93          	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002f18:	00010497          	auipc	s1,0x10
    80002f1c:	fe048493          	addi	s1,s1,-32 # 80012ef8 <proc>
      if(p->state == RUNNABLE) {
    80002f20:	00300913          	li	s2,3
    80002f24:	f99ff06f          	j	80002ebc <scheduler+0x90>

0000000080002f28 <sched>:
{
    80002f28:	fd010113          	addi	sp,sp,-48
    80002f2c:	02113423          	sd	ra,40(sp)
    80002f30:	02813023          	sd	s0,32(sp)
    80002f34:	00913c23          	sd	s1,24(sp)
    80002f38:	01213823          	sd	s2,16(sp)
    80002f3c:	01313423          	sd	s3,8(sp)
    80002f40:	03010413          	addi	s0,sp,48
  struct proc *p = myproc();
    80002f44:	fffff097          	auipc	ra,0xfffff
    80002f48:	7a4080e7          	jalr	1956(ra) # 800026e8 <myproc>
    80002f4c:	00050493          	mv	s1,a0
  if(!holding(&p->lock))
    80002f50:	ffffe097          	auipc	ra,0xffffe
    80002f54:	0a8080e7          	jalr	168(ra) # 80000ff8 <holding>
    80002f58:	0a050863          	beqz	a0,80003008 <sched+0xe0>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002f5c:	00020793          	mv	a5,tp
  if(mycpu()->noff != 1)
    80002f60:	0007879b          	sext.w	a5,a5
    80002f64:	00779793          	slli	a5,a5,0x7
    80002f68:	00010717          	auipc	a4,0x10
    80002f6c:	b6070713          	addi	a4,a4,-1184 # 80012ac8 <pid_lock>
    80002f70:	00f707b3          	add	a5,a4,a5
    80002f74:	0a87a703          	lw	a4,168(a5)
    80002f78:	00100793          	li	a5,1
    80002f7c:	08f71e63          	bne	a4,a5,80003018 <sched+0xf0>
  if(p->state == RUNNING)
    80002f80:	0184a703          	lw	a4,24(s1)
    80002f84:	00400793          	li	a5,4
    80002f88:	0af70063          	beq	a4,a5,80003028 <sched+0x100>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f8c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f90:	0027f793          	andi	a5,a5,2
  if(intr_get())
    80002f94:	0a079263          	bnez	a5,80003038 <sched+0x110>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002f98:	00020793          	mv	a5,tp
  intena = mycpu()->intena;
    80002f9c:	00010917          	auipc	s2,0x10
    80002fa0:	b2c90913          	addi	s2,s2,-1236 # 80012ac8 <pid_lock>
    80002fa4:	0007879b          	sext.w	a5,a5
    80002fa8:	00779793          	slli	a5,a5,0x7
    80002fac:	00f907b3          	add	a5,s2,a5
    80002fb0:	0ac7a983          	lw	s3,172(a5)
    80002fb4:	00020793          	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002fb8:	0007879b          	sext.w	a5,a5
    80002fbc:	00779793          	slli	a5,a5,0x7
    80002fc0:	00010597          	auipc	a1,0x10
    80002fc4:	b4058593          	addi	a1,a1,-1216 # 80012b00 <cpus+0x8>
    80002fc8:	00b785b3          	add	a1,a5,a1
    80002fcc:	06048513          	addi	a0,s1,96
    80002fd0:	00001097          	auipc	ra,0x1
    80002fd4:	87c080e7          	jalr	-1924(ra) # 8000384c <swtch>
    80002fd8:	00020793          	mv	a5,tp
  mycpu()->intena = intena;
    80002fdc:	0007879b          	sext.w	a5,a5
    80002fe0:	00779793          	slli	a5,a5,0x7
    80002fe4:	00f90933          	add	s2,s2,a5
    80002fe8:	0b392623          	sw	s3,172(s2)
}
    80002fec:	02813083          	ld	ra,40(sp)
    80002ff0:	02013403          	ld	s0,32(sp)
    80002ff4:	01813483          	ld	s1,24(sp)
    80002ff8:	01013903          	ld	s2,16(sp)
    80002ffc:	00813983          	ld	s3,8(sp)
    80003000:	03010113          	addi	sp,sp,48
    80003004:	00008067          	ret
    panic("sched p->lock");
    80003008:	00007517          	auipc	a0,0x7
    8000300c:	31850513          	addi	a0,a0,792 # 8000a320 <digits+0x2e8>
    80003010:	ffffe097          	auipc	ra,0xffffe
    80003014:	a70080e7          	jalr	-1424(ra) # 80000a80 <panic>
    panic("sched locks");
    80003018:	00007517          	auipc	a0,0x7
    8000301c:	31850513          	addi	a0,a0,792 # 8000a330 <digits+0x2f8>
    80003020:	ffffe097          	auipc	ra,0xffffe
    80003024:	a60080e7          	jalr	-1440(ra) # 80000a80 <panic>
    panic("sched RUNNING");
    80003028:	00007517          	auipc	a0,0x7
    8000302c:	31850513          	addi	a0,a0,792 # 8000a340 <digits+0x308>
    80003030:	ffffe097          	auipc	ra,0xffffe
    80003034:	a50080e7          	jalr	-1456(ra) # 80000a80 <panic>
    panic("sched interruptible");
    80003038:	00007517          	auipc	a0,0x7
    8000303c:	31850513          	addi	a0,a0,792 # 8000a350 <digits+0x318>
    80003040:	ffffe097          	auipc	ra,0xffffe
    80003044:	a40080e7          	jalr	-1472(ra) # 80000a80 <panic>

0000000080003048 <yield>:
{
    80003048:	fe010113          	addi	sp,sp,-32
    8000304c:	00113c23          	sd	ra,24(sp)
    80003050:	00813823          	sd	s0,16(sp)
    80003054:	00913423          	sd	s1,8(sp)
    80003058:	02010413          	addi	s0,sp,32
  struct proc *p = myproc();
    8000305c:	fffff097          	auipc	ra,0xfffff
    80003060:	68c080e7          	jalr	1676(ra) # 800026e8 <myproc>
    80003064:	00050493          	mv	s1,a0
  acquire(&p->lock);
    80003068:	ffffe097          	auipc	ra,0xffffe
    8000306c:	050080e7          	jalr	80(ra) # 800010b8 <acquire>
  p->state = RUNNABLE;
    80003070:	00300793          	li	a5,3
    80003074:	00f4ac23          	sw	a5,24(s1)
  sched();
    80003078:	00000097          	auipc	ra,0x0
    8000307c:	eb0080e7          	jalr	-336(ra) # 80002f28 <sched>
  release(&p->lock);
    80003080:	00048513          	mv	a0,s1
    80003084:	ffffe097          	auipc	ra,0xffffe
    80003088:	12c080e7          	jalr	300(ra) # 800011b0 <release>
}
    8000308c:	01813083          	ld	ra,24(sp)
    80003090:	01013403          	ld	s0,16(sp)
    80003094:	00813483          	ld	s1,8(sp)
    80003098:	02010113          	addi	sp,sp,32
    8000309c:	00008067          	ret

00000000800030a0 <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800030a0:	fd010113          	addi	sp,sp,-48
    800030a4:	02113423          	sd	ra,40(sp)
    800030a8:	02813023          	sd	s0,32(sp)
    800030ac:	00913c23          	sd	s1,24(sp)
    800030b0:	01213823          	sd	s2,16(sp)
    800030b4:	01313423          	sd	s3,8(sp)
    800030b8:	03010413          	addi	s0,sp,48
    800030bc:	00050993          	mv	s3,a0
    800030c0:	00058913          	mv	s2,a1
  struct proc *p = myproc();
    800030c4:	fffff097          	auipc	ra,0xfffff
    800030c8:	624080e7          	jalr	1572(ra) # 800026e8 <myproc>
    800030cc:	00050493          	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800030d0:	ffffe097          	auipc	ra,0xffffe
    800030d4:	fe8080e7          	jalr	-24(ra) # 800010b8 <acquire>
  release(lk);
    800030d8:	00090513          	mv	a0,s2
    800030dc:	ffffe097          	auipc	ra,0xffffe
    800030e0:	0d4080e7          	jalr	212(ra) # 800011b0 <release>

  // Go to sleep.
  p->chan = chan;
    800030e4:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800030e8:	00200793          	li	a5,2
    800030ec:	00f4ac23          	sw	a5,24(s1)

  sched();
    800030f0:	00000097          	auipc	ra,0x0
    800030f4:	e38080e7          	jalr	-456(ra) # 80002f28 <sched>

  // Tidy up.
  p->chan = 0;
    800030f8:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800030fc:	00048513          	mv	a0,s1
    80003100:	ffffe097          	auipc	ra,0xffffe
    80003104:	0b0080e7          	jalr	176(ra) # 800011b0 <release>
  acquire(lk);
    80003108:	00090513          	mv	a0,s2
    8000310c:	ffffe097          	auipc	ra,0xffffe
    80003110:	fac080e7          	jalr	-84(ra) # 800010b8 <acquire>
}
    80003114:	02813083          	ld	ra,40(sp)
    80003118:	02013403          	ld	s0,32(sp)
    8000311c:	01813483          	ld	s1,24(sp)
    80003120:	01013903          	ld	s2,16(sp)
    80003124:	00813983          	ld	s3,8(sp)
    80003128:	03010113          	addi	sp,sp,48
    8000312c:	00008067          	ret

0000000080003130 <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
    80003130:	fc010113          	addi	sp,sp,-64
    80003134:	02113c23          	sd	ra,56(sp)
    80003138:	02813823          	sd	s0,48(sp)
    8000313c:	02913423          	sd	s1,40(sp)
    80003140:	03213023          	sd	s2,32(sp)
    80003144:	01313c23          	sd	s3,24(sp)
    80003148:	01413823          	sd	s4,16(sp)
    8000314c:	01513423          	sd	s5,8(sp)
    80003150:	04010413          	addi	s0,sp,64
    80003154:	00050a13          	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80003158:	00010497          	auipc	s1,0x10
    8000315c:	da048493          	addi	s1,s1,-608 # 80012ef8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80003160:	00200993          	li	s3,2
        p->state = RUNNABLE;
    80003164:	00300a93          	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80003168:	00015917          	auipc	s2,0x15
    8000316c:	79090913          	addi	s2,s2,1936 # 800188f8 <tickslock>
    80003170:	0180006f          	j	80003188 <wakeup+0x58>
      }
      release(&p->lock);
    80003174:	00048513          	mv	a0,s1
    80003178:	ffffe097          	auipc	ra,0xffffe
    8000317c:	038080e7          	jalr	56(ra) # 800011b0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80003180:	16848493          	addi	s1,s1,360
    80003184:	03248a63          	beq	s1,s2,800031b8 <wakeup+0x88>
    if(p != myproc()){
    80003188:	fffff097          	auipc	ra,0xfffff
    8000318c:	560080e7          	jalr	1376(ra) # 800026e8 <myproc>
    80003190:	fea488e3          	beq	s1,a0,80003180 <wakeup+0x50>
      acquire(&p->lock);
    80003194:	00048513          	mv	a0,s1
    80003198:	ffffe097          	auipc	ra,0xffffe
    8000319c:	f20080e7          	jalr	-224(ra) # 800010b8 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800031a0:	0184a783          	lw	a5,24(s1)
    800031a4:	fd3798e3          	bne	a5,s3,80003174 <wakeup+0x44>
    800031a8:	0204b783          	ld	a5,32(s1)
    800031ac:	fd4794e3          	bne	a5,s4,80003174 <wakeup+0x44>
        p->state = RUNNABLE;
    800031b0:	0154ac23          	sw	s5,24(s1)
    800031b4:	fc1ff06f          	j	80003174 <wakeup+0x44>
    }
  }
}
    800031b8:	03813083          	ld	ra,56(sp)
    800031bc:	03013403          	ld	s0,48(sp)
    800031c0:	02813483          	ld	s1,40(sp)
    800031c4:	02013903          	ld	s2,32(sp)
    800031c8:	01813983          	ld	s3,24(sp)
    800031cc:	01013a03          	ld	s4,16(sp)
    800031d0:	00813a83          	ld	s5,8(sp)
    800031d4:	04010113          	addi	sp,sp,64
    800031d8:	00008067          	ret

00000000800031dc <reparent>:
{
    800031dc:	fd010113          	addi	sp,sp,-48
    800031e0:	02113423          	sd	ra,40(sp)
    800031e4:	02813023          	sd	s0,32(sp)
    800031e8:	00913c23          	sd	s1,24(sp)
    800031ec:	01213823          	sd	s2,16(sp)
    800031f0:	01313423          	sd	s3,8(sp)
    800031f4:	01413023          	sd	s4,0(sp)
    800031f8:	03010413          	addi	s0,sp,48
    800031fc:	00050913          	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80003200:	00010497          	auipc	s1,0x10
    80003204:	cf848493          	addi	s1,s1,-776 # 80012ef8 <proc>
      pp->parent = initproc;
    80003208:	00007a17          	auipc	s4,0x7
    8000320c:	7b8a0a13          	addi	s4,s4,1976 # 8000a9c0 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80003210:	00015997          	auipc	s3,0x15
    80003214:	6e898993          	addi	s3,s3,1768 # 800188f8 <tickslock>
    80003218:	00c0006f          	j	80003224 <reparent+0x48>
    8000321c:	16848493          	addi	s1,s1,360
    80003220:	03348063          	beq	s1,s3,80003240 <reparent+0x64>
    if(pp->parent == p){
    80003224:	0384b783          	ld	a5,56(s1)
    80003228:	ff279ae3          	bne	a5,s2,8000321c <reparent+0x40>
      pp->parent = initproc;
    8000322c:	000a3503          	ld	a0,0(s4)
    80003230:	02a4bc23          	sd	a0,56(s1)
      wakeup(initproc);
    80003234:	00000097          	auipc	ra,0x0
    80003238:	efc080e7          	jalr	-260(ra) # 80003130 <wakeup>
    8000323c:	fe1ff06f          	j	8000321c <reparent+0x40>
}
    80003240:	02813083          	ld	ra,40(sp)
    80003244:	02013403          	ld	s0,32(sp)
    80003248:	01813483          	ld	s1,24(sp)
    8000324c:	01013903          	ld	s2,16(sp)
    80003250:	00813983          	ld	s3,8(sp)
    80003254:	00013a03          	ld	s4,0(sp)
    80003258:	03010113          	addi	sp,sp,48
    8000325c:	00008067          	ret

0000000080003260 <kexit>:
{
    80003260:	fd010113          	addi	sp,sp,-48
    80003264:	02113423          	sd	ra,40(sp)
    80003268:	02813023          	sd	s0,32(sp)
    8000326c:	00913c23          	sd	s1,24(sp)
    80003270:	01213823          	sd	s2,16(sp)
    80003274:	01313423          	sd	s3,8(sp)
    80003278:	01413023          	sd	s4,0(sp)
    8000327c:	03010413          	addi	s0,sp,48
    80003280:	00050a13          	mv	s4,a0
  struct proc *p = myproc();
    80003284:	fffff097          	auipc	ra,0xfffff
    80003288:	464080e7          	jalr	1124(ra) # 800026e8 <myproc>
    8000328c:	00050993          	mv	s3,a0
  if(p == initproc)
    80003290:	00007797          	auipc	a5,0x7
    80003294:	7307b783          	ld	a5,1840(a5) # 8000a9c0 <initproc>
    80003298:	0d050493          	addi	s1,a0,208
    8000329c:	15050913          	addi	s2,a0,336
    800032a0:	02a79463          	bne	a5,a0,800032c8 <kexit+0x68>
    panic("init exiting");
    800032a4:	00007517          	auipc	a0,0x7
    800032a8:	0c450513          	addi	a0,a0,196 # 8000a368 <digits+0x330>
    800032ac:	ffffd097          	auipc	ra,0xffffd
    800032b0:	7d4080e7          	jalr	2004(ra) # 80000a80 <panic>
      fileclose(f);
    800032b4:	00003097          	auipc	ra,0x3
    800032b8:	260080e7          	jalr	608(ra) # 80006514 <fileclose>
      p->ofile[fd] = 0;
    800032bc:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800032c0:	00848493          	addi	s1,s1,8
    800032c4:	01248863          	beq	s1,s2,800032d4 <kexit+0x74>
    if(p->ofile[fd]){
    800032c8:	0004b503          	ld	a0,0(s1)
    800032cc:	fe0514e3          	bnez	a0,800032b4 <kexit+0x54>
    800032d0:	ff1ff06f          	j	800032c0 <kexit+0x60>
  begin_op();
    800032d4:	00003097          	auipc	ra,0x3
    800032d8:	bc4080e7          	jalr	-1084(ra) # 80005e98 <begin_op>
  iput(p->cwd);
    800032dc:	1509b503          	ld	a0,336(s3)
    800032e0:	00002097          	auipc	ra,0x2
    800032e4:	e18080e7          	jalr	-488(ra) # 800050f8 <iput>
  end_op();
    800032e8:	00003097          	auipc	ra,0x3
    800032ec:	c64080e7          	jalr	-924(ra) # 80005f4c <end_op>
  p->cwd = 0;
    800032f0:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800032f4:	0000f497          	auipc	s1,0xf
    800032f8:	7ec48493          	addi	s1,s1,2028 # 80012ae0 <wait_lock>
    800032fc:	00048513          	mv	a0,s1
    80003300:	ffffe097          	auipc	ra,0xffffe
    80003304:	db8080e7          	jalr	-584(ra) # 800010b8 <acquire>
  reparent(p);
    80003308:	00098513          	mv	a0,s3
    8000330c:	00000097          	auipc	ra,0x0
    80003310:	ed0080e7          	jalr	-304(ra) # 800031dc <reparent>
  wakeup(p->parent);
    80003314:	0389b503          	ld	a0,56(s3)
    80003318:	00000097          	auipc	ra,0x0
    8000331c:	e18080e7          	jalr	-488(ra) # 80003130 <wakeup>
  acquire(&p->lock);
    80003320:	00098513          	mv	a0,s3
    80003324:	ffffe097          	auipc	ra,0xffffe
    80003328:	d94080e7          	jalr	-620(ra) # 800010b8 <acquire>
  p->xstate = status;
    8000332c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80003330:	00500793          	li	a5,5
    80003334:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80003338:	00048513          	mv	a0,s1
    8000333c:	ffffe097          	auipc	ra,0xffffe
    80003340:	e74080e7          	jalr	-396(ra) # 800011b0 <release>
  sched();
    80003344:	00000097          	auipc	ra,0x0
    80003348:	be4080e7          	jalr	-1052(ra) # 80002f28 <sched>
  panic("zombie exit");
    8000334c:	00007517          	auipc	a0,0x7
    80003350:	02c50513          	addi	a0,a0,44 # 8000a378 <digits+0x340>
    80003354:	ffffd097          	auipc	ra,0xffffd
    80003358:	72c080e7          	jalr	1836(ra) # 80000a80 <panic>

000000008000335c <kkill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
    8000335c:	fd010113          	addi	sp,sp,-48
    80003360:	02113423          	sd	ra,40(sp)
    80003364:	02813023          	sd	s0,32(sp)
    80003368:	00913c23          	sd	s1,24(sp)
    8000336c:	01213823          	sd	s2,16(sp)
    80003370:	01313423          	sd	s3,8(sp)
    80003374:	03010413          	addi	s0,sp,48
    80003378:	00050913          	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000337c:	00010497          	auipc	s1,0x10
    80003380:	b7c48493          	addi	s1,s1,-1156 # 80012ef8 <proc>
    80003384:	00015997          	auipc	s3,0x15
    80003388:	57498993          	addi	s3,s3,1396 # 800188f8 <tickslock>
    acquire(&p->lock);
    8000338c:	00048513          	mv	a0,s1
    80003390:	ffffe097          	auipc	ra,0xffffe
    80003394:	d28080e7          	jalr	-728(ra) # 800010b8 <acquire>
    if(p->pid == pid){
    80003398:	0304a783          	lw	a5,48(s1)
    8000339c:	03278063          	beq	a5,s2,800033bc <kkill+0x60>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800033a0:	00048513          	mv	a0,s1
    800033a4:	ffffe097          	auipc	ra,0xffffe
    800033a8:	e0c080e7          	jalr	-500(ra) # 800011b0 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800033ac:	16848493          	addi	s1,s1,360
    800033b0:	fd349ee3          	bne	s1,s3,8000338c <kkill+0x30>
  }
  return -1;
    800033b4:	fff00513          	li	a0,-1
    800033b8:	0280006f          	j	800033e0 <kkill+0x84>
      p->killed = 1;
    800033bc:	00100793          	li	a5,1
    800033c0:	02f4a423          	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800033c4:	0184a703          	lw	a4,24(s1)
    800033c8:	00200793          	li	a5,2
    800033cc:	02f70863          	beq	a4,a5,800033fc <kkill+0xa0>
      release(&p->lock);
    800033d0:	00048513          	mv	a0,s1
    800033d4:	ffffe097          	auipc	ra,0xffffe
    800033d8:	ddc080e7          	jalr	-548(ra) # 800011b0 <release>
      return 0;
    800033dc:	00000513          	li	a0,0
}
    800033e0:	02813083          	ld	ra,40(sp)
    800033e4:	02013403          	ld	s0,32(sp)
    800033e8:	01813483          	ld	s1,24(sp)
    800033ec:	01013903          	ld	s2,16(sp)
    800033f0:	00813983          	ld	s3,8(sp)
    800033f4:	03010113          	addi	sp,sp,48
    800033f8:	00008067          	ret
        p->state = RUNNABLE;
    800033fc:	00300793          	li	a5,3
    80003400:	00f4ac23          	sw	a5,24(s1)
    80003404:	fcdff06f          	j	800033d0 <kkill+0x74>

0000000080003408 <setkilled>:

void
setkilled(struct proc *p)
{
    80003408:	fe010113          	addi	sp,sp,-32
    8000340c:	00113c23          	sd	ra,24(sp)
    80003410:	00813823          	sd	s0,16(sp)
    80003414:	00913423          	sd	s1,8(sp)
    80003418:	02010413          	addi	s0,sp,32
    8000341c:	00050493          	mv	s1,a0
  acquire(&p->lock);
    80003420:	ffffe097          	auipc	ra,0xffffe
    80003424:	c98080e7          	jalr	-872(ra) # 800010b8 <acquire>
  p->killed = 1;
    80003428:	00100793          	li	a5,1
    8000342c:	02f4a423          	sw	a5,40(s1)
  release(&p->lock);
    80003430:	00048513          	mv	a0,s1
    80003434:	ffffe097          	auipc	ra,0xffffe
    80003438:	d7c080e7          	jalr	-644(ra) # 800011b0 <release>
}
    8000343c:	01813083          	ld	ra,24(sp)
    80003440:	01013403          	ld	s0,16(sp)
    80003444:	00813483          	ld	s1,8(sp)
    80003448:	02010113          	addi	sp,sp,32
    8000344c:	00008067          	ret

0000000080003450 <killed>:

int
killed(struct proc *p)
{
    80003450:	fe010113          	addi	sp,sp,-32
    80003454:	00113c23          	sd	ra,24(sp)
    80003458:	00813823          	sd	s0,16(sp)
    8000345c:	00913423          	sd	s1,8(sp)
    80003460:	01213023          	sd	s2,0(sp)
    80003464:	02010413          	addi	s0,sp,32
    80003468:	00050493          	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000346c:	ffffe097          	auipc	ra,0xffffe
    80003470:	c4c080e7          	jalr	-948(ra) # 800010b8 <acquire>
  k = p->killed;
    80003474:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80003478:	00048513          	mv	a0,s1
    8000347c:	ffffe097          	auipc	ra,0xffffe
    80003480:	d34080e7          	jalr	-716(ra) # 800011b0 <release>
  return k;
}
    80003484:	00090513          	mv	a0,s2
    80003488:	01813083          	ld	ra,24(sp)
    8000348c:	01013403          	ld	s0,16(sp)
    80003490:	00813483          	ld	s1,8(sp)
    80003494:	00013903          	ld	s2,0(sp)
    80003498:	02010113          	addi	sp,sp,32
    8000349c:	00008067          	ret

00000000800034a0 <kwait>:
{
    800034a0:	fb010113          	addi	sp,sp,-80
    800034a4:	04113423          	sd	ra,72(sp)
    800034a8:	04813023          	sd	s0,64(sp)
    800034ac:	02913c23          	sd	s1,56(sp)
    800034b0:	03213823          	sd	s2,48(sp)
    800034b4:	03313423          	sd	s3,40(sp)
    800034b8:	03413023          	sd	s4,32(sp)
    800034bc:	01513c23          	sd	s5,24(sp)
    800034c0:	01613823          	sd	s6,16(sp)
    800034c4:	01713423          	sd	s7,8(sp)
    800034c8:	01813023          	sd	s8,0(sp)
    800034cc:	05010413          	addi	s0,sp,80
    800034d0:	00050b13          	mv	s6,a0
  struct proc *p = myproc();
    800034d4:	fffff097          	auipc	ra,0xfffff
    800034d8:	214080e7          	jalr	532(ra) # 800026e8 <myproc>
    800034dc:	00050913          	mv	s2,a0
  acquire(&wait_lock);
    800034e0:	0000f517          	auipc	a0,0xf
    800034e4:	60050513          	addi	a0,a0,1536 # 80012ae0 <wait_lock>
    800034e8:	ffffe097          	auipc	ra,0xffffe
    800034ec:	bd0080e7          	jalr	-1072(ra) # 800010b8 <acquire>
    havekids = 0;
    800034f0:	00000b93          	li	s7,0
        if(pp->state == ZOMBIE){
    800034f4:	00500a13          	li	s4,5
        havekids = 1;
    800034f8:	00100a93          	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800034fc:	00015997          	auipc	s3,0x15
    80003500:	3fc98993          	addi	s3,s3,1020 # 800188f8 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80003504:	0000fc17          	auipc	s8,0xf
    80003508:	5dcc0c13          	addi	s8,s8,1500 # 80012ae0 <wait_lock>
    havekids = 0;
    8000350c:	000b8713          	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80003510:	00010497          	auipc	s1,0x10
    80003514:	9e848493          	addi	s1,s1,-1560 # 80012ef8 <proc>
    80003518:	0800006f          	j	80003598 <kwait+0xf8>
          pid = pp->pid;
    8000351c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80003520:	020b0063          	beqz	s6,80003540 <kwait+0xa0>
    80003524:	00400693          	li	a3,4
    80003528:	02c48613          	addi	a2,s1,44
    8000352c:	000b0593          	mv	a1,s6
    80003530:	05093503          	ld	a0,80(s2)
    80003534:	fffff097          	auipc	ra,0xfffff
    80003538:	d40080e7          	jalr	-704(ra) # 80002274 <copyout>
    8000353c:	02054863          	bltz	a0,8000356c <kwait+0xcc>
          freeproc(pp);
    80003540:	00048513          	mv	a0,s1
    80003544:	fffff097          	auipc	ra,0xfffff
    80003548:	4b8080e7          	jalr	1208(ra) # 800029fc <freeproc>
          release(&pp->lock);
    8000354c:	00048513          	mv	a0,s1
    80003550:	ffffe097          	auipc	ra,0xffffe
    80003554:	c60080e7          	jalr	-928(ra) # 800011b0 <release>
          release(&wait_lock);
    80003558:	0000f517          	auipc	a0,0xf
    8000355c:	58850513          	addi	a0,a0,1416 # 80012ae0 <wait_lock>
    80003560:	ffffe097          	auipc	ra,0xffffe
    80003564:	c50080e7          	jalr	-944(ra) # 800011b0 <release>
          return pid;
    80003568:	0880006f          	j	800035f0 <kwait+0x150>
            release(&pp->lock);
    8000356c:	00048513          	mv	a0,s1
    80003570:	ffffe097          	auipc	ra,0xffffe
    80003574:	c40080e7          	jalr	-960(ra) # 800011b0 <release>
            release(&wait_lock);
    80003578:	0000f517          	auipc	a0,0xf
    8000357c:	56850513          	addi	a0,a0,1384 # 80012ae0 <wait_lock>
    80003580:	ffffe097          	auipc	ra,0xffffe
    80003584:	c30080e7          	jalr	-976(ra) # 800011b0 <release>
            return -1;
    80003588:	fff00993          	li	s3,-1
    8000358c:	0640006f          	j	800035f0 <kwait+0x150>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80003590:	16848493          	addi	s1,s1,360
    80003594:	03348a63          	beq	s1,s3,800035c8 <kwait+0x128>
      if(pp->parent == p){
    80003598:	0384b783          	ld	a5,56(s1)
    8000359c:	ff279ae3          	bne	a5,s2,80003590 <kwait+0xf0>
        acquire(&pp->lock);
    800035a0:	00048513          	mv	a0,s1
    800035a4:	ffffe097          	auipc	ra,0xffffe
    800035a8:	b14080e7          	jalr	-1260(ra) # 800010b8 <acquire>
        if(pp->state == ZOMBIE){
    800035ac:	0184a783          	lw	a5,24(s1)
    800035b0:	f74786e3          	beq	a5,s4,8000351c <kwait+0x7c>
        release(&pp->lock);
    800035b4:	00048513          	mv	a0,s1
    800035b8:	ffffe097          	auipc	ra,0xffffe
    800035bc:	bf8080e7          	jalr	-1032(ra) # 800011b0 <release>
        havekids = 1;
    800035c0:	000a8713          	mv	a4,s5
    800035c4:	fcdff06f          	j	80003590 <kwait+0xf0>
    if(!havekids || killed(p)){
    800035c8:	00070a63          	beqz	a4,800035dc <kwait+0x13c>
    800035cc:	00090513          	mv	a0,s2
    800035d0:	00000097          	auipc	ra,0x0
    800035d4:	e80080e7          	jalr	-384(ra) # 80003450 <killed>
    800035d8:	04050663          	beqz	a0,80003624 <kwait+0x184>
      release(&wait_lock);
    800035dc:	0000f517          	auipc	a0,0xf
    800035e0:	50450513          	addi	a0,a0,1284 # 80012ae0 <wait_lock>
    800035e4:	ffffe097          	auipc	ra,0xffffe
    800035e8:	bcc080e7          	jalr	-1076(ra) # 800011b0 <release>
      return -1;
    800035ec:	fff00993          	li	s3,-1
}
    800035f0:	00098513          	mv	a0,s3
    800035f4:	04813083          	ld	ra,72(sp)
    800035f8:	04013403          	ld	s0,64(sp)
    800035fc:	03813483          	ld	s1,56(sp)
    80003600:	03013903          	ld	s2,48(sp)
    80003604:	02813983          	ld	s3,40(sp)
    80003608:	02013a03          	ld	s4,32(sp)
    8000360c:	01813a83          	ld	s5,24(sp)
    80003610:	01013b03          	ld	s6,16(sp)
    80003614:	00813b83          	ld	s7,8(sp)
    80003618:	00013c03          	ld	s8,0(sp)
    8000361c:	05010113          	addi	sp,sp,80
    80003620:	00008067          	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80003624:	000c0593          	mv	a1,s8
    80003628:	00090513          	mv	a0,s2
    8000362c:	00000097          	auipc	ra,0x0
    80003630:	a74080e7          	jalr	-1420(ra) # 800030a0 <sleep>
    havekids = 0;
    80003634:	ed9ff06f          	j	8000350c <kwait+0x6c>

0000000080003638 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80003638:	fd010113          	addi	sp,sp,-48
    8000363c:	02113423          	sd	ra,40(sp)
    80003640:	02813023          	sd	s0,32(sp)
    80003644:	00913c23          	sd	s1,24(sp)
    80003648:	01213823          	sd	s2,16(sp)
    8000364c:	01313423          	sd	s3,8(sp)
    80003650:	01413023          	sd	s4,0(sp)
    80003654:	03010413          	addi	s0,sp,48
    80003658:	00050493          	mv	s1,a0
    8000365c:	00058913          	mv	s2,a1
    80003660:	00060993          	mv	s3,a2
    80003664:	00068a13          	mv	s4,a3
  struct proc *p = myproc();
    80003668:	fffff097          	auipc	ra,0xfffff
    8000366c:	080080e7          	jalr	128(ra) # 800026e8 <myproc>
  if(user_dst){
    80003670:	02048e63          	beqz	s1,800036ac <either_copyout+0x74>
    return copyout(p->pagetable, dst, src, len);
    80003674:	000a0693          	mv	a3,s4
    80003678:	00098613          	mv	a2,s3
    8000367c:	00090593          	mv	a1,s2
    80003680:	05053503          	ld	a0,80(a0)
    80003684:	fffff097          	auipc	ra,0xfffff
    80003688:	bf0080e7          	jalr	-1040(ra) # 80002274 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000368c:	02813083          	ld	ra,40(sp)
    80003690:	02013403          	ld	s0,32(sp)
    80003694:	01813483          	ld	s1,24(sp)
    80003698:	01013903          	ld	s2,16(sp)
    8000369c:	00813983          	ld	s3,8(sp)
    800036a0:	00013a03          	ld	s4,0(sp)
    800036a4:	03010113          	addi	sp,sp,48
    800036a8:	00008067          	ret
    memmove((char *)dst, src, len);
    800036ac:	000a061b          	sext.w	a2,s4
    800036b0:	00098593          	mv	a1,s3
    800036b4:	00090513          	mv	a0,s2
    800036b8:	ffffe097          	auipc	ra,0xffffe
    800036bc:	bec080e7          	jalr	-1044(ra) # 800012a4 <memmove>
    return 0;
    800036c0:	00048513          	mv	a0,s1
    800036c4:	fc9ff06f          	j	8000368c <either_copyout+0x54>

00000000800036c8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800036c8:	fd010113          	addi	sp,sp,-48
    800036cc:	02113423          	sd	ra,40(sp)
    800036d0:	02813023          	sd	s0,32(sp)
    800036d4:	00913c23          	sd	s1,24(sp)
    800036d8:	01213823          	sd	s2,16(sp)
    800036dc:	01313423          	sd	s3,8(sp)
    800036e0:	01413023          	sd	s4,0(sp)
    800036e4:	03010413          	addi	s0,sp,48
    800036e8:	00050913          	mv	s2,a0
    800036ec:	00058493          	mv	s1,a1
    800036f0:	00060993          	mv	s3,a2
    800036f4:	00068a13          	mv	s4,a3
  struct proc *p = myproc();
    800036f8:	fffff097          	auipc	ra,0xfffff
    800036fc:	ff0080e7          	jalr	-16(ra) # 800026e8 <myproc>
  if(user_src){
    80003700:	02048e63          	beqz	s1,8000373c <either_copyin+0x74>
    return copyin(p->pagetable, dst, src, len);
    80003704:	000a0693          	mv	a3,s4
    80003708:	00098613          	mv	a2,s3
    8000370c:	00090593          	mv	a1,s2
    80003710:	05053503          	ld	a0,80(a0)
    80003714:	fffff097          	auipc	ra,0xfffff
    80003718:	cc8080e7          	jalr	-824(ra) # 800023dc <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000371c:	02813083          	ld	ra,40(sp)
    80003720:	02013403          	ld	s0,32(sp)
    80003724:	01813483          	ld	s1,24(sp)
    80003728:	01013903          	ld	s2,16(sp)
    8000372c:	00813983          	ld	s3,8(sp)
    80003730:	00013a03          	ld	s4,0(sp)
    80003734:	03010113          	addi	sp,sp,48
    80003738:	00008067          	ret
    memmove(dst, (char*)src, len);
    8000373c:	000a061b          	sext.w	a2,s4
    80003740:	00098593          	mv	a1,s3
    80003744:	00090513          	mv	a0,s2
    80003748:	ffffe097          	auipc	ra,0xffffe
    8000374c:	b5c080e7          	jalr	-1188(ra) # 800012a4 <memmove>
    return 0;
    80003750:	00048513          	mv	a0,s1
    80003754:	fc9ff06f          	j	8000371c <either_copyin+0x54>

0000000080003758 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80003758:	fb010113          	addi	sp,sp,-80
    8000375c:	04113423          	sd	ra,72(sp)
    80003760:	04813023          	sd	s0,64(sp)
    80003764:	02913c23          	sd	s1,56(sp)
    80003768:	03213823          	sd	s2,48(sp)
    8000376c:	03313423          	sd	s3,40(sp)
    80003770:	03413023          	sd	s4,32(sp)
    80003774:	01513c23          	sd	s5,24(sp)
    80003778:	01613823          	sd	s6,16(sp)
    8000377c:	01713423          	sd	s7,8(sp)
    80003780:	05010413          	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80003784:	00007517          	auipc	a0,0x7
    80003788:	aac50513          	addi	a0,a0,-1364 # 8000a230 <digits+0x1f8>
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	f1c080e7          	jalr	-228(ra) # 800006a8 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80003794:	00010497          	auipc	s1,0x10
    80003798:	8bc48493          	addi	s1,s1,-1860 # 80013050 <proc+0x158>
    8000379c:	00015917          	auipc	s2,0x15
    800037a0:	2b490913          	addi	s2,s2,692 # 80018a50 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800037a4:	00500b13          	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800037a8:	00007997          	auipc	s3,0x7
    800037ac:	be098993          	addi	s3,s3,-1056 # 8000a388 <digits+0x350>
    printf("%d %s %s", p->pid, state, p->name);
    800037b0:	00007a97          	auipc	s5,0x7
    800037b4:	be0a8a93          	addi	s5,s5,-1056 # 8000a390 <digits+0x358>
    printf("\n");
    800037b8:	00007a17          	auipc	s4,0x7
    800037bc:	a78a0a13          	addi	s4,s4,-1416 # 8000a230 <digits+0x1f8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800037c0:	00007b97          	auipc	s7,0x7
    800037c4:	c10b8b93          	addi	s7,s7,-1008 # 8000a3d0 <states.0>
    800037c8:	0280006f          	j	800037f0 <procdump+0x98>
    printf("%d %s %s", p->pid, state, p->name);
    800037cc:	ed86a583          	lw	a1,-296(a3)
    800037d0:	000a8513          	mv	a0,s5
    800037d4:	ffffd097          	auipc	ra,0xffffd
    800037d8:	ed4080e7          	jalr	-300(ra) # 800006a8 <printf>
    printf("\n");
    800037dc:	000a0513          	mv	a0,s4
    800037e0:	ffffd097          	auipc	ra,0xffffd
    800037e4:	ec8080e7          	jalr	-312(ra) # 800006a8 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800037e8:	16848493          	addi	s1,s1,360
    800037ec:	03248a63          	beq	s1,s2,80003820 <procdump+0xc8>
    if(p->state == UNUSED)
    800037f0:	00048693          	mv	a3,s1
    800037f4:	ec04a783          	lw	a5,-320(s1)
    800037f8:	fe0788e3          	beqz	a5,800037e8 <procdump+0x90>
      state = "???";
    800037fc:	00098613          	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003800:	fcfb66e3          	bltu	s6,a5,800037cc <procdump+0x74>
    80003804:	02079713          	slli	a4,a5,0x20
    80003808:	01d75793          	srli	a5,a4,0x1d
    8000380c:	00fb87b3          	add	a5,s7,a5
    80003810:	0007b603          	ld	a2,0(a5)
    80003814:	fa061ce3          	bnez	a2,800037cc <procdump+0x74>
      state = "???";
    80003818:	00098613          	mv	a2,s3
    8000381c:	fb1ff06f          	j	800037cc <procdump+0x74>
  }
}
    80003820:	04813083          	ld	ra,72(sp)
    80003824:	04013403          	ld	s0,64(sp)
    80003828:	03813483          	ld	s1,56(sp)
    8000382c:	03013903          	ld	s2,48(sp)
    80003830:	02813983          	ld	s3,40(sp)
    80003834:	02013a03          	ld	s4,32(sp)
    80003838:	01813a83          	ld	s5,24(sp)
    8000383c:	01013b03          	ld	s6,16(sp)
    80003840:	00813b83          	ld	s7,8(sp)
    80003844:	05010113          	addi	sp,sp,80
    80003848:	00008067          	ret

000000008000384c <swtch>:
# Save current registers in old. Load from new.	


.globl swtch
swtch:
        sd ra, 0(a0)
    8000384c:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)
    80003850:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)
    80003854:	00853823          	sd	s0,16(a0)
        sd s1, 24(a0)
    80003858:	00953c23          	sd	s1,24(a0)
        sd s2, 32(a0)
    8000385c:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)
    80003860:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)
    80003864:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)
    80003868:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)
    8000386c:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)
    80003870:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)
    80003874:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)
    80003878:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
    8000387c:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
    80003880:	07b53423          	sd	s11,104(a0)

        ld ra, 0(a1)
    80003884:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)
    80003888:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)
    8000388c:	0105b403          	ld	s0,16(a1)
        ld s1, 24(a1)
    80003890:	0185b483          	ld	s1,24(a1)
        ld s2, 32(a1)
    80003894:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)
    80003898:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)
    8000389c:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)
    800038a0:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)
    800038a4:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)
    800038a8:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)
    800038ac:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)
    800038b0:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
    800038b4:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
    800038b8:	0685bd83          	ld	s11,104(a1)
        
        ret
    800038bc:	00008067          	ret

00000000800038c0 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800038c0:	ff010113          	addi	sp,sp,-16
    800038c4:	00113423          	sd	ra,8(sp)
    800038c8:	00813023          	sd	s0,0(sp)
    800038cc:	01010413          	addi	s0,sp,16
  initlock(&tickslock, "time");
    800038d0:	00007597          	auipc	a1,0x7
    800038d4:	b3058593          	addi	a1,a1,-1232 # 8000a400 <states.0+0x30>
    800038d8:	00015517          	auipc	a0,0x15
    800038dc:	02050513          	addi	a0,a0,32 # 800188f8 <tickslock>
    800038e0:	ffffd097          	auipc	ra,0xffffd
    800038e4:	6f4080e7          	jalr	1780(ra) # 80000fd4 <initlock>
}
    800038e8:	00813083          	ld	ra,8(sp)
    800038ec:	00013403          	ld	s0,0(sp)
    800038f0:	01010113          	addi	sp,sp,16
    800038f4:	00008067          	ret

00000000800038f8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800038f8:	ff010113          	addi	sp,sp,-16
    800038fc:	00813423          	sd	s0,8(sp)
    80003900:	01010413          	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003904:	00005797          	auipc	a5,0x5
    80003908:	9bc78793          	addi	a5,a5,-1604 # 800082c0 <kernelvec>
    8000390c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80003910:	00813403          	ld	s0,8(sp)
    80003914:	01010113          	addi	sp,sp,16
    80003918:	00008067          	ret

000000008000391c <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    8000391c:	ff010113          	addi	sp,sp,-16
    80003920:	00113423          	sd	ra,8(sp)
    80003924:	00813023          	sd	s0,0(sp)
    80003928:	01010413          	addi	s0,sp,16
  struct proc *p = myproc();
    8000392c:	fffff097          	auipc	ra,0xfffff
    80003930:	dbc080e7          	jalr	-580(ra) # 800026e8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003934:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003938:	ffd7f793          	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000393c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80003940:	04000737          	lui	a4,0x4000
    80003944:	00005797          	auipc	a5,0x5
    80003948:	6bc78793          	addi	a5,a5,1724 # 80009000 <_trampoline>
    8000394c:	00005697          	auipc	a3,0x5
    80003950:	6b468693          	addi	a3,a3,1716 # 80009000 <_trampoline>
    80003954:	40d787b3          	sub	a5,a5,a3
    80003958:	fff70713          	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    8000395c:	00c71713          	slli	a4,a4,0xc
    80003960:	00e787b3          	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003964:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80003968:	05853783          	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000396c:	18002773          	csrr	a4,satp
    80003970:	00e7b023          	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80003974:	05853703          	ld	a4,88(a0)
    80003978:	04053783          	ld	a5,64(a0)
    8000397c:	000016b7          	lui	a3,0x1
    80003980:	00d787b3          	add	a5,a5,a3
    80003984:	00f73423          	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80003988:	05853783          	ld	a5,88(a0)
    8000398c:	00000717          	auipc	a4,0x0
    80003990:	17c70713          	addi	a4,a4,380 # 80003b08 <usertrap>
    80003994:	00e7b823          	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80003998:	05853783          	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000399c:	00020713          	mv	a4,tp
    800039a0:	02e7b023          	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800039a4:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800039a8:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800039ac:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800039b0:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800039b4:	05853783          	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800039b8:	0187b783          	ld	a5,24(a5)
    800039bc:	14179073          	csrw	sepc,a5
}
    800039c0:	00813083          	ld	ra,8(sp)
    800039c4:	00013403          	ld	s0,0(sp)
    800039c8:	01010113          	addi	sp,sp,16
    800039cc:	00008067          	ret

00000000800039d0 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800039d0:	fe010113          	addi	sp,sp,-32
    800039d4:	00113c23          	sd	ra,24(sp)
    800039d8:	00813823          	sd	s0,16(sp)
    800039dc:	00913423          	sd	s1,8(sp)
    800039e0:	02010413          	addi	s0,sp,32
  if(cpuid() == 0){
    800039e4:	fffff097          	auipc	ra,0xfffff
    800039e8:	cb4080e7          	jalr	-844(ra) # 80002698 <cpuid>
    800039ec:	00050c63          	beqz	a0,80003a04 <clockintr+0x34>

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
//  w_stimecmp(r_time() + 1000000);
} 
    800039f0:	01813083          	ld	ra,24(sp)
    800039f4:	01013403          	ld	s0,16(sp)
    800039f8:	00813483          	ld	s1,8(sp)
    800039fc:	02010113          	addi	sp,sp,32
    80003a00:	00008067          	ret
    acquire(&tickslock);
    80003a04:	00015497          	auipc	s1,0x15
    80003a08:	ef448493          	addi	s1,s1,-268 # 800188f8 <tickslock>
    80003a0c:	00048513          	mv	a0,s1
    80003a10:	ffffd097          	auipc	ra,0xffffd
    80003a14:	6a8080e7          	jalr	1704(ra) # 800010b8 <acquire>
    ticks++;
    80003a18:	00007517          	auipc	a0,0x7
    80003a1c:	fb050513          	addi	a0,a0,-80 # 8000a9c8 <ticks>
    80003a20:	00052783          	lw	a5,0(a0)
    80003a24:	0017879b          	addiw	a5,a5,1
    80003a28:	00f52023          	sw	a5,0(a0)
    wakeup(&ticks);
    80003a2c:	fffff097          	auipc	ra,0xfffff
    80003a30:	704080e7          	jalr	1796(ra) # 80003130 <wakeup>
    release(&tickslock);
    80003a34:	00048513          	mv	a0,s1
    80003a38:	ffffd097          	auipc	ra,0xffffd
    80003a3c:	778080e7          	jalr	1912(ra) # 800011b0 <release>
} 
    80003a40:	fb1ff06f          	j	800039f0 <clockintr+0x20>

0000000080003a44 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003a44:	fe010113          	addi	sp,sp,-32
    80003a48:	00113c23          	sd	ra,24(sp)
    80003a4c:	00813823          	sd	s0,16(sp)
    80003a50:	00913423          	sd	s1,8(sp)
    80003a54:	02010413          	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003a58:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    80003a5c:	fff00793          	li	a5,-1
    80003a60:	03f79793          	slli	a5,a5,0x3f
    80003a64:	00978793          	addi	a5,a5,9
    80003a68:	02f70663          	beq	a4,a5,80003a94 <devintr+0x50>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    80003a6c:	fff00793          	li	a5,-1
    80003a70:	03f79793          	slli	a5,a5,0x3f
    80003a74:	00578793          	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    80003a78:	00000513          	li	a0,0
  } else if(scause == 0x8000000000000005L){
    80003a7c:	06f70e63          	beq	a4,a5,80003af8 <devintr+0xb4>
  }
}
    80003a80:	01813083          	ld	ra,24(sp)
    80003a84:	01013403          	ld	s0,16(sp)
    80003a88:	00813483          	ld	s1,8(sp)
    80003a8c:	02010113          	addi	sp,sp,32
    80003a90:	00008067          	ret
    int irq = plic_claim();
    80003a94:	00005097          	auipc	ra,0x5
    80003a98:	940080e7          	jalr	-1728(ra) # 800083d4 <plic_claim>
    80003a9c:	00050493          	mv	s1,a0
    if(irq == UART0_IRQ){
    80003aa0:	00a00793          	li	a5,10
    80003aa4:	02f50e63          	beq	a0,a5,80003ae0 <devintr+0x9c>
    } else if(irq == VIRTIO0_IRQ){
    80003aa8:	00100793          	li	a5,1
    80003aac:	04f50063          	beq	a0,a5,80003aec <devintr+0xa8>
    return 1;
    80003ab0:	00100513          	li	a0,1
    } else if(irq){
    80003ab4:	fc0486e3          	beqz	s1,80003a80 <devintr+0x3c>
      printf("unexpected interrupt irq=%d\n", irq);
    80003ab8:	00048593          	mv	a1,s1
    80003abc:	00007517          	auipc	a0,0x7
    80003ac0:	94c50513          	addi	a0,a0,-1716 # 8000a408 <states.0+0x38>
    80003ac4:	ffffd097          	auipc	ra,0xffffd
    80003ac8:	be4080e7          	jalr	-1052(ra) # 800006a8 <printf>
      plic_complete(irq);
    80003acc:	00048513          	mv	a0,s1
    80003ad0:	00005097          	auipc	ra,0x5
    80003ad4:	93c080e7          	jalr	-1732(ra) # 8000840c <plic_complete>
    return 1;
    80003ad8:	00100513          	li	a0,1
    80003adc:	fa5ff06f          	j	80003a80 <devintr+0x3c>
      uartintr();
    80003ae0:	ffffd097          	auipc	ra,0xffffd
    80003ae4:	24c080e7          	jalr	588(ra) # 80000d2c <uartintr>
    80003ae8:	fe5ff06f          	j	80003acc <devintr+0x88>
      virtio_disk_intr();
    80003aec:	00005097          	auipc	ra,0x5
    80003af0:	f5c080e7          	jalr	-164(ra) # 80008a48 <virtio_disk_intr>
    80003af4:	fd9ff06f          	j	80003acc <devintr+0x88>
    clockintr();
    80003af8:	00000097          	auipc	ra,0x0
    80003afc:	ed8080e7          	jalr	-296(ra) # 800039d0 <clockintr>
    return 2;
    80003b00:	00200513          	li	a0,2
    80003b04:	f7dff06f          	j	80003a80 <devintr+0x3c>

0000000080003b08 <usertrap>:
{
    80003b08:	fe010113          	addi	sp,sp,-32
    80003b0c:	00113c23          	sd	ra,24(sp)
    80003b10:	00813823          	sd	s0,16(sp)
    80003b14:	00913423          	sd	s1,8(sp)
    80003b18:	01213023          	sd	s2,0(sp)
    80003b1c:	02010413          	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003b20:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003b24:	1007f793          	andi	a5,a5,256
    80003b28:	08079e63          	bnez	a5,80003bc4 <usertrap+0xbc>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003b2c:	00004797          	auipc	a5,0x4
    80003b30:	79478793          	addi	a5,a5,1940 # 800082c0 <kernelvec>
    80003b34:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003b38:	fffff097          	auipc	ra,0xfffff
    80003b3c:	bb0080e7          	jalr	-1104(ra) # 800026e8 <myproc>
    80003b40:	00050493          	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003b44:	05853783          	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003b48:	14102773          	csrr	a4,sepc
    80003b4c:	00e7bc23          	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003b50:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003b54:	00800793          	li	a5,8
    80003b58:	06f70e63          	beq	a4,a5,80003bd4 <usertrap+0xcc>
  } else if((which_dev = devintr()) != 0){
    80003b5c:	00000097          	auipc	ra,0x0
    80003b60:	ee8080e7          	jalr	-280(ra) # 80003a44 <devintr>
    80003b64:	00050913          	mv	s2,a0
    80003b68:	10051a63          	bnez	a0,80003c7c <usertrap+0x174>
    80003b6c:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80003b70:	00f00793          	li	a5,15
    80003b74:	0ef70263          	beq	a4,a5,80003c58 <usertrap+0x150>
    80003b78:	14202773          	csrr	a4,scause
    80003b7c:	00d00793          	li	a5,13
    80003b80:	0cf70c63          	beq	a4,a5,80003c58 <usertrap+0x150>
    80003b84:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    80003b88:	0304a603          	lw	a2,48(s1)
    80003b8c:	00007517          	auipc	a0,0x7
    80003b90:	8bc50513          	addi	a0,a0,-1860 # 8000a448 <states.0+0x78>
    80003b94:	ffffd097          	auipc	ra,0xffffd
    80003b98:	b14080e7          	jalr	-1260(ra) # 800006a8 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003b9c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003ba0:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    80003ba4:	00007517          	auipc	a0,0x7
    80003ba8:	8d450513          	addi	a0,a0,-1836 # 8000a478 <states.0+0xa8>
    80003bac:	ffffd097          	auipc	ra,0xffffd
    80003bb0:	afc080e7          	jalr	-1284(ra) # 800006a8 <printf>
    setkilled(p);
    80003bb4:	00048513          	mv	a0,s1
    80003bb8:	00000097          	auipc	ra,0x0
    80003bbc:	850080e7          	jalr	-1968(ra) # 80003408 <setkilled>
    80003bc0:	0440006f          	j	80003c04 <usertrap+0xfc>
    panic("usertrap: not from user mode");
    80003bc4:	00007517          	auipc	a0,0x7
    80003bc8:	86450513          	addi	a0,a0,-1948 # 8000a428 <states.0+0x58>
    80003bcc:	ffffd097          	auipc	ra,0xffffd
    80003bd0:	eb4080e7          	jalr	-332(ra) # 80000a80 <panic>
    if(killed(p))
    80003bd4:	00000097          	auipc	ra,0x0
    80003bd8:	87c080e7          	jalr	-1924(ra) # 80003450 <killed>
    80003bdc:	06051663          	bnez	a0,80003c48 <usertrap+0x140>
    p->trapframe->epc += 4;
    80003be0:	0584b703          	ld	a4,88(s1)
    80003be4:	01873783          	ld	a5,24(a4)
    80003be8:	00478793          	addi	a5,a5,4
    80003bec:	00f73c23          	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003bf0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003bf4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003bf8:	10079073          	csrw	sstatus,a5
    syscall();
    80003bfc:	00000097          	auipc	ra,0x0
    80003c00:	400080e7          	jalr	1024(ra) # 80003ffc <syscall>
  if(killed(p))
    80003c04:	00048513          	mv	a0,s1
    80003c08:	00000097          	auipc	ra,0x0
    80003c0c:	848080e7          	jalr	-1976(ra) # 80003450 <killed>
    80003c10:	08051063          	bnez	a0,80003c90 <usertrap+0x188>
  prepare_return();
    80003c14:	00000097          	auipc	ra,0x0
    80003c18:	d08080e7          	jalr	-760(ra) # 8000391c <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    80003c1c:	0504b503          	ld	a0,80(s1)
    80003c20:	00c55513          	srli	a0,a0,0xc
    80003c24:	fff00793          	li	a5,-1
    80003c28:	03f79793          	slli	a5,a5,0x3f
    80003c2c:	00f56533          	or	a0,a0,a5
}
    80003c30:	01813083          	ld	ra,24(sp)
    80003c34:	01013403          	ld	s0,16(sp)
    80003c38:	00813483          	ld	s1,8(sp)
    80003c3c:	00013903          	ld	s2,0(sp)
    80003c40:	02010113          	addi	sp,sp,32
    80003c44:	00008067          	ret
      kexit(-1);
    80003c48:	fff00513          	li	a0,-1
    80003c4c:	fffff097          	auipc	ra,0xfffff
    80003c50:	614080e7          	jalr	1556(ra) # 80003260 <kexit>
    80003c54:	f8dff06f          	j	80003be0 <usertrap+0xd8>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003c58:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003c5c:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    80003c60:	ff360613          	addi	a2,a2,-13 # ff3 <_entry-0x7ffff00d>
    80003c64:	00163613          	seqz	a2,a2
    80003c68:	0504b503          	ld	a0,80(s1)
    80003c6c:	ffffe097          	auipc	ra,0xffffe
    80003c70:	52c080e7          	jalr	1324(ra) # 80002198 <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80003c74:	f80518e3          	bnez	a0,80003c04 <usertrap+0xfc>
    80003c78:	f0dff06f          	j	80003b84 <usertrap+0x7c>
  if(killed(p))
    80003c7c:	00048513          	mv	a0,s1
    80003c80:	fffff097          	auipc	ra,0xfffff
    80003c84:	7d0080e7          	jalr	2000(ra) # 80003450 <killed>
    80003c88:	00050c63          	beqz	a0,80003ca0 <usertrap+0x198>
    80003c8c:	0080006f          	j	80003c94 <usertrap+0x18c>
    80003c90:	00000913          	li	s2,0
    kexit(-1);
    80003c94:	fff00513          	li	a0,-1
    80003c98:	fffff097          	auipc	ra,0xfffff
    80003c9c:	5c8080e7          	jalr	1480(ra) # 80003260 <kexit>
  if(which_dev == 2)
    80003ca0:	00200793          	li	a5,2
    80003ca4:	f6f918e3          	bne	s2,a5,80003c14 <usertrap+0x10c>
    yield();
    80003ca8:	fffff097          	auipc	ra,0xfffff
    80003cac:	3a0080e7          	jalr	928(ra) # 80003048 <yield>
    80003cb0:	f65ff06f          	j	80003c14 <usertrap+0x10c>

0000000080003cb4 <kerneltrap>:
{
    80003cb4:	fd010113          	addi	sp,sp,-48
    80003cb8:	02113423          	sd	ra,40(sp)
    80003cbc:	02813023          	sd	s0,32(sp)
    80003cc0:	00913c23          	sd	s1,24(sp)
    80003cc4:	01213823          	sd	s2,16(sp)
    80003cc8:	01313423          	sd	s3,8(sp)
    80003ccc:	03010413          	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003cd0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003cd4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003cd8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003cdc:	1004f793          	andi	a5,s1,256
    80003ce0:	04078463          	beqz	a5,80003d28 <kerneltrap+0x74>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003ce4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003ce8:	0027f793          	andi	a5,a5,2
  if(intr_get() != 0)
    80003cec:	04079663          	bnez	a5,80003d38 <kerneltrap+0x84>
  if((which_dev = devintr()) == 0){
    80003cf0:	00000097          	auipc	ra,0x0
    80003cf4:	d54080e7          	jalr	-684(ra) # 80003a44 <devintr>
    80003cf8:	04050863          	beqz	a0,80003d48 <kerneltrap+0x94>
  if(which_dev == 2 && myproc() != 0)
    80003cfc:	00200793          	li	a5,2
    80003d00:	06f50a63          	beq	a0,a5,80003d74 <kerneltrap+0xc0>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003d04:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003d08:	10049073          	csrw	sstatus,s1
}
    80003d0c:	02813083          	ld	ra,40(sp)
    80003d10:	02013403          	ld	s0,32(sp)
    80003d14:	01813483          	ld	s1,24(sp)
    80003d18:	01013903          	ld	s2,16(sp)
    80003d1c:	00813983          	ld	s3,8(sp)
    80003d20:	03010113          	addi	sp,sp,48
    80003d24:	00008067          	ret
    panic("kerneltrap: not from supervisor mode");
    80003d28:	00006517          	auipc	a0,0x6
    80003d2c:	77850513          	addi	a0,a0,1912 # 8000a4a0 <states.0+0xd0>
    80003d30:	ffffd097          	auipc	ra,0xffffd
    80003d34:	d50080e7          	jalr	-688(ra) # 80000a80 <panic>
    panic("kerneltrap: interrupts enabled");
    80003d38:	00006517          	auipc	a0,0x6
    80003d3c:	79050513          	addi	a0,a0,1936 # 8000a4c8 <states.0+0xf8>
    80003d40:	ffffd097          	auipc	ra,0xffffd
    80003d44:	d40080e7          	jalr	-704(ra) # 80000a80 <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003d48:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003d4c:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    80003d50:	00098593          	mv	a1,s3
    80003d54:	00006517          	auipc	a0,0x6
    80003d58:	79450513          	addi	a0,a0,1940 # 8000a4e8 <states.0+0x118>
    80003d5c:	ffffd097          	auipc	ra,0xffffd
    80003d60:	94c080e7          	jalr	-1716(ra) # 800006a8 <printf>
    panic("kerneltrap");
    80003d64:	00006517          	auipc	a0,0x6
    80003d68:	7ac50513          	addi	a0,a0,1964 # 8000a510 <states.0+0x140>
    80003d6c:	ffffd097          	auipc	ra,0xffffd
    80003d70:	d14080e7          	jalr	-748(ra) # 80000a80 <panic>
  if(which_dev == 2 && myproc() != 0)
    80003d74:	fffff097          	auipc	ra,0xfffff
    80003d78:	974080e7          	jalr	-1676(ra) # 800026e8 <myproc>
    80003d7c:	f80504e3          	beqz	a0,80003d04 <kerneltrap+0x50>
    yield();
    80003d80:	fffff097          	auipc	ra,0xfffff
    80003d84:	2c8080e7          	jalr	712(ra) # 80003048 <yield>
    80003d88:	f7dff06f          	j	80003d04 <kerneltrap+0x50>

0000000080003d8c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003d8c:	fe010113          	addi	sp,sp,-32
    80003d90:	00113c23          	sd	ra,24(sp)
    80003d94:	00813823          	sd	s0,16(sp)
    80003d98:	00913423          	sd	s1,8(sp)
    80003d9c:	02010413          	addi	s0,sp,32
    80003da0:	00050493          	mv	s1,a0
  struct proc *p = myproc();
    80003da4:	fffff097          	auipc	ra,0xfffff
    80003da8:	944080e7          	jalr	-1724(ra) # 800026e8 <myproc>
  switch (n) {
    80003dac:	00500793          	li	a5,5
    80003db0:	0697ec63          	bltu	a5,s1,80003e28 <argraw+0x9c>
    80003db4:	00249493          	slli	s1,s1,0x2
    80003db8:	00006717          	auipc	a4,0x6
    80003dbc:	79070713          	addi	a4,a4,1936 # 8000a548 <states.0+0x178>
    80003dc0:	00e484b3          	add	s1,s1,a4
    80003dc4:	0004a783          	lw	a5,0(s1)
    80003dc8:	00e787b3          	add	a5,a5,a4
    80003dcc:	00078067          	jr	a5
  case 0:
    return p->trapframe->a0;
    80003dd0:	05853783          	ld	a5,88(a0)
    80003dd4:	0707b503          	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003dd8:	01813083          	ld	ra,24(sp)
    80003ddc:	01013403          	ld	s0,16(sp)
    80003de0:	00813483          	ld	s1,8(sp)
    80003de4:	02010113          	addi	sp,sp,32
    80003de8:	00008067          	ret
    return p->trapframe->a1;
    80003dec:	05853783          	ld	a5,88(a0)
    80003df0:	0787b503          	ld	a0,120(a5)
    80003df4:	fe5ff06f          	j	80003dd8 <argraw+0x4c>
    return p->trapframe->a2;
    80003df8:	05853783          	ld	a5,88(a0)
    80003dfc:	0807b503          	ld	a0,128(a5)
    80003e00:	fd9ff06f          	j	80003dd8 <argraw+0x4c>
    return p->trapframe->a3;
    80003e04:	05853783          	ld	a5,88(a0)
    80003e08:	0887b503          	ld	a0,136(a5)
    80003e0c:	fcdff06f          	j	80003dd8 <argraw+0x4c>
    return p->trapframe->a4;
    80003e10:	05853783          	ld	a5,88(a0)
    80003e14:	0907b503          	ld	a0,144(a5)
    80003e18:	fc1ff06f          	j	80003dd8 <argraw+0x4c>
    return p->trapframe->a5;
    80003e1c:	05853783          	ld	a5,88(a0)
    80003e20:	0987b503          	ld	a0,152(a5)
    80003e24:	fb5ff06f          	j	80003dd8 <argraw+0x4c>
  panic("argraw");
    80003e28:	00006517          	auipc	a0,0x6
    80003e2c:	6f850513          	addi	a0,a0,1784 # 8000a520 <states.0+0x150>
    80003e30:	ffffd097          	auipc	ra,0xffffd
    80003e34:	c50080e7          	jalr	-944(ra) # 80000a80 <panic>

0000000080003e38 <fetchaddr>:
{
    80003e38:	fe010113          	addi	sp,sp,-32
    80003e3c:	00113c23          	sd	ra,24(sp)
    80003e40:	00813823          	sd	s0,16(sp)
    80003e44:	00913423          	sd	s1,8(sp)
    80003e48:	01213023          	sd	s2,0(sp)
    80003e4c:	02010413          	addi	s0,sp,32
    80003e50:	00050493          	mv	s1,a0
    80003e54:	00058913          	mv	s2,a1
  struct proc *p = myproc();
    80003e58:	fffff097          	auipc	ra,0xfffff
    80003e5c:	890080e7          	jalr	-1904(ra) # 800026e8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80003e60:	04853783          	ld	a5,72(a0)
    80003e64:	04f4f263          	bgeu	s1,a5,80003ea8 <fetchaddr+0x70>
    80003e68:	00848713          	addi	a4,s1,8
    80003e6c:	04e7e263          	bltu	a5,a4,80003eb0 <fetchaddr+0x78>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003e70:	00800693          	li	a3,8
    80003e74:	00048613          	mv	a2,s1
    80003e78:	00090593          	mv	a1,s2
    80003e7c:	05053503          	ld	a0,80(a0)
    80003e80:	ffffe097          	auipc	ra,0xffffe
    80003e84:	55c080e7          	jalr	1372(ra) # 800023dc <copyin>
    80003e88:	00a03533          	snez	a0,a0
    80003e8c:	40a00533          	neg	a0,a0
}
    80003e90:	01813083          	ld	ra,24(sp)
    80003e94:	01013403          	ld	s0,16(sp)
    80003e98:	00813483          	ld	s1,8(sp)
    80003e9c:	00013903          	ld	s2,0(sp)
    80003ea0:	02010113          	addi	sp,sp,32
    80003ea4:	00008067          	ret
    return -1;
    80003ea8:	fff00513          	li	a0,-1
    80003eac:	fe5ff06f          	j	80003e90 <fetchaddr+0x58>
    80003eb0:	fff00513          	li	a0,-1
    80003eb4:	fddff06f          	j	80003e90 <fetchaddr+0x58>

0000000080003eb8 <fetchstr>:
{
    80003eb8:	fd010113          	addi	sp,sp,-48
    80003ebc:	02113423          	sd	ra,40(sp)
    80003ec0:	02813023          	sd	s0,32(sp)
    80003ec4:	00913c23          	sd	s1,24(sp)
    80003ec8:	01213823          	sd	s2,16(sp)
    80003ecc:	01313423          	sd	s3,8(sp)
    80003ed0:	03010413          	addi	s0,sp,48
    80003ed4:	00050913          	mv	s2,a0
    80003ed8:	00058493          	mv	s1,a1
    80003edc:	00060993          	mv	s3,a2
  struct proc *p = myproc();
    80003ee0:	fffff097          	auipc	ra,0xfffff
    80003ee4:	808080e7          	jalr	-2040(ra) # 800026e8 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003ee8:	00098693          	mv	a3,s3
    80003eec:	00090613          	mv	a2,s2
    80003ef0:	00048593          	mv	a1,s1
    80003ef4:	05053503          	ld	a0,80(a0)
    80003ef8:	ffffe097          	auipc	ra,0xffffe
    80003efc:	144080e7          	jalr	324(ra) # 8000203c <copyinstr>
    80003f00:	02054663          	bltz	a0,80003f2c <fetchstr+0x74>
  return strlen(buf);
    80003f04:	00048513          	mv	a0,s1
    80003f08:	ffffd097          	auipc	ra,0xffffd
    80003f0c:	554080e7          	jalr	1364(ra) # 8000145c <strlen>
}
    80003f10:	02813083          	ld	ra,40(sp)
    80003f14:	02013403          	ld	s0,32(sp)
    80003f18:	01813483          	ld	s1,24(sp)
    80003f1c:	01013903          	ld	s2,16(sp)
    80003f20:	00813983          	ld	s3,8(sp)
    80003f24:	03010113          	addi	sp,sp,48
    80003f28:	00008067          	ret
    return -1;
    80003f2c:	fff00513          	li	a0,-1
    80003f30:	fe1ff06f          	j	80003f10 <fetchstr+0x58>

0000000080003f34 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80003f34:	fe010113          	addi	sp,sp,-32
    80003f38:	00113c23          	sd	ra,24(sp)
    80003f3c:	00813823          	sd	s0,16(sp)
    80003f40:	00913423          	sd	s1,8(sp)
    80003f44:	02010413          	addi	s0,sp,32
    80003f48:	00058493          	mv	s1,a1
  *ip = argraw(n);
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	e40080e7          	jalr	-448(ra) # 80003d8c <argraw>
    80003f54:	00a4a023          	sw	a0,0(s1)
}
    80003f58:	01813083          	ld	ra,24(sp)
    80003f5c:	01013403          	ld	s0,16(sp)
    80003f60:	00813483          	ld	s1,8(sp)
    80003f64:	02010113          	addi	sp,sp,32
    80003f68:	00008067          	ret

0000000080003f6c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80003f6c:	fe010113          	addi	sp,sp,-32
    80003f70:	00113c23          	sd	ra,24(sp)
    80003f74:	00813823          	sd	s0,16(sp)
    80003f78:	00913423          	sd	s1,8(sp)
    80003f7c:	02010413          	addi	s0,sp,32
    80003f80:	00058493          	mv	s1,a1
  *ip = argraw(n);
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	e08080e7          	jalr	-504(ra) # 80003d8c <argraw>
    80003f8c:	00a4b023          	sd	a0,0(s1)
}
    80003f90:	01813083          	ld	ra,24(sp)
    80003f94:	01013403          	ld	s0,16(sp)
    80003f98:	00813483          	ld	s1,8(sp)
    80003f9c:	02010113          	addi	sp,sp,32
    80003fa0:	00008067          	ret

0000000080003fa4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003fa4:	fd010113          	addi	sp,sp,-48
    80003fa8:	02113423          	sd	ra,40(sp)
    80003fac:	02813023          	sd	s0,32(sp)
    80003fb0:	00913c23          	sd	s1,24(sp)
    80003fb4:	01213823          	sd	s2,16(sp)
    80003fb8:	03010413          	addi	s0,sp,48
    80003fbc:	00058493          	mv	s1,a1
    80003fc0:	00060913          	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80003fc4:	fd840593          	addi	a1,s0,-40
    80003fc8:	00000097          	auipc	ra,0x0
    80003fcc:	fa4080e7          	jalr	-92(ra) # 80003f6c <argaddr>
  return fetchstr(addr, buf, max);
    80003fd0:	00090613          	mv	a2,s2
    80003fd4:	00048593          	mv	a1,s1
    80003fd8:	fd843503          	ld	a0,-40(s0)
    80003fdc:	00000097          	auipc	ra,0x0
    80003fe0:	edc080e7          	jalr	-292(ra) # 80003eb8 <fetchstr>
}
    80003fe4:	02813083          	ld	ra,40(sp)
    80003fe8:	02013403          	ld	s0,32(sp)
    80003fec:	01813483          	ld	s1,24(sp)
    80003ff0:	01013903          	ld	s2,16(sp)
    80003ff4:	03010113          	addi	sp,sp,48
    80003ff8:	00008067          	ret

0000000080003ffc <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80003ffc:	fe010113          	addi	sp,sp,-32
    80004000:	00113c23          	sd	ra,24(sp)
    80004004:	00813823          	sd	s0,16(sp)
    80004008:	00913423          	sd	s1,8(sp)
    8000400c:	01213023          	sd	s2,0(sp)
    80004010:	02010413          	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80004014:	ffffe097          	auipc	ra,0xffffe
    80004018:	6d4080e7          	jalr	1748(ra) # 800026e8 <myproc>
    8000401c:	00050493          	mv	s1,a0

  num = p->trapframe->a7;
    80004020:	05853903          	ld	s2,88(a0)
    80004024:	0a893783          	ld	a5,168(s2)
    80004028:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000402c:	fff7879b          	addiw	a5,a5,-1
    80004030:	01400713          	li	a4,20
    80004034:	02f76463          	bltu	a4,a5,8000405c <syscall+0x60>
    80004038:	00369713          	slli	a4,a3,0x3
    8000403c:	00006797          	auipc	a5,0x6
    80004040:	52478793          	addi	a5,a5,1316 # 8000a560 <syscalls>
    80004044:	00e787b3          	add	a5,a5,a4
    80004048:	0007b783          	ld	a5,0(a5)
    8000404c:	00078863          	beqz	a5,8000405c <syscall+0x60>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80004050:	000780e7          	jalr	a5
    80004054:	06a93823          	sd	a0,112(s2)
    80004058:	0280006f          	j	80004080 <syscall+0x84>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000405c:	15848613          	addi	a2,s1,344
    80004060:	0304a583          	lw	a1,48(s1)
    80004064:	00006517          	auipc	a0,0x6
    80004068:	4c450513          	addi	a0,a0,1220 # 8000a528 <states.0+0x158>
    8000406c:	ffffc097          	auipc	ra,0xffffc
    80004070:	63c080e7          	jalr	1596(ra) # 800006a8 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80004074:	0584b783          	ld	a5,88(s1)
    80004078:	fff00713          	li	a4,-1
    8000407c:	06e7b823          	sd	a4,112(a5)
  }
}
    80004080:	01813083          	ld	ra,24(sp)
    80004084:	01013403          	ld	s0,16(sp)
    80004088:	00813483          	ld	s1,8(sp)
    8000408c:	00013903          	ld	s2,0(sp)
    80004090:	02010113          	addi	sp,sp,32
    80004094:	00008067          	ret

0000000080004098 <sys_exit>:
#include "proc.h"
#include "vm.h"

uint64
sys_exit(void)
{
    80004098:	fe010113          	addi	sp,sp,-32
    8000409c:	00113c23          	sd	ra,24(sp)
    800040a0:	00813823          	sd	s0,16(sp)
    800040a4:	02010413          	addi	s0,sp,32
  int n;
  argint(0, &n);
    800040a8:	fec40593          	addi	a1,s0,-20
    800040ac:	00000513          	li	a0,0
    800040b0:	00000097          	auipc	ra,0x0
    800040b4:	e84080e7          	jalr	-380(ra) # 80003f34 <argint>
  kexit(n);
    800040b8:	fec42503          	lw	a0,-20(s0)
    800040bc:	fffff097          	auipc	ra,0xfffff
    800040c0:	1a4080e7          	jalr	420(ra) # 80003260 <kexit>
  return 0;  // not reached
}
    800040c4:	00000513          	li	a0,0
    800040c8:	01813083          	ld	ra,24(sp)
    800040cc:	01013403          	ld	s0,16(sp)
    800040d0:	02010113          	addi	sp,sp,32
    800040d4:	00008067          	ret

00000000800040d8 <sys_getpid>:

uint64
sys_getpid(void)
{
    800040d8:	ff010113          	addi	sp,sp,-16
    800040dc:	00113423          	sd	ra,8(sp)
    800040e0:	00813023          	sd	s0,0(sp)
    800040e4:	01010413          	addi	s0,sp,16
  return myproc()->pid;
    800040e8:	ffffe097          	auipc	ra,0xffffe
    800040ec:	600080e7          	jalr	1536(ra) # 800026e8 <myproc>
}
    800040f0:	03052503          	lw	a0,48(a0)
    800040f4:	00813083          	ld	ra,8(sp)
    800040f8:	00013403          	ld	s0,0(sp)
    800040fc:	01010113          	addi	sp,sp,16
    80004100:	00008067          	ret

0000000080004104 <sys_fork>:

uint64
sys_fork(void)
{
    80004104:	ff010113          	addi	sp,sp,-16
    80004108:	00113423          	sd	ra,8(sp)
    8000410c:	00813023          	sd	s0,0(sp)
    80004110:	01010413          	addi	s0,sp,16
  return kfork();
    80004114:	fffff097          	auipc	ra,0xfffff
    80004118:	b78080e7          	jalr	-1160(ra) # 80002c8c <kfork>
}
    8000411c:	00813083          	ld	ra,8(sp)
    80004120:	00013403          	ld	s0,0(sp)
    80004124:	01010113          	addi	sp,sp,16
    80004128:	00008067          	ret

000000008000412c <sys_wait>:

uint64
sys_wait(void)
{
    8000412c:	fe010113          	addi	sp,sp,-32
    80004130:	00113c23          	sd	ra,24(sp)
    80004134:	00813823          	sd	s0,16(sp)
    80004138:	02010413          	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000413c:	fe840593          	addi	a1,s0,-24
    80004140:	00000513          	li	a0,0
    80004144:	00000097          	auipc	ra,0x0
    80004148:	e28080e7          	jalr	-472(ra) # 80003f6c <argaddr>
  return kwait(p);
    8000414c:	fe843503          	ld	a0,-24(s0)
    80004150:	fffff097          	auipc	ra,0xfffff
    80004154:	350080e7          	jalr	848(ra) # 800034a0 <kwait>
}
    80004158:	01813083          	ld	ra,24(sp)
    8000415c:	01013403          	ld	s0,16(sp)
    80004160:	02010113          	addi	sp,sp,32
    80004164:	00008067          	ret

0000000080004168 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80004168:	fd010113          	addi	sp,sp,-48
    8000416c:	02113423          	sd	ra,40(sp)
    80004170:	02813023          	sd	s0,32(sp)
    80004174:	00913c23          	sd	s1,24(sp)
    80004178:	03010413          	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
    8000417c:	fd840593          	addi	a1,s0,-40
    80004180:	00000513          	li	a0,0
    80004184:	00000097          	auipc	ra,0x0
    80004188:	db0080e7          	jalr	-592(ra) # 80003f34 <argint>
  argint(1, &t);
    8000418c:	fdc40593          	addi	a1,s0,-36
    80004190:	00100513          	li	a0,1
    80004194:	00000097          	auipc	ra,0x0
    80004198:	da0080e7          	jalr	-608(ra) # 80003f34 <argint>
  addr = myproc()->sz;
    8000419c:	ffffe097          	auipc	ra,0xffffe
    800041a0:	54c080e7          	jalr	1356(ra) # 800026e8 <myproc>
    800041a4:	04853483          	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {
    800041a8:	fdc42703          	lw	a4,-36(s0)
    800041ac:	00100793          	li	a5,1
    800041b0:	02f70863          	beq	a4,a5,800041e0 <sys_sbrk+0x78>
    800041b4:	fd842783          	lw	a5,-40(s0)
    800041b8:	0207c463          	bltz	a5,800041e0 <sys_sbrk+0x78>
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
    800041bc:	009787b3          	add	a5,a5,s1
    800041c0:	0497e863          	bltu	a5,s1,80004210 <sys_sbrk+0xa8>
      return -1;
    myproc()->sz += n;
    800041c4:	ffffe097          	auipc	ra,0xffffe
    800041c8:	524080e7          	jalr	1316(ra) # 800026e8 <myproc>
    800041cc:	fd842703          	lw	a4,-40(s0)
    800041d0:	04853783          	ld	a5,72(a0)
    800041d4:	00e787b3          	add	a5,a5,a4
    800041d8:	04f53423          	sd	a5,72(a0)
    800041dc:	0140006f          	j	800041f0 <sys_sbrk+0x88>
    if(growproc(n) < 0) {
    800041e0:	fd842503          	lw	a0,-40(s0)
    800041e4:	fffff097          	auipc	ra,0xfffff
    800041e8:	a18080e7          	jalr	-1512(ra) # 80002bfc <growproc>
    800041ec:	00054e63          	bltz	a0,80004208 <sys_sbrk+0xa0>
  }
  return addr;
}
    800041f0:	00048513          	mv	a0,s1
    800041f4:	02813083          	ld	ra,40(sp)
    800041f8:	02013403          	ld	s0,32(sp)
    800041fc:	01813483          	ld	s1,24(sp)
    80004200:	03010113          	addi	sp,sp,48
    80004204:	00008067          	ret
      return -1;
    80004208:	fff00493          	li	s1,-1
    8000420c:	fe5ff06f          	j	800041f0 <sys_sbrk+0x88>
      return -1;
    80004210:	fff00493          	li	s1,-1
    80004214:	fddff06f          	j	800041f0 <sys_sbrk+0x88>

0000000080004218 <sys_pause>:

uint64
sys_pause(void)
{
    80004218:	fc010113          	addi	sp,sp,-64
    8000421c:	02113c23          	sd	ra,56(sp)
    80004220:	02813823          	sd	s0,48(sp)
    80004224:	02913423          	sd	s1,40(sp)
    80004228:	03213023          	sd	s2,32(sp)
    8000422c:	01313c23          	sd	s3,24(sp)
    80004230:	04010413          	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80004234:	fcc40593          	addi	a1,s0,-52
    80004238:	00000513          	li	a0,0
    8000423c:	00000097          	auipc	ra,0x0
    80004240:	cf8080e7          	jalr	-776(ra) # 80003f34 <argint>
  if(n < 0)
    80004244:	fcc42783          	lw	a5,-52(s0)
    80004248:	0807cc63          	bltz	a5,800042e0 <sys_pause+0xc8>
    n = 0;
  acquire(&tickslock);
    8000424c:	00014517          	auipc	a0,0x14
    80004250:	6ac50513          	addi	a0,a0,1708 # 800188f8 <tickslock>
    80004254:	ffffd097          	auipc	ra,0xffffd
    80004258:	e64080e7          	jalr	-412(ra) # 800010b8 <acquire>
  ticks0 = ticks;
    8000425c:	00006917          	auipc	s2,0x6
    80004260:	76c92903          	lw	s2,1900(s2) # 8000a9c8 <ticks>
  while(ticks - ticks0 < n){
    80004264:	fcc42783          	lw	a5,-52(s0)
    80004268:	04078463          	beqz	a5,800042b0 <sys_pause+0x98>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000426c:	00014997          	auipc	s3,0x14
    80004270:	68c98993          	addi	s3,s3,1676 # 800188f8 <tickslock>
    80004274:	00006497          	auipc	s1,0x6
    80004278:	75448493          	addi	s1,s1,1876 # 8000a9c8 <ticks>
    if(killed(myproc())){
    8000427c:	ffffe097          	auipc	ra,0xffffe
    80004280:	46c080e7          	jalr	1132(ra) # 800026e8 <myproc>
    80004284:	fffff097          	auipc	ra,0xfffff
    80004288:	1cc080e7          	jalr	460(ra) # 80003450 <killed>
    8000428c:	04051e63          	bnez	a0,800042e8 <sys_pause+0xd0>
    sleep(&ticks, &tickslock);
    80004290:	00098593          	mv	a1,s3
    80004294:	00048513          	mv	a0,s1
    80004298:	fffff097          	auipc	ra,0xfffff
    8000429c:	e08080e7          	jalr	-504(ra) # 800030a0 <sleep>
  while(ticks - ticks0 < n){
    800042a0:	0004a783          	lw	a5,0(s1)
    800042a4:	412787bb          	subw	a5,a5,s2
    800042a8:	fcc42703          	lw	a4,-52(s0)
    800042ac:	fce7e8e3          	bltu	a5,a4,8000427c <sys_pause+0x64>
  }
  release(&tickslock);
    800042b0:	00014517          	auipc	a0,0x14
    800042b4:	64850513          	addi	a0,a0,1608 # 800188f8 <tickslock>
    800042b8:	ffffd097          	auipc	ra,0xffffd
    800042bc:	ef8080e7          	jalr	-264(ra) # 800011b0 <release>
  return 0;
    800042c0:	00000513          	li	a0,0
}
    800042c4:	03813083          	ld	ra,56(sp)
    800042c8:	03013403          	ld	s0,48(sp)
    800042cc:	02813483          	ld	s1,40(sp)
    800042d0:	02013903          	ld	s2,32(sp)
    800042d4:	01813983          	ld	s3,24(sp)
    800042d8:	04010113          	addi	sp,sp,64
    800042dc:	00008067          	ret
    n = 0;
    800042e0:	fc042623          	sw	zero,-52(s0)
    800042e4:	f69ff06f          	j	8000424c <sys_pause+0x34>
      release(&tickslock);
    800042e8:	00014517          	auipc	a0,0x14
    800042ec:	61050513          	addi	a0,a0,1552 # 800188f8 <tickslock>
    800042f0:	ffffd097          	auipc	ra,0xffffd
    800042f4:	ec0080e7          	jalr	-320(ra) # 800011b0 <release>
      return -1;
    800042f8:	fff00513          	li	a0,-1
    800042fc:	fc9ff06f          	j	800042c4 <sys_pause+0xac>

0000000080004300 <sys_kill>:

uint64
sys_kill(void)
{
    80004300:	fe010113          	addi	sp,sp,-32
    80004304:	00113c23          	sd	ra,24(sp)
    80004308:	00813823          	sd	s0,16(sp)
    8000430c:	02010413          	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80004310:	fec40593          	addi	a1,s0,-20
    80004314:	00000513          	li	a0,0
    80004318:	00000097          	auipc	ra,0x0
    8000431c:	c1c080e7          	jalr	-996(ra) # 80003f34 <argint>
  return kkill(pid);
    80004320:	fec42503          	lw	a0,-20(s0)
    80004324:	fffff097          	auipc	ra,0xfffff
    80004328:	038080e7          	jalr	56(ra) # 8000335c <kkill>
}
    8000432c:	01813083          	ld	ra,24(sp)
    80004330:	01013403          	ld	s0,16(sp)
    80004334:	02010113          	addi	sp,sp,32
    80004338:	00008067          	ret

000000008000433c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000433c:	fe010113          	addi	sp,sp,-32
    80004340:	00113c23          	sd	ra,24(sp)
    80004344:	00813823          	sd	s0,16(sp)
    80004348:	00913423          	sd	s1,8(sp)
    8000434c:	02010413          	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80004350:	00014517          	auipc	a0,0x14
    80004354:	5a850513          	addi	a0,a0,1448 # 800188f8 <tickslock>
    80004358:	ffffd097          	auipc	ra,0xffffd
    8000435c:	d60080e7          	jalr	-672(ra) # 800010b8 <acquire>
  xticks = ticks;
    80004360:	00006497          	auipc	s1,0x6
    80004364:	6684a483          	lw	s1,1640(s1) # 8000a9c8 <ticks>
  release(&tickslock);
    80004368:	00014517          	auipc	a0,0x14
    8000436c:	59050513          	addi	a0,a0,1424 # 800188f8 <tickslock>
    80004370:	ffffd097          	auipc	ra,0xffffd
    80004374:	e40080e7          	jalr	-448(ra) # 800011b0 <release>
  return xticks;
}
    80004378:	02049513          	slli	a0,s1,0x20
    8000437c:	02055513          	srli	a0,a0,0x20
    80004380:	01813083          	ld	ra,24(sp)
    80004384:	01013403          	ld	s0,16(sp)
    80004388:	00813483          	ld	s1,8(sp)
    8000438c:	02010113          	addi	sp,sp,32
    80004390:	00008067          	ret

0000000080004394 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80004394:	fd010113          	addi	sp,sp,-48
    80004398:	02113423          	sd	ra,40(sp)
    8000439c:	02813023          	sd	s0,32(sp)
    800043a0:	00913c23          	sd	s1,24(sp)
    800043a4:	01213823          	sd	s2,16(sp)
    800043a8:	01313423          	sd	s3,8(sp)
    800043ac:	01413023          	sd	s4,0(sp)
    800043b0:	03010413          	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800043b4:	00006597          	auipc	a1,0x6
    800043b8:	25c58593          	addi	a1,a1,604 # 8000a610 <syscalls+0xb0>
    800043bc:	00014517          	auipc	a0,0x14
    800043c0:	55450513          	addi	a0,a0,1364 # 80018910 <bcache>
    800043c4:	ffffd097          	auipc	ra,0xffffd
    800043c8:	c10080e7          	jalr	-1008(ra) # 80000fd4 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800043cc:	0001c797          	auipc	a5,0x1c
    800043d0:	54478793          	addi	a5,a5,1348 # 80020910 <bcache+0x8000>
    800043d4:	0001c717          	auipc	a4,0x1c
    800043d8:	7a470713          	addi	a4,a4,1956 # 80020b78 <bcache+0x8268>
    800043dc:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800043e0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800043e4:	00014497          	auipc	s1,0x14
    800043e8:	54448493          	addi	s1,s1,1348 # 80018928 <bcache+0x18>
    b->next = bcache.head.next;
    800043ec:	00078913          	mv	s2,a5
    b->prev = &bcache.head;
    800043f0:	00070993          	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800043f4:	00006a17          	auipc	s4,0x6
    800043f8:	224a0a13          	addi	s4,s4,548 # 8000a618 <syscalls+0xb8>
    b->next = bcache.head.next;
    800043fc:	2b893783          	ld	a5,696(s2)
    80004400:	04f4b823          	sd	a5,80(s1)
    b->prev = &bcache.head;
    80004404:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80004408:	000a0593          	mv	a1,s4
    8000440c:	01048513          	addi	a0,s1,16
    80004410:	00002097          	auipc	ra,0x2
    80004414:	e08080e7          	jalr	-504(ra) # 80006218 <initsleeplock>
    bcache.head.next->prev = b;
    80004418:	2b893783          	ld	a5,696(s2)
    8000441c:	0497b423          	sd	s1,72(a5)
    bcache.head.next = b;
    80004420:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80004424:	45848493          	addi	s1,s1,1112
    80004428:	fd349ae3          	bne	s1,s3,800043fc <binit+0x68>
  }
}
    8000442c:	02813083          	ld	ra,40(sp)
    80004430:	02013403          	ld	s0,32(sp)
    80004434:	01813483          	ld	s1,24(sp)
    80004438:	01013903          	ld	s2,16(sp)
    8000443c:	00813983          	ld	s3,8(sp)
    80004440:	00013a03          	ld	s4,0(sp)
    80004444:	03010113          	addi	sp,sp,48
    80004448:	00008067          	ret

000000008000444c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000444c:	fd010113          	addi	sp,sp,-48
    80004450:	02113423          	sd	ra,40(sp)
    80004454:	02813023          	sd	s0,32(sp)
    80004458:	00913c23          	sd	s1,24(sp)
    8000445c:	01213823          	sd	s2,16(sp)
    80004460:	01313423          	sd	s3,8(sp)
    80004464:	03010413          	addi	s0,sp,48
    80004468:	00050913          	mv	s2,a0
    8000446c:	00058993          	mv	s3,a1
  acquire(&bcache.lock);
    80004470:	00014517          	auipc	a0,0x14
    80004474:	4a050513          	addi	a0,a0,1184 # 80018910 <bcache>
    80004478:	ffffd097          	auipc	ra,0xffffd
    8000447c:	c40080e7          	jalr	-960(ra) # 800010b8 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80004480:	0001c497          	auipc	s1,0x1c
    80004484:	7484b483          	ld	s1,1864(s1) # 80020bc8 <bcache+0x82b8>
    80004488:	0001c797          	auipc	a5,0x1c
    8000448c:	6f078793          	addi	a5,a5,1776 # 80020b78 <bcache+0x8268>
    80004490:	04f48863          	beq	s1,a5,800044e0 <bread+0x94>
    80004494:	00078713          	mv	a4,a5
    80004498:	00c0006f          	j	800044a4 <bread+0x58>
    8000449c:	0504b483          	ld	s1,80(s1)
    800044a0:	04e48063          	beq	s1,a4,800044e0 <bread+0x94>
    if(b->dev == dev && b->blockno == blockno){
    800044a4:	0084a783          	lw	a5,8(s1)
    800044a8:	ff279ae3          	bne	a5,s2,8000449c <bread+0x50>
    800044ac:	00c4a783          	lw	a5,12(s1)
    800044b0:	ff3796e3          	bne	a5,s3,8000449c <bread+0x50>
      b->refcnt++;
    800044b4:	0404a783          	lw	a5,64(s1)
    800044b8:	0017879b          	addiw	a5,a5,1
    800044bc:	04f4a023          	sw	a5,64(s1)
      release(&bcache.lock);
    800044c0:	00014517          	auipc	a0,0x14
    800044c4:	45050513          	addi	a0,a0,1104 # 80018910 <bcache>
    800044c8:	ffffd097          	auipc	ra,0xffffd
    800044cc:	ce8080e7          	jalr	-792(ra) # 800011b0 <release>
      acquiresleep(&b->lock);
    800044d0:	01048513          	addi	a0,s1,16
    800044d4:	00002097          	auipc	ra,0x2
    800044d8:	d9c080e7          	jalr	-612(ra) # 80006270 <acquiresleep>
      return b;
    800044dc:	06c0006f          	j	80004548 <bread+0xfc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800044e0:	0001c497          	auipc	s1,0x1c
    800044e4:	6e04b483          	ld	s1,1760(s1) # 80020bc0 <bcache+0x82b0>
    800044e8:	0001c797          	auipc	a5,0x1c
    800044ec:	69078793          	addi	a5,a5,1680 # 80020b78 <bcache+0x8268>
    800044f0:	00f48c63          	beq	s1,a5,80004508 <bread+0xbc>
    800044f4:	00078713          	mv	a4,a5
    if(b->refcnt == 0) {
    800044f8:	0404a783          	lw	a5,64(s1)
    800044fc:	00078e63          	beqz	a5,80004518 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80004500:	0484b483          	ld	s1,72(s1)
    80004504:	fee49ae3          	bne	s1,a4,800044f8 <bread+0xac>
  panic("bget: no buffers");
    80004508:	00006517          	auipc	a0,0x6
    8000450c:	11850513          	addi	a0,a0,280 # 8000a620 <syscalls+0xc0>
    80004510:	ffffc097          	auipc	ra,0xffffc
    80004514:	570080e7          	jalr	1392(ra) # 80000a80 <panic>
      b->dev = dev;
    80004518:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000451c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80004520:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80004524:	00100793          	li	a5,1
    80004528:	04f4a023          	sw	a5,64(s1)
      release(&bcache.lock);
    8000452c:	00014517          	auipc	a0,0x14
    80004530:	3e450513          	addi	a0,a0,996 # 80018910 <bcache>
    80004534:	ffffd097          	auipc	ra,0xffffd
    80004538:	c7c080e7          	jalr	-900(ra) # 800011b0 <release>
      acquiresleep(&b->lock);
    8000453c:	01048513          	addi	a0,s1,16
    80004540:	00002097          	auipc	ra,0x2
    80004544:	d30080e7          	jalr	-720(ra) # 80006270 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80004548:	0004a783          	lw	a5,0(s1)
    8000454c:	02078263          	beqz	a5,80004570 <bread+0x124>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80004550:	00048513          	mv	a0,s1
    80004554:	02813083          	ld	ra,40(sp)
    80004558:	02013403          	ld	s0,32(sp)
    8000455c:	01813483          	ld	s1,24(sp)
    80004560:	01013903          	ld	s2,16(sp)
    80004564:	00813983          	ld	s3,8(sp)
    80004568:	03010113          	addi	sp,sp,48
    8000456c:	00008067          	ret
    virtio_disk_rw(b, 0);
    80004570:	00000593          	li	a1,0
    80004574:	00048513          	mv	a0,s1
    80004578:	00004097          	auipc	ra,0x4
    8000457c:	1e4080e7          	jalr	484(ra) # 8000875c <virtio_disk_rw>
    b->valid = 1;
    80004580:	00100793          	li	a5,1
    80004584:	00f4a023          	sw	a5,0(s1)
  return b;
    80004588:	fc9ff06f          	j	80004550 <bread+0x104>

000000008000458c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000458c:	fe010113          	addi	sp,sp,-32
    80004590:	00113c23          	sd	ra,24(sp)
    80004594:	00813823          	sd	s0,16(sp)
    80004598:	00913423          	sd	s1,8(sp)
    8000459c:	02010413          	addi	s0,sp,32
    800045a0:	00050493          	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800045a4:	01050513          	addi	a0,a0,16
    800045a8:	00002097          	auipc	ra,0x2
    800045ac:	db4080e7          	jalr	-588(ra) # 8000635c <holdingsleep>
    800045b0:	02050463          	beqz	a0,800045d8 <bwrite+0x4c>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800045b4:	00100593          	li	a1,1
    800045b8:	00048513          	mv	a0,s1
    800045bc:	00004097          	auipc	ra,0x4
    800045c0:	1a0080e7          	jalr	416(ra) # 8000875c <virtio_disk_rw>
}
    800045c4:	01813083          	ld	ra,24(sp)
    800045c8:	01013403          	ld	s0,16(sp)
    800045cc:	00813483          	ld	s1,8(sp)
    800045d0:	02010113          	addi	sp,sp,32
    800045d4:	00008067          	ret
    panic("bwrite");
    800045d8:	00006517          	auipc	a0,0x6
    800045dc:	06050513          	addi	a0,a0,96 # 8000a638 <syscalls+0xd8>
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	4a0080e7          	jalr	1184(ra) # 80000a80 <panic>

00000000800045e8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800045e8:	fe010113          	addi	sp,sp,-32
    800045ec:	00113c23          	sd	ra,24(sp)
    800045f0:	00813823          	sd	s0,16(sp)
    800045f4:	00913423          	sd	s1,8(sp)
    800045f8:	01213023          	sd	s2,0(sp)
    800045fc:	02010413          	addi	s0,sp,32
    80004600:	00050493          	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80004604:	01050913          	addi	s2,a0,16
    80004608:	00090513          	mv	a0,s2
    8000460c:	00002097          	auipc	ra,0x2
    80004610:	d50080e7          	jalr	-688(ra) # 8000635c <holdingsleep>
    80004614:	08050e63          	beqz	a0,800046b0 <brelse+0xc8>
    panic("brelse");

  releasesleep(&b->lock);
    80004618:	00090513          	mv	a0,s2
    8000461c:	00002097          	auipc	ra,0x2
    80004620:	cdc080e7          	jalr	-804(ra) # 800062f8 <releasesleep>

  acquire(&bcache.lock);
    80004624:	00014517          	auipc	a0,0x14
    80004628:	2ec50513          	addi	a0,a0,748 # 80018910 <bcache>
    8000462c:	ffffd097          	auipc	ra,0xffffd
    80004630:	a8c080e7          	jalr	-1396(ra) # 800010b8 <acquire>
  b->refcnt--;
    80004634:	0404a783          	lw	a5,64(s1)
    80004638:	fff7879b          	addiw	a5,a5,-1
    8000463c:	0007871b          	sext.w	a4,a5
    80004640:	04f4a023          	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80004644:	04071263          	bnez	a4,80004688 <brelse+0xa0>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80004648:	0504b783          	ld	a5,80(s1)
    8000464c:	0484b703          	ld	a4,72(s1)
    80004650:	04e7b423          	sd	a4,72(a5)
    b->prev->next = b->next;
    80004654:	0484b783          	ld	a5,72(s1)
    80004658:	0504b703          	ld	a4,80(s1)
    8000465c:	04e7b823          	sd	a4,80(a5)
    b->next = bcache.head.next;
    80004660:	0001c797          	auipc	a5,0x1c
    80004664:	2b078793          	addi	a5,a5,688 # 80020910 <bcache+0x8000>
    80004668:	2b87b703          	ld	a4,696(a5)
    8000466c:	04e4b823          	sd	a4,80(s1)
    b->prev = &bcache.head;
    80004670:	0001c717          	auipc	a4,0x1c
    80004674:	50870713          	addi	a4,a4,1288 # 80020b78 <bcache+0x8268>
    80004678:	04e4b423          	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000467c:	2b87b703          	ld	a4,696(a5)
    80004680:	04973423          	sd	s1,72(a4)
    bcache.head.next = b;
    80004684:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80004688:	00014517          	auipc	a0,0x14
    8000468c:	28850513          	addi	a0,a0,648 # 80018910 <bcache>
    80004690:	ffffd097          	auipc	ra,0xffffd
    80004694:	b20080e7          	jalr	-1248(ra) # 800011b0 <release>
}
    80004698:	01813083          	ld	ra,24(sp)
    8000469c:	01013403          	ld	s0,16(sp)
    800046a0:	00813483          	ld	s1,8(sp)
    800046a4:	00013903          	ld	s2,0(sp)
    800046a8:	02010113          	addi	sp,sp,32
    800046ac:	00008067          	ret
    panic("brelse");
    800046b0:	00006517          	auipc	a0,0x6
    800046b4:	f9050513          	addi	a0,a0,-112 # 8000a640 <syscalls+0xe0>
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	3c8080e7          	jalr	968(ra) # 80000a80 <panic>

00000000800046c0 <bpin>:

void
bpin(struct buf *b) {
    800046c0:	fe010113          	addi	sp,sp,-32
    800046c4:	00113c23          	sd	ra,24(sp)
    800046c8:	00813823          	sd	s0,16(sp)
    800046cc:	00913423          	sd	s1,8(sp)
    800046d0:	02010413          	addi	s0,sp,32
    800046d4:	00050493          	mv	s1,a0
  acquire(&bcache.lock);
    800046d8:	00014517          	auipc	a0,0x14
    800046dc:	23850513          	addi	a0,a0,568 # 80018910 <bcache>
    800046e0:	ffffd097          	auipc	ra,0xffffd
    800046e4:	9d8080e7          	jalr	-1576(ra) # 800010b8 <acquire>
  b->refcnt++;
    800046e8:	0404a783          	lw	a5,64(s1)
    800046ec:	0017879b          	addiw	a5,a5,1
    800046f0:	04f4a023          	sw	a5,64(s1)
  release(&bcache.lock);
    800046f4:	00014517          	auipc	a0,0x14
    800046f8:	21c50513          	addi	a0,a0,540 # 80018910 <bcache>
    800046fc:	ffffd097          	auipc	ra,0xffffd
    80004700:	ab4080e7          	jalr	-1356(ra) # 800011b0 <release>
}
    80004704:	01813083          	ld	ra,24(sp)
    80004708:	01013403          	ld	s0,16(sp)
    8000470c:	00813483          	ld	s1,8(sp)
    80004710:	02010113          	addi	sp,sp,32
    80004714:	00008067          	ret

0000000080004718 <bunpin>:

void
bunpin(struct buf *b) {
    80004718:	fe010113          	addi	sp,sp,-32
    8000471c:	00113c23          	sd	ra,24(sp)
    80004720:	00813823          	sd	s0,16(sp)
    80004724:	00913423          	sd	s1,8(sp)
    80004728:	02010413          	addi	s0,sp,32
    8000472c:	00050493          	mv	s1,a0
  acquire(&bcache.lock);
    80004730:	00014517          	auipc	a0,0x14
    80004734:	1e050513          	addi	a0,a0,480 # 80018910 <bcache>
    80004738:	ffffd097          	auipc	ra,0xffffd
    8000473c:	980080e7          	jalr	-1664(ra) # 800010b8 <acquire>
  b->refcnt--;
    80004740:	0404a783          	lw	a5,64(s1)
    80004744:	fff7879b          	addiw	a5,a5,-1
    80004748:	04f4a023          	sw	a5,64(s1)
  release(&bcache.lock);
    8000474c:	00014517          	auipc	a0,0x14
    80004750:	1c450513          	addi	a0,a0,452 # 80018910 <bcache>
    80004754:	ffffd097          	auipc	ra,0xffffd
    80004758:	a5c080e7          	jalr	-1444(ra) # 800011b0 <release>
}
    8000475c:	01813083          	ld	ra,24(sp)
    80004760:	01013403          	ld	s0,16(sp)
    80004764:	00813483          	ld	s1,8(sp)
    80004768:	02010113          	addi	sp,sp,32
    8000476c:	00008067          	ret

0000000080004770 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80004770:	fe010113          	addi	sp,sp,-32
    80004774:	00113c23          	sd	ra,24(sp)
    80004778:	00813823          	sd	s0,16(sp)
    8000477c:	00913423          	sd	s1,8(sp)
    80004780:	01213023          	sd	s2,0(sp)
    80004784:	02010413          	addi	s0,sp,32
    80004788:	00058493          	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000478c:	00d5d59b          	srliw	a1,a1,0xd
    80004790:	0001d797          	auipc	a5,0x1d
    80004794:	85c7a783          	lw	a5,-1956(a5) # 80020fec <sb+0x1c>
    80004798:	00f585bb          	addw	a1,a1,a5
    8000479c:	00000097          	auipc	ra,0x0
    800047a0:	cb0080e7          	jalr	-848(ra) # 8000444c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800047a4:	0074f713          	andi	a4,s1,7
    800047a8:	00100793          	li	a5,1
    800047ac:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800047b0:	03349493          	slli	s1,s1,0x33
    800047b4:	0364d493          	srli	s1,s1,0x36
    800047b8:	00950733          	add	a4,a0,s1
    800047bc:	05874703          	lbu	a4,88(a4)
    800047c0:	00e7f6b3          	and	a3,a5,a4
    800047c4:	04068263          	beqz	a3,80004808 <bfree+0x98>
    800047c8:	00050913          	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800047cc:	009504b3          	add	s1,a0,s1
    800047d0:	fff7c793          	not	a5,a5
    800047d4:	00f77733          	and	a4,a4,a5
    800047d8:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800047dc:	00002097          	auipc	ra,0x2
    800047e0:	920080e7          	jalr	-1760(ra) # 800060fc <log_write>
  brelse(bp);
    800047e4:	00090513          	mv	a0,s2
    800047e8:	00000097          	auipc	ra,0x0
    800047ec:	e00080e7          	jalr	-512(ra) # 800045e8 <brelse>
}
    800047f0:	01813083          	ld	ra,24(sp)
    800047f4:	01013403          	ld	s0,16(sp)
    800047f8:	00813483          	ld	s1,8(sp)
    800047fc:	00013903          	ld	s2,0(sp)
    80004800:	02010113          	addi	sp,sp,32
    80004804:	00008067          	ret
    panic("freeing free block");
    80004808:	00006517          	auipc	a0,0x6
    8000480c:	e4050513          	addi	a0,a0,-448 # 8000a648 <syscalls+0xe8>
    80004810:	ffffc097          	auipc	ra,0xffffc
    80004814:	270080e7          	jalr	624(ra) # 80000a80 <panic>

0000000080004818 <balloc>:
{
    80004818:	fa010113          	addi	sp,sp,-96
    8000481c:	04113c23          	sd	ra,88(sp)
    80004820:	04813823          	sd	s0,80(sp)
    80004824:	04913423          	sd	s1,72(sp)
    80004828:	05213023          	sd	s2,64(sp)
    8000482c:	03313c23          	sd	s3,56(sp)
    80004830:	03413823          	sd	s4,48(sp)
    80004834:	03513423          	sd	s5,40(sp)
    80004838:	03613023          	sd	s6,32(sp)
    8000483c:	01713c23          	sd	s7,24(sp)
    80004840:	01813823          	sd	s8,16(sp)
    80004844:	01913423          	sd	s9,8(sp)
    80004848:	06010413          	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000484c:	0001c797          	auipc	a5,0x1c
    80004850:	7887a783          	lw	a5,1928(a5) # 80020fd4 <sb+0x4>
    80004854:	14078863          	beqz	a5,800049a4 <balloc+0x18c>
    80004858:	00050b93          	mv	s7,a0
    8000485c:	00000a93          	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80004860:	0001cb17          	auipc	s6,0x1c
    80004864:	770b0b13          	addi	s6,s6,1904 # 80020fd0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004868:	00000c13          	li	s8,0
      m = 1 << (bi % 8);
    8000486c:	00100993          	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004870:	00002a37          	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80004874:	00002cb7          	lui	s9,0x2
    80004878:	0bc0006f          	j	80004934 <balloc+0x11c>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000487c:	00f907b3          	add	a5,s2,a5
    80004880:	00d66633          	or	a2,a2,a3
    80004884:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80004888:	00090513          	mv	a0,s2
    8000488c:	00002097          	auipc	ra,0x2
    80004890:	870080e7          	jalr	-1936(ra) # 800060fc <log_write>
        brelse(bp);
    80004894:	00090513          	mv	a0,s2
    80004898:	00000097          	auipc	ra,0x0
    8000489c:	d50080e7          	jalr	-688(ra) # 800045e8 <brelse>
  bp = bread(dev, bno);
    800048a0:	00048593          	mv	a1,s1
    800048a4:	000b8513          	mv	a0,s7
    800048a8:	00000097          	auipc	ra,0x0
    800048ac:	ba4080e7          	jalr	-1116(ra) # 8000444c <bread>
    800048b0:	00050913          	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800048b4:	40000613          	li	a2,1024
    800048b8:	00000593          	li	a1,0
    800048bc:	05850513          	addi	a0,a0,88
    800048c0:	ffffd097          	auipc	ra,0xffffd
    800048c4:	950080e7          	jalr	-1712(ra) # 80001210 <memset>
  log_write(bp);
    800048c8:	00090513          	mv	a0,s2
    800048cc:	00002097          	auipc	ra,0x2
    800048d0:	830080e7          	jalr	-2000(ra) # 800060fc <log_write>
  brelse(bp);
    800048d4:	00090513          	mv	a0,s2
    800048d8:	00000097          	auipc	ra,0x0
    800048dc:	d10080e7          	jalr	-752(ra) # 800045e8 <brelse>
}
    800048e0:	00048513          	mv	a0,s1
    800048e4:	05813083          	ld	ra,88(sp)
    800048e8:	05013403          	ld	s0,80(sp)
    800048ec:	04813483          	ld	s1,72(sp)
    800048f0:	04013903          	ld	s2,64(sp)
    800048f4:	03813983          	ld	s3,56(sp)
    800048f8:	03013a03          	ld	s4,48(sp)
    800048fc:	02813a83          	ld	s5,40(sp)
    80004900:	02013b03          	ld	s6,32(sp)
    80004904:	01813b83          	ld	s7,24(sp)
    80004908:	01013c03          	ld	s8,16(sp)
    8000490c:	00813c83          	ld	s9,8(sp)
    80004910:	06010113          	addi	sp,sp,96
    80004914:	00008067          	ret
    brelse(bp);
    80004918:	00090513          	mv	a0,s2
    8000491c:	00000097          	auipc	ra,0x0
    80004920:	ccc080e7          	jalr	-820(ra) # 800045e8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80004924:	015c87bb          	addw	a5,s9,s5
    80004928:	00078a9b          	sext.w	s5,a5
    8000492c:	004b2703          	lw	a4,4(s6)
    80004930:	06eafa63          	bgeu	s5,a4,800049a4 <balloc+0x18c>
    bp = bread(dev, BBLOCK(b, sb));
    80004934:	41fad79b          	sraiw	a5,s5,0x1f
    80004938:	0137d79b          	srliw	a5,a5,0x13
    8000493c:	015787bb          	addw	a5,a5,s5
    80004940:	40d7d79b          	sraiw	a5,a5,0xd
    80004944:	01cb2583          	lw	a1,28(s6)
    80004948:	00b785bb          	addw	a1,a5,a1
    8000494c:	000b8513          	mv	a0,s7
    80004950:	00000097          	auipc	ra,0x0
    80004954:	afc080e7          	jalr	-1284(ra) # 8000444c <bread>
    80004958:	00050913          	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000495c:	004b2503          	lw	a0,4(s6)
    80004960:	000a849b          	sext.w	s1,s5
    80004964:	000c0713          	mv	a4,s8
    80004968:	faa4f8e3          	bgeu	s1,a0,80004918 <balloc+0x100>
      m = 1 << (bi % 8);
    8000496c:	00777693          	andi	a3,a4,7
    80004970:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80004974:	41f7579b          	sraiw	a5,a4,0x1f
    80004978:	01d7d79b          	srliw	a5,a5,0x1d
    8000497c:	00e787bb          	addw	a5,a5,a4
    80004980:	4037d79b          	sraiw	a5,a5,0x3
    80004984:	00f90633          	add	a2,s2,a5
    80004988:	05864603          	lbu	a2,88(a2)
    8000498c:	00c6f5b3          	and	a1,a3,a2
    80004990:	ee0586e3          	beqz	a1,8000487c <balloc+0x64>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004994:	0017071b          	addiw	a4,a4,1
    80004998:	0014849b          	addiw	s1,s1,1
    8000499c:	fd4716e3          	bne	a4,s4,80004968 <balloc+0x150>
    800049a0:	f79ff06f          	j	80004918 <balloc+0x100>
  printf("balloc: out of blocks\n");
    800049a4:	00006517          	auipc	a0,0x6
    800049a8:	cbc50513          	addi	a0,a0,-836 # 8000a660 <syscalls+0x100>
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	cfc080e7          	jalr	-772(ra) # 800006a8 <printf>
  return 0;
    800049b4:	00000493          	li	s1,0
    800049b8:	f29ff06f          	j	800048e0 <balloc+0xc8>

00000000800049bc <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800049bc:	fd010113          	addi	sp,sp,-48
    800049c0:	02113423          	sd	ra,40(sp)
    800049c4:	02813023          	sd	s0,32(sp)
    800049c8:	00913c23          	sd	s1,24(sp)
    800049cc:	01213823          	sd	s2,16(sp)
    800049d0:	01313423          	sd	s3,8(sp)
    800049d4:	01413023          	sd	s4,0(sp)
    800049d8:	03010413          	addi	s0,sp,48
    800049dc:	00050993          	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800049e0:	00b00793          	li	a5,11
    800049e4:	02b7ea63          	bltu	a5,a1,80004a18 <bmap+0x5c>
    if((addr = ip->addrs[bn]) == 0){
    800049e8:	02059793          	slli	a5,a1,0x20
    800049ec:	01e7d593          	srli	a1,a5,0x1e
    800049f0:	00b504b3          	add	s1,a0,a1
    800049f4:	0504a903          	lw	s2,80(s1)
    800049f8:	08091463          	bnez	s2,80004a80 <bmap+0xc4>
      addr = balloc(ip->dev);
    800049fc:	00052503          	lw	a0,0(a0)
    80004a00:	00000097          	auipc	ra,0x0
    80004a04:	e18080e7          	jalr	-488(ra) # 80004818 <balloc>
    80004a08:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80004a0c:	06090a63          	beqz	s2,80004a80 <bmap+0xc4>
        return 0;
      ip->addrs[bn] = addr;
    80004a10:	0524a823          	sw	s2,80(s1)
    80004a14:	06c0006f          	j	80004a80 <bmap+0xc4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80004a18:	ff45849b          	addiw	s1,a1,-12
    80004a1c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80004a20:	0ff00793          	li	a5,255
    80004a24:	0ae7e463          	bltu	a5,a4,80004acc <bmap+0x110>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80004a28:	08052903          	lw	s2,128(a0)
    80004a2c:	00091e63          	bnez	s2,80004a48 <bmap+0x8c>
      addr = balloc(ip->dev);
    80004a30:	00052503          	lw	a0,0(a0)
    80004a34:	00000097          	auipc	ra,0x0
    80004a38:	de4080e7          	jalr	-540(ra) # 80004818 <balloc>
    80004a3c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80004a40:	04090063          	beqz	s2,80004a80 <bmap+0xc4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80004a44:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80004a48:	00090593          	mv	a1,s2
    80004a4c:	0009a503          	lw	a0,0(s3)
    80004a50:	00000097          	auipc	ra,0x0
    80004a54:	9fc080e7          	jalr	-1540(ra) # 8000444c <bread>
    80004a58:	00050a13          	mv	s4,a0
    a = (uint*)bp->data;
    80004a5c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80004a60:	02049713          	slli	a4,s1,0x20
    80004a64:	01e75593          	srli	a1,a4,0x1e
    80004a68:	00b784b3          	add	s1,a5,a1
    80004a6c:	0004a903          	lw	s2,0(s1)
    80004a70:	02090a63          	beqz	s2,80004aa4 <bmap+0xe8>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80004a74:	000a0513          	mv	a0,s4
    80004a78:	00000097          	auipc	ra,0x0
    80004a7c:	b70080e7          	jalr	-1168(ra) # 800045e8 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80004a80:	00090513          	mv	a0,s2
    80004a84:	02813083          	ld	ra,40(sp)
    80004a88:	02013403          	ld	s0,32(sp)
    80004a8c:	01813483          	ld	s1,24(sp)
    80004a90:	01013903          	ld	s2,16(sp)
    80004a94:	00813983          	ld	s3,8(sp)
    80004a98:	00013a03          	ld	s4,0(sp)
    80004a9c:	03010113          	addi	sp,sp,48
    80004aa0:	00008067          	ret
      addr = balloc(ip->dev);
    80004aa4:	0009a503          	lw	a0,0(s3)
    80004aa8:	00000097          	auipc	ra,0x0
    80004aac:	d70080e7          	jalr	-656(ra) # 80004818 <balloc>
    80004ab0:	0005091b          	sext.w	s2,a0
      if(addr){
    80004ab4:	fc0900e3          	beqz	s2,80004a74 <bmap+0xb8>
        a[bn] = addr;
    80004ab8:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80004abc:	000a0513          	mv	a0,s4
    80004ac0:	00001097          	auipc	ra,0x1
    80004ac4:	63c080e7          	jalr	1596(ra) # 800060fc <log_write>
    80004ac8:	fadff06f          	j	80004a74 <bmap+0xb8>
  panic("bmap: out of range");
    80004acc:	00006517          	auipc	a0,0x6
    80004ad0:	bac50513          	addi	a0,a0,-1108 # 8000a678 <syscalls+0x118>
    80004ad4:	ffffc097          	auipc	ra,0xffffc
    80004ad8:	fac080e7          	jalr	-84(ra) # 80000a80 <panic>

0000000080004adc <iget>:
{
    80004adc:	fd010113          	addi	sp,sp,-48
    80004ae0:	02113423          	sd	ra,40(sp)
    80004ae4:	02813023          	sd	s0,32(sp)
    80004ae8:	00913c23          	sd	s1,24(sp)
    80004aec:	01213823          	sd	s2,16(sp)
    80004af0:	01313423          	sd	s3,8(sp)
    80004af4:	01413023          	sd	s4,0(sp)
    80004af8:	03010413          	addi	s0,sp,48
    80004afc:	00050993          	mv	s3,a0
    80004b00:	00058a13          	mv	s4,a1
  acquire(&itable.lock);
    80004b04:	0001c517          	auipc	a0,0x1c
    80004b08:	4ec50513          	addi	a0,a0,1260 # 80020ff0 <itable>
    80004b0c:	ffffc097          	auipc	ra,0xffffc
    80004b10:	5ac080e7          	jalr	1452(ra) # 800010b8 <acquire>
  empty = 0;
    80004b14:	00000913          	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004b18:	0001c497          	auipc	s1,0x1c
    80004b1c:	4f048493          	addi	s1,s1,1264 # 80021008 <itable+0x18>
    80004b20:	0001e697          	auipc	a3,0x1e
    80004b24:	f7868693          	addi	a3,a3,-136 # 80022a98 <log>
    80004b28:	0100006f          	j	80004b38 <iget+0x5c>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004b2c:	04090263          	beqz	s2,80004b70 <iget+0x94>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004b30:	08848493          	addi	s1,s1,136
    80004b34:	04d48463          	beq	s1,a3,80004b7c <iget+0xa0>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80004b38:	0084a783          	lw	a5,8(s1)
    80004b3c:	fef058e3          	blez	a5,80004b2c <iget+0x50>
    80004b40:	0004a703          	lw	a4,0(s1)
    80004b44:	ff3714e3          	bne	a4,s3,80004b2c <iget+0x50>
    80004b48:	0044a703          	lw	a4,4(s1)
    80004b4c:	ff4710e3          	bne	a4,s4,80004b2c <iget+0x50>
      ip->ref++;
    80004b50:	0017879b          	addiw	a5,a5,1
    80004b54:	00f4a423          	sw	a5,8(s1)
      release(&itable.lock);
    80004b58:	0001c517          	auipc	a0,0x1c
    80004b5c:	49850513          	addi	a0,a0,1176 # 80020ff0 <itable>
    80004b60:	ffffc097          	auipc	ra,0xffffc
    80004b64:	650080e7          	jalr	1616(ra) # 800011b0 <release>
      return ip;
    80004b68:	00048913          	mv	s2,s1
    80004b6c:	0380006f          	j	80004ba4 <iget+0xc8>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004b70:	fc0790e3          	bnez	a5,80004b30 <iget+0x54>
    80004b74:	00048913          	mv	s2,s1
    80004b78:	fb9ff06f          	j	80004b30 <iget+0x54>
  if(empty == 0)
    80004b7c:	04090663          	beqz	s2,80004bc8 <iget+0xec>
  ip->dev = dev;
    80004b80:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80004b84:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80004b88:	00100793          	li	a5,1
    80004b8c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80004b90:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80004b94:	0001c517          	auipc	a0,0x1c
    80004b98:	45c50513          	addi	a0,a0,1116 # 80020ff0 <itable>
    80004b9c:	ffffc097          	auipc	ra,0xffffc
    80004ba0:	614080e7          	jalr	1556(ra) # 800011b0 <release>
}
    80004ba4:	00090513          	mv	a0,s2
    80004ba8:	02813083          	ld	ra,40(sp)
    80004bac:	02013403          	ld	s0,32(sp)
    80004bb0:	01813483          	ld	s1,24(sp)
    80004bb4:	01013903          	ld	s2,16(sp)
    80004bb8:	00813983          	ld	s3,8(sp)
    80004bbc:	00013a03          	ld	s4,0(sp)
    80004bc0:	03010113          	addi	sp,sp,48
    80004bc4:	00008067          	ret
    panic("iget: no inodes");
    80004bc8:	00006517          	auipc	a0,0x6
    80004bcc:	ac850513          	addi	a0,a0,-1336 # 8000a690 <syscalls+0x130>
    80004bd0:	ffffc097          	auipc	ra,0xffffc
    80004bd4:	eb0080e7          	jalr	-336(ra) # 80000a80 <panic>

0000000080004bd8 <iinit>:
{
    80004bd8:	fd010113          	addi	sp,sp,-48
    80004bdc:	02113423          	sd	ra,40(sp)
    80004be0:	02813023          	sd	s0,32(sp)
    80004be4:	00913c23          	sd	s1,24(sp)
    80004be8:	01213823          	sd	s2,16(sp)
    80004bec:	01313423          	sd	s3,8(sp)
    80004bf0:	03010413          	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80004bf4:	00006597          	auipc	a1,0x6
    80004bf8:	aac58593          	addi	a1,a1,-1364 # 8000a6a0 <syscalls+0x140>
    80004bfc:	0001c517          	auipc	a0,0x1c
    80004c00:	3f450513          	addi	a0,a0,1012 # 80020ff0 <itable>
    80004c04:	ffffc097          	auipc	ra,0xffffc
    80004c08:	3d0080e7          	jalr	976(ra) # 80000fd4 <initlock>
  for(i = 0; i < NINODE; i++) {
    80004c0c:	0001c497          	auipc	s1,0x1c
    80004c10:	40c48493          	addi	s1,s1,1036 # 80021018 <itable+0x28>
    80004c14:	0001e997          	auipc	s3,0x1e
    80004c18:	e9498993          	addi	s3,s3,-364 # 80022aa8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80004c1c:	00006917          	auipc	s2,0x6
    80004c20:	a8c90913          	addi	s2,s2,-1396 # 8000a6a8 <syscalls+0x148>
    80004c24:	00090593          	mv	a1,s2
    80004c28:	00048513          	mv	a0,s1
    80004c2c:	00001097          	auipc	ra,0x1
    80004c30:	5ec080e7          	jalr	1516(ra) # 80006218 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80004c34:	08848493          	addi	s1,s1,136
    80004c38:	ff3496e3          	bne	s1,s3,80004c24 <iinit+0x4c>
}
    80004c3c:	02813083          	ld	ra,40(sp)
    80004c40:	02013403          	ld	s0,32(sp)
    80004c44:	01813483          	ld	s1,24(sp)
    80004c48:	01013903          	ld	s2,16(sp)
    80004c4c:	00813983          	ld	s3,8(sp)
    80004c50:	03010113          	addi	sp,sp,48
    80004c54:	00008067          	ret

0000000080004c58 <ialloc>:
{
    80004c58:	fb010113          	addi	sp,sp,-80
    80004c5c:	04113423          	sd	ra,72(sp)
    80004c60:	04813023          	sd	s0,64(sp)
    80004c64:	02913c23          	sd	s1,56(sp)
    80004c68:	03213823          	sd	s2,48(sp)
    80004c6c:	03313423          	sd	s3,40(sp)
    80004c70:	03413023          	sd	s4,32(sp)
    80004c74:	01513c23          	sd	s5,24(sp)
    80004c78:	01613823          	sd	s6,16(sp)
    80004c7c:	01713423          	sd	s7,8(sp)
    80004c80:	05010413          	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80004c84:	0001c717          	auipc	a4,0x1c
    80004c88:	35872703          	lw	a4,856(a4) # 80020fdc <sb+0xc>
    80004c8c:	00100793          	li	a5,1
    80004c90:	06e7f463          	bgeu	a5,a4,80004cf8 <ialloc+0xa0>
    80004c94:	00050a93          	mv	s5,a0
    80004c98:	00058b93          	mv	s7,a1
    80004c9c:	00100493          	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004ca0:	0001ca17          	auipc	s4,0x1c
    80004ca4:	330a0a13          	addi	s4,s4,816 # 80020fd0 <sb>
    80004ca8:	00048b1b          	sext.w	s6,s1
    80004cac:	0044d593          	srli	a1,s1,0x4
    80004cb0:	018a2783          	lw	a5,24(s4)
    80004cb4:	00b785bb          	addw	a1,a5,a1
    80004cb8:	000a8513          	mv	a0,s5
    80004cbc:	fffff097          	auipc	ra,0xfffff
    80004cc0:	790080e7          	jalr	1936(ra) # 8000444c <bread>
    80004cc4:	00050913          	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004cc8:	05850993          	addi	s3,a0,88
    80004ccc:	00f4f793          	andi	a5,s1,15
    80004cd0:	00679793          	slli	a5,a5,0x6
    80004cd4:	00f989b3          	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004cd8:	00099783          	lh	a5,0(s3)
    80004cdc:	04078e63          	beqz	a5,80004d38 <ialloc+0xe0>
    brelse(bp);
    80004ce0:	00000097          	auipc	ra,0x0
    80004ce4:	908080e7          	jalr	-1784(ra) # 800045e8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80004ce8:	00148493          	addi	s1,s1,1
    80004cec:	00ca2703          	lw	a4,12(s4)
    80004cf0:	0004879b          	sext.w	a5,s1
    80004cf4:	fae7eae3          	bltu	a5,a4,80004ca8 <ialloc+0x50>
  printf("ialloc: no inodes\n");
    80004cf8:	00006517          	auipc	a0,0x6
    80004cfc:	9b850513          	addi	a0,a0,-1608 # 8000a6b0 <syscalls+0x150>
    80004d00:	ffffc097          	auipc	ra,0xffffc
    80004d04:	9a8080e7          	jalr	-1624(ra) # 800006a8 <printf>
  return 0;
    80004d08:	00000513          	li	a0,0
}
    80004d0c:	04813083          	ld	ra,72(sp)
    80004d10:	04013403          	ld	s0,64(sp)
    80004d14:	03813483          	ld	s1,56(sp)
    80004d18:	03013903          	ld	s2,48(sp)
    80004d1c:	02813983          	ld	s3,40(sp)
    80004d20:	02013a03          	ld	s4,32(sp)
    80004d24:	01813a83          	ld	s5,24(sp)
    80004d28:	01013b03          	ld	s6,16(sp)
    80004d2c:	00813b83          	ld	s7,8(sp)
    80004d30:	05010113          	addi	sp,sp,80
    80004d34:	00008067          	ret
      memset(dip, 0, sizeof(*dip));
    80004d38:	04000613          	li	a2,64
    80004d3c:	00000593          	li	a1,0
    80004d40:	00098513          	mv	a0,s3
    80004d44:	ffffc097          	auipc	ra,0xffffc
    80004d48:	4cc080e7          	jalr	1228(ra) # 80001210 <memset>
      dip->type = type;
    80004d4c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80004d50:	00090513          	mv	a0,s2
    80004d54:	00001097          	auipc	ra,0x1
    80004d58:	3a8080e7          	jalr	936(ra) # 800060fc <log_write>
      brelse(bp);
    80004d5c:	00090513          	mv	a0,s2
    80004d60:	00000097          	auipc	ra,0x0
    80004d64:	888080e7          	jalr	-1912(ra) # 800045e8 <brelse>
      return iget(dev, inum);
    80004d68:	000b0593          	mv	a1,s6
    80004d6c:	000a8513          	mv	a0,s5
    80004d70:	00000097          	auipc	ra,0x0
    80004d74:	d6c080e7          	jalr	-660(ra) # 80004adc <iget>
    80004d78:	f95ff06f          	j	80004d0c <ialloc+0xb4>

0000000080004d7c <iupdate>:
{
    80004d7c:	fe010113          	addi	sp,sp,-32
    80004d80:	00113c23          	sd	ra,24(sp)
    80004d84:	00813823          	sd	s0,16(sp)
    80004d88:	00913423          	sd	s1,8(sp)
    80004d8c:	01213023          	sd	s2,0(sp)
    80004d90:	02010413          	addi	s0,sp,32
    80004d94:	00050493          	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004d98:	00452783          	lw	a5,4(a0)
    80004d9c:	0047d79b          	srliw	a5,a5,0x4
    80004da0:	0001c597          	auipc	a1,0x1c
    80004da4:	2485a583          	lw	a1,584(a1) # 80020fe8 <sb+0x18>
    80004da8:	00b785bb          	addw	a1,a5,a1
    80004dac:	00052503          	lw	a0,0(a0)
    80004db0:	fffff097          	auipc	ra,0xfffff
    80004db4:	69c080e7          	jalr	1692(ra) # 8000444c <bread>
    80004db8:	00050913          	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004dbc:	05850793          	addi	a5,a0,88
    80004dc0:	0044a703          	lw	a4,4(s1)
    80004dc4:	00f77713          	andi	a4,a4,15
    80004dc8:	00671713          	slli	a4,a4,0x6
    80004dcc:	00e787b3          	add	a5,a5,a4
  dip->type = ip->type;
    80004dd0:	04449703          	lh	a4,68(s1)
    80004dd4:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80004dd8:	04649703          	lh	a4,70(s1)
    80004ddc:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80004de0:	04849703          	lh	a4,72(s1)
    80004de4:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80004de8:	04a49703          	lh	a4,74(s1)
    80004dec:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80004df0:	04c4a703          	lw	a4,76(s1)
    80004df4:	00e7a423          	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004df8:	03400613          	li	a2,52
    80004dfc:	05048593          	addi	a1,s1,80
    80004e00:	00c78513          	addi	a0,a5,12
    80004e04:	ffffc097          	auipc	ra,0xffffc
    80004e08:	4a0080e7          	jalr	1184(ra) # 800012a4 <memmove>
  log_write(bp);
    80004e0c:	00090513          	mv	a0,s2
    80004e10:	00001097          	auipc	ra,0x1
    80004e14:	2ec080e7          	jalr	748(ra) # 800060fc <log_write>
  brelse(bp);
    80004e18:	00090513          	mv	a0,s2
    80004e1c:	fffff097          	auipc	ra,0xfffff
    80004e20:	7cc080e7          	jalr	1996(ra) # 800045e8 <brelse>
}
    80004e24:	01813083          	ld	ra,24(sp)
    80004e28:	01013403          	ld	s0,16(sp)
    80004e2c:	00813483          	ld	s1,8(sp)
    80004e30:	00013903          	ld	s2,0(sp)
    80004e34:	02010113          	addi	sp,sp,32
    80004e38:	00008067          	ret

0000000080004e3c <idup>:
{
    80004e3c:	fe010113          	addi	sp,sp,-32
    80004e40:	00113c23          	sd	ra,24(sp)
    80004e44:	00813823          	sd	s0,16(sp)
    80004e48:	00913423          	sd	s1,8(sp)
    80004e4c:	02010413          	addi	s0,sp,32
    80004e50:	00050493          	mv	s1,a0
  acquire(&itable.lock);
    80004e54:	0001c517          	auipc	a0,0x1c
    80004e58:	19c50513          	addi	a0,a0,412 # 80020ff0 <itable>
    80004e5c:	ffffc097          	auipc	ra,0xffffc
    80004e60:	25c080e7          	jalr	604(ra) # 800010b8 <acquire>
  ip->ref++;
    80004e64:	0084a783          	lw	a5,8(s1)
    80004e68:	0017879b          	addiw	a5,a5,1
    80004e6c:	00f4a423          	sw	a5,8(s1)
  release(&itable.lock);
    80004e70:	0001c517          	auipc	a0,0x1c
    80004e74:	18050513          	addi	a0,a0,384 # 80020ff0 <itable>
    80004e78:	ffffc097          	auipc	ra,0xffffc
    80004e7c:	338080e7          	jalr	824(ra) # 800011b0 <release>
}
    80004e80:	00048513          	mv	a0,s1
    80004e84:	01813083          	ld	ra,24(sp)
    80004e88:	01013403          	ld	s0,16(sp)
    80004e8c:	00813483          	ld	s1,8(sp)
    80004e90:	02010113          	addi	sp,sp,32
    80004e94:	00008067          	ret

0000000080004e98 <ilock>:
{
    80004e98:	fe010113          	addi	sp,sp,-32
    80004e9c:	00113c23          	sd	ra,24(sp)
    80004ea0:	00813823          	sd	s0,16(sp)
    80004ea4:	00913423          	sd	s1,8(sp)
    80004ea8:	01213023          	sd	s2,0(sp)
    80004eac:	02010413          	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004eb0:	02050e63          	beqz	a0,80004eec <ilock+0x54>
    80004eb4:	00050493          	mv	s1,a0
    80004eb8:	00852783          	lw	a5,8(a0)
    80004ebc:	02f05863          	blez	a5,80004eec <ilock+0x54>
  acquiresleep(&ip->lock);
    80004ec0:	01050513          	addi	a0,a0,16
    80004ec4:	00001097          	auipc	ra,0x1
    80004ec8:	3ac080e7          	jalr	940(ra) # 80006270 <acquiresleep>
  if(ip->valid == 0){
    80004ecc:	0404a783          	lw	a5,64(s1)
    80004ed0:	02078663          	beqz	a5,80004efc <ilock+0x64>
}
    80004ed4:	01813083          	ld	ra,24(sp)
    80004ed8:	01013403          	ld	s0,16(sp)
    80004edc:	00813483          	ld	s1,8(sp)
    80004ee0:	00013903          	ld	s2,0(sp)
    80004ee4:	02010113          	addi	sp,sp,32
    80004ee8:	00008067          	ret
    panic("ilock");
    80004eec:	00005517          	auipc	a0,0x5
    80004ef0:	7dc50513          	addi	a0,a0,2012 # 8000a6c8 <syscalls+0x168>
    80004ef4:	ffffc097          	auipc	ra,0xffffc
    80004ef8:	b8c080e7          	jalr	-1140(ra) # 80000a80 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004efc:	0044a783          	lw	a5,4(s1)
    80004f00:	0047d79b          	srliw	a5,a5,0x4
    80004f04:	0001c597          	auipc	a1,0x1c
    80004f08:	0e45a583          	lw	a1,228(a1) # 80020fe8 <sb+0x18>
    80004f0c:	00b785bb          	addw	a1,a5,a1
    80004f10:	0004a503          	lw	a0,0(s1)
    80004f14:	fffff097          	auipc	ra,0xfffff
    80004f18:	538080e7          	jalr	1336(ra) # 8000444c <bread>
    80004f1c:	00050913          	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004f20:	05850593          	addi	a1,a0,88
    80004f24:	0044a783          	lw	a5,4(s1)
    80004f28:	00f7f793          	andi	a5,a5,15
    80004f2c:	00679793          	slli	a5,a5,0x6
    80004f30:	00f585b3          	add	a1,a1,a5
    ip->type = dip->type;
    80004f34:	00059783          	lh	a5,0(a1)
    80004f38:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004f3c:	00259783          	lh	a5,2(a1)
    80004f40:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004f44:	00459783          	lh	a5,4(a1)
    80004f48:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004f4c:	00659783          	lh	a5,6(a1)
    80004f50:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004f54:	0085a783          	lw	a5,8(a1)
    80004f58:	04f4a623          	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004f5c:	03400613          	li	a2,52
    80004f60:	00c58593          	addi	a1,a1,12
    80004f64:	05048513          	addi	a0,s1,80
    80004f68:	ffffc097          	auipc	ra,0xffffc
    80004f6c:	33c080e7          	jalr	828(ra) # 800012a4 <memmove>
    brelse(bp);
    80004f70:	00090513          	mv	a0,s2
    80004f74:	fffff097          	auipc	ra,0xfffff
    80004f78:	674080e7          	jalr	1652(ra) # 800045e8 <brelse>
    ip->valid = 1;
    80004f7c:	00100793          	li	a5,1
    80004f80:	04f4a023          	sw	a5,64(s1)
    if(ip->type == 0)
    80004f84:	04449783          	lh	a5,68(s1)
    80004f88:	f40796e3          	bnez	a5,80004ed4 <ilock+0x3c>
      panic("ilock: no type");
    80004f8c:	00005517          	auipc	a0,0x5
    80004f90:	74450513          	addi	a0,a0,1860 # 8000a6d0 <syscalls+0x170>
    80004f94:	ffffc097          	auipc	ra,0xffffc
    80004f98:	aec080e7          	jalr	-1300(ra) # 80000a80 <panic>

0000000080004f9c <iunlock>:
{
    80004f9c:	fe010113          	addi	sp,sp,-32
    80004fa0:	00113c23          	sd	ra,24(sp)
    80004fa4:	00813823          	sd	s0,16(sp)
    80004fa8:	00913423          	sd	s1,8(sp)
    80004fac:	01213023          	sd	s2,0(sp)
    80004fb0:	02010413          	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004fb4:	04050463          	beqz	a0,80004ffc <iunlock+0x60>
    80004fb8:	00050493          	mv	s1,a0
    80004fbc:	01050913          	addi	s2,a0,16
    80004fc0:	00090513          	mv	a0,s2
    80004fc4:	00001097          	auipc	ra,0x1
    80004fc8:	398080e7          	jalr	920(ra) # 8000635c <holdingsleep>
    80004fcc:	02050863          	beqz	a0,80004ffc <iunlock+0x60>
    80004fd0:	0084a783          	lw	a5,8(s1)
    80004fd4:	02f05463          	blez	a5,80004ffc <iunlock+0x60>
  releasesleep(&ip->lock);
    80004fd8:	00090513          	mv	a0,s2
    80004fdc:	00001097          	auipc	ra,0x1
    80004fe0:	31c080e7          	jalr	796(ra) # 800062f8 <releasesleep>
}
    80004fe4:	01813083          	ld	ra,24(sp)
    80004fe8:	01013403          	ld	s0,16(sp)
    80004fec:	00813483          	ld	s1,8(sp)
    80004ff0:	00013903          	ld	s2,0(sp)
    80004ff4:	02010113          	addi	sp,sp,32
    80004ff8:	00008067          	ret
    panic("iunlock");
    80004ffc:	00005517          	auipc	a0,0x5
    80005000:	6e450513          	addi	a0,a0,1764 # 8000a6e0 <syscalls+0x180>
    80005004:	ffffc097          	auipc	ra,0xffffc
    80005008:	a7c080e7          	jalr	-1412(ra) # 80000a80 <panic>

000000008000500c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000500c:	fd010113          	addi	sp,sp,-48
    80005010:	02113423          	sd	ra,40(sp)
    80005014:	02813023          	sd	s0,32(sp)
    80005018:	00913c23          	sd	s1,24(sp)
    8000501c:	01213823          	sd	s2,16(sp)
    80005020:	01313423          	sd	s3,8(sp)
    80005024:	01413023          	sd	s4,0(sp)
    80005028:	03010413          	addi	s0,sp,48
    8000502c:	00050993          	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80005030:	05050493          	addi	s1,a0,80
    80005034:	08050913          	addi	s2,a0,128
    80005038:	00c0006f          	j	80005044 <itrunc+0x38>
    8000503c:	00448493          	addi	s1,s1,4
    80005040:	03248063          	beq	s1,s2,80005060 <itrunc+0x54>
    if(ip->addrs[i]){
    80005044:	0004a583          	lw	a1,0(s1)
    80005048:	fe058ae3          	beqz	a1,8000503c <itrunc+0x30>
      bfree(ip->dev, ip->addrs[i]);
    8000504c:	0009a503          	lw	a0,0(s3)
    80005050:	fffff097          	auipc	ra,0xfffff
    80005054:	720080e7          	jalr	1824(ra) # 80004770 <bfree>
      ip->addrs[i] = 0;
    80005058:	0004a023          	sw	zero,0(s1)
    8000505c:	fe1ff06f          	j	8000503c <itrunc+0x30>
    }
  }

  if(ip->addrs[NDIRECT]){
    80005060:	0809a583          	lw	a1,128(s3)
    80005064:	02059a63          	bnez	a1,80005098 <itrunc+0x8c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80005068:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000506c:	00098513          	mv	a0,s3
    80005070:	00000097          	auipc	ra,0x0
    80005074:	d0c080e7          	jalr	-756(ra) # 80004d7c <iupdate>
}
    80005078:	02813083          	ld	ra,40(sp)
    8000507c:	02013403          	ld	s0,32(sp)
    80005080:	01813483          	ld	s1,24(sp)
    80005084:	01013903          	ld	s2,16(sp)
    80005088:	00813983          	ld	s3,8(sp)
    8000508c:	00013a03          	ld	s4,0(sp)
    80005090:	03010113          	addi	sp,sp,48
    80005094:	00008067          	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80005098:	0009a503          	lw	a0,0(s3)
    8000509c:	fffff097          	auipc	ra,0xfffff
    800050a0:	3b0080e7          	jalr	944(ra) # 8000444c <bread>
    800050a4:	00050a13          	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800050a8:	05850493          	addi	s1,a0,88
    800050ac:	45850913          	addi	s2,a0,1112
    800050b0:	00c0006f          	j	800050bc <itrunc+0xb0>
    800050b4:	00448493          	addi	s1,s1,4
    800050b8:	01248e63          	beq	s1,s2,800050d4 <itrunc+0xc8>
      if(a[j])
    800050bc:	0004a583          	lw	a1,0(s1)
    800050c0:	fe058ae3          	beqz	a1,800050b4 <itrunc+0xa8>
        bfree(ip->dev, a[j]);
    800050c4:	0009a503          	lw	a0,0(s3)
    800050c8:	fffff097          	auipc	ra,0xfffff
    800050cc:	6a8080e7          	jalr	1704(ra) # 80004770 <bfree>
    800050d0:	fe5ff06f          	j	800050b4 <itrunc+0xa8>
    brelse(bp);
    800050d4:	000a0513          	mv	a0,s4
    800050d8:	fffff097          	auipc	ra,0xfffff
    800050dc:	510080e7          	jalr	1296(ra) # 800045e8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800050e0:	0809a583          	lw	a1,128(s3)
    800050e4:	0009a503          	lw	a0,0(s3)
    800050e8:	fffff097          	auipc	ra,0xfffff
    800050ec:	688080e7          	jalr	1672(ra) # 80004770 <bfree>
    ip->addrs[NDIRECT] = 0;
    800050f0:	0809a023          	sw	zero,128(s3)
    800050f4:	f75ff06f          	j	80005068 <itrunc+0x5c>

00000000800050f8 <iput>:
{
    800050f8:	fe010113          	addi	sp,sp,-32
    800050fc:	00113c23          	sd	ra,24(sp)
    80005100:	00813823          	sd	s0,16(sp)
    80005104:	00913423          	sd	s1,8(sp)
    80005108:	01213023          	sd	s2,0(sp)
    8000510c:	02010413          	addi	s0,sp,32
    80005110:	00050493          	mv	s1,a0
  acquire(&itable.lock);
    80005114:	0001c517          	auipc	a0,0x1c
    80005118:	edc50513          	addi	a0,a0,-292 # 80020ff0 <itable>
    8000511c:	ffffc097          	auipc	ra,0xffffc
    80005120:	f9c080e7          	jalr	-100(ra) # 800010b8 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80005124:	0084a703          	lw	a4,8(s1)
    80005128:	00100793          	li	a5,1
    8000512c:	02f70c63          	beq	a4,a5,80005164 <iput+0x6c>
  ip->ref--;
    80005130:	0084a783          	lw	a5,8(s1)
    80005134:	fff7879b          	addiw	a5,a5,-1
    80005138:	00f4a423          	sw	a5,8(s1)
  release(&itable.lock);
    8000513c:	0001c517          	auipc	a0,0x1c
    80005140:	eb450513          	addi	a0,a0,-332 # 80020ff0 <itable>
    80005144:	ffffc097          	auipc	ra,0xffffc
    80005148:	06c080e7          	jalr	108(ra) # 800011b0 <release>
}
    8000514c:	01813083          	ld	ra,24(sp)
    80005150:	01013403          	ld	s0,16(sp)
    80005154:	00813483          	ld	s1,8(sp)
    80005158:	00013903          	ld	s2,0(sp)
    8000515c:	02010113          	addi	sp,sp,32
    80005160:	00008067          	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80005164:	0404a783          	lw	a5,64(s1)
    80005168:	fc0784e3          	beqz	a5,80005130 <iput+0x38>
    8000516c:	04a49783          	lh	a5,74(s1)
    80005170:	fc0790e3          	bnez	a5,80005130 <iput+0x38>
    acquiresleep(&ip->lock);
    80005174:	01048913          	addi	s2,s1,16
    80005178:	00090513          	mv	a0,s2
    8000517c:	00001097          	auipc	ra,0x1
    80005180:	0f4080e7          	jalr	244(ra) # 80006270 <acquiresleep>
    release(&itable.lock);
    80005184:	0001c517          	auipc	a0,0x1c
    80005188:	e6c50513          	addi	a0,a0,-404 # 80020ff0 <itable>
    8000518c:	ffffc097          	auipc	ra,0xffffc
    80005190:	024080e7          	jalr	36(ra) # 800011b0 <release>
    itrunc(ip);
    80005194:	00048513          	mv	a0,s1
    80005198:	00000097          	auipc	ra,0x0
    8000519c:	e74080e7          	jalr	-396(ra) # 8000500c <itrunc>
    ip->type = 0;
    800051a0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800051a4:	00048513          	mv	a0,s1
    800051a8:	00000097          	auipc	ra,0x0
    800051ac:	bd4080e7          	jalr	-1068(ra) # 80004d7c <iupdate>
    ip->valid = 0;
    800051b0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800051b4:	00090513          	mv	a0,s2
    800051b8:	00001097          	auipc	ra,0x1
    800051bc:	140080e7          	jalr	320(ra) # 800062f8 <releasesleep>
    acquire(&itable.lock);
    800051c0:	0001c517          	auipc	a0,0x1c
    800051c4:	e3050513          	addi	a0,a0,-464 # 80020ff0 <itable>
    800051c8:	ffffc097          	auipc	ra,0xffffc
    800051cc:	ef0080e7          	jalr	-272(ra) # 800010b8 <acquire>
    800051d0:	f61ff06f          	j	80005130 <iput+0x38>

00000000800051d4 <iunlockput>:
{
    800051d4:	fe010113          	addi	sp,sp,-32
    800051d8:	00113c23          	sd	ra,24(sp)
    800051dc:	00813823          	sd	s0,16(sp)
    800051e0:	00913423          	sd	s1,8(sp)
    800051e4:	02010413          	addi	s0,sp,32
    800051e8:	00050493          	mv	s1,a0
  iunlock(ip);
    800051ec:	00000097          	auipc	ra,0x0
    800051f0:	db0080e7          	jalr	-592(ra) # 80004f9c <iunlock>
  iput(ip);
    800051f4:	00048513          	mv	a0,s1
    800051f8:	00000097          	auipc	ra,0x0
    800051fc:	f00080e7          	jalr	-256(ra) # 800050f8 <iput>
}
    80005200:	01813083          	ld	ra,24(sp)
    80005204:	01013403          	ld	s0,16(sp)
    80005208:	00813483          	ld	s1,8(sp)
    8000520c:	02010113          	addi	sp,sp,32
    80005210:	00008067          	ret

0000000080005214 <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80005214:	0001c717          	auipc	a4,0x1c
    80005218:	dc872703          	lw	a4,-568(a4) # 80020fdc <sb+0xc>
    8000521c:	00100793          	li	a5,1
    80005220:	12e7fc63          	bgeu	a5,a4,80005358 <ireclaim+0x144>
{
    80005224:	fc010113          	addi	sp,sp,-64
    80005228:	02113c23          	sd	ra,56(sp)
    8000522c:	02813823          	sd	s0,48(sp)
    80005230:	02913423          	sd	s1,40(sp)
    80005234:	03213023          	sd	s2,32(sp)
    80005238:	01313c23          	sd	s3,24(sp)
    8000523c:	01413823          	sd	s4,16(sp)
    80005240:	01513423          	sd	s5,8(sp)
    80005244:	01613023          	sd	s6,0(sp)
    80005248:	04010413          	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    8000524c:	00100493          	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80005250:	00050a1b          	sext.w	s4,a0
    80005254:	0001ca97          	auipc	s5,0x1c
    80005258:	d7ca8a93          	addi	s5,s5,-644 # 80020fd0 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    8000525c:	00005b17          	auipc	s6,0x5
    80005260:	48cb0b13          	addi	s6,s6,1164 # 8000a6e8 <syscalls+0x188>
    80005264:	07c0006f          	j	800052e0 <ireclaim+0xcc>
    80005268:	00098593          	mv	a1,s3
    8000526c:	000b0513          	mv	a0,s6
    80005270:	ffffb097          	auipc	ra,0xffffb
    80005274:	438080e7          	jalr	1080(ra) # 800006a8 <printf>
      ip = iget(dev, inum);
    80005278:	00098593          	mv	a1,s3
    8000527c:	000a0513          	mv	a0,s4
    80005280:	00000097          	auipc	ra,0x0
    80005284:	85c080e7          	jalr	-1956(ra) # 80004adc <iget>
    80005288:	00050993          	mv	s3,a0
    brelse(bp);
    8000528c:	00090513          	mv	a0,s2
    80005290:	fffff097          	auipc	ra,0xfffff
    80005294:	358080e7          	jalr	856(ra) # 800045e8 <brelse>
    if (ip) {
    80005298:	02098c63          	beqz	s3,800052d0 <ireclaim+0xbc>
      begin_op();
    8000529c:	00001097          	auipc	ra,0x1
    800052a0:	bfc080e7          	jalr	-1028(ra) # 80005e98 <begin_op>
      ilock(ip);
    800052a4:	00098513          	mv	a0,s3
    800052a8:	00000097          	auipc	ra,0x0
    800052ac:	bf0080e7          	jalr	-1040(ra) # 80004e98 <ilock>
      iunlock(ip);
    800052b0:	00098513          	mv	a0,s3
    800052b4:	00000097          	auipc	ra,0x0
    800052b8:	ce8080e7          	jalr	-792(ra) # 80004f9c <iunlock>
      iput(ip);
    800052bc:	00098513          	mv	a0,s3
    800052c0:	00000097          	auipc	ra,0x0
    800052c4:	e38080e7          	jalr	-456(ra) # 800050f8 <iput>
      end_op();
    800052c8:	00001097          	auipc	ra,0x1
    800052cc:	c84080e7          	jalr	-892(ra) # 80005f4c <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800052d0:	00148493          	addi	s1,s1,1
    800052d4:	00caa703          	lw	a4,12(s5)
    800052d8:	0004879b          	sext.w	a5,s1
    800052dc:	04e7fa63          	bgeu	a5,a4,80005330 <ireclaim+0x11c>
    800052e0:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    800052e4:	0044d593          	srli	a1,s1,0x4
    800052e8:	018aa783          	lw	a5,24(s5)
    800052ec:	00b785bb          	addw	a1,a5,a1
    800052f0:	000a0513          	mv	a0,s4
    800052f4:	fffff097          	auipc	ra,0xfffff
    800052f8:	158080e7          	jalr	344(ra) # 8000444c <bread>
    800052fc:	00050913          	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    80005300:	05850793          	addi	a5,a0,88
    80005304:	00f9f713          	andi	a4,s3,15
    80005308:	00671713          	slli	a4,a4,0x6
    8000530c:	00e787b3          	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    80005310:	00079703          	lh	a4,0(a5)
    80005314:	00070663          	beqz	a4,80005320 <ireclaim+0x10c>
    80005318:	00679783          	lh	a5,6(a5)
    8000531c:	f40786e3          	beqz	a5,80005268 <ireclaim+0x54>
    brelse(bp);
    80005320:	00090513          	mv	a0,s2
    80005324:	fffff097          	auipc	ra,0xfffff
    80005328:	2c4080e7          	jalr	708(ra) # 800045e8 <brelse>
    if (ip) {
    8000532c:	fa5ff06f          	j	800052d0 <ireclaim+0xbc>
}
    80005330:	03813083          	ld	ra,56(sp)
    80005334:	03013403          	ld	s0,48(sp)
    80005338:	02813483          	ld	s1,40(sp)
    8000533c:	02013903          	ld	s2,32(sp)
    80005340:	01813983          	ld	s3,24(sp)
    80005344:	01013a03          	ld	s4,16(sp)
    80005348:	00813a83          	ld	s5,8(sp)
    8000534c:	00013b03          	ld	s6,0(sp)
    80005350:	04010113          	addi	sp,sp,64
    80005354:	00008067          	ret
    80005358:	00008067          	ret

000000008000535c <fsinit>:
fsinit(int dev) {
    8000535c:	fd010113          	addi	sp,sp,-48
    80005360:	02113423          	sd	ra,40(sp)
    80005364:	02813023          	sd	s0,32(sp)
    80005368:	00913c23          	sd	s1,24(sp)
    8000536c:	01213823          	sd	s2,16(sp)
    80005370:	01313423          	sd	s3,8(sp)
    80005374:	03010413          	addi	s0,sp,48
    80005378:	00050493          	mv	s1,a0
  bp = bread(dev, 1);
    8000537c:	00100593          	li	a1,1
    80005380:	fffff097          	auipc	ra,0xfffff
    80005384:	0cc080e7          	jalr	204(ra) # 8000444c <bread>
    80005388:	00050913          	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000538c:	0001c997          	auipc	s3,0x1c
    80005390:	c4498993          	addi	s3,s3,-956 # 80020fd0 <sb>
    80005394:	02000613          	li	a2,32
    80005398:	05850593          	addi	a1,a0,88
    8000539c:	00098513          	mv	a0,s3
    800053a0:	ffffc097          	auipc	ra,0xffffc
    800053a4:	f04080e7          	jalr	-252(ra) # 800012a4 <memmove>
  brelse(bp);
    800053a8:	00090513          	mv	a0,s2
    800053ac:	fffff097          	auipc	ra,0xfffff
    800053b0:	23c080e7          	jalr	572(ra) # 800045e8 <brelse>
  if(sb.magic != FSMAGIC)
    800053b4:	0009a703          	lw	a4,0(s3)
    800053b8:	102037b7          	lui	a5,0x10203
    800053bc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800053c0:	04f71063          	bne	a4,a5,80005400 <fsinit+0xa4>
  initlog(dev, &sb);
    800053c4:	0001c597          	auipc	a1,0x1c
    800053c8:	c0c58593          	addi	a1,a1,-1012 # 80020fd0 <sb>
    800053cc:	00048513          	mv	a0,s1
    800053d0:	00001097          	auipc	ra,0x1
    800053d4:	9f0080e7          	jalr	-1552(ra) # 80005dc0 <initlog>
  ireclaim(dev);
    800053d8:	00048513          	mv	a0,s1
    800053dc:	00000097          	auipc	ra,0x0
    800053e0:	e38080e7          	jalr	-456(ra) # 80005214 <ireclaim>
}
    800053e4:	02813083          	ld	ra,40(sp)
    800053e8:	02013403          	ld	s0,32(sp)
    800053ec:	01813483          	ld	s1,24(sp)
    800053f0:	01013903          	ld	s2,16(sp)
    800053f4:	00813983          	ld	s3,8(sp)
    800053f8:	03010113          	addi	sp,sp,48
    800053fc:	00008067          	ret
    panic("invalid file system");
    80005400:	00005517          	auipc	a0,0x5
    80005404:	30850513          	addi	a0,a0,776 # 8000a708 <syscalls+0x1a8>
    80005408:	ffffb097          	auipc	ra,0xffffb
    8000540c:	678080e7          	jalr	1656(ra) # 80000a80 <panic>

0000000080005410 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80005410:	ff010113          	addi	sp,sp,-16
    80005414:	00813423          	sd	s0,8(sp)
    80005418:	01010413          	addi	s0,sp,16
  st->dev = ip->dev;
    8000541c:	00052783          	lw	a5,0(a0)
    80005420:	00f5a023          	sw	a5,0(a1)
  st->ino = ip->inum;
    80005424:	00452783          	lw	a5,4(a0)
    80005428:	00f5a223          	sw	a5,4(a1)
  st->type = ip->type;
    8000542c:	04451783          	lh	a5,68(a0)
    80005430:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80005434:	04a51783          	lh	a5,74(a0)
    80005438:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000543c:	04c56783          	lwu	a5,76(a0)
    80005440:	00f5b823          	sd	a5,16(a1)
}
    80005444:	00813403          	ld	s0,8(sp)
    80005448:	01010113          	addi	sp,sp,16
    8000544c:	00008067          	ret

0000000080005450 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80005450:	04c52783          	lw	a5,76(a0)
    80005454:	16d7e263          	bltu	a5,a3,800055b8 <readi+0x168>
{
    80005458:	f9010113          	addi	sp,sp,-112
    8000545c:	06113423          	sd	ra,104(sp)
    80005460:	06813023          	sd	s0,96(sp)
    80005464:	04913c23          	sd	s1,88(sp)
    80005468:	05213823          	sd	s2,80(sp)
    8000546c:	05313423          	sd	s3,72(sp)
    80005470:	05413023          	sd	s4,64(sp)
    80005474:	03513c23          	sd	s5,56(sp)
    80005478:	03613823          	sd	s6,48(sp)
    8000547c:	03713423          	sd	s7,40(sp)
    80005480:	03813023          	sd	s8,32(sp)
    80005484:	01913c23          	sd	s9,24(sp)
    80005488:	01a13823          	sd	s10,16(sp)
    8000548c:	01b13423          	sd	s11,8(sp)
    80005490:	07010413          	addi	s0,sp,112
    80005494:	00050b13          	mv	s6,a0
    80005498:	00058b93          	mv	s7,a1
    8000549c:	00060a13          	mv	s4,a2
    800054a0:	00068493          	mv	s1,a3
    800054a4:	00070a93          	mv	s5,a4
  if(off > ip->size || off + n < off)
    800054a8:	00e6873b          	addw	a4,a3,a4
    return 0;
    800054ac:	00000513          	li	a0,0
  if(off > ip->size || off + n < off)
    800054b0:	0cd76263          	bltu	a4,a3,80005574 <readi+0x124>
  if(off + n > ip->size)
    800054b4:	00e7f463          	bgeu	a5,a4,800054bc <readi+0x6c>
    n = ip->size - off;
    800054b8:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800054bc:	0e0a8a63          	beqz	s5,800055b0 <readi+0x160>
    800054c0:	00000993          	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800054c4:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800054c8:	fff00c13          	li	s8,-1
    800054cc:	0480006f          	j	80005514 <readi+0xc4>
    800054d0:	020d1d93          	slli	s11,s10,0x20
    800054d4:	020ddd93          	srli	s11,s11,0x20
    800054d8:	05890613          	addi	a2,s2,88
    800054dc:	000d8693          	mv	a3,s11
    800054e0:	00e60633          	add	a2,a2,a4
    800054e4:	000a0593          	mv	a1,s4
    800054e8:	000b8513          	mv	a0,s7
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	14c080e7          	jalr	332(ra) # 80003638 <either_copyout>
    800054f4:	07850663          	beq	a0,s8,80005560 <readi+0x110>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800054f8:	00090513          	mv	a0,s2
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	0ec080e7          	jalr	236(ra) # 800045e8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80005504:	013d09bb          	addw	s3,s10,s3
    80005508:	009d04bb          	addw	s1,s10,s1
    8000550c:	01ba0a33          	add	s4,s4,s11
    80005510:	0759f063          	bgeu	s3,s5,80005570 <readi+0x120>
    uint addr = bmap(ip, off/BSIZE);
    80005514:	00a4d59b          	srliw	a1,s1,0xa
    80005518:	000b0513          	mv	a0,s6
    8000551c:	fffff097          	auipc	ra,0xfffff
    80005520:	4a0080e7          	jalr	1184(ra) # 800049bc <bmap>
    80005524:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80005528:	04058463          	beqz	a1,80005570 <readi+0x120>
    bp = bread(ip->dev, addr);
    8000552c:	000b2503          	lw	a0,0(s6)
    80005530:	fffff097          	auipc	ra,0xfffff
    80005534:	f1c080e7          	jalr	-228(ra) # 8000444c <bread>
    80005538:	00050913          	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000553c:	3ff4f713          	andi	a4,s1,1023
    80005540:	40ec87bb          	subw	a5,s9,a4
    80005544:	413a86bb          	subw	a3,s5,s3
    80005548:	00078d13          	mv	s10,a5
    8000554c:	0007879b          	sext.w	a5,a5
    80005550:	0006861b          	sext.w	a2,a3
    80005554:	f6f67ee3          	bgeu	a2,a5,800054d0 <readi+0x80>
    80005558:	00068d13          	mv	s10,a3
    8000555c:	f75ff06f          	j	800054d0 <readi+0x80>
      brelse(bp);
    80005560:	00090513          	mv	a0,s2
    80005564:	fffff097          	auipc	ra,0xfffff
    80005568:	084080e7          	jalr	132(ra) # 800045e8 <brelse>
      tot = -1;
    8000556c:	fff00993          	li	s3,-1
  }
  return tot;
    80005570:	0009851b          	sext.w	a0,s3
}
    80005574:	06813083          	ld	ra,104(sp)
    80005578:	06013403          	ld	s0,96(sp)
    8000557c:	05813483          	ld	s1,88(sp)
    80005580:	05013903          	ld	s2,80(sp)
    80005584:	04813983          	ld	s3,72(sp)
    80005588:	04013a03          	ld	s4,64(sp)
    8000558c:	03813a83          	ld	s5,56(sp)
    80005590:	03013b03          	ld	s6,48(sp)
    80005594:	02813b83          	ld	s7,40(sp)
    80005598:	02013c03          	ld	s8,32(sp)
    8000559c:	01813c83          	ld	s9,24(sp)
    800055a0:	01013d03          	ld	s10,16(sp)
    800055a4:	00813d83          	ld	s11,8(sp)
    800055a8:	07010113          	addi	sp,sp,112
    800055ac:	00008067          	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800055b0:	000a8993          	mv	s3,s5
    800055b4:	fbdff06f          	j	80005570 <readi+0x120>
    return 0;
    800055b8:	00000513          	li	a0,0
}
    800055bc:	00008067          	ret

00000000800055c0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800055c0:	04c52783          	lw	a5,76(a0)
    800055c4:	18d7e063          	bltu	a5,a3,80005744 <writei+0x184>
{
    800055c8:	f9010113          	addi	sp,sp,-112
    800055cc:	06113423          	sd	ra,104(sp)
    800055d0:	06813023          	sd	s0,96(sp)
    800055d4:	04913c23          	sd	s1,88(sp)
    800055d8:	05213823          	sd	s2,80(sp)
    800055dc:	05313423          	sd	s3,72(sp)
    800055e0:	05413023          	sd	s4,64(sp)
    800055e4:	03513c23          	sd	s5,56(sp)
    800055e8:	03613823          	sd	s6,48(sp)
    800055ec:	03713423          	sd	s7,40(sp)
    800055f0:	03813023          	sd	s8,32(sp)
    800055f4:	01913c23          	sd	s9,24(sp)
    800055f8:	01a13823          	sd	s10,16(sp)
    800055fc:	01b13423          	sd	s11,8(sp)
    80005600:	07010413          	addi	s0,sp,112
    80005604:	00050a93          	mv	s5,a0
    80005608:	00058b93          	mv	s7,a1
    8000560c:	00060a13          	mv	s4,a2
    80005610:	00068913          	mv	s2,a3
    80005614:	00070b13          	mv	s6,a4
  if(off > ip->size || off + n < off)
    80005618:	00e687bb          	addw	a5,a3,a4
    8000561c:	12d7e863          	bltu	a5,a3,8000574c <writei+0x18c>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80005620:	00043737          	lui	a4,0x43
    80005624:	12f76863          	bltu	a4,a5,80005754 <writei+0x194>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80005628:	100b0a63          	beqz	s6,8000573c <writei+0x17c>
    8000562c:	00000993          	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80005630:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80005634:	fff00c13          	li	s8,-1
    80005638:	0540006f          	j	8000568c <writei+0xcc>
    8000563c:	020d1d93          	slli	s11,s10,0x20
    80005640:	020ddd93          	srli	s11,s11,0x20
    80005644:	05848513          	addi	a0,s1,88
    80005648:	000d8693          	mv	a3,s11
    8000564c:	000a0613          	mv	a2,s4
    80005650:	000b8593          	mv	a1,s7
    80005654:	00e50533          	add	a0,a0,a4
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	070080e7          	jalr	112(ra) # 800036c8 <either_copyin>
    80005660:	07850c63          	beq	a0,s8,800056d8 <writei+0x118>
      brelse(bp);
      break;
    }
    log_write(bp);
    80005664:	00048513          	mv	a0,s1
    80005668:	00001097          	auipc	ra,0x1
    8000566c:	a94080e7          	jalr	-1388(ra) # 800060fc <log_write>
    brelse(bp);
    80005670:	00048513          	mv	a0,s1
    80005674:	fffff097          	auipc	ra,0xfffff
    80005678:	f74080e7          	jalr	-140(ra) # 800045e8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000567c:	013d09bb          	addw	s3,s10,s3
    80005680:	012d093b          	addw	s2,s10,s2
    80005684:	01ba0a33          	add	s4,s4,s11
    80005688:	0569fe63          	bgeu	s3,s6,800056e4 <writei+0x124>
    uint addr = bmap(ip, off/BSIZE);
    8000568c:	00a9559b          	srliw	a1,s2,0xa
    80005690:	000a8513          	mv	a0,s5
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	328080e7          	jalr	808(ra) # 800049bc <bmap>
    8000569c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800056a0:	04058263          	beqz	a1,800056e4 <writei+0x124>
    bp = bread(ip->dev, addr);
    800056a4:	000aa503          	lw	a0,0(s5)
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	da4080e7          	jalr	-604(ra) # 8000444c <bread>
    800056b0:	00050493          	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800056b4:	3ff97713          	andi	a4,s2,1023
    800056b8:	40ec87bb          	subw	a5,s9,a4
    800056bc:	413b06bb          	subw	a3,s6,s3
    800056c0:	00078d13          	mv	s10,a5
    800056c4:	0007879b          	sext.w	a5,a5
    800056c8:	0006861b          	sext.w	a2,a3
    800056cc:	f6f678e3          	bgeu	a2,a5,8000563c <writei+0x7c>
    800056d0:	00068d13          	mv	s10,a3
    800056d4:	f69ff06f          	j	8000563c <writei+0x7c>
      brelse(bp);
    800056d8:	00048513          	mv	a0,s1
    800056dc:	fffff097          	auipc	ra,0xfffff
    800056e0:	f0c080e7          	jalr	-244(ra) # 800045e8 <brelse>
  }

  if(off > ip->size)
    800056e4:	04caa783          	lw	a5,76(s5)
    800056e8:	0127f463          	bgeu	a5,s2,800056f0 <writei+0x130>
    ip->size = off;
    800056ec:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800056f0:	000a8513          	mv	a0,s5
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	688080e7          	jalr	1672(ra) # 80004d7c <iupdate>

  return tot;
    800056fc:	0009851b          	sext.w	a0,s3
}
    80005700:	06813083          	ld	ra,104(sp)
    80005704:	06013403          	ld	s0,96(sp)
    80005708:	05813483          	ld	s1,88(sp)
    8000570c:	05013903          	ld	s2,80(sp)
    80005710:	04813983          	ld	s3,72(sp)
    80005714:	04013a03          	ld	s4,64(sp)
    80005718:	03813a83          	ld	s5,56(sp)
    8000571c:	03013b03          	ld	s6,48(sp)
    80005720:	02813b83          	ld	s7,40(sp)
    80005724:	02013c03          	ld	s8,32(sp)
    80005728:	01813c83          	ld	s9,24(sp)
    8000572c:	01013d03          	ld	s10,16(sp)
    80005730:	00813d83          	ld	s11,8(sp)
    80005734:	07010113          	addi	sp,sp,112
    80005738:	00008067          	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000573c:	000b0993          	mv	s3,s6
    80005740:	fb1ff06f          	j	800056f0 <writei+0x130>
    return -1;
    80005744:	fff00513          	li	a0,-1
}
    80005748:	00008067          	ret
    return -1;
    8000574c:	fff00513          	li	a0,-1
    80005750:	fb1ff06f          	j	80005700 <writei+0x140>
    return -1;
    80005754:	fff00513          	li	a0,-1
    80005758:	fa9ff06f          	j	80005700 <writei+0x140>

000000008000575c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000575c:	ff010113          	addi	sp,sp,-16
    80005760:	00113423          	sd	ra,8(sp)
    80005764:	00813023          	sd	s0,0(sp)
    80005768:	01010413          	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000576c:	00e00613          	li	a2,14
    80005770:	ffffc097          	auipc	ra,0xffffc
    80005774:	be0080e7          	jalr	-1056(ra) # 80001350 <strncmp>
}
    80005778:	00813083          	ld	ra,8(sp)
    8000577c:	00013403          	ld	s0,0(sp)
    80005780:	01010113          	addi	sp,sp,16
    80005784:	00008067          	ret

0000000080005788 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80005788:	fc010113          	addi	sp,sp,-64
    8000578c:	02113c23          	sd	ra,56(sp)
    80005790:	02813823          	sd	s0,48(sp)
    80005794:	02913423          	sd	s1,40(sp)
    80005798:	03213023          	sd	s2,32(sp)
    8000579c:	01313c23          	sd	s3,24(sp)
    800057a0:	01413823          	sd	s4,16(sp)
    800057a4:	04010413          	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800057a8:	04451703          	lh	a4,68(a0)
    800057ac:	00100793          	li	a5,1
    800057b0:	02f71263          	bne	a4,a5,800057d4 <dirlookup+0x4c>
    800057b4:	00050913          	mv	s2,a0
    800057b8:	00058993          	mv	s3,a1
    800057bc:	00060a13          	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800057c0:	04c52783          	lw	a5,76(a0)
    800057c4:	00000493          	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800057c8:	00000513          	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800057cc:	02079a63          	bnez	a5,80005800 <dirlookup+0x78>
    800057d0:	0900006f          	j	80005860 <dirlookup+0xd8>
    panic("dirlookup not DIR");
    800057d4:	00005517          	auipc	a0,0x5
    800057d8:	f4c50513          	addi	a0,a0,-180 # 8000a720 <syscalls+0x1c0>
    800057dc:	ffffb097          	auipc	ra,0xffffb
    800057e0:	2a4080e7          	jalr	676(ra) # 80000a80 <panic>
      panic("dirlookup read");
    800057e4:	00005517          	auipc	a0,0x5
    800057e8:	f5450513          	addi	a0,a0,-172 # 8000a738 <syscalls+0x1d8>
    800057ec:	ffffb097          	auipc	ra,0xffffb
    800057f0:	294080e7          	jalr	660(ra) # 80000a80 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800057f4:	0104849b          	addiw	s1,s1,16
    800057f8:	04c92783          	lw	a5,76(s2)
    800057fc:	06f4f063          	bgeu	s1,a5,8000585c <dirlookup+0xd4>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005800:	01000713          	li	a4,16
    80005804:	00048693          	mv	a3,s1
    80005808:	fc040613          	addi	a2,s0,-64
    8000580c:	00000593          	li	a1,0
    80005810:	00090513          	mv	a0,s2
    80005814:	00000097          	auipc	ra,0x0
    80005818:	c3c080e7          	jalr	-964(ra) # 80005450 <readi>
    8000581c:	01000793          	li	a5,16
    80005820:	fcf512e3          	bne	a0,a5,800057e4 <dirlookup+0x5c>
    if(de.inum == 0)
    80005824:	fc045783          	lhu	a5,-64(s0)
    80005828:	fc0786e3          	beqz	a5,800057f4 <dirlookup+0x6c>
    if(namecmp(name, de.name) == 0){
    8000582c:	fc240593          	addi	a1,s0,-62
    80005830:	00098513          	mv	a0,s3
    80005834:	00000097          	auipc	ra,0x0
    80005838:	f28080e7          	jalr	-216(ra) # 8000575c <namecmp>
    8000583c:	fa051ce3          	bnez	a0,800057f4 <dirlookup+0x6c>
      if(poff)
    80005840:	000a0463          	beqz	s4,80005848 <dirlookup+0xc0>
        *poff = off;
    80005844:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80005848:	fc045583          	lhu	a1,-64(s0)
    8000584c:	00092503          	lw	a0,0(s2)
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	28c080e7          	jalr	652(ra) # 80004adc <iget>
    80005858:	0080006f          	j	80005860 <dirlookup+0xd8>
  return 0;
    8000585c:	00000513          	li	a0,0
}
    80005860:	03813083          	ld	ra,56(sp)
    80005864:	03013403          	ld	s0,48(sp)
    80005868:	02813483          	ld	s1,40(sp)
    8000586c:	02013903          	ld	s2,32(sp)
    80005870:	01813983          	ld	s3,24(sp)
    80005874:	01013a03          	ld	s4,16(sp)
    80005878:	04010113          	addi	sp,sp,64
    8000587c:	00008067          	ret

0000000080005880 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80005880:	fa010113          	addi	sp,sp,-96
    80005884:	04113c23          	sd	ra,88(sp)
    80005888:	04813823          	sd	s0,80(sp)
    8000588c:	04913423          	sd	s1,72(sp)
    80005890:	05213023          	sd	s2,64(sp)
    80005894:	03313c23          	sd	s3,56(sp)
    80005898:	03413823          	sd	s4,48(sp)
    8000589c:	03513423          	sd	s5,40(sp)
    800058a0:	03613023          	sd	s6,32(sp)
    800058a4:	01713c23          	sd	s7,24(sp)
    800058a8:	01813823          	sd	s8,16(sp)
    800058ac:	01913423          	sd	s9,8(sp)
    800058b0:	01a13023          	sd	s10,0(sp)
    800058b4:	06010413          	addi	s0,sp,96
    800058b8:	00050493          	mv	s1,a0
    800058bc:	00058b13          	mv	s6,a1
    800058c0:	00060a93          	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800058c4:	00054703          	lbu	a4,0(a0)
    800058c8:	02f00793          	li	a5,47
    800058cc:	02f70863          	beq	a4,a5,800058fc <namex+0x7c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800058d0:	ffffd097          	auipc	ra,0xffffd
    800058d4:	e18080e7          	jalr	-488(ra) # 800026e8 <myproc>
    800058d8:	15053503          	ld	a0,336(a0)
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	560080e7          	jalr	1376(ra) # 80004e3c <idup>
    800058e4:	00050a13          	mv	s4,a0
  while(*path == '/')
    800058e8:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800058ec:	00d00c93          	li	s9,13
  len = path - s;
    800058f0:	00000b93          	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800058f4:	00100c13          	li	s8,1
    800058f8:	1100006f          	j	80005a08 <namex+0x188>
    ip = iget(ROOTDEV, ROOTINO);
    800058fc:	00100593          	li	a1,1
    80005900:	00100513          	li	a0,1
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	1d8080e7          	jalr	472(ra) # 80004adc <iget>
    8000590c:	00050a13          	mv	s4,a0
    80005910:	fd9ff06f          	j	800058e8 <namex+0x68>
      iunlockput(ip);
    80005914:	000a0513          	mv	a0,s4
    80005918:	00000097          	auipc	ra,0x0
    8000591c:	8bc080e7          	jalr	-1860(ra) # 800051d4 <iunlockput>
      return 0;
    80005920:	00000a13          	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80005924:	000a0513          	mv	a0,s4
    80005928:	05813083          	ld	ra,88(sp)
    8000592c:	05013403          	ld	s0,80(sp)
    80005930:	04813483          	ld	s1,72(sp)
    80005934:	04013903          	ld	s2,64(sp)
    80005938:	03813983          	ld	s3,56(sp)
    8000593c:	03013a03          	ld	s4,48(sp)
    80005940:	02813a83          	ld	s5,40(sp)
    80005944:	02013b03          	ld	s6,32(sp)
    80005948:	01813b83          	ld	s7,24(sp)
    8000594c:	01013c03          	ld	s8,16(sp)
    80005950:	00813c83          	ld	s9,8(sp)
    80005954:	00013d03          	ld	s10,0(sp)
    80005958:	06010113          	addi	sp,sp,96
    8000595c:	00008067          	ret
      iunlock(ip);
    80005960:	000a0513          	mv	a0,s4
    80005964:	fffff097          	auipc	ra,0xfffff
    80005968:	638080e7          	jalr	1592(ra) # 80004f9c <iunlock>
      return ip;
    8000596c:	fb9ff06f          	j	80005924 <namex+0xa4>
      iunlockput(ip);
    80005970:	000a0513          	mv	a0,s4
    80005974:	00000097          	auipc	ra,0x0
    80005978:	860080e7          	jalr	-1952(ra) # 800051d4 <iunlockput>
      return 0;
    8000597c:	00098a13          	mv	s4,s3
    80005980:	fa5ff06f          	j	80005924 <namex+0xa4>
  len = path - s;
    80005984:	40998633          	sub	a2,s3,s1
    80005988:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    8000598c:	0bacde63          	bge	s9,s10,80005a48 <namex+0x1c8>
    memmove(name, s, DIRSIZ);
    80005990:	00e00613          	li	a2,14
    80005994:	00048593          	mv	a1,s1
    80005998:	000a8513          	mv	a0,s5
    8000599c:	ffffc097          	auipc	ra,0xffffc
    800059a0:	908080e7          	jalr	-1784(ra) # 800012a4 <memmove>
    800059a4:	00098493          	mv	s1,s3
  while(*path == '/')
    800059a8:	0004c783          	lbu	a5,0(s1)
    800059ac:	01279863          	bne	a5,s2,800059bc <namex+0x13c>
    path++;
    800059b0:	00148493          	addi	s1,s1,1
  while(*path == '/')
    800059b4:	0004c783          	lbu	a5,0(s1)
    800059b8:	ff278ce3          	beq	a5,s2,800059b0 <namex+0x130>
    ilock(ip);
    800059bc:	000a0513          	mv	a0,s4
    800059c0:	fffff097          	auipc	ra,0xfffff
    800059c4:	4d8080e7          	jalr	1240(ra) # 80004e98 <ilock>
    if(ip->type != T_DIR){
    800059c8:	044a1783          	lh	a5,68(s4)
    800059cc:	f58794e3          	bne	a5,s8,80005914 <namex+0x94>
    if(nameiparent && *path == '\0'){
    800059d0:	000b0663          	beqz	s6,800059dc <namex+0x15c>
    800059d4:	0004c783          	lbu	a5,0(s1)
    800059d8:	f80784e3          	beqz	a5,80005960 <namex+0xe0>
    if((next = dirlookup(ip, name, 0)) == 0){
    800059dc:	000b8613          	mv	a2,s7
    800059e0:	000a8593          	mv	a1,s5
    800059e4:	000a0513          	mv	a0,s4
    800059e8:	00000097          	auipc	ra,0x0
    800059ec:	da0080e7          	jalr	-608(ra) # 80005788 <dirlookup>
    800059f0:	00050993          	mv	s3,a0
    800059f4:	f6050ee3          	beqz	a0,80005970 <namex+0xf0>
    iunlockput(ip);
    800059f8:	000a0513          	mv	a0,s4
    800059fc:	fffff097          	auipc	ra,0xfffff
    80005a00:	7d8080e7          	jalr	2008(ra) # 800051d4 <iunlockput>
    ip = next;
    80005a04:	00098a13          	mv	s4,s3
  while(*path == '/')
    80005a08:	0004c783          	lbu	a5,0(s1)
    80005a0c:	01279863          	bne	a5,s2,80005a1c <namex+0x19c>
    path++;
    80005a10:	00148493          	addi	s1,s1,1
  while(*path == '/')
    80005a14:	0004c783          	lbu	a5,0(s1)
    80005a18:	ff278ce3          	beq	a5,s2,80005a10 <namex+0x190>
  if(*path == 0)
    80005a1c:	04078863          	beqz	a5,80005a6c <namex+0x1ec>
  while(*path != '/' && *path != 0)
    80005a20:	0004c783          	lbu	a5,0(s1)
    80005a24:	00048993          	mv	s3,s1
  len = path - s;
    80005a28:	000b8d13          	mv	s10,s7
    80005a2c:	000b8613          	mv	a2,s7
  while(*path != '/' && *path != 0)
    80005a30:	01278c63          	beq	a5,s2,80005a48 <namex+0x1c8>
    80005a34:	f40788e3          	beqz	a5,80005984 <namex+0x104>
    path++;
    80005a38:	00198993          	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80005a3c:	0009c783          	lbu	a5,0(s3)
    80005a40:	ff279ae3          	bne	a5,s2,80005a34 <namex+0x1b4>
    80005a44:	f41ff06f          	j	80005984 <namex+0x104>
    memmove(name, s, len);
    80005a48:	0006061b          	sext.w	a2,a2
    80005a4c:	00048593          	mv	a1,s1
    80005a50:	000a8513          	mv	a0,s5
    80005a54:	ffffc097          	auipc	ra,0xffffc
    80005a58:	850080e7          	jalr	-1968(ra) # 800012a4 <memmove>
    name[len] = 0;
    80005a5c:	01aa8d33          	add	s10,s5,s10
    80005a60:	000d0023          	sb	zero,0(s10) # 1000 <_entry-0x7ffff000>
    80005a64:	00098493          	mv	s1,s3
    80005a68:	f41ff06f          	j	800059a8 <namex+0x128>
  if(nameiparent){
    80005a6c:	ea0b0ce3          	beqz	s6,80005924 <namex+0xa4>
    iput(ip);
    80005a70:	000a0513          	mv	a0,s4
    80005a74:	fffff097          	auipc	ra,0xfffff
    80005a78:	684080e7          	jalr	1668(ra) # 800050f8 <iput>
    return 0;
    80005a7c:	00000a13          	li	s4,0
    80005a80:	ea5ff06f          	j	80005924 <namex+0xa4>

0000000080005a84 <dirlink>:
{
    80005a84:	fc010113          	addi	sp,sp,-64
    80005a88:	02113c23          	sd	ra,56(sp)
    80005a8c:	02813823          	sd	s0,48(sp)
    80005a90:	02913423          	sd	s1,40(sp)
    80005a94:	03213023          	sd	s2,32(sp)
    80005a98:	01313c23          	sd	s3,24(sp)
    80005a9c:	01413823          	sd	s4,16(sp)
    80005aa0:	04010413          	addi	s0,sp,64
    80005aa4:	00050913          	mv	s2,a0
    80005aa8:	00058a13          	mv	s4,a1
    80005aac:	00060993          	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80005ab0:	00000613          	li	a2,0
    80005ab4:	00000097          	auipc	ra,0x0
    80005ab8:	cd4080e7          	jalr	-812(ra) # 80005788 <dirlookup>
    80005abc:	0a051463          	bnez	a0,80005b64 <dirlink+0xe0>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80005ac0:	04c92483          	lw	s1,76(s2)
    80005ac4:	04048063          	beqz	s1,80005b04 <dirlink+0x80>
    80005ac8:	00000493          	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005acc:	01000713          	li	a4,16
    80005ad0:	00048693          	mv	a3,s1
    80005ad4:	fc040613          	addi	a2,s0,-64
    80005ad8:	00000593          	li	a1,0
    80005adc:	00090513          	mv	a0,s2
    80005ae0:	00000097          	auipc	ra,0x0
    80005ae4:	970080e7          	jalr	-1680(ra) # 80005450 <readi>
    80005ae8:	01000793          	li	a5,16
    80005aec:	08f51463          	bne	a0,a5,80005b74 <dirlink+0xf0>
    if(de.inum == 0)
    80005af0:	fc045783          	lhu	a5,-64(s0)
    80005af4:	00078863          	beqz	a5,80005b04 <dirlink+0x80>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80005af8:	0104849b          	addiw	s1,s1,16
    80005afc:	04c92783          	lw	a5,76(s2)
    80005b00:	fcf4e6e3          	bltu	s1,a5,80005acc <dirlink+0x48>
  strncpy(de.name, name, DIRSIZ);
    80005b04:	00e00613          	li	a2,14
    80005b08:	000a0593          	mv	a1,s4
    80005b0c:	fc240513          	addi	a0,s0,-62
    80005b10:	ffffc097          	auipc	ra,0xffffc
    80005b14:	8a4080e7          	jalr	-1884(ra) # 800013b4 <strncpy>
  de.inum = inum;
    80005b18:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b1c:	01000713          	li	a4,16
    80005b20:	00048693          	mv	a3,s1
    80005b24:	fc040613          	addi	a2,s0,-64
    80005b28:	00000593          	li	a1,0
    80005b2c:	00090513          	mv	a0,s2
    80005b30:	00000097          	auipc	ra,0x0
    80005b34:	a90080e7          	jalr	-1392(ra) # 800055c0 <writei>
    80005b38:	ff050513          	addi	a0,a0,-16
    80005b3c:	00a03533          	snez	a0,a0
    80005b40:	40a00533          	neg	a0,a0
}
    80005b44:	03813083          	ld	ra,56(sp)
    80005b48:	03013403          	ld	s0,48(sp)
    80005b4c:	02813483          	ld	s1,40(sp)
    80005b50:	02013903          	ld	s2,32(sp)
    80005b54:	01813983          	ld	s3,24(sp)
    80005b58:	01013a03          	ld	s4,16(sp)
    80005b5c:	04010113          	addi	sp,sp,64
    80005b60:	00008067          	ret
    iput(ip);
    80005b64:	fffff097          	auipc	ra,0xfffff
    80005b68:	594080e7          	jalr	1428(ra) # 800050f8 <iput>
    return -1;
    80005b6c:	fff00513          	li	a0,-1
    80005b70:	fd5ff06f          	j	80005b44 <dirlink+0xc0>
      panic("dirlink read");
    80005b74:	00005517          	auipc	a0,0x5
    80005b78:	bd450513          	addi	a0,a0,-1068 # 8000a748 <syscalls+0x1e8>
    80005b7c:	ffffb097          	auipc	ra,0xffffb
    80005b80:	f04080e7          	jalr	-252(ra) # 80000a80 <panic>

0000000080005b84 <namei>:

struct inode*
namei(char *path)
{
    80005b84:	fe010113          	addi	sp,sp,-32
    80005b88:	00113c23          	sd	ra,24(sp)
    80005b8c:	00813823          	sd	s0,16(sp)
    80005b90:	02010413          	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80005b94:	fe040613          	addi	a2,s0,-32
    80005b98:	00000593          	li	a1,0
    80005b9c:	00000097          	auipc	ra,0x0
    80005ba0:	ce4080e7          	jalr	-796(ra) # 80005880 <namex>
}
    80005ba4:	01813083          	ld	ra,24(sp)
    80005ba8:	01013403          	ld	s0,16(sp)
    80005bac:	02010113          	addi	sp,sp,32
    80005bb0:	00008067          	ret

0000000080005bb4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80005bb4:	ff010113          	addi	sp,sp,-16
    80005bb8:	00113423          	sd	ra,8(sp)
    80005bbc:	00813023          	sd	s0,0(sp)
    80005bc0:	01010413          	addi	s0,sp,16
    80005bc4:	00058613          	mv	a2,a1
  return namex(path, 1, name);
    80005bc8:	00100593          	li	a1,1
    80005bcc:	00000097          	auipc	ra,0x0
    80005bd0:	cb4080e7          	jalr	-844(ra) # 80005880 <namex>
}
    80005bd4:	00813083          	ld	ra,8(sp)
    80005bd8:	00013403          	ld	s0,0(sp)
    80005bdc:	01010113          	addi	sp,sp,16
    80005be0:	00008067          	ret

0000000080005be4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80005be4:	fe010113          	addi	sp,sp,-32
    80005be8:	00113c23          	sd	ra,24(sp)
    80005bec:	00813823          	sd	s0,16(sp)
    80005bf0:	00913423          	sd	s1,8(sp)
    80005bf4:	01213023          	sd	s2,0(sp)
    80005bf8:	02010413          	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80005bfc:	0001d917          	auipc	s2,0x1d
    80005c00:	e9c90913          	addi	s2,s2,-356 # 80022a98 <log>
    80005c04:	01892583          	lw	a1,24(s2)
    80005c08:	02492503          	lw	a0,36(s2)
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	840080e7          	jalr	-1984(ra) # 8000444c <bread>
    80005c14:	00050493          	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80005c18:	02892683          	lw	a3,40(s2)
    80005c1c:	04d52c23          	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80005c20:	02d05e63          	blez	a3,80005c5c <write_head+0x78>
    80005c24:	0001d797          	auipc	a5,0x1d
    80005c28:	ea078793          	addi	a5,a5,-352 # 80022ac4 <log+0x2c>
    80005c2c:	05c50713          	addi	a4,a0,92
    80005c30:	fff6869b          	addiw	a3,a3,-1
    80005c34:	02069613          	slli	a2,a3,0x20
    80005c38:	01e65693          	srli	a3,a2,0x1e
    80005c3c:	0001d617          	auipc	a2,0x1d
    80005c40:	e8c60613          	addi	a2,a2,-372 # 80022ac8 <log+0x30>
    80005c44:	00c686b3          	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80005c48:	0007a603          	lw	a2,0(a5)
    80005c4c:	00c72023          	sw	a2,0(a4) # 43000 <_entry-0x7ffbd000>
  for (i = 0; i < log.lh.n; i++) {
    80005c50:	00478793          	addi	a5,a5,4
    80005c54:	00470713          	addi	a4,a4,4
    80005c58:	fed798e3          	bne	a5,a3,80005c48 <write_head+0x64>
  }
  bwrite(buf);
    80005c5c:	00048513          	mv	a0,s1
    80005c60:	fffff097          	auipc	ra,0xfffff
    80005c64:	92c080e7          	jalr	-1748(ra) # 8000458c <bwrite>
  brelse(buf);
    80005c68:	00048513          	mv	a0,s1
    80005c6c:	fffff097          	auipc	ra,0xfffff
    80005c70:	97c080e7          	jalr	-1668(ra) # 800045e8 <brelse>
}
    80005c74:	01813083          	ld	ra,24(sp)
    80005c78:	01013403          	ld	s0,16(sp)
    80005c7c:	00813483          	ld	s1,8(sp)
    80005c80:	00013903          	ld	s2,0(sp)
    80005c84:	02010113          	addi	sp,sp,32
    80005c88:	00008067          	ret

0000000080005c8c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80005c8c:	0001d797          	auipc	a5,0x1d
    80005c90:	e347a783          	lw	a5,-460(a5) # 80022ac0 <log+0x28>
    80005c94:	12f05463          	blez	a5,80005dbc <install_trans+0x130>
{
    80005c98:	fb010113          	addi	sp,sp,-80
    80005c9c:	04113423          	sd	ra,72(sp)
    80005ca0:	04813023          	sd	s0,64(sp)
    80005ca4:	02913c23          	sd	s1,56(sp)
    80005ca8:	03213823          	sd	s2,48(sp)
    80005cac:	03313423          	sd	s3,40(sp)
    80005cb0:	03413023          	sd	s4,32(sp)
    80005cb4:	01513c23          	sd	s5,24(sp)
    80005cb8:	01613823          	sd	s6,16(sp)
    80005cbc:	01713423          	sd	s7,8(sp)
    80005cc0:	05010413          	addi	s0,sp,80
    80005cc4:	00050b13          	mv	s6,a0
    80005cc8:	0001da97          	auipc	s5,0x1d
    80005ccc:	dfca8a93          	addi	s5,s5,-516 # 80022ac4 <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80005cd0:	00000993          	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80005cd4:	00005b97          	auipc	s7,0x5
    80005cd8:	a84b8b93          	addi	s7,s7,-1404 # 8000a758 <syscalls+0x1f8>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80005cdc:	0001da17          	auipc	s4,0x1d
    80005ce0:	dbca0a13          	addi	s4,s4,-580 # 80022a98 <log>
    80005ce4:	0440006f          	j	80005d28 <install_trans+0x9c>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80005ce8:	000aa603          	lw	a2,0(s5)
    80005cec:	00098593          	mv	a1,s3
    80005cf0:	000b8513          	mv	a0,s7
    80005cf4:	ffffb097          	auipc	ra,0xffffb
    80005cf8:	9b4080e7          	jalr	-1612(ra) # 800006a8 <printf>
    80005cfc:	0300006f          	j	80005d2c <install_trans+0xa0>
    brelse(lbuf);
    80005d00:	00090513          	mv	a0,s2
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	8e4080e7          	jalr	-1820(ra) # 800045e8 <brelse>
    brelse(dbuf);
    80005d0c:	00048513          	mv	a0,s1
    80005d10:	fffff097          	auipc	ra,0xfffff
    80005d14:	8d8080e7          	jalr	-1832(ra) # 800045e8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80005d18:	0019899b          	addiw	s3,s3,1
    80005d1c:	004a8a93          	addi	s5,s5,4
    80005d20:	028a2783          	lw	a5,40(s4)
    80005d24:	06f9d663          	bge	s3,a5,80005d90 <install_trans+0x104>
    if(recovering) {
    80005d28:	fc0b10e3          	bnez	s6,80005ce8 <install_trans+0x5c>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80005d2c:	018a2583          	lw	a1,24(s4)
    80005d30:	013585bb          	addw	a1,a1,s3
    80005d34:	0015859b          	addiw	a1,a1,1
    80005d38:	024a2503          	lw	a0,36(s4)
    80005d3c:	ffffe097          	auipc	ra,0xffffe
    80005d40:	710080e7          	jalr	1808(ra) # 8000444c <bread>
    80005d44:	00050913          	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80005d48:	000aa583          	lw	a1,0(s5)
    80005d4c:	024a2503          	lw	a0,36(s4)
    80005d50:	ffffe097          	auipc	ra,0xffffe
    80005d54:	6fc080e7          	jalr	1788(ra) # 8000444c <bread>
    80005d58:	00050493          	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80005d5c:	40000613          	li	a2,1024
    80005d60:	05890593          	addi	a1,s2,88
    80005d64:	05850513          	addi	a0,a0,88
    80005d68:	ffffb097          	auipc	ra,0xffffb
    80005d6c:	53c080e7          	jalr	1340(ra) # 800012a4 <memmove>
    bwrite(dbuf);  // write dst to disk
    80005d70:	00048513          	mv	a0,s1
    80005d74:	fffff097          	auipc	ra,0xfffff
    80005d78:	818080e7          	jalr	-2024(ra) # 8000458c <bwrite>
    if(recovering == 0)
    80005d7c:	f80b12e3          	bnez	s6,80005d00 <install_trans+0x74>
      bunpin(dbuf);
    80005d80:	00048513          	mv	a0,s1
    80005d84:	fffff097          	auipc	ra,0xfffff
    80005d88:	994080e7          	jalr	-1644(ra) # 80004718 <bunpin>
    80005d8c:	f75ff06f          	j	80005d00 <install_trans+0x74>
}
    80005d90:	04813083          	ld	ra,72(sp)
    80005d94:	04013403          	ld	s0,64(sp)
    80005d98:	03813483          	ld	s1,56(sp)
    80005d9c:	03013903          	ld	s2,48(sp)
    80005da0:	02813983          	ld	s3,40(sp)
    80005da4:	02013a03          	ld	s4,32(sp)
    80005da8:	01813a83          	ld	s5,24(sp)
    80005dac:	01013b03          	ld	s6,16(sp)
    80005db0:	00813b83          	ld	s7,8(sp)
    80005db4:	05010113          	addi	sp,sp,80
    80005db8:	00008067          	ret
    80005dbc:	00008067          	ret

0000000080005dc0 <initlog>:
{
    80005dc0:	fd010113          	addi	sp,sp,-48
    80005dc4:	02113423          	sd	ra,40(sp)
    80005dc8:	02813023          	sd	s0,32(sp)
    80005dcc:	00913c23          	sd	s1,24(sp)
    80005dd0:	01213823          	sd	s2,16(sp)
    80005dd4:	01313423          	sd	s3,8(sp)
    80005dd8:	03010413          	addi	s0,sp,48
    80005ddc:	00050913          	mv	s2,a0
    80005de0:	00058993          	mv	s3,a1
  initlock(&log.lock, "log");
    80005de4:	0001d497          	auipc	s1,0x1d
    80005de8:	cb448493          	addi	s1,s1,-844 # 80022a98 <log>
    80005dec:	00005597          	auipc	a1,0x5
    80005df0:	98c58593          	addi	a1,a1,-1652 # 8000a778 <syscalls+0x218>
    80005df4:	00048513          	mv	a0,s1
    80005df8:	ffffb097          	auipc	ra,0xffffb
    80005dfc:	1dc080e7          	jalr	476(ra) # 80000fd4 <initlock>
  log.start = sb->logstart;
    80005e00:	0149a583          	lw	a1,20(s3)
    80005e04:	00b4ac23          	sw	a1,24(s1)
  log.dev = dev;
    80005e08:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80005e0c:	00090513          	mv	a0,s2
    80005e10:	ffffe097          	auipc	ra,0xffffe
    80005e14:	63c080e7          	jalr	1596(ra) # 8000444c <bread>
  log.lh.n = lh->n;
    80005e18:	05852683          	lw	a3,88(a0)
    80005e1c:	02d4a423          	sw	a3,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    80005e20:	02d05c63          	blez	a3,80005e58 <initlog+0x98>
    80005e24:	05c50793          	addi	a5,a0,92
    80005e28:	0001d717          	auipc	a4,0x1d
    80005e2c:	c9c70713          	addi	a4,a4,-868 # 80022ac4 <log+0x2c>
    80005e30:	fff6869b          	addiw	a3,a3,-1
    80005e34:	02069613          	slli	a2,a3,0x20
    80005e38:	01e65693          	srli	a3,a2,0x1e
    80005e3c:	06050613          	addi	a2,a0,96
    80005e40:	00c686b3          	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80005e44:	0007a603          	lw	a2,0(a5)
    80005e48:	00c72023          	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80005e4c:	00478793          	addi	a5,a5,4
    80005e50:	00470713          	addi	a4,a4,4
    80005e54:	fed798e3          	bne	a5,a3,80005e44 <initlog+0x84>
  brelse(buf);
    80005e58:	ffffe097          	auipc	ra,0xffffe
    80005e5c:	790080e7          	jalr	1936(ra) # 800045e8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80005e60:	00100513          	li	a0,1
    80005e64:	00000097          	auipc	ra,0x0
    80005e68:	e28080e7          	jalr	-472(ra) # 80005c8c <install_trans>
  log.lh.n = 0;
    80005e6c:	0001d797          	auipc	a5,0x1d
    80005e70:	c407aa23          	sw	zero,-940(a5) # 80022ac0 <log+0x28>
  write_head(); // clear the log
    80005e74:	00000097          	auipc	ra,0x0
    80005e78:	d70080e7          	jalr	-656(ra) # 80005be4 <write_head>
}
    80005e7c:	02813083          	ld	ra,40(sp)
    80005e80:	02013403          	ld	s0,32(sp)
    80005e84:	01813483          	ld	s1,24(sp)
    80005e88:	01013903          	ld	s2,16(sp)
    80005e8c:	00813983          	ld	s3,8(sp)
    80005e90:	03010113          	addi	sp,sp,48
    80005e94:	00008067          	ret

0000000080005e98 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80005e98:	fe010113          	addi	sp,sp,-32
    80005e9c:	00113c23          	sd	ra,24(sp)
    80005ea0:	00813823          	sd	s0,16(sp)
    80005ea4:	00913423          	sd	s1,8(sp)
    80005ea8:	01213023          	sd	s2,0(sp)
    80005eac:	02010413          	addi	s0,sp,32
  acquire(&log.lock);
    80005eb0:	0001d517          	auipc	a0,0x1d
    80005eb4:	be850513          	addi	a0,a0,-1048 # 80022a98 <log>
    80005eb8:	ffffb097          	auipc	ra,0xffffb
    80005ebc:	200080e7          	jalr	512(ra) # 800010b8 <acquire>
  while(1){
    if(log.committing){
    80005ec0:	0001d497          	auipc	s1,0x1d
    80005ec4:	bd848493          	addi	s1,s1,-1064 # 80022a98 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80005ec8:	01e00913          	li	s2,30
    80005ecc:	0140006f          	j	80005ee0 <begin_op+0x48>
      sleep(&log, &log.lock);
    80005ed0:	00048593          	mv	a1,s1
    80005ed4:	00048513          	mv	a0,s1
    80005ed8:	ffffd097          	auipc	ra,0xffffd
    80005edc:	1c8080e7          	jalr	456(ra) # 800030a0 <sleep>
    if(log.committing){
    80005ee0:	0204a783          	lw	a5,32(s1)
    80005ee4:	fe0796e3          	bnez	a5,80005ed0 <begin_op+0x38>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80005ee8:	01c4a703          	lw	a4,28(s1)
    80005eec:	0017071b          	addiw	a4,a4,1
    80005ef0:	0007069b          	sext.w	a3,a4
    80005ef4:	0027179b          	slliw	a5,a4,0x2
    80005ef8:	00e787bb          	addw	a5,a5,a4
    80005efc:	0017979b          	slliw	a5,a5,0x1
    80005f00:	0284a703          	lw	a4,40(s1)
    80005f04:	00e787bb          	addw	a5,a5,a4
    80005f08:	00f95c63          	bge	s2,a5,80005f20 <begin_op+0x88>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80005f0c:	00048593          	mv	a1,s1
    80005f10:	00048513          	mv	a0,s1
    80005f14:	ffffd097          	auipc	ra,0xffffd
    80005f18:	18c080e7          	jalr	396(ra) # 800030a0 <sleep>
    80005f1c:	fc5ff06f          	j	80005ee0 <begin_op+0x48>
    } else {
      log.outstanding += 1;
    80005f20:	0001d517          	auipc	a0,0x1d
    80005f24:	b7850513          	addi	a0,a0,-1160 # 80022a98 <log>
    80005f28:	00d52e23          	sw	a3,28(a0)
      release(&log.lock);
    80005f2c:	ffffb097          	auipc	ra,0xffffb
    80005f30:	284080e7          	jalr	644(ra) # 800011b0 <release>
      break;
    }
  }
}
    80005f34:	01813083          	ld	ra,24(sp)
    80005f38:	01013403          	ld	s0,16(sp)
    80005f3c:	00813483          	ld	s1,8(sp)
    80005f40:	00013903          	ld	s2,0(sp)
    80005f44:	02010113          	addi	sp,sp,32
    80005f48:	00008067          	ret

0000000080005f4c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80005f4c:	fc010113          	addi	sp,sp,-64
    80005f50:	02113c23          	sd	ra,56(sp)
    80005f54:	02813823          	sd	s0,48(sp)
    80005f58:	02913423          	sd	s1,40(sp)
    80005f5c:	03213023          	sd	s2,32(sp)
    80005f60:	01313c23          	sd	s3,24(sp)
    80005f64:	01413823          	sd	s4,16(sp)
    80005f68:	01513423          	sd	s5,8(sp)
    80005f6c:	04010413          	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80005f70:	0001d497          	auipc	s1,0x1d
    80005f74:	b2848493          	addi	s1,s1,-1240 # 80022a98 <log>
    80005f78:	00048513          	mv	a0,s1
    80005f7c:	ffffb097          	auipc	ra,0xffffb
    80005f80:	13c080e7          	jalr	316(ra) # 800010b8 <acquire>
  log.outstanding -= 1;
    80005f84:	01c4a783          	lw	a5,28(s1)
    80005f88:	fff7879b          	addiw	a5,a5,-1
    80005f8c:	0007891b          	sext.w	s2,a5
    80005f90:	00f4ae23          	sw	a5,28(s1)
  if(log.committing)
    80005f94:	0204a783          	lw	a5,32(s1)
    80005f98:	06079063          	bnez	a5,80005ff8 <end_op+0xac>
    panic("log.committing");
  if(log.outstanding == 0){
    80005f9c:	06091663          	bnez	s2,80006008 <end_op+0xbc>
    do_commit = 1;
    log.committing = 1;
    80005fa0:	0001d497          	auipc	s1,0x1d
    80005fa4:	af848493          	addi	s1,s1,-1288 # 80022a98 <log>
    80005fa8:	00100793          	li	a5,1
    80005fac:	02f4a023          	sw	a5,32(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80005fb0:	00048513          	mv	a0,s1
    80005fb4:	ffffb097          	auipc	ra,0xffffb
    80005fb8:	1fc080e7          	jalr	508(ra) # 800011b0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80005fbc:	0284a783          	lw	a5,40(s1)
    80005fc0:	08f04663          	bgtz	a5,8000604c <end_op+0x100>
    acquire(&log.lock);
    80005fc4:	0001d497          	auipc	s1,0x1d
    80005fc8:	ad448493          	addi	s1,s1,-1324 # 80022a98 <log>
    80005fcc:	00048513          	mv	a0,s1
    80005fd0:	ffffb097          	auipc	ra,0xffffb
    80005fd4:	0e8080e7          	jalr	232(ra) # 800010b8 <acquire>
    log.committing = 0;
    80005fd8:	0204a023          	sw	zero,32(s1)
    wakeup(&log);
    80005fdc:	00048513          	mv	a0,s1
    80005fe0:	ffffd097          	auipc	ra,0xffffd
    80005fe4:	150080e7          	jalr	336(ra) # 80003130 <wakeup>
    release(&log.lock);
    80005fe8:	00048513          	mv	a0,s1
    80005fec:	ffffb097          	auipc	ra,0xffffb
    80005ff0:	1c4080e7          	jalr	452(ra) # 800011b0 <release>
}
    80005ff4:	0340006f          	j	80006028 <end_op+0xdc>
    panic("log.committing");
    80005ff8:	00004517          	auipc	a0,0x4
    80005ffc:	78850513          	addi	a0,a0,1928 # 8000a780 <syscalls+0x220>
    80006000:	ffffb097          	auipc	ra,0xffffb
    80006004:	a80080e7          	jalr	-1408(ra) # 80000a80 <panic>
    wakeup(&log);
    80006008:	0001d497          	auipc	s1,0x1d
    8000600c:	a9048493          	addi	s1,s1,-1392 # 80022a98 <log>
    80006010:	00048513          	mv	a0,s1
    80006014:	ffffd097          	auipc	ra,0xffffd
    80006018:	11c080e7          	jalr	284(ra) # 80003130 <wakeup>
  release(&log.lock);
    8000601c:	00048513          	mv	a0,s1
    80006020:	ffffb097          	auipc	ra,0xffffb
    80006024:	190080e7          	jalr	400(ra) # 800011b0 <release>
}
    80006028:	03813083          	ld	ra,56(sp)
    8000602c:	03013403          	ld	s0,48(sp)
    80006030:	02813483          	ld	s1,40(sp)
    80006034:	02013903          	ld	s2,32(sp)
    80006038:	01813983          	ld	s3,24(sp)
    8000603c:	01013a03          	ld	s4,16(sp)
    80006040:	00813a83          	ld	s5,8(sp)
    80006044:	04010113          	addi	sp,sp,64
    80006048:	00008067          	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000604c:	0001da97          	auipc	s5,0x1d
    80006050:	a78a8a93          	addi	s5,s5,-1416 # 80022ac4 <log+0x2c>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80006054:	0001da17          	auipc	s4,0x1d
    80006058:	a44a0a13          	addi	s4,s4,-1468 # 80022a98 <log>
    8000605c:	018a2583          	lw	a1,24(s4)
    80006060:	012585bb          	addw	a1,a1,s2
    80006064:	0015859b          	addiw	a1,a1,1
    80006068:	024a2503          	lw	a0,36(s4)
    8000606c:	ffffe097          	auipc	ra,0xffffe
    80006070:	3e0080e7          	jalr	992(ra) # 8000444c <bread>
    80006074:	00050493          	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80006078:	000aa583          	lw	a1,0(s5)
    8000607c:	024a2503          	lw	a0,36(s4)
    80006080:	ffffe097          	auipc	ra,0xffffe
    80006084:	3cc080e7          	jalr	972(ra) # 8000444c <bread>
    80006088:	00050993          	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000608c:	40000613          	li	a2,1024
    80006090:	05850593          	addi	a1,a0,88
    80006094:	05848513          	addi	a0,s1,88
    80006098:	ffffb097          	auipc	ra,0xffffb
    8000609c:	20c080e7          	jalr	524(ra) # 800012a4 <memmove>
    bwrite(to);  // write the log
    800060a0:	00048513          	mv	a0,s1
    800060a4:	ffffe097          	auipc	ra,0xffffe
    800060a8:	4e8080e7          	jalr	1256(ra) # 8000458c <bwrite>
    brelse(from);
    800060ac:	00098513          	mv	a0,s3
    800060b0:	ffffe097          	auipc	ra,0xffffe
    800060b4:	538080e7          	jalr	1336(ra) # 800045e8 <brelse>
    brelse(to);
    800060b8:	00048513          	mv	a0,s1
    800060bc:	ffffe097          	auipc	ra,0xffffe
    800060c0:	52c080e7          	jalr	1324(ra) # 800045e8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800060c4:	0019091b          	addiw	s2,s2,1
    800060c8:	004a8a93          	addi	s5,s5,4
    800060cc:	028a2783          	lw	a5,40(s4)
    800060d0:	f8f946e3          	blt	s2,a5,8000605c <end_op+0x110>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800060d4:	00000097          	auipc	ra,0x0
    800060d8:	b10080e7          	jalr	-1264(ra) # 80005be4 <write_head>
    install_trans(0); // Now install writes to home locations
    800060dc:	00000513          	li	a0,0
    800060e0:	00000097          	auipc	ra,0x0
    800060e4:	bac080e7          	jalr	-1108(ra) # 80005c8c <install_trans>
    log.lh.n = 0;
    800060e8:	0001d797          	auipc	a5,0x1d
    800060ec:	9c07ac23          	sw	zero,-1576(a5) # 80022ac0 <log+0x28>
    write_head();    // Erase the transaction from the log
    800060f0:	00000097          	auipc	ra,0x0
    800060f4:	af4080e7          	jalr	-1292(ra) # 80005be4 <write_head>
    800060f8:	ecdff06f          	j	80005fc4 <end_op+0x78>

00000000800060fc <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800060fc:	fe010113          	addi	sp,sp,-32
    80006100:	00113c23          	sd	ra,24(sp)
    80006104:	00813823          	sd	s0,16(sp)
    80006108:	00913423          	sd	s1,8(sp)
    8000610c:	01213023          	sd	s2,0(sp)
    80006110:	02010413          	addi	s0,sp,32
    80006114:	00050493          	mv	s1,a0
  int i;

  acquire(&log.lock);
    80006118:	0001d917          	auipc	s2,0x1d
    8000611c:	98090913          	addi	s2,s2,-1664 # 80022a98 <log>
    80006120:	00090513          	mv	a0,s2
    80006124:	ffffb097          	auipc	ra,0xffffb
    80006128:	f94080e7          	jalr	-108(ra) # 800010b8 <acquire>
  if (log.lh.n >= LOGBLOCKS)
    8000612c:	02892603          	lw	a2,40(s2)
    80006130:	01d00793          	li	a5,29
    80006134:	06c7ce63          	blt	a5,a2,800061b0 <log_write+0xb4>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80006138:	0001d797          	auipc	a5,0x1d
    8000613c:	97c7a783          	lw	a5,-1668(a5) # 80022ab4 <log+0x1c>
    80006140:	08f05063          	blez	a5,800061c0 <log_write+0xc4>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80006144:	00000793          	li	a5,0
    80006148:	08c05463          	blez	a2,800061d0 <log_write+0xd4>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000614c:	00c4a583          	lw	a1,12(s1)
    80006150:	0001d717          	auipc	a4,0x1d
    80006154:	97470713          	addi	a4,a4,-1676 # 80022ac4 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    80006158:	00000793          	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000615c:	00072683          	lw	a3,0(a4)
    80006160:	06b68863          	beq	a3,a1,800061d0 <log_write+0xd4>
  for (i = 0; i < log.lh.n; i++) {
    80006164:	0017879b          	addiw	a5,a5,1
    80006168:	00470713          	addi	a4,a4,4
    8000616c:	fef618e3          	bne	a2,a5,8000615c <log_write+0x60>
      break;
  }
  log.lh.block[i] = b->blockno;
    80006170:	00860613          	addi	a2,a2,8
    80006174:	00261613          	slli	a2,a2,0x2
    80006178:	0001d797          	auipc	a5,0x1d
    8000617c:	92078793          	addi	a5,a5,-1760 # 80022a98 <log>
    80006180:	00c787b3          	add	a5,a5,a2
    80006184:	00c4a703          	lw	a4,12(s1)
    80006188:	00e7a623          	sw	a4,12(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000618c:	00048513          	mv	a0,s1
    80006190:	ffffe097          	auipc	ra,0xffffe
    80006194:	530080e7          	jalr	1328(ra) # 800046c0 <bpin>
    log.lh.n++;
    80006198:	0001d717          	auipc	a4,0x1d
    8000619c:	90070713          	addi	a4,a4,-1792 # 80022a98 <log>
    800061a0:	02872783          	lw	a5,40(a4)
    800061a4:	0017879b          	addiw	a5,a5,1
    800061a8:	02f72423          	sw	a5,40(a4)
    800061ac:	0440006f          	j	800061f0 <log_write+0xf4>
    panic("too big a transaction");
    800061b0:	00004517          	auipc	a0,0x4
    800061b4:	5e050513          	addi	a0,a0,1504 # 8000a790 <syscalls+0x230>
    800061b8:	ffffb097          	auipc	ra,0xffffb
    800061bc:	8c8080e7          	jalr	-1848(ra) # 80000a80 <panic>
    panic("log_write outside of trans");
    800061c0:	00004517          	auipc	a0,0x4
    800061c4:	5e850513          	addi	a0,a0,1512 # 8000a7a8 <syscalls+0x248>
    800061c8:	ffffb097          	auipc	ra,0xffffb
    800061cc:	8b8080e7          	jalr	-1864(ra) # 80000a80 <panic>
  log.lh.block[i] = b->blockno;
    800061d0:	00878693          	addi	a3,a5,8
    800061d4:	00269693          	slli	a3,a3,0x2
    800061d8:	0001d717          	auipc	a4,0x1d
    800061dc:	8c070713          	addi	a4,a4,-1856 # 80022a98 <log>
    800061e0:	00d70733          	add	a4,a4,a3
    800061e4:	00c4a683          	lw	a3,12(s1)
    800061e8:	00d72623          	sw	a3,12(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800061ec:	faf600e3          	beq	a2,a5,8000618c <log_write+0x90>
  }
  release(&log.lock);
    800061f0:	0001d517          	auipc	a0,0x1d
    800061f4:	8a850513          	addi	a0,a0,-1880 # 80022a98 <log>
    800061f8:	ffffb097          	auipc	ra,0xffffb
    800061fc:	fb8080e7          	jalr	-72(ra) # 800011b0 <release>
}
    80006200:	01813083          	ld	ra,24(sp)
    80006204:	01013403          	ld	s0,16(sp)
    80006208:	00813483          	ld	s1,8(sp)
    8000620c:	00013903          	ld	s2,0(sp)
    80006210:	02010113          	addi	sp,sp,32
    80006214:	00008067          	ret

0000000080006218 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80006218:	fe010113          	addi	sp,sp,-32
    8000621c:	00113c23          	sd	ra,24(sp)
    80006220:	00813823          	sd	s0,16(sp)
    80006224:	00913423          	sd	s1,8(sp)
    80006228:	01213023          	sd	s2,0(sp)
    8000622c:	02010413          	addi	s0,sp,32
    80006230:	00050493          	mv	s1,a0
    80006234:	00058913          	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80006238:	00004597          	auipc	a1,0x4
    8000623c:	59058593          	addi	a1,a1,1424 # 8000a7c8 <syscalls+0x268>
    80006240:	00850513          	addi	a0,a0,8
    80006244:	ffffb097          	auipc	ra,0xffffb
    80006248:	d90080e7          	jalr	-624(ra) # 80000fd4 <initlock>
  lk->name = name;
    8000624c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80006250:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80006254:	0204a423          	sw	zero,40(s1)
}
    80006258:	01813083          	ld	ra,24(sp)
    8000625c:	01013403          	ld	s0,16(sp)
    80006260:	00813483          	ld	s1,8(sp)
    80006264:	00013903          	ld	s2,0(sp)
    80006268:	02010113          	addi	sp,sp,32
    8000626c:	00008067          	ret

0000000080006270 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80006270:	fe010113          	addi	sp,sp,-32
    80006274:	00113c23          	sd	ra,24(sp)
    80006278:	00813823          	sd	s0,16(sp)
    8000627c:	00913423          	sd	s1,8(sp)
    80006280:	01213023          	sd	s2,0(sp)
    80006284:	02010413          	addi	s0,sp,32
    80006288:	00050493          	mv	s1,a0
  acquire(&lk->lk);
    8000628c:	00850913          	addi	s2,a0,8
    80006290:	00090513          	mv	a0,s2
    80006294:	ffffb097          	auipc	ra,0xffffb
    80006298:	e24080e7          	jalr	-476(ra) # 800010b8 <acquire>
  while (lk->locked) {
    8000629c:	0004a783          	lw	a5,0(s1)
    800062a0:	00078e63          	beqz	a5,800062bc <acquiresleep+0x4c>
    sleep(lk, &lk->lk);
    800062a4:	00090593          	mv	a1,s2
    800062a8:	00048513          	mv	a0,s1
    800062ac:	ffffd097          	auipc	ra,0xffffd
    800062b0:	df4080e7          	jalr	-524(ra) # 800030a0 <sleep>
  while (lk->locked) {
    800062b4:	0004a783          	lw	a5,0(s1)
    800062b8:	fe0796e3          	bnez	a5,800062a4 <acquiresleep+0x34>
  }
  lk->locked = 1;
    800062bc:	00100793          	li	a5,1
    800062c0:	00f4a023          	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800062c4:	ffffc097          	auipc	ra,0xffffc
    800062c8:	424080e7          	jalr	1060(ra) # 800026e8 <myproc>
    800062cc:	03052783          	lw	a5,48(a0)
    800062d0:	02f4a423          	sw	a5,40(s1)
  release(&lk->lk);
    800062d4:	00090513          	mv	a0,s2
    800062d8:	ffffb097          	auipc	ra,0xffffb
    800062dc:	ed8080e7          	jalr	-296(ra) # 800011b0 <release>
}
    800062e0:	01813083          	ld	ra,24(sp)
    800062e4:	01013403          	ld	s0,16(sp)
    800062e8:	00813483          	ld	s1,8(sp)
    800062ec:	00013903          	ld	s2,0(sp)
    800062f0:	02010113          	addi	sp,sp,32
    800062f4:	00008067          	ret

00000000800062f8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800062f8:	fe010113          	addi	sp,sp,-32
    800062fc:	00113c23          	sd	ra,24(sp)
    80006300:	00813823          	sd	s0,16(sp)
    80006304:	00913423          	sd	s1,8(sp)
    80006308:	01213023          	sd	s2,0(sp)
    8000630c:	02010413          	addi	s0,sp,32
    80006310:	00050493          	mv	s1,a0
  acquire(&lk->lk);
    80006314:	00850913          	addi	s2,a0,8
    80006318:	00090513          	mv	a0,s2
    8000631c:	ffffb097          	auipc	ra,0xffffb
    80006320:	d9c080e7          	jalr	-612(ra) # 800010b8 <acquire>
  lk->locked = 0;
    80006324:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80006328:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000632c:	00048513          	mv	a0,s1
    80006330:	ffffd097          	auipc	ra,0xffffd
    80006334:	e00080e7          	jalr	-512(ra) # 80003130 <wakeup>
  release(&lk->lk);
    80006338:	00090513          	mv	a0,s2
    8000633c:	ffffb097          	auipc	ra,0xffffb
    80006340:	e74080e7          	jalr	-396(ra) # 800011b0 <release>
}
    80006344:	01813083          	ld	ra,24(sp)
    80006348:	01013403          	ld	s0,16(sp)
    8000634c:	00813483          	ld	s1,8(sp)
    80006350:	00013903          	ld	s2,0(sp)
    80006354:	02010113          	addi	sp,sp,32
    80006358:	00008067          	ret

000000008000635c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000635c:	fd010113          	addi	sp,sp,-48
    80006360:	02113423          	sd	ra,40(sp)
    80006364:	02813023          	sd	s0,32(sp)
    80006368:	00913c23          	sd	s1,24(sp)
    8000636c:	01213823          	sd	s2,16(sp)
    80006370:	01313423          	sd	s3,8(sp)
    80006374:	03010413          	addi	s0,sp,48
    80006378:	00050493          	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000637c:	00850913          	addi	s2,a0,8
    80006380:	00090513          	mv	a0,s2
    80006384:	ffffb097          	auipc	ra,0xffffb
    80006388:	d34080e7          	jalr	-716(ra) # 800010b8 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000638c:	0004a783          	lw	a5,0(s1)
    80006390:	02079a63          	bnez	a5,800063c4 <holdingsleep+0x68>
    80006394:	00000493          	li	s1,0
  release(&lk->lk);
    80006398:	00090513          	mv	a0,s2
    8000639c:	ffffb097          	auipc	ra,0xffffb
    800063a0:	e14080e7          	jalr	-492(ra) # 800011b0 <release>
  return r;
}
    800063a4:	00048513          	mv	a0,s1
    800063a8:	02813083          	ld	ra,40(sp)
    800063ac:	02013403          	ld	s0,32(sp)
    800063b0:	01813483          	ld	s1,24(sp)
    800063b4:	01013903          	ld	s2,16(sp)
    800063b8:	00813983          	ld	s3,8(sp)
    800063bc:	03010113          	addi	sp,sp,48
    800063c0:	00008067          	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800063c4:	0284a983          	lw	s3,40(s1)
    800063c8:	ffffc097          	auipc	ra,0xffffc
    800063cc:	320080e7          	jalr	800(ra) # 800026e8 <myproc>
    800063d0:	03052483          	lw	s1,48(a0)
    800063d4:	413484b3          	sub	s1,s1,s3
    800063d8:	0014b493          	seqz	s1,s1
    800063dc:	fbdff06f          	j	80006398 <holdingsleep+0x3c>

00000000800063e0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800063e0:	ff010113          	addi	sp,sp,-16
    800063e4:	00113423          	sd	ra,8(sp)
    800063e8:	00813023          	sd	s0,0(sp)
    800063ec:	01010413          	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800063f0:	00004597          	auipc	a1,0x4
    800063f4:	3e858593          	addi	a1,a1,1000 # 8000a7d8 <syscalls+0x278>
    800063f8:	0001c517          	auipc	a0,0x1c
    800063fc:	7e850513          	addi	a0,a0,2024 # 80022be0 <ftable>
    80006400:	ffffb097          	auipc	ra,0xffffb
    80006404:	bd4080e7          	jalr	-1068(ra) # 80000fd4 <initlock>
}
    80006408:	00813083          	ld	ra,8(sp)
    8000640c:	00013403          	ld	s0,0(sp)
    80006410:	01010113          	addi	sp,sp,16
    80006414:	00008067          	ret

0000000080006418 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80006418:	fe010113          	addi	sp,sp,-32
    8000641c:	00113c23          	sd	ra,24(sp)
    80006420:	00813823          	sd	s0,16(sp)
    80006424:	00913423          	sd	s1,8(sp)
    80006428:	02010413          	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000642c:	0001c517          	auipc	a0,0x1c
    80006430:	7b450513          	addi	a0,a0,1972 # 80022be0 <ftable>
    80006434:	ffffb097          	auipc	ra,0xffffb
    80006438:	c84080e7          	jalr	-892(ra) # 800010b8 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000643c:	0001c497          	auipc	s1,0x1c
    80006440:	7bc48493          	addi	s1,s1,1980 # 80022bf8 <ftable+0x18>
    80006444:	0001d717          	auipc	a4,0x1d
    80006448:	75470713          	addi	a4,a4,1876 # 80023b98 <disk>
    if(f->ref == 0){
    8000644c:	0044a783          	lw	a5,4(s1)
    80006450:	02078263          	beqz	a5,80006474 <filealloc+0x5c>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80006454:	02848493          	addi	s1,s1,40
    80006458:	fee49ae3          	bne	s1,a4,8000644c <filealloc+0x34>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000645c:	0001c517          	auipc	a0,0x1c
    80006460:	78450513          	addi	a0,a0,1924 # 80022be0 <ftable>
    80006464:	ffffb097          	auipc	ra,0xffffb
    80006468:	d4c080e7          	jalr	-692(ra) # 800011b0 <release>
  return 0;
    8000646c:	00000493          	li	s1,0
    80006470:	01c0006f          	j	8000648c <filealloc+0x74>
      f->ref = 1;
    80006474:	00100793          	li	a5,1
    80006478:	00f4a223          	sw	a5,4(s1)
      release(&ftable.lock);
    8000647c:	0001c517          	auipc	a0,0x1c
    80006480:	76450513          	addi	a0,a0,1892 # 80022be0 <ftable>
    80006484:	ffffb097          	auipc	ra,0xffffb
    80006488:	d2c080e7          	jalr	-724(ra) # 800011b0 <release>
}
    8000648c:	00048513          	mv	a0,s1
    80006490:	01813083          	ld	ra,24(sp)
    80006494:	01013403          	ld	s0,16(sp)
    80006498:	00813483          	ld	s1,8(sp)
    8000649c:	02010113          	addi	sp,sp,32
    800064a0:	00008067          	ret

00000000800064a4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800064a4:	fe010113          	addi	sp,sp,-32
    800064a8:	00113c23          	sd	ra,24(sp)
    800064ac:	00813823          	sd	s0,16(sp)
    800064b0:	00913423          	sd	s1,8(sp)
    800064b4:	02010413          	addi	s0,sp,32
    800064b8:	00050493          	mv	s1,a0
  acquire(&ftable.lock);
    800064bc:	0001c517          	auipc	a0,0x1c
    800064c0:	72450513          	addi	a0,a0,1828 # 80022be0 <ftable>
    800064c4:	ffffb097          	auipc	ra,0xffffb
    800064c8:	bf4080e7          	jalr	-1036(ra) # 800010b8 <acquire>
  if(f->ref < 1)
    800064cc:	0044a783          	lw	a5,4(s1)
    800064d0:	02f05a63          	blez	a5,80006504 <filedup+0x60>
    panic("filedup");
  f->ref++;
    800064d4:	0017879b          	addiw	a5,a5,1
    800064d8:	00f4a223          	sw	a5,4(s1)
  release(&ftable.lock);
    800064dc:	0001c517          	auipc	a0,0x1c
    800064e0:	70450513          	addi	a0,a0,1796 # 80022be0 <ftable>
    800064e4:	ffffb097          	auipc	ra,0xffffb
    800064e8:	ccc080e7          	jalr	-820(ra) # 800011b0 <release>
  return f;
}
    800064ec:	00048513          	mv	a0,s1
    800064f0:	01813083          	ld	ra,24(sp)
    800064f4:	01013403          	ld	s0,16(sp)
    800064f8:	00813483          	ld	s1,8(sp)
    800064fc:	02010113          	addi	sp,sp,32
    80006500:	00008067          	ret
    panic("filedup");
    80006504:	00004517          	auipc	a0,0x4
    80006508:	2dc50513          	addi	a0,a0,732 # 8000a7e0 <syscalls+0x280>
    8000650c:	ffffa097          	auipc	ra,0xffffa
    80006510:	574080e7          	jalr	1396(ra) # 80000a80 <panic>

0000000080006514 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80006514:	fc010113          	addi	sp,sp,-64
    80006518:	02113c23          	sd	ra,56(sp)
    8000651c:	02813823          	sd	s0,48(sp)
    80006520:	02913423          	sd	s1,40(sp)
    80006524:	03213023          	sd	s2,32(sp)
    80006528:	01313c23          	sd	s3,24(sp)
    8000652c:	01413823          	sd	s4,16(sp)
    80006530:	01513423          	sd	s5,8(sp)
    80006534:	04010413          	addi	s0,sp,64
    80006538:	00050493          	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000653c:	0001c517          	auipc	a0,0x1c
    80006540:	6a450513          	addi	a0,a0,1700 # 80022be0 <ftable>
    80006544:	ffffb097          	auipc	ra,0xffffb
    80006548:	b74080e7          	jalr	-1164(ra) # 800010b8 <acquire>
  if(f->ref < 1)
    8000654c:	0044a783          	lw	a5,4(s1)
    80006550:	06f05863          	blez	a5,800065c0 <fileclose+0xac>
    panic("fileclose");
  if(--f->ref > 0){
    80006554:	fff7879b          	addiw	a5,a5,-1
    80006558:	0007871b          	sext.w	a4,a5
    8000655c:	00f4a223          	sw	a5,4(s1)
    80006560:	06e04863          	bgtz	a4,800065d0 <fileclose+0xbc>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80006564:	0004a903          	lw	s2,0(s1)
    80006568:	0094ca83          	lbu	s5,9(s1)
    8000656c:	0104ba03          	ld	s4,16(s1)
    80006570:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80006574:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80006578:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000657c:	0001c517          	auipc	a0,0x1c
    80006580:	66450513          	addi	a0,a0,1636 # 80022be0 <ftable>
    80006584:	ffffb097          	auipc	ra,0xffffb
    80006588:	c2c080e7          	jalr	-980(ra) # 800011b0 <release>

  if(ff.type == FD_PIPE){
    8000658c:	00100793          	li	a5,1
    80006590:	06f90a63          	beq	s2,a5,80006604 <fileclose+0xf0>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80006594:	ffe9091b          	addiw	s2,s2,-2
    80006598:	00100793          	li	a5,1
    8000659c:	0527e263          	bltu	a5,s2,800065e0 <fileclose+0xcc>
    begin_op();
    800065a0:	00000097          	auipc	ra,0x0
    800065a4:	8f8080e7          	jalr	-1800(ra) # 80005e98 <begin_op>
    iput(ff.ip);
    800065a8:	00098513          	mv	a0,s3
    800065ac:	fffff097          	auipc	ra,0xfffff
    800065b0:	b4c080e7          	jalr	-1204(ra) # 800050f8 <iput>
    end_op();
    800065b4:	00000097          	auipc	ra,0x0
    800065b8:	998080e7          	jalr	-1640(ra) # 80005f4c <end_op>
    800065bc:	0240006f          	j	800065e0 <fileclose+0xcc>
    panic("fileclose");
    800065c0:	00004517          	auipc	a0,0x4
    800065c4:	22850513          	addi	a0,a0,552 # 8000a7e8 <syscalls+0x288>
    800065c8:	ffffa097          	auipc	ra,0xffffa
    800065cc:	4b8080e7          	jalr	1208(ra) # 80000a80 <panic>
    release(&ftable.lock);
    800065d0:	0001c517          	auipc	a0,0x1c
    800065d4:	61050513          	addi	a0,a0,1552 # 80022be0 <ftable>
    800065d8:	ffffb097          	auipc	ra,0xffffb
    800065dc:	bd8080e7          	jalr	-1064(ra) # 800011b0 <release>
  }
}
    800065e0:	03813083          	ld	ra,56(sp)
    800065e4:	03013403          	ld	s0,48(sp)
    800065e8:	02813483          	ld	s1,40(sp)
    800065ec:	02013903          	ld	s2,32(sp)
    800065f0:	01813983          	ld	s3,24(sp)
    800065f4:	01013a03          	ld	s4,16(sp)
    800065f8:	00813a83          	ld	s5,8(sp)
    800065fc:	04010113          	addi	sp,sp,64
    80006600:	00008067          	ret
    pipeclose(ff.pipe, ff.writable);
    80006604:	000a8593          	mv	a1,s5
    80006608:	000a0513          	mv	a0,s4
    8000660c:	00000097          	auipc	ra,0x0
    80006610:	4c0080e7          	jalr	1216(ra) # 80006acc <pipeclose>
    80006614:	fcdff06f          	j	800065e0 <fileclose+0xcc>

0000000080006618 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80006618:	fb010113          	addi	sp,sp,-80
    8000661c:	04113423          	sd	ra,72(sp)
    80006620:	04813023          	sd	s0,64(sp)
    80006624:	02913c23          	sd	s1,56(sp)
    80006628:	03213823          	sd	s2,48(sp)
    8000662c:	03313423          	sd	s3,40(sp)
    80006630:	05010413          	addi	s0,sp,80
    80006634:	00050493          	mv	s1,a0
    80006638:	00058993          	mv	s3,a1
  struct proc *p = myproc();
    8000663c:	ffffc097          	auipc	ra,0xffffc
    80006640:	0ac080e7          	jalr	172(ra) # 800026e8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80006644:	0004a783          	lw	a5,0(s1)
    80006648:	ffe7879b          	addiw	a5,a5,-2
    8000664c:	00100713          	li	a4,1
    80006650:	06f76463          	bltu	a4,a5,800066b8 <filestat+0xa0>
    80006654:	00050913          	mv	s2,a0
    ilock(f->ip);
    80006658:	0184b503          	ld	a0,24(s1)
    8000665c:	fffff097          	auipc	ra,0xfffff
    80006660:	83c080e7          	jalr	-1988(ra) # 80004e98 <ilock>
    stati(f->ip, &st);
    80006664:	fb840593          	addi	a1,s0,-72
    80006668:	0184b503          	ld	a0,24(s1)
    8000666c:	fffff097          	auipc	ra,0xfffff
    80006670:	da4080e7          	jalr	-604(ra) # 80005410 <stati>
    iunlock(f->ip);
    80006674:	0184b503          	ld	a0,24(s1)
    80006678:	fffff097          	auipc	ra,0xfffff
    8000667c:	924080e7          	jalr	-1756(ra) # 80004f9c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80006680:	01800693          	li	a3,24
    80006684:	fb840613          	addi	a2,s0,-72
    80006688:	00098593          	mv	a1,s3
    8000668c:	05093503          	ld	a0,80(s2)
    80006690:	ffffc097          	auipc	ra,0xffffc
    80006694:	be4080e7          	jalr	-1052(ra) # 80002274 <copyout>
    80006698:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000669c:	04813083          	ld	ra,72(sp)
    800066a0:	04013403          	ld	s0,64(sp)
    800066a4:	03813483          	ld	s1,56(sp)
    800066a8:	03013903          	ld	s2,48(sp)
    800066ac:	02813983          	ld	s3,40(sp)
    800066b0:	05010113          	addi	sp,sp,80
    800066b4:	00008067          	ret
  return -1;
    800066b8:	fff00513          	li	a0,-1
    800066bc:	fe1ff06f          	j	8000669c <filestat+0x84>

00000000800066c0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800066c0:	fd010113          	addi	sp,sp,-48
    800066c4:	02113423          	sd	ra,40(sp)
    800066c8:	02813023          	sd	s0,32(sp)
    800066cc:	00913c23          	sd	s1,24(sp)
    800066d0:	01213823          	sd	s2,16(sp)
    800066d4:	01313423          	sd	s3,8(sp)
    800066d8:	03010413          	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800066dc:	00854783          	lbu	a5,8(a0)
    800066e0:	0e078a63          	beqz	a5,800067d4 <fileread+0x114>
    800066e4:	00050493          	mv	s1,a0
    800066e8:	00058993          	mv	s3,a1
    800066ec:	00060913          	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800066f0:	00052783          	lw	a5,0(a0)
    800066f4:	00100713          	li	a4,1
    800066f8:	06e78e63          	beq	a5,a4,80006774 <fileread+0xb4>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800066fc:	00300713          	li	a4,3
    80006700:	08e78463          	beq	a5,a4,80006788 <fileread+0xc8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80006704:	00200713          	li	a4,2
    80006708:	0ae79e63          	bne	a5,a4,800067c4 <fileread+0x104>
    ilock(f->ip);
    8000670c:	01853503          	ld	a0,24(a0)
    80006710:	ffffe097          	auipc	ra,0xffffe
    80006714:	788080e7          	jalr	1928(ra) # 80004e98 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80006718:	00090713          	mv	a4,s2
    8000671c:	0204a683          	lw	a3,32(s1)
    80006720:	00098613          	mv	a2,s3
    80006724:	00100593          	li	a1,1
    80006728:	0184b503          	ld	a0,24(s1)
    8000672c:	fffff097          	auipc	ra,0xfffff
    80006730:	d24080e7          	jalr	-732(ra) # 80005450 <readi>
    80006734:	00050913          	mv	s2,a0
    80006738:	00a05863          	blez	a0,80006748 <fileread+0x88>
      f->off += r;
    8000673c:	0204a783          	lw	a5,32(s1)
    80006740:	00a787bb          	addw	a5,a5,a0
    80006744:	02f4a023          	sw	a5,32(s1)
    iunlock(f->ip);
    80006748:	0184b503          	ld	a0,24(s1)
    8000674c:	fffff097          	auipc	ra,0xfffff
    80006750:	850080e7          	jalr	-1968(ra) # 80004f9c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80006754:	00090513          	mv	a0,s2
    80006758:	02813083          	ld	ra,40(sp)
    8000675c:	02013403          	ld	s0,32(sp)
    80006760:	01813483          	ld	s1,24(sp)
    80006764:	01013903          	ld	s2,16(sp)
    80006768:	00813983          	ld	s3,8(sp)
    8000676c:	03010113          	addi	sp,sp,48
    80006770:	00008067          	ret
    r = piperead(f->pipe, addr, n);
    80006774:	01053503          	ld	a0,16(a0)
    80006778:	00000097          	auipc	ra,0x0
    8000677c:	544080e7          	jalr	1348(ra) # 80006cbc <piperead>
    80006780:	00050913          	mv	s2,a0
    80006784:	fd1ff06f          	j	80006754 <fileread+0x94>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80006788:	02451783          	lh	a5,36(a0)
    8000678c:	03079693          	slli	a3,a5,0x30
    80006790:	0306d693          	srli	a3,a3,0x30
    80006794:	00900713          	li	a4,9
    80006798:	04d76263          	bltu	a4,a3,800067dc <fileread+0x11c>
    8000679c:	00479793          	slli	a5,a5,0x4
    800067a0:	0001c717          	auipc	a4,0x1c
    800067a4:	3a070713          	addi	a4,a4,928 # 80022b40 <devsw>
    800067a8:	00f707b3          	add	a5,a4,a5
    800067ac:	0007b783          	ld	a5,0(a5)
    800067b0:	02078a63          	beqz	a5,800067e4 <fileread+0x124>
    r = devsw[f->major].read(1, addr, n);
    800067b4:	00100513          	li	a0,1
    800067b8:	000780e7          	jalr	a5
    800067bc:	00050913          	mv	s2,a0
    800067c0:	f95ff06f          	j	80006754 <fileread+0x94>
    panic("fileread");
    800067c4:	00004517          	auipc	a0,0x4
    800067c8:	03450513          	addi	a0,a0,52 # 8000a7f8 <syscalls+0x298>
    800067cc:	ffffa097          	auipc	ra,0xffffa
    800067d0:	2b4080e7          	jalr	692(ra) # 80000a80 <panic>
    return -1;
    800067d4:	fff00913          	li	s2,-1
    800067d8:	f7dff06f          	j	80006754 <fileread+0x94>
      return -1;
    800067dc:	fff00913          	li	s2,-1
    800067e0:	f75ff06f          	j	80006754 <fileread+0x94>
    800067e4:	fff00913          	li	s2,-1
    800067e8:	f6dff06f          	j	80006754 <fileread+0x94>

00000000800067ec <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800067ec:	fb010113          	addi	sp,sp,-80
    800067f0:	04113423          	sd	ra,72(sp)
    800067f4:	04813023          	sd	s0,64(sp)
    800067f8:	02913c23          	sd	s1,56(sp)
    800067fc:	03213823          	sd	s2,48(sp)
    80006800:	03313423          	sd	s3,40(sp)
    80006804:	03413023          	sd	s4,32(sp)
    80006808:	01513c23          	sd	s5,24(sp)
    8000680c:	01613823          	sd	s6,16(sp)
    80006810:	01713423          	sd	s7,8(sp)
    80006814:	01813023          	sd	s8,0(sp)
    80006818:	05010413          	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000681c:	00954783          	lbu	a5,9(a0)
    80006820:	16078463          	beqz	a5,80006988 <filewrite+0x19c>
    80006824:	00050913          	mv	s2,a0
    80006828:	00058b13          	mv	s6,a1
    8000682c:	00060a13          	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80006830:	00052783          	lw	a5,0(a0)
    80006834:	00100713          	li	a4,1
    80006838:	02e78863          	beq	a5,a4,80006868 <filewrite+0x7c>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000683c:	00300713          	li	a4,3
    80006840:	02e78e63          	beq	a5,a4,8000687c <filewrite+0x90>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80006844:	00200713          	li	a4,2
    80006848:	12e79863          	bne	a5,a4,80006978 <filewrite+0x18c>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000684c:	0ec05463          	blez	a2,80006934 <filewrite+0x148>
    int i = 0;
    80006850:	00000993          	li	s3,0
    80006854:	00001bb7          	lui	s7,0x1
    80006858:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000685c:	00001c37          	lui	s8,0x1
    80006860:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80006864:	0bc0006f          	j	80006920 <filewrite+0x134>
    ret = pipewrite(f->pipe, addr, n);
    80006868:	01053503          	ld	a0,16(a0)
    8000686c:	00000097          	auipc	ra,0x0
    80006870:	2f8080e7          	jalr	760(ra) # 80006b64 <pipewrite>
    80006874:	00050a13          	mv	s4,a0
    80006878:	0c40006f          	j	8000693c <filewrite+0x150>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000687c:	02451783          	lh	a5,36(a0)
    80006880:	03079693          	slli	a3,a5,0x30
    80006884:	0306d693          	srli	a3,a3,0x30
    80006888:	00900713          	li	a4,9
    8000688c:	10d76263          	bltu	a4,a3,80006990 <filewrite+0x1a4>
    80006890:	00479793          	slli	a5,a5,0x4
    80006894:	0001c717          	auipc	a4,0x1c
    80006898:	2ac70713          	addi	a4,a4,684 # 80022b40 <devsw>
    8000689c:	00f707b3          	add	a5,a4,a5
    800068a0:	0087b783          	ld	a5,8(a5)
    800068a4:	0e078a63          	beqz	a5,80006998 <filewrite+0x1ac>
    ret = devsw[f->major].write(1, addr, n);
    800068a8:	00100513          	li	a0,1
    800068ac:	000780e7          	jalr	a5
    800068b0:	00050a13          	mv	s4,a0
    800068b4:	0880006f          	j	8000693c <filewrite+0x150>
    800068b8:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800068bc:	fffff097          	auipc	ra,0xfffff
    800068c0:	5dc080e7          	jalr	1500(ra) # 80005e98 <begin_op>
      ilock(f->ip);
    800068c4:	01893503          	ld	a0,24(s2)
    800068c8:	ffffe097          	auipc	ra,0xffffe
    800068cc:	5d0080e7          	jalr	1488(ra) # 80004e98 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800068d0:	000a8713          	mv	a4,s5
    800068d4:	02092683          	lw	a3,32(s2)
    800068d8:	01698633          	add	a2,s3,s6
    800068dc:	00100593          	li	a1,1
    800068e0:	01893503          	ld	a0,24(s2)
    800068e4:	fffff097          	auipc	ra,0xfffff
    800068e8:	cdc080e7          	jalr	-804(ra) # 800055c0 <writei>
    800068ec:	00050493          	mv	s1,a0
    800068f0:	00a05863          	blez	a0,80006900 <filewrite+0x114>
        f->off += r;
    800068f4:	02092783          	lw	a5,32(s2)
    800068f8:	00a787bb          	addw	a5,a5,a0
    800068fc:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80006900:	01893503          	ld	a0,24(s2)
    80006904:	ffffe097          	auipc	ra,0xffffe
    80006908:	698080e7          	jalr	1688(ra) # 80004f9c <iunlock>
      end_op();
    8000690c:	fffff097          	auipc	ra,0xfffff
    80006910:	640080e7          	jalr	1600(ra) # 80005f4c <end_op>

      if(r != n1){
    80006914:	029a9263          	bne	s5,s1,80006938 <filewrite+0x14c>
        // error from writei
        break;
      }
      i += r;
    80006918:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000691c:	0149de63          	bge	s3,s4,80006938 <filewrite+0x14c>
      int n1 = n - i;
    80006920:	413a04bb          	subw	s1,s4,s3
    80006924:	0004879b          	sext.w	a5,s1
    80006928:	f8fbd8e3          	bge	s7,a5,800068b8 <filewrite+0xcc>
    8000692c:	000c0493          	mv	s1,s8
    80006930:	f89ff06f          	j	800068b8 <filewrite+0xcc>
    int i = 0;
    80006934:	00000993          	li	s3,0
    }
    ret = (i == n ? n : -1);
    80006938:	033a1c63          	bne	s4,s3,80006970 <filewrite+0x184>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000693c:	000a0513          	mv	a0,s4
    80006940:	04813083          	ld	ra,72(sp)
    80006944:	04013403          	ld	s0,64(sp)
    80006948:	03813483          	ld	s1,56(sp)
    8000694c:	03013903          	ld	s2,48(sp)
    80006950:	02813983          	ld	s3,40(sp)
    80006954:	02013a03          	ld	s4,32(sp)
    80006958:	01813a83          	ld	s5,24(sp)
    8000695c:	01013b03          	ld	s6,16(sp)
    80006960:	00813b83          	ld	s7,8(sp)
    80006964:	00013c03          	ld	s8,0(sp)
    80006968:	05010113          	addi	sp,sp,80
    8000696c:	00008067          	ret
    ret = (i == n ? n : -1);
    80006970:	fff00a13          	li	s4,-1
    80006974:	fc9ff06f          	j	8000693c <filewrite+0x150>
    panic("filewrite");
    80006978:	00004517          	auipc	a0,0x4
    8000697c:	e9050513          	addi	a0,a0,-368 # 8000a808 <syscalls+0x2a8>
    80006980:	ffffa097          	auipc	ra,0xffffa
    80006984:	100080e7          	jalr	256(ra) # 80000a80 <panic>
    return -1;
    80006988:	fff00a13          	li	s4,-1
    8000698c:	fb1ff06f          	j	8000693c <filewrite+0x150>
      return -1;
    80006990:	fff00a13          	li	s4,-1
    80006994:	fa9ff06f          	j	8000693c <filewrite+0x150>
    80006998:	fff00a13          	li	s4,-1
    8000699c:	fa1ff06f          	j	8000693c <filewrite+0x150>

00000000800069a0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800069a0:	fd010113          	addi	sp,sp,-48
    800069a4:	02113423          	sd	ra,40(sp)
    800069a8:	02813023          	sd	s0,32(sp)
    800069ac:	00913c23          	sd	s1,24(sp)
    800069b0:	01213823          	sd	s2,16(sp)
    800069b4:	01313423          	sd	s3,8(sp)
    800069b8:	01413023          	sd	s4,0(sp)
    800069bc:	03010413          	addi	s0,sp,48
    800069c0:	00050493          	mv	s1,a0
    800069c4:	00058a13          	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800069c8:	0005b023          	sd	zero,0(a1)
    800069cc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800069d0:	00000097          	auipc	ra,0x0
    800069d4:	a48080e7          	jalr	-1464(ra) # 80006418 <filealloc>
    800069d8:	00a4b023          	sd	a0,0(s1)
    800069dc:	0a050663          	beqz	a0,80006a88 <pipealloc+0xe8>
    800069e0:	00000097          	auipc	ra,0x0
    800069e4:	a38080e7          	jalr	-1480(ra) # 80006418 <filealloc>
    800069e8:	00aa3023          	sd	a0,0(s4)
    800069ec:	08050663          	beqz	a0,80006a78 <pipealloc+0xd8>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800069f0:	ffffa097          	auipc	ra,0xffffa
    800069f4:	55c080e7          	jalr	1372(ra) # 80000f4c <kalloc>
    800069f8:	00050913          	mv	s2,a0
    800069fc:	06050863          	beqz	a0,80006a6c <pipealloc+0xcc>
    goto bad;
  pi->readopen = 1;
    80006a00:	00100993          	li	s3,1
    80006a04:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80006a08:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80006a0c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80006a10:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80006a14:	00004597          	auipc	a1,0x4
    80006a18:	e0458593          	addi	a1,a1,-508 # 8000a818 <syscalls+0x2b8>
    80006a1c:	ffffa097          	auipc	ra,0xffffa
    80006a20:	5b8080e7          	jalr	1464(ra) # 80000fd4 <initlock>
  (*f0)->type = FD_PIPE;
    80006a24:	0004b783          	ld	a5,0(s1)
    80006a28:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80006a2c:	0004b783          	ld	a5,0(s1)
    80006a30:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80006a34:	0004b783          	ld	a5,0(s1)
    80006a38:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80006a3c:	0004b783          	ld	a5,0(s1)
    80006a40:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80006a44:	000a3783          	ld	a5,0(s4)
    80006a48:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80006a4c:	000a3783          	ld	a5,0(s4)
    80006a50:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80006a54:	000a3783          	ld	a5,0(s4)
    80006a58:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80006a5c:	000a3783          	ld	a5,0(s4)
    80006a60:	0127b823          	sd	s2,16(a5)
  return 0;
    80006a64:	00000513          	li	a0,0
    80006a68:	03c0006f          	j	80006aa4 <pipealloc+0x104>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80006a6c:	0004b503          	ld	a0,0(s1)
    80006a70:	00051863          	bnez	a0,80006a80 <pipealloc+0xe0>
    80006a74:	0140006f          	j	80006a88 <pipealloc+0xe8>
    80006a78:	0004b503          	ld	a0,0(s1)
    80006a7c:	04050463          	beqz	a0,80006ac4 <pipealloc+0x124>
    fileclose(*f0);
    80006a80:	00000097          	auipc	ra,0x0
    80006a84:	a94080e7          	jalr	-1388(ra) # 80006514 <fileclose>
  if(*f1)
    80006a88:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80006a8c:	fff00513          	li	a0,-1
  if(*f1)
    80006a90:	00078a63          	beqz	a5,80006aa4 <pipealloc+0x104>
    fileclose(*f1);
    80006a94:	00078513          	mv	a0,a5
    80006a98:	00000097          	auipc	ra,0x0
    80006a9c:	a7c080e7          	jalr	-1412(ra) # 80006514 <fileclose>
  return -1;
    80006aa0:	fff00513          	li	a0,-1
}
    80006aa4:	02813083          	ld	ra,40(sp)
    80006aa8:	02013403          	ld	s0,32(sp)
    80006aac:	01813483          	ld	s1,24(sp)
    80006ab0:	01013903          	ld	s2,16(sp)
    80006ab4:	00813983          	ld	s3,8(sp)
    80006ab8:	00013a03          	ld	s4,0(sp)
    80006abc:	03010113          	addi	sp,sp,48
    80006ac0:	00008067          	ret
  return -1;
    80006ac4:	fff00513          	li	a0,-1
    80006ac8:	fddff06f          	j	80006aa4 <pipealloc+0x104>

0000000080006acc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80006acc:	fe010113          	addi	sp,sp,-32
    80006ad0:	00113c23          	sd	ra,24(sp)
    80006ad4:	00813823          	sd	s0,16(sp)
    80006ad8:	00913423          	sd	s1,8(sp)
    80006adc:	01213023          	sd	s2,0(sp)
    80006ae0:	02010413          	addi	s0,sp,32
    80006ae4:	00050493          	mv	s1,a0
    80006ae8:	00058913          	mv	s2,a1
  acquire(&pi->lock);
    80006aec:	ffffa097          	auipc	ra,0xffffa
    80006af0:	5cc080e7          	jalr	1484(ra) # 800010b8 <acquire>
  if(writable){
    80006af4:	04090663          	beqz	s2,80006b40 <pipeclose+0x74>
    pi->writeopen = 0;
    80006af8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80006afc:	21848513          	addi	a0,s1,536
    80006b00:	ffffc097          	auipc	ra,0xffffc
    80006b04:	630080e7          	jalr	1584(ra) # 80003130 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80006b08:	2204b783          	ld	a5,544(s1)
    80006b0c:	04079463          	bnez	a5,80006b54 <pipeclose+0x88>
    release(&pi->lock);
    80006b10:	00048513          	mv	a0,s1
    80006b14:	ffffa097          	auipc	ra,0xffffa
    80006b18:	69c080e7          	jalr	1692(ra) # 800011b0 <release>
    kfree((char*)pi);
    80006b1c:	00048513          	mv	a0,s1
    80006b20:	ffffa097          	auipc	ra,0xffffa
    80006b24:	2a0080e7          	jalr	672(ra) # 80000dc0 <kfree>
  } else
    release(&pi->lock);
}
    80006b28:	01813083          	ld	ra,24(sp)
    80006b2c:	01013403          	ld	s0,16(sp)
    80006b30:	00813483          	ld	s1,8(sp)
    80006b34:	00013903          	ld	s2,0(sp)
    80006b38:	02010113          	addi	sp,sp,32
    80006b3c:	00008067          	ret
    pi->readopen = 0;
    80006b40:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80006b44:	21c48513          	addi	a0,s1,540
    80006b48:	ffffc097          	auipc	ra,0xffffc
    80006b4c:	5e8080e7          	jalr	1512(ra) # 80003130 <wakeup>
    80006b50:	fb9ff06f          	j	80006b08 <pipeclose+0x3c>
    release(&pi->lock);
    80006b54:	00048513          	mv	a0,s1
    80006b58:	ffffa097          	auipc	ra,0xffffa
    80006b5c:	658080e7          	jalr	1624(ra) # 800011b0 <release>
}
    80006b60:	fc9ff06f          	j	80006b28 <pipeclose+0x5c>

0000000080006b64 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80006b64:	fa010113          	addi	sp,sp,-96
    80006b68:	04113c23          	sd	ra,88(sp)
    80006b6c:	04813823          	sd	s0,80(sp)
    80006b70:	04913423          	sd	s1,72(sp)
    80006b74:	05213023          	sd	s2,64(sp)
    80006b78:	03313c23          	sd	s3,56(sp)
    80006b7c:	03413823          	sd	s4,48(sp)
    80006b80:	03513423          	sd	s5,40(sp)
    80006b84:	03613023          	sd	s6,32(sp)
    80006b88:	01713c23          	sd	s7,24(sp)
    80006b8c:	01813823          	sd	s8,16(sp)
    80006b90:	06010413          	addi	s0,sp,96
    80006b94:	00050493          	mv	s1,a0
    80006b98:	00058a93          	mv	s5,a1
    80006b9c:	00060a13          	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80006ba0:	ffffc097          	auipc	ra,0xffffc
    80006ba4:	b48080e7          	jalr	-1208(ra) # 800026e8 <myproc>
    80006ba8:	00050993          	mv	s3,a0

  acquire(&pi->lock);
    80006bac:	00048513          	mv	a0,s1
    80006bb0:	ffffa097          	auipc	ra,0xffffa
    80006bb4:	508080e7          	jalr	1288(ra) # 800010b8 <acquire>
  while(i < n){
    80006bb8:	0f405263          	blez	s4,80006c9c <pipewrite+0x138>
  int i = 0;
    80006bbc:	00000913          	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80006bc0:	fff00b13          	li	s6,-1
      wakeup(&pi->nread);
    80006bc4:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80006bc8:	21c48b93          	addi	s7,s1,540
    80006bcc:	0680006f          	j	80006c34 <pipewrite+0xd0>
      release(&pi->lock);
    80006bd0:	00048513          	mv	a0,s1
    80006bd4:	ffffa097          	auipc	ra,0xffffa
    80006bd8:	5dc080e7          	jalr	1500(ra) # 800011b0 <release>
      return -1;
    80006bdc:	fff00913          	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80006be0:	00090513          	mv	a0,s2
    80006be4:	05813083          	ld	ra,88(sp)
    80006be8:	05013403          	ld	s0,80(sp)
    80006bec:	04813483          	ld	s1,72(sp)
    80006bf0:	04013903          	ld	s2,64(sp)
    80006bf4:	03813983          	ld	s3,56(sp)
    80006bf8:	03013a03          	ld	s4,48(sp)
    80006bfc:	02813a83          	ld	s5,40(sp)
    80006c00:	02013b03          	ld	s6,32(sp)
    80006c04:	01813b83          	ld	s7,24(sp)
    80006c08:	01013c03          	ld	s8,16(sp)
    80006c0c:	06010113          	addi	sp,sp,96
    80006c10:	00008067          	ret
      wakeup(&pi->nread);
    80006c14:	000c0513          	mv	a0,s8
    80006c18:	ffffc097          	auipc	ra,0xffffc
    80006c1c:	518080e7          	jalr	1304(ra) # 80003130 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80006c20:	00048593          	mv	a1,s1
    80006c24:	000b8513          	mv	a0,s7
    80006c28:	ffffc097          	auipc	ra,0xffffc
    80006c2c:	478080e7          	jalr	1144(ra) # 800030a0 <sleep>
  while(i < n){
    80006c30:	07495863          	bge	s2,s4,80006ca0 <pipewrite+0x13c>
    if(pi->readopen == 0 || killed(pr)){
    80006c34:	2204a783          	lw	a5,544(s1)
    80006c38:	f8078ce3          	beqz	a5,80006bd0 <pipewrite+0x6c>
    80006c3c:	00098513          	mv	a0,s3
    80006c40:	ffffd097          	auipc	ra,0xffffd
    80006c44:	810080e7          	jalr	-2032(ra) # 80003450 <killed>
    80006c48:	f80514e3          	bnez	a0,80006bd0 <pipewrite+0x6c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80006c4c:	2184a783          	lw	a5,536(s1)
    80006c50:	21c4a703          	lw	a4,540(s1)
    80006c54:	2007879b          	addiw	a5,a5,512
    80006c58:	faf70ee3          	beq	a4,a5,80006c14 <pipewrite+0xb0>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80006c5c:	00100693          	li	a3,1
    80006c60:	01590633          	add	a2,s2,s5
    80006c64:	faf40593          	addi	a1,s0,-81
    80006c68:	0509b503          	ld	a0,80(s3)
    80006c6c:	ffffb097          	auipc	ra,0xffffb
    80006c70:	770080e7          	jalr	1904(ra) # 800023dc <copyin>
    80006c74:	03650663          	beq	a0,s6,80006ca0 <pipewrite+0x13c>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80006c78:	21c4a783          	lw	a5,540(s1)
    80006c7c:	0017871b          	addiw	a4,a5,1
    80006c80:	20e4ae23          	sw	a4,540(s1)
    80006c84:	1ff7f793          	andi	a5,a5,511
    80006c88:	00f487b3          	add	a5,s1,a5
    80006c8c:	faf44703          	lbu	a4,-81(s0)
    80006c90:	00e78c23          	sb	a4,24(a5)
      i++;
    80006c94:	0019091b          	addiw	s2,s2,1
    80006c98:	f99ff06f          	j	80006c30 <pipewrite+0xcc>
  int i = 0;
    80006c9c:	00000913          	li	s2,0
  wakeup(&pi->nread);
    80006ca0:	21848513          	addi	a0,s1,536
    80006ca4:	ffffc097          	auipc	ra,0xffffc
    80006ca8:	48c080e7          	jalr	1164(ra) # 80003130 <wakeup>
  release(&pi->lock);
    80006cac:	00048513          	mv	a0,s1
    80006cb0:	ffffa097          	auipc	ra,0xffffa
    80006cb4:	500080e7          	jalr	1280(ra) # 800011b0 <release>
  return i;
    80006cb8:	f29ff06f          	j	80006be0 <pipewrite+0x7c>

0000000080006cbc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80006cbc:	fb010113          	addi	sp,sp,-80
    80006cc0:	04113423          	sd	ra,72(sp)
    80006cc4:	04813023          	sd	s0,64(sp)
    80006cc8:	02913c23          	sd	s1,56(sp)
    80006ccc:	03213823          	sd	s2,48(sp)
    80006cd0:	03313423          	sd	s3,40(sp)
    80006cd4:	03413023          	sd	s4,32(sp)
    80006cd8:	01513c23          	sd	s5,24(sp)
    80006cdc:	01613823          	sd	s6,16(sp)
    80006ce0:	05010413          	addi	s0,sp,80
    80006ce4:	00050493          	mv	s1,a0
    80006ce8:	00058913          	mv	s2,a1
    80006cec:	00060a93          	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80006cf0:	ffffc097          	auipc	ra,0xffffc
    80006cf4:	9f8080e7          	jalr	-1544(ra) # 800026e8 <myproc>
    80006cf8:	00050a13          	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80006cfc:	00048513          	mv	a0,s1
    80006d00:	ffffa097          	auipc	ra,0xffffa
    80006d04:	3b8080e7          	jalr	952(ra) # 800010b8 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80006d08:	2184a703          	lw	a4,536(s1)
    80006d0c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80006d10:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80006d14:	02f71c63          	bne	a4,a5,80006d4c <piperead+0x90>
    80006d18:	2244a783          	lw	a5,548(s1)
    80006d1c:	02078863          	beqz	a5,80006d4c <piperead+0x90>
    if(killed(pr)){
    80006d20:	000a0513          	mv	a0,s4
    80006d24:	ffffc097          	auipc	ra,0xffffc
    80006d28:	72c080e7          	jalr	1836(ra) # 80003450 <killed>
    80006d2c:	0c051063          	bnez	a0,80006dec <piperead+0x130>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80006d30:	00048593          	mv	a1,s1
    80006d34:	00098513          	mv	a0,s3
    80006d38:	ffffc097          	auipc	ra,0xffffc
    80006d3c:	368080e7          	jalr	872(ra) # 800030a0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80006d40:	2184a703          	lw	a4,536(s1)
    80006d44:	21c4a783          	lw	a5,540(s1)
    80006d48:	fcf708e3          	beq	a4,a5,80006d18 <piperead+0x5c>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80006d4c:	00000993          	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80006d50:	fff00b13          	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80006d54:	05505a63          	blez	s5,80006da8 <piperead+0xec>
    if(pi->nread == pi->nwrite)
    80006d58:	2184a783          	lw	a5,536(s1)
    80006d5c:	21c4a703          	lw	a4,540(s1)
    80006d60:	04f70463          	beq	a4,a5,80006da8 <piperead+0xec>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80006d64:	0017871b          	addiw	a4,a5,1
    80006d68:	20e4ac23          	sw	a4,536(s1)
    80006d6c:	1ff7f793          	andi	a5,a5,511
    80006d70:	00f487b3          	add	a5,s1,a5
    80006d74:	0187c783          	lbu	a5,24(a5)
    80006d78:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80006d7c:	00100693          	li	a3,1
    80006d80:	fbf40613          	addi	a2,s0,-65
    80006d84:	00090593          	mv	a1,s2
    80006d88:	050a3503          	ld	a0,80(s4)
    80006d8c:	ffffb097          	auipc	ra,0xffffb
    80006d90:	4e8080e7          	jalr	1256(ra) # 80002274 <copyout>
    80006d94:	01650a63          	beq	a0,s6,80006da8 <piperead+0xec>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80006d98:	0019899b          	addiw	s3,s3,1
    80006d9c:	00190913          	addi	s2,s2,1
    80006da0:	fb3a9ce3          	bne	s5,s3,80006d58 <piperead+0x9c>
    80006da4:	000a8993          	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80006da8:	21c48513          	addi	a0,s1,540
    80006dac:	ffffc097          	auipc	ra,0xffffc
    80006db0:	384080e7          	jalr	900(ra) # 80003130 <wakeup>
  release(&pi->lock);
    80006db4:	00048513          	mv	a0,s1
    80006db8:	ffffa097          	auipc	ra,0xffffa
    80006dbc:	3f8080e7          	jalr	1016(ra) # 800011b0 <release>
  return i;
}
    80006dc0:	00098513          	mv	a0,s3
    80006dc4:	04813083          	ld	ra,72(sp)
    80006dc8:	04013403          	ld	s0,64(sp)
    80006dcc:	03813483          	ld	s1,56(sp)
    80006dd0:	03013903          	ld	s2,48(sp)
    80006dd4:	02813983          	ld	s3,40(sp)
    80006dd8:	02013a03          	ld	s4,32(sp)
    80006ddc:	01813a83          	ld	s5,24(sp)
    80006de0:	01013b03          	ld	s6,16(sp)
    80006de4:	05010113          	addi	sp,sp,80
    80006de8:	00008067          	ret
      release(&pi->lock);
    80006dec:	00048513          	mv	a0,s1
    80006df0:	ffffa097          	auipc	ra,0xffffa
    80006df4:	3c0080e7          	jalr	960(ra) # 800011b0 <release>
      return -1;
    80006df8:	fff00993          	li	s3,-1
    80006dfc:	fc5ff06f          	j	80006dc0 <piperead+0x104>

0000000080006e00 <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    80006e00:	ff010113          	addi	sp,sp,-16
    80006e04:	00813423          	sd	s0,8(sp)
    80006e08:	01010413          	addi	s0,sp,16
    80006e0c:	00050793          	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80006e10:	00157513          	andi	a0,a0,1
    80006e14:	00351513          	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80006e18:	0027f793          	andi	a5,a5,2
    80006e1c:	00078463          	beqz	a5,80006e24 <flags2perm+0x24>
      perm |= PTE_W;
    80006e20:	00456513          	ori	a0,a0,4
    return perm;
}
    80006e24:	00813403          	ld	s0,8(sp)
    80006e28:	01010113          	addi	sp,sp,16
    80006e2c:	00008067          	ret

0000000080006e30 <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    80006e30:	de010113          	addi	sp,sp,-544
    80006e34:	20113c23          	sd	ra,536(sp)
    80006e38:	20813823          	sd	s0,528(sp)
    80006e3c:	20913423          	sd	s1,520(sp)
    80006e40:	21213023          	sd	s2,512(sp)
    80006e44:	1f313c23          	sd	s3,504(sp)
    80006e48:	1f413823          	sd	s4,496(sp)
    80006e4c:	1f513423          	sd	s5,488(sp)
    80006e50:	1f613023          	sd	s6,480(sp)
    80006e54:	1d713c23          	sd	s7,472(sp)
    80006e58:	1d813823          	sd	s8,464(sp)
    80006e5c:	1d913423          	sd	s9,456(sp)
    80006e60:	1da13023          	sd	s10,448(sp)
    80006e64:	1bb13c23          	sd	s11,440(sp)
    80006e68:	22010413          	addi	s0,sp,544
    80006e6c:	00050913          	mv	s2,a0
    80006e70:	dea43423          	sd	a0,-536(s0)
    80006e74:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80006e78:	ffffc097          	auipc	ra,0xffffc
    80006e7c:	870080e7          	jalr	-1936(ra) # 800026e8 <myproc>
    80006e80:	00050493          	mv	s1,a0

  begin_op();
    80006e84:	fffff097          	auipc	ra,0xfffff
    80006e88:	014080e7          	jalr	20(ra) # 80005e98 <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    80006e8c:	00090513          	mv	a0,s2
    80006e90:	fffff097          	auipc	ra,0xfffff
    80006e94:	cf4080e7          	jalr	-780(ra) # 80005b84 <namei>
    80006e98:	08050c63          	beqz	a0,80006f30 <kexec+0x100>
    80006e9c:	00050a93          	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80006ea0:	ffffe097          	auipc	ra,0xffffe
    80006ea4:	ff8080e7          	jalr	-8(ra) # 80004e98 <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80006ea8:	04000713          	li	a4,64
    80006eac:	00000693          	li	a3,0
    80006eb0:	e5040613          	addi	a2,s0,-432
    80006eb4:	00000593          	li	a1,0
    80006eb8:	000a8513          	mv	a0,s5
    80006ebc:	ffffe097          	auipc	ra,0xffffe
    80006ec0:	594080e7          	jalr	1428(ra) # 80005450 <readi>
    80006ec4:	04000793          	li	a5,64
    80006ec8:	00f51a63          	bne	a0,a5,80006edc <kexec+0xac>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    80006ecc:	e5042703          	lw	a4,-432(s0)
    80006ed0:	464c47b7          	lui	a5,0x464c4
    80006ed4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80006ed8:	06f70463          	beq	a4,a5,80006f40 <kexec+0x110>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80006edc:	000a8513          	mv	a0,s5
    80006ee0:	ffffe097          	auipc	ra,0xffffe
    80006ee4:	2f4080e7          	jalr	756(ra) # 800051d4 <iunlockput>
    end_op();
    80006ee8:	fffff097          	auipc	ra,0xfffff
    80006eec:	064080e7          	jalr	100(ra) # 80005f4c <end_op>
  }
  return -1;
    80006ef0:	fff00513          	li	a0,-1
}
    80006ef4:	21813083          	ld	ra,536(sp)
    80006ef8:	21013403          	ld	s0,528(sp)
    80006efc:	20813483          	ld	s1,520(sp)
    80006f00:	20013903          	ld	s2,512(sp)
    80006f04:	1f813983          	ld	s3,504(sp)
    80006f08:	1f013a03          	ld	s4,496(sp)
    80006f0c:	1e813a83          	ld	s5,488(sp)
    80006f10:	1e013b03          	ld	s6,480(sp)
    80006f14:	1d813b83          	ld	s7,472(sp)
    80006f18:	1d013c03          	ld	s8,464(sp)
    80006f1c:	1c813c83          	ld	s9,456(sp)
    80006f20:	1c013d03          	ld	s10,448(sp)
    80006f24:	1b813d83          	ld	s11,440(sp)
    80006f28:	22010113          	addi	sp,sp,544
    80006f2c:	00008067          	ret
    end_op();
    80006f30:	fffff097          	auipc	ra,0xfffff
    80006f34:	01c080e7          	jalr	28(ra) # 80005f4c <end_op>
    return -1;
    80006f38:	fff00513          	li	a0,-1
    80006f3c:	fb9ff06f          	j	80006ef4 <kexec+0xc4>
  if((pagetable = proc_pagetable(p)) == 0)
    80006f40:	00048513          	mv	a0,s1
    80006f44:	ffffc097          	auipc	ra,0xffffc
    80006f48:	94c080e7          	jalr	-1716(ra) # 80002890 <proc_pagetable>
    80006f4c:	00050b13          	mv	s6,a0
    80006f50:	f80506e3          	beqz	a0,80006edc <kexec+0xac>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80006f54:	e7042783          	lw	a5,-400(s0)
    80006f58:	e8845703          	lhu	a4,-376(s0)
    80006f5c:	08070863          	beqz	a4,80006fec <kexec+0x1bc>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80006f60:	00000913          	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80006f64:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80006f68:	00001a37          	lui	s4,0x1
    80006f6c:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80006f70:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80006f74:	00001db7          	lui	s11,0x1
    80006f78:	fffffd37          	lui	s10,0xfffff
    80006f7c:	2d80006f          	j	80007254 <kexec+0x424>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80006f80:	00004517          	auipc	a0,0x4
    80006f84:	8a050513          	addi	a0,a0,-1888 # 8000a820 <syscalls+0x2c0>
    80006f88:	ffffa097          	auipc	ra,0xffffa
    80006f8c:	af8080e7          	jalr	-1288(ra) # 80000a80 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80006f90:	00090713          	mv	a4,s2
    80006f94:	009c86bb          	addw	a3,s9,s1
    80006f98:	00000593          	li	a1,0
    80006f9c:	000a8513          	mv	a0,s5
    80006fa0:	ffffe097          	auipc	ra,0xffffe
    80006fa4:	4b0080e7          	jalr	1200(ra) # 80005450 <readi>
    80006fa8:	0005051b          	sext.w	a0,a0
    80006fac:	22a91463          	bne	s2,a0,800071d4 <kexec+0x3a4>
  for(i = 0; i < sz; i += PGSIZE){
    80006fb0:	009d84bb          	addw	s1,s11,s1
    80006fb4:	013d09bb          	addw	s3,s10,s3
    80006fb8:	2774fe63          	bgeu	s1,s7,80007234 <kexec+0x404>
    pa = walkaddr(pagetable, va + i);
    80006fbc:	02049593          	slli	a1,s1,0x20
    80006fc0:	0205d593          	srli	a1,a1,0x20
    80006fc4:	018585b3          	add	a1,a1,s8
    80006fc8:	000b0513          	mv	a0,s6
    80006fcc:	ffffb097          	auipc	ra,0xffffb
    80006fd0:	81c080e7          	jalr	-2020(ra) # 800017e8 <walkaddr>
    80006fd4:	00050613          	mv	a2,a0
    if(pa == 0)
    80006fd8:	fa0504e3          	beqz	a0,80006f80 <kexec+0x150>
      n = PGSIZE;
    80006fdc:	000a0913          	mv	s2,s4
    if(sz - i < PGSIZE)
    80006fe0:	fb49f8e3          	bgeu	s3,s4,80006f90 <kexec+0x160>
      n = sz - i;
    80006fe4:	00098913          	mv	s2,s3
    80006fe8:	fa9ff06f          	j	80006f90 <kexec+0x160>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80006fec:	00000913          	li	s2,0
  iunlockput(ip);
    80006ff0:	000a8513          	mv	a0,s5
    80006ff4:	ffffe097          	auipc	ra,0xffffe
    80006ff8:	1e0080e7          	jalr	480(ra) # 800051d4 <iunlockput>
  end_op();
    80006ffc:	fffff097          	auipc	ra,0xfffff
    80007000:	f50080e7          	jalr	-176(ra) # 80005f4c <end_op>
  p = myproc();
    80007004:	ffffb097          	auipc	ra,0xffffb
    80007008:	6e4080e7          	jalr	1764(ra) # 800026e8 <myproc>
    8000700c:	00050b93          	mv	s7,a0
  uint64 oldsz = p->sz;
    80007010:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80007014:	000017b7          	lui	a5,0x1
    80007018:	fff78793          	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000701c:	00f907b3          	add	a5,s2,a5
    80007020:	fffff737          	lui	a4,0xfffff
    80007024:	00e7f7b3          	and	a5,a5,a4
    80007028:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    8000702c:	00400693          	li	a3,4
    80007030:	00002637          	lui	a2,0x2
    80007034:	00c78633          	add	a2,a5,a2
    80007038:	00078593          	mv	a1,a5
    8000703c:	000b0513          	mv	a0,s6
    80007040:	ffffb097          	auipc	ra,0xffffb
    80007044:	c68080e7          	jalr	-920(ra) # 80001ca8 <uvmalloc>
    80007048:	00050c13          	mv	s8,a0
  ip = 0;
    8000704c:	00000a93          	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    80007050:	18050263          	beqz	a0,800071d4 <kexec+0x3a4>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    80007054:	ffffe5b7          	lui	a1,0xffffe
    80007058:	00b505b3          	add	a1,a0,a1
    8000705c:	000b0513          	mv	a0,s6
    80007060:	ffffb097          	auipc	ra,0xffffb
    80007064:	f90080e7          	jalr	-112(ra) # 80001ff0 <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    80007068:	fffffab7          	lui	s5,0xfffff
    8000706c:	015c0ab3          	add	s5,s8,s5
  for(argc = 0; argv[argc]; argc++) {
    80007070:	df043783          	ld	a5,-528(s0)
    80007074:	0007b503          	ld	a0,0(a5)
    80007078:	08050463          	beqz	a0,80007100 <kexec+0x2d0>
    8000707c:	e9040993          	addi	s3,s0,-368
    80007080:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80007084:	000c0913          	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80007088:	00000493          	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000708c:	ffffa097          	auipc	ra,0xffffa
    80007090:	3d0080e7          	jalr	976(ra) # 8000145c <strlen>
    80007094:	0015079b          	addiw	a5,a0,1
    80007098:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000709c:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800070a0:	17596863          	bltu	s2,s5,80007210 <kexec+0x3e0>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800070a4:	df043d83          	ld	s11,-528(s0)
    800070a8:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800070ac:	000a0513          	mv	a0,s4
    800070b0:	ffffa097          	auipc	ra,0xffffa
    800070b4:	3ac080e7          	jalr	940(ra) # 8000145c <strlen>
    800070b8:	0015069b          	addiw	a3,a0,1
    800070bc:	000a0613          	mv	a2,s4
    800070c0:	00090593          	mv	a1,s2
    800070c4:	000b0513          	mv	a0,s6
    800070c8:	ffffb097          	auipc	ra,0xffffb
    800070cc:	1ac080e7          	jalr	428(ra) # 80002274 <copyout>
    800070d0:	14054663          	bltz	a0,8000721c <kexec+0x3ec>
    ustack[argc] = sp;
    800070d4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800070d8:	00148493          	addi	s1,s1,1
    800070dc:	008d8793          	addi	a5,s11,8
    800070e0:	def43823          	sd	a5,-528(s0)
    800070e4:	008db503          	ld	a0,8(s11)
    800070e8:	02050063          	beqz	a0,80007108 <kexec+0x2d8>
    if(argc >= MAXARG)
    800070ec:	00898993          	addi	s3,s3,8
    800070f0:	f93c9ee3          	bne	s9,s3,8000708c <kexec+0x25c>
  sz = sz1;
    800070f4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800070f8:	00000a93          	li	s5,0
    800070fc:	0d80006f          	j	800071d4 <kexec+0x3a4>
  sp = sz;
    80007100:	000c0913          	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80007104:	00000493          	li	s1,0
  ustack[argc] = 0;
    80007108:	00349793          	slli	a5,s1,0x3
    8000710c:	f9078793          	addi	a5,a5,-112
    80007110:	008787b3          	add	a5,a5,s0
    80007114:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80007118:	00148693          	addi	a3,s1,1
    8000711c:	00369693          	slli	a3,a3,0x3
    80007120:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80007124:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80007128:	01597863          	bgeu	s2,s5,80007138 <kexec+0x308>
  sz = sz1;
    8000712c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80007130:	00000a93          	li	s5,0
    80007134:	0a00006f          	j	800071d4 <kexec+0x3a4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80007138:	e9040613          	addi	a2,s0,-368
    8000713c:	00090593          	mv	a1,s2
    80007140:	000b0513          	mv	a0,s6
    80007144:	ffffb097          	auipc	ra,0xffffb
    80007148:	130080e7          	jalr	304(ra) # 80002274 <copyout>
    8000714c:	0c054e63          	bltz	a0,80007228 <kexec+0x3f8>
  p->trapframe->a1 = sp;
    80007150:	058bb783          	ld	a5,88(s7)
    80007154:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80007158:	de843783          	ld	a5,-536(s0)
    8000715c:	0007c703          	lbu	a4,0(a5)
    80007160:	02070463          	beqz	a4,80007188 <kexec+0x358>
    80007164:	00178793          	addi	a5,a5,1
    if(*s == '/')
    80007168:	02f00693          	li	a3,47
    8000716c:	0140006f          	j	80007180 <kexec+0x350>
      last = s+1;
    80007170:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80007174:	00178793          	addi	a5,a5,1
    80007178:	fff7c703          	lbu	a4,-1(a5)
    8000717c:	00070663          	beqz	a4,80007188 <kexec+0x358>
    if(*s == '/')
    80007180:	fed71ae3          	bne	a4,a3,80007174 <kexec+0x344>
    80007184:	fedff06f          	j	80007170 <kexec+0x340>
  safestrcpy(p->name, last, sizeof(p->name));
    80007188:	01000613          	li	a2,16
    8000718c:	de843583          	ld	a1,-536(s0)
    80007190:	158b8513          	addi	a0,s7,344
    80007194:	ffffa097          	auipc	ra,0xffffa
    80007198:	27c080e7          	jalr	636(ra) # 80001410 <safestrcpy>
  oldpagetable = p->pagetable;
    8000719c:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800071a0:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800071a4:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800071a8:	058bb783          	ld	a5,88(s7)
    800071ac:	e6843703          	ld	a4,-408(s0)
    800071b0:	00e7bc23          	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800071b4:	058bb783          	ld	a5,88(s7)
    800071b8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800071bc:	000d0593          	mv	a1,s10
    800071c0:	ffffb097          	auipc	ra,0xffffb
    800071c4:	7b8080e7          	jalr	1976(ra) # 80002978 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800071c8:	0004851b          	sext.w	a0,s1
    800071cc:	d29ff06f          	j	80006ef4 <kexec+0xc4>
    800071d0:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800071d4:	df843583          	ld	a1,-520(s0)
    800071d8:	000b0513          	mv	a0,s6
    800071dc:	ffffb097          	auipc	ra,0xffffb
    800071e0:	79c080e7          	jalr	1948(ra) # 80002978 <proc_freepagetable>
  if(ip){
    800071e4:	ce0a9ce3          	bnez	s5,80006edc <kexec+0xac>
  return -1;
    800071e8:	fff00513          	li	a0,-1
    800071ec:	d09ff06f          	j	80006ef4 <kexec+0xc4>
    800071f0:	df243c23          	sd	s2,-520(s0)
    800071f4:	fe1ff06f          	j	800071d4 <kexec+0x3a4>
    800071f8:	df243c23          	sd	s2,-520(s0)
    800071fc:	fd9ff06f          	j	800071d4 <kexec+0x3a4>
    80007200:	df243c23          	sd	s2,-520(s0)
    80007204:	fd1ff06f          	j	800071d4 <kexec+0x3a4>
    80007208:	df243c23          	sd	s2,-520(s0)
    8000720c:	fc9ff06f          	j	800071d4 <kexec+0x3a4>
  sz = sz1;
    80007210:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80007214:	00000a93          	li	s5,0
    80007218:	fbdff06f          	j	800071d4 <kexec+0x3a4>
  sz = sz1;
    8000721c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80007220:	00000a93          	li	s5,0
    80007224:	fb1ff06f          	j	800071d4 <kexec+0x3a4>
  sz = sz1;
    80007228:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000722c:	00000a93          	li	s5,0
    80007230:	fa5ff06f          	j	800071d4 <kexec+0x3a4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80007234:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80007238:	e0843783          	ld	a5,-504(s0)
    8000723c:	0017869b          	addiw	a3,a5,1
    80007240:	e0d43423          	sd	a3,-504(s0)
    80007244:	e0043783          	ld	a5,-512(s0)
    80007248:	0387879b          	addiw	a5,a5,56
    8000724c:	e8845703          	lhu	a4,-376(s0)
    80007250:	dae6d0e3          	bge	a3,a4,80006ff0 <kexec+0x1c0>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80007254:	0007879b          	sext.w	a5,a5
    80007258:	e0f43023          	sd	a5,-512(s0)
    8000725c:	03800713          	li	a4,56
    80007260:	00078693          	mv	a3,a5
    80007264:	e1840613          	addi	a2,s0,-488
    80007268:	00000593          	li	a1,0
    8000726c:	000a8513          	mv	a0,s5
    80007270:	ffffe097          	auipc	ra,0xffffe
    80007274:	1e0080e7          	jalr	480(ra) # 80005450 <readi>
    80007278:	03800793          	li	a5,56
    8000727c:	f4f51ae3          	bne	a0,a5,800071d0 <kexec+0x3a0>
    if(ph.type != ELF_PROG_LOAD)
    80007280:	e1842783          	lw	a5,-488(s0)
    80007284:	00100713          	li	a4,1
    80007288:	fae798e3          	bne	a5,a4,80007238 <kexec+0x408>
    if(ph.memsz < ph.filesz)
    8000728c:	e4043483          	ld	s1,-448(s0)
    80007290:	e3843783          	ld	a5,-456(s0)
    80007294:	f4f4eee3          	bltu	s1,a5,800071f0 <kexec+0x3c0>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80007298:	e2843783          	ld	a5,-472(s0)
    8000729c:	00f484b3          	add	s1,s1,a5
    800072a0:	f4f4ece3          	bltu	s1,a5,800071f8 <kexec+0x3c8>
    if(ph.vaddr % PGSIZE != 0)
    800072a4:	de043703          	ld	a4,-544(s0)
    800072a8:	00e7f7b3          	and	a5,a5,a4
    800072ac:	f4079ae3          	bnez	a5,80007200 <kexec+0x3d0>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800072b0:	e1c42503          	lw	a0,-484(s0)
    800072b4:	00000097          	auipc	ra,0x0
    800072b8:	b4c080e7          	jalr	-1204(ra) # 80006e00 <flags2perm>
    800072bc:	00050693          	mv	a3,a0
    800072c0:	00048613          	mv	a2,s1
    800072c4:	00090593          	mv	a1,s2
    800072c8:	000b0513          	mv	a0,s6
    800072cc:	ffffb097          	auipc	ra,0xffffb
    800072d0:	9dc080e7          	jalr	-1572(ra) # 80001ca8 <uvmalloc>
    800072d4:	dea43c23          	sd	a0,-520(s0)
    800072d8:	f20508e3          	beqz	a0,80007208 <kexec+0x3d8>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800072dc:	e2843c03          	ld	s8,-472(s0)
    800072e0:	e2042c83          	lw	s9,-480(s0)
    800072e4:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800072e8:	f40b86e3          	beqz	s7,80007234 <kexec+0x404>
    800072ec:	000b8993          	mv	s3,s7
    800072f0:	00000493          	li	s1,0
    800072f4:	cc9ff06f          	j	80006fbc <kexec+0x18c>

00000000800072f8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800072f8:	fd010113          	addi	sp,sp,-48
    800072fc:	02113423          	sd	ra,40(sp)
    80007300:	02813023          	sd	s0,32(sp)
    80007304:	00913c23          	sd	s1,24(sp)
    80007308:	01213823          	sd	s2,16(sp)
    8000730c:	03010413          	addi	s0,sp,48
    80007310:	00058913          	mv	s2,a1
    80007314:	00060493          	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80007318:	fdc40593          	addi	a1,s0,-36
    8000731c:	ffffd097          	auipc	ra,0xffffd
    80007320:	c18080e7          	jalr	-1000(ra) # 80003f34 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80007324:	fdc42703          	lw	a4,-36(s0)
    80007328:	00f00793          	li	a5,15
    8000732c:	04e7e863          	bltu	a5,a4,8000737c <argfd+0x84>
    80007330:	ffffb097          	auipc	ra,0xffffb
    80007334:	3b8080e7          	jalr	952(ra) # 800026e8 <myproc>
    80007338:	fdc42703          	lw	a4,-36(s0)
    8000733c:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdb342>
    80007340:	00379793          	slli	a5,a5,0x3
    80007344:	00f50533          	add	a0,a0,a5
    80007348:	00053783          	ld	a5,0(a0)
    8000734c:	02078c63          	beqz	a5,80007384 <argfd+0x8c>
    return -1;
  if(pfd)
    80007350:	00090463          	beqz	s2,80007358 <argfd+0x60>
    *pfd = fd;
    80007354:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80007358:	00000513          	li	a0,0
  if(pf)
    8000735c:	00048463          	beqz	s1,80007364 <argfd+0x6c>
    *pf = f;
    80007360:	00f4b023          	sd	a5,0(s1)
}
    80007364:	02813083          	ld	ra,40(sp)
    80007368:	02013403          	ld	s0,32(sp)
    8000736c:	01813483          	ld	s1,24(sp)
    80007370:	01013903          	ld	s2,16(sp)
    80007374:	03010113          	addi	sp,sp,48
    80007378:	00008067          	ret
    return -1;
    8000737c:	fff00513          	li	a0,-1
    80007380:	fe5ff06f          	j	80007364 <argfd+0x6c>
    80007384:	fff00513          	li	a0,-1
    80007388:	fddff06f          	j	80007364 <argfd+0x6c>

000000008000738c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000738c:	fe010113          	addi	sp,sp,-32
    80007390:	00113c23          	sd	ra,24(sp)
    80007394:	00813823          	sd	s0,16(sp)
    80007398:	00913423          	sd	s1,8(sp)
    8000739c:	02010413          	addi	s0,sp,32
    800073a0:	00050493          	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800073a4:	ffffb097          	auipc	ra,0xffffb
    800073a8:	344080e7          	jalr	836(ra) # 800026e8 <myproc>
    800073ac:	00050613          	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800073b0:	0d050793          	addi	a5,a0,208
    800073b4:	00000513          	li	a0,0
    800073b8:	01000693          	li	a3,16
    if(p->ofile[fd] == 0){
    800073bc:	0007b703          	ld	a4,0(a5)
    800073c0:	02070463          	beqz	a4,800073e8 <fdalloc+0x5c>
  for(fd = 0; fd < NOFILE; fd++){
    800073c4:	0015051b          	addiw	a0,a0,1
    800073c8:	00878793          	addi	a5,a5,8
    800073cc:	fed518e3          	bne	a0,a3,800073bc <fdalloc+0x30>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800073d0:	fff00513          	li	a0,-1
}
    800073d4:	01813083          	ld	ra,24(sp)
    800073d8:	01013403          	ld	s0,16(sp)
    800073dc:	00813483          	ld	s1,8(sp)
    800073e0:	02010113          	addi	sp,sp,32
    800073e4:	00008067          	ret
      p->ofile[fd] = f;
    800073e8:	01a50793          	addi	a5,a0,26
    800073ec:	00379793          	slli	a5,a5,0x3
    800073f0:	00f60633          	add	a2,a2,a5
    800073f4:	00963023          	sd	s1,0(a2) # 2000 <_entry-0x7fffe000>
      return fd;
    800073f8:	fddff06f          	j	800073d4 <fdalloc+0x48>

00000000800073fc <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800073fc:	fb010113          	addi	sp,sp,-80
    80007400:	04113423          	sd	ra,72(sp)
    80007404:	04813023          	sd	s0,64(sp)
    80007408:	02913c23          	sd	s1,56(sp)
    8000740c:	03213823          	sd	s2,48(sp)
    80007410:	03313423          	sd	s3,40(sp)
    80007414:	03413023          	sd	s4,32(sp)
    80007418:	01513c23          	sd	s5,24(sp)
    8000741c:	01613823          	sd	s6,16(sp)
    80007420:	05010413          	addi	s0,sp,80
    80007424:	00058b13          	mv	s6,a1
    80007428:	00060993          	mv	s3,a2
    8000742c:	00068913          	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80007430:	fb040593          	addi	a1,s0,-80
    80007434:	ffffe097          	auipc	ra,0xffffe
    80007438:	780080e7          	jalr	1920(ra) # 80005bb4 <nameiparent>
    8000743c:	00050493          	mv	s1,a0
    80007440:	1c050063          	beqz	a0,80007600 <create+0x204>
    return 0;

  ilock(dp);
    80007444:	ffffe097          	auipc	ra,0xffffe
    80007448:	a54080e7          	jalr	-1452(ra) # 80004e98 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000744c:	00000613          	li	a2,0
    80007450:	fb040593          	addi	a1,s0,-80
    80007454:	00048513          	mv	a0,s1
    80007458:	ffffe097          	auipc	ra,0xffffe
    8000745c:	330080e7          	jalr	816(ra) # 80005788 <dirlookup>
    80007460:	00050a93          	mv	s5,a0
    80007464:	08050063          	beqz	a0,800074e4 <create+0xe8>
    iunlockput(dp);
    80007468:	00048513          	mv	a0,s1
    8000746c:	ffffe097          	auipc	ra,0xffffe
    80007470:	d68080e7          	jalr	-664(ra) # 800051d4 <iunlockput>
    ilock(ip);
    80007474:	000a8513          	mv	a0,s5
    80007478:	ffffe097          	auipc	ra,0xffffe
    8000747c:	a20080e7          	jalr	-1504(ra) # 80004e98 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80007480:	000b059b          	sext.w	a1,s6
    80007484:	00200793          	li	a5,2
    80007488:	04f59463          	bne	a1,a5,800074d0 <create+0xd4>
    8000748c:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdb36c>
    80007490:	ffe7879b          	addiw	a5,a5,-2
    80007494:	03079793          	slli	a5,a5,0x30
    80007498:	0307d793          	srli	a5,a5,0x30
    8000749c:	00100713          	li	a4,1
    800074a0:	02f76863          	bltu	a4,a5,800074d0 <create+0xd4>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800074a4:	000a8513          	mv	a0,s5
    800074a8:	04813083          	ld	ra,72(sp)
    800074ac:	04013403          	ld	s0,64(sp)
    800074b0:	03813483          	ld	s1,56(sp)
    800074b4:	03013903          	ld	s2,48(sp)
    800074b8:	02813983          	ld	s3,40(sp)
    800074bc:	02013a03          	ld	s4,32(sp)
    800074c0:	01813a83          	ld	s5,24(sp)
    800074c4:	01013b03          	ld	s6,16(sp)
    800074c8:	05010113          	addi	sp,sp,80
    800074cc:	00008067          	ret
    iunlockput(ip);
    800074d0:	000a8513          	mv	a0,s5
    800074d4:	ffffe097          	auipc	ra,0xffffe
    800074d8:	d00080e7          	jalr	-768(ra) # 800051d4 <iunlockput>
    return 0;
    800074dc:	00000a93          	li	s5,0
    800074e0:	fc5ff06f          	j	800074a4 <create+0xa8>
  if((ip = ialloc(dp->dev, type)) == 0){
    800074e4:	000b0593          	mv	a1,s6
    800074e8:	0004a503          	lw	a0,0(s1)
    800074ec:	ffffd097          	auipc	ra,0xffffd
    800074f0:	76c080e7          	jalr	1900(ra) # 80004c58 <ialloc>
    800074f4:	00050a13          	mv	s4,a0
    800074f8:	04050e63          	beqz	a0,80007554 <create+0x158>
  ilock(ip);
    800074fc:	ffffe097          	auipc	ra,0xffffe
    80007500:	99c080e7          	jalr	-1636(ra) # 80004e98 <ilock>
  ip->major = major;
    80007504:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80007508:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000750c:	00100913          	li	s2,1
    80007510:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80007514:	000a0513          	mv	a0,s4
    80007518:	ffffe097          	auipc	ra,0xffffe
    8000751c:	864080e7          	jalr	-1948(ra) # 80004d7c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80007520:	000b059b          	sext.w	a1,s6
    80007524:	05258263          	beq	a1,s2,80007568 <create+0x16c>
  if(dirlink(dp, name, ip->inum) < 0)
    80007528:	004a2603          	lw	a2,4(s4)
    8000752c:	fb040593          	addi	a1,s0,-80
    80007530:	00048513          	mv	a0,s1
    80007534:	ffffe097          	auipc	ra,0xffffe
    80007538:	550080e7          	jalr	1360(ra) # 80005a84 <dirlink>
    8000753c:	08054c63          	bltz	a0,800075d4 <create+0x1d8>
  iunlockput(dp);
    80007540:	00048513          	mv	a0,s1
    80007544:	ffffe097          	auipc	ra,0xffffe
    80007548:	c90080e7          	jalr	-880(ra) # 800051d4 <iunlockput>
  return ip;
    8000754c:	000a0a93          	mv	s5,s4
    80007550:	f55ff06f          	j	800074a4 <create+0xa8>
    iunlockput(dp);
    80007554:	00048513          	mv	a0,s1
    80007558:	ffffe097          	auipc	ra,0xffffe
    8000755c:	c7c080e7          	jalr	-900(ra) # 800051d4 <iunlockput>
    return 0;
    80007560:	000a0a93          	mv	s5,s4
    80007564:	f41ff06f          	j	800074a4 <create+0xa8>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80007568:	004a2603          	lw	a2,4(s4)
    8000756c:	00003597          	auipc	a1,0x3
    80007570:	2d458593          	addi	a1,a1,724 # 8000a840 <syscalls+0x2e0>
    80007574:	000a0513          	mv	a0,s4
    80007578:	ffffe097          	auipc	ra,0xffffe
    8000757c:	50c080e7          	jalr	1292(ra) # 80005a84 <dirlink>
    80007580:	04054a63          	bltz	a0,800075d4 <create+0x1d8>
    80007584:	0044a603          	lw	a2,4(s1)
    80007588:	00003597          	auipc	a1,0x3
    8000758c:	2c058593          	addi	a1,a1,704 # 8000a848 <syscalls+0x2e8>
    80007590:	000a0513          	mv	a0,s4
    80007594:	ffffe097          	auipc	ra,0xffffe
    80007598:	4f0080e7          	jalr	1264(ra) # 80005a84 <dirlink>
    8000759c:	02054c63          	bltz	a0,800075d4 <create+0x1d8>
  if(dirlink(dp, name, ip->inum) < 0)
    800075a0:	004a2603          	lw	a2,4(s4)
    800075a4:	fb040593          	addi	a1,s0,-80
    800075a8:	00048513          	mv	a0,s1
    800075ac:	ffffe097          	auipc	ra,0xffffe
    800075b0:	4d8080e7          	jalr	1240(ra) # 80005a84 <dirlink>
    800075b4:	02054063          	bltz	a0,800075d4 <create+0x1d8>
    dp->nlink++;  // for ".."
    800075b8:	04a4d783          	lhu	a5,74(s1)
    800075bc:	0017879b          	addiw	a5,a5,1
    800075c0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800075c4:	00048513          	mv	a0,s1
    800075c8:	ffffd097          	auipc	ra,0xffffd
    800075cc:	7b4080e7          	jalr	1972(ra) # 80004d7c <iupdate>
    800075d0:	f71ff06f          	j	80007540 <create+0x144>
  ip->nlink = 0;
    800075d4:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800075d8:	000a0513          	mv	a0,s4
    800075dc:	ffffd097          	auipc	ra,0xffffd
    800075e0:	7a0080e7          	jalr	1952(ra) # 80004d7c <iupdate>
  iunlockput(ip);
    800075e4:	000a0513          	mv	a0,s4
    800075e8:	ffffe097          	auipc	ra,0xffffe
    800075ec:	bec080e7          	jalr	-1044(ra) # 800051d4 <iunlockput>
  iunlockput(dp);
    800075f0:	00048513          	mv	a0,s1
    800075f4:	ffffe097          	auipc	ra,0xffffe
    800075f8:	be0080e7          	jalr	-1056(ra) # 800051d4 <iunlockput>
  return 0;
    800075fc:	ea9ff06f          	j	800074a4 <create+0xa8>
    return 0;
    80007600:	00050a93          	mv	s5,a0
    80007604:	ea1ff06f          	j	800074a4 <create+0xa8>

0000000080007608 <sys_dup>:
{
    80007608:	fd010113          	addi	sp,sp,-48
    8000760c:	02113423          	sd	ra,40(sp)
    80007610:	02813023          	sd	s0,32(sp)
    80007614:	00913c23          	sd	s1,24(sp)
    80007618:	01213823          	sd	s2,16(sp)
    8000761c:	03010413          	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80007620:	fd840613          	addi	a2,s0,-40
    80007624:	00000593          	li	a1,0
    80007628:	00000513          	li	a0,0
    8000762c:	00000097          	auipc	ra,0x0
    80007630:	ccc080e7          	jalr	-820(ra) # 800072f8 <argfd>
    return -1;
    80007634:	fff00793          	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80007638:	02054863          	bltz	a0,80007668 <sys_dup+0x60>
  if((fd=fdalloc(f)) < 0)
    8000763c:	fd843903          	ld	s2,-40(s0)
    80007640:	00090513          	mv	a0,s2
    80007644:	00000097          	auipc	ra,0x0
    80007648:	d48080e7          	jalr	-696(ra) # 8000738c <fdalloc>
    8000764c:	00050493          	mv	s1,a0
    return -1;
    80007650:	fff00793          	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80007654:	00054a63          	bltz	a0,80007668 <sys_dup+0x60>
  filedup(f);
    80007658:	00090513          	mv	a0,s2
    8000765c:	fffff097          	auipc	ra,0xfffff
    80007660:	e48080e7          	jalr	-440(ra) # 800064a4 <filedup>
  return fd;
    80007664:	00048793          	mv	a5,s1
}
    80007668:	00078513          	mv	a0,a5
    8000766c:	02813083          	ld	ra,40(sp)
    80007670:	02013403          	ld	s0,32(sp)
    80007674:	01813483          	ld	s1,24(sp)
    80007678:	01013903          	ld	s2,16(sp)
    8000767c:	03010113          	addi	sp,sp,48
    80007680:	00008067          	ret

0000000080007684 <sys_read>:
{
    80007684:	fd010113          	addi	sp,sp,-48
    80007688:	02113423          	sd	ra,40(sp)
    8000768c:	02813023          	sd	s0,32(sp)
    80007690:	03010413          	addi	s0,sp,48
  argaddr(1, &p);
    80007694:	fd840593          	addi	a1,s0,-40
    80007698:	00100513          	li	a0,1
    8000769c:	ffffd097          	auipc	ra,0xffffd
    800076a0:	8d0080e7          	jalr	-1840(ra) # 80003f6c <argaddr>
  argint(2, &n);
    800076a4:	fe440593          	addi	a1,s0,-28
    800076a8:	00200513          	li	a0,2
    800076ac:	ffffd097          	auipc	ra,0xffffd
    800076b0:	888080e7          	jalr	-1912(ra) # 80003f34 <argint>
  if(argfd(0, 0, &f) < 0)
    800076b4:	fe840613          	addi	a2,s0,-24
    800076b8:	00000593          	li	a1,0
    800076bc:	00000513          	li	a0,0
    800076c0:	00000097          	auipc	ra,0x0
    800076c4:	c38080e7          	jalr	-968(ra) # 800072f8 <argfd>
    800076c8:	00050793          	mv	a5,a0
    return -1;
    800076cc:	fff00513          	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800076d0:	0007cc63          	bltz	a5,800076e8 <sys_read+0x64>
  return fileread(f, p, n);
    800076d4:	fe442603          	lw	a2,-28(s0)
    800076d8:	fd843583          	ld	a1,-40(s0)
    800076dc:	fe843503          	ld	a0,-24(s0)
    800076e0:	fffff097          	auipc	ra,0xfffff
    800076e4:	fe0080e7          	jalr	-32(ra) # 800066c0 <fileread>
}
    800076e8:	02813083          	ld	ra,40(sp)
    800076ec:	02013403          	ld	s0,32(sp)
    800076f0:	03010113          	addi	sp,sp,48
    800076f4:	00008067          	ret

00000000800076f8 <sys_write>:
{
    800076f8:	fd010113          	addi	sp,sp,-48
    800076fc:	02113423          	sd	ra,40(sp)
    80007700:	02813023          	sd	s0,32(sp)
    80007704:	03010413          	addi	s0,sp,48
  argaddr(1, &p);
    80007708:	fd840593          	addi	a1,s0,-40
    8000770c:	00100513          	li	a0,1
    80007710:	ffffd097          	auipc	ra,0xffffd
    80007714:	85c080e7          	jalr	-1956(ra) # 80003f6c <argaddr>
  argint(2, &n);
    80007718:	fe440593          	addi	a1,s0,-28
    8000771c:	00200513          	li	a0,2
    80007720:	ffffd097          	auipc	ra,0xffffd
    80007724:	814080e7          	jalr	-2028(ra) # 80003f34 <argint>
  if(argfd(0, 0, &f) < 0)
    80007728:	fe840613          	addi	a2,s0,-24
    8000772c:	00000593          	li	a1,0
    80007730:	00000513          	li	a0,0
    80007734:	00000097          	auipc	ra,0x0
    80007738:	bc4080e7          	jalr	-1084(ra) # 800072f8 <argfd>
    8000773c:	00050793          	mv	a5,a0
    return -1;
    80007740:	fff00513          	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80007744:	0007cc63          	bltz	a5,8000775c <sys_write+0x64>
  return filewrite(f, p, n);
    80007748:	fe442603          	lw	a2,-28(s0)
    8000774c:	fd843583          	ld	a1,-40(s0)
    80007750:	fe843503          	ld	a0,-24(s0)
    80007754:	fffff097          	auipc	ra,0xfffff
    80007758:	098080e7          	jalr	152(ra) # 800067ec <filewrite>
}
    8000775c:	02813083          	ld	ra,40(sp)
    80007760:	02013403          	ld	s0,32(sp)
    80007764:	03010113          	addi	sp,sp,48
    80007768:	00008067          	ret

000000008000776c <sys_close>:
{
    8000776c:	fe010113          	addi	sp,sp,-32
    80007770:	00113c23          	sd	ra,24(sp)
    80007774:	00813823          	sd	s0,16(sp)
    80007778:	02010413          	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000777c:	fe040613          	addi	a2,s0,-32
    80007780:	fec40593          	addi	a1,s0,-20
    80007784:	00000513          	li	a0,0
    80007788:	00000097          	auipc	ra,0x0
    8000778c:	b70080e7          	jalr	-1168(ra) # 800072f8 <argfd>
    return -1;
    80007790:	fff00793          	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80007794:	02054863          	bltz	a0,800077c4 <sys_close+0x58>
  myproc()->ofile[fd] = 0;
    80007798:	ffffb097          	auipc	ra,0xffffb
    8000779c:	f50080e7          	jalr	-176(ra) # 800026e8 <myproc>
    800077a0:	fec42783          	lw	a5,-20(s0)
    800077a4:	01a78793          	addi	a5,a5,26
    800077a8:	00379793          	slli	a5,a5,0x3
    800077ac:	00f50533          	add	a0,a0,a5
    800077b0:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800077b4:	fe043503          	ld	a0,-32(s0)
    800077b8:	fffff097          	auipc	ra,0xfffff
    800077bc:	d5c080e7          	jalr	-676(ra) # 80006514 <fileclose>
  return 0;
    800077c0:	00000793          	li	a5,0
}
    800077c4:	00078513          	mv	a0,a5
    800077c8:	01813083          	ld	ra,24(sp)
    800077cc:	01013403          	ld	s0,16(sp)
    800077d0:	02010113          	addi	sp,sp,32
    800077d4:	00008067          	ret

00000000800077d8 <sys_fstat>:
{
    800077d8:	fe010113          	addi	sp,sp,-32
    800077dc:	00113c23          	sd	ra,24(sp)
    800077e0:	00813823          	sd	s0,16(sp)
    800077e4:	02010413          	addi	s0,sp,32
  argaddr(1, &st);
    800077e8:	fe040593          	addi	a1,s0,-32
    800077ec:	00100513          	li	a0,1
    800077f0:	ffffc097          	auipc	ra,0xffffc
    800077f4:	77c080e7          	jalr	1916(ra) # 80003f6c <argaddr>
  if(argfd(0, 0, &f) < 0)
    800077f8:	fe840613          	addi	a2,s0,-24
    800077fc:	00000593          	li	a1,0
    80007800:	00000513          	li	a0,0
    80007804:	00000097          	auipc	ra,0x0
    80007808:	af4080e7          	jalr	-1292(ra) # 800072f8 <argfd>
    8000780c:	00050793          	mv	a5,a0
    return -1;
    80007810:	fff00513          	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80007814:	0007ca63          	bltz	a5,80007828 <sys_fstat+0x50>
  return filestat(f, st);
    80007818:	fe043583          	ld	a1,-32(s0)
    8000781c:	fe843503          	ld	a0,-24(s0)
    80007820:	fffff097          	auipc	ra,0xfffff
    80007824:	df8080e7          	jalr	-520(ra) # 80006618 <filestat>
}
    80007828:	01813083          	ld	ra,24(sp)
    8000782c:	01013403          	ld	s0,16(sp)
    80007830:	02010113          	addi	sp,sp,32
    80007834:	00008067          	ret

0000000080007838 <sys_link>:
{
    80007838:	ed010113          	addi	sp,sp,-304
    8000783c:	12113423          	sd	ra,296(sp)
    80007840:	12813023          	sd	s0,288(sp)
    80007844:	10913c23          	sd	s1,280(sp)
    80007848:	11213823          	sd	s2,272(sp)
    8000784c:	13010413          	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80007850:	08000613          	li	a2,128
    80007854:	ed040593          	addi	a1,s0,-304
    80007858:	00000513          	li	a0,0
    8000785c:	ffffc097          	auipc	ra,0xffffc
    80007860:	748080e7          	jalr	1864(ra) # 80003fa4 <argstr>
    return -1;
    80007864:	fff00793          	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80007868:	14054a63          	bltz	a0,800079bc <sys_link+0x184>
    8000786c:	08000613          	li	a2,128
    80007870:	f5040593          	addi	a1,s0,-176
    80007874:	00100513          	li	a0,1
    80007878:	ffffc097          	auipc	ra,0xffffc
    8000787c:	72c080e7          	jalr	1836(ra) # 80003fa4 <argstr>
    return -1;
    80007880:	fff00793          	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80007884:	12054c63          	bltz	a0,800079bc <sys_link+0x184>
  begin_op();
    80007888:	ffffe097          	auipc	ra,0xffffe
    8000788c:	610080e7          	jalr	1552(ra) # 80005e98 <begin_op>
  if((ip = namei(old)) == 0){
    80007890:	ed040513          	addi	a0,s0,-304
    80007894:	ffffe097          	auipc	ra,0xffffe
    80007898:	2f0080e7          	jalr	752(ra) # 80005b84 <namei>
    8000789c:	00050493          	mv	s1,a0
    800078a0:	0a050463          	beqz	a0,80007948 <sys_link+0x110>
  ilock(ip);
    800078a4:	ffffd097          	auipc	ra,0xffffd
    800078a8:	5f4080e7          	jalr	1524(ra) # 80004e98 <ilock>
  if(ip->type == T_DIR){
    800078ac:	04449703          	lh	a4,68(s1)
    800078b0:	00100793          	li	a5,1
    800078b4:	0af70263          	beq	a4,a5,80007958 <sys_link+0x120>
  ip->nlink++;
    800078b8:	04a4d783          	lhu	a5,74(s1)
    800078bc:	0017879b          	addiw	a5,a5,1
    800078c0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800078c4:	00048513          	mv	a0,s1
    800078c8:	ffffd097          	auipc	ra,0xffffd
    800078cc:	4b4080e7          	jalr	1204(ra) # 80004d7c <iupdate>
  iunlock(ip);
    800078d0:	00048513          	mv	a0,s1
    800078d4:	ffffd097          	auipc	ra,0xffffd
    800078d8:	6c8080e7          	jalr	1736(ra) # 80004f9c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800078dc:	fd040593          	addi	a1,s0,-48
    800078e0:	f5040513          	addi	a0,s0,-176
    800078e4:	ffffe097          	auipc	ra,0xffffe
    800078e8:	2d0080e7          	jalr	720(ra) # 80005bb4 <nameiparent>
    800078ec:	00050913          	mv	s2,a0
    800078f0:	08050863          	beqz	a0,80007980 <sys_link+0x148>
  ilock(dp);
    800078f4:	ffffd097          	auipc	ra,0xffffd
    800078f8:	5a4080e7          	jalr	1444(ra) # 80004e98 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800078fc:	00092703          	lw	a4,0(s2)
    80007900:	0004a783          	lw	a5,0(s1)
    80007904:	06f71863          	bne	a4,a5,80007974 <sys_link+0x13c>
    80007908:	0044a603          	lw	a2,4(s1)
    8000790c:	fd040593          	addi	a1,s0,-48
    80007910:	00090513          	mv	a0,s2
    80007914:	ffffe097          	auipc	ra,0xffffe
    80007918:	170080e7          	jalr	368(ra) # 80005a84 <dirlink>
    8000791c:	04054c63          	bltz	a0,80007974 <sys_link+0x13c>
  iunlockput(dp);
    80007920:	00090513          	mv	a0,s2
    80007924:	ffffe097          	auipc	ra,0xffffe
    80007928:	8b0080e7          	jalr	-1872(ra) # 800051d4 <iunlockput>
  iput(ip);
    8000792c:	00048513          	mv	a0,s1
    80007930:	ffffd097          	auipc	ra,0xffffd
    80007934:	7c8080e7          	jalr	1992(ra) # 800050f8 <iput>
  end_op();
    80007938:	ffffe097          	auipc	ra,0xffffe
    8000793c:	614080e7          	jalr	1556(ra) # 80005f4c <end_op>
  return 0;
    80007940:	00000793          	li	a5,0
    80007944:	0780006f          	j	800079bc <sys_link+0x184>
    end_op();
    80007948:	ffffe097          	auipc	ra,0xffffe
    8000794c:	604080e7          	jalr	1540(ra) # 80005f4c <end_op>
    return -1;
    80007950:	fff00793          	li	a5,-1
    80007954:	0680006f          	j	800079bc <sys_link+0x184>
    iunlockput(ip);
    80007958:	00048513          	mv	a0,s1
    8000795c:	ffffe097          	auipc	ra,0xffffe
    80007960:	878080e7          	jalr	-1928(ra) # 800051d4 <iunlockput>
    end_op();
    80007964:	ffffe097          	auipc	ra,0xffffe
    80007968:	5e8080e7          	jalr	1512(ra) # 80005f4c <end_op>
    return -1;
    8000796c:	fff00793          	li	a5,-1
    80007970:	04c0006f          	j	800079bc <sys_link+0x184>
    iunlockput(dp);
    80007974:	00090513          	mv	a0,s2
    80007978:	ffffe097          	auipc	ra,0xffffe
    8000797c:	85c080e7          	jalr	-1956(ra) # 800051d4 <iunlockput>
  ilock(ip);
    80007980:	00048513          	mv	a0,s1
    80007984:	ffffd097          	auipc	ra,0xffffd
    80007988:	514080e7          	jalr	1300(ra) # 80004e98 <ilock>
  ip->nlink--;
    8000798c:	04a4d783          	lhu	a5,74(s1)
    80007990:	fff7879b          	addiw	a5,a5,-1
    80007994:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80007998:	00048513          	mv	a0,s1
    8000799c:	ffffd097          	auipc	ra,0xffffd
    800079a0:	3e0080e7          	jalr	992(ra) # 80004d7c <iupdate>
  iunlockput(ip);
    800079a4:	00048513          	mv	a0,s1
    800079a8:	ffffe097          	auipc	ra,0xffffe
    800079ac:	82c080e7          	jalr	-2004(ra) # 800051d4 <iunlockput>
  end_op();
    800079b0:	ffffe097          	auipc	ra,0xffffe
    800079b4:	59c080e7          	jalr	1436(ra) # 80005f4c <end_op>
  return -1;
    800079b8:	fff00793          	li	a5,-1
}
    800079bc:	00078513          	mv	a0,a5
    800079c0:	12813083          	ld	ra,296(sp)
    800079c4:	12013403          	ld	s0,288(sp)
    800079c8:	11813483          	ld	s1,280(sp)
    800079cc:	11013903          	ld	s2,272(sp)
    800079d0:	13010113          	addi	sp,sp,304
    800079d4:	00008067          	ret

00000000800079d8 <sys_unlink>:
{
    800079d8:	f1010113          	addi	sp,sp,-240
    800079dc:	0e113423          	sd	ra,232(sp)
    800079e0:	0e813023          	sd	s0,224(sp)
    800079e4:	0c913c23          	sd	s1,216(sp)
    800079e8:	0d213823          	sd	s2,208(sp)
    800079ec:	0d313423          	sd	s3,200(sp)
    800079f0:	0f010413          	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800079f4:	08000613          	li	a2,128
    800079f8:	f3040593          	addi	a1,s0,-208
    800079fc:	00000513          	li	a0,0
    80007a00:	ffffc097          	auipc	ra,0xffffc
    80007a04:	5a4080e7          	jalr	1444(ra) # 80003fa4 <argstr>
    80007a08:	1c054063          	bltz	a0,80007bc8 <sys_unlink+0x1f0>
  begin_op();
    80007a0c:	ffffe097          	auipc	ra,0xffffe
    80007a10:	48c080e7          	jalr	1164(ra) # 80005e98 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80007a14:	fb040593          	addi	a1,s0,-80
    80007a18:	f3040513          	addi	a0,s0,-208
    80007a1c:	ffffe097          	auipc	ra,0xffffe
    80007a20:	198080e7          	jalr	408(ra) # 80005bb4 <nameiparent>
    80007a24:	00050493          	mv	s1,a0
    80007a28:	0e050c63          	beqz	a0,80007b20 <sys_unlink+0x148>
  ilock(dp);
    80007a2c:	ffffd097          	auipc	ra,0xffffd
    80007a30:	46c080e7          	jalr	1132(ra) # 80004e98 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80007a34:	00003597          	auipc	a1,0x3
    80007a38:	e0c58593          	addi	a1,a1,-500 # 8000a840 <syscalls+0x2e0>
    80007a3c:	fb040513          	addi	a0,s0,-80
    80007a40:	ffffe097          	auipc	ra,0xffffe
    80007a44:	d1c080e7          	jalr	-740(ra) # 8000575c <namecmp>
    80007a48:	18050a63          	beqz	a0,80007bdc <sys_unlink+0x204>
    80007a4c:	00003597          	auipc	a1,0x3
    80007a50:	dfc58593          	addi	a1,a1,-516 # 8000a848 <syscalls+0x2e8>
    80007a54:	fb040513          	addi	a0,s0,-80
    80007a58:	ffffe097          	auipc	ra,0xffffe
    80007a5c:	d04080e7          	jalr	-764(ra) # 8000575c <namecmp>
    80007a60:	16050e63          	beqz	a0,80007bdc <sys_unlink+0x204>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80007a64:	f2c40613          	addi	a2,s0,-212
    80007a68:	fb040593          	addi	a1,s0,-80
    80007a6c:	00048513          	mv	a0,s1
    80007a70:	ffffe097          	auipc	ra,0xffffe
    80007a74:	d18080e7          	jalr	-744(ra) # 80005788 <dirlookup>
    80007a78:	00050913          	mv	s2,a0
    80007a7c:	16050063          	beqz	a0,80007bdc <sys_unlink+0x204>
  ilock(ip);
    80007a80:	ffffd097          	auipc	ra,0xffffd
    80007a84:	418080e7          	jalr	1048(ra) # 80004e98 <ilock>
  if(ip->nlink < 1)
    80007a88:	04a91783          	lh	a5,74(s2)
    80007a8c:	0af05263          	blez	a5,80007b30 <sys_unlink+0x158>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80007a90:	04491703          	lh	a4,68(s2)
    80007a94:	00100793          	li	a5,1
    80007a98:	0af70463          	beq	a4,a5,80007b40 <sys_unlink+0x168>
  memset(&de, 0, sizeof(de));
    80007a9c:	01000613          	li	a2,16
    80007aa0:	00000593          	li	a1,0
    80007aa4:	fc040513          	addi	a0,s0,-64
    80007aa8:	ffff9097          	auipc	ra,0xffff9
    80007aac:	768080e7          	jalr	1896(ra) # 80001210 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80007ab0:	01000713          	li	a4,16
    80007ab4:	f2c42683          	lw	a3,-212(s0)
    80007ab8:	fc040613          	addi	a2,s0,-64
    80007abc:	00000593          	li	a1,0
    80007ac0:	00048513          	mv	a0,s1
    80007ac4:	ffffe097          	auipc	ra,0xffffe
    80007ac8:	afc080e7          	jalr	-1284(ra) # 800055c0 <writei>
    80007acc:	01000793          	li	a5,16
    80007ad0:	0cf51663          	bne	a0,a5,80007b9c <sys_unlink+0x1c4>
  if(ip->type == T_DIR){
    80007ad4:	04491703          	lh	a4,68(s2)
    80007ad8:	00100793          	li	a5,1
    80007adc:	0cf70863          	beq	a4,a5,80007bac <sys_unlink+0x1d4>
  iunlockput(dp);
    80007ae0:	00048513          	mv	a0,s1
    80007ae4:	ffffd097          	auipc	ra,0xffffd
    80007ae8:	6f0080e7          	jalr	1776(ra) # 800051d4 <iunlockput>
  ip->nlink--;
    80007aec:	04a95783          	lhu	a5,74(s2)
    80007af0:	fff7879b          	addiw	a5,a5,-1
    80007af4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80007af8:	00090513          	mv	a0,s2
    80007afc:	ffffd097          	auipc	ra,0xffffd
    80007b00:	280080e7          	jalr	640(ra) # 80004d7c <iupdate>
  iunlockput(ip);
    80007b04:	00090513          	mv	a0,s2
    80007b08:	ffffd097          	auipc	ra,0xffffd
    80007b0c:	6cc080e7          	jalr	1740(ra) # 800051d4 <iunlockput>
  end_op();
    80007b10:	ffffe097          	auipc	ra,0xffffe
    80007b14:	43c080e7          	jalr	1084(ra) # 80005f4c <end_op>
  return 0;
    80007b18:	00000513          	li	a0,0
    80007b1c:	0d80006f          	j	80007bf4 <sys_unlink+0x21c>
    end_op();
    80007b20:	ffffe097          	auipc	ra,0xffffe
    80007b24:	42c080e7          	jalr	1068(ra) # 80005f4c <end_op>
    return -1;
    80007b28:	fff00513          	li	a0,-1
    80007b2c:	0c80006f          	j	80007bf4 <sys_unlink+0x21c>
    panic("unlink: nlink < 1");
    80007b30:	00003517          	auipc	a0,0x3
    80007b34:	d2050513          	addi	a0,a0,-736 # 8000a850 <syscalls+0x2f0>
    80007b38:	ffff9097          	auipc	ra,0xffff9
    80007b3c:	f48080e7          	jalr	-184(ra) # 80000a80 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80007b40:	04c92703          	lw	a4,76(s2)
    80007b44:	02000793          	li	a5,32
    80007b48:	f4e7fae3          	bgeu	a5,a4,80007a9c <sys_unlink+0xc4>
    80007b4c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80007b50:	01000713          	li	a4,16
    80007b54:	00098693          	mv	a3,s3
    80007b58:	f1840613          	addi	a2,s0,-232
    80007b5c:	00000593          	li	a1,0
    80007b60:	00090513          	mv	a0,s2
    80007b64:	ffffe097          	auipc	ra,0xffffe
    80007b68:	8ec080e7          	jalr	-1812(ra) # 80005450 <readi>
    80007b6c:	01000793          	li	a5,16
    80007b70:	00f51e63          	bne	a0,a5,80007b8c <sys_unlink+0x1b4>
    if(de.inum != 0)
    80007b74:	f1845783          	lhu	a5,-232(s0)
    80007b78:	04079c63          	bnez	a5,80007bd0 <sys_unlink+0x1f8>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80007b7c:	0109899b          	addiw	s3,s3,16
    80007b80:	04c92783          	lw	a5,76(s2)
    80007b84:	fcf9e6e3          	bltu	s3,a5,80007b50 <sys_unlink+0x178>
    80007b88:	f15ff06f          	j	80007a9c <sys_unlink+0xc4>
      panic("isdirempty: readi");
    80007b8c:	00003517          	auipc	a0,0x3
    80007b90:	cdc50513          	addi	a0,a0,-804 # 8000a868 <syscalls+0x308>
    80007b94:	ffff9097          	auipc	ra,0xffff9
    80007b98:	eec080e7          	jalr	-276(ra) # 80000a80 <panic>
    panic("unlink: writei");
    80007b9c:	00003517          	auipc	a0,0x3
    80007ba0:	ce450513          	addi	a0,a0,-796 # 8000a880 <syscalls+0x320>
    80007ba4:	ffff9097          	auipc	ra,0xffff9
    80007ba8:	edc080e7          	jalr	-292(ra) # 80000a80 <panic>
    dp->nlink--;
    80007bac:	04a4d783          	lhu	a5,74(s1)
    80007bb0:	fff7879b          	addiw	a5,a5,-1
    80007bb4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80007bb8:	00048513          	mv	a0,s1
    80007bbc:	ffffd097          	auipc	ra,0xffffd
    80007bc0:	1c0080e7          	jalr	448(ra) # 80004d7c <iupdate>
    80007bc4:	f1dff06f          	j	80007ae0 <sys_unlink+0x108>
    return -1;
    80007bc8:	fff00513          	li	a0,-1
    80007bcc:	0280006f          	j	80007bf4 <sys_unlink+0x21c>
    iunlockput(ip);
    80007bd0:	00090513          	mv	a0,s2
    80007bd4:	ffffd097          	auipc	ra,0xffffd
    80007bd8:	600080e7          	jalr	1536(ra) # 800051d4 <iunlockput>
  iunlockput(dp);
    80007bdc:	00048513          	mv	a0,s1
    80007be0:	ffffd097          	auipc	ra,0xffffd
    80007be4:	5f4080e7          	jalr	1524(ra) # 800051d4 <iunlockput>
  end_op();
    80007be8:	ffffe097          	auipc	ra,0xffffe
    80007bec:	364080e7          	jalr	868(ra) # 80005f4c <end_op>
  return -1;
    80007bf0:	fff00513          	li	a0,-1
}
    80007bf4:	0e813083          	ld	ra,232(sp)
    80007bf8:	0e013403          	ld	s0,224(sp)
    80007bfc:	0d813483          	ld	s1,216(sp)
    80007c00:	0d013903          	ld	s2,208(sp)
    80007c04:	0c813983          	ld	s3,200(sp)
    80007c08:	0f010113          	addi	sp,sp,240
    80007c0c:	00008067          	ret

0000000080007c10 <sys_open>:

uint64
sys_open(void)
{
    80007c10:	f4010113          	addi	sp,sp,-192
    80007c14:	0a113c23          	sd	ra,184(sp)
    80007c18:	0a813823          	sd	s0,176(sp)
    80007c1c:	0a913423          	sd	s1,168(sp)
    80007c20:	0b213023          	sd	s2,160(sp)
    80007c24:	09313c23          	sd	s3,152(sp)
    80007c28:	0c010413          	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80007c2c:	f4c40593          	addi	a1,s0,-180
    80007c30:	00100513          	li	a0,1
    80007c34:	ffffc097          	auipc	ra,0xffffc
    80007c38:	300080e7          	jalr	768(ra) # 80003f34 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80007c3c:	08000613          	li	a2,128
    80007c40:	f5040593          	addi	a1,s0,-176
    80007c44:	00000513          	li	a0,0
    80007c48:	ffffc097          	auipc	ra,0xffffc
    80007c4c:	35c080e7          	jalr	860(ra) # 80003fa4 <argstr>
    80007c50:	00050793          	mv	a5,a0
    return -1;
    80007c54:	fff00513          	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80007c58:	0c07ca63          	bltz	a5,80007d2c <sys_open+0x11c>

  begin_op();
    80007c5c:	ffffe097          	auipc	ra,0xffffe
    80007c60:	23c080e7          	jalr	572(ra) # 80005e98 <begin_op>

  if(omode & O_CREATE){
    80007c64:	f4c42783          	lw	a5,-180(s0)
    80007c68:	2007f793          	andi	a5,a5,512
    80007c6c:	0e078663          	beqz	a5,80007d58 <sys_open+0x148>
    ip = create(path, T_FILE, 0, 0);
    80007c70:	00000693          	li	a3,0
    80007c74:	00000613          	li	a2,0
    80007c78:	00200593          	li	a1,2
    80007c7c:	f5040513          	addi	a0,s0,-176
    80007c80:	fffff097          	auipc	ra,0xfffff
    80007c84:	77c080e7          	jalr	1916(ra) # 800073fc <create>
    80007c88:	00050493          	mv	s1,a0
    if(ip == 0){
    80007c8c:	0a050e63          	beqz	a0,80007d48 <sys_open+0x138>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80007c90:	04449703          	lh	a4,68(s1)
    80007c94:	00300793          	li	a5,3
    80007c98:	00f71863          	bne	a4,a5,80007ca8 <sys_open+0x98>
    80007c9c:	0464d703          	lhu	a4,70(s1)
    80007ca0:	00900793          	li	a5,9
    80007ca4:	10e7e863          	bltu	a5,a4,80007db4 <sys_open+0x1a4>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80007ca8:	ffffe097          	auipc	ra,0xffffe
    80007cac:	770080e7          	jalr	1904(ra) # 80006418 <filealloc>
    80007cb0:	00050993          	mv	s3,a0
    80007cb4:	14050463          	beqz	a0,80007dfc <sys_open+0x1ec>
    80007cb8:	fffff097          	auipc	ra,0xfffff
    80007cbc:	6d4080e7          	jalr	1748(ra) # 8000738c <fdalloc>
    80007cc0:	00050913          	mv	s2,a0
    80007cc4:	12054663          	bltz	a0,80007df0 <sys_open+0x1e0>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80007cc8:	04449703          	lh	a4,68(s1)
    80007ccc:	00300793          	li	a5,3
    80007cd0:	10f70063          	beq	a4,a5,80007dd0 <sys_open+0x1c0>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80007cd4:	00200793          	li	a5,2
    80007cd8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80007cdc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80007ce0:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80007ce4:	f4c42783          	lw	a5,-180(s0)
    80007ce8:	0017c713          	xori	a4,a5,1
    80007cec:	00177713          	andi	a4,a4,1
    80007cf0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80007cf4:	0037f713          	andi	a4,a5,3
    80007cf8:	00e03733          	snez	a4,a4
    80007cfc:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80007d00:	4007f793          	andi	a5,a5,1024
    80007d04:	00078863          	beqz	a5,80007d14 <sys_open+0x104>
    80007d08:	04449703          	lh	a4,68(s1)
    80007d0c:	00200793          	li	a5,2
    80007d10:	0cf70863          	beq	a4,a5,80007de0 <sys_open+0x1d0>
    itrunc(ip);
  }

  iunlock(ip);
    80007d14:	00048513          	mv	a0,s1
    80007d18:	ffffd097          	auipc	ra,0xffffd
    80007d1c:	284080e7          	jalr	644(ra) # 80004f9c <iunlock>
  end_op();
    80007d20:	ffffe097          	auipc	ra,0xffffe
    80007d24:	22c080e7          	jalr	556(ra) # 80005f4c <end_op>

  return fd;
    80007d28:	00090513          	mv	a0,s2
}
    80007d2c:	0b813083          	ld	ra,184(sp)
    80007d30:	0b013403          	ld	s0,176(sp)
    80007d34:	0a813483          	ld	s1,168(sp)
    80007d38:	0a013903          	ld	s2,160(sp)
    80007d3c:	09813983          	ld	s3,152(sp)
    80007d40:	0c010113          	addi	sp,sp,192
    80007d44:	00008067          	ret
      end_op();
    80007d48:	ffffe097          	auipc	ra,0xffffe
    80007d4c:	204080e7          	jalr	516(ra) # 80005f4c <end_op>
      return -1;
    80007d50:	fff00513          	li	a0,-1
    80007d54:	fd9ff06f          	j	80007d2c <sys_open+0x11c>
    if((ip = namei(path)) == 0){
    80007d58:	f5040513          	addi	a0,s0,-176
    80007d5c:	ffffe097          	auipc	ra,0xffffe
    80007d60:	e28080e7          	jalr	-472(ra) # 80005b84 <namei>
    80007d64:	00050493          	mv	s1,a0
    80007d68:	02050e63          	beqz	a0,80007da4 <sys_open+0x194>
    ilock(ip);
    80007d6c:	ffffd097          	auipc	ra,0xffffd
    80007d70:	12c080e7          	jalr	300(ra) # 80004e98 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80007d74:	04449703          	lh	a4,68(s1)
    80007d78:	00100793          	li	a5,1
    80007d7c:	f0f71ae3          	bne	a4,a5,80007c90 <sys_open+0x80>
    80007d80:	f4c42783          	lw	a5,-180(s0)
    80007d84:	f20782e3          	beqz	a5,80007ca8 <sys_open+0x98>
      iunlockput(ip);
    80007d88:	00048513          	mv	a0,s1
    80007d8c:	ffffd097          	auipc	ra,0xffffd
    80007d90:	448080e7          	jalr	1096(ra) # 800051d4 <iunlockput>
      end_op();
    80007d94:	ffffe097          	auipc	ra,0xffffe
    80007d98:	1b8080e7          	jalr	440(ra) # 80005f4c <end_op>
      return -1;
    80007d9c:	fff00513          	li	a0,-1
    80007da0:	f8dff06f          	j	80007d2c <sys_open+0x11c>
      end_op();
    80007da4:	ffffe097          	auipc	ra,0xffffe
    80007da8:	1a8080e7          	jalr	424(ra) # 80005f4c <end_op>
      return -1;
    80007dac:	fff00513          	li	a0,-1
    80007db0:	f7dff06f          	j	80007d2c <sys_open+0x11c>
    iunlockput(ip);
    80007db4:	00048513          	mv	a0,s1
    80007db8:	ffffd097          	auipc	ra,0xffffd
    80007dbc:	41c080e7          	jalr	1052(ra) # 800051d4 <iunlockput>
    end_op();
    80007dc0:	ffffe097          	auipc	ra,0xffffe
    80007dc4:	18c080e7          	jalr	396(ra) # 80005f4c <end_op>
    return -1;
    80007dc8:	fff00513          	li	a0,-1
    80007dcc:	f61ff06f          	j	80007d2c <sys_open+0x11c>
    f->type = FD_DEVICE;
    80007dd0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80007dd4:	04649783          	lh	a5,70(s1)
    80007dd8:	02f99223          	sh	a5,36(s3)
    80007ddc:	f05ff06f          	j	80007ce0 <sys_open+0xd0>
    itrunc(ip);
    80007de0:	00048513          	mv	a0,s1
    80007de4:	ffffd097          	auipc	ra,0xffffd
    80007de8:	228080e7          	jalr	552(ra) # 8000500c <itrunc>
    80007dec:	f29ff06f          	j	80007d14 <sys_open+0x104>
      fileclose(f);
    80007df0:	00098513          	mv	a0,s3
    80007df4:	ffffe097          	auipc	ra,0xffffe
    80007df8:	720080e7          	jalr	1824(ra) # 80006514 <fileclose>
    iunlockput(ip);
    80007dfc:	00048513          	mv	a0,s1
    80007e00:	ffffd097          	auipc	ra,0xffffd
    80007e04:	3d4080e7          	jalr	980(ra) # 800051d4 <iunlockput>
    end_op();
    80007e08:	ffffe097          	auipc	ra,0xffffe
    80007e0c:	144080e7          	jalr	324(ra) # 80005f4c <end_op>
    return -1;
    80007e10:	fff00513          	li	a0,-1
    80007e14:	f19ff06f          	j	80007d2c <sys_open+0x11c>

0000000080007e18 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80007e18:	f7010113          	addi	sp,sp,-144
    80007e1c:	08113423          	sd	ra,136(sp)
    80007e20:	08813023          	sd	s0,128(sp)
    80007e24:	09010413          	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80007e28:	ffffe097          	auipc	ra,0xffffe
    80007e2c:	070080e7          	jalr	112(ra) # 80005e98 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80007e30:	08000613          	li	a2,128
    80007e34:	f7040593          	addi	a1,s0,-144
    80007e38:	00000513          	li	a0,0
    80007e3c:	ffffc097          	auipc	ra,0xffffc
    80007e40:	168080e7          	jalr	360(ra) # 80003fa4 <argstr>
    80007e44:	04054263          	bltz	a0,80007e88 <sys_mkdir+0x70>
    80007e48:	00000693          	li	a3,0
    80007e4c:	00000613          	li	a2,0
    80007e50:	00100593          	li	a1,1
    80007e54:	f7040513          	addi	a0,s0,-144
    80007e58:	fffff097          	auipc	ra,0xfffff
    80007e5c:	5a4080e7          	jalr	1444(ra) # 800073fc <create>
    80007e60:	02050463          	beqz	a0,80007e88 <sys_mkdir+0x70>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80007e64:	ffffd097          	auipc	ra,0xffffd
    80007e68:	370080e7          	jalr	880(ra) # 800051d4 <iunlockput>
  end_op();
    80007e6c:	ffffe097          	auipc	ra,0xffffe
    80007e70:	0e0080e7          	jalr	224(ra) # 80005f4c <end_op>
  return 0;
    80007e74:	00000513          	li	a0,0
}
    80007e78:	08813083          	ld	ra,136(sp)
    80007e7c:	08013403          	ld	s0,128(sp)
    80007e80:	09010113          	addi	sp,sp,144
    80007e84:	00008067          	ret
    end_op();
    80007e88:	ffffe097          	auipc	ra,0xffffe
    80007e8c:	0c4080e7          	jalr	196(ra) # 80005f4c <end_op>
    return -1;
    80007e90:	fff00513          	li	a0,-1
    80007e94:	fe5ff06f          	j	80007e78 <sys_mkdir+0x60>

0000000080007e98 <sys_mknod>:

uint64
sys_mknod(void)
{
    80007e98:	f6010113          	addi	sp,sp,-160
    80007e9c:	08113c23          	sd	ra,152(sp)
    80007ea0:	08813823          	sd	s0,144(sp)
    80007ea4:	0a010413          	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80007ea8:	ffffe097          	auipc	ra,0xffffe
    80007eac:	ff0080e7          	jalr	-16(ra) # 80005e98 <begin_op>
  argint(1, &major);
    80007eb0:	f6c40593          	addi	a1,s0,-148
    80007eb4:	00100513          	li	a0,1
    80007eb8:	ffffc097          	auipc	ra,0xffffc
    80007ebc:	07c080e7          	jalr	124(ra) # 80003f34 <argint>
  argint(2, &minor);
    80007ec0:	f6840593          	addi	a1,s0,-152
    80007ec4:	00200513          	li	a0,2
    80007ec8:	ffffc097          	auipc	ra,0xffffc
    80007ecc:	06c080e7          	jalr	108(ra) # 80003f34 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80007ed0:	08000613          	li	a2,128
    80007ed4:	f7040593          	addi	a1,s0,-144
    80007ed8:	00000513          	li	a0,0
    80007edc:	ffffc097          	auipc	ra,0xffffc
    80007ee0:	0c8080e7          	jalr	200(ra) # 80003fa4 <argstr>
    80007ee4:	04054263          	bltz	a0,80007f28 <sys_mknod+0x90>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80007ee8:	f6841683          	lh	a3,-152(s0)
    80007eec:	f6c41603          	lh	a2,-148(s0)
    80007ef0:	00300593          	li	a1,3
    80007ef4:	f7040513          	addi	a0,s0,-144
    80007ef8:	fffff097          	auipc	ra,0xfffff
    80007efc:	504080e7          	jalr	1284(ra) # 800073fc <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80007f00:	02050463          	beqz	a0,80007f28 <sys_mknod+0x90>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80007f04:	ffffd097          	auipc	ra,0xffffd
    80007f08:	2d0080e7          	jalr	720(ra) # 800051d4 <iunlockput>
  end_op();
    80007f0c:	ffffe097          	auipc	ra,0xffffe
    80007f10:	040080e7          	jalr	64(ra) # 80005f4c <end_op>
  return 0;
    80007f14:	00000513          	li	a0,0
}
    80007f18:	09813083          	ld	ra,152(sp)
    80007f1c:	09013403          	ld	s0,144(sp)
    80007f20:	0a010113          	addi	sp,sp,160
    80007f24:	00008067          	ret
    end_op();
    80007f28:	ffffe097          	auipc	ra,0xffffe
    80007f2c:	024080e7          	jalr	36(ra) # 80005f4c <end_op>
    return -1;
    80007f30:	fff00513          	li	a0,-1
    80007f34:	fe5ff06f          	j	80007f18 <sys_mknod+0x80>

0000000080007f38 <sys_chdir>:

uint64
sys_chdir(void)
{
    80007f38:	f6010113          	addi	sp,sp,-160
    80007f3c:	08113c23          	sd	ra,152(sp)
    80007f40:	08813823          	sd	s0,144(sp)
    80007f44:	08913423          	sd	s1,136(sp)
    80007f48:	09213023          	sd	s2,128(sp)
    80007f4c:	0a010413          	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80007f50:	ffffa097          	auipc	ra,0xffffa
    80007f54:	798080e7          	jalr	1944(ra) # 800026e8 <myproc>
    80007f58:	00050913          	mv	s2,a0
  
  begin_op();
    80007f5c:	ffffe097          	auipc	ra,0xffffe
    80007f60:	f3c080e7          	jalr	-196(ra) # 80005e98 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80007f64:	08000613          	li	a2,128
    80007f68:	f6040593          	addi	a1,s0,-160
    80007f6c:	00000513          	li	a0,0
    80007f70:	ffffc097          	auipc	ra,0xffffc
    80007f74:	034080e7          	jalr	52(ra) # 80003fa4 <argstr>
    80007f78:	06054663          	bltz	a0,80007fe4 <sys_chdir+0xac>
    80007f7c:	f6040513          	addi	a0,s0,-160
    80007f80:	ffffe097          	auipc	ra,0xffffe
    80007f84:	c04080e7          	jalr	-1020(ra) # 80005b84 <namei>
    80007f88:	00050493          	mv	s1,a0
    80007f8c:	04050c63          	beqz	a0,80007fe4 <sys_chdir+0xac>
    end_op();
    return -1;
  }
  ilock(ip);
    80007f90:	ffffd097          	auipc	ra,0xffffd
    80007f94:	f08080e7          	jalr	-248(ra) # 80004e98 <ilock>
  if(ip->type != T_DIR){
    80007f98:	04449703          	lh	a4,68(s1)
    80007f9c:	00100793          	li	a5,1
    80007fa0:	04f71a63          	bne	a4,a5,80007ff4 <sys_chdir+0xbc>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80007fa4:	00048513          	mv	a0,s1
    80007fa8:	ffffd097          	auipc	ra,0xffffd
    80007fac:	ff4080e7          	jalr	-12(ra) # 80004f9c <iunlock>
  iput(p->cwd);
    80007fb0:	15093503          	ld	a0,336(s2)
    80007fb4:	ffffd097          	auipc	ra,0xffffd
    80007fb8:	144080e7          	jalr	324(ra) # 800050f8 <iput>
  end_op();
    80007fbc:	ffffe097          	auipc	ra,0xffffe
    80007fc0:	f90080e7          	jalr	-112(ra) # 80005f4c <end_op>
  p->cwd = ip;
    80007fc4:	14993823          	sd	s1,336(s2)
  return 0;
    80007fc8:	00000513          	li	a0,0
}
    80007fcc:	09813083          	ld	ra,152(sp)
    80007fd0:	09013403          	ld	s0,144(sp)
    80007fd4:	08813483          	ld	s1,136(sp)
    80007fd8:	08013903          	ld	s2,128(sp)
    80007fdc:	0a010113          	addi	sp,sp,160
    80007fe0:	00008067          	ret
    end_op();
    80007fe4:	ffffe097          	auipc	ra,0xffffe
    80007fe8:	f68080e7          	jalr	-152(ra) # 80005f4c <end_op>
    return -1;
    80007fec:	fff00513          	li	a0,-1
    80007ff0:	fddff06f          	j	80007fcc <sys_chdir+0x94>
    iunlockput(ip);
    80007ff4:	00048513          	mv	a0,s1
    80007ff8:	ffffd097          	auipc	ra,0xffffd
    80007ffc:	1dc080e7          	jalr	476(ra) # 800051d4 <iunlockput>
    end_op();
    80008000:	ffffe097          	auipc	ra,0xffffe
    80008004:	f4c080e7          	jalr	-180(ra) # 80005f4c <end_op>
    return -1;
    80008008:	fff00513          	li	a0,-1
    8000800c:	fc1ff06f          	j	80007fcc <sys_chdir+0x94>

0000000080008010 <sys_exec>:

uint64
sys_exec(void)
{
    80008010:	e3010113          	addi	sp,sp,-464
    80008014:	1c113423          	sd	ra,456(sp)
    80008018:	1c813023          	sd	s0,448(sp)
    8000801c:	1a913c23          	sd	s1,440(sp)
    80008020:	1b213823          	sd	s2,432(sp)
    80008024:	1b313423          	sd	s3,424(sp)
    80008028:	1b413023          	sd	s4,416(sp)
    8000802c:	19513c23          	sd	s5,408(sp)
    80008030:	1d010413          	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80008034:	e3840593          	addi	a1,s0,-456
    80008038:	00100513          	li	a0,1
    8000803c:	ffffc097          	auipc	ra,0xffffc
    80008040:	f30080e7          	jalr	-208(ra) # 80003f6c <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80008044:	08000613          	li	a2,128
    80008048:	f4040593          	addi	a1,s0,-192
    8000804c:	00000513          	li	a0,0
    80008050:	ffffc097          	auipc	ra,0xffffc
    80008054:	f54080e7          	jalr	-172(ra) # 80003fa4 <argstr>
    80008058:	00050793          	mv	a5,a0
    return -1;
    8000805c:	fff00513          	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80008060:	0e07ca63          	bltz	a5,80008154 <sys_exec+0x144>
  }
  memset(argv, 0, sizeof(argv));
    80008064:	10000613          	li	a2,256
    80008068:	00000593          	li	a1,0
    8000806c:	e4040513          	addi	a0,s0,-448
    80008070:	ffff9097          	auipc	ra,0xffff9
    80008074:	1a0080e7          	jalr	416(ra) # 80001210 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80008078:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000807c:	00048993          	mv	s3,s1
    80008080:	00000913          	li	s2,0
    if(i >= NELEM(argv)){
    80008084:	02000a13          	li	s4,32
    80008088:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000808c:	00391513          	slli	a0,s2,0x3
    80008090:	e3040593          	addi	a1,s0,-464
    80008094:	e3843783          	ld	a5,-456(s0)
    80008098:	00f50533          	add	a0,a0,a5
    8000809c:	ffffc097          	auipc	ra,0xffffc
    800080a0:	d9c080e7          	jalr	-612(ra) # 80003e38 <fetchaddr>
    800080a4:	04054063          	bltz	a0,800080e4 <sys_exec+0xd4>
      goto bad;
    }
    if(uarg == 0){
    800080a8:	e3043783          	ld	a5,-464(s0)
    800080ac:	04078e63          	beqz	a5,80008108 <sys_exec+0xf8>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800080b0:	ffff9097          	auipc	ra,0xffff9
    800080b4:	e9c080e7          	jalr	-356(ra) # 80000f4c <kalloc>
    800080b8:	00050593          	mv	a1,a0
    800080bc:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800080c0:	02050263          	beqz	a0,800080e4 <sys_exec+0xd4>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800080c4:	00001637          	lui	a2,0x1
    800080c8:	e3043503          	ld	a0,-464(s0)
    800080cc:	ffffc097          	auipc	ra,0xffffc
    800080d0:	dec080e7          	jalr	-532(ra) # 80003eb8 <fetchstr>
    800080d4:	00054863          	bltz	a0,800080e4 <sys_exec+0xd4>
    if(i >= NELEM(argv)){
    800080d8:	00190913          	addi	s2,s2,1
    800080dc:	00898993          	addi	s3,s3,8
    800080e0:	fb4914e3          	bne	s2,s4,80008088 <sys_exec+0x78>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800080e4:	f4040913          	addi	s2,s0,-192
    800080e8:	0004b503          	ld	a0,0(s1)
    800080ec:	06050263          	beqz	a0,80008150 <sys_exec+0x140>
    kfree(argv[i]);
    800080f0:	ffff9097          	auipc	ra,0xffff9
    800080f4:	cd0080e7          	jalr	-816(ra) # 80000dc0 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800080f8:	00848493          	addi	s1,s1,8
    800080fc:	ff2496e3          	bne	s1,s2,800080e8 <sys_exec+0xd8>
  return -1;
    80008100:	fff00513          	li	a0,-1
    80008104:	0500006f          	j	80008154 <sys_exec+0x144>
      argv[i] = 0;
    80008108:	003a9a93          	slli	s5,s5,0x3
    8000810c:	fc0a8793          	addi	a5,s5,-64
    80008110:	00878ab3          	add	s5,a5,s0
    80008114:	e80ab023          	sd	zero,-384(s5)
  int ret = kexec(path, argv);
    80008118:	e4040593          	addi	a1,s0,-448
    8000811c:	f4040513          	addi	a0,s0,-192
    80008120:	fffff097          	auipc	ra,0xfffff
    80008124:	d10080e7          	jalr	-752(ra) # 80006e30 <kexec>
    80008128:	00050913          	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000812c:	f4040993          	addi	s3,s0,-192
    80008130:	0004b503          	ld	a0,0(s1)
    80008134:	00050a63          	beqz	a0,80008148 <sys_exec+0x138>
    kfree(argv[i]);
    80008138:	ffff9097          	auipc	ra,0xffff9
    8000813c:	c88080e7          	jalr	-888(ra) # 80000dc0 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80008140:	00848493          	addi	s1,s1,8
    80008144:	ff3496e3          	bne	s1,s3,80008130 <sys_exec+0x120>
  return ret;
    80008148:	00090513          	mv	a0,s2
    8000814c:	0080006f          	j	80008154 <sys_exec+0x144>
  return -1;
    80008150:	fff00513          	li	a0,-1
}
    80008154:	1c813083          	ld	ra,456(sp)
    80008158:	1c013403          	ld	s0,448(sp)
    8000815c:	1b813483          	ld	s1,440(sp)
    80008160:	1b013903          	ld	s2,432(sp)
    80008164:	1a813983          	ld	s3,424(sp)
    80008168:	1a013a03          	ld	s4,416(sp)
    8000816c:	19813a83          	ld	s5,408(sp)
    80008170:	1d010113          	addi	sp,sp,464
    80008174:	00008067          	ret

0000000080008178 <sys_pipe>:

uint64
sys_pipe(void)
{
    80008178:	fc010113          	addi	sp,sp,-64
    8000817c:	02113c23          	sd	ra,56(sp)
    80008180:	02813823          	sd	s0,48(sp)
    80008184:	02913423          	sd	s1,40(sp)
    80008188:	04010413          	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000818c:	ffffa097          	auipc	ra,0xffffa
    80008190:	55c080e7          	jalr	1372(ra) # 800026e8 <myproc>
    80008194:	00050493          	mv	s1,a0

  argaddr(0, &fdarray);
    80008198:	fd840593          	addi	a1,s0,-40
    8000819c:	00000513          	li	a0,0
    800081a0:	ffffc097          	auipc	ra,0xffffc
    800081a4:	dcc080e7          	jalr	-564(ra) # 80003f6c <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800081a8:	fc840593          	addi	a1,s0,-56
    800081ac:	fd040513          	addi	a0,s0,-48
    800081b0:	ffffe097          	auipc	ra,0xffffe
    800081b4:	7f0080e7          	jalr	2032(ra) # 800069a0 <pipealloc>
    return -1;
    800081b8:	fff00793          	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800081bc:	0e054663          	bltz	a0,800082a8 <sys_pipe+0x130>
  fd0 = -1;
    800081c0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800081c4:	fd043503          	ld	a0,-48(s0)
    800081c8:	fffff097          	auipc	ra,0xfffff
    800081cc:	1c4080e7          	jalr	452(ra) # 8000738c <fdalloc>
    800081d0:	fca42223          	sw	a0,-60(s0)
    800081d4:	0a054c63          	bltz	a0,8000828c <sys_pipe+0x114>
    800081d8:	fc843503          	ld	a0,-56(s0)
    800081dc:	fffff097          	auipc	ra,0xfffff
    800081e0:	1b0080e7          	jalr	432(ra) # 8000738c <fdalloc>
    800081e4:	fca42023          	sw	a0,-64(s0)
    800081e8:	08054663          	bltz	a0,80008274 <sys_pipe+0xfc>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800081ec:	00400693          	li	a3,4
    800081f0:	fc440613          	addi	a2,s0,-60
    800081f4:	fd843583          	ld	a1,-40(s0)
    800081f8:	0504b503          	ld	a0,80(s1)
    800081fc:	ffffa097          	auipc	ra,0xffffa
    80008200:	078080e7          	jalr	120(ra) # 80002274 <copyout>
    80008204:	02054463          	bltz	a0,8000822c <sys_pipe+0xb4>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80008208:	00400693          	li	a3,4
    8000820c:	fc040613          	addi	a2,s0,-64
    80008210:	fd843583          	ld	a1,-40(s0)
    80008214:	00458593          	addi	a1,a1,4
    80008218:	0504b503          	ld	a0,80(s1)
    8000821c:	ffffa097          	auipc	ra,0xffffa
    80008220:	058080e7          	jalr	88(ra) # 80002274 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80008224:	00000793          	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80008228:	08055063          	bgez	a0,800082a8 <sys_pipe+0x130>
    p->ofile[fd0] = 0;
    8000822c:	fc442783          	lw	a5,-60(s0)
    80008230:	01a78793          	addi	a5,a5,26
    80008234:	00379793          	slli	a5,a5,0x3
    80008238:	00f487b3          	add	a5,s1,a5
    8000823c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80008240:	fc042783          	lw	a5,-64(s0)
    80008244:	01a78793          	addi	a5,a5,26
    80008248:	00379793          	slli	a5,a5,0x3
    8000824c:	00f484b3          	add	s1,s1,a5
    80008250:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80008254:	fd043503          	ld	a0,-48(s0)
    80008258:	ffffe097          	auipc	ra,0xffffe
    8000825c:	2bc080e7          	jalr	700(ra) # 80006514 <fileclose>
    fileclose(wf);
    80008260:	fc843503          	ld	a0,-56(s0)
    80008264:	ffffe097          	auipc	ra,0xffffe
    80008268:	2b0080e7          	jalr	688(ra) # 80006514 <fileclose>
    return -1;
    8000826c:	fff00793          	li	a5,-1
    80008270:	0380006f          	j	800082a8 <sys_pipe+0x130>
    if(fd0 >= 0)
    80008274:	fc442783          	lw	a5,-60(s0)
    80008278:	0007ca63          	bltz	a5,8000828c <sys_pipe+0x114>
      p->ofile[fd0] = 0;
    8000827c:	01a78793          	addi	a5,a5,26
    80008280:	00379793          	slli	a5,a5,0x3
    80008284:	00f487b3          	add	a5,s1,a5
    80008288:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    8000828c:	fd043503          	ld	a0,-48(s0)
    80008290:	ffffe097          	auipc	ra,0xffffe
    80008294:	284080e7          	jalr	644(ra) # 80006514 <fileclose>
    fileclose(wf);
    80008298:	fc843503          	ld	a0,-56(s0)
    8000829c:	ffffe097          	auipc	ra,0xffffe
    800082a0:	278080e7          	jalr	632(ra) # 80006514 <fileclose>
    return -1;
    800082a4:	fff00793          	li	a5,-1
}
    800082a8:	00078513          	mv	a0,a5
    800082ac:	03813083          	ld	ra,56(sp)
    800082b0:	03013403          	ld	s0,48(sp)
    800082b4:	02813483          	ld	s1,40(sp)
    800082b8:	04010113          	addi	sp,sp,64
    800082bc:	00008067          	ret

00000000800082c0 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    800082c0:	f0010113          	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    800082c4:	00113023          	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    800082c8:	00313823          	sd	gp,16(sp)
        sd tp, 24(sp)
    800082cc:	00413c23          	sd	tp,24(sp)
        sd t0, 32(sp)
    800082d0:	02513023          	sd	t0,32(sp)
        sd t1, 40(sp)
    800082d4:	02613423          	sd	t1,40(sp)
        sd t2, 48(sp)
    800082d8:	02713823          	sd	t2,48(sp)
        sd a0, 72(sp)
    800082dc:	04a13423          	sd	a0,72(sp)
        sd a1, 80(sp)
    800082e0:	04b13823          	sd	a1,80(sp)
        sd a2, 88(sp)
    800082e4:	04c13c23          	sd	a2,88(sp)
        sd a3, 96(sp)
    800082e8:	06d13023          	sd	a3,96(sp)
        sd a4, 104(sp)
    800082ec:	06e13423          	sd	a4,104(sp)
        sd a5, 112(sp)
    800082f0:	06f13823          	sd	a5,112(sp)
        sd a6, 120(sp)
    800082f4:	07013c23          	sd	a6,120(sp)
        sd a7, 128(sp)
    800082f8:	09113023          	sd	a7,128(sp)
        sd t3, 216(sp)
    800082fc:	0dc13c23          	sd	t3,216(sp)
        sd t4, 224(sp)
    80008300:	0fd13023          	sd	t4,224(sp)
        sd t5, 232(sp)
    80008304:	0fe13423          	sd	t5,232(sp)
        sd t6, 240(sp)
    80008308:	0ff13823          	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    8000830c:	9a9fb0ef          	jal	ra,80003cb4 <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    80008310:	00013083          	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    80008314:	01013183          	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    80008318:	02013283          	ld	t0,32(sp)
        ld t1, 40(sp)
    8000831c:	02813303          	ld	t1,40(sp)
        ld t2, 48(sp)
    80008320:	03013383          	ld	t2,48(sp)
        ld a0, 72(sp)
    80008324:	04813503          	ld	a0,72(sp)
        ld a1, 80(sp)
    80008328:	05013583          	ld	a1,80(sp)
        ld a2, 88(sp)
    8000832c:	05813603          	ld	a2,88(sp)
        ld a3, 96(sp)
    80008330:	06013683          	ld	a3,96(sp)
        ld a4, 104(sp)
    80008334:	06813703          	ld	a4,104(sp)
        ld a5, 112(sp)
    80008338:	07013783          	ld	a5,112(sp)
        ld a6, 120(sp)
    8000833c:	07813803          	ld	a6,120(sp)
        ld a7, 128(sp)
    80008340:	08013883          	ld	a7,128(sp)
        ld t3, 216(sp)
    80008344:	0d813e03          	ld	t3,216(sp)
        ld t4, 224(sp)
    80008348:	0e013e83          	ld	t4,224(sp)
        ld t5, 232(sp)
    8000834c:	0e813f03          	ld	t5,232(sp)
        ld t6, 240(sp)
    80008350:	0f013f83          	ld	t6,240(sp)

        addi sp, sp, 256
    80008354:	10010113          	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    80008358:	10200073          	sret
    8000835c:	0000                	.2byte	0x0
	...

0000000080008360 <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80008360:	ff010113          	addi	sp,sp,-16
    80008364:	00813423          	sd	s0,8(sp)
    80008368:	01010413          	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    8000836c:	0c0007b7          	lui	a5,0xc000
    80008370:	00100713          	li	a4,1
    80008374:	02e7a423          	sw	a4,40(a5) # c000028 <_entry-0x73ffffd8>
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80008378:	00e7a223          	sw	a4,4(a5)
}
    8000837c:	00813403          	ld	s0,8(sp)
    80008380:	01010113          	addi	sp,sp,16
    80008384:	00008067          	ret

0000000080008388 <plicinithart>:

void
plicinithart(void)
{
    80008388:	ff010113          	addi	sp,sp,-16
    8000838c:	00113423          	sd	ra,8(sp)
    80008390:	00813023          	sd	s0,0(sp)
    80008394:	01010413          	addi	s0,sp,16
  int hart = cpuid();
    80008398:	ffffa097          	auipc	ra,0xffffa
    8000839c:	300080e7          	jalr	768(ra) # 80002698 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800083a0:	0085171b          	slliw	a4,a0,0x8
    800083a4:	0c0027b7          	lui	a5,0xc002
    800083a8:	00e787b3          	add	a5,a5,a4
    800083ac:	40200713          	li	a4,1026
    800083b0:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800083b4:	00d5151b          	slliw	a0,a0,0xd
    800083b8:	0c2017b7          	lui	a5,0xc201
    800083bc:	00a787b3          	add	a5,a5,a0
    800083c0:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800083c4:	00813083          	ld	ra,8(sp)
    800083c8:	00013403          	ld	s0,0(sp)
    800083cc:	01010113          	addi	sp,sp,16
    800083d0:	00008067          	ret

00000000800083d4 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800083d4:	ff010113          	addi	sp,sp,-16
    800083d8:	00113423          	sd	ra,8(sp)
    800083dc:	00813023          	sd	s0,0(sp)
    800083e0:	01010413          	addi	s0,sp,16
  int hart = cpuid();
    800083e4:	ffffa097          	auipc	ra,0xffffa
    800083e8:	2b4080e7          	jalr	692(ra) # 80002698 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800083ec:	00d5151b          	slliw	a0,a0,0xd
    800083f0:	0c2017b7          	lui	a5,0xc201
    800083f4:	00a787b3          	add	a5,a5,a0
  return irq;
}
    800083f8:	0047a503          	lw	a0,4(a5) # c201004 <_entry-0x73dfeffc>
    800083fc:	00813083          	ld	ra,8(sp)
    80008400:	00013403          	ld	s0,0(sp)
    80008404:	01010113          	addi	sp,sp,16
    80008408:	00008067          	ret

000000008000840c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000840c:	fe010113          	addi	sp,sp,-32
    80008410:	00113c23          	sd	ra,24(sp)
    80008414:	00813823          	sd	s0,16(sp)
    80008418:	00913423          	sd	s1,8(sp)
    8000841c:	02010413          	addi	s0,sp,32
    80008420:	00050493          	mv	s1,a0
  int hart = cpuid();
    80008424:	ffffa097          	auipc	ra,0xffffa
    80008428:	274080e7          	jalr	628(ra) # 80002698 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    8000842c:	00d5151b          	slliw	a0,a0,0xd
    80008430:	0c2017b7          	lui	a5,0xc201
    80008434:	00a787b3          	add	a5,a5,a0
    80008438:	0097a223          	sw	s1,4(a5) # c201004 <_entry-0x73dfeffc>
}
    8000843c:	01813083          	ld	ra,24(sp)
    80008440:	01013403          	ld	s0,16(sp)
    80008444:	00813483          	ld	s1,8(sp)
    80008448:	02010113          	addi	sp,sp,32
    8000844c:	00008067          	ret

0000000080008450 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80008450:	ff010113          	addi	sp,sp,-16
    80008454:	00113423          	sd	ra,8(sp)
    80008458:	00813023          	sd	s0,0(sp)
    8000845c:	01010413          	addi	s0,sp,16
  if(i >= NUM)
    80008460:	00700793          	li	a5,7
    80008464:	06a7c863          	blt	a5,a0,800084d4 <free_desc+0x84>
    panic("free_desc 1");
  if(disk.free[i])
    80008468:	0001b797          	auipc	a5,0x1b
    8000846c:	73078793          	addi	a5,a5,1840 # 80023b98 <disk>
    80008470:	00a787b3          	add	a5,a5,a0
    80008474:	0187c783          	lbu	a5,24(a5)
    80008478:	06079663          	bnez	a5,800084e4 <free_desc+0x94>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000847c:	00451693          	slli	a3,a0,0x4
    80008480:	0001b797          	auipc	a5,0x1b
    80008484:	71878793          	addi	a5,a5,1816 # 80023b98 <disk>
    80008488:	0007b703          	ld	a4,0(a5)
    8000848c:	00d70733          	add	a4,a4,a3
    80008490:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80008494:	0007b703          	ld	a4,0(a5)
    80008498:	00d70733          	add	a4,a4,a3
    8000849c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800084a0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800084a4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800084a8:	00a787b3          	add	a5,a5,a0
    800084ac:	00100713          	li	a4,1
    800084b0:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800084b4:	0001b517          	auipc	a0,0x1b
    800084b8:	6fc50513          	addi	a0,a0,1788 # 80023bb0 <disk+0x18>
    800084bc:	ffffb097          	auipc	ra,0xffffb
    800084c0:	c74080e7          	jalr	-908(ra) # 80003130 <wakeup>
}
    800084c4:	00813083          	ld	ra,8(sp)
    800084c8:	00013403          	ld	s0,0(sp)
    800084cc:	01010113          	addi	sp,sp,16
    800084d0:	00008067          	ret
    panic("free_desc 1");
    800084d4:	00002517          	auipc	a0,0x2
    800084d8:	3bc50513          	addi	a0,a0,956 # 8000a890 <syscalls+0x330>
    800084dc:	ffff8097          	auipc	ra,0xffff8
    800084e0:	5a4080e7          	jalr	1444(ra) # 80000a80 <panic>
    panic("free_desc 2");
    800084e4:	00002517          	auipc	a0,0x2
    800084e8:	3bc50513          	addi	a0,a0,956 # 8000a8a0 <syscalls+0x340>
    800084ec:	ffff8097          	auipc	ra,0xffff8
    800084f0:	594080e7          	jalr	1428(ra) # 80000a80 <panic>

00000000800084f4 <virtio_disk_init>:
{
    800084f4:	fe010113          	addi	sp,sp,-32
    800084f8:	00113c23          	sd	ra,24(sp)
    800084fc:	00813823          	sd	s0,16(sp)
    80008500:	00913423          	sd	s1,8(sp)
    80008504:	01213023          	sd	s2,0(sp)
    80008508:	02010413          	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000850c:	00002597          	auipc	a1,0x2
    80008510:	3a458593          	addi	a1,a1,932 # 8000a8b0 <syscalls+0x350>
    80008514:	0001b517          	auipc	a0,0x1b
    80008518:	7ac50513          	addi	a0,a0,1964 # 80023cc0 <disk+0x128>
    8000851c:	ffff9097          	auipc	ra,0xffff9
    80008520:	ab8080e7          	jalr	-1352(ra) # 80000fd4 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80008524:	100017b7          	lui	a5,0x10001
    80008528:	0007a703          	lw	a4,0(a5) # 10001000 <_entry-0x6ffff000>
    8000852c:	0007071b          	sext.w	a4,a4
    80008530:	747277b7          	lui	a5,0x74727
    80008534:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80008538:	1cf71263          	bne	a4,a5,800086fc <virtio_disk_init+0x208>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000853c:	100017b7          	lui	a5,0x10001
    80008540:	0047a783          	lw	a5,4(a5) # 10001004 <_entry-0x6fffeffc>
    80008544:	0007879b          	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80008548:	00200713          	li	a4,2
    8000854c:	1ae79863          	bne	a5,a4,800086fc <virtio_disk_init+0x208>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80008550:	100017b7          	lui	a5,0x10001
    80008554:	0087a783          	lw	a5,8(a5) # 10001008 <_entry-0x6fffeff8>
    80008558:	0007879b          	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000855c:	1ae79063          	bne	a5,a4,800086fc <virtio_disk_init+0x208>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80008560:	100017b7          	lui	a5,0x10001
    80008564:	00c7a703          	lw	a4,12(a5) # 1000100c <_entry-0x6fffeff4>
    80008568:	0007071b          	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000856c:	554d47b7          	lui	a5,0x554d4
    80008570:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80008574:	18f71463          	bne	a4,a5,800086fc <virtio_disk_init+0x208>
  *R(VIRTIO_MMIO_STATUS) = status;
    80008578:	100017b7          	lui	a5,0x10001
    8000857c:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80008580:	00100713          	li	a4,1
    80008584:	06e7a823          	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80008588:	00300713          	li	a4,3
    8000858c:	06e7a823          	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80008590:	0107a703          	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80008594:	c7ffe6b7          	lui	a3,0xc7ffe
    80008598:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdaa87>
    8000859c:	00d77733          	and	a4,a4,a3
    800085a0:	02e7a023          	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800085a4:	00b00713          	li	a4,11
    800085a8:	06e7a823          	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800085ac:	0707a783          	lw	a5,112(a5)
    800085b0:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800085b4:	0087f793          	andi	a5,a5,8
    800085b8:	14078a63          	beqz	a5,8000870c <virtio_disk_init+0x218>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800085bc:	100017b7          	lui	a5,0x10001
    800085c0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800085c4:	0447a783          	lw	a5,68(a5)
    800085c8:	0007879b          	sext.w	a5,a5
    800085cc:	14079863          	bnez	a5,8000871c <virtio_disk_init+0x228>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800085d0:	100017b7          	lui	a5,0x10001
    800085d4:	0347a783          	lw	a5,52(a5) # 10001034 <_entry-0x6fffefcc>
    800085d8:	0007879b          	sext.w	a5,a5
  if(max == 0)
    800085dc:	14078863          	beqz	a5,8000872c <virtio_disk_init+0x238>
  if(max < NUM)
    800085e0:	00700713          	li	a4,7
    800085e4:	14f77c63          	bgeu	a4,a5,8000873c <virtio_disk_init+0x248>
  disk.desc = kalloc();
    800085e8:	ffff9097          	auipc	ra,0xffff9
    800085ec:	964080e7          	jalr	-1692(ra) # 80000f4c <kalloc>
    800085f0:	0001b497          	auipc	s1,0x1b
    800085f4:	5a848493          	addi	s1,s1,1448 # 80023b98 <disk>
    800085f8:	00a4b023          	sd	a0,0(s1)
  disk.avail = kalloc();
    800085fc:	ffff9097          	auipc	ra,0xffff9
    80008600:	950080e7          	jalr	-1712(ra) # 80000f4c <kalloc>
    80008604:	00a4b423          	sd	a0,8(s1)
  disk.used = kalloc();
    80008608:	ffff9097          	auipc	ra,0xffff9
    8000860c:	944080e7          	jalr	-1724(ra) # 80000f4c <kalloc>
    80008610:	00050793          	mv	a5,a0
    80008614:	00a4b823          	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80008618:	0004b503          	ld	a0,0(s1)
    8000861c:	12050863          	beqz	a0,8000874c <virtio_disk_init+0x258>
    80008620:	0001b717          	auipc	a4,0x1b
    80008624:	58073703          	ld	a4,1408(a4) # 80023ba0 <disk+0x8>
    80008628:	12070263          	beqz	a4,8000874c <virtio_disk_init+0x258>
    8000862c:	12078063          	beqz	a5,8000874c <virtio_disk_init+0x258>
  memset(disk.desc, 0, PGSIZE);
    80008630:	00001637          	lui	a2,0x1
    80008634:	00000593          	li	a1,0
    80008638:	ffff9097          	auipc	ra,0xffff9
    8000863c:	bd8080e7          	jalr	-1064(ra) # 80001210 <memset>
  memset(disk.avail, 0, PGSIZE);
    80008640:	0001b497          	auipc	s1,0x1b
    80008644:	55848493          	addi	s1,s1,1368 # 80023b98 <disk>
    80008648:	00001637          	lui	a2,0x1
    8000864c:	00000593          	li	a1,0
    80008650:	0084b503          	ld	a0,8(s1)
    80008654:	ffff9097          	auipc	ra,0xffff9
    80008658:	bbc080e7          	jalr	-1092(ra) # 80001210 <memset>
  memset(disk.used, 0, PGSIZE);
    8000865c:	00001637          	lui	a2,0x1
    80008660:	00000593          	li	a1,0
    80008664:	0104b503          	ld	a0,16(s1)
    80008668:	ffff9097          	auipc	ra,0xffff9
    8000866c:	ba8080e7          	jalr	-1112(ra) # 80001210 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80008670:	100017b7          	lui	a5,0x10001
    80008674:	00800713          	li	a4,8
    80008678:	02e7ac23          	sw	a4,56(a5) # 10001038 <_entry-0x6fffefc8>
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000867c:	0004a703          	lw	a4,0(s1)
    80008680:	08e7a023          	sw	a4,128(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80008684:	0044a703          	lw	a4,4(s1)
    80008688:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000868c:	0084b703          	ld	a4,8(s1)
    80008690:	0007069b          	sext.w	a3,a4
    80008694:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80008698:	42075713          	srai	a4,a4,0x20
    8000869c:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800086a0:	0104b703          	ld	a4,16(s1)
    800086a4:	0007069b          	sext.w	a3,a4
    800086a8:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800086ac:	42075713          	srai	a4,a4,0x20
    800086b0:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800086b4:	00100713          	li	a4,1
    800086b8:	04e7a223          	sw	a4,68(a5)
    disk.free[i] = 1;
    800086bc:	00e48c23          	sb	a4,24(s1)
    800086c0:	00e48ca3          	sb	a4,25(s1)
    800086c4:	00e48d23          	sb	a4,26(s1)
    800086c8:	00e48da3          	sb	a4,27(s1)
    800086cc:	00e48e23          	sb	a4,28(s1)
    800086d0:	00e48ea3          	sb	a4,29(s1)
    800086d4:	00e48f23          	sb	a4,30(s1)
    800086d8:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800086dc:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800086e0:	0727a823          	sw	s2,112(a5)
}
    800086e4:	01813083          	ld	ra,24(sp)
    800086e8:	01013403          	ld	s0,16(sp)
    800086ec:	00813483          	ld	s1,8(sp)
    800086f0:	00013903          	ld	s2,0(sp)
    800086f4:	02010113          	addi	sp,sp,32
    800086f8:	00008067          	ret
    panic("could not find virtio disk");
    800086fc:	00002517          	auipc	a0,0x2
    80008700:	1c450513          	addi	a0,a0,452 # 8000a8c0 <syscalls+0x360>
    80008704:	ffff8097          	auipc	ra,0xffff8
    80008708:	37c080e7          	jalr	892(ra) # 80000a80 <panic>
    panic("virtio disk FEATURES_OK unset");
    8000870c:	00002517          	auipc	a0,0x2
    80008710:	1d450513          	addi	a0,a0,468 # 8000a8e0 <syscalls+0x380>
    80008714:	ffff8097          	auipc	ra,0xffff8
    80008718:	36c080e7          	jalr	876(ra) # 80000a80 <panic>
    panic("virtio disk should not be ready");
    8000871c:	00002517          	auipc	a0,0x2
    80008720:	1e450513          	addi	a0,a0,484 # 8000a900 <syscalls+0x3a0>
    80008724:	ffff8097          	auipc	ra,0xffff8
    80008728:	35c080e7          	jalr	860(ra) # 80000a80 <panic>
    panic("virtio disk has no queue 0");
    8000872c:	00002517          	auipc	a0,0x2
    80008730:	1f450513          	addi	a0,a0,500 # 8000a920 <syscalls+0x3c0>
    80008734:	ffff8097          	auipc	ra,0xffff8
    80008738:	34c080e7          	jalr	844(ra) # 80000a80 <panic>
    panic("virtio disk max queue too short");
    8000873c:	00002517          	auipc	a0,0x2
    80008740:	20450513          	addi	a0,a0,516 # 8000a940 <syscalls+0x3e0>
    80008744:	ffff8097          	auipc	ra,0xffff8
    80008748:	33c080e7          	jalr	828(ra) # 80000a80 <panic>
    panic("virtio disk kalloc");
    8000874c:	00002517          	auipc	a0,0x2
    80008750:	21450513          	addi	a0,a0,532 # 8000a960 <syscalls+0x400>
    80008754:	ffff8097          	auipc	ra,0xffff8
    80008758:	32c080e7          	jalr	812(ra) # 80000a80 <panic>

000000008000875c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000875c:	f8010113          	addi	sp,sp,-128
    80008760:	06113c23          	sd	ra,120(sp)
    80008764:	06813823          	sd	s0,112(sp)
    80008768:	06913423          	sd	s1,104(sp)
    8000876c:	07213023          	sd	s2,96(sp)
    80008770:	05313c23          	sd	s3,88(sp)
    80008774:	05413823          	sd	s4,80(sp)
    80008778:	05513423          	sd	s5,72(sp)
    8000877c:	05613023          	sd	s6,64(sp)
    80008780:	03713c23          	sd	s7,56(sp)
    80008784:	03813823          	sd	s8,48(sp)
    80008788:	03913423          	sd	s9,40(sp)
    8000878c:	03a13023          	sd	s10,32(sp)
    80008790:	01b13c23          	sd	s11,24(sp)
    80008794:	08010413          	addi	s0,sp,128
    80008798:	00050a93          	mv	s5,a0
    8000879c:	00058c13          	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800087a0:	00c52d03          	lw	s10,12(a0)
    800087a4:	001d1d1b          	slliw	s10,s10,0x1
    800087a8:	020d1d13          	slli	s10,s10,0x20
    800087ac:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800087b0:	0001b517          	auipc	a0,0x1b
    800087b4:	51050513          	addi	a0,a0,1296 # 80023cc0 <disk+0x128>
    800087b8:	ffff9097          	auipc	ra,0xffff9
    800087bc:	900080e7          	jalr	-1792(ra) # 800010b8 <acquire>
  for(int i = 0; i < 3; i++){
    800087c0:	00000993          	li	s3,0
  for(int i = 0; i < NUM; i++){
    800087c4:	00800493          	li	s1,8
      disk.free[i] = 0;
    800087c8:	0001bb97          	auipc	s7,0x1b
    800087cc:	3d0b8b93          	addi	s7,s7,976 # 80023b98 <disk>
  for(int i = 0; i < 3; i++){
    800087d0:	00300b13          	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800087d4:	0001bc97          	auipc	s9,0x1b
    800087d8:	4ecc8c93          	addi	s9,s9,1260 # 80023cc0 <disk+0x128>
    800087dc:	0800006f          	j	8000885c <virtio_disk_rw+0x100>
      disk.free[i] = 0;
    800087e0:	00fb8733          	add	a4,s7,a5
    800087e4:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800087e8:	00f5a023          	sw	a5,0(a1)
    if(idx[i] < 0){
    800087ec:	0207ce63          	bltz	a5,80008828 <virtio_disk_rw+0xcc>
  for(int i = 0; i < 3; i++){
    800087f0:	0019091b          	addiw	s2,s2,1
    800087f4:	00460613          	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800087f8:	07690a63          	beq	s2,s6,8000886c <virtio_disk_rw+0x110>
    idx[i] = alloc_desc();
    800087fc:	00060593          	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80008800:	0001b717          	auipc	a4,0x1b
    80008804:	39870713          	addi	a4,a4,920 # 80023b98 <disk>
    80008808:	00098793          	mv	a5,s3
    if(disk.free[i]){
    8000880c:	01874683          	lbu	a3,24(a4)
    80008810:	fc0698e3          	bnez	a3,800087e0 <virtio_disk_rw+0x84>
  for(int i = 0; i < NUM; i++){
    80008814:	0017879b          	addiw	a5,a5,1
    80008818:	00170713          	addi	a4,a4,1
    8000881c:	fe9798e3          	bne	a5,s1,8000880c <virtio_disk_rw+0xb0>
    idx[i] = alloc_desc();
    80008820:	fff00793          	li	a5,-1
    80008824:	00f5a023          	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80008828:	03205063          	blez	s2,80008848 <virtio_disk_rw+0xec>
    8000882c:	00098d93          	mv	s11,s3
        free_desc(idx[j]);
    80008830:	000a2503          	lw	a0,0(s4)
    80008834:	00000097          	auipc	ra,0x0
    80008838:	c1c080e7          	jalr	-996(ra) # 80008450 <free_desc>
      for(int j = 0; j < i; j++)
    8000883c:	001d8d9b          	addiw	s11,s11,1
    80008840:	004a0a13          	addi	s4,s4,4
    80008844:	ff2d96e3          	bne	s11,s2,80008830 <virtio_disk_rw+0xd4>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80008848:	000c8593          	mv	a1,s9
    8000884c:	0001b517          	auipc	a0,0x1b
    80008850:	36450513          	addi	a0,a0,868 # 80023bb0 <disk+0x18>
    80008854:	ffffb097          	auipc	ra,0xffffb
    80008858:	84c080e7          	jalr	-1972(ra) # 800030a0 <sleep>
  for(int i = 0; i < 3; i++){
    8000885c:	f8040a13          	addi	s4,s0,-128
{
    80008860:	000a0613          	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80008864:	00098913          	mv	s2,s3
    80008868:	f95ff06f          	j	800087fc <virtio_disk_rw+0xa0>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000886c:	f8042503          	lw	a0,-128(s0)
    80008870:	00a50713          	addi	a4,a0,10
    80008874:	00471713          	slli	a4,a4,0x4

  if(write)
    80008878:	0001b797          	auipc	a5,0x1b
    8000887c:	32078793          	addi	a5,a5,800 # 80023b98 <disk>
    80008880:	00e786b3          	add	a3,a5,a4
    80008884:	01803633          	snez	a2,s8
    80008888:	00c6a423          	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000888c:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80008890:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80008894:	f6070613          	addi	a2,a4,-160
    80008898:	0007b683          	ld	a3,0(a5)
    8000889c:	00c686b3          	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800088a0:	00870593          	addi	a1,a4,8
    800088a4:	00b785b3          	add	a1,a5,a1
  disk.desc[idx[0]].addr = (uint64) buf0;
    800088a8:	00b6b023          	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800088ac:	0007b803          	ld	a6,0(a5)
    800088b0:	00c80633          	add	a2,a6,a2
    800088b4:	01000693          	li	a3,16
    800088b8:	00d62423          	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800088bc:	00100593          	li	a1,1
    800088c0:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800088c4:	f8442683          	lw	a3,-124(s0)
    800088c8:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800088cc:	00469693          	slli	a3,a3,0x4
    800088d0:	00d80833          	add	a6,a6,a3
    800088d4:	058a8613          	addi	a2,s5,88
    800088d8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800088dc:	0007b803          	ld	a6,0(a5)
    800088e0:	00d806b3          	add	a3,a6,a3
    800088e4:	40000613          	li	a2,1024
    800088e8:	00c6a423          	sw	a2,8(a3)
  if(write)
    800088ec:	001c3613          	seqz	a2,s8
    800088f0:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800088f4:	00166613          	ori	a2,a2,1
    800088f8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800088fc:	f8842603          	lw	a2,-120(s0)
    80008900:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80008904:	00250693          	addi	a3,a0,2
    80008908:	00469693          	slli	a3,a3,0x4
    8000890c:	00d786b3          	add	a3,a5,a3
    80008910:	fff00893          	li	a7,-1
    80008914:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80008918:	00461613          	slli	a2,a2,0x4
    8000891c:	00c80833          	add	a6,a6,a2
    80008920:	f9070713          	addi	a4,a4,-112
    80008924:	00e78733          	add	a4,a5,a4
    80008928:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000892c:	0007b703          	ld	a4,0(a5)
    80008930:	00c70733          	add	a4,a4,a2
    80008934:	00b72423          	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80008938:	00200613          	li	a2,2
    8000893c:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80008940:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80008944:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80008948:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000894c:	0087b683          	ld	a3,8(a5)
    80008950:	0026d703          	lhu	a4,2(a3)
    80008954:	00777713          	andi	a4,a4,7
    80008958:	00171713          	slli	a4,a4,0x1
    8000895c:	00e686b3          	add	a3,a3,a4
    80008960:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80008964:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80008968:	0087b703          	ld	a4,8(a5)
    8000896c:	00275783          	lhu	a5,2(a4)
    80008970:	0017879b          	addiw	a5,a5,1
    80008974:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80008978:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000897c:	100017b7          	lui	a5,0x10001
    80008980:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80008984:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80008988:	0001b917          	auipc	s2,0x1b
    8000898c:	33890913          	addi	s2,s2,824 # 80023cc0 <disk+0x128>
  while(b->disk == 1) {
    80008990:	00100493          	li	s1,1
    80008994:	00b79e63          	bne	a5,a1,800089b0 <virtio_disk_rw+0x254>
    sleep(b, &disk.vdisk_lock);
    80008998:	00090593          	mv	a1,s2
    8000899c:	000a8513          	mv	a0,s5
    800089a0:	ffffa097          	auipc	ra,0xffffa
    800089a4:	700080e7          	jalr	1792(ra) # 800030a0 <sleep>
  while(b->disk == 1) {
    800089a8:	004aa783          	lw	a5,4(s5)
    800089ac:	fe9786e3          	beq	a5,s1,80008998 <virtio_disk_rw+0x23c>
  }

  disk.info[idx[0]].b = 0;
    800089b0:	f8042903          	lw	s2,-128(s0)
    800089b4:	00290713          	addi	a4,s2,2
    800089b8:	00471713          	slli	a4,a4,0x4
    800089bc:	0001b797          	auipc	a5,0x1b
    800089c0:	1dc78793          	addi	a5,a5,476 # 80023b98 <disk>
    800089c4:	00e787b3          	add	a5,a5,a4
    800089c8:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800089cc:	0001b997          	auipc	s3,0x1b
    800089d0:	1cc98993          	addi	s3,s3,460 # 80023b98 <disk>
    800089d4:	00491713          	slli	a4,s2,0x4
    800089d8:	0009b783          	ld	a5,0(s3)
    800089dc:	00e787b3          	add	a5,a5,a4
    800089e0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800089e4:	00090513          	mv	a0,s2
    800089e8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800089ec:	00000097          	auipc	ra,0x0
    800089f0:	a64080e7          	jalr	-1436(ra) # 80008450 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800089f4:	0014f493          	andi	s1,s1,1
    800089f8:	fc049ee3          	bnez	s1,800089d4 <virtio_disk_rw+0x278>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800089fc:	0001b517          	auipc	a0,0x1b
    80008a00:	2c450513          	addi	a0,a0,708 # 80023cc0 <disk+0x128>
    80008a04:	ffff8097          	auipc	ra,0xffff8
    80008a08:	7ac080e7          	jalr	1964(ra) # 800011b0 <release>
}
    80008a0c:	07813083          	ld	ra,120(sp)
    80008a10:	07013403          	ld	s0,112(sp)
    80008a14:	06813483          	ld	s1,104(sp)
    80008a18:	06013903          	ld	s2,96(sp)
    80008a1c:	05813983          	ld	s3,88(sp)
    80008a20:	05013a03          	ld	s4,80(sp)
    80008a24:	04813a83          	ld	s5,72(sp)
    80008a28:	04013b03          	ld	s6,64(sp)
    80008a2c:	03813b83          	ld	s7,56(sp)
    80008a30:	03013c03          	ld	s8,48(sp)
    80008a34:	02813c83          	ld	s9,40(sp)
    80008a38:	02013d03          	ld	s10,32(sp)
    80008a3c:	01813d83          	ld	s11,24(sp)
    80008a40:	08010113          	addi	sp,sp,128
    80008a44:	00008067          	ret

0000000080008a48 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80008a48:	fe010113          	addi	sp,sp,-32
    80008a4c:	00113c23          	sd	ra,24(sp)
    80008a50:	00813823          	sd	s0,16(sp)
    80008a54:	00913423          	sd	s1,8(sp)
    80008a58:	02010413          	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80008a5c:	0001b497          	auipc	s1,0x1b
    80008a60:	13c48493          	addi	s1,s1,316 # 80023b98 <disk>
    80008a64:	0001b517          	auipc	a0,0x1b
    80008a68:	25c50513          	addi	a0,a0,604 # 80023cc0 <disk+0x128>
    80008a6c:	ffff8097          	auipc	ra,0xffff8
    80008a70:	64c080e7          	jalr	1612(ra) # 800010b8 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80008a74:	10001737          	lui	a4,0x10001
    80008a78:	06072783          	lw	a5,96(a4) # 10001060 <_entry-0x6fffefa0>
    80008a7c:	0037f793          	andi	a5,a5,3
    80008a80:	06f72223          	sw	a5,100(a4)

  __sync_synchronize();
    80008a84:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80008a88:	0104b783          	ld	a5,16(s1)
    80008a8c:	0204d703          	lhu	a4,32(s1)
    80008a90:	0027d783          	lhu	a5,2(a5)
    80008a94:	06f70863          	beq	a4,a5,80008b04 <virtio_disk_intr+0xbc>
    __sync_synchronize();
    80008a98:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80008a9c:	0104b703          	ld	a4,16(s1)
    80008aa0:	0204d783          	lhu	a5,32(s1)
    80008aa4:	0077f793          	andi	a5,a5,7
    80008aa8:	00379793          	slli	a5,a5,0x3
    80008aac:	00f707b3          	add	a5,a4,a5
    80008ab0:	0047a783          	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80008ab4:	00278713          	addi	a4,a5,2
    80008ab8:	00471713          	slli	a4,a4,0x4
    80008abc:	00e48733          	add	a4,s1,a4
    80008ac0:	01074703          	lbu	a4,16(a4)
    80008ac4:	06071263          	bnez	a4,80008b28 <virtio_disk_intr+0xe0>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80008ac8:	00278793          	addi	a5,a5,2
    80008acc:	00479793          	slli	a5,a5,0x4
    80008ad0:	00f487b3          	add	a5,s1,a5
    80008ad4:	0087b503          	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80008ad8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80008adc:	ffffa097          	auipc	ra,0xffffa
    80008ae0:	654080e7          	jalr	1620(ra) # 80003130 <wakeup>

    disk.used_idx += 1;
    80008ae4:	0204d783          	lhu	a5,32(s1)
    80008ae8:	0017879b          	addiw	a5,a5,1
    80008aec:	03079793          	slli	a5,a5,0x30
    80008af0:	0307d793          	srli	a5,a5,0x30
    80008af4:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80008af8:	0104b703          	ld	a4,16(s1)
    80008afc:	00275703          	lhu	a4,2(a4)
    80008b00:	f8f71ce3          	bne	a4,a5,80008a98 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80008b04:	0001b517          	auipc	a0,0x1b
    80008b08:	1bc50513          	addi	a0,a0,444 # 80023cc0 <disk+0x128>
    80008b0c:	ffff8097          	auipc	ra,0xffff8
    80008b10:	6a4080e7          	jalr	1700(ra) # 800011b0 <release>
}
    80008b14:	01813083          	ld	ra,24(sp)
    80008b18:	01013403          	ld	s0,16(sp)
    80008b1c:	00813483          	ld	s1,8(sp)
    80008b20:	02010113          	addi	sp,sp,32
    80008b24:	00008067          	ret
      panic("virtio_disk_intr status");
    80008b28:	00002517          	auipc	a0,0x2
    80008b2c:	e5050513          	addi	a0,a0,-432 # 8000a978 <syscalls+0x418>
    80008b30:	ffff8097          	auipc	ra,0xffff8
    80008b34:	f50080e7          	jalr	-176(ra) # 80000a80 <panic>
	...

0000000080009000 <_trampoline>:
    80009000:	14051073          	csrw	sscratch,a0
    80009004:	02000537          	lui	a0,0x2000
    80009008:	fff5051b          	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000900c:	00d51513          	slli	a0,a0,0xd
    80009010:	02153423          	sd	ra,40(a0)
    80009014:	02253823          	sd	sp,48(a0)
    80009018:	02353c23          	sd	gp,56(a0)
    8000901c:	04453023          	sd	tp,64(a0)
    80009020:	04553423          	sd	t0,72(a0)
    80009024:	04653823          	sd	t1,80(a0)
    80009028:	04753c23          	sd	t2,88(a0)
    8000902c:	06853023          	sd	s0,96(a0)
    80009030:	06953423          	sd	s1,104(a0)
    80009034:	06b53c23          	sd	a1,120(a0)
    80009038:	08c53023          	sd	a2,128(a0)
    8000903c:	08d53423          	sd	a3,136(a0)
    80009040:	08e53823          	sd	a4,144(a0)
    80009044:	08f53c23          	sd	a5,152(a0)
    80009048:	0b053023          	sd	a6,160(a0)
    8000904c:	0b153423          	sd	a7,168(a0)
    80009050:	0b253823          	sd	s2,176(a0)
    80009054:	0b353c23          	sd	s3,184(a0)
    80009058:	0d453023          	sd	s4,192(a0)
    8000905c:	0d553423          	sd	s5,200(a0)
    80009060:	0d653823          	sd	s6,208(a0)
    80009064:	0d753c23          	sd	s7,216(a0)
    80009068:	0f853023          	sd	s8,224(a0)
    8000906c:	0f953423          	sd	s9,232(a0)
    80009070:	0fa53823          	sd	s10,240(a0)
    80009074:	0fb53c23          	sd	s11,248(a0)
    80009078:	11c53023          	sd	t3,256(a0)
    8000907c:	11d53423          	sd	t4,264(a0)
    80009080:	11e53823          	sd	t5,272(a0)
    80009084:	11f53c23          	sd	t6,280(a0)
    80009088:	140022f3          	csrr	t0,sscratch
    8000908c:	06553823          	sd	t0,112(a0)
    80009090:	00853103          	ld	sp,8(a0)
    80009094:	02053203          	ld	tp,32(a0)
    80009098:	01053283          	ld	t0,16(a0)
    8000909c:	00053303          	ld	t1,0(a0)
    800090a0:	12000073          	sfence.vma
    800090a4:	18031073          	csrw	satp,t1
    800090a8:	12000073          	sfence.vma
    800090ac:	000280e7          	jalr	t0

00000000800090b0 <userret>:
    800090b0:	12000073          	sfence.vma
    800090b4:	18051073          	csrw	satp,a0
    800090b8:	12000073          	sfence.vma
    800090bc:	02000537          	lui	a0,0x2000
    800090c0:	fff5051b          	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800090c4:	00d51513          	slli	a0,a0,0xd
    800090c8:	02853083          	ld	ra,40(a0)
    800090cc:	03053103          	ld	sp,48(a0)
    800090d0:	03853183          	ld	gp,56(a0)
    800090d4:	04053203          	ld	tp,64(a0)
    800090d8:	04853283          	ld	t0,72(a0)
    800090dc:	05053303          	ld	t1,80(a0)
    800090e0:	05853383          	ld	t2,88(a0)
    800090e4:	06053403          	ld	s0,96(a0)
    800090e8:	06853483          	ld	s1,104(a0)
    800090ec:	07853583          	ld	a1,120(a0)
    800090f0:	08053603          	ld	a2,128(a0)
    800090f4:	08853683          	ld	a3,136(a0)
    800090f8:	09053703          	ld	a4,144(a0)
    800090fc:	09853783          	ld	a5,152(a0)
    80009100:	0a053803          	ld	a6,160(a0)
    80009104:	0a853883          	ld	a7,168(a0)
    80009108:	0b053903          	ld	s2,176(a0)
    8000910c:	0b853983          	ld	s3,184(a0)
    80009110:	0c053a03          	ld	s4,192(a0)
    80009114:	0c853a83          	ld	s5,200(a0)
    80009118:	0d053b03          	ld	s6,208(a0)
    8000911c:	0d853b83          	ld	s7,216(a0)
    80009120:	0e053c03          	ld	s8,224(a0)
    80009124:	0e853c83          	ld	s9,232(a0)
    80009128:	0f053d03          	ld	s10,240(a0)
    8000912c:	0f853d83          	ld	s11,248(a0)
    80009130:	10053e03          	ld	t3,256(a0)
    80009134:	10853e83          	ld	t4,264(a0)
    80009138:	11053f03          	ld	t5,272(a0)
    8000913c:	11853f83          	ld	t6,280(a0)
    80009140:	07053503          	ld	a0,112(a0)
    80009144:	10200073          	sret
	...
