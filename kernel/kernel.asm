
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8e013103          	ld	sp,-1824(sp) # 800088e0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	ff070713          	addi	a4,a4,-16 # 80009040 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	34e78793          	addi	a5,a5,846 # 800063b0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dc678793          	addi	a5,a5,-570 # 80000e72 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	748080e7          	jalr	1864(ra) # 80002872 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	77e080e7          	jalr	1918(ra) # 800008b8 <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	ff650513          	addi	a0,a0,-10 # 80011180 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a3e080e7          	jalr	-1474(ra) # 80000bd0 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	fe648493          	addi	s1,s1,-26 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	07690913          	addi	s2,s2,118 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305863          	blez	s3,80000220 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71463          	bne	a4,a5,800001e4 <consoleread+0x80>
      if(myproc()->killed){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	a90080e7          	jalr	-1392(ra) # 80001c50 <myproc>
    800001c8:	551c                	lw	a5,40(a0)
    800001ca:	e7b5                	bnez	a5,80000236 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	1fe080e7          	jalr	510(ra) # 800023ce <sleep>
    while(cons.r == cons.w){
    800001d8:	0984a783          	lw	a5,152(s1)
    800001dc:	09c4a703          	lw	a4,156(s1)
    800001e0:	fef700e3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e4:	0017871b          	addiw	a4,a5,1
    800001e8:	08e4ac23          	sw	a4,152(s1)
    800001ec:	07f7f713          	andi	a4,a5,127
    800001f0:	9726                	add	a4,a4,s1
    800001f2:	01874703          	lbu	a4,24(a4)
    800001f6:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001fa:	077d0563          	beq	s10,s7,80000264 <consoleread+0x100>
    cbuf = c;
    800001fe:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000202:	4685                	li	a3,1
    80000204:	f9f40613          	addi	a2,s0,-97
    80000208:	85d2                	mv	a1,s4
    8000020a:	8556                	mv	a0,s5
    8000020c:	00002097          	auipc	ra,0x2
    80000210:	610080e7          	jalr	1552(ra) # 8000281c <either_copyout>
    80000214:	01850663          	beq	a0,s8,80000220 <consoleread+0xbc>
    dst++;
    80000218:	0a05                	addi	s4,s4,1
    --n;
    8000021a:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000021c:	f99d1ae3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000220:	00011517          	auipc	a0,0x11
    80000224:	f6050513          	addi	a0,a0,-160 # 80011180 <cons>
    80000228:	00001097          	auipc	ra,0x1
    8000022c:	a5c080e7          	jalr	-1444(ra) # 80000c84 <release>

  return target - n;
    80000230:	413b053b          	subw	a0,s6,s3
    80000234:	a811                	j	80000248 <consoleread+0xe4>
        release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f4a50513          	addi	a0,a0,-182 # 80011180 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	a46080e7          	jalr	-1466(ra) # 80000c84 <release>
        return -1;
    80000246:	557d                	li	a0,-1
}
    80000248:	70a6                	ld	ra,104(sp)
    8000024a:	7406                	ld	s0,96(sp)
    8000024c:	64e6                	ld	s1,88(sp)
    8000024e:	6946                	ld	s2,80(sp)
    80000250:	69a6                	ld	s3,72(sp)
    80000252:	6a06                	ld	s4,64(sp)
    80000254:	7ae2                	ld	s5,56(sp)
    80000256:	7b42                	ld	s6,48(sp)
    80000258:	7ba2                	ld	s7,40(sp)
    8000025a:	7c02                	ld	s8,32(sp)
    8000025c:	6ce2                	ld	s9,24(sp)
    8000025e:	6d42                	ld	s10,16(sp)
    80000260:	6165                	addi	sp,sp,112
    80000262:	8082                	ret
      if(n < target){
    80000264:	0009871b          	sext.w	a4,s3
    80000268:	fb677ce3          	bgeu	a4,s6,80000220 <consoleread+0xbc>
        cons.r--;
    8000026c:	00011717          	auipc	a4,0x11
    80000270:	faf72623          	sw	a5,-84(a4) # 80011218 <cons+0x98>
    80000274:	b775                	j	80000220 <consoleread+0xbc>

0000000080000276 <consputc>:
{
    80000276:	1141                	addi	sp,sp,-16
    80000278:	e406                	sd	ra,8(sp)
    8000027a:	e022                	sd	s0,0(sp)
    8000027c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000027e:	10000793          	li	a5,256
    80000282:	00f50a63          	beq	a0,a5,80000296 <consputc+0x20>
    uartputc_sync(c);
    80000286:	00000097          	auipc	ra,0x0
    8000028a:	560080e7          	jalr	1376(ra) # 800007e6 <uartputc_sync>
}
    8000028e:	60a2                	ld	ra,8(sp)
    80000290:	6402                	ld	s0,0(sp)
    80000292:	0141                	addi	sp,sp,16
    80000294:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000296:	4521                	li	a0,8
    80000298:	00000097          	auipc	ra,0x0
    8000029c:	54e080e7          	jalr	1358(ra) # 800007e6 <uartputc_sync>
    800002a0:	02000513          	li	a0,32
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	542080e7          	jalr	1346(ra) # 800007e6 <uartputc_sync>
    800002ac:	4521                	li	a0,8
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	538080e7          	jalr	1336(ra) # 800007e6 <uartputc_sync>
    800002b6:	bfe1                	j	8000028e <consputc+0x18>

00000000800002b8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b8:	1101                	addi	sp,sp,-32
    800002ba:	ec06                	sd	ra,24(sp)
    800002bc:	e822                	sd	s0,16(sp)
    800002be:	e426                	sd	s1,8(sp)
    800002c0:	e04a                	sd	s2,0(sp)
    800002c2:	1000                	addi	s0,sp,32
    800002c4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c6:	00011517          	auipc	a0,0x11
    800002ca:	eba50513          	addi	a0,a0,-326 # 80011180 <cons>
    800002ce:	00001097          	auipc	ra,0x1
    800002d2:	902080e7          	jalr	-1790(ra) # 80000bd0 <acquire>

  switch(c){
    800002d6:	47d5                	li	a5,21
    800002d8:	0af48663          	beq	s1,a5,80000384 <consoleintr+0xcc>
    800002dc:	0297ca63          	blt	a5,s1,80000310 <consoleintr+0x58>
    800002e0:	47a1                	li	a5,8
    800002e2:	0ef48763          	beq	s1,a5,800003d0 <consoleintr+0x118>
    800002e6:	47c1                	li	a5,16
    800002e8:	10f49a63          	bne	s1,a5,800003fc <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ec:	00002097          	auipc	ra,0x2
    800002f0:	5dc080e7          	jalr	1500(ra) # 800028c8 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f4:	00011517          	auipc	a0,0x11
    800002f8:	e8c50513          	addi	a0,a0,-372 # 80011180 <cons>
    800002fc:	00001097          	auipc	ra,0x1
    80000300:	988080e7          	jalr	-1656(ra) # 80000c84 <release>
}
    80000304:	60e2                	ld	ra,24(sp)
    80000306:	6442                	ld	s0,16(sp)
    80000308:	64a2                	ld	s1,8(sp)
    8000030a:	6902                	ld	s2,0(sp)
    8000030c:	6105                	addi	sp,sp,32
    8000030e:	8082                	ret
  switch(c){
    80000310:	07f00793          	li	a5,127
    80000314:	0af48e63          	beq	s1,a5,800003d0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000318:	00011717          	auipc	a4,0x11
    8000031c:	e6870713          	addi	a4,a4,-408 # 80011180 <cons>
    80000320:	0a072783          	lw	a5,160(a4)
    80000324:	09872703          	lw	a4,152(a4)
    80000328:	9f99                	subw	a5,a5,a4
    8000032a:	07f00713          	li	a4,127
    8000032e:	fcf763e3          	bltu	a4,a5,800002f4 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000332:	47b5                	li	a5,13
    80000334:	0cf48763          	beq	s1,a5,80000402 <consoleintr+0x14a>
      consputc(c);
    80000338:	8526                	mv	a0,s1
    8000033a:	00000097          	auipc	ra,0x0
    8000033e:	f3c080e7          	jalr	-196(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000342:	00011797          	auipc	a5,0x11
    80000346:	e3e78793          	addi	a5,a5,-450 # 80011180 <cons>
    8000034a:	0a07a703          	lw	a4,160(a5)
    8000034e:	0017069b          	addiw	a3,a4,1
    80000352:	0006861b          	sext.w	a2,a3
    80000356:	0ad7a023          	sw	a3,160(a5)
    8000035a:	07f77713          	andi	a4,a4,127
    8000035e:	97ba                	add	a5,a5,a4
    80000360:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000364:	47a9                	li	a5,10
    80000366:	0cf48563          	beq	s1,a5,80000430 <consoleintr+0x178>
    8000036a:	4791                	li	a5,4
    8000036c:	0cf48263          	beq	s1,a5,80000430 <consoleintr+0x178>
    80000370:	00011797          	auipc	a5,0x11
    80000374:	ea87a783          	lw	a5,-344(a5) # 80011218 <cons+0x98>
    80000378:	0807879b          	addiw	a5,a5,128
    8000037c:	f6f61ce3          	bne	a2,a5,800002f4 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000380:	863e                	mv	a2,a5
    80000382:	a07d                	j	80000430 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000384:	00011717          	auipc	a4,0x11
    80000388:	dfc70713          	addi	a4,a4,-516 # 80011180 <cons>
    8000038c:	0a072783          	lw	a5,160(a4)
    80000390:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	00011497          	auipc	s1,0x11
    80000398:	dec48493          	addi	s1,s1,-532 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000039c:	4929                	li	s2,10
    8000039e:	f4f70be3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a2:	37fd                	addiw	a5,a5,-1
    800003a4:	07f7f713          	andi	a4,a5,127
    800003a8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003aa:	01874703          	lbu	a4,24(a4)
    800003ae:	f52703e3          	beq	a4,s2,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003b2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b6:	10000513          	li	a0,256
    800003ba:	00000097          	auipc	ra,0x0
    800003be:	ebc080e7          	jalr	-324(ra) # 80000276 <consputc>
    while(cons.e != cons.w &&
    800003c2:	0a04a783          	lw	a5,160(s1)
    800003c6:	09c4a703          	lw	a4,156(s1)
    800003ca:	fcf71ce3          	bne	a4,a5,800003a2 <consoleintr+0xea>
    800003ce:	b71d                	j	800002f4 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d0:	00011717          	auipc	a4,0x11
    800003d4:	db070713          	addi	a4,a4,-592 # 80011180 <cons>
    800003d8:	0a072783          	lw	a5,160(a4)
    800003dc:	09c72703          	lw	a4,156(a4)
    800003e0:	f0f70ae3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003e4:	37fd                	addiw	a5,a5,-1
    800003e6:	00011717          	auipc	a4,0x11
    800003ea:	e2f72d23          	sw	a5,-454(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003ee:	10000513          	li	a0,256
    800003f2:	00000097          	auipc	ra,0x0
    800003f6:	e84080e7          	jalr	-380(ra) # 80000276 <consputc>
    800003fa:	bded                	j	800002f4 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003fc:	ee048ce3          	beqz	s1,800002f4 <consoleintr+0x3c>
    80000400:	bf21                	j	80000318 <consoleintr+0x60>
      consputc(c);
    80000402:	4529                	li	a0,10
    80000404:	00000097          	auipc	ra,0x0
    80000408:	e72080e7          	jalr	-398(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000040c:	00011797          	auipc	a5,0x11
    80000410:	d7478793          	addi	a5,a5,-652 # 80011180 <cons>
    80000414:	0a07a703          	lw	a4,160(a5)
    80000418:	0017069b          	addiw	a3,a4,1
    8000041c:	0006861b          	sext.w	a2,a3
    80000420:	0ad7a023          	sw	a3,160(a5)
    80000424:	07f77713          	andi	a4,a4,127
    80000428:	97ba                	add	a5,a5,a4
    8000042a:	4729                	li	a4,10
    8000042c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000430:	00011797          	auipc	a5,0x11
    80000434:	dec7a623          	sw	a2,-532(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000438:	00011517          	auipc	a0,0x11
    8000043c:	de050513          	addi	a0,a0,-544 # 80011218 <cons+0x98>
    80000440:	00002097          	auipc	ra,0x2
    80000444:	11a080e7          	jalr	282(ra) # 8000255a <wakeup>
    80000448:	b575                	j	800002f4 <consoleintr+0x3c>

000000008000044a <consoleinit>:

void
consoleinit(void)
{
    8000044a:	1141                	addi	sp,sp,-16
    8000044c:	e406                	sd	ra,8(sp)
    8000044e:	e022                	sd	s0,0(sp)
    80000450:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000452:	00008597          	auipc	a1,0x8
    80000456:	bbe58593          	addi	a1,a1,-1090 # 80008010 <etext+0x10>
    8000045a:	00011517          	auipc	a0,0x11
    8000045e:	d2650513          	addi	a0,a0,-730 # 80011180 <cons>
    80000462:	00000097          	auipc	ra,0x0
    80000466:	6de080e7          	jalr	1758(ra) # 80000b40 <initlock>

  uartinit();
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	32c080e7          	jalr	812(ra) # 80000796 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000472:	00021797          	auipc	a5,0x21
    80000476:	73678793          	addi	a5,a5,1846 # 80021ba8 <devsw>
    8000047a:	00000717          	auipc	a4,0x0
    8000047e:	cea70713          	addi	a4,a4,-790 # 80000164 <consoleread>
    80000482:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000484:	00000717          	auipc	a4,0x0
    80000488:	c7c70713          	addi	a4,a4,-900 # 80000100 <consolewrite>
    8000048c:	ef98                	sd	a4,24(a5)
}
    8000048e:	60a2                	ld	ra,8(sp)
    80000490:	6402                	ld	s0,0(sp)
    80000492:	0141                	addi	sp,sp,16
    80000494:	8082                	ret

0000000080000496 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000496:	7179                	addi	sp,sp,-48
    80000498:	f406                	sd	ra,40(sp)
    8000049a:	f022                	sd	s0,32(sp)
    8000049c:	ec26                	sd	s1,24(sp)
    8000049e:	e84a                	sd	s2,16(sp)
    800004a0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a2:	c219                	beqz	a2,800004a8 <printint+0x12>
    800004a4:	08054763          	bltz	a0,80000532 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004a8:	2501                	sext.w	a0,a0
    800004aa:	4881                	li	a7,0
    800004ac:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b2:	2581                	sext.w	a1,a1
    800004b4:	00008617          	auipc	a2,0x8
    800004b8:	b8c60613          	addi	a2,a2,-1140 # 80008040 <digits>
    800004bc:	883a                	mv	a6,a4
    800004be:	2705                	addiw	a4,a4,1
    800004c0:	02b577bb          	remuw	a5,a0,a1
    800004c4:	1782                	slli	a5,a5,0x20
    800004c6:	9381                	srli	a5,a5,0x20
    800004c8:	97b2                	add	a5,a5,a2
    800004ca:	0007c783          	lbu	a5,0(a5)
    800004ce:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d2:	0005079b          	sext.w	a5,a0
    800004d6:	02b5553b          	divuw	a0,a0,a1
    800004da:	0685                	addi	a3,a3,1
    800004dc:	feb7f0e3          	bgeu	a5,a1,800004bc <printint+0x26>

  if(sign)
    800004e0:	00088c63          	beqz	a7,800004f8 <printint+0x62>
    buf[i++] = '-';
    800004e4:	fe070793          	addi	a5,a4,-32
    800004e8:	00878733          	add	a4,a5,s0
    800004ec:	02d00793          	li	a5,45
    800004f0:	fef70823          	sb	a5,-16(a4)
    800004f4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004f8:	02e05763          	blez	a4,80000526 <printint+0x90>
    800004fc:	fd040793          	addi	a5,s0,-48
    80000500:	00e784b3          	add	s1,a5,a4
    80000504:	fff78913          	addi	s2,a5,-1
    80000508:	993a                	add	s2,s2,a4
    8000050a:	377d                	addiw	a4,a4,-1
    8000050c:	1702                	slli	a4,a4,0x20
    8000050e:	9301                	srli	a4,a4,0x20
    80000510:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000514:	fff4c503          	lbu	a0,-1(s1)
    80000518:	00000097          	auipc	ra,0x0
    8000051c:	d5e080e7          	jalr	-674(ra) # 80000276 <consputc>
  while(--i >= 0)
    80000520:	14fd                	addi	s1,s1,-1
    80000522:	ff2499e3          	bne	s1,s2,80000514 <printint+0x7e>
}
    80000526:	70a2                	ld	ra,40(sp)
    80000528:	7402                	ld	s0,32(sp)
    8000052a:	64e2                	ld	s1,24(sp)
    8000052c:	6942                	ld	s2,16(sp)
    8000052e:	6145                	addi	sp,sp,48
    80000530:	8082                	ret
    x = -xx;
    80000532:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000536:	4885                	li	a7,1
    x = -xx;
    80000538:	bf95                	j	800004ac <printint+0x16>

000000008000053a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053a:	1101                	addi	sp,sp,-32
    8000053c:	ec06                	sd	ra,24(sp)
    8000053e:	e822                	sd	s0,16(sp)
    80000540:	e426                	sd	s1,8(sp)
    80000542:	1000                	addi	s0,sp,32
    80000544:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000546:	00011797          	auipc	a5,0x11
    8000054a:	ce07ad23          	sw	zero,-774(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000054e:	00008517          	auipc	a0,0x8
    80000552:	aca50513          	addi	a0,a0,-1334 # 80008018 <etext+0x18>
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	02e080e7          	jalr	46(ra) # 80000584 <printf>
  printf(s);
    8000055e:	8526                	mv	a0,s1
    80000560:	00000097          	auipc	ra,0x0
    80000564:	024080e7          	jalr	36(ra) # 80000584 <printf>
  printf("\n");
    80000568:	00008517          	auipc	a0,0x8
    8000056c:	b6050513          	addi	a0,a0,-1184 # 800080c8 <digits+0x88>
    80000570:	00000097          	auipc	ra,0x0
    80000574:	014080e7          	jalr	20(ra) # 80000584 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000578:	4785                	li	a5,1
    8000057a:	00009717          	auipc	a4,0x9
    8000057e:	a8f72323          	sw	a5,-1402(a4) # 80009000 <panicked>
  for(;;)
    80000582:	a001                	j	80000582 <panic+0x48>

0000000080000584 <printf>:
{
    80000584:	7131                	addi	sp,sp,-192
    80000586:	fc86                	sd	ra,120(sp)
    80000588:	f8a2                	sd	s0,112(sp)
    8000058a:	f4a6                	sd	s1,104(sp)
    8000058c:	f0ca                	sd	s2,96(sp)
    8000058e:	ecce                	sd	s3,88(sp)
    80000590:	e8d2                	sd	s4,80(sp)
    80000592:	e4d6                	sd	s5,72(sp)
    80000594:	e0da                	sd	s6,64(sp)
    80000596:	fc5e                	sd	s7,56(sp)
    80000598:	f862                	sd	s8,48(sp)
    8000059a:	f466                	sd	s9,40(sp)
    8000059c:	f06a                	sd	s10,32(sp)
    8000059e:	ec6e                	sd	s11,24(sp)
    800005a0:	0100                	addi	s0,sp,128
    800005a2:	8a2a                	mv	s4,a0
    800005a4:	e40c                	sd	a1,8(s0)
    800005a6:	e810                	sd	a2,16(s0)
    800005a8:	ec14                	sd	a3,24(s0)
    800005aa:	f018                	sd	a4,32(s0)
    800005ac:	f41c                	sd	a5,40(s0)
    800005ae:	03043823          	sd	a6,48(s0)
    800005b2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b6:	00011d97          	auipc	s11,0x11
    800005ba:	c8adad83          	lw	s11,-886(s11) # 80011240 <pr+0x18>
  if(locking)
    800005be:	020d9b63          	bnez	s11,800005f4 <printf+0x70>
  if (fmt == 0)
    800005c2:	040a0263          	beqz	s4,80000606 <printf+0x82>
  va_start(ap, fmt);
    800005c6:	00840793          	addi	a5,s0,8
    800005ca:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005ce:	000a4503          	lbu	a0,0(s4)
    800005d2:	14050f63          	beqz	a0,80000730 <printf+0x1ac>
    800005d6:	4981                	li	s3,0
    if(c != '%'){
    800005d8:	02500a93          	li	s5,37
    switch(c){
    800005dc:	07000b93          	li	s7,112
  consputc('x');
    800005e0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e2:	00008b17          	auipc	s6,0x8
    800005e6:	a5eb0b13          	addi	s6,s6,-1442 # 80008040 <digits>
    switch(c){
    800005ea:	07300c93          	li	s9,115
    800005ee:	06400c13          	li	s8,100
    800005f2:	a82d                	j	8000062c <printf+0xa8>
    acquire(&pr.lock);
    800005f4:	00011517          	auipc	a0,0x11
    800005f8:	c3450513          	addi	a0,a0,-972 # 80011228 <pr>
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	5d4080e7          	jalr	1492(ra) # 80000bd0 <acquire>
    80000604:	bf7d                	j	800005c2 <printf+0x3e>
    panic("null fmt");
    80000606:	00008517          	auipc	a0,0x8
    8000060a:	a2250513          	addi	a0,a0,-1502 # 80008028 <etext+0x28>
    8000060e:	00000097          	auipc	ra,0x0
    80000612:	f2c080e7          	jalr	-212(ra) # 8000053a <panic>
      consputc(c);
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	c60080e7          	jalr	-928(ra) # 80000276 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000061e:	2985                	addiw	s3,s3,1
    80000620:	013a07b3          	add	a5,s4,s3
    80000624:	0007c503          	lbu	a0,0(a5)
    80000628:	10050463          	beqz	a0,80000730 <printf+0x1ac>
    if(c != '%'){
    8000062c:	ff5515e3          	bne	a0,s5,80000616 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000630:	2985                	addiw	s3,s3,1
    80000632:	013a07b3          	add	a5,s4,s3
    80000636:	0007c783          	lbu	a5,0(a5)
    8000063a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000063e:	cbed                	beqz	a5,80000730 <printf+0x1ac>
    switch(c){
    80000640:	05778a63          	beq	a5,s7,80000694 <printf+0x110>
    80000644:	02fbf663          	bgeu	s7,a5,80000670 <printf+0xec>
    80000648:	09978863          	beq	a5,s9,800006d8 <printf+0x154>
    8000064c:	07800713          	li	a4,120
    80000650:	0ce79563          	bne	a5,a4,8000071a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000654:	f8843783          	ld	a5,-120(s0)
    80000658:	00878713          	addi	a4,a5,8
    8000065c:	f8e43423          	sd	a4,-120(s0)
    80000660:	4605                	li	a2,1
    80000662:	85ea                	mv	a1,s10
    80000664:	4388                	lw	a0,0(a5)
    80000666:	00000097          	auipc	ra,0x0
    8000066a:	e30080e7          	jalr	-464(ra) # 80000496 <printint>
      break;
    8000066e:	bf45                	j	8000061e <printf+0x9a>
    switch(c){
    80000670:	09578f63          	beq	a5,s5,8000070e <printf+0x18a>
    80000674:	0b879363          	bne	a5,s8,8000071a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000678:	f8843783          	ld	a5,-120(s0)
    8000067c:	00878713          	addi	a4,a5,8
    80000680:	f8e43423          	sd	a4,-120(s0)
    80000684:	4605                	li	a2,1
    80000686:	45a9                	li	a1,10
    80000688:	4388                	lw	a0,0(a5)
    8000068a:	00000097          	auipc	ra,0x0
    8000068e:	e0c080e7          	jalr	-500(ra) # 80000496 <printint>
      break;
    80000692:	b771                	j	8000061e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000694:	f8843783          	ld	a5,-120(s0)
    80000698:	00878713          	addi	a4,a5,8
    8000069c:	f8e43423          	sd	a4,-120(s0)
    800006a0:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a4:	03000513          	li	a0,48
    800006a8:	00000097          	auipc	ra,0x0
    800006ac:	bce080e7          	jalr	-1074(ra) # 80000276 <consputc>
  consputc('x');
    800006b0:	07800513          	li	a0,120
    800006b4:	00000097          	auipc	ra,0x0
    800006b8:	bc2080e7          	jalr	-1086(ra) # 80000276 <consputc>
    800006bc:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006be:	03c95793          	srli	a5,s2,0x3c
    800006c2:	97da                	add	a5,a5,s6
    800006c4:	0007c503          	lbu	a0,0(a5)
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	bae080e7          	jalr	-1106(ra) # 80000276 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d0:	0912                	slli	s2,s2,0x4
    800006d2:	34fd                	addiw	s1,s1,-1
    800006d4:	f4ed                	bnez	s1,800006be <printf+0x13a>
    800006d6:	b7a1                	j	8000061e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d8:	f8843783          	ld	a5,-120(s0)
    800006dc:	00878713          	addi	a4,a5,8
    800006e0:	f8e43423          	sd	a4,-120(s0)
    800006e4:	6384                	ld	s1,0(a5)
    800006e6:	cc89                	beqz	s1,80000700 <printf+0x17c>
      for(; *s; s++)
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	d90d                	beqz	a0,8000061e <printf+0x9a>
        consputc(*s);
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	b88080e7          	jalr	-1144(ra) # 80000276 <consputc>
      for(; *s; s++)
    800006f6:	0485                	addi	s1,s1,1
    800006f8:	0004c503          	lbu	a0,0(s1)
    800006fc:	f96d                	bnez	a0,800006ee <printf+0x16a>
    800006fe:	b705                	j	8000061e <printf+0x9a>
        s = "(null)";
    80000700:	00008497          	auipc	s1,0x8
    80000704:	92048493          	addi	s1,s1,-1760 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000708:	02800513          	li	a0,40
    8000070c:	b7cd                	j	800006ee <printf+0x16a>
      consputc('%');
    8000070e:	8556                	mv	a0,s5
    80000710:	00000097          	auipc	ra,0x0
    80000714:	b66080e7          	jalr	-1178(ra) # 80000276 <consputc>
      break;
    80000718:	b719                	j	8000061e <printf+0x9a>
      consputc('%');
    8000071a:	8556                	mv	a0,s5
    8000071c:	00000097          	auipc	ra,0x0
    80000720:	b5a080e7          	jalr	-1190(ra) # 80000276 <consputc>
      consputc(c);
    80000724:	8526                	mv	a0,s1
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b50080e7          	jalr	-1200(ra) # 80000276 <consputc>
      break;
    8000072e:	bdc5                	j	8000061e <printf+0x9a>
  if(locking)
    80000730:	020d9163          	bnez	s11,80000752 <printf+0x1ce>
}
    80000734:	70e6                	ld	ra,120(sp)
    80000736:	7446                	ld	s0,112(sp)
    80000738:	74a6                	ld	s1,104(sp)
    8000073a:	7906                	ld	s2,96(sp)
    8000073c:	69e6                	ld	s3,88(sp)
    8000073e:	6a46                	ld	s4,80(sp)
    80000740:	6aa6                	ld	s5,72(sp)
    80000742:	6b06                	ld	s6,64(sp)
    80000744:	7be2                	ld	s7,56(sp)
    80000746:	7c42                	ld	s8,48(sp)
    80000748:	7ca2                	ld	s9,40(sp)
    8000074a:	7d02                	ld	s10,32(sp)
    8000074c:	6de2                	ld	s11,24(sp)
    8000074e:	6129                	addi	sp,sp,192
    80000750:	8082                	ret
    release(&pr.lock);
    80000752:	00011517          	auipc	a0,0x11
    80000756:	ad650513          	addi	a0,a0,-1322 # 80011228 <pr>
    8000075a:	00000097          	auipc	ra,0x0
    8000075e:	52a080e7          	jalr	1322(ra) # 80000c84 <release>
}
    80000762:	bfc9                	j	80000734 <printf+0x1b0>

0000000080000764 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000764:	1101                	addi	sp,sp,-32
    80000766:	ec06                	sd	ra,24(sp)
    80000768:	e822                	sd	s0,16(sp)
    8000076a:	e426                	sd	s1,8(sp)
    8000076c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076e:	00011497          	auipc	s1,0x11
    80000772:	aba48493          	addi	s1,s1,-1350 # 80011228 <pr>
    80000776:	00008597          	auipc	a1,0x8
    8000077a:	8c258593          	addi	a1,a1,-1854 # 80008038 <etext+0x38>
    8000077e:	8526                	mv	a0,s1
    80000780:	00000097          	auipc	ra,0x0
    80000784:	3c0080e7          	jalr	960(ra) # 80000b40 <initlock>
  pr.locking = 1;
    80000788:	4785                	li	a5,1
    8000078a:	cc9c                	sw	a5,24(s1)
}
    8000078c:	60e2                	ld	ra,24(sp)
    8000078e:	6442                	ld	s0,16(sp)
    80000790:	64a2                	ld	s1,8(sp)
    80000792:	6105                	addi	sp,sp,32
    80000794:	8082                	ret

0000000080000796 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000796:	1141                	addi	sp,sp,-16
    80000798:	e406                	sd	ra,8(sp)
    8000079a:	e022                	sd	s0,0(sp)
    8000079c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079e:	100007b7          	lui	a5,0x10000
    800007a2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a6:	f8000713          	li	a4,-128
    800007aa:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ae:	470d                	li	a4,3
    800007b0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007bc:	469d                	li	a3,7
    800007be:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c6:	00008597          	auipc	a1,0x8
    800007ca:	89258593          	addi	a1,a1,-1902 # 80008058 <digits+0x18>
    800007ce:	00011517          	auipc	a0,0x11
    800007d2:	a7a50513          	addi	a0,a0,-1414 # 80011248 <uart_tx_lock>
    800007d6:	00000097          	auipc	ra,0x0
    800007da:	36a080e7          	jalr	874(ra) # 80000b40 <initlock>
}
    800007de:	60a2                	ld	ra,8(sp)
    800007e0:	6402                	ld	s0,0(sp)
    800007e2:	0141                	addi	sp,sp,16
    800007e4:	8082                	ret

00000000800007e6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e6:	1101                	addi	sp,sp,-32
    800007e8:	ec06                	sd	ra,24(sp)
    800007ea:	e822                	sd	s0,16(sp)
    800007ec:	e426                	sd	s1,8(sp)
    800007ee:	1000                	addi	s0,sp,32
    800007f0:	84aa                	mv	s1,a0
  push_off();
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	392080e7          	jalr	914(ra) # 80000b84 <push_off>

  if(panicked){
    800007fa:	00009797          	auipc	a5,0x9
    800007fe:	8067a783          	lw	a5,-2042(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000802:	10000737          	lui	a4,0x10000
  if(panicked){
    80000806:	c391                	beqz	a5,8000080a <uartputc_sync+0x24>
    for(;;)
    80000808:	a001                	j	80000808 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dfe5                	beqz	a5,8000080a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f513          	zext.b	a0,s1
    80000818:	100007b7          	lui	a5,0x10000
    8000081c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	404080e7          	jalr	1028(ra) # 80000c24 <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008797          	auipc	a5,0x8
    80000836:	7d67b783          	ld	a5,2006(a5) # 80009008 <uart_tx_r>
    8000083a:	00008717          	auipc	a4,0x8
    8000083e:	7d673703          	ld	a4,2006(a4) # 80009010 <uart_tx_w>
    80000842:	06f70a63          	beq	a4,a5,800008b6 <uartstart+0x84>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9eca0a13          	addi	s4,s4,-1556 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	02077713          	andi	a4,a4,32
    8000087c:	c705                	beqz	a4,800008a4 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000087e:	01f7f713          	andi	a4,a5,31
    80000882:	9752                	add	a4,a4,s4
    80000884:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000888:	0785                	addi	a5,a5,1
    8000088a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088c:	8526                	mv	a0,s1
    8000088e:	00002097          	auipc	ra,0x2
    80000892:	ccc080e7          	jalr	-820(ra) # 8000255a <wakeup>
    
    WriteReg(THR, c);
    80000896:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089a:	609c                	ld	a5,0(s1)
    8000089c:	0009b703          	ld	a4,0(s3)
    800008a0:	fcf71ae3          	bne	a4,a5,80000874 <uartstart+0x42>
  }
}
    800008a4:	70e2                	ld	ra,56(sp)
    800008a6:	7442                	ld	s0,48(sp)
    800008a8:	74a2                	ld	s1,40(sp)
    800008aa:	7902                	ld	s2,32(sp)
    800008ac:	69e2                	ld	s3,24(sp)
    800008ae:	6a42                	ld	s4,16(sp)
    800008b0:	6aa2                	ld	s5,8(sp)
    800008b2:	6121                	addi	sp,sp,64
    800008b4:	8082                	ret
    800008b6:	8082                	ret

00000000800008b8 <uartputc>:
{
    800008b8:	7179                	addi	sp,sp,-48
    800008ba:	f406                	sd	ra,40(sp)
    800008bc:	f022                	sd	s0,32(sp)
    800008be:	ec26                	sd	s1,24(sp)
    800008c0:	e84a                	sd	s2,16(sp)
    800008c2:	e44e                	sd	s3,8(sp)
    800008c4:	e052                	sd	s4,0(sp)
    800008c6:	1800                	addi	s0,sp,48
    800008c8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ca:	00011517          	auipc	a0,0x11
    800008ce:	97e50513          	addi	a0,a0,-1666 # 80011248 <uart_tx_lock>
    800008d2:	00000097          	auipc	ra,0x0
    800008d6:	2fe080e7          	jalr	766(ra) # 80000bd0 <acquire>
  if(panicked){
    800008da:	00008797          	auipc	a5,0x8
    800008de:	7267a783          	lw	a5,1830(a5) # 80009000 <panicked>
    800008e2:	c391                	beqz	a5,800008e6 <uartputc+0x2e>
    for(;;)
    800008e4:	a001                	j	800008e4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	72a73703          	ld	a4,1834(a4) # 80009010 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	71a7b783          	ld	a5,1818(a5) # 80009008 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    800008fa:	02e79b63          	bne	a5,a4,80000930 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00011997          	auipc	s3,0x11
    80000902:	94a98993          	addi	s3,s3,-1718 # 80011248 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	70248493          	addi	s1,s1,1794 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	70290913          	addi	s2,s2,1794 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	ab4080e7          	jalr	-1356(ra) # 800023ce <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00011497          	auipc	s1,0x11
    80000934:	91848493          	addi	s1,s1,-1768 # 80011248 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	6ce7b623          	sd	a4,1740(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee6080e7          	jalr	-282(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	32e080e7          	jalr	814(ra) # 80000c84 <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	addi	sp,sp,48
    8000096c:	8082                	ret

000000008000096e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000096e:	1141                	addi	sp,sp,-16
    80000970:	e422                	sd	s0,8(sp)
    80000972:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000974:	100007b7          	lui	a5,0x10000
    80000978:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097c:	8b85                	andi	a5,a5,1
    8000097e:	cb81                	beqz	a5,8000098e <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000980:	100007b7          	lui	a5,0x10000
    80000984:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000988:	6422                	ld	s0,8(sp)
    8000098a:	0141                	addi	sp,sp,16
    8000098c:	8082                	ret
    return -1;
    8000098e:	557d                	li	a0,-1
    80000990:	bfe5                	j	80000988 <uartgetc+0x1a>

0000000080000992 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000992:	1101                	addi	sp,sp,-32
    80000994:	ec06                	sd	ra,24(sp)
    80000996:	e822                	sd	s0,16(sp)
    80000998:	e426                	sd	s1,8(sp)
    8000099a:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099c:	54fd                	li	s1,-1
    8000099e:	a029                	j	800009a8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a0:	00000097          	auipc	ra,0x0
    800009a4:	918080e7          	jalr	-1768(ra) # 800002b8 <consoleintr>
    int c = uartgetc();
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	fc6080e7          	jalr	-58(ra) # 8000096e <uartgetc>
    if(c == -1)
    800009b0:	fe9518e3          	bne	a0,s1,800009a0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b4:	00011497          	auipc	s1,0x11
    800009b8:	89448493          	addi	s1,s1,-1900 # 80011248 <uart_tx_lock>
    800009bc:	8526                	mv	a0,s1
    800009be:	00000097          	auipc	ra,0x0
    800009c2:	212080e7          	jalr	530(ra) # 80000bd0 <acquire>
  uartstart();
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	e6c080e7          	jalr	-404(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009ce:	8526                	mv	a0,s1
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	2b4080e7          	jalr	692(ra) # 80000c84 <release>
}
    800009d8:	60e2                	ld	ra,24(sp)
    800009da:	6442                	ld	s0,16(sp)
    800009dc:	64a2                	ld	s1,8(sp)
    800009de:	6105                	addi	sp,sp,32
    800009e0:	8082                	ret

00000000800009e2 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e2:	1101                	addi	sp,sp,-32
    800009e4:	ec06                	sd	ra,24(sp)
    800009e6:	e822                	sd	s0,16(sp)
    800009e8:	e426                	sd	s1,8(sp)
    800009ea:	e04a                	sd	s2,0(sp)
    800009ec:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009ee:	03451793          	slli	a5,a0,0x34
    800009f2:	ebb9                	bnez	a5,80000a48 <kfree+0x66>
    800009f4:	84aa                	mv	s1,a0
    800009f6:	00025797          	auipc	a5,0x25
    800009fa:	60a78793          	addi	a5,a5,1546 # 80026000 <end>
    800009fe:	04f56563          	bltu	a0,a5,80000a48 <kfree+0x66>
    80000a02:	47c5                	li	a5,17
    80000a04:	07ee                	slli	a5,a5,0x1b
    80000a06:	04f57163          	bgeu	a0,a5,80000a48 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0a:	6605                	lui	a2,0x1
    80000a0c:	4585                	li	a1,1
    80000a0e:	00000097          	auipc	ra,0x0
    80000a12:	2be080e7          	jalr	702(ra) # 80000ccc <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a16:	00011917          	auipc	s2,0x11
    80000a1a:	86a90913          	addi	s2,s2,-1942 # 80011280 <kmem>
    80000a1e:	854a                	mv	a0,s2
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	1b0080e7          	jalr	432(ra) # 80000bd0 <acquire>
  r->next = kmem.freelist;
    80000a28:	01893783          	ld	a5,24(s2)
    80000a2c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a2e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a32:	854a                	mv	a0,s2
    80000a34:	00000097          	auipc	ra,0x0
    80000a38:	250080e7          	jalr	592(ra) # 80000c84 <release>
}
    80000a3c:	60e2                	ld	ra,24(sp)
    80000a3e:	6442                	ld	s0,16(sp)
    80000a40:	64a2                	ld	s1,8(sp)
    80000a42:	6902                	ld	s2,0(sp)
    80000a44:	6105                	addi	sp,sp,32
    80000a46:	8082                	ret
    panic("kfree");
    80000a48:	00007517          	auipc	a0,0x7
    80000a4c:	61850513          	addi	a0,a0,1560 # 80008060 <digits+0x20>
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	aea080e7          	jalr	-1302(ra) # 8000053a <panic>

0000000080000a58 <freerange>:
{
    80000a58:	7179                	addi	sp,sp,-48
    80000a5a:	f406                	sd	ra,40(sp)
    80000a5c:	f022                	sd	s0,32(sp)
    80000a5e:	ec26                	sd	s1,24(sp)
    80000a60:	e84a                	sd	s2,16(sp)
    80000a62:	e44e                	sd	s3,8(sp)
    80000a64:	e052                	sd	s4,0(sp)
    80000a66:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a68:	6785                	lui	a5,0x1
    80000a6a:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a6e:	00e504b3          	add	s1,a0,a4
    80000a72:	777d                	lui	a4,0xfffff
    80000a74:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a76:	94be                	add	s1,s1,a5
    80000a78:	0095ee63          	bltu	a1,s1,80000a94 <freerange+0x3c>
    80000a7c:	892e                	mv	s2,a1
    kfree(p);
    80000a7e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	6985                	lui	s3,0x1
    kfree(p);
    80000a82:	01448533          	add	a0,s1,s4
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	f5c080e7          	jalr	-164(ra) # 800009e2 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8e:	94ce                	add	s1,s1,s3
    80000a90:	fe9979e3          	bgeu	s2,s1,80000a82 <freerange+0x2a>
}
    80000a94:	70a2                	ld	ra,40(sp)
    80000a96:	7402                	ld	s0,32(sp)
    80000a98:	64e2                	ld	s1,24(sp)
    80000a9a:	6942                	ld	s2,16(sp)
    80000a9c:	69a2                	ld	s3,8(sp)
    80000a9e:	6a02                	ld	s4,0(sp)
    80000aa0:	6145                	addi	sp,sp,48
    80000aa2:	8082                	ret

0000000080000aa4 <kinit>:
{
    80000aa4:	1141                	addi	sp,sp,-16
    80000aa6:	e406                	sd	ra,8(sp)
    80000aa8:	e022                	sd	s0,0(sp)
    80000aaa:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aac:	00007597          	auipc	a1,0x7
    80000ab0:	5bc58593          	addi	a1,a1,1468 # 80008068 <digits+0x28>
    80000ab4:	00010517          	auipc	a0,0x10
    80000ab8:	7cc50513          	addi	a0,a0,1996 # 80011280 <kmem>
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	084080e7          	jalr	132(ra) # 80000b40 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac4:	45c5                	li	a1,17
    80000ac6:	05ee                	slli	a1,a1,0x1b
    80000ac8:	00025517          	auipc	a0,0x25
    80000acc:	53850513          	addi	a0,a0,1336 # 80026000 <end>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	f88080e7          	jalr	-120(ra) # 80000a58 <freerange>
}
    80000ad8:	60a2                	ld	ra,8(sp)
    80000ada:	6402                	ld	s0,0(sp)
    80000adc:	0141                	addi	sp,sp,16
    80000ade:	8082                	ret

0000000080000ae0 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae0:	1101                	addi	sp,sp,-32
    80000ae2:	ec06                	sd	ra,24(sp)
    80000ae4:	e822                	sd	s0,16(sp)
    80000ae6:	e426                	sd	s1,8(sp)
    80000ae8:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aea:	00010497          	auipc	s1,0x10
    80000aee:	79648493          	addi	s1,s1,1942 # 80011280 <kmem>
    80000af2:	8526                	mv	a0,s1
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	0dc080e7          	jalr	220(ra) # 80000bd0 <acquire>
  r = kmem.freelist;
    80000afc:	6c84                	ld	s1,24(s1)
  if(r)
    80000afe:	c885                	beqz	s1,80000b2e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b00:	609c                	ld	a5,0(s1)
    80000b02:	00010517          	auipc	a0,0x10
    80000b06:	77e50513          	addi	a0,a0,1918 # 80011280 <kmem>
    80000b0a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	178080e7          	jalr	376(ra) # 80000c84 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b14:	6605                	lui	a2,0x1
    80000b16:	4595                	li	a1,5
    80000b18:	8526                	mv	a0,s1
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	1b2080e7          	jalr	434(ra) # 80000ccc <memset>
  return (void*)r;
}
    80000b22:	8526                	mv	a0,s1
    80000b24:	60e2                	ld	ra,24(sp)
    80000b26:	6442                	ld	s0,16(sp)
    80000b28:	64a2                	ld	s1,8(sp)
    80000b2a:	6105                	addi	sp,sp,32
    80000b2c:	8082                	ret
  release(&kmem.lock);
    80000b2e:	00010517          	auipc	a0,0x10
    80000b32:	75250513          	addi	a0,a0,1874 # 80011280 <kmem>
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	14e080e7          	jalr	334(ra) # 80000c84 <release>
  if(r)
    80000b3e:	b7d5                	j	80000b22 <kalloc+0x42>

0000000080000b40 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b40:	1141                	addi	sp,sp,-16
    80000b42:	e422                	sd	s0,8(sp)
    80000b44:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b46:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b48:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4c:	00053823          	sd	zero,16(a0)
}
    80000b50:	6422                	ld	s0,8(sp)
    80000b52:	0141                	addi	sp,sp,16
    80000b54:	8082                	ret

0000000080000b56 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b56:	411c                	lw	a5,0(a0)
    80000b58:	e399                	bnez	a5,80000b5e <holding+0x8>
    80000b5a:	4501                	li	a0,0
  return r;
}
    80000b5c:	8082                	ret
{
    80000b5e:	1101                	addi	sp,sp,-32
    80000b60:	ec06                	sd	ra,24(sp)
    80000b62:	e822                	sd	s0,16(sp)
    80000b64:	e426                	sd	s1,8(sp)
    80000b66:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b68:	6904                	ld	s1,16(a0)
    80000b6a:	00001097          	auipc	ra,0x1
    80000b6e:	0ca080e7          	jalr	202(ra) # 80001c34 <mycpu>
    80000b72:	40a48533          	sub	a0,s1,a0
    80000b76:	00153513          	seqz	a0,a0
}
    80000b7a:	60e2                	ld	ra,24(sp)
    80000b7c:	6442                	ld	s0,16(sp)
    80000b7e:	64a2                	ld	s1,8(sp)
    80000b80:	6105                	addi	sp,sp,32
    80000b82:	8082                	ret

0000000080000b84 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b84:	1101                	addi	sp,sp,-32
    80000b86:	ec06                	sd	ra,24(sp)
    80000b88:	e822                	sd	s0,16(sp)
    80000b8a:	e426                	sd	s1,8(sp)
    80000b8c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b8e:	100024f3          	csrr	s1,sstatus
    80000b92:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b96:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b98:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9c:	00001097          	auipc	ra,0x1
    80000ba0:	098080e7          	jalr	152(ra) # 80001c34 <mycpu>
    80000ba4:	5d3c                	lw	a5,120(a0)
    80000ba6:	cf89                	beqz	a5,80000bc0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ba8:	00001097          	auipc	ra,0x1
    80000bac:	08c080e7          	jalr	140(ra) # 80001c34 <mycpu>
    80000bb0:	5d3c                	lw	a5,120(a0)
    80000bb2:	2785                	addiw	a5,a5,1
    80000bb4:	dd3c                	sw	a5,120(a0)
}
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret
    mycpu()->intena = old;
    80000bc0:	00001097          	auipc	ra,0x1
    80000bc4:	074080e7          	jalr	116(ra) # 80001c34 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc8:	8085                	srli	s1,s1,0x1
    80000bca:	8885                	andi	s1,s1,1
    80000bcc:	dd64                	sw	s1,124(a0)
    80000bce:	bfe9                	j	80000ba8 <push_off+0x24>

0000000080000bd0 <acquire>:
{
    80000bd0:	1101                	addi	sp,sp,-32
    80000bd2:	ec06                	sd	ra,24(sp)
    80000bd4:	e822                	sd	s0,16(sp)
    80000bd6:	e426                	sd	s1,8(sp)
    80000bd8:	1000                	addi	s0,sp,32
    80000bda:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bdc:	00000097          	auipc	ra,0x0
    80000be0:	fa8080e7          	jalr	-88(ra) # 80000b84 <push_off>
  if(holding(lk))
    80000be4:	8526                	mv	a0,s1
    80000be6:	00000097          	auipc	ra,0x0
    80000bea:	f70080e7          	jalr	-144(ra) # 80000b56 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bee:	4705                	li	a4,1
  if(holding(lk))
    80000bf0:	e115                	bnez	a0,80000c14 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf2:	87ba                	mv	a5,a4
    80000bf4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bf8:	2781                	sext.w	a5,a5
    80000bfa:	ffe5                	bnez	a5,80000bf2 <acquire+0x22>
  __sync_synchronize();
    80000bfc:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	034080e7          	jalr	52(ra) # 80001c34 <mycpu>
    80000c08:	e888                	sd	a0,16(s1)
}
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	addi	sp,sp,32
    80000c12:	8082                	ret
    panic("acquire");
    80000c14:	00007517          	auipc	a0,0x7
    80000c18:	45c50513          	addi	a0,a0,1116 # 80008070 <digits+0x30>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	91e080e7          	jalr	-1762(ra) # 8000053a <panic>

0000000080000c24 <pop_off>:

void
pop_off(void)
{
    80000c24:	1141                	addi	sp,sp,-16
    80000c26:	e406                	sd	ra,8(sp)
    80000c28:	e022                	sd	s0,0(sp)
    80000c2a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	008080e7          	jalr	8(ra) # 80001c34 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c34:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c38:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3a:	e78d                	bnez	a5,80000c64 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3c:	5d3c                	lw	a5,120(a0)
    80000c3e:	02f05b63          	blez	a5,80000c74 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c42:	37fd                	addiw	a5,a5,-1
    80000c44:	0007871b          	sext.w	a4,a5
    80000c48:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4a:	eb09                	bnez	a4,80000c5c <pop_off+0x38>
    80000c4c:	5d7c                	lw	a5,124(a0)
    80000c4e:	c799                	beqz	a5,80000c5c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c54:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c58:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5c:	60a2                	ld	ra,8(sp)
    80000c5e:	6402                	ld	s0,0(sp)
    80000c60:	0141                	addi	sp,sp,16
    80000c62:	8082                	ret
    panic("pop_off - interruptible");
    80000c64:	00007517          	auipc	a0,0x7
    80000c68:	41450513          	addi	a0,a0,1044 # 80008078 <digits+0x38>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	8ce080e7          	jalr	-1842(ra) # 8000053a <panic>
    panic("pop_off");
    80000c74:	00007517          	auipc	a0,0x7
    80000c78:	41c50513          	addi	a0,a0,1052 # 80008090 <digits+0x50>
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	8be080e7          	jalr	-1858(ra) # 8000053a <panic>

0000000080000c84 <release>:
{
    80000c84:	1101                	addi	sp,sp,-32
    80000c86:	ec06                	sd	ra,24(sp)
    80000c88:	e822                	sd	s0,16(sp)
    80000c8a:	e426                	sd	s1,8(sp)
    80000c8c:	1000                	addi	s0,sp,32
    80000c8e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	ec6080e7          	jalr	-314(ra) # 80000b56 <holding>
    80000c98:	c115                	beqz	a0,80000cbc <release+0x38>
  lk->cpu = 0;
    80000c9a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c9e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca2:	0f50000f          	fence	iorw,ow
    80000ca6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	f7a080e7          	jalr	-134(ra) # 80000c24 <pop_off>
}
    80000cb2:	60e2                	ld	ra,24(sp)
    80000cb4:	6442                	ld	s0,16(sp)
    80000cb6:	64a2                	ld	s1,8(sp)
    80000cb8:	6105                	addi	sp,sp,32
    80000cba:	8082                	ret
    panic("release");
    80000cbc:	00007517          	auipc	a0,0x7
    80000cc0:	3dc50513          	addi	a0,a0,988 # 80008098 <digits+0x58>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	876080e7          	jalr	-1930(ra) # 8000053a <panic>

0000000080000ccc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ccc:	1141                	addi	sp,sp,-16
    80000cce:	e422                	sd	s0,8(sp)
    80000cd0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd2:	ca19                	beqz	a2,80000ce8 <memset+0x1c>
    80000cd4:	87aa                	mv	a5,a0
    80000cd6:	1602                	slli	a2,a2,0x20
    80000cd8:	9201                	srli	a2,a2,0x20
    80000cda:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cde:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce2:	0785                	addi	a5,a5,1
    80000ce4:	fee79de3          	bne	a5,a4,80000cde <memset+0x12>
  }
  return dst;
}
    80000ce8:	6422                	ld	s0,8(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret

0000000080000cee <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cee:	1141                	addi	sp,sp,-16
    80000cf0:	e422                	sd	s0,8(sp)
    80000cf2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf4:	ca05                	beqz	a2,80000d24 <memcmp+0x36>
    80000cf6:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cfa:	1682                	slli	a3,a3,0x20
    80000cfc:	9281                	srli	a3,a3,0x20
    80000cfe:	0685                	addi	a3,a3,1
    80000d00:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d02:	00054783          	lbu	a5,0(a0)
    80000d06:	0005c703          	lbu	a4,0(a1)
    80000d0a:	00e79863          	bne	a5,a4,80000d1a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d0e:	0505                	addi	a0,a0,1
    80000d10:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d12:	fed518e3          	bne	a0,a3,80000d02 <memcmp+0x14>
  }

  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	a019                	j	80000d1e <memcmp+0x30>
      return *s1 - *s2;
    80000d1a:	40e7853b          	subw	a0,a5,a4
}
    80000d1e:	6422                	ld	s0,8(sp)
    80000d20:	0141                	addi	sp,sp,16
    80000d22:	8082                	ret
  return 0;
    80000d24:	4501                	li	a0,0
    80000d26:	bfe5                	j	80000d1e <memcmp+0x30>

0000000080000d28 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d28:	1141                	addi	sp,sp,-16
    80000d2a:	e422                	sd	s0,8(sp)
    80000d2c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d2e:	c205                	beqz	a2,80000d4e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d30:	02a5e263          	bltu	a1,a0,80000d54 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d34:	1602                	slli	a2,a2,0x20
    80000d36:	9201                	srli	a2,a2,0x20
    80000d38:	00c587b3          	add	a5,a1,a2
{
    80000d3c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d3e:	0585                	addi	a1,a1,1
    80000d40:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd9001>
    80000d42:	fff5c683          	lbu	a3,-1(a1)
    80000d46:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4a:	fef59ae3          	bne	a1,a5,80000d3e <memmove+0x16>

  return dst;
}
    80000d4e:	6422                	ld	s0,8(sp)
    80000d50:	0141                	addi	sp,sp,16
    80000d52:	8082                	ret
  if(s < d && s + n > d){
    80000d54:	02061693          	slli	a3,a2,0x20
    80000d58:	9281                	srli	a3,a3,0x20
    80000d5a:	00d58733          	add	a4,a1,a3
    80000d5e:	fce57be3          	bgeu	a0,a4,80000d34 <memmove+0xc>
    d += n;
    80000d62:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d64:	fff6079b          	addiw	a5,a2,-1
    80000d68:	1782                	slli	a5,a5,0x20
    80000d6a:	9381                	srli	a5,a5,0x20
    80000d6c:	fff7c793          	not	a5,a5
    80000d70:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d72:	177d                	addi	a4,a4,-1
    80000d74:	16fd                	addi	a3,a3,-1
    80000d76:	00074603          	lbu	a2,0(a4)
    80000d7a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d7e:	fee79ae3          	bne	a5,a4,80000d72 <memmove+0x4a>
    80000d82:	b7f1                	j	80000d4e <memmove+0x26>

0000000080000d84 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d84:	1141                	addi	sp,sp,-16
    80000d86:	e406                	sd	ra,8(sp)
    80000d88:	e022                	sd	s0,0(sp)
    80000d8a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d8c:	00000097          	auipc	ra,0x0
    80000d90:	f9c080e7          	jalr	-100(ra) # 80000d28 <memmove>
}
    80000d94:	60a2                	ld	ra,8(sp)
    80000d96:	6402                	ld	s0,0(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret

0000000080000d9c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9c:	1141                	addi	sp,sp,-16
    80000d9e:	e422                	sd	s0,8(sp)
    80000da0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da2:	ce11                	beqz	a2,80000dbe <strncmp+0x22>
    80000da4:	00054783          	lbu	a5,0(a0)
    80000da8:	cf89                	beqz	a5,80000dc2 <strncmp+0x26>
    80000daa:	0005c703          	lbu	a4,0(a1)
    80000dae:	00f71a63          	bne	a4,a5,80000dc2 <strncmp+0x26>
    n--, p++, q++;
    80000db2:	367d                	addiw	a2,a2,-1
    80000db4:	0505                	addi	a0,a0,1
    80000db6:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db8:	f675                	bnez	a2,80000da4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dba:	4501                	li	a0,0
    80000dbc:	a809                	j	80000dce <strncmp+0x32>
    80000dbe:	4501                	li	a0,0
    80000dc0:	a039                	j	80000dce <strncmp+0x32>
  if(n == 0)
    80000dc2:	ca09                	beqz	a2,80000dd4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc4:	00054503          	lbu	a0,0(a0)
    80000dc8:	0005c783          	lbu	a5,0(a1)
    80000dcc:	9d1d                	subw	a0,a0,a5
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret
    return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	bfe5                	j	80000dce <strncmp+0x32>

0000000080000dd8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e422                	sd	s0,8(sp)
    80000ddc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dde:	872a                	mv	a4,a0
    80000de0:	8832                	mv	a6,a2
    80000de2:	367d                	addiw	a2,a2,-1
    80000de4:	01005963          	blez	a6,80000df6 <strncpy+0x1e>
    80000de8:	0705                	addi	a4,a4,1
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	fef70fa3          	sb	a5,-1(a4)
    80000df2:	0585                	addi	a1,a1,1
    80000df4:	f7f5                	bnez	a5,80000de0 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df6:	86ba                	mv	a3,a4
    80000df8:	00c05c63          	blez	a2,80000e10 <strncpy+0x38>
    *s++ = 0;
    80000dfc:	0685                	addi	a3,a3,1
    80000dfe:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e02:	40d707bb          	subw	a5,a4,a3
    80000e06:	37fd                	addiw	a5,a5,-1
    80000e08:	010787bb          	addw	a5,a5,a6
    80000e0c:	fef048e3          	bgtz	a5,80000dfc <strncpy+0x24>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addiw	a3,a2,-1
    80000e24:	1682                	slli	a3,a3,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	addi	a1,a1,1
    80000e32:	0785                	addi	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	addi	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	addi	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	4685                	li	a3,1
    80000e5a:	9e89                	subw	a3,a3,a0
    80000e5c:	00f6853b          	addw	a0,a3,a5
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	fff7c703          	lbu	a4,-1(a5)
    80000e66:	fb7d                	bnez	a4,80000e5c <strlen+0x14>
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	daa080e7          	jalr	-598(ra) # 80001c24 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	19670713          	addi	a4,a4,406 # 80009018 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	d8e080e7          	jalr	-626(ra) # 80001c24 <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	addi	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6dc080e7          	jalr	1756(ra) # 80000584 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00002097          	auipc	ra,0x2
    80000ebc:	d5c080e7          	jalr	-676(ra) # 80002c14 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	530080e7          	jalr	1328(ra) # 800063f0 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	2c8080e7          	jalr	712(ra) # 80002190 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57a080e7          	jalr	1402(ra) # 8000044a <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88c080e7          	jalr	-1908(ra) # 80000764 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	addi	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69c080e7          	jalr	1692(ra) # 80000584 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	addi	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68c080e7          	jalr	1676(ra) # 80000584 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	addi	a0,a0,456 # 800080c8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67c080e7          	jalr	1660(ra) # 80000584 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b94080e7          	jalr	-1132(ra) # 80000aa4 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	322080e7          	jalr	802(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	c44080e7          	jalr	-956(ra) # 80001b6c <procinit>
    trapinit();      // trap vectors
    80000f30:	00002097          	auipc	ra,0x2
    80000f34:	cbc080e7          	jalr	-836(ra) # 80002bec <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	cdc080e7          	jalr	-804(ra) # 80002c14 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	49a080e7          	jalr	1178(ra) # 800063da <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	4a8080e7          	jalr	1192(ra) # 800063f0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	668080e7          	jalr	1640(ra) # 800035b8 <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	cf6080e7          	jalr	-778(ra) # 80003c4e <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	ca8080e7          	jalr	-856(ra) # 80004c08 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	5a8080e7          	jalr	1448(ra) # 80006510 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	fcc080e7          	jalr	-52(ra) # 80001f3c <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	08f72d23          	sw	a5,154(a4) # 80009018 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f8e:	00008797          	auipc	a5,0x8
    80000f92:	0927b783          	ld	a5,146(a5) # 80009020 <kernel_pagetable>
    80000f96:	83b1                	srli	a5,a5,0xc
    80000f98:	577d                	li	a4,-1
    80000f9a:	177e                	slli	a4,a4,0x3f
    80000f9c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f9e:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fa2:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa6:	6422                	ld	s0,8(sp)
    80000fa8:	0141                	addi	sp,sp,16
    80000faa:	8082                	ret

0000000080000fac <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fac:	7139                	addi	sp,sp,-64
    80000fae:	fc06                	sd	ra,56(sp)
    80000fb0:	f822                	sd	s0,48(sp)
    80000fb2:	f426                	sd	s1,40(sp)
    80000fb4:	f04a                	sd	s2,32(sp)
    80000fb6:	ec4e                	sd	s3,24(sp)
    80000fb8:	e852                	sd	s4,16(sp)
    80000fba:	e456                	sd	s5,8(sp)
    80000fbc:	e05a                	sd	s6,0(sp)
    80000fbe:	0080                	addi	s0,sp,64
    80000fc0:	84aa                	mv	s1,a0
    80000fc2:	89ae                	mv	s3,a1
    80000fc4:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc6:	57fd                	li	a5,-1
    80000fc8:	83e9                	srli	a5,a5,0x1a
    80000fca:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fcc:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fce:	04b7f263          	bgeu	a5,a1,80001012 <walk+0x66>
    panic("walk");
    80000fd2:	00007517          	auipc	a0,0x7
    80000fd6:	0fe50513          	addi	a0,a0,254 # 800080d0 <digits+0x90>
    80000fda:	fffff097          	auipc	ra,0xfffff
    80000fde:	560080e7          	jalr	1376(ra) # 8000053a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe2:	060a8663          	beqz	s5,8000104e <walk+0xa2>
    80000fe6:	00000097          	auipc	ra,0x0
    80000fea:	afa080e7          	jalr	-1286(ra) # 80000ae0 <kalloc>
    80000fee:	84aa                	mv	s1,a0
    80000ff0:	c529                	beqz	a0,8000103a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff2:	6605                	lui	a2,0x1
    80000ff4:	4581                	li	a1,0
    80000ff6:	00000097          	auipc	ra,0x0
    80000ffa:	cd6080e7          	jalr	-810(ra) # 80000ccc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ffe:	00c4d793          	srli	a5,s1,0xc
    80001002:	07aa                	slli	a5,a5,0xa
    80001004:	0017e793          	ori	a5,a5,1
    80001008:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000100c:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd8ff7>
    8000100e:	036a0063          	beq	s4,s6,8000102e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001012:	0149d933          	srl	s2,s3,s4
    80001016:	1ff97913          	andi	s2,s2,511
    8000101a:	090e                	slli	s2,s2,0x3
    8000101c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000101e:	00093483          	ld	s1,0(s2)
    80001022:	0014f793          	andi	a5,s1,1
    80001026:	dfd5                	beqz	a5,80000fe2 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001028:	80a9                	srli	s1,s1,0xa
    8000102a:	04b2                	slli	s1,s1,0xc
    8000102c:	b7c5                	j	8000100c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000102e:	00c9d513          	srli	a0,s3,0xc
    80001032:	1ff57513          	andi	a0,a0,511
    80001036:	050e                	slli	a0,a0,0x3
    80001038:	9526                	add	a0,a0,s1
}
    8000103a:	70e2                	ld	ra,56(sp)
    8000103c:	7442                	ld	s0,48(sp)
    8000103e:	74a2                	ld	s1,40(sp)
    80001040:	7902                	ld	s2,32(sp)
    80001042:	69e2                	ld	s3,24(sp)
    80001044:	6a42                	ld	s4,16(sp)
    80001046:	6aa2                	ld	s5,8(sp)
    80001048:	6b02                	ld	s6,0(sp)
    8000104a:	6121                	addi	sp,sp,64
    8000104c:	8082                	ret
        return 0;
    8000104e:	4501                	li	a0,0
    80001050:	b7ed                	j	8000103a <walk+0x8e>

0000000080001052 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001052:	57fd                	li	a5,-1
    80001054:	83e9                	srli	a5,a5,0x1a
    80001056:	00b7f463          	bgeu	a5,a1,8000105e <walkaddr+0xc>
    return 0;
    8000105a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000105c:	8082                	ret
{
    8000105e:	1141                	addi	sp,sp,-16
    80001060:	e406                	sd	ra,8(sp)
    80001062:	e022                	sd	s0,0(sp)
    80001064:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001066:	4601                	li	a2,0
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	f44080e7          	jalr	-188(ra) # 80000fac <walk>
  if(pte == 0)
    80001070:	c105                	beqz	a0,80001090 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001072:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001074:	0117f693          	andi	a3,a5,17
    80001078:	4745                	li	a4,17
    return 0;
    8000107a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000107c:	00e68663          	beq	a3,a4,80001088 <walkaddr+0x36>
}
    80001080:	60a2                	ld	ra,8(sp)
    80001082:	6402                	ld	s0,0(sp)
    80001084:	0141                	addi	sp,sp,16
    80001086:	8082                	ret
  pa = PTE2PA(*pte);
    80001088:	83a9                	srli	a5,a5,0xa
    8000108a:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000108e:	bfcd                	j	80001080 <walkaddr+0x2e>
    return 0;
    80001090:	4501                	li	a0,0
    80001092:	b7fd                	j	80001080 <walkaddr+0x2e>

0000000080001094 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001094:	715d                	addi	sp,sp,-80
    80001096:	e486                	sd	ra,72(sp)
    80001098:	e0a2                	sd	s0,64(sp)
    8000109a:	fc26                	sd	s1,56(sp)
    8000109c:	f84a                	sd	s2,48(sp)
    8000109e:	f44e                	sd	s3,40(sp)
    800010a0:	f052                	sd	s4,32(sp)
    800010a2:	ec56                	sd	s5,24(sp)
    800010a4:	e85a                	sd	s6,16(sp)
    800010a6:	e45e                	sd	s7,8(sp)
    800010a8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010aa:	c639                	beqz	a2,800010f8 <mappages+0x64>
    800010ac:	8aaa                	mv	s5,a0
    800010ae:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b0:	777d                	lui	a4,0xfffff
    800010b2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010b6:	fff58993          	addi	s3,a1,-1
    800010ba:	99b2                	add	s3,s3,a2
    800010bc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c0:	893e                	mv	s2,a5
    800010c2:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010c6:	6b85                	lui	s7,0x1
    800010c8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010cc:	4605                	li	a2,1
    800010ce:	85ca                	mv	a1,s2
    800010d0:	8556                	mv	a0,s5
    800010d2:	00000097          	auipc	ra,0x0
    800010d6:	eda080e7          	jalr	-294(ra) # 80000fac <walk>
    800010da:	cd1d                	beqz	a0,80001118 <mappages+0x84>
    if(*pte & PTE_V)
    800010dc:	611c                	ld	a5,0(a0)
    800010de:	8b85                	andi	a5,a5,1
    800010e0:	e785                	bnez	a5,80001108 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e2:	80b1                	srli	s1,s1,0xc
    800010e4:	04aa                	slli	s1,s1,0xa
    800010e6:	0164e4b3          	or	s1,s1,s6
    800010ea:	0014e493          	ori	s1,s1,1
    800010ee:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f0:	05390063          	beq	s2,s3,80001130 <mappages+0x9c>
    a += PGSIZE;
    800010f4:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f6:	bfc9                	j	800010c8 <mappages+0x34>
    panic("mappages: size");
    800010f8:	00007517          	auipc	a0,0x7
    800010fc:	fe050513          	addi	a0,a0,-32 # 800080d8 <digits+0x98>
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	43a080e7          	jalr	1082(ra) # 8000053a <panic>
      panic("mappages: remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fe050513          	addi	a0,a0,-32 # 800080e8 <digits+0xa8>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	42a080e7          	jalr	1066(ra) # 8000053a <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x86>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f52080e7          	jalr	-174(ra) # 80001094 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	fa450513          	addi	a0,a0,-92 # 800080f8 <digits+0xb8>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3de080e7          	jalr	990(ra) # 8000053a <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	970080e7          	jalr	-1680(ra) # 80000ae0 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b4e080e7          	jalr	-1202(ra) # 80000ccc <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00001097          	auipc	ra,0x1
    80001228:	8b2080e7          	jalr	-1870(ra) # 80001ad6 <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6b05                	lui	s6,0x1
    80001286:	0735e263          	bltu	a1,s3,800012ea <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e6050513          	addi	a0,a0,-416 # 80008100 <digits+0xc0>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	292080e7          	jalr	658(ra) # 8000053a <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e6850513          	addi	a0,a0,-408 # 80008118 <digits+0xd8>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	282080e7          	jalr	642(ra) # 8000053a <panic>
      panic("uvmunmap: not mapped");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e6850513          	addi	a0,a0,-408 # 80008128 <digits+0xe8>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	272080e7          	jalr	626(ra) # 8000053a <panic>
      panic("uvmunmap: not a leaf");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e7050513          	addi	a0,a0,-400 # 80008140 <digits+0x100>
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	262080e7          	jalr	610(ra) # 8000053a <panic>
    *pte = 0;
    800012e0:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e4:	995a                	add	s2,s2,s6
    800012e6:	fb3972e3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ea:	4601                	li	a2,0
    800012ec:	85ca                	mv	a1,s2
    800012ee:	8552                	mv	a0,s4
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	cbc080e7          	jalr	-836(ra) # 80000fac <walk>
    800012f8:	84aa                	mv	s1,a0
    800012fa:	d95d                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012fc:	6108                	ld	a0,0(a0)
    800012fe:	00157793          	andi	a5,a0,1
    80001302:	dfdd                	beqz	a5,800012c0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	3ff57793          	andi	a5,a0,1023
    80001308:	fd7784e3          	beq	a5,s7,800012d0 <uvmunmap+0x76>
    if(do_free){
    8000130c:	fc0a8ae3          	beqz	s5,800012e0 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001310:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001312:	0532                	slli	a0,a0,0xc
    80001314:	fffff097          	auipc	ra,0xfffff
    80001318:	6ce080e7          	jalr	1742(ra) # 800009e2 <kfree>
    8000131c:	b7d1                	j	800012e0 <uvmunmap+0x86>

000000008000131e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000131e:	1101                	addi	sp,sp,-32
    80001320:	ec06                	sd	ra,24(sp)
    80001322:	e822                	sd	s0,16(sp)
    80001324:	e426                	sd	s1,8(sp)
    80001326:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	7b8080e7          	jalr	1976(ra) # 80000ae0 <kalloc>
    80001330:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001332:	c519                	beqz	a0,80001340 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001334:	6605                	lui	a2,0x1
    80001336:	4581                	li	a1,0
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	994080e7          	jalr	-1644(ra) # 80000ccc <memset>
  return pagetable;
}
    80001340:	8526                	mv	a0,s1
    80001342:	60e2                	ld	ra,24(sp)
    80001344:	6442                	ld	s0,16(sp)
    80001346:	64a2                	ld	s1,8(sp)
    80001348:	6105                	addi	sp,sp,32
    8000134a:	8082                	ret

000000008000134c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000134c:	7179                	addi	sp,sp,-48
    8000134e:	f406                	sd	ra,40(sp)
    80001350:	f022                	sd	s0,32(sp)
    80001352:	ec26                	sd	s1,24(sp)
    80001354:	e84a                	sd	s2,16(sp)
    80001356:	e44e                	sd	s3,8(sp)
    80001358:	e052                	sd	s4,0(sp)
    8000135a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000135c:	6785                	lui	a5,0x1
    8000135e:	04f67863          	bgeu	a2,a5,800013ae <uvminit+0x62>
    80001362:	8a2a                	mv	s4,a0
    80001364:	89ae                	mv	s3,a1
    80001366:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	778080e7          	jalr	1912(ra) # 80000ae0 <kalloc>
    80001370:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001372:	6605                	lui	a2,0x1
    80001374:	4581                	li	a1,0
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	956080e7          	jalr	-1706(ra) # 80000ccc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000137e:	4779                	li	a4,30
    80001380:	86ca                	mv	a3,s2
    80001382:	6605                	lui	a2,0x1
    80001384:	4581                	li	a1,0
    80001386:	8552                	mv	a0,s4
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	d0c080e7          	jalr	-756(ra) # 80001094 <mappages>
  memmove(mem, src, sz);
    80001390:	8626                	mv	a2,s1
    80001392:	85ce                	mv	a1,s3
    80001394:	854a                	mv	a0,s2
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	992080e7          	jalr	-1646(ra) # 80000d28 <memmove>
}
    8000139e:	70a2                	ld	ra,40(sp)
    800013a0:	7402                	ld	s0,32(sp)
    800013a2:	64e2                	ld	s1,24(sp)
    800013a4:	6942                	ld	s2,16(sp)
    800013a6:	69a2                	ld	s3,8(sp)
    800013a8:	6a02                	ld	s4,0(sp)
    800013aa:	6145                	addi	sp,sp,48
    800013ac:	8082                	ret
    panic("inituvm: more than a page");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	daa50513          	addi	a0,a0,-598 # 80008158 <digits+0x118>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	184080e7          	jalr	388(ra) # 8000053a <panic>

00000000800013be <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013be:	1101                	addi	sp,sp,-32
    800013c0:	ec06                	sd	ra,24(sp)
    800013c2:	e822                	sd	s0,16(sp)
    800013c4:	e426                	sd	s1,8(sp)
    800013c6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013c8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ca:	00b67d63          	bgeu	a2,a1,800013e4 <uvmdealloc+0x26>
    800013ce:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d0:	6785                	lui	a5,0x1
    800013d2:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013d4:	00f60733          	add	a4,a2,a5
    800013d8:	76fd                	lui	a3,0xfffff
    800013da:	8f75                	and	a4,a4,a3
    800013dc:	97ae                	add	a5,a5,a1
    800013de:	8ff5                	and	a5,a5,a3
    800013e0:	00f76863          	bltu	a4,a5,800013f0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e4:	8526                	mv	a0,s1
    800013e6:	60e2                	ld	ra,24(sp)
    800013e8:	6442                	ld	s0,16(sp)
    800013ea:	64a2                	ld	s1,8(sp)
    800013ec:	6105                	addi	sp,sp,32
    800013ee:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f0:	8f99                	sub	a5,a5,a4
    800013f2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f4:	4685                	li	a3,1
    800013f6:	0007861b          	sext.w	a2,a5
    800013fa:	85ba                	mv	a1,a4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	e5e080e7          	jalr	-418(ra) # 8000125a <uvmunmap>
    80001404:	b7c5                	j	800013e4 <uvmdealloc+0x26>

0000000080001406 <uvmalloc>:
  if(newsz < oldsz)
    80001406:	0ab66163          	bltu	a2,a1,800014a8 <uvmalloc+0xa2>
{
    8000140a:	7139                	addi	sp,sp,-64
    8000140c:	fc06                	sd	ra,56(sp)
    8000140e:	f822                	sd	s0,48(sp)
    80001410:	f426                	sd	s1,40(sp)
    80001412:	f04a                	sd	s2,32(sp)
    80001414:	ec4e                	sd	s3,24(sp)
    80001416:	e852                	sd	s4,16(sp)
    80001418:	e456                	sd	s5,8(sp)
    8000141a:	0080                	addi	s0,sp,64
    8000141c:	8aaa                	mv	s5,a0
    8000141e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001420:	6785                	lui	a5,0x1
    80001422:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001424:	95be                	add	a1,a1,a5
    80001426:	77fd                	lui	a5,0xfffff
    80001428:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000142c:	08c9f063          	bgeu	s3,a2,800014ac <uvmalloc+0xa6>
    80001430:	894e                	mv	s2,s3
    mem = kalloc();
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	6ae080e7          	jalr	1710(ra) # 80000ae0 <kalloc>
    8000143a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000143c:	c51d                	beqz	a0,8000146a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000143e:	6605                	lui	a2,0x1
    80001440:	4581                	li	a1,0
    80001442:	00000097          	auipc	ra,0x0
    80001446:	88a080e7          	jalr	-1910(ra) # 80000ccc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000144a:	4779                	li	a4,30
    8000144c:	86a6                	mv	a3,s1
    8000144e:	6605                	lui	a2,0x1
    80001450:	85ca                	mv	a1,s2
    80001452:	8556                	mv	a0,s5
    80001454:	00000097          	auipc	ra,0x0
    80001458:	c40080e7          	jalr	-960(ra) # 80001094 <mappages>
    8000145c:	e905                	bnez	a0,8000148c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145e:	6785                	lui	a5,0x1
    80001460:	993e                	add	s2,s2,a5
    80001462:	fd4968e3          	bltu	s2,s4,80001432 <uvmalloc+0x2c>
  return newsz;
    80001466:	8552                	mv	a0,s4
    80001468:	a809                	j	8000147a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000146a:	864e                	mv	a2,s3
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	f4e080e7          	jalr	-178(ra) # 800013be <uvmdealloc>
      return 0;
    80001478:	4501                	li	a0,0
}
    8000147a:	70e2                	ld	ra,56(sp)
    8000147c:	7442                	ld	s0,48(sp)
    8000147e:	74a2                	ld	s1,40(sp)
    80001480:	7902                	ld	s2,32(sp)
    80001482:	69e2                	ld	s3,24(sp)
    80001484:	6a42                	ld	s4,16(sp)
    80001486:	6aa2                	ld	s5,8(sp)
    80001488:	6121                	addi	sp,sp,64
    8000148a:	8082                	ret
      kfree(mem);
    8000148c:	8526                	mv	a0,s1
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	554080e7          	jalr	1364(ra) # 800009e2 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f22080e7          	jalr	-222(ra) # 800013be <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
    800014a6:	bfd1                	j	8000147a <uvmalloc+0x74>
    return oldsz;
    800014a8:	852e                	mv	a0,a1
}
    800014aa:	8082                	ret
  return newsz;
    800014ac:	8532                	mv	a0,a2
    800014ae:	b7f1                	j	8000147a <uvmalloc+0x74>

00000000800014b0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014b0:	7179                	addi	sp,sp,-48
    800014b2:	f406                	sd	ra,40(sp)
    800014b4:	f022                	sd	s0,32(sp)
    800014b6:	ec26                	sd	s1,24(sp)
    800014b8:	e84a                	sd	s2,16(sp)
    800014ba:	e44e                	sd	s3,8(sp)
    800014bc:	e052                	sd	s4,0(sp)
    800014be:	1800                	addi	s0,sp,48
    800014c0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014c2:	84aa                	mv	s1,a0
    800014c4:	6905                	lui	s2,0x1
    800014c6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c8:	4985                	li	s3,1
    800014ca:	a829                	j	800014e4 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014cc:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014ce:	00c79513          	slli	a0,a5,0xc
    800014d2:	00000097          	auipc	ra,0x0
    800014d6:	fde080e7          	jalr	-34(ra) # 800014b0 <freewalk>
      pagetable[i] = 0;
    800014da:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014de:	04a1                	addi	s1,s1,8
    800014e0:	03248163          	beq	s1,s2,80001502 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014e4:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e6:	00f7f713          	andi	a4,a5,15
    800014ea:	ff3701e3          	beq	a4,s3,800014cc <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014ee:	8b85                	andi	a5,a5,1
    800014f0:	d7fd                	beqz	a5,800014de <freewalk+0x2e>
      panic("freewalk: leaf");
    800014f2:	00007517          	auipc	a0,0x7
    800014f6:	c8650513          	addi	a0,a0,-890 # 80008178 <digits+0x138>
    800014fa:	fffff097          	auipc	ra,0xfffff
    800014fe:	040080e7          	jalr	64(ra) # 8000053a <panic>
    }
  }
  kfree((void*)pagetable);
    80001502:	8552                	mv	a0,s4
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	4de080e7          	jalr	1246(ra) # 800009e2 <kfree>
}
    8000150c:	70a2                	ld	ra,40(sp)
    8000150e:	7402                	ld	s0,32(sp)
    80001510:	64e2                	ld	s1,24(sp)
    80001512:	6942                	ld	s2,16(sp)
    80001514:	69a2                	ld	s3,8(sp)
    80001516:	6a02                	ld	s4,0(sp)
    80001518:	6145                	addi	sp,sp,48
    8000151a:	8082                	ret

000000008000151c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000151c:	1101                	addi	sp,sp,-32
    8000151e:	ec06                	sd	ra,24(sp)
    80001520:	e822                	sd	s0,16(sp)
    80001522:	e426                	sd	s1,8(sp)
    80001524:	1000                	addi	s0,sp,32
    80001526:	84aa                	mv	s1,a0
  if(sz > 0)
    80001528:	e999                	bnez	a1,8000153e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000152a:	8526                	mv	a0,s1
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	f84080e7          	jalr	-124(ra) # 800014b0 <freewalk>
}
    80001534:	60e2                	ld	ra,24(sp)
    80001536:	6442                	ld	s0,16(sp)
    80001538:	64a2                	ld	s1,8(sp)
    8000153a:	6105                	addi	sp,sp,32
    8000153c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000153e:	6785                	lui	a5,0x1
    80001540:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001542:	95be                	add	a1,a1,a5
    80001544:	4685                	li	a3,1
    80001546:	00c5d613          	srli	a2,a1,0xc
    8000154a:	4581                	li	a1,0
    8000154c:	00000097          	auipc	ra,0x0
    80001550:	d0e080e7          	jalr	-754(ra) # 8000125a <uvmunmap>
    80001554:	bfd9                	j	8000152a <uvmfree+0xe>

0000000080001556 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001556:	c679                	beqz	a2,80001624 <uvmcopy+0xce>
{
    80001558:	715d                	addi	sp,sp,-80
    8000155a:	e486                	sd	ra,72(sp)
    8000155c:	e0a2                	sd	s0,64(sp)
    8000155e:	fc26                	sd	s1,56(sp)
    80001560:	f84a                	sd	s2,48(sp)
    80001562:	f44e                	sd	s3,40(sp)
    80001564:	f052                	sd	s4,32(sp)
    80001566:	ec56                	sd	s5,24(sp)
    80001568:	e85a                	sd	s6,16(sp)
    8000156a:	e45e                	sd	s7,8(sp)
    8000156c:	0880                	addi	s0,sp,80
    8000156e:	8b2a                	mv	s6,a0
    80001570:	8aae                	mv	s5,a1
    80001572:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001574:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001576:	4601                	li	a2,0
    80001578:	85ce                	mv	a1,s3
    8000157a:	855a                	mv	a0,s6
    8000157c:	00000097          	auipc	ra,0x0
    80001580:	a30080e7          	jalr	-1488(ra) # 80000fac <walk>
    80001584:	c531                	beqz	a0,800015d0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001586:	6118                	ld	a4,0(a0)
    80001588:	00177793          	andi	a5,a4,1
    8000158c:	cbb1                	beqz	a5,800015e0 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000158e:	00a75593          	srli	a1,a4,0xa
    80001592:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001596:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000159a:	fffff097          	auipc	ra,0xfffff
    8000159e:	546080e7          	jalr	1350(ra) # 80000ae0 <kalloc>
    800015a2:	892a                	mv	s2,a0
    800015a4:	c939                	beqz	a0,800015fa <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015a6:	6605                	lui	a2,0x1
    800015a8:	85de                	mv	a1,s7
    800015aa:	fffff097          	auipc	ra,0xfffff
    800015ae:	77e080e7          	jalr	1918(ra) # 80000d28 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015b2:	8726                	mv	a4,s1
    800015b4:	86ca                	mv	a3,s2
    800015b6:	6605                	lui	a2,0x1
    800015b8:	85ce                	mv	a1,s3
    800015ba:	8556                	mv	a0,s5
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	ad8080e7          	jalr	-1320(ra) # 80001094 <mappages>
    800015c4:	e515                	bnez	a0,800015f0 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015c6:	6785                	lui	a5,0x1
    800015c8:	99be                	add	s3,s3,a5
    800015ca:	fb49e6e3          	bltu	s3,s4,80001576 <uvmcopy+0x20>
    800015ce:	a081                	j	8000160e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015d0:	00007517          	auipc	a0,0x7
    800015d4:	bb850513          	addi	a0,a0,-1096 # 80008188 <digits+0x148>
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	f62080e7          	jalr	-158(ra) # 8000053a <panic>
      panic("uvmcopy: page not present");
    800015e0:	00007517          	auipc	a0,0x7
    800015e4:	bc850513          	addi	a0,a0,-1080 # 800081a8 <digits+0x168>
    800015e8:	fffff097          	auipc	ra,0xfffff
    800015ec:	f52080e7          	jalr	-174(ra) # 8000053a <panic>
      kfree(mem);
    800015f0:	854a                	mv	a0,s2
    800015f2:	fffff097          	auipc	ra,0xfffff
    800015f6:	3f0080e7          	jalr	1008(ra) # 800009e2 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015fa:	4685                	li	a3,1
    800015fc:	00c9d613          	srli	a2,s3,0xc
    80001600:	4581                	li	a1,0
    80001602:	8556                	mv	a0,s5
    80001604:	00000097          	auipc	ra,0x0
    80001608:	c56080e7          	jalr	-938(ra) # 8000125a <uvmunmap>
  return -1;
    8000160c:	557d                	li	a0,-1
}
    8000160e:	60a6                	ld	ra,72(sp)
    80001610:	6406                	ld	s0,64(sp)
    80001612:	74e2                	ld	s1,56(sp)
    80001614:	7942                	ld	s2,48(sp)
    80001616:	79a2                	ld	s3,40(sp)
    80001618:	7a02                	ld	s4,32(sp)
    8000161a:	6ae2                	ld	s5,24(sp)
    8000161c:	6b42                	ld	s6,16(sp)
    8000161e:	6ba2                	ld	s7,8(sp)
    80001620:	6161                	addi	sp,sp,80
    80001622:	8082                	ret
  return 0;
    80001624:	4501                	li	a0,0
}
    80001626:	8082                	ret

0000000080001628 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001628:	1141                	addi	sp,sp,-16
    8000162a:	e406                	sd	ra,8(sp)
    8000162c:	e022                	sd	s0,0(sp)
    8000162e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001630:	4601                	li	a2,0
    80001632:	00000097          	auipc	ra,0x0
    80001636:	97a080e7          	jalr	-1670(ra) # 80000fac <walk>
  if(pte == 0)
    8000163a:	c901                	beqz	a0,8000164a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000163c:	611c                	ld	a5,0(a0)
    8000163e:	9bbd                	andi	a5,a5,-17
    80001640:	e11c                	sd	a5,0(a0)
}
    80001642:	60a2                	ld	ra,8(sp)
    80001644:	6402                	ld	s0,0(sp)
    80001646:	0141                	addi	sp,sp,16
    80001648:	8082                	ret
    panic("uvmclear");
    8000164a:	00007517          	auipc	a0,0x7
    8000164e:	b7e50513          	addi	a0,a0,-1154 # 800081c8 <digits+0x188>
    80001652:	fffff097          	auipc	ra,0xfffff
    80001656:	ee8080e7          	jalr	-280(ra) # 8000053a <panic>

000000008000165a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000165a:	c6bd                	beqz	a3,800016c8 <copyout+0x6e>
{
    8000165c:	715d                	addi	sp,sp,-80
    8000165e:	e486                	sd	ra,72(sp)
    80001660:	e0a2                	sd	s0,64(sp)
    80001662:	fc26                	sd	s1,56(sp)
    80001664:	f84a                	sd	s2,48(sp)
    80001666:	f44e                	sd	s3,40(sp)
    80001668:	f052                	sd	s4,32(sp)
    8000166a:	ec56                	sd	s5,24(sp)
    8000166c:	e85a                	sd	s6,16(sp)
    8000166e:	e45e                	sd	s7,8(sp)
    80001670:	e062                	sd	s8,0(sp)
    80001672:	0880                	addi	s0,sp,80
    80001674:	8b2a                	mv	s6,a0
    80001676:	8c2e                	mv	s8,a1
    80001678:	8a32                	mv	s4,a2
    8000167a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000167c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000167e:	6a85                	lui	s5,0x1
    80001680:	a015                	j	800016a4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001682:	9562                	add	a0,a0,s8
    80001684:	0004861b          	sext.w	a2,s1
    80001688:	85d2                	mv	a1,s4
    8000168a:	41250533          	sub	a0,a0,s2
    8000168e:	fffff097          	auipc	ra,0xfffff
    80001692:	69a080e7          	jalr	1690(ra) # 80000d28 <memmove>

    len -= n;
    80001696:	409989b3          	sub	s3,s3,s1
    src += n;
    8000169a:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000169c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016a0:	02098263          	beqz	s3,800016c4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016a4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016a8:	85ca                	mv	a1,s2
    800016aa:	855a                	mv	a0,s6
    800016ac:	00000097          	auipc	ra,0x0
    800016b0:	9a6080e7          	jalr	-1626(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800016b4:	cd01                	beqz	a0,800016cc <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016b6:	418904b3          	sub	s1,s2,s8
    800016ba:	94d6                	add	s1,s1,s5
    800016bc:	fc99f3e3          	bgeu	s3,s1,80001682 <copyout+0x28>
    800016c0:	84ce                	mv	s1,s3
    800016c2:	b7c1                	j	80001682 <copyout+0x28>
  }
  return 0;
    800016c4:	4501                	li	a0,0
    800016c6:	a021                	j	800016ce <copyout+0x74>
    800016c8:	4501                	li	a0,0
}
    800016ca:	8082                	ret
      return -1;
    800016cc:	557d                	li	a0,-1
}
    800016ce:	60a6                	ld	ra,72(sp)
    800016d0:	6406                	ld	s0,64(sp)
    800016d2:	74e2                	ld	s1,56(sp)
    800016d4:	7942                	ld	s2,48(sp)
    800016d6:	79a2                	ld	s3,40(sp)
    800016d8:	7a02                	ld	s4,32(sp)
    800016da:	6ae2                	ld	s5,24(sp)
    800016dc:	6b42                	ld	s6,16(sp)
    800016de:	6ba2                	ld	s7,8(sp)
    800016e0:	6c02                	ld	s8,0(sp)
    800016e2:	6161                	addi	sp,sp,80
    800016e4:	8082                	ret

00000000800016e6 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e6:	caa5                	beqz	a3,80001756 <copyin+0x70>
{
    800016e8:	715d                	addi	sp,sp,-80
    800016ea:	e486                	sd	ra,72(sp)
    800016ec:	e0a2                	sd	s0,64(sp)
    800016ee:	fc26                	sd	s1,56(sp)
    800016f0:	f84a                	sd	s2,48(sp)
    800016f2:	f44e                	sd	s3,40(sp)
    800016f4:	f052                	sd	s4,32(sp)
    800016f6:	ec56                	sd	s5,24(sp)
    800016f8:	e85a                	sd	s6,16(sp)
    800016fa:	e45e                	sd	s7,8(sp)
    800016fc:	e062                	sd	s8,0(sp)
    800016fe:	0880                	addi	s0,sp,80
    80001700:	8b2a                	mv	s6,a0
    80001702:	8a2e                	mv	s4,a1
    80001704:	8c32                	mv	s8,a2
    80001706:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001708:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000170a:	6a85                	lui	s5,0x1
    8000170c:	a01d                	j	80001732 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000170e:	018505b3          	add	a1,a0,s8
    80001712:	0004861b          	sext.w	a2,s1
    80001716:	412585b3          	sub	a1,a1,s2
    8000171a:	8552                	mv	a0,s4
    8000171c:	fffff097          	auipc	ra,0xfffff
    80001720:	60c080e7          	jalr	1548(ra) # 80000d28 <memmove>

    len -= n;
    80001724:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001728:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000172a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172e:	02098263          	beqz	s3,80001752 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001732:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001736:	85ca                	mv	a1,s2
    80001738:	855a                	mv	a0,s6
    8000173a:	00000097          	auipc	ra,0x0
    8000173e:	918080e7          	jalr	-1768(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    80001742:	cd01                	beqz	a0,8000175a <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001744:	418904b3          	sub	s1,s2,s8
    80001748:	94d6                	add	s1,s1,s5
    8000174a:	fc99f2e3          	bgeu	s3,s1,8000170e <copyin+0x28>
    8000174e:	84ce                	mv	s1,s3
    80001750:	bf7d                	j	8000170e <copyin+0x28>
  }
  return 0;
    80001752:	4501                	li	a0,0
    80001754:	a021                	j	8000175c <copyin+0x76>
    80001756:	4501                	li	a0,0
}
    80001758:	8082                	ret
      return -1;
    8000175a:	557d                	li	a0,-1
}
    8000175c:	60a6                	ld	ra,72(sp)
    8000175e:	6406                	ld	s0,64(sp)
    80001760:	74e2                	ld	s1,56(sp)
    80001762:	7942                	ld	s2,48(sp)
    80001764:	79a2                	ld	s3,40(sp)
    80001766:	7a02                	ld	s4,32(sp)
    80001768:	6ae2                	ld	s5,24(sp)
    8000176a:	6b42                	ld	s6,16(sp)
    8000176c:	6ba2                	ld	s7,8(sp)
    8000176e:	6c02                	ld	s8,0(sp)
    80001770:	6161                	addi	sp,sp,80
    80001772:	8082                	ret

0000000080001774 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001774:	c2dd                	beqz	a3,8000181a <copyinstr+0xa6>
{
    80001776:	715d                	addi	sp,sp,-80
    80001778:	e486                	sd	ra,72(sp)
    8000177a:	e0a2                	sd	s0,64(sp)
    8000177c:	fc26                	sd	s1,56(sp)
    8000177e:	f84a                	sd	s2,48(sp)
    80001780:	f44e                	sd	s3,40(sp)
    80001782:	f052                	sd	s4,32(sp)
    80001784:	ec56                	sd	s5,24(sp)
    80001786:	e85a                	sd	s6,16(sp)
    80001788:	e45e                	sd	s7,8(sp)
    8000178a:	0880                	addi	s0,sp,80
    8000178c:	8a2a                	mv	s4,a0
    8000178e:	8b2e                	mv	s6,a1
    80001790:	8bb2                	mv	s7,a2
    80001792:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001794:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001796:	6985                	lui	s3,0x1
    80001798:	a02d                	j	800017c2 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000179a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000179e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017a0:	37fd                	addiw	a5,a5,-1
    800017a2:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017a6:	60a6                	ld	ra,72(sp)
    800017a8:	6406                	ld	s0,64(sp)
    800017aa:	74e2                	ld	s1,56(sp)
    800017ac:	7942                	ld	s2,48(sp)
    800017ae:	79a2                	ld	s3,40(sp)
    800017b0:	7a02                	ld	s4,32(sp)
    800017b2:	6ae2                	ld	s5,24(sp)
    800017b4:	6b42                	ld	s6,16(sp)
    800017b6:	6ba2                	ld	s7,8(sp)
    800017b8:	6161                	addi	sp,sp,80
    800017ba:	8082                	ret
    srcva = va0 + PGSIZE;
    800017bc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017c0:	c8a9                	beqz	s1,80001812 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017c2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017c6:	85ca                	mv	a1,s2
    800017c8:	8552                	mv	a0,s4
    800017ca:	00000097          	auipc	ra,0x0
    800017ce:	888080e7          	jalr	-1912(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800017d2:	c131                	beqz	a0,80001816 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017d4:	417906b3          	sub	a3,s2,s7
    800017d8:	96ce                	add	a3,a3,s3
    800017da:	00d4f363          	bgeu	s1,a3,800017e0 <copyinstr+0x6c>
    800017de:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017e0:	955e                	add	a0,a0,s7
    800017e2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017e6:	daf9                	beqz	a3,800017bc <copyinstr+0x48>
    800017e8:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017ea:	41650633          	sub	a2,a0,s6
    800017ee:	fff48593          	addi	a1,s1,-1
    800017f2:	95da                	add	a1,a1,s6
    while(n > 0){
    800017f4:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800017f6:	00f60733          	add	a4,a2,a5
    800017fa:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800017fe:	df51                	beqz	a4,8000179a <copyinstr+0x26>
        *dst = *p;
    80001800:	00e78023          	sb	a4,0(a5)
      --max;
    80001804:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001808:	0785                	addi	a5,a5,1
    while(n > 0){
    8000180a:	fed796e3          	bne	a5,a3,800017f6 <copyinstr+0x82>
      dst++;
    8000180e:	8b3e                	mv	s6,a5
    80001810:	b775                	j	800017bc <copyinstr+0x48>
    80001812:	4781                	li	a5,0
    80001814:	b771                	j	800017a0 <copyinstr+0x2c>
      return -1;
    80001816:	557d                	li	a0,-1
    80001818:	b779                	j	800017a6 <copyinstr+0x32>
  int got_null = 0;
    8000181a:	4781                	li	a5,0
  if(got_null){
    8000181c:	37fd                	addiw	a5,a5,-1
    8000181e:	0007851b          	sext.w	a0,a5
}
    80001822:	8082                	ret

0000000080001824 <enqueue_at_tail>:
  return(0);
}

static int
enqueue_at_tail(struct proc *p, int priority)
{
    80001824:	7179                	addi	sp,sp,-48
    80001826:	f406                	sd	ra,40(sp)
    80001828:	f022                	sd	s0,32(sp)
    8000182a:	ec26                	sd	s1,24(sp)
    8000182c:	e84a                	sd	s2,16(sp)
    8000182e:	e44e                	sd	s3,8(sp)
    80001830:	1800                	addi	s0,sp,48
  if(!(p >= proc && p < &proc[NPROC]))
    80001832:	00010797          	auipc	a5,0x10
    80001836:	f2e78793          	addi	a5,a5,-210 # 80011760 <proc>
    8000183a:	08f56263          	bltu	a0,a5,800018be <enqueue_at_tail+0x9a>
    8000183e:	892a                	mv	s2,a0
    80001840:	84ae                	mv	s1,a1
    80001842:	00016797          	auipc	a5,0x16
    80001846:	11e78793          	addi	a5,a5,286 # 80017960 <tickslock>
    8000184a:	06f57a63          	bgeu	a0,a5,800018be <enqueue_at_tail+0x9a>
    panic("enqueue_at_tail");
  if(!(priority >= 0) && (priority < NQUEUE))
    8000184e:	0805c063          	bltz	a1,800018ce <enqueue_at_tail+0xaa>
    panic("enqueue_at_tail");
  acquire(&queue[priority].lock);
    80001852:	00159793          	slli	a5,a1,0x1
    80001856:	97ae                	add	a5,a5,a1
    80001858:	0792                	slli	a5,a5,0x4
    8000185a:	00010997          	auipc	s3,0x10
    8000185e:	a4698993          	addi	s3,s3,-1466 # 800112a0 <queue>
    80001862:	99be                	add	s3,s3,a5
    80001864:	854e                	mv	a0,s3
    80001866:	fffff097          	auipc	ra,0xfffff
    8000186a:	36a080e7          	jalr	874(ra) # 80000bd0 <acquire>

  if((queue[priority].head == 0) && (queue[priority].tail == 0)){
    8000186e:	0209b783          	ld	a5,32(s3)
    80001872:	c7b5                	beqz	a5,800018de <enqueue_at_tail+0xba>
    queue[priority].tail = p;
    release(&queue[priority].lock);
    return(0);
  }

  if(queue[priority].tail == 0){
    80001874:	00149793          	slli	a5,s1,0x1
    80001878:	97a6                	add	a5,a5,s1
    8000187a:	0792                	slli	a5,a5,0x4
    8000187c:	00010717          	auipc	a4,0x10
    80001880:	a2470713          	addi	a4,a4,-1500 # 800112a0 <queue>
    80001884:	97ba                	add	a5,a5,a4
    80001886:	779c                	ld	a5,40(a5)
    80001888:	cba5                	beqz	a5,800018f8 <enqueue_at_tail+0xd4>
    release(&queue[priority].lock);
    panic("enqueue_at_tail");
  }

  queue[priority].tail->next = p;
    8000188a:	0527b823          	sd	s2,80(a5)
  queue[priority].tail = p;
    8000188e:	00149793          	slli	a5,s1,0x1
    80001892:	97a6                	add	a5,a5,s1
    80001894:	0792                	slli	a5,a5,0x4
    80001896:	00010717          	auipc	a4,0x10
    8000189a:	a0a70713          	addi	a4,a4,-1526 # 800112a0 <queue>
    8000189e:	97ba                	add	a5,a5,a4
    800018a0:	0327b423          	sd	s2,40(a5)

  release(&queue[priority].lock);
    800018a4:	854e                	mv	a0,s3
    800018a6:	fffff097          	auipc	ra,0xfffff
    800018aa:	3de080e7          	jalr	990(ra) # 80000c84 <release>
  return(0);
}
    800018ae:	4501                	li	a0,0
    800018b0:	70a2                	ld	ra,40(sp)
    800018b2:	7402                	ld	s0,32(sp)
    800018b4:	64e2                	ld	s1,24(sp)
    800018b6:	6942                	ld	s2,16(sp)
    800018b8:	69a2                	ld	s3,8(sp)
    800018ba:	6145                	addi	sp,sp,48
    800018bc:	8082                	ret
    panic("enqueue_at_tail");
    800018be:	00007517          	auipc	a0,0x7
    800018c2:	91a50513          	addi	a0,a0,-1766 # 800081d8 <digits+0x198>
    800018c6:	fffff097          	auipc	ra,0xfffff
    800018ca:	c74080e7          	jalr	-908(ra) # 8000053a <panic>
    panic("enqueue_at_tail");
    800018ce:	00007517          	auipc	a0,0x7
    800018d2:	90a50513          	addi	a0,a0,-1782 # 800081d8 <digits+0x198>
    800018d6:	fffff097          	auipc	ra,0xfffff
    800018da:	c64080e7          	jalr	-924(ra) # 8000053a <panic>
  if((queue[priority].head == 0) && (queue[priority].tail == 0)){
    800018de:	0289b783          	ld	a5,40(s3)
    800018e2:	f7c5                	bnez	a5,8000188a <enqueue_at_tail+0x66>
    queue[priority].head = p;
    800018e4:	0329b023          	sd	s2,32(s3)
    queue[priority].tail = p;
    800018e8:	0329b423          	sd	s2,40(s3)
    release(&queue[priority].lock);
    800018ec:	854e                	mv	a0,s3
    800018ee:	fffff097          	auipc	ra,0xfffff
    800018f2:	396080e7          	jalr	918(ra) # 80000c84 <release>
    return(0);
    800018f6:	bf65                	j	800018ae <enqueue_at_tail+0x8a>
    release(&queue[priority].lock);
    800018f8:	854e                	mv	a0,s3
    800018fa:	fffff097          	auipc	ra,0xfffff
    800018fe:	38a080e7          	jalr	906(ra) # 80000c84 <release>
    panic("enqueue_at_tail");
    80001902:	00007517          	auipc	a0,0x7
    80001906:	8d650513          	addi	a0,a0,-1834 # 800081d8 <digits+0x198>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	c30080e7          	jalr	-976(ra) # 8000053a <panic>

0000000080001912 <dequeue>:
  return(0);
} 

static struct proc*
dequeue(int priority)
{
    80001912:	7179                	addi	sp,sp,-48
    80001914:	f406                	sd	ra,40(sp)
    80001916:	f022                	sd	s0,32(sp)
    80001918:	ec26                	sd	s1,24(sp)
    8000191a:	e84a                	sd	s2,16(sp)
    8000191c:	e44e                	sd	s3,8(sp)
    8000191e:	e052                	sd	s4,0(sp)
    80001920:	1800                	addi	s0,sp,48
    80001922:	84aa                	mv	s1,a0
  struct proc *p;
  if (!(priority >= 0) && (priority < NQUEUE)) {
    80001924:	06054e63          	bltz	a0,800019a0 <dequeue+0x8e>
    printf("dequeue: invalid argument %d\n", priority);
    return(0);
  }
  acquire(&queue[priority].lock);
    80001928:	00151793          	slli	a5,a0,0x1
    8000192c:	97aa                	add	a5,a5,a0
    8000192e:	0792                	slli	a5,a5,0x4
    80001930:	00010997          	auipc	s3,0x10
    80001934:	97098993          	addi	s3,s3,-1680 # 800112a0 <queue>
    80001938:	99be                	add	s3,s3,a5
    8000193a:	854e                	mv	a0,s3
    8000193c:	fffff097          	auipc	ra,0xfffff
    80001940:	294080e7          	jalr	660(ra) # 80000bd0 <acquire>
  if ((queue[priority].head == 0) && (queue[priority].tail == 0)) {
    80001944:	0209b903          	ld	s2,32(s3)
    80001948:	06090763          	beqz	s2,800019b6 <dequeue+0xa4>
  if (queue[priority].head == 0) {
    release(&queue[priority].lock);
    panic("dequeue");
  }
  p = queue[priority].head;
  acquire(&p->lock);
    8000194c:	854a                	mv	a0,s2
    8000194e:	fffff097          	auipc	ra,0xfffff
    80001952:	282080e7          	jalr	642(ra) # 80000bd0 <acquire>
  queue[priority].head = p->next;
    80001956:	05093703          	ld	a4,80(s2) # 1050 <_entry-0x7fffefb0>
    8000195a:	00149793          	slli	a5,s1,0x1
    8000195e:	97a6                	add	a5,a5,s1
    80001960:	0792                	slli	a5,a5,0x4
    80001962:	00010a17          	auipc	s4,0x10
    80001966:	93ea0a13          	addi	s4,s4,-1730 # 800112a0 <queue>
    8000196a:	9a3e                	add	s4,s4,a5
    8000196c:	02ea3023          	sd	a4,32(s4)
  p->next = 0;
    80001970:	04093823          	sd	zero,80(s2)
  release(&p->lock);
    80001974:	854a                	mv	a0,s2
    80001976:	fffff097          	auipc	ra,0xfffff
    8000197a:	30e080e7          	jalr	782(ra) # 80000c84 <release>
  if (!queue[priority].head)
    8000197e:	020a3783          	ld	a5,32(s4)
    80001982:	c3ad                	beqz	a5,800019e4 <dequeue+0xd2>
  queue[priority].tail = 0;
  release(&queue[priority].lock);
    80001984:	854e                	mv	a0,s3
    80001986:	fffff097          	auipc	ra,0xfffff
    8000198a:	2fe080e7          	jalr	766(ra) # 80000c84 <release>
  return(p);
}
    8000198e:	854a                	mv	a0,s2
    80001990:	70a2                	ld	ra,40(sp)
    80001992:	7402                	ld	s0,32(sp)
    80001994:	64e2                	ld	s1,24(sp)
    80001996:	6942                	ld	s2,16(sp)
    80001998:	69a2                	ld	s3,8(sp)
    8000199a:	6a02                	ld	s4,0(sp)
    8000199c:	6145                	addi	sp,sp,48
    8000199e:	8082                	ret
    printf("dequeue: invalid argument %d\n", priority);
    800019a0:	85aa                	mv	a1,a0
    800019a2:	00007517          	auipc	a0,0x7
    800019a6:	84650513          	addi	a0,a0,-1978 # 800081e8 <digits+0x1a8>
    800019aa:	fffff097          	auipc	ra,0xfffff
    800019ae:	bda080e7          	jalr	-1062(ra) # 80000584 <printf>
    return(0);
    800019b2:	4901                	li	s2,0
    800019b4:	bfe9                	j	8000198e <dequeue+0x7c>
  if ((queue[priority].head == 0) && (queue[priority].tail == 0)) {
    800019b6:	0289b903          	ld	s2,40(s3)
    800019ba:	00090f63          	beqz	s2,800019d8 <dequeue+0xc6>
    release(&queue[priority].lock);
    800019be:	854e                	mv	a0,s3
    800019c0:	fffff097          	auipc	ra,0xfffff
    800019c4:	2c4080e7          	jalr	708(ra) # 80000c84 <release>
    panic("dequeue");
    800019c8:	00007517          	auipc	a0,0x7
    800019cc:	84050513          	addi	a0,a0,-1984 # 80008208 <digits+0x1c8>
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	b6a080e7          	jalr	-1174(ra) # 8000053a <panic>
    release(&queue[priority].lock);
    800019d8:	854e                	mv	a0,s3
    800019da:	fffff097          	auipc	ra,0xfffff
    800019de:	2aa080e7          	jalr	682(ra) # 80000c84 <release>
    return(0);
    800019e2:	b775                	j	8000198e <dequeue+0x7c>
  queue[priority].tail = 0;
    800019e4:	020a3423          	sd	zero,40(s4)
    800019e8:	bf71                	j	80001984 <dequeue+0x72>

00000000800019ea <queueinit>:
{
    800019ea:	1101                	addi	sp,sp,-32
    800019ec:	ec06                	sd	ra,24(sp)
    800019ee:	e822                	sd	s0,16(sp)
    800019f0:	e426                	sd	s1,8(sp)
    800019f2:	1000                	addi	s0,sp,32
    initlock(&q->lock, "queue");
    800019f4:	00010497          	auipc	s1,0x10
    800019f8:	8ac48493          	addi	s1,s1,-1876 # 800112a0 <queue>
    800019fc:	00007597          	auipc	a1,0x7
    80001a00:	81458593          	addi	a1,a1,-2028 # 80008210 <digits+0x1d0>
    80001a04:	8526                	mv	a0,s1
    80001a06:	fffff097          	auipc	ra,0xfffff
    80001a0a:	13a080e7          	jalr	314(ra) # 80000b40 <initlock>
      q->timeslice = TSTICKSHIGH;
    80001a0e:	4785                	li	a5,1
    80001a10:	cc9c                	sw	a5,24(s1)
    q->head = 0;
    80001a12:	0204b023          	sd	zero,32(s1)
    q->tail = 0;
    80001a16:	0204b423          	sd	zero,40(s1)
    initlock(&q->lock, "queue");
    80001a1a:	00006597          	auipc	a1,0x6
    80001a1e:	7f658593          	addi	a1,a1,2038 # 80008210 <digits+0x1d0>
    80001a22:	00010517          	auipc	a0,0x10
    80001a26:	8ae50513          	addi	a0,a0,-1874 # 800112d0 <queue+0x30>
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	116080e7          	jalr	278(ra) # 80000b40 <initlock>
      q->timeslice = TSTICKSHIGH;
    80001a32:	03200793          	li	a5,50
    80001a36:	c4bc                	sw	a5,72(s1)
    q->head = 0;
    80001a38:	0404b823          	sd	zero,80(s1)
    q->tail = 0;
    80001a3c:	0404bc23          	sd	zero,88(s1)
    initlock(&q->lock, "queue");
    80001a40:	00006597          	auipc	a1,0x6
    80001a44:	7d058593          	addi	a1,a1,2000 # 80008210 <digits+0x1d0>
    80001a48:	00010517          	auipc	a0,0x10
    80001a4c:	8b850513          	addi	a0,a0,-1864 # 80011300 <queue+0x60>
    80001a50:	fffff097          	auipc	ra,0xfffff
    80001a54:	0f0080e7          	jalr	240(ra) # 80000b40 <initlock>
      q->timeslice = TSTICKSHIGH;
    80001a58:	0c800793          	li	a5,200
    80001a5c:	dcbc                	sw	a5,120(s1)
    q->head = 0;
    80001a5e:	0804b023          	sd	zero,128(s1)
    q->tail = 0;
    80001a62:	0804b423          	sd	zero,136(s1)
} 
    80001a66:	60e2                	ld	ra,24(sp)
    80001a68:	6442                	ld	s0,16(sp)
    80001a6a:	64a2                	ld	s1,8(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <timeslice>:
  if(priority == HIGH)
    80001a70:	cd05                	beqz	a0,80001aa8 <timeslice+0x38>
    80001a72:	85aa                	mv	a1,a0
  else if(priority == MEDIUM)
    80001a74:	4785                	li	a5,1
    80001a76:	02f50b63          	beq	a0,a5,80001aac <timeslice+0x3c>
  else if(priority == LOW)
    80001a7a:	4789                	li	a5,2
    return(TSTICKSLOW);
    80001a7c:	0c800513          	li	a0,200
  else if(priority == LOW)
    80001a80:	00f59363          	bne	a1,a5,80001a86 <timeslice+0x16>
}
    80001a84:	8082                	ret
{
    80001a86:	1141                	addi	sp,sp,-16
    80001a88:	e406                	sd	ra,8(sp)
    80001a8a:	e022                	sd	s0,0(sp)
    80001a8c:	0800                	addi	s0,sp,16
    printf("timeslive: invalid priority %d\n", priority);
    80001a8e:	00006517          	auipc	a0,0x6
    80001a92:	78a50513          	addi	a0,a0,1930 # 80008218 <digits+0x1d8>
    80001a96:	fffff097          	auipc	ra,0xfffff
    80001a9a:	aee080e7          	jalr	-1298(ra) # 80000584 <printf>
    return -1;
    80001a9e:	557d                	li	a0,-1
}
    80001aa0:	60a2                	ld	ra,8(sp)
    80001aa2:	6402                	ld	s0,0(sp)
    80001aa4:	0141                	addi	sp,sp,16
    80001aa6:	8082                	ret
    return(TSTICKSHIGH);
    80001aa8:	4505                	li	a0,1
    80001aaa:	8082                	ret
    return(TSTICKSMEDIUM);
    80001aac:	03200513          	li	a0,50
    80001ab0:	8082                	ret

0000000080001ab2 <queue_empty>:
{
    80001ab2:	1141                	addi	sp,sp,-16
    80001ab4:	e422                	sd	s0,8(sp)
    80001ab6:	0800                	addi	s0,sp,16
  if (!queue[priority].head)
    80001ab8:	00151793          	slli	a5,a0,0x1
    80001abc:	97aa                	add	a5,a5,a0
    80001abe:	0792                	slli	a5,a5,0x4
    80001ac0:	0000f717          	auipc	a4,0xf
    80001ac4:	7e070713          	addi	a4,a4,2016 # 800112a0 <queue>
    80001ac8:	97ba                	add	a5,a5,a4
    80001aca:	7388                	ld	a0,32(a5)
}
    80001acc:	00153513          	seqz	a0,a0
    80001ad0:	6422                	ld	s0,8(sp)
    80001ad2:	0141                	addi	sp,sp,16
    80001ad4:	8082                	ret

0000000080001ad6 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001ad6:	7139                	addi	sp,sp,-64
    80001ad8:	fc06                	sd	ra,56(sp)
    80001ada:	f822                	sd	s0,48(sp)
    80001adc:	f426                	sd	s1,40(sp)
    80001ade:	f04a                	sd	s2,32(sp)
    80001ae0:	ec4e                	sd	s3,24(sp)
    80001ae2:	e852                	sd	s4,16(sp)
    80001ae4:	e456                	sd	s5,8(sp)
    80001ae6:	e05a                	sd	s6,0(sp)
    80001ae8:	0080                	addi	s0,sp,64
    80001aea:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001aec:	00010497          	auipc	s1,0x10
    80001af0:	c7448493          	addi	s1,s1,-908 # 80011760 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001af4:	8b26                	mv	s6,s1
    80001af6:	00006a97          	auipc	s5,0x6
    80001afa:	50aa8a93          	addi	s5,s5,1290 # 80008000 <etext>
    80001afe:	04000937          	lui	s2,0x4000
    80001b02:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001b04:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b06:	00016a17          	auipc	s4,0x16
    80001b0a:	e5aa0a13          	addi	s4,s4,-422 # 80017960 <tickslock>
    char *pa = kalloc();
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	fd2080e7          	jalr	-46(ra) # 80000ae0 <kalloc>
    80001b16:	862a                	mv	a2,a0
    if(pa == 0)
    80001b18:	c131                	beqz	a0,80001b5c <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001b1a:	416485b3          	sub	a1,s1,s6
    80001b1e:	858d                	srai	a1,a1,0x3
    80001b20:	000ab783          	ld	a5,0(s5)
    80001b24:	02f585b3          	mul	a1,a1,a5
    80001b28:	2585                	addiw	a1,a1,1
    80001b2a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b2e:	4719                	li	a4,6
    80001b30:	6685                	lui	a3,0x1
    80001b32:	40b905b3          	sub	a1,s2,a1
    80001b36:	854e                	mv	a0,s3
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	5fc080e7          	jalr	1532(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b40:	18848493          	addi	s1,s1,392
    80001b44:	fd4495e3          	bne	s1,s4,80001b0e <proc_mapstacks+0x38>
  }
}
    80001b48:	70e2                	ld	ra,56(sp)
    80001b4a:	7442                	ld	s0,48(sp)
    80001b4c:	74a2                	ld	s1,40(sp)
    80001b4e:	7902                	ld	s2,32(sp)
    80001b50:	69e2                	ld	s3,24(sp)
    80001b52:	6a42                	ld	s4,16(sp)
    80001b54:	6aa2                	ld	s5,8(sp)
    80001b56:	6b02                	ld	s6,0(sp)
    80001b58:	6121                	addi	sp,sp,64
    80001b5a:	8082                	ret
      panic("kalloc");
    80001b5c:	00006517          	auipc	a0,0x6
    80001b60:	6dc50513          	addi	a0,a0,1756 # 80008238 <digits+0x1f8>
    80001b64:	fffff097          	auipc	ra,0xfffff
    80001b68:	9d6080e7          	jalr	-1578(ra) # 8000053a <panic>

0000000080001b6c <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001b6c:	7139                	addi	sp,sp,-64
    80001b6e:	fc06                	sd	ra,56(sp)
    80001b70:	f822                	sd	s0,48(sp)
    80001b72:	f426                	sd	s1,40(sp)
    80001b74:	f04a                	sd	s2,32(sp)
    80001b76:	ec4e                	sd	s3,24(sp)
    80001b78:	e852                	sd	s4,16(sp)
    80001b7a:	e456                	sd	s5,8(sp)
    80001b7c:	e05a                	sd	s6,0(sp)
    80001b7e:	0080                	addi	s0,sp,64
  struct proc *p;
  
  //Initializes the queue at startup
  queueinit();
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	e6a080e7          	jalr	-406(ra) # 800019ea <queueinit>

  initlock(&pid_lock, "nextpid");
    80001b88:	00006597          	auipc	a1,0x6
    80001b8c:	6b858593          	addi	a1,a1,1720 # 80008240 <digits+0x200>
    80001b90:	0000f517          	auipc	a0,0xf
    80001b94:	7a050513          	addi	a0,a0,1952 # 80011330 <pid_lock>
    80001b98:	fffff097          	auipc	ra,0xfffff
    80001b9c:	fa8080e7          	jalr	-88(ra) # 80000b40 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001ba0:	00006597          	auipc	a1,0x6
    80001ba4:	6a858593          	addi	a1,a1,1704 # 80008248 <digits+0x208>
    80001ba8:	0000f517          	auipc	a0,0xf
    80001bac:	7a050513          	addi	a0,a0,1952 # 80011348 <wait_lock>
    80001bb0:	fffff097          	auipc	ra,0xfffff
    80001bb4:	f90080e7          	jalr	-112(ra) # 80000b40 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bb8:	00010497          	auipc	s1,0x10
    80001bbc:	ba848493          	addi	s1,s1,-1112 # 80011760 <proc>
      initlock(&p->lock, "proc");
    80001bc0:	00006b17          	auipc	s6,0x6
    80001bc4:	698b0b13          	addi	s6,s6,1688 # 80008258 <digits+0x218>
      p->kstack = KSTACK((int) (p - proc));
    80001bc8:	8aa6                	mv	s5,s1
    80001bca:	00006a17          	auipc	s4,0x6
    80001bce:	436a0a13          	addi	s4,s4,1078 # 80008000 <etext>
    80001bd2:	04000937          	lui	s2,0x4000
    80001bd6:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001bd8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bda:	00016997          	auipc	s3,0x16
    80001bde:	d8698993          	addi	s3,s3,-634 # 80017960 <tickslock>
      initlock(&p->lock, "proc");
    80001be2:	85da                	mv	a1,s6
    80001be4:	8526                	mv	a0,s1
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	f5a080e7          	jalr	-166(ra) # 80000b40 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001bee:	415487b3          	sub	a5,s1,s5
    80001bf2:	878d                	srai	a5,a5,0x3
    80001bf4:	000a3703          	ld	a4,0(s4)
    80001bf8:	02e787b3          	mul	a5,a5,a4
    80001bfc:	2785                	addiw	a5,a5,1
    80001bfe:	00d7979b          	slliw	a5,a5,0xd
    80001c02:	40f907b3          	sub	a5,s2,a5
    80001c06:	f0bc                	sd	a5,96(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c08:	18848493          	addi	s1,s1,392
    80001c0c:	fd349be3          	bne	s1,s3,80001be2 <procinit+0x76>
  }
}
    80001c10:	70e2                	ld	ra,56(sp)
    80001c12:	7442                	ld	s0,48(sp)
    80001c14:	74a2                	ld	s1,40(sp)
    80001c16:	7902                	ld	s2,32(sp)
    80001c18:	69e2                	ld	s3,24(sp)
    80001c1a:	6a42                	ld	s4,16(sp)
    80001c1c:	6aa2                	ld	s5,8(sp)
    80001c1e:	6b02                	ld	s6,0(sp)
    80001c20:	6121                	addi	sp,sp,64
    80001c22:	8082                	ret

0000000080001c24 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001c24:	1141                	addi	sp,sp,-16
    80001c26:	e422                	sd	s0,8(sp)
    80001c28:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c2a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001c2c:	2501                	sext.w	a0,a0
    80001c2e:	6422                	ld	s0,8(sp)
    80001c30:	0141                	addi	sp,sp,16
    80001c32:	8082                	ret

0000000080001c34 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001c34:	1141                	addi	sp,sp,-16
    80001c36:	e422                	sd	s0,8(sp)
    80001c38:	0800                	addi	s0,sp,16
    80001c3a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001c3c:	2781                	sext.w	a5,a5
    80001c3e:	079e                	slli	a5,a5,0x7
  return c;
}
    80001c40:	0000f517          	auipc	a0,0xf
    80001c44:	72050513          	addi	a0,a0,1824 # 80011360 <cpus>
    80001c48:	953e                	add	a0,a0,a5
    80001c4a:	6422                	ld	s0,8(sp)
    80001c4c:	0141                	addi	sp,sp,16
    80001c4e:	8082                	ret

0000000080001c50 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001c50:	1101                	addi	sp,sp,-32
    80001c52:	ec06                	sd	ra,24(sp)
    80001c54:	e822                	sd	s0,16(sp)
    80001c56:	e426                	sd	s1,8(sp)
    80001c58:	1000                	addi	s0,sp,32
  push_off();
    80001c5a:	fffff097          	auipc	ra,0xfffff
    80001c5e:	f2a080e7          	jalr	-214(ra) # 80000b84 <push_off>
    80001c62:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001c64:	2781                	sext.w	a5,a5
    80001c66:	079e                	slli	a5,a5,0x7
    80001c68:	0000f717          	auipc	a4,0xf
    80001c6c:	63870713          	addi	a4,a4,1592 # 800112a0 <queue>
    80001c70:	97ba                	add	a5,a5,a4
    80001c72:	63e4                	ld	s1,192(a5)
  pop_off();
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	fb0080e7          	jalr	-80(ra) # 80000c24 <pop_off>
  return p;
}
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	60e2                	ld	ra,24(sp)
    80001c80:	6442                	ld	s0,16(sp)
    80001c82:	64a2                	ld	s1,8(sp)
    80001c84:	6105                	addi	sp,sp,32
    80001c86:	8082                	ret

0000000080001c88 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001c88:	1141                	addi	sp,sp,-16
    80001c8a:	e406                	sd	ra,8(sp)
    80001c8c:	e022                	sd	s0,0(sp)
    80001c8e:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001c90:	00000097          	auipc	ra,0x0
    80001c94:	fc0080e7          	jalr	-64(ra) # 80001c50 <myproc>
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	fec080e7          	jalr	-20(ra) # 80000c84 <release>

  if (first) {
    80001ca0:	00007797          	auipc	a5,0x7
    80001ca4:	bf07a783          	lw	a5,-1040(a5) # 80008890 <first.1>
    80001ca8:	eb89                	bnez	a5,80001cba <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001caa:	00001097          	auipc	ra,0x1
    80001cae:	f82080e7          	jalr	-126(ra) # 80002c2c <usertrapret>
}
    80001cb2:	60a2                	ld	ra,8(sp)
    80001cb4:	6402                	ld	s0,0(sp)
    80001cb6:	0141                	addi	sp,sp,16
    80001cb8:	8082                	ret
    first = 0;
    80001cba:	00007797          	auipc	a5,0x7
    80001cbe:	bc07ab23          	sw	zero,-1066(a5) # 80008890 <first.1>
    fsinit(ROOTDEV);
    80001cc2:	4505                	li	a0,1
    80001cc4:	00002097          	auipc	ra,0x2
    80001cc8:	f0a080e7          	jalr	-246(ra) # 80003bce <fsinit>
    80001ccc:	bff9                	j	80001caa <forkret+0x22>

0000000080001cce <allocpid>:
allocpid() {
    80001cce:	1101                	addi	sp,sp,-32
    80001cd0:	ec06                	sd	ra,24(sp)
    80001cd2:	e822                	sd	s0,16(sp)
    80001cd4:	e426                	sd	s1,8(sp)
    80001cd6:	e04a                	sd	s2,0(sp)
    80001cd8:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001cda:	0000f917          	auipc	s2,0xf
    80001cde:	65690913          	addi	s2,s2,1622 # 80011330 <pid_lock>
    80001ce2:	854a                	mv	a0,s2
    80001ce4:	fffff097          	auipc	ra,0xfffff
    80001ce8:	eec080e7          	jalr	-276(ra) # 80000bd0 <acquire>
  pid = nextpid;
    80001cec:	00007797          	auipc	a5,0x7
    80001cf0:	ba878793          	addi	a5,a5,-1112 # 80008894 <nextpid>
    80001cf4:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001cf6:	0014871b          	addiw	a4,s1,1
    80001cfa:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001cfc:	854a                	mv	a0,s2
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	f86080e7          	jalr	-122(ra) # 80000c84 <release>
}
    80001d06:	8526                	mv	a0,s1
    80001d08:	60e2                	ld	ra,24(sp)
    80001d0a:	6442                	ld	s0,16(sp)
    80001d0c:	64a2                	ld	s1,8(sp)
    80001d0e:	6902                	ld	s2,0(sp)
    80001d10:	6105                	addi	sp,sp,32
    80001d12:	8082                	ret

0000000080001d14 <proc_pagetable>:
{
    80001d14:	1101                	addi	sp,sp,-32
    80001d16:	ec06                	sd	ra,24(sp)
    80001d18:	e822                	sd	s0,16(sp)
    80001d1a:	e426                	sd	s1,8(sp)
    80001d1c:	e04a                	sd	s2,0(sp)
    80001d1e:	1000                	addi	s0,sp,32
    80001d20:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001d22:	fffff097          	auipc	ra,0xfffff
    80001d26:	5fc080e7          	jalr	1532(ra) # 8000131e <uvmcreate>
    80001d2a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001d2c:	c121                	beqz	a0,80001d6c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d2e:	4729                	li	a4,10
    80001d30:	00005697          	auipc	a3,0x5
    80001d34:	2d068693          	addi	a3,a3,720 # 80007000 <_trampoline>
    80001d38:	6605                	lui	a2,0x1
    80001d3a:	040005b7          	lui	a1,0x4000
    80001d3e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d40:	05b2                	slli	a1,a1,0xc
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	352080e7          	jalr	850(ra) # 80001094 <mappages>
    80001d4a:	02054863          	bltz	a0,80001d7a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d4e:	4719                	li	a4,6
    80001d50:	07893683          	ld	a3,120(s2)
    80001d54:	6605                	lui	a2,0x1
    80001d56:	020005b7          	lui	a1,0x2000
    80001d5a:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d5c:	05b6                	slli	a1,a1,0xd
    80001d5e:	8526                	mv	a0,s1
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	334080e7          	jalr	820(ra) # 80001094 <mappages>
    80001d68:	02054163          	bltz	a0,80001d8a <proc_pagetable+0x76>
}
    80001d6c:	8526                	mv	a0,s1
    80001d6e:	60e2                	ld	ra,24(sp)
    80001d70:	6442                	ld	s0,16(sp)
    80001d72:	64a2                	ld	s1,8(sp)
    80001d74:	6902                	ld	s2,0(sp)
    80001d76:	6105                	addi	sp,sp,32
    80001d78:	8082                	ret
    uvmfree(pagetable, 0);
    80001d7a:	4581                	li	a1,0
    80001d7c:	8526                	mv	a0,s1
    80001d7e:	fffff097          	auipc	ra,0xfffff
    80001d82:	79e080e7          	jalr	1950(ra) # 8000151c <uvmfree>
    return 0;
    80001d86:	4481                	li	s1,0
    80001d88:	b7d5                	j	80001d6c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d8a:	4681                	li	a3,0
    80001d8c:	4605                	li	a2,1
    80001d8e:	040005b7          	lui	a1,0x4000
    80001d92:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d94:	05b2                	slli	a1,a1,0xc
    80001d96:	8526                	mv	a0,s1
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	4c2080e7          	jalr	1218(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001da0:	4581                	li	a1,0
    80001da2:	8526                	mv	a0,s1
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	778080e7          	jalr	1912(ra) # 8000151c <uvmfree>
    return 0;
    80001dac:	4481                	li	s1,0
    80001dae:	bf7d                	j	80001d6c <proc_pagetable+0x58>

0000000080001db0 <proc_freepagetable>:
{
    80001db0:	1101                	addi	sp,sp,-32
    80001db2:	ec06                	sd	ra,24(sp)
    80001db4:	e822                	sd	s0,16(sp)
    80001db6:	e426                	sd	s1,8(sp)
    80001db8:	e04a                	sd	s2,0(sp)
    80001dba:	1000                	addi	s0,sp,32
    80001dbc:	84aa                	mv	s1,a0
    80001dbe:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001dc0:	4681                	li	a3,0
    80001dc2:	4605                	li	a2,1
    80001dc4:	040005b7          	lui	a1,0x4000
    80001dc8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001dca:	05b2                	slli	a1,a1,0xc
    80001dcc:	fffff097          	auipc	ra,0xfffff
    80001dd0:	48e080e7          	jalr	1166(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001dd4:	4681                	li	a3,0
    80001dd6:	4605                	li	a2,1
    80001dd8:	020005b7          	lui	a1,0x2000
    80001ddc:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001dde:	05b6                	slli	a1,a1,0xd
    80001de0:	8526                	mv	a0,s1
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	478080e7          	jalr	1144(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001dea:	85ca                	mv	a1,s2
    80001dec:	8526                	mv	a0,s1
    80001dee:	fffff097          	auipc	ra,0xfffff
    80001df2:	72e080e7          	jalr	1838(ra) # 8000151c <uvmfree>
}
    80001df6:	60e2                	ld	ra,24(sp)
    80001df8:	6442                	ld	s0,16(sp)
    80001dfa:	64a2                	ld	s1,8(sp)
    80001dfc:	6902                	ld	s2,0(sp)
    80001dfe:	6105                	addi	sp,sp,32
    80001e00:	8082                	ret

0000000080001e02 <freeproc>:
{
    80001e02:	1101                	addi	sp,sp,-32
    80001e04:	ec06                	sd	ra,24(sp)
    80001e06:	e822                	sd	s0,16(sp)
    80001e08:	e426                	sd	s1,8(sp)
    80001e0a:	1000                	addi	s0,sp,32
    80001e0c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001e0e:	7d28                	ld	a0,120(a0)
    80001e10:	c509                	beqz	a0,80001e1a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001e12:	fffff097          	auipc	ra,0xfffff
    80001e16:	bd0080e7          	jalr	-1072(ra) # 800009e2 <kfree>
  p->trapframe = 0;
    80001e1a:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    80001e1e:	78a8                	ld	a0,112(s1)
    80001e20:	c511                	beqz	a0,80001e2c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001e22:	74ac                	ld	a1,104(s1)
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	f8c080e7          	jalr	-116(ra) # 80001db0 <proc_freepagetable>
  p->pagetable = 0;
    80001e2c:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80001e30:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80001e34:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001e38:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80001e3c:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80001e40:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001e44:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001e48:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001e4c:	0004ac23          	sw	zero,24(s1)
}
    80001e50:	60e2                	ld	ra,24(sp)
    80001e52:	6442                	ld	s0,16(sp)
    80001e54:	64a2                	ld	s1,8(sp)
    80001e56:	6105                	addi	sp,sp,32
    80001e58:	8082                	ret

0000000080001e5a <allocproc>:
{
    80001e5a:	1101                	addi	sp,sp,-32
    80001e5c:	ec06                	sd	ra,24(sp)
    80001e5e:	e822                	sd	s0,16(sp)
    80001e60:	e426                	sd	s1,8(sp)
    80001e62:	e04a                	sd	s2,0(sp)
    80001e64:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e66:	00010497          	auipc	s1,0x10
    80001e6a:	8fa48493          	addi	s1,s1,-1798 # 80011760 <proc>
    80001e6e:	00016917          	auipc	s2,0x16
    80001e72:	af290913          	addi	s2,s2,-1294 # 80017960 <tickslock>
    acquire(&p->lock);
    80001e76:	8526                	mv	a0,s1
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	d58080e7          	jalr	-680(ra) # 80000bd0 <acquire>
    if(p->state == UNUSED) {
    80001e80:	4c9c                	lw	a5,24(s1)
    80001e82:	cf81                	beqz	a5,80001e9a <allocproc+0x40>
      release(&p->lock);
    80001e84:	8526                	mv	a0,s1
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	dfe080e7          	jalr	-514(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e8e:	18848493          	addi	s1,s1,392
    80001e92:	ff2492e3          	bne	s1,s2,80001e76 <allocproc+0x1c>
  return 0;
    80001e96:	4481                	li	s1,0
    80001e98:	a09d                	j	80001efe <allocproc+0xa4>
  p->pid = allocpid();
    80001e9a:	00000097          	auipc	ra,0x0
    80001e9e:	e34080e7          	jalr	-460(ra) # 80001cce <allocpid>
    80001ea2:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001ea4:	4785                	li	a5,1
    80001ea6:	cc9c                	sw	a5,24(s1)
  p->cputime = 0;
    80001ea8:	0204bc23          	sd	zero,56(s1)
  p->priority = HIGH;
    80001eac:	0404a223          	sw	zero,68(s1)
  p->timeslice = TSTICKSHIGH;
    80001eb0:	c4bc                	sw	a5,72(s1)
  p->tsticks = TSTICKSHIGH;
    80001eb2:	c0bc                	sw	a5,64(s1)
  p->yielded = 0;
    80001eb4:	0404a623          	sw	zero,76(s1)
  p->next = 0;
    80001eb8:	0404b823          	sd	zero,80(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	c24080e7          	jalr	-988(ra) # 80000ae0 <kalloc>
    80001ec4:	892a                	mv	s2,a0
    80001ec6:	fca8                	sd	a0,120(s1)
    80001ec8:	c131                	beqz	a0,80001f0c <allocproc+0xb2>
  p->pagetable = proc_pagetable(p);
    80001eca:	8526                	mv	a0,s1
    80001ecc:	00000097          	auipc	ra,0x0
    80001ed0:	e48080e7          	jalr	-440(ra) # 80001d14 <proc_pagetable>
    80001ed4:	892a                	mv	s2,a0
    80001ed6:	f8a8                	sd	a0,112(s1)
  if(p->pagetable == 0){
    80001ed8:	c531                	beqz	a0,80001f24 <allocproc+0xca>
  memset(&p->context, 0, sizeof(p->context));
    80001eda:	07000613          	li	a2,112
    80001ede:	4581                	li	a1,0
    80001ee0:	08048513          	addi	a0,s1,128
    80001ee4:	fffff097          	auipc	ra,0xfffff
    80001ee8:	de8080e7          	jalr	-536(ra) # 80000ccc <memset>
  p->context.ra = (uint64)forkret;
    80001eec:	00000797          	auipc	a5,0x0
    80001ef0:	d9c78793          	addi	a5,a5,-612 # 80001c88 <forkret>
    80001ef4:	e0dc                	sd	a5,128(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ef6:	70bc                	ld	a5,96(s1)
    80001ef8:	6705                	lui	a4,0x1
    80001efa:	97ba                	add	a5,a5,a4
    80001efc:	e4dc                	sd	a5,136(s1)
}
    80001efe:	8526                	mv	a0,s1
    80001f00:	60e2                	ld	ra,24(sp)
    80001f02:	6442                	ld	s0,16(sp)
    80001f04:	64a2                	ld	s1,8(sp)
    80001f06:	6902                	ld	s2,0(sp)
    80001f08:	6105                	addi	sp,sp,32
    80001f0a:	8082                	ret
    freeproc(p);
    80001f0c:	8526                	mv	a0,s1
    80001f0e:	00000097          	auipc	ra,0x0
    80001f12:	ef4080e7          	jalr	-268(ra) # 80001e02 <freeproc>
    release(&p->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	d6c080e7          	jalr	-660(ra) # 80000c84 <release>
    return 0;
    80001f20:	84ca                	mv	s1,s2
    80001f22:	bff1                	j	80001efe <allocproc+0xa4>
    freeproc(p);
    80001f24:	8526                	mv	a0,s1
    80001f26:	00000097          	auipc	ra,0x0
    80001f2a:	edc080e7          	jalr	-292(ra) # 80001e02 <freeproc>
    release(&p->lock);
    80001f2e:	8526                	mv	a0,s1
    80001f30:	fffff097          	auipc	ra,0xfffff
    80001f34:	d54080e7          	jalr	-684(ra) # 80000c84 <release>
    return 0;
    80001f38:	84ca                	mv	s1,s2
    80001f3a:	b7d1                	j	80001efe <allocproc+0xa4>

0000000080001f3c <userinit>:
{
    80001f3c:	1101                	addi	sp,sp,-32
    80001f3e:	ec06                	sd	ra,24(sp)
    80001f40:	e822                	sd	s0,16(sp)
    80001f42:	e426                	sd	s1,8(sp)
    80001f44:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f46:	00000097          	auipc	ra,0x0
    80001f4a:	f14080e7          	jalr	-236(ra) # 80001e5a <allocproc>
    80001f4e:	84aa                	mv	s1,a0
  initproc = p;
    80001f50:	00007797          	auipc	a5,0x7
    80001f54:	0ca7bc23          	sd	a0,216(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001f58:	03400613          	li	a2,52
    80001f5c:	00007597          	auipc	a1,0x7
    80001f60:	94458593          	addi	a1,a1,-1724 # 800088a0 <initcode>
    80001f64:	7928                	ld	a0,112(a0)
    80001f66:	fffff097          	auipc	ra,0xfffff
    80001f6a:	3e6080e7          	jalr	998(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001f6e:	6785                	lui	a5,0x1
    80001f70:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    80001f72:	7cb8                	ld	a4,120(s1)
    80001f74:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f78:	7cb8                	ld	a4,120(s1)
    80001f7a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f7c:	4641                	li	a2,16
    80001f7e:	00006597          	auipc	a1,0x6
    80001f82:	2e258593          	addi	a1,a1,738 # 80008260 <digits+0x220>
    80001f86:	17848513          	addi	a0,s1,376
    80001f8a:	fffff097          	auipc	ra,0xfffff
    80001f8e:	e8c080e7          	jalr	-372(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001f92:	00006517          	auipc	a0,0x6
    80001f96:	2de50513          	addi	a0,a0,734 # 80008270 <digits+0x230>
    80001f9a:	00002097          	auipc	ra,0x2
    80001f9e:	66a080e7          	jalr	1642(ra) # 80004604 <namei>
    80001fa2:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    80001fa6:	478d                	li	a5,3
    80001fa8:	cc9c                	sw	a5,24(s1)
  enqueue_at_tail(p, p->priority);
    80001faa:	40ec                	lw	a1,68(s1)
    80001fac:	8526                	mv	a0,s1
    80001fae:	00000097          	auipc	ra,0x0
    80001fb2:	876080e7          	jalr	-1930(ra) # 80001824 <enqueue_at_tail>
  release(&p->lock);
    80001fb6:	8526                	mv	a0,s1
    80001fb8:	fffff097          	auipc	ra,0xfffff
    80001fbc:	ccc080e7          	jalr	-820(ra) # 80000c84 <release>
}
    80001fc0:	60e2                	ld	ra,24(sp)
    80001fc2:	6442                	ld	s0,16(sp)
    80001fc4:	64a2                	ld	s1,8(sp)
    80001fc6:	6105                	addi	sp,sp,32
    80001fc8:	8082                	ret

0000000080001fca <growproc>:
{
    80001fca:	1101                	addi	sp,sp,-32
    80001fcc:	ec06                	sd	ra,24(sp)
    80001fce:	e822                	sd	s0,16(sp)
    80001fd0:	e426                	sd	s1,8(sp)
    80001fd2:	e04a                	sd	s2,0(sp)
    80001fd4:	1000                	addi	s0,sp,32
    80001fd6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001fd8:	00000097          	auipc	ra,0x0
    80001fdc:	c78080e7          	jalr	-904(ra) # 80001c50 <myproc>
    80001fe0:	892a                	mv	s2,a0
  sz = p->sz;
    80001fe2:	752c                	ld	a1,104(a0)
    80001fe4:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001fe8:	00904f63          	bgtz	s1,80002006 <growproc+0x3c>
  } else if(n < 0){
    80001fec:	0204cd63          	bltz	s1,80002026 <growproc+0x5c>
  p->sz = sz;
    80001ff0:	1782                	slli	a5,a5,0x20
    80001ff2:	9381                	srli	a5,a5,0x20
    80001ff4:	06f93423          	sd	a5,104(s2)
  return 0;
    80001ff8:	4501                	li	a0,0
}
    80001ffa:	60e2                	ld	ra,24(sp)
    80001ffc:	6442                	ld	s0,16(sp)
    80001ffe:	64a2                	ld	s1,8(sp)
    80002000:	6902                	ld	s2,0(sp)
    80002002:	6105                	addi	sp,sp,32
    80002004:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002006:	00f4863b          	addw	a2,s1,a5
    8000200a:	1602                	slli	a2,a2,0x20
    8000200c:	9201                	srli	a2,a2,0x20
    8000200e:	1582                	slli	a1,a1,0x20
    80002010:	9181                	srli	a1,a1,0x20
    80002012:	7928                	ld	a0,112(a0)
    80002014:	fffff097          	auipc	ra,0xfffff
    80002018:	3f2080e7          	jalr	1010(ra) # 80001406 <uvmalloc>
    8000201c:	0005079b          	sext.w	a5,a0
    80002020:	fbe1                	bnez	a5,80001ff0 <growproc+0x26>
      return -1;
    80002022:	557d                	li	a0,-1
    80002024:	bfd9                	j	80001ffa <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002026:	00f4863b          	addw	a2,s1,a5
    8000202a:	1602                	slli	a2,a2,0x20
    8000202c:	9201                	srli	a2,a2,0x20
    8000202e:	1582                	slli	a1,a1,0x20
    80002030:	9181                	srli	a1,a1,0x20
    80002032:	7928                	ld	a0,112(a0)
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	38a080e7          	jalr	906(ra) # 800013be <uvmdealloc>
    8000203c:	0005079b          	sext.w	a5,a0
    80002040:	bf45                	j	80001ff0 <growproc+0x26>

0000000080002042 <fork>:
{
    80002042:	7139                	addi	sp,sp,-64
    80002044:	fc06                	sd	ra,56(sp)
    80002046:	f822                	sd	s0,48(sp)
    80002048:	f426                	sd	s1,40(sp)
    8000204a:	f04a                	sd	s2,32(sp)
    8000204c:	ec4e                	sd	s3,24(sp)
    8000204e:	e852                	sd	s4,16(sp)
    80002050:	e456                	sd	s5,8(sp)
    80002052:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002054:	00000097          	auipc	ra,0x0
    80002058:	bfc080e7          	jalr	-1028(ra) # 80001c50 <myproc>
    8000205c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    8000205e:	00000097          	auipc	ra,0x0
    80002062:	dfc080e7          	jalr	-516(ra) # 80001e5a <allocproc>
    80002066:	12050363          	beqz	a0,8000218c <fork+0x14a>
    8000206a:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000206c:	068ab603          	ld	a2,104(s5)
    80002070:	792c                	ld	a1,112(a0)
    80002072:	070ab503          	ld	a0,112(s5)
    80002076:	fffff097          	auipc	ra,0xfffff
    8000207a:	4e0080e7          	jalr	1248(ra) # 80001556 <uvmcopy>
    8000207e:	04054863          	bltz	a0,800020ce <fork+0x8c>
  np->sz = p->sz;
    80002082:	068ab783          	ld	a5,104(s5)
    80002086:	06f9b423          	sd	a5,104(s3)
  *(np->trapframe) = *(p->trapframe);
    8000208a:	078ab683          	ld	a3,120(s5)
    8000208e:	87b6                	mv	a5,a3
    80002090:	0789b703          	ld	a4,120(s3)
    80002094:	12068693          	addi	a3,a3,288
    80002098:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000209c:	6788                	ld	a0,8(a5)
    8000209e:	6b8c                	ld	a1,16(a5)
    800020a0:	6f90                	ld	a2,24(a5)
    800020a2:	01073023          	sd	a6,0(a4)
    800020a6:	e708                	sd	a0,8(a4)
    800020a8:	eb0c                	sd	a1,16(a4)
    800020aa:	ef10                	sd	a2,24(a4)
    800020ac:	02078793          	addi	a5,a5,32
    800020b0:	02070713          	addi	a4,a4,32
    800020b4:	fed792e3          	bne	a5,a3,80002098 <fork+0x56>
  np->trapframe->a0 = 0;
    800020b8:	0789b783          	ld	a5,120(s3)
    800020bc:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    800020c0:	0f0a8493          	addi	s1,s5,240
    800020c4:	0f098913          	addi	s2,s3,240
    800020c8:	170a8a13          	addi	s4,s5,368
    800020cc:	a00d                	j	800020ee <fork+0xac>
    freeproc(np);
    800020ce:	854e                	mv	a0,s3
    800020d0:	00000097          	auipc	ra,0x0
    800020d4:	d32080e7          	jalr	-718(ra) # 80001e02 <freeproc>
    release(&np->lock);
    800020d8:	854e                	mv	a0,s3
    800020da:	fffff097          	auipc	ra,0xfffff
    800020de:	baa080e7          	jalr	-1110(ra) # 80000c84 <release>
    return -1;
    800020e2:	597d                	li	s2,-1
    800020e4:	a851                	j	80002178 <fork+0x136>
  for(i = 0; i < NOFILE; i++)
    800020e6:	04a1                	addi	s1,s1,8
    800020e8:	0921                	addi	s2,s2,8
    800020ea:	01448b63          	beq	s1,s4,80002100 <fork+0xbe>
    if(p->ofile[i])
    800020ee:	6088                	ld	a0,0(s1)
    800020f0:	d97d                	beqz	a0,800020e6 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    800020f2:	00003097          	auipc	ra,0x3
    800020f6:	ba8080e7          	jalr	-1112(ra) # 80004c9a <filedup>
    800020fa:	00a93023          	sd	a0,0(s2)
    800020fe:	b7e5                	j	800020e6 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80002100:	170ab503          	ld	a0,368(s5)
    80002104:	00002097          	auipc	ra,0x2
    80002108:	d06080e7          	jalr	-762(ra) # 80003e0a <idup>
    8000210c:	16a9b823          	sd	a0,368(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002110:	4641                	li	a2,16
    80002112:	178a8593          	addi	a1,s5,376
    80002116:	17898513          	addi	a0,s3,376
    8000211a:	fffff097          	auipc	ra,0xfffff
    8000211e:	cfc080e7          	jalr	-772(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80002122:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80002126:	854e                	mv	a0,s3
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	b5c080e7          	jalr	-1188(ra) # 80000c84 <release>
  acquire(&wait_lock);
    80002130:	0000f497          	auipc	s1,0xf
    80002134:	21848493          	addi	s1,s1,536 # 80011348 <wait_lock>
    80002138:	8526                	mv	a0,s1
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	a96080e7          	jalr	-1386(ra) # 80000bd0 <acquire>
  np->parent = p;
    80002142:	0559bc23          	sd	s5,88(s3)
  release(&wait_lock);
    80002146:	8526                	mv	a0,s1
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	b3c080e7          	jalr	-1220(ra) # 80000c84 <release>
  acquire(&np->lock);
    80002150:	854e                	mv	a0,s3
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	a7e080e7          	jalr	-1410(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    8000215a:	478d                	li	a5,3
    8000215c:	00f9ac23          	sw	a5,24(s3)
  enqueue_at_tail(np, np->priority);
    80002160:	0449a583          	lw	a1,68(s3)
    80002164:	854e                	mv	a0,s3
    80002166:	fffff097          	auipc	ra,0xfffff
    8000216a:	6be080e7          	jalr	1726(ra) # 80001824 <enqueue_at_tail>
  release(&np->lock);
    8000216e:	854e                	mv	a0,s3
    80002170:	fffff097          	auipc	ra,0xfffff
    80002174:	b14080e7          	jalr	-1260(ra) # 80000c84 <release>
}
    80002178:	854a                	mv	a0,s2
    8000217a:	70e2                	ld	ra,56(sp)
    8000217c:	7442                	ld	s0,48(sp)
    8000217e:	74a2                	ld	s1,40(sp)
    80002180:	7902                	ld	s2,32(sp)
    80002182:	69e2                	ld	s3,24(sp)
    80002184:	6a42                	ld	s4,16(sp)
    80002186:	6aa2                	ld	s5,8(sp)
    80002188:	6121                	addi	sp,sp,64
    8000218a:	8082                	ret
    return -1;
    8000218c:	597d                	li	s2,-1
    8000218e:	b7ed                	j	80002178 <fork+0x136>

0000000080002190 <scheduler>:
{
    80002190:	715d                	addi	sp,sp,-80
    80002192:	e486                	sd	ra,72(sp)
    80002194:	e0a2                	sd	s0,64(sp)
    80002196:	fc26                	sd	s1,56(sp)
    80002198:	f84a                	sd	s2,48(sp)
    8000219a:	f44e                	sd	s3,40(sp)
    8000219c:	f052                	sd	s4,32(sp)
    8000219e:	ec56                	sd	s5,24(sp)
    800021a0:	e85a                	sd	s6,16(sp)
    800021a2:	e45e                	sd	s7,8(sp)
    800021a4:	0880                	addi	s0,sp,80
    800021a6:	8792                	mv	a5,tp
  int id = r_tp();
    800021a8:	2781                	sext.w	a5,a5
  c->proc = 0;
    800021aa:	00779a93          	slli	s5,a5,0x7
    800021ae:	0000f717          	auipc	a4,0xf
    800021b2:	0f270713          	addi	a4,a4,242 # 800112a0 <queue>
    800021b6:	9756                	add	a4,a4,s5
    800021b8:	0c073023          	sd	zero,192(a4)
          swtch(&c->context, &p->context);
    800021bc:	0000f717          	auipc	a4,0xf
    800021c0:	1ac70713          	addi	a4,a4,428 # 80011368 <cpus+0x8>
    800021c4:	9aba                	add	s5,s5,a4
    if(sched_policy == RR) {
    800021c6:	00006b97          	auipc	s7,0x6
    800021ca:	6d2b8b93          	addi	s7,s7,1746 # 80008898 <sched_policy>
          p->state = RUNNING;
    800021ce:	4b11                	li	s6,4
          c->proc = p;
    800021d0:	079e                	slli	a5,a5,0x7
    800021d2:	0000fa17          	auipc	s4,0xf
    800021d6:	0cea0a13          	addi	s4,s4,206 # 800112a0 <queue>
    800021da:	9a3e                	add	s4,s4,a5
      for(p = proc; p < &proc[NPROC]; p++) {
    800021dc:	00015997          	auipc	s3,0x15
    800021e0:	78498993          	addi	s3,s3,1924 # 80017960 <tickslock>
    800021e4:	a099                	j	8000222a <scheduler+0x9a>
        release(&p->lock);
    800021e6:	8526                	mv	a0,s1
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	a9c080e7          	jalr	-1380(ra) # 80000c84 <release>
      for(p = proc; p < &proc[NPROC]; p++) {
    800021f0:	18848493          	addi	s1,s1,392
    800021f4:	03348b63          	beq	s1,s3,8000222a <scheduler+0x9a>
        acquire(&p->lock);
    800021f8:	8526                	mv	a0,s1
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	9d6080e7          	jalr	-1578(ra) # 80000bd0 <acquire>
        if(p->state == RUNNABLE) {
    80002202:	4c9c                	lw	a5,24(s1)
    80002204:	ff2791e3          	bne	a5,s2,800021e6 <scheduler+0x56>
          p->state = RUNNING;
    80002208:	0164ac23          	sw	s6,24(s1)
          c->proc = p;
    8000220c:	0c9a3023          	sd	s1,192(s4)
          swtch(&c->context, &p->context);
    80002210:	08048593          	addi	a1,s1,128
    80002214:	8556                	mv	a0,s5
    80002216:	00001097          	auipc	ra,0x1
    8000221a:	96c080e7          	jalr	-1684(ra) # 80002b82 <swtch>
          c->proc = 0;
    8000221e:	0c0a3023          	sd	zero,192(s4)
    80002222:	b7d1                	j	800021e6 <scheduler+0x56>
    } else if(sched_policy == MLFQ) {
    80002224:	4705                	li	a4,1
    80002226:	02e78163          	beq	a5,a4,80002248 <scheduler+0xb8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000222a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000222e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002232:	10079073          	csrw	sstatus,a5
    if(sched_policy == RR) {
    80002236:	000ba783          	lw	a5,0(s7)
    8000223a:	f7ed                	bnez	a5,80002224 <scheduler+0x94>
      for(p = proc; p < &proc[NPROC]; p++) {
    8000223c:	0000f497          	auipc	s1,0xf
    80002240:	52448493          	addi	s1,s1,1316 # 80011760 <proc>
        if(p->state == RUNNABLE) {
    80002244:	490d                	li	s2,3
    80002246:	bf4d                	j	800021f8 <scheduler+0x68>
      p = dequeue(HIGH);
    80002248:	4501                	li	a0,0
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	6c8080e7          	jalr	1736(ra) # 80001912 <dequeue>
    80002252:	84aa                	mv	s1,a0
      if(!p)
    80002254:	c10d                	beqz	a0,80002276 <scheduler+0xe6>
        acquire(&p->lock);
    80002256:	8926                	mv	s2,s1
    80002258:	8526                	mv	a0,s1
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	976080e7          	jalr	-1674(ra) # 80000bd0 <acquire>
        if(p->state == RUNNABLE){;
    80002262:	4c98                	lw	a4,24(s1)
    80002264:	478d                	li	a5,3
    80002266:	02f70763          	beq	a4,a5,80002294 <scheduler+0x104>
        release(&p->lock);
    8000226a:	854a                	mv	a0,s2
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	a18080e7          	jalr	-1512(ra) # 80000c84 <release>
    80002274:	bf5d                	j	8000222a <scheduler+0x9a>
        p = dequeue(MEDIUM);
    80002276:	4505                	li	a0,1
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	69a080e7          	jalr	1690(ra) # 80001912 <dequeue>
    80002280:	84aa                	mv	s1,a0
      if(!p)
    80002282:	f971                	bnez	a0,80002256 <scheduler+0xc6>
        p = dequeue(LOW);
    80002284:	4509                	li	a0,2
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	68c080e7          	jalr	1676(ra) # 80001912 <dequeue>
    8000228e:	84aa                	mv	s1,a0
      if(p){
    80002290:	dd49                	beqz	a0,8000222a <scheduler+0x9a>
    80002292:	b7d1                	j	80002256 <scheduler+0xc6>
          p->state = RUNNING;
    80002294:	0164ac23          	sw	s6,24(s1)
          c->proc = p;
    80002298:	0c9a3023          	sd	s1,192(s4)
          swtch(&c->context, &p->context);
    8000229c:	08048593          	addi	a1,s1,128
    800022a0:	8556                	mv	a0,s5
    800022a2:	00001097          	auipc	ra,0x1
    800022a6:	8e0080e7          	jalr	-1824(ra) # 80002b82 <swtch>
          c->proc = 0;
    800022aa:	0c0a3023          	sd	zero,192(s4)
    800022ae:	bf75                	j	8000226a <scheduler+0xda>

00000000800022b0 <sched>:
{
    800022b0:	7179                	addi	sp,sp,-48
    800022b2:	f406                	sd	ra,40(sp)
    800022b4:	f022                	sd	s0,32(sp)
    800022b6:	ec26                	sd	s1,24(sp)
    800022b8:	e84a                	sd	s2,16(sp)
    800022ba:	e44e                	sd	s3,8(sp)
    800022bc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800022be:	00000097          	auipc	ra,0x0
    800022c2:	992080e7          	jalr	-1646(ra) # 80001c50 <myproc>
    800022c6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	88e080e7          	jalr	-1906(ra) # 80000b56 <holding>
    800022d0:	c93d                	beqz	a0,80002346 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022d2:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800022d4:	2781                	sext.w	a5,a5
    800022d6:	079e                	slli	a5,a5,0x7
    800022d8:	0000f717          	auipc	a4,0xf
    800022dc:	fc870713          	addi	a4,a4,-56 # 800112a0 <queue>
    800022e0:	97ba                	add	a5,a5,a4
    800022e2:	1387a703          	lw	a4,312(a5)
    800022e6:	4785                	li	a5,1
    800022e8:	06f71763          	bne	a4,a5,80002356 <sched+0xa6>
  if(p->state == RUNNING)
    800022ec:	4c98                	lw	a4,24(s1)
    800022ee:	4791                	li	a5,4
    800022f0:	06f70b63          	beq	a4,a5,80002366 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022f4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022f8:	8b89                	andi	a5,a5,2
  if(intr_get())
    800022fa:	efb5                	bnez	a5,80002376 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022fc:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022fe:	0000f917          	auipc	s2,0xf
    80002302:	fa290913          	addi	s2,s2,-94 # 800112a0 <queue>
    80002306:	2781                	sext.w	a5,a5
    80002308:	079e                	slli	a5,a5,0x7
    8000230a:	97ca                	add	a5,a5,s2
    8000230c:	13c7a983          	lw	s3,316(a5)
    80002310:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002312:	2781                	sext.w	a5,a5
    80002314:	079e                	slli	a5,a5,0x7
    80002316:	0000f597          	auipc	a1,0xf
    8000231a:	05258593          	addi	a1,a1,82 # 80011368 <cpus+0x8>
    8000231e:	95be                	add	a1,a1,a5
    80002320:	08048513          	addi	a0,s1,128
    80002324:	00001097          	auipc	ra,0x1
    80002328:	85e080e7          	jalr	-1954(ra) # 80002b82 <swtch>
    8000232c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000232e:	2781                	sext.w	a5,a5
    80002330:	079e                	slli	a5,a5,0x7
    80002332:	993e                	add	s2,s2,a5
    80002334:	13392e23          	sw	s3,316(s2)
}
    80002338:	70a2                	ld	ra,40(sp)
    8000233a:	7402                	ld	s0,32(sp)
    8000233c:	64e2                	ld	s1,24(sp)
    8000233e:	6942                	ld	s2,16(sp)
    80002340:	69a2                	ld	s3,8(sp)
    80002342:	6145                	addi	sp,sp,48
    80002344:	8082                	ret
    panic("sched p->lock");
    80002346:	00006517          	auipc	a0,0x6
    8000234a:	f3250513          	addi	a0,a0,-206 # 80008278 <digits+0x238>
    8000234e:	ffffe097          	auipc	ra,0xffffe
    80002352:	1ec080e7          	jalr	492(ra) # 8000053a <panic>
    panic("sched locks");
    80002356:	00006517          	auipc	a0,0x6
    8000235a:	f3250513          	addi	a0,a0,-206 # 80008288 <digits+0x248>
    8000235e:	ffffe097          	auipc	ra,0xffffe
    80002362:	1dc080e7          	jalr	476(ra) # 8000053a <panic>
    panic("sched running");
    80002366:	00006517          	auipc	a0,0x6
    8000236a:	f3250513          	addi	a0,a0,-206 # 80008298 <digits+0x258>
    8000236e:	ffffe097          	auipc	ra,0xffffe
    80002372:	1cc080e7          	jalr	460(ra) # 8000053a <panic>
    panic("sched interruptible");
    80002376:	00006517          	auipc	a0,0x6
    8000237a:	f3250513          	addi	a0,a0,-206 # 800082a8 <digits+0x268>
    8000237e:	ffffe097          	auipc	ra,0xffffe
    80002382:	1bc080e7          	jalr	444(ra) # 8000053a <panic>

0000000080002386 <yield>:
{
    80002386:	1101                	addi	sp,sp,-32
    80002388:	ec06                	sd	ra,24(sp)
    8000238a:	e822                	sd	s0,16(sp)
    8000238c:	e426                	sd	s1,8(sp)
    8000238e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002390:	00000097          	auipc	ra,0x0
    80002394:	8c0080e7          	jalr	-1856(ra) # 80001c50 <myproc>
    80002398:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	836080e7          	jalr	-1994(ra) # 80000bd0 <acquire>
  p->state = RUNNABLE;
    800023a2:	478d                	li	a5,3
    800023a4:	cc9c                	sw	a5,24(s1)
  enqueue_at_tail(p, p->priority);
    800023a6:	40ec                	lw	a1,68(s1)
    800023a8:	8526                	mv	a0,s1
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	47a080e7          	jalr	1146(ra) # 80001824 <enqueue_at_tail>
  sched();
    800023b2:	00000097          	auipc	ra,0x0
    800023b6:	efe080e7          	jalr	-258(ra) # 800022b0 <sched>
  release(&p->lock);
    800023ba:	8526                	mv	a0,s1
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	8c8080e7          	jalr	-1848(ra) # 80000c84 <release>
}
    800023c4:	60e2                	ld	ra,24(sp)
    800023c6:	6442                	ld	s0,16(sp)
    800023c8:	64a2                	ld	s1,8(sp)
    800023ca:	6105                	addi	sp,sp,32
    800023cc:	8082                	ret

00000000800023ce <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800023ce:	7179                	addi	sp,sp,-48
    800023d0:	f406                	sd	ra,40(sp)
    800023d2:	f022                	sd	s0,32(sp)
    800023d4:	ec26                	sd	s1,24(sp)
    800023d6:	e84a                	sd	s2,16(sp)
    800023d8:	e44e                	sd	s3,8(sp)
    800023da:	1800                	addi	s0,sp,48
    800023dc:	89aa                	mv	s3,a0
    800023de:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800023e0:	00000097          	auipc	ra,0x0
    800023e4:	870080e7          	jalr	-1936(ra) # 80001c50 <myproc>
    800023e8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800023ea:	ffffe097          	auipc	ra,0xffffe
    800023ee:	7e6080e7          	jalr	2022(ra) # 80000bd0 <acquire>
  release(lk);
    800023f2:	854a                	mv	a0,s2
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	890080e7          	jalr	-1904(ra) # 80000c84 <release>

  // Go to sleep.
  p->chan = chan;
    800023fc:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002400:	4789                	li	a5,2
    80002402:	cc9c                	sw	a5,24(s1)

  sched();
    80002404:	00000097          	auipc	ra,0x0
    80002408:	eac080e7          	jalr	-340(ra) # 800022b0 <sched>

  // Tidy up.
  p->chan = 0;
    8000240c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002410:	8526                	mv	a0,s1
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	872080e7          	jalr	-1934(ra) # 80000c84 <release>
  acquire(lk);
    8000241a:	854a                	mv	a0,s2
    8000241c:	ffffe097          	auipc	ra,0xffffe
    80002420:	7b4080e7          	jalr	1972(ra) # 80000bd0 <acquire>
}
    80002424:	70a2                	ld	ra,40(sp)
    80002426:	7402                	ld	s0,32(sp)
    80002428:	64e2                	ld	s1,24(sp)
    8000242a:	6942                	ld	s2,16(sp)
    8000242c:	69a2                	ld	s3,8(sp)
    8000242e:	6145                	addi	sp,sp,48
    80002430:	8082                	ret

0000000080002432 <wait>:
{
    80002432:	715d                	addi	sp,sp,-80
    80002434:	e486                	sd	ra,72(sp)
    80002436:	e0a2                	sd	s0,64(sp)
    80002438:	fc26                	sd	s1,56(sp)
    8000243a:	f84a                	sd	s2,48(sp)
    8000243c:	f44e                	sd	s3,40(sp)
    8000243e:	f052                	sd	s4,32(sp)
    80002440:	ec56                	sd	s5,24(sp)
    80002442:	e85a                	sd	s6,16(sp)
    80002444:	e45e                	sd	s7,8(sp)
    80002446:	e062                	sd	s8,0(sp)
    80002448:	0880                	addi	s0,sp,80
    8000244a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000244c:	00000097          	auipc	ra,0x0
    80002450:	804080e7          	jalr	-2044(ra) # 80001c50 <myproc>
    80002454:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002456:	0000f517          	auipc	a0,0xf
    8000245a:	ef250513          	addi	a0,a0,-270 # 80011348 <wait_lock>
    8000245e:	ffffe097          	auipc	ra,0xffffe
    80002462:	772080e7          	jalr	1906(ra) # 80000bd0 <acquire>
    havekids = 0;
    80002466:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002468:	4a15                	li	s4,5
        havekids = 1;
    8000246a:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    8000246c:	00015997          	auipc	s3,0x15
    80002470:	4f498993          	addi	s3,s3,1268 # 80017960 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002474:	0000fc17          	auipc	s8,0xf
    80002478:	ed4c0c13          	addi	s8,s8,-300 # 80011348 <wait_lock>
    havekids = 0;
    8000247c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000247e:	0000f497          	auipc	s1,0xf
    80002482:	2e248493          	addi	s1,s1,738 # 80011760 <proc>
    80002486:	a0bd                	j	800024f4 <wait+0xc2>
          pid = np->pid;
    80002488:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000248c:	000b0e63          	beqz	s6,800024a8 <wait+0x76>
    80002490:	4691                	li	a3,4
    80002492:	02c48613          	addi	a2,s1,44
    80002496:	85da                	mv	a1,s6
    80002498:	07093503          	ld	a0,112(s2)
    8000249c:	fffff097          	auipc	ra,0xfffff
    800024a0:	1be080e7          	jalr	446(ra) # 8000165a <copyout>
    800024a4:	02054563          	bltz	a0,800024ce <wait+0x9c>
          freeproc(np);
    800024a8:	8526                	mv	a0,s1
    800024aa:	00000097          	auipc	ra,0x0
    800024ae:	958080e7          	jalr	-1704(ra) # 80001e02 <freeproc>
          release(&np->lock);
    800024b2:	8526                	mv	a0,s1
    800024b4:	ffffe097          	auipc	ra,0xffffe
    800024b8:	7d0080e7          	jalr	2000(ra) # 80000c84 <release>
          release(&wait_lock);
    800024bc:	0000f517          	auipc	a0,0xf
    800024c0:	e8c50513          	addi	a0,a0,-372 # 80011348 <wait_lock>
    800024c4:	ffffe097          	auipc	ra,0xffffe
    800024c8:	7c0080e7          	jalr	1984(ra) # 80000c84 <release>
          return pid;
    800024cc:	a09d                	j	80002532 <wait+0x100>
            release(&np->lock);
    800024ce:	8526                	mv	a0,s1
    800024d0:	ffffe097          	auipc	ra,0xffffe
    800024d4:	7b4080e7          	jalr	1972(ra) # 80000c84 <release>
            release(&wait_lock);
    800024d8:	0000f517          	auipc	a0,0xf
    800024dc:	e7050513          	addi	a0,a0,-400 # 80011348 <wait_lock>
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	7a4080e7          	jalr	1956(ra) # 80000c84 <release>
            return -1;
    800024e8:	59fd                	li	s3,-1
    800024ea:	a0a1                	j	80002532 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800024ec:	18848493          	addi	s1,s1,392
    800024f0:	03348463          	beq	s1,s3,80002518 <wait+0xe6>
      if(np->parent == p){
    800024f4:	6cbc                	ld	a5,88(s1)
    800024f6:	ff279be3          	bne	a5,s2,800024ec <wait+0xba>
        acquire(&np->lock);
    800024fa:	8526                	mv	a0,s1
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	6d4080e7          	jalr	1748(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    80002504:	4c9c                	lw	a5,24(s1)
    80002506:	f94781e3          	beq	a5,s4,80002488 <wait+0x56>
        release(&np->lock);
    8000250a:	8526                	mv	a0,s1
    8000250c:	ffffe097          	auipc	ra,0xffffe
    80002510:	778080e7          	jalr	1912(ra) # 80000c84 <release>
        havekids = 1;
    80002514:	8756                	mv	a4,s5
    80002516:	bfd9                	j	800024ec <wait+0xba>
    if(!havekids || p->killed){
    80002518:	c701                	beqz	a4,80002520 <wait+0xee>
    8000251a:	02892783          	lw	a5,40(s2)
    8000251e:	c79d                	beqz	a5,8000254c <wait+0x11a>
      release(&wait_lock);
    80002520:	0000f517          	auipc	a0,0xf
    80002524:	e2850513          	addi	a0,a0,-472 # 80011348 <wait_lock>
    80002528:	ffffe097          	auipc	ra,0xffffe
    8000252c:	75c080e7          	jalr	1884(ra) # 80000c84 <release>
      return -1;
    80002530:	59fd                	li	s3,-1
}
    80002532:	854e                	mv	a0,s3
    80002534:	60a6                	ld	ra,72(sp)
    80002536:	6406                	ld	s0,64(sp)
    80002538:	74e2                	ld	s1,56(sp)
    8000253a:	7942                	ld	s2,48(sp)
    8000253c:	79a2                	ld	s3,40(sp)
    8000253e:	7a02                	ld	s4,32(sp)
    80002540:	6ae2                	ld	s5,24(sp)
    80002542:	6b42                	ld	s6,16(sp)
    80002544:	6ba2                	ld	s7,8(sp)
    80002546:	6c02                	ld	s8,0(sp)
    80002548:	6161                	addi	sp,sp,80
    8000254a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000254c:	85e2                	mv	a1,s8
    8000254e:	854a                	mv	a0,s2
    80002550:	00000097          	auipc	ra,0x0
    80002554:	e7e080e7          	jalr	-386(ra) # 800023ce <sleep>
    havekids = 0;
    80002558:	b715                	j	8000247c <wait+0x4a>

000000008000255a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000255a:	711d                	addi	sp,sp,-96
    8000255c:	ec86                	sd	ra,88(sp)
    8000255e:	e8a2                	sd	s0,80(sp)
    80002560:	e4a6                	sd	s1,72(sp)
    80002562:	e0ca                	sd	s2,64(sp)
    80002564:	fc4e                	sd	s3,56(sp)
    80002566:	f852                	sd	s4,48(sp)
    80002568:	f456                	sd	s5,40(sp)
    8000256a:	f05a                	sd	s6,32(sp)
    8000256c:	ec5e                	sd	s7,24(sp)
    8000256e:	e862                	sd	s8,16(sp)
    80002570:	e466                	sd	s9,8(sp)
    80002572:	1080                	addi	s0,sp,96
    80002574:	8aaa                	mv	s5,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002576:	0000f497          	auipc	s1,0xf
    8000257a:	1ea48493          	addi	s1,s1,490 # 80011760 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000257e:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002580:	4c0d                	li	s8,3
  if (!(p >= proc && p < &proc[NPROC]))
    80002582:	8ba6                	mv	s7,s1
  acquire(&queue[priority].lock);
    80002584:	0000fb17          	auipc	s6,0xf
    80002588:	d1cb0b13          	addi	s6,s6,-740 # 800112a0 <queue>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000258c:	00015917          	auipc	s2,0x15
    80002590:	3d490913          	addi	s2,s2,980 # 80017960 <tickslock>
    80002594:	a085                	j	800025f4 <wakeup+0x9a>
    panic("enqueue_at_head");
    80002596:	00006517          	auipc	a0,0x6
    8000259a:	d2a50513          	addi	a0,a0,-726 # 800082c0 <digits+0x280>
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	f9c080e7          	jalr	-100(ra) # 8000053a <panic>
    panic("enqueue_at_head");
    800025a6:	00006517          	auipc	a0,0x6
    800025aa:	d1a50513          	addi	a0,a0,-742 # 800082c0 <digits+0x280>
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	f8c080e7          	jalr	-116(ra) # 8000053a <panic>
    queue[priority].head = p;
    800025b6:	029a3023          	sd	s1,32(s4)
    queue[priority].tail = p;
    800025ba:	029a3423          	sd	s1,40(s4)
    release(&queue[priority].lock);
    800025be:	8552                	mv	a0,s4
    800025c0:	ffffe097          	auipc	ra,0xffffe
    800025c4:	6c4080e7          	jalr	1732(ra) # 80000c84 <release>
    return(0);
    800025c8:	a829                	j	800025e2 <wakeup+0x88>
  p->next = queue[priority].head;
    800025ca:	e8bc                	sd	a5,80(s1)
  queue[priority].head = p;
    800025cc:	001c9793          	slli	a5,s9,0x1
    800025d0:	97e6                	add	a5,a5,s9
    800025d2:	0792                	slli	a5,a5,0x4
    800025d4:	97da                	add	a5,a5,s6
    800025d6:	f384                	sd	s1,32(a5)
  release(&queue[priority].lock);
    800025d8:	8552                	mv	a0,s4
    800025da:	ffffe097          	auipc	ra,0xffffe
    800025de:	6aa080e7          	jalr	1706(ra) # 80000c84 <release>
        //Determine if this is the correct behavior
        enqueue_at_head(p, p->priority);
      }
      release(&p->lock);
    800025e2:	8526                	mv	a0,s1
    800025e4:	ffffe097          	auipc	ra,0xffffe
    800025e8:	6a0080e7          	jalr	1696(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800025ec:	18848493          	addi	s1,s1,392
    800025f0:	07248863          	beq	s1,s2,80002660 <wakeup+0x106>
    if(p != myproc()){
    800025f4:	fffff097          	auipc	ra,0xfffff
    800025f8:	65c080e7          	jalr	1628(ra) # 80001c50 <myproc>
    800025fc:	fea488e3          	beq	s1,a0,800025ec <wakeup+0x92>
      acquire(&p->lock);
    80002600:	8526                	mv	a0,s1
    80002602:	ffffe097          	auipc	ra,0xffffe
    80002606:	5ce080e7          	jalr	1486(ra) # 80000bd0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000260a:	4c9c                	lw	a5,24(s1)
    8000260c:	fd379be3          	bne	a5,s3,800025e2 <wakeup+0x88>
    80002610:	709c                	ld	a5,32(s1)
    80002612:	fd5798e3          	bne	a5,s5,800025e2 <wakeup+0x88>
        p->state = RUNNABLE;
    80002616:	0184ac23          	sw	s8,24(s1)
        enqueue_at_head(p, p->priority);
    8000261a:	0444ac83          	lw	s9,68(s1)
  if (!(p >= proc && p < &proc[NPROC]))
    8000261e:	f774ece3          	bltu	s1,s7,80002596 <wakeup+0x3c>
  if (!(priority >= 0) && (priority < NQUEUE))
    80002622:	f80cc2e3          	bltz	s9,800025a6 <wakeup+0x4c>
  acquire(&queue[priority].lock);
    80002626:	001c9a13          	slli	s4,s9,0x1
    8000262a:	9a66                	add	s4,s4,s9
    8000262c:	0a12                	slli	s4,s4,0x4
    8000262e:	9a5a                	add	s4,s4,s6
    80002630:	8552                	mv	a0,s4
    80002632:	ffffe097          	auipc	ra,0xffffe
    80002636:	59e080e7          	jalr	1438(ra) # 80000bd0 <acquire>
  if ((queue[priority].head == 0) && (queue[priority].tail == 0)) {
    8000263a:	020a3783          	ld	a5,32(s4)
    8000263e:	f7d1                	bnez	a5,800025ca <wakeup+0x70>
    80002640:	028a3783          	ld	a5,40(s4)
    80002644:	dbad                	beqz	a5,800025b6 <wakeup+0x5c>
    release(&queue[priority].lock);
    80002646:	8552                	mv	a0,s4
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	63c080e7          	jalr	1596(ra) # 80000c84 <release>
    panic("enqueue_at_head");
    80002650:	00006517          	auipc	a0,0x6
    80002654:	c7050513          	addi	a0,a0,-912 # 800082c0 <digits+0x280>
    80002658:	ffffe097          	auipc	ra,0xffffe
    8000265c:	ee2080e7          	jalr	-286(ra) # 8000053a <panic>
    }
  }
}
    80002660:	60e6                	ld	ra,88(sp)
    80002662:	6446                	ld	s0,80(sp)
    80002664:	64a6                	ld	s1,72(sp)
    80002666:	6906                	ld	s2,64(sp)
    80002668:	79e2                	ld	s3,56(sp)
    8000266a:	7a42                	ld	s4,48(sp)
    8000266c:	7aa2                	ld	s5,40(sp)
    8000266e:	7b02                	ld	s6,32(sp)
    80002670:	6be2                	ld	s7,24(sp)
    80002672:	6c42                	ld	s8,16(sp)
    80002674:	6ca2                	ld	s9,8(sp)
    80002676:	6125                	addi	sp,sp,96
    80002678:	8082                	ret

000000008000267a <reparent>:
{
    8000267a:	7179                	addi	sp,sp,-48
    8000267c:	f406                	sd	ra,40(sp)
    8000267e:	f022                	sd	s0,32(sp)
    80002680:	ec26                	sd	s1,24(sp)
    80002682:	e84a                	sd	s2,16(sp)
    80002684:	e44e                	sd	s3,8(sp)
    80002686:	e052                	sd	s4,0(sp)
    80002688:	1800                	addi	s0,sp,48
    8000268a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000268c:	0000f497          	auipc	s1,0xf
    80002690:	0d448493          	addi	s1,s1,212 # 80011760 <proc>
      pp->parent = initproc;
    80002694:	00007a17          	auipc	s4,0x7
    80002698:	994a0a13          	addi	s4,s4,-1644 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000269c:	00015997          	auipc	s3,0x15
    800026a0:	2c498993          	addi	s3,s3,708 # 80017960 <tickslock>
    800026a4:	a029                	j	800026ae <reparent+0x34>
    800026a6:	18848493          	addi	s1,s1,392
    800026aa:	01348d63          	beq	s1,s3,800026c4 <reparent+0x4a>
    if(pp->parent == p){
    800026ae:	6cbc                	ld	a5,88(s1)
    800026b0:	ff279be3          	bne	a5,s2,800026a6 <reparent+0x2c>
      pp->parent = initproc;
    800026b4:	000a3503          	ld	a0,0(s4)
    800026b8:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    800026ba:	00000097          	auipc	ra,0x0
    800026be:	ea0080e7          	jalr	-352(ra) # 8000255a <wakeup>
    800026c2:	b7d5                	j	800026a6 <reparent+0x2c>
}
    800026c4:	70a2                	ld	ra,40(sp)
    800026c6:	7402                	ld	s0,32(sp)
    800026c8:	64e2                	ld	s1,24(sp)
    800026ca:	6942                	ld	s2,16(sp)
    800026cc:	69a2                	ld	s3,8(sp)
    800026ce:	6a02                	ld	s4,0(sp)
    800026d0:	6145                	addi	sp,sp,48
    800026d2:	8082                	ret

00000000800026d4 <exit>:
{
    800026d4:	7179                	addi	sp,sp,-48
    800026d6:	f406                	sd	ra,40(sp)
    800026d8:	f022                	sd	s0,32(sp)
    800026da:	ec26                	sd	s1,24(sp)
    800026dc:	e84a                	sd	s2,16(sp)
    800026de:	e44e                	sd	s3,8(sp)
    800026e0:	e052                	sd	s4,0(sp)
    800026e2:	1800                	addi	s0,sp,48
    800026e4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800026e6:	fffff097          	auipc	ra,0xfffff
    800026ea:	56a080e7          	jalr	1386(ra) # 80001c50 <myproc>
    800026ee:	89aa                	mv	s3,a0
  if(p == initproc)
    800026f0:	00007797          	auipc	a5,0x7
    800026f4:	9387b783          	ld	a5,-1736(a5) # 80009028 <initproc>
    800026f8:	0f050493          	addi	s1,a0,240
    800026fc:	17050913          	addi	s2,a0,368
    80002700:	02a79363          	bne	a5,a0,80002726 <exit+0x52>
    panic("init exiting");
    80002704:	00006517          	auipc	a0,0x6
    80002708:	bcc50513          	addi	a0,a0,-1076 # 800082d0 <digits+0x290>
    8000270c:	ffffe097          	auipc	ra,0xffffe
    80002710:	e2e080e7          	jalr	-466(ra) # 8000053a <panic>
      fileclose(f);
    80002714:	00002097          	auipc	ra,0x2
    80002718:	5d8080e7          	jalr	1496(ra) # 80004cec <fileclose>
      p->ofile[fd] = 0;
    8000271c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002720:	04a1                	addi	s1,s1,8
    80002722:	01248563          	beq	s1,s2,8000272c <exit+0x58>
    if(p->ofile[fd]){
    80002726:	6088                	ld	a0,0(s1)
    80002728:	f575                	bnez	a0,80002714 <exit+0x40>
    8000272a:	bfdd                	j	80002720 <exit+0x4c>
  begin_op();
    8000272c:	00002097          	auipc	ra,0x2
    80002730:	0f8080e7          	jalr	248(ra) # 80004824 <begin_op>
  iput(p->cwd);
    80002734:	1709b503          	ld	a0,368(s3)
    80002738:	00002097          	auipc	ra,0x2
    8000273c:	8ca080e7          	jalr	-1846(ra) # 80004002 <iput>
  end_op();
    80002740:	00002097          	auipc	ra,0x2
    80002744:	162080e7          	jalr	354(ra) # 800048a2 <end_op>
  p->cwd = 0;
    80002748:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    8000274c:	0000f497          	auipc	s1,0xf
    80002750:	bfc48493          	addi	s1,s1,-1028 # 80011348 <wait_lock>
    80002754:	8526                	mv	a0,s1
    80002756:	ffffe097          	auipc	ra,0xffffe
    8000275a:	47a080e7          	jalr	1146(ra) # 80000bd0 <acquire>
  reparent(p);
    8000275e:	854e                	mv	a0,s3
    80002760:	00000097          	auipc	ra,0x0
    80002764:	f1a080e7          	jalr	-230(ra) # 8000267a <reparent>
  wakeup(p->parent);
    80002768:	0589b503          	ld	a0,88(s3)
    8000276c:	00000097          	auipc	ra,0x0
    80002770:	dee080e7          	jalr	-530(ra) # 8000255a <wakeup>
  acquire(&p->lock);
    80002774:	854e                	mv	a0,s3
    80002776:	ffffe097          	auipc	ra,0xffffe
    8000277a:	45a080e7          	jalr	1114(ra) # 80000bd0 <acquire>
  p->xstate = status;
    8000277e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002782:	4795                	li	a5,5
    80002784:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002788:	8526                	mv	a0,s1
    8000278a:	ffffe097          	auipc	ra,0xffffe
    8000278e:	4fa080e7          	jalr	1274(ra) # 80000c84 <release>
  sched();
    80002792:	00000097          	auipc	ra,0x0
    80002796:	b1e080e7          	jalr	-1250(ra) # 800022b0 <sched>
  panic("zombie exit");
    8000279a:	00006517          	auipc	a0,0x6
    8000279e:	b4650513          	addi	a0,a0,-1210 # 800082e0 <digits+0x2a0>
    800027a2:	ffffe097          	auipc	ra,0xffffe
    800027a6:	d98080e7          	jalr	-616(ra) # 8000053a <panic>

00000000800027aa <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800027aa:	7179                	addi	sp,sp,-48
    800027ac:	f406                	sd	ra,40(sp)
    800027ae:	f022                	sd	s0,32(sp)
    800027b0:	ec26                	sd	s1,24(sp)
    800027b2:	e84a                	sd	s2,16(sp)
    800027b4:	e44e                	sd	s3,8(sp)
    800027b6:	1800                	addi	s0,sp,48
    800027b8:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800027ba:	0000f497          	auipc	s1,0xf
    800027be:	fa648493          	addi	s1,s1,-90 # 80011760 <proc>
    800027c2:	00015997          	auipc	s3,0x15
    800027c6:	19e98993          	addi	s3,s3,414 # 80017960 <tickslock>
    acquire(&p->lock);
    800027ca:	8526                	mv	a0,s1
    800027cc:	ffffe097          	auipc	ra,0xffffe
    800027d0:	404080e7          	jalr	1028(ra) # 80000bd0 <acquire>
    if(p->pid == pid){
    800027d4:	589c                	lw	a5,48(s1)
    800027d6:	01278d63          	beq	a5,s2,800027f0 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800027da:	8526                	mv	a0,s1
    800027dc:	ffffe097          	auipc	ra,0xffffe
    800027e0:	4a8080e7          	jalr	1192(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800027e4:	18848493          	addi	s1,s1,392
    800027e8:	ff3491e3          	bne	s1,s3,800027ca <kill+0x20>
  }
  return -1;
    800027ec:	557d                	li	a0,-1
    800027ee:	a829                	j	80002808 <kill+0x5e>
      p->killed = 1;
    800027f0:	4785                	li	a5,1
    800027f2:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800027f4:	4c98                	lw	a4,24(s1)
    800027f6:	4789                	li	a5,2
    800027f8:	00f70f63          	beq	a4,a5,80002816 <kill+0x6c>
      release(&p->lock);
    800027fc:	8526                	mv	a0,s1
    800027fe:	ffffe097          	auipc	ra,0xffffe
    80002802:	486080e7          	jalr	1158(ra) # 80000c84 <release>
      return 0;
    80002806:	4501                	li	a0,0
}
    80002808:	70a2                	ld	ra,40(sp)
    8000280a:	7402                	ld	s0,32(sp)
    8000280c:	64e2                	ld	s1,24(sp)
    8000280e:	6942                	ld	s2,16(sp)
    80002810:	69a2                	ld	s3,8(sp)
    80002812:	6145                	addi	sp,sp,48
    80002814:	8082                	ret
        p->state = RUNNABLE;
    80002816:	478d                	li	a5,3
    80002818:	cc9c                	sw	a5,24(s1)
    8000281a:	b7cd                	j	800027fc <kill+0x52>

000000008000281c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000281c:	7179                	addi	sp,sp,-48
    8000281e:	f406                	sd	ra,40(sp)
    80002820:	f022                	sd	s0,32(sp)
    80002822:	ec26                	sd	s1,24(sp)
    80002824:	e84a                	sd	s2,16(sp)
    80002826:	e44e                	sd	s3,8(sp)
    80002828:	e052                	sd	s4,0(sp)
    8000282a:	1800                	addi	s0,sp,48
    8000282c:	84aa                	mv	s1,a0
    8000282e:	892e                	mv	s2,a1
    80002830:	89b2                	mv	s3,a2
    80002832:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002834:	fffff097          	auipc	ra,0xfffff
    80002838:	41c080e7          	jalr	1052(ra) # 80001c50 <myproc>
  if(user_dst){
    8000283c:	c08d                	beqz	s1,8000285e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000283e:	86d2                	mv	a3,s4
    80002840:	864e                	mv	a2,s3
    80002842:	85ca                	mv	a1,s2
    80002844:	7928                	ld	a0,112(a0)
    80002846:	fffff097          	auipc	ra,0xfffff
    8000284a:	e14080e7          	jalr	-492(ra) # 8000165a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000284e:	70a2                	ld	ra,40(sp)
    80002850:	7402                	ld	s0,32(sp)
    80002852:	64e2                	ld	s1,24(sp)
    80002854:	6942                	ld	s2,16(sp)
    80002856:	69a2                	ld	s3,8(sp)
    80002858:	6a02                	ld	s4,0(sp)
    8000285a:	6145                	addi	sp,sp,48
    8000285c:	8082                	ret
    memmove((char *)dst, src, len);
    8000285e:	000a061b          	sext.w	a2,s4
    80002862:	85ce                	mv	a1,s3
    80002864:	854a                	mv	a0,s2
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	4c2080e7          	jalr	1218(ra) # 80000d28 <memmove>
    return 0;
    8000286e:	8526                	mv	a0,s1
    80002870:	bff9                	j	8000284e <either_copyout+0x32>

0000000080002872 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002872:	7179                	addi	sp,sp,-48
    80002874:	f406                	sd	ra,40(sp)
    80002876:	f022                	sd	s0,32(sp)
    80002878:	ec26                	sd	s1,24(sp)
    8000287a:	e84a                	sd	s2,16(sp)
    8000287c:	e44e                	sd	s3,8(sp)
    8000287e:	e052                	sd	s4,0(sp)
    80002880:	1800                	addi	s0,sp,48
    80002882:	892a                	mv	s2,a0
    80002884:	84ae                	mv	s1,a1
    80002886:	89b2                	mv	s3,a2
    80002888:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000288a:	fffff097          	auipc	ra,0xfffff
    8000288e:	3c6080e7          	jalr	966(ra) # 80001c50 <myproc>
  if(user_src){
    80002892:	c08d                	beqz	s1,800028b4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002894:	86d2                	mv	a3,s4
    80002896:	864e                	mv	a2,s3
    80002898:	85ca                	mv	a1,s2
    8000289a:	7928                	ld	a0,112(a0)
    8000289c:	fffff097          	auipc	ra,0xfffff
    800028a0:	e4a080e7          	jalr	-438(ra) # 800016e6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800028a4:	70a2                	ld	ra,40(sp)
    800028a6:	7402                	ld	s0,32(sp)
    800028a8:	64e2                	ld	s1,24(sp)
    800028aa:	6942                	ld	s2,16(sp)
    800028ac:	69a2                	ld	s3,8(sp)
    800028ae:	6a02                	ld	s4,0(sp)
    800028b0:	6145                	addi	sp,sp,48
    800028b2:	8082                	ret
    memmove(dst, (char*)src, len);
    800028b4:	000a061b          	sext.w	a2,s4
    800028b8:	85ce                	mv	a1,s3
    800028ba:	854a                	mv	a0,s2
    800028bc:	ffffe097          	auipc	ra,0xffffe
    800028c0:	46c080e7          	jalr	1132(ra) # 80000d28 <memmove>
    return 0;
    800028c4:	8526                	mv	a0,s1
    800028c6:	bff9                	j	800028a4 <either_copyin+0x32>

00000000800028c8 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800028c8:	715d                	addi	sp,sp,-80
    800028ca:	e486                	sd	ra,72(sp)
    800028cc:	e0a2                	sd	s0,64(sp)
    800028ce:	fc26                	sd	s1,56(sp)
    800028d0:	f84a                	sd	s2,48(sp)
    800028d2:	f44e                	sd	s3,40(sp)
    800028d4:	f052                	sd	s4,32(sp)
    800028d6:	ec56                	sd	s5,24(sp)
    800028d8:	e85a                	sd	s6,16(sp)
    800028da:	e45e                	sd	s7,8(sp)
    800028dc:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800028de:	00005517          	auipc	a0,0x5
    800028e2:	7ea50513          	addi	a0,a0,2026 # 800080c8 <digits+0x88>
    800028e6:	ffffe097          	auipc	ra,0xffffe
    800028ea:	c9e080e7          	jalr	-866(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028ee:	0000f497          	auipc	s1,0xf
    800028f2:	fea48493          	addi	s1,s1,-22 # 800118d8 <proc+0x178>
    800028f6:	00015917          	auipc	s2,0x15
    800028fa:	1e290913          	addi	s2,s2,482 # 80017ad8 <bcache+0x160>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028fe:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002900:	00006997          	auipc	s3,0x6
    80002904:	9f098993          	addi	s3,s3,-1552 # 800082f0 <digits+0x2b0>
    printf("%d %s %s", p->pid, state, p->name);
    80002908:	00006a97          	auipc	s5,0x6
    8000290c:	9f0a8a93          	addi	s5,s5,-1552 # 800082f8 <digits+0x2b8>
    printf("\n");
    80002910:	00005a17          	auipc	s4,0x5
    80002914:	7b8a0a13          	addi	s4,s4,1976 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002918:	00006b97          	auipc	s7,0x6
    8000291c:	a18b8b93          	addi	s7,s7,-1512 # 80008330 <states.0>
    80002920:	a00d                	j	80002942 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002922:	eb86a583          	lw	a1,-328(a3)
    80002926:	8556                	mv	a0,s5
    80002928:	ffffe097          	auipc	ra,0xffffe
    8000292c:	c5c080e7          	jalr	-932(ra) # 80000584 <printf>
    printf("\n");
    80002930:	8552                	mv	a0,s4
    80002932:	ffffe097          	auipc	ra,0xffffe
    80002936:	c52080e7          	jalr	-942(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000293a:	18848493          	addi	s1,s1,392
    8000293e:	03248263          	beq	s1,s2,80002962 <procdump+0x9a>
    if(p->state == UNUSED)
    80002942:	86a6                	mv	a3,s1
    80002944:	ea04a783          	lw	a5,-352(s1)
    80002948:	dbed                	beqz	a5,8000293a <procdump+0x72>
      state = "???";
    8000294a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000294c:	fcfb6be3          	bltu	s6,a5,80002922 <procdump+0x5a>
    80002950:	02079713          	slli	a4,a5,0x20
    80002954:	01d75793          	srli	a5,a4,0x1d
    80002958:	97de                	add	a5,a5,s7
    8000295a:	6390                	ld	a2,0(a5)
    8000295c:	f279                	bnez	a2,80002922 <procdump+0x5a>
      state = "???";
    8000295e:	864e                	mv	a2,s3
    80002960:	b7c9                	j	80002922 <procdump+0x5a>
  }
}
    80002962:	60a6                	ld	ra,72(sp)
    80002964:	6406                	ld	s0,64(sp)
    80002966:	74e2                	ld	s1,56(sp)
    80002968:	7942                	ld	s2,48(sp)
    8000296a:	79a2                	ld	s3,40(sp)
    8000296c:	7a02                	ld	s4,32(sp)
    8000296e:	6ae2                	ld	s5,24(sp)
    80002970:	6b42                	ld	s6,16(sp)
    80002972:	6ba2                	ld	s7,8(sp)
    80002974:	6161                	addi	sp,sp,80
    80002976:	8082                	ret

0000000080002978 <procinfo>:

// Fill in user-provided array with info for current processes
// Return the number of processes found
int
procinfo(uint64 addr)
{
    80002978:	7175                	addi	sp,sp,-144
    8000297a:	e506                	sd	ra,136(sp)
    8000297c:	e122                	sd	s0,128(sp)
    8000297e:	fca6                	sd	s1,120(sp)
    80002980:	f8ca                	sd	s2,112(sp)
    80002982:	f4ce                	sd	s3,104(sp)
    80002984:	f0d2                	sd	s4,96(sp)
    80002986:	ecd6                	sd	s5,88(sp)
    80002988:	e8da                	sd	s6,80(sp)
    8000298a:	e4de                	sd	s7,72(sp)
    8000298c:	0900                	addi	s0,sp,144
    8000298e:	89aa                	mv	s3,a0
  struct proc *p;
  struct proc *thisproc = myproc();
    80002990:	fffff097          	auipc	ra,0xfffff
    80002994:	2c0080e7          	jalr	704(ra) # 80001c50 <myproc>
    80002998:	8b2a                	mv	s6,a0
  struct pstat procinfo;
  int nprocs = 0;
  for(p = proc; p < &proc[NPROC]; p++){ 
    8000299a:	0000f917          	auipc	s2,0xf
    8000299e:	f3e90913          	addi	s2,s2,-194 # 800118d8 <proc+0x178>
    800029a2:	00015a17          	auipc	s4,0x15
    800029a6:	136a0a13          	addi	s4,s4,310 # 80017ad8 <bcache+0x160>
  int nprocs = 0;
    800029aa:	4a81                	li	s5,0
    procinfo.size = p->sz;
    procinfo.cputime = p->cputime;
    if (p->parent)
      procinfo.ppid = (p->parent)->pid;
    else
      procinfo.ppid = 0;
    800029ac:	4b81                	li	s7,0
    800029ae:	f9c40493          	addi	s1,s0,-100
    800029b2:	a089                	j	800029f4 <procinfo+0x7c>
    800029b4:	f8f42423          	sw	a5,-120(s0)
    for (int i=0; i<16; i++)
    800029b8:	f8c40793          	addi	a5,s0,-116
      procinfo.ppid = 0;
    800029bc:	874a                	mv	a4,s2
      procinfo.name[i] = p->name[i];
    800029be:	00074683          	lbu	a3,0(a4)
    800029c2:	00d78023          	sb	a3,0(a5)
    for (int i=0; i<16; i++)
    800029c6:	0705                	addi	a4,a4,1
    800029c8:	0785                	addi	a5,a5,1
    800029ca:	fe979ae3          	bne	a5,s1,800029be <procinfo+0x46>
   if (copyout(thisproc->pagetable, addr, (char *)&procinfo, sizeof(procinfo)) < 0)
    800029ce:	03800693          	li	a3,56
    800029d2:	f7840613          	addi	a2,s0,-136
    800029d6:	85ce                	mv	a1,s3
    800029d8:	070b3503          	ld	a0,112(s6)
    800029dc:	fffff097          	auipc	ra,0xfffff
    800029e0:	c7e080e7          	jalr	-898(ra) # 8000165a <copyout>
    800029e4:	04054063          	bltz	a0,80002a24 <procinfo+0xac>
      return -1;
    addr += sizeof(procinfo);
    800029e8:	03898993          	addi	s3,s3,56
  for(p = proc; p < &proc[NPROC]; p++){ 
    800029ec:	18890913          	addi	s2,s2,392
    800029f0:	03490b63          	beq	s2,s4,80002a26 <procinfo+0xae>
    if(p->state == UNUSED)
    800029f4:	ea092783          	lw	a5,-352(s2)
    800029f8:	dbf5                	beqz	a5,800029ec <procinfo+0x74>
    nprocs++;
    800029fa:	2a85                	addiw	s5,s5,1
    procinfo.pid = p->pid;
    800029fc:	eb892703          	lw	a4,-328(s2)
    80002a00:	f6e42c23          	sw	a4,-136(s0)
    procinfo.state = p->state;
    80002a04:	f6f42e23          	sw	a5,-132(s0)
    procinfo.size = p->sz;
    80002a08:	ef093783          	ld	a5,-272(s2)
    80002a0c:	f8f43023          	sd	a5,-128(s0)
    procinfo.cputime = p->cputime;
    80002a10:	ec093783          	ld	a5,-320(s2)
    80002a14:	faf43023          	sd	a5,-96(s0)
    if (p->parent)
    80002a18:	ee093703          	ld	a4,-288(s2)
      procinfo.ppid = 0;
    80002a1c:	87de                	mv	a5,s7
    if (p->parent)
    80002a1e:	db59                	beqz	a4,800029b4 <procinfo+0x3c>
      procinfo.ppid = (p->parent)->pid;
    80002a20:	5b1c                	lw	a5,48(a4)
    80002a22:	bf49                	j	800029b4 <procinfo+0x3c>
      return -1;
    80002a24:	5afd                	li	s5,-1
  }
  return nprocs;
}
    80002a26:	8556                	mv	a0,s5
    80002a28:	60aa                	ld	ra,136(sp)
    80002a2a:	640a                	ld	s0,128(sp)
    80002a2c:	74e6                	ld	s1,120(sp)
    80002a2e:	7946                	ld	s2,112(sp)
    80002a30:	79a6                	ld	s3,104(sp)
    80002a32:	7a06                	ld	s4,96(sp)
    80002a34:	6ae6                	ld	s5,88(sp)
    80002a36:	6b46                	ld	s6,80(sp)
    80002a38:	6ba6                	ld	s7,72(sp)
    80002a3a:	6149                	addi	sp,sp,144
    80002a3c:	8082                	ret

0000000080002a3e <wait2>:

int
wait2(uint64 addr, uint64 raddr)
{
    80002a3e:	7159                	addi	sp,sp,-112
    80002a40:	f486                	sd	ra,104(sp)
    80002a42:	f0a2                	sd	s0,96(sp)
    80002a44:	eca6                	sd	s1,88(sp)
    80002a46:	e8ca                	sd	s2,80(sp)
    80002a48:	e4ce                	sd	s3,72(sp)
    80002a4a:	e0d2                	sd	s4,64(sp)
    80002a4c:	fc56                	sd	s5,56(sp)
    80002a4e:	f85a                	sd	s6,48(sp)
    80002a50:	f45e                	sd	s7,40(sp)
    80002a52:	f062                	sd	s8,32(sp)
    80002a54:	ec66                	sd	s9,24(sp)
    80002a56:	1880                	addi	s0,sp,112
    80002a58:	8b2a                	mv	s6,a0
    80002a5a:	8bae                	mv	s7,a1
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002a5c:	fffff097          	auipc	ra,0xfffff
    80002a60:	1f4080e7          	jalr	500(ra) # 80001c50 <myproc>
    80002a64:	892a                	mv	s2,a0
  struct rusage use;

  acquire(&wait_lock);
    80002a66:	0000f517          	auipc	a0,0xf
    80002a6a:	8e250513          	addi	a0,a0,-1822 # 80011348 <wait_lock>
    80002a6e:	ffffe097          	auipc	ra,0xffffe
    80002a72:	162080e7          	jalr	354(ra) # 80000bd0 <acquire>

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    80002a76:	4c01                	li	s8,0
      if(np->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
    80002a78:	4a15                	li	s4,5
        havekids = 1;
    80002a7a:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002a7c:	00015997          	auipc	s3,0x15
    80002a80:	ee498993          	addi	s3,s3,-284 # 80017960 <tickslock>
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002a84:	0000fc97          	auipc	s9,0xf
    80002a88:	8c4c8c93          	addi	s9,s9,-1852 # 80011348 <wait_lock>
    havekids = 0;
    80002a8c:	8762                	mv	a4,s8
    for(np = proc; np < &proc[NPROC]; np++){
    80002a8e:	0000f497          	auipc	s1,0xf
    80002a92:	cd248493          	addi	s1,s1,-814 # 80011760 <proc>
    80002a96:	a051                	j	80002b1a <wait2+0xdc>
          use.cputime = np->cputime;
    80002a98:	7c9c                	ld	a5,56(s1)
    80002a9a:	f8f43c23          	sd	a5,-104(s0)
          copyout(p->pagetable, raddr, (char *)&use.cputime, sizeof(use.cputime));
    80002a9e:	46a1                	li	a3,8
    80002aa0:	f9840613          	addi	a2,s0,-104
    80002aa4:	85de                	mv	a1,s7
    80002aa6:	07093503          	ld	a0,112(s2)
    80002aaa:	fffff097          	auipc	ra,0xfffff
    80002aae:	bb0080e7          	jalr	-1104(ra) # 8000165a <copyout>
          pid = np->pid;
    80002ab2:	0304a983          	lw	s3,48(s1)
          if(copyout(p->pagetable, addr, (char *)&np->xstate, sizeof(np->xstate)) < 0) {
    80002ab6:	4691                	li	a3,4
    80002ab8:	02c48613          	addi	a2,s1,44
    80002abc:	85da                	mv	a1,s6
    80002abe:	07093503          	ld	a0,112(s2)
    80002ac2:	fffff097          	auipc	ra,0xfffff
    80002ac6:	b98080e7          	jalr	-1128(ra) # 8000165a <copyout>
    80002aca:	02054563          	bltz	a0,80002af4 <wait2+0xb6>
          freeproc(np);
    80002ace:	8526                	mv	a0,s1
    80002ad0:	fffff097          	auipc	ra,0xfffff
    80002ad4:	332080e7          	jalr	818(ra) # 80001e02 <freeproc>
          release(&np->lock);
    80002ad8:	8526                	mv	a0,s1
    80002ada:	ffffe097          	auipc	ra,0xffffe
    80002ade:	1aa080e7          	jalr	426(ra) # 80000c84 <release>
          release(&wait_lock);
    80002ae2:	0000f517          	auipc	a0,0xf
    80002ae6:	86650513          	addi	a0,a0,-1946 # 80011348 <wait_lock>
    80002aea:	ffffe097          	auipc	ra,0xffffe
    80002aee:	19a080e7          	jalr	410(ra) # 80000c84 <release>
          return pid;
    80002af2:	a09d                	j	80002b58 <wait2+0x11a>
            release(&np->lock);
    80002af4:	8526                	mv	a0,s1
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	18e080e7          	jalr	398(ra) # 80000c84 <release>
            release(&wait_lock);
    80002afe:	0000f517          	auipc	a0,0xf
    80002b02:	84a50513          	addi	a0,a0,-1974 # 80011348 <wait_lock>
    80002b06:	ffffe097          	auipc	ra,0xffffe
    80002b0a:	17e080e7          	jalr	382(ra) # 80000c84 <release>
            return -1;
    80002b0e:	59fd                	li	s3,-1
    80002b10:	a0a1                	j	80002b58 <wait2+0x11a>
    for(np = proc; np < &proc[NPROC]; np++){
    80002b12:	18848493          	addi	s1,s1,392
    80002b16:	03348463          	beq	s1,s3,80002b3e <wait2+0x100>
      if(np->parent == p){
    80002b1a:	6cbc                	ld	a5,88(s1)
    80002b1c:	ff279be3          	bne	a5,s2,80002b12 <wait2+0xd4>
        acquire(&np->lock);
    80002b20:	8526                	mv	a0,s1
    80002b22:	ffffe097          	auipc	ra,0xffffe
    80002b26:	0ae080e7          	jalr	174(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    80002b2a:	4c9c                	lw	a5,24(s1)
    80002b2c:	f74786e3          	beq	a5,s4,80002a98 <wait2+0x5a>
        release(&np->lock);
    80002b30:	8526                	mv	a0,s1
    80002b32:	ffffe097          	auipc	ra,0xffffe
    80002b36:	152080e7          	jalr	338(ra) # 80000c84 <release>
        havekids = 1;
    80002b3a:	8756                	mv	a4,s5
    80002b3c:	bfd9                	j	80002b12 <wait2+0xd4>
    if(!havekids || p->killed){
    80002b3e:	c701                	beqz	a4,80002b46 <wait2+0x108>
    80002b40:	02892783          	lw	a5,40(s2)
    80002b44:	cb85                	beqz	a5,80002b74 <wait2+0x136>
      release(&wait_lock);
    80002b46:	0000f517          	auipc	a0,0xf
    80002b4a:	80250513          	addi	a0,a0,-2046 # 80011348 <wait_lock>
    80002b4e:	ffffe097          	auipc	ra,0xffffe
    80002b52:	136080e7          	jalr	310(ra) # 80000c84 <release>
      return -1;
    80002b56:	59fd                	li	s3,-1
  }
}
    80002b58:	854e                	mv	a0,s3
    80002b5a:	70a6                	ld	ra,104(sp)
    80002b5c:	7406                	ld	s0,96(sp)
    80002b5e:	64e6                	ld	s1,88(sp)
    80002b60:	6946                	ld	s2,80(sp)
    80002b62:	69a6                	ld	s3,72(sp)
    80002b64:	6a06                	ld	s4,64(sp)
    80002b66:	7ae2                	ld	s5,56(sp)
    80002b68:	7b42                	ld	s6,48(sp)
    80002b6a:	7ba2                	ld	s7,40(sp)
    80002b6c:	7c02                	ld	s8,32(sp)
    80002b6e:	6ce2                	ld	s9,24(sp)
    80002b70:	6165                	addi	sp,sp,112
    80002b72:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002b74:	85e6                	mv	a1,s9
    80002b76:	854a                	mv	a0,s2
    80002b78:	00000097          	auipc	ra,0x0
    80002b7c:	856080e7          	jalr	-1962(ra) # 800023ce <sleep>
    havekids = 0;
    80002b80:	b731                	j	80002a8c <wait2+0x4e>

0000000080002b82 <swtch>:
    80002b82:	00153023          	sd	ra,0(a0)
    80002b86:	00253423          	sd	sp,8(a0)
    80002b8a:	e900                	sd	s0,16(a0)
    80002b8c:	ed04                	sd	s1,24(a0)
    80002b8e:	03253023          	sd	s2,32(a0)
    80002b92:	03353423          	sd	s3,40(a0)
    80002b96:	03453823          	sd	s4,48(a0)
    80002b9a:	03553c23          	sd	s5,56(a0)
    80002b9e:	05653023          	sd	s6,64(a0)
    80002ba2:	05753423          	sd	s7,72(a0)
    80002ba6:	05853823          	sd	s8,80(a0)
    80002baa:	05953c23          	sd	s9,88(a0)
    80002bae:	07a53023          	sd	s10,96(a0)
    80002bb2:	07b53423          	sd	s11,104(a0)
    80002bb6:	0005b083          	ld	ra,0(a1)
    80002bba:	0085b103          	ld	sp,8(a1)
    80002bbe:	6980                	ld	s0,16(a1)
    80002bc0:	6d84                	ld	s1,24(a1)
    80002bc2:	0205b903          	ld	s2,32(a1)
    80002bc6:	0285b983          	ld	s3,40(a1)
    80002bca:	0305ba03          	ld	s4,48(a1)
    80002bce:	0385ba83          	ld	s5,56(a1)
    80002bd2:	0405bb03          	ld	s6,64(a1)
    80002bd6:	0485bb83          	ld	s7,72(a1)
    80002bda:	0505bc03          	ld	s8,80(a1)
    80002bde:	0585bc83          	ld	s9,88(a1)
    80002be2:	0605bd03          	ld	s10,96(a1)
    80002be6:	0685bd83          	ld	s11,104(a1)
    80002bea:	8082                	ret

0000000080002bec <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002bec:	1141                	addi	sp,sp,-16
    80002bee:	e406                	sd	ra,8(sp)
    80002bf0:	e022                	sd	s0,0(sp)
    80002bf2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002bf4:	00005597          	auipc	a1,0x5
    80002bf8:	76c58593          	addi	a1,a1,1900 # 80008360 <states.0+0x30>
    80002bfc:	00015517          	auipc	a0,0x15
    80002c00:	d6450513          	addi	a0,a0,-668 # 80017960 <tickslock>
    80002c04:	ffffe097          	auipc	ra,0xffffe
    80002c08:	f3c080e7          	jalr	-196(ra) # 80000b40 <initlock>
}
    80002c0c:	60a2                	ld	ra,8(sp)
    80002c0e:	6402                	ld	s0,0(sp)
    80002c10:	0141                	addi	sp,sp,16
    80002c12:	8082                	ret

0000000080002c14 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002c14:	1141                	addi	sp,sp,-16
    80002c16:	e422                	sd	s0,8(sp)
    80002c18:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c1a:	00003797          	auipc	a5,0x3
    80002c1e:	70678793          	addi	a5,a5,1798 # 80006320 <kernelvec>
    80002c22:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c26:	6422                	ld	s0,8(sp)
    80002c28:	0141                	addi	sp,sp,16
    80002c2a:	8082                	ret

0000000080002c2c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002c2c:	1141                	addi	sp,sp,-16
    80002c2e:	e406                	sd	ra,8(sp)
    80002c30:	e022                	sd	s0,0(sp)
    80002c32:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c34:	fffff097          	auipc	ra,0xfffff
    80002c38:	01c080e7          	jalr	28(ra) # 80001c50 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c3c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c40:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c42:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002c46:	00004697          	auipc	a3,0x4
    80002c4a:	3ba68693          	addi	a3,a3,954 # 80007000 <_trampoline>
    80002c4e:	00004717          	auipc	a4,0x4
    80002c52:	3b270713          	addi	a4,a4,946 # 80007000 <_trampoline>
    80002c56:	8f15                	sub	a4,a4,a3
    80002c58:	040007b7          	lui	a5,0x4000
    80002c5c:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002c5e:	07b2                	slli	a5,a5,0xc
    80002c60:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c62:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c66:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c68:	18002673          	csrr	a2,satp
    80002c6c:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c6e:	7d30                	ld	a2,120(a0)
    80002c70:	7138                	ld	a4,96(a0)
    80002c72:	6585                	lui	a1,0x1
    80002c74:	972e                	add	a4,a4,a1
    80002c76:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c78:	7d38                	ld	a4,120(a0)
    80002c7a:	00000617          	auipc	a2,0x0
    80002c7e:	13860613          	addi	a2,a2,312 # 80002db2 <usertrap>
    80002c82:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c84:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c86:	8612                	mv	a2,tp
    80002c88:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c8a:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c8e:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c92:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c96:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c9a:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c9c:	6f18                	ld	a4,24(a4)
    80002c9e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002ca2:	792c                	ld	a1,112(a0)
    80002ca4:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002ca6:	00004717          	auipc	a4,0x4
    80002caa:	3ea70713          	addi	a4,a4,1002 # 80007090 <userret>
    80002cae:	8f15                	sub	a4,a4,a3
    80002cb0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002cb2:	577d                	li	a4,-1
    80002cb4:	177e                	slli	a4,a4,0x3f
    80002cb6:	8dd9                	or	a1,a1,a4
    80002cb8:	02000537          	lui	a0,0x2000
    80002cbc:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002cbe:	0536                	slli	a0,a0,0xd
    80002cc0:	9782                	jalr	a5
}
    80002cc2:	60a2                	ld	ra,8(sp)
    80002cc4:	6402                	ld	s0,0(sp)
    80002cc6:	0141                	addi	sp,sp,16
    80002cc8:	8082                	ret

0000000080002cca <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002cca:	1101                	addi	sp,sp,-32
    80002ccc:	ec06                	sd	ra,24(sp)
    80002cce:	e822                	sd	s0,16(sp)
    80002cd0:	e426                	sd	s1,8(sp)
    80002cd2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002cd4:	00015497          	auipc	s1,0x15
    80002cd8:	c8c48493          	addi	s1,s1,-884 # 80017960 <tickslock>
    80002cdc:	8526                	mv	a0,s1
    80002cde:	ffffe097          	auipc	ra,0xffffe
    80002ce2:	ef2080e7          	jalr	-270(ra) # 80000bd0 <acquire>
  ticks++;
    80002ce6:	00006517          	auipc	a0,0x6
    80002cea:	34e50513          	addi	a0,a0,846 # 80009034 <ticks>
    80002cee:	411c                	lw	a5,0(a0)
    80002cf0:	2785                	addiw	a5,a5,1
    80002cf2:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002cf4:	00000097          	auipc	ra,0x0
    80002cf8:	866080e7          	jalr	-1946(ra) # 8000255a <wakeup>
  release(&tickslock);
    80002cfc:	8526                	mv	a0,s1
    80002cfe:	ffffe097          	auipc	ra,0xffffe
    80002d02:	f86080e7          	jalr	-122(ra) # 80000c84 <release>
}
    80002d06:	60e2                	ld	ra,24(sp)
    80002d08:	6442                	ld	s0,16(sp)
    80002d0a:	64a2                	ld	s1,8(sp)
    80002d0c:	6105                	addi	sp,sp,32
    80002d0e:	8082                	ret

0000000080002d10 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002d10:	1101                	addi	sp,sp,-32
    80002d12:	ec06                	sd	ra,24(sp)
    80002d14:	e822                	sd	s0,16(sp)
    80002d16:	e426                	sd	s1,8(sp)
    80002d18:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d1a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002d1e:	00074d63          	bltz	a4,80002d38 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002d22:	57fd                	li	a5,-1
    80002d24:	17fe                	slli	a5,a5,0x3f
    80002d26:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002d28:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002d2a:	06f70363          	beq	a4,a5,80002d90 <devintr+0x80>
  }
}
    80002d2e:	60e2                	ld	ra,24(sp)
    80002d30:	6442                	ld	s0,16(sp)
    80002d32:	64a2                	ld	s1,8(sp)
    80002d34:	6105                	addi	sp,sp,32
    80002d36:	8082                	ret
     (scause & 0xff) == 9){
    80002d38:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002d3c:	46a5                	li	a3,9
    80002d3e:	fed792e3          	bne	a5,a3,80002d22 <devintr+0x12>
    int irq = plic_claim();
    80002d42:	00003097          	auipc	ra,0x3
    80002d46:	6e6080e7          	jalr	1766(ra) # 80006428 <plic_claim>
    80002d4a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d4c:	47a9                	li	a5,10
    80002d4e:	02f50763          	beq	a0,a5,80002d7c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002d52:	4785                	li	a5,1
    80002d54:	02f50963          	beq	a0,a5,80002d86 <devintr+0x76>
    return 1;
    80002d58:	4505                	li	a0,1
    } else if(irq){
    80002d5a:	d8f1                	beqz	s1,80002d2e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d5c:	85a6                	mv	a1,s1
    80002d5e:	00005517          	auipc	a0,0x5
    80002d62:	60a50513          	addi	a0,a0,1546 # 80008368 <states.0+0x38>
    80002d66:	ffffe097          	auipc	ra,0xffffe
    80002d6a:	81e080e7          	jalr	-2018(ra) # 80000584 <printf>
      plic_complete(irq);
    80002d6e:	8526                	mv	a0,s1
    80002d70:	00003097          	auipc	ra,0x3
    80002d74:	6dc080e7          	jalr	1756(ra) # 8000644c <plic_complete>
    return 1;
    80002d78:	4505                	li	a0,1
    80002d7a:	bf55                	j	80002d2e <devintr+0x1e>
      uartintr();
    80002d7c:	ffffe097          	auipc	ra,0xffffe
    80002d80:	c16080e7          	jalr	-1002(ra) # 80000992 <uartintr>
    80002d84:	b7ed                	j	80002d6e <devintr+0x5e>
      virtio_disk_intr();
    80002d86:	00004097          	auipc	ra,0x4
    80002d8a:	b52080e7          	jalr	-1198(ra) # 800068d8 <virtio_disk_intr>
    80002d8e:	b7c5                	j	80002d6e <devintr+0x5e>
    if(cpuid() == 0){
    80002d90:	fffff097          	auipc	ra,0xfffff
    80002d94:	e94080e7          	jalr	-364(ra) # 80001c24 <cpuid>
    80002d98:	c901                	beqz	a0,80002da8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d9a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d9e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002da0:	14479073          	csrw	sip,a5
    return 2;
    80002da4:	4509                	li	a0,2
    80002da6:	b761                	j	80002d2e <devintr+0x1e>
      clockintr();
    80002da8:	00000097          	auipc	ra,0x0
    80002dac:	f22080e7          	jalr	-222(ra) # 80002cca <clockintr>
    80002db0:	b7ed                	j	80002d9a <devintr+0x8a>

0000000080002db2 <usertrap>:
{
    80002db2:	1101                	addi	sp,sp,-32
    80002db4:	ec06                	sd	ra,24(sp)
    80002db6:	e822                	sd	s0,16(sp)
    80002db8:	e426                	sd	s1,8(sp)
    80002dba:	e04a                	sd	s2,0(sp)
    80002dbc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dbe:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002dc2:	1007f793          	andi	a5,a5,256
    80002dc6:	e3ad                	bnez	a5,80002e28 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002dc8:	00003797          	auipc	a5,0x3
    80002dcc:	55878793          	addi	a5,a5,1368 # 80006320 <kernelvec>
    80002dd0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	e7c080e7          	jalr	-388(ra) # 80001c50 <myproc>
    80002ddc:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002dde:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002de0:	14102773          	csrr	a4,sepc
    80002de4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002de6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002dea:	47a1                	li	a5,8
    80002dec:	04f71c63          	bne	a4,a5,80002e44 <usertrap+0x92>
    if(p->killed)
    80002df0:	551c                	lw	a5,40(a0)
    80002df2:	e3b9                	bnez	a5,80002e38 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002df4:	7cb8                	ld	a4,120(s1)
    80002df6:	6f1c                	ld	a5,24(a4)
    80002df8:	0791                	addi	a5,a5,4
    80002dfa:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dfc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e00:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e04:	10079073          	csrw	sstatus,a5
    syscall();
    80002e08:	00000097          	auipc	ra,0x0
    80002e0c:	4c4080e7          	jalr	1220(ra) # 800032cc <syscall>
  if(p->killed)
    80002e10:	549c                	lw	a5,40(s1)
    80002e12:	e7cd                	bnez	a5,80002ebc <usertrap+0x10a>
  usertrapret();
    80002e14:	00000097          	auipc	ra,0x0
    80002e18:	e18080e7          	jalr	-488(ra) # 80002c2c <usertrapret>
}
    80002e1c:	60e2                	ld	ra,24(sp)
    80002e1e:	6442                	ld	s0,16(sp)
    80002e20:	64a2                	ld	s1,8(sp)
    80002e22:	6902                	ld	s2,0(sp)
    80002e24:	6105                	addi	sp,sp,32
    80002e26:	8082                	ret
    panic("usertrap: not from user mode");
    80002e28:	00005517          	auipc	a0,0x5
    80002e2c:	56050513          	addi	a0,a0,1376 # 80008388 <states.0+0x58>
    80002e30:	ffffd097          	auipc	ra,0xffffd
    80002e34:	70a080e7          	jalr	1802(ra) # 8000053a <panic>
      exit(-1);
    80002e38:	557d                	li	a0,-1
    80002e3a:	00000097          	auipc	ra,0x0
    80002e3e:	89a080e7          	jalr	-1894(ra) # 800026d4 <exit>
    80002e42:	bf4d                	j	80002df4 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002e44:	00000097          	auipc	ra,0x0
    80002e48:	ecc080e7          	jalr	-308(ra) # 80002d10 <devintr>
    80002e4c:	892a                	mv	s2,a0
    80002e4e:	c501                	beqz	a0,80002e56 <usertrap+0xa4>
  if(p->killed)
    80002e50:	549c                	lw	a5,40(s1)
    80002e52:	c3a1                	beqz	a5,80002e92 <usertrap+0xe0>
    80002e54:	a815                	j	80002e88 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e56:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e5a:	5890                	lw	a2,48(s1)
    80002e5c:	00005517          	auipc	a0,0x5
    80002e60:	54c50513          	addi	a0,a0,1356 # 800083a8 <states.0+0x78>
    80002e64:	ffffd097          	auipc	ra,0xffffd
    80002e68:	720080e7          	jalr	1824(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e6c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e70:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e74:	00005517          	auipc	a0,0x5
    80002e78:	56450513          	addi	a0,a0,1380 # 800083d8 <states.0+0xa8>
    80002e7c:	ffffd097          	auipc	ra,0xffffd
    80002e80:	708080e7          	jalr	1800(ra) # 80000584 <printf>
    p->killed = 1;
    80002e84:	4785                	li	a5,1
    80002e86:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002e88:	557d                	li	a0,-1
    80002e8a:	00000097          	auipc	ra,0x0
    80002e8e:	84a080e7          	jalr	-1974(ra) # 800026d4 <exit>
  if(which_dev == 2 && --(p->tsticks) <= 0){
    80002e92:	4789                	li	a5,2
    80002e94:	f8f910e3          	bne	s2,a5,80002e14 <usertrap+0x62>
    80002e98:	40bc                	lw	a5,64(s1)
    80002e9a:	37fd                	addiw	a5,a5,-1
    80002e9c:	0007871b          	sext.w	a4,a5
    80002ea0:	c0bc                	sw	a5,64(s1)
    80002ea2:	fb2d                	bnez	a4,80002e14 <usertrap+0x62>
    if(p->priority == LOW){
    80002ea4:	40fc                	lw	a5,68(s1)
    80002ea6:	4709                	li	a4,2
    80002ea8:	00e78c63          	beq	a5,a4,80002ec0 <usertrap+0x10e>
    } else if (p->priority == MEDIUM){
    80002eac:	4705                	li	a4,1
    80002eae:	02e78963          	beq	a5,a4,80002ee0 <usertrap+0x12e>
    } else if (p->priority == HIGH){
    80002eb2:	ef8d                	bnez	a5,80002eec <usertrap+0x13a>
      p->cputime = p->cputime + TSTICKSHIGH;
    80002eb4:	7c9c                	ld	a5,56(s1)
    80002eb6:	0785                	addi	a5,a5,1
    80002eb8:	4705                	li	a4,1
    80002eba:	a801                	j	80002eca <usertrap+0x118>
  int which_dev = 0;
    80002ebc:	4901                	li	s2,0
    80002ebe:	b7e9                	j	80002e88 <usertrap+0xd6>
      p->cputime = p->cputime + TSTICKSLOW;
    80002ec0:	7c9c                	ld	a5,56(s1)
    80002ec2:	0c878793          	addi	a5,a5,200
      p->tsticks = TSTICKSLOW;
    80002ec6:	0c800713          	li	a4,200
      p->cputime = p->cputime + TSTICKSHIGH;
    80002eca:	fc9c                	sd	a5,56(s1)
      tempsticks = TSTICKSHIGH;
    80002ecc:	00006797          	auipc	a5,0x6
    80002ed0:	16e7a223          	sw	a4,356(a5) # 80009030 <tempsticks>
      p->tsticks = TSTICKSHIGH;
    80002ed4:	c0b8                	sw	a4,64(s1)
    yield();
    80002ed6:	fffff097          	auipc	ra,0xfffff
    80002eda:	4b0080e7          	jalr	1200(ra) # 80002386 <yield>
    80002ede:	bf1d                	j	80002e14 <usertrap+0x62>
      p->cputime = p->cputime + TSTICKSMEDIUM;
    80002ee0:	7c9c                	ld	a5,56(s1)
    80002ee2:	03278793          	addi	a5,a5,50
      p->tsticks = TSTICKSMEDIUM;
    80002ee6:	03200713          	li	a4,50
    80002eea:	b7c5                	j	80002eca <usertrap+0x118>
    if(p->priority > LOW) {
    80002eec:	4709                	li	a4,2
    80002eee:	fef754e3          	bge	a4,a5,80002ed6 <usertrap+0x124>
      p->priority = p->priority - 1;
    80002ef2:	37fd                	addiw	a5,a5,-1
    80002ef4:	0007871b          	sext.w	a4,a5
    80002ef8:	c0fc                	sw	a5,68(s1)
      if(p->priority == LOW){
    80002efa:	4789                	li	a5,2
    80002efc:	fcf71de3          	bne	a4,a5,80002ed6 <usertrap+0x124>
        p->timeslice = TSTICKSLOW;
    80002f00:	0c800793          	li	a5,200
    80002f04:	c4bc                	sw	a5,72(s1)
        p->tsticks = TSTICKSLOW;
    80002f06:	c0bc                	sw	a5,64(s1)
        tempsticks = TSTICKSLOW;
    80002f08:	00006717          	auipc	a4,0x6
    80002f0c:	12f72423          	sw	a5,296(a4) # 80009030 <tempsticks>
    80002f10:	b7d9                	j	80002ed6 <usertrap+0x124>

0000000080002f12 <kerneltrap>:
{
    80002f12:	7179                	addi	sp,sp,-48
    80002f14:	f406                	sd	ra,40(sp)
    80002f16:	f022                	sd	s0,32(sp)
    80002f18:	ec26                	sd	s1,24(sp)
    80002f1a:	e84a                	sd	s2,16(sp)
    80002f1c:	e44e                	sd	s3,8(sp)
    80002f1e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f20:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f24:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f28:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002f2c:	1004f793          	andi	a5,s1,256
    80002f30:	cb85                	beqz	a5,80002f60 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f32:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f36:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f38:	ef85                	bnez	a5,80002f70 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002f3a:	00000097          	auipc	ra,0x0
    80002f3e:	dd6080e7          	jalr	-554(ra) # 80002d10 <devintr>
    80002f42:	cd1d                	beqz	a0,80002f80 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING && --(myproc()->tsticks) <= 0){
    80002f44:	4789                	li	a5,2
    80002f46:	06f50a63          	beq	a0,a5,80002fba <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f4a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f4e:	10049073          	csrw	sstatus,s1
}
    80002f52:	70a2                	ld	ra,40(sp)
    80002f54:	7402                	ld	s0,32(sp)
    80002f56:	64e2                	ld	s1,24(sp)
    80002f58:	6942                	ld	s2,16(sp)
    80002f5a:	69a2                	ld	s3,8(sp)
    80002f5c:	6145                	addi	sp,sp,48
    80002f5e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f60:	00005517          	auipc	a0,0x5
    80002f64:	49850513          	addi	a0,a0,1176 # 800083f8 <states.0+0xc8>
    80002f68:	ffffd097          	auipc	ra,0xffffd
    80002f6c:	5d2080e7          	jalr	1490(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    80002f70:	00005517          	auipc	a0,0x5
    80002f74:	4b050513          	addi	a0,a0,1200 # 80008420 <states.0+0xf0>
    80002f78:	ffffd097          	auipc	ra,0xffffd
    80002f7c:	5c2080e7          	jalr	1474(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    80002f80:	85ce                	mv	a1,s3
    80002f82:	00005517          	auipc	a0,0x5
    80002f86:	4be50513          	addi	a0,a0,1214 # 80008440 <states.0+0x110>
    80002f8a:	ffffd097          	auipc	ra,0xffffd
    80002f8e:	5fa080e7          	jalr	1530(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f92:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f96:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f9a:	00005517          	auipc	a0,0x5
    80002f9e:	4b650513          	addi	a0,a0,1206 # 80008450 <states.0+0x120>
    80002fa2:	ffffd097          	auipc	ra,0xffffd
    80002fa6:	5e2080e7          	jalr	1506(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002faa:	00005517          	auipc	a0,0x5
    80002fae:	4be50513          	addi	a0,a0,1214 # 80008468 <states.0+0x138>
    80002fb2:	ffffd097          	auipc	ra,0xffffd
    80002fb6:	588080e7          	jalr	1416(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING && --(myproc()->tsticks) <= 0){
    80002fba:	fffff097          	auipc	ra,0xfffff
    80002fbe:	c96080e7          	jalr	-874(ra) # 80001c50 <myproc>
    80002fc2:	d541                	beqz	a0,80002f4a <kerneltrap+0x38>
    80002fc4:	fffff097          	auipc	ra,0xfffff
    80002fc8:	c8c080e7          	jalr	-884(ra) # 80001c50 <myproc>
    80002fcc:	4d18                	lw	a4,24(a0)
    80002fce:	4791                	li	a5,4
    80002fd0:	f6f71de3          	bne	a4,a5,80002f4a <kerneltrap+0x38>
    80002fd4:	fffff097          	auipc	ra,0xfffff
    80002fd8:	c7c080e7          	jalr	-900(ra) # 80001c50 <myproc>
    80002fdc:	413c                	lw	a5,64(a0)
    80002fde:	37fd                	addiw	a5,a5,-1
    80002fe0:	0007871b          	sext.w	a4,a5
    80002fe4:	c13c                	sw	a5,64(a0)
    80002fe6:	f335                	bnez	a4,80002f4a <kerneltrap+0x38>
    if(myproc()->priority == LOW){
    80002fe8:	fffff097          	auipc	ra,0xfffff
    80002fec:	c68080e7          	jalr	-920(ra) # 80001c50 <myproc>
    80002ff0:	4178                	lw	a4,68(a0)
    80002ff2:	4789                	li	a5,2
    80002ff4:	04f70a63          	beq	a4,a5,80003048 <kerneltrap+0x136>
    } else if (myproc()->priority == MEDIUM){
    80002ff8:	fffff097          	auipc	ra,0xfffff
    80002ffc:	c58080e7          	jalr	-936(ra) # 80001c50 <myproc>
    80003000:	4178                	lw	a4,68(a0)
    80003002:	4785                	li	a5,1
    80003004:	0af70163          	beq	a4,a5,800030a6 <kerneltrap+0x194>
    } else if (myproc()->priority == HIGH){
    80003008:	fffff097          	auipc	ra,0xfffff
    8000300c:	c48080e7          	jalr	-952(ra) # 80001c50 <myproc>
    80003010:	417c                	lw	a5,68(a0)
    80003012:	e7a5                	bnez	a5,8000307a <kerneltrap+0x168>
      myproc()->cputime = myproc()->cputime + TSTICKSHIGH;
    80003014:	fffff097          	auipc	ra,0xfffff
    80003018:	c3c080e7          	jalr	-964(ra) # 80001c50 <myproc>
    8000301c:	03853983          	ld	s3,56(a0)
    80003020:	fffff097          	auipc	ra,0xfffff
    80003024:	c30080e7          	jalr	-976(ra) # 80001c50 <myproc>
    80003028:	0985                	addi	s3,s3,1
    8000302a:	03353c23          	sd	s3,56(a0)
      tempsticks = TSTICKSLOW;
    8000302e:	0c800793          	li	a5,200
    80003032:	00006717          	auipc	a4,0x6
    80003036:	fef72f23          	sw	a5,-2(a4) # 80009030 <tempsticks>
      myproc()->tsticks = HIGH;
    8000303a:	fffff097          	auipc	ra,0xfffff
    8000303e:	c16080e7          	jalr	-1002(ra) # 80001c50 <myproc>
    80003042:	04052023          	sw	zero,64(a0)
    80003046:	a815                	j	8000307a <kerneltrap+0x168>
      myproc()->cputime = myproc()->cputime + TSTICKSLOW;
    80003048:	fffff097          	auipc	ra,0xfffff
    8000304c:	c08080e7          	jalr	-1016(ra) # 80001c50 <myproc>
    80003050:	03853983          	ld	s3,56(a0)
    80003054:	fffff097          	auipc	ra,0xfffff
    80003058:	bfc080e7          	jalr	-1028(ra) # 80001c50 <myproc>
    8000305c:	0c898993          	addi	s3,s3,200
    80003060:	03353c23          	sd	s3,56(a0)
      myproc()->tsticks = TSTICKSLOW;
    80003064:	fffff097          	auipc	ra,0xfffff
    80003068:	bec080e7          	jalr	-1044(ra) # 80001c50 <myproc>
    8000306c:	0c800793          	li	a5,200
    80003070:	c13c                	sw	a5,64(a0)
      tempsticks = TSTICKSLOW;
    80003072:	00006717          	auipc	a4,0x6
    80003076:	faf72f23          	sw	a5,-66(a4) # 80009030 <tempsticks>
    tempsticks = myproc()->tsticks;
    8000307a:	fffff097          	auipc	ra,0xfffff
    8000307e:	bd6080e7          	jalr	-1066(ra) # 80001c50 <myproc>
    80003082:	413c                	lw	a5,64(a0)
    80003084:	00006717          	auipc	a4,0x6
    80003088:	faf72623          	sw	a5,-84(a4) # 80009030 <tempsticks>
    if(myproc()->priority > LOW){
    8000308c:	fffff097          	auipc	ra,0xfffff
    80003090:	bc4080e7          	jalr	-1084(ra) # 80001c50 <myproc>
    80003094:	4178                	lw	a4,68(a0)
    80003096:	4789                	li	a5,2
    80003098:	04e7c263          	blt	a5,a4,800030dc <kerneltrap+0x1ca>
    yield();
    8000309c:	fffff097          	auipc	ra,0xfffff
    800030a0:	2ea080e7          	jalr	746(ra) # 80002386 <yield>
    800030a4:	b55d                	j	80002f4a <kerneltrap+0x38>
      myproc()->cputime = myproc()->cputime + TSTICKSMEDIUM;
    800030a6:	fffff097          	auipc	ra,0xfffff
    800030aa:	baa080e7          	jalr	-1110(ra) # 80001c50 <myproc>
    800030ae:	03853983          	ld	s3,56(a0)
    800030b2:	fffff097          	auipc	ra,0xfffff
    800030b6:	b9e080e7          	jalr	-1122(ra) # 80001c50 <myproc>
    800030ba:	03298993          	addi	s3,s3,50
    800030be:	03353c23          	sd	s3,56(a0)
      tempsticks = TSTICKSMEDIUM;
    800030c2:	03200993          	li	s3,50
    800030c6:	00006797          	auipc	a5,0x6
    800030ca:	f737a523          	sw	s3,-150(a5) # 80009030 <tempsticks>
      myproc()->tsticks = TSTICKSMEDIUM;
    800030ce:	fffff097          	auipc	ra,0xfffff
    800030d2:	b82080e7          	jalr	-1150(ra) # 80001c50 <myproc>
    800030d6:	05352023          	sw	s3,64(a0)
    800030da:	b745                	j	8000307a <kerneltrap+0x168>
      myproc()->priority--;
    800030dc:	fffff097          	auipc	ra,0xfffff
    800030e0:	b74080e7          	jalr	-1164(ra) # 80001c50 <myproc>
    800030e4:	417c                	lw	a5,68(a0)
    800030e6:	37fd                	addiw	a5,a5,-1
    800030e8:	c17c                	sw	a5,68(a0)
      if(myproc()->priority == MEDIUM){
    800030ea:	fffff097          	auipc	ra,0xfffff
    800030ee:	b66080e7          	jalr	-1178(ra) # 80001c50 <myproc>
    800030f2:	4178                	lw	a4,68(a0)
    800030f4:	4785                	li	a5,1
    800030f6:	02f70d63          	beq	a4,a5,80003130 <kerneltrap+0x21e>
      if(myproc()->priority == LOW){
    800030fa:	fffff097          	auipc	ra,0xfffff
    800030fe:	b56080e7          	jalr	-1194(ra) # 80001c50 <myproc>
    80003102:	4178                	lw	a4,68(a0)
    80003104:	4789                	li	a5,2
    80003106:	f8f71be3          	bne	a4,a5,8000309c <kerneltrap+0x18a>
        myproc()->timeslice = TSTICKSLOW;
    8000310a:	fffff097          	auipc	ra,0xfffff
    8000310e:	b46080e7          	jalr	-1210(ra) # 80001c50 <myproc>
    80003112:	0c800993          	li	s3,200
    80003116:	05352423          	sw	s3,72(a0)
        myproc()->tsticks = TSTICKSLOW;
    8000311a:	fffff097          	auipc	ra,0xfffff
    8000311e:	b36080e7          	jalr	-1226(ra) # 80001c50 <myproc>
    80003122:	05352023          	sw	s3,64(a0)
        tempsticks = TSTICKSLOW;
    80003126:	00006797          	auipc	a5,0x6
    8000312a:	f137a523          	sw	s3,-246(a5) # 80009030 <tempsticks>
    8000312e:	b7bd                	j	8000309c <kerneltrap+0x18a>
        myproc()->timeslice = TSTICKSMEDIUM;
    80003130:	fffff097          	auipc	ra,0xfffff
    80003134:	b20080e7          	jalr	-1248(ra) # 80001c50 <myproc>
    80003138:	03200993          	li	s3,50
    8000313c:	05352423          	sw	s3,72(a0)
        myproc()->tsticks = TSTICKSMEDIUM;
    80003140:	fffff097          	auipc	ra,0xfffff
    80003144:	b10080e7          	jalr	-1264(ra) # 80001c50 <myproc>
    80003148:	05352023          	sw	s3,64(a0)
        tempsticks = TSTICKSMEDIUM;
    8000314c:	00006797          	auipc	a5,0x6
    80003150:	ef37a223          	sw	s3,-284(a5) # 80009030 <tempsticks>
    80003154:	b75d                	j	800030fa <kerneltrap+0x1e8>

0000000080003156 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003156:	1101                	addi	sp,sp,-32
    80003158:	ec06                	sd	ra,24(sp)
    8000315a:	e822                	sd	s0,16(sp)
    8000315c:	e426                	sd	s1,8(sp)
    8000315e:	1000                	addi	s0,sp,32
    80003160:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003162:	fffff097          	auipc	ra,0xfffff
    80003166:	aee080e7          	jalr	-1298(ra) # 80001c50 <myproc>
  switch (n) {
    8000316a:	4795                	li	a5,5
    8000316c:	0497e163          	bltu	a5,s1,800031ae <argraw+0x58>
    80003170:	048a                	slli	s1,s1,0x2
    80003172:	00005717          	auipc	a4,0x5
    80003176:	32e70713          	addi	a4,a4,814 # 800084a0 <states.0+0x170>
    8000317a:	94ba                	add	s1,s1,a4
    8000317c:	409c                	lw	a5,0(s1)
    8000317e:	97ba                	add	a5,a5,a4
    80003180:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003182:	7d3c                	ld	a5,120(a0)
    80003184:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003186:	60e2                	ld	ra,24(sp)
    80003188:	6442                	ld	s0,16(sp)
    8000318a:	64a2                	ld	s1,8(sp)
    8000318c:	6105                	addi	sp,sp,32
    8000318e:	8082                	ret
    return p->trapframe->a1;
    80003190:	7d3c                	ld	a5,120(a0)
    80003192:	7fa8                	ld	a0,120(a5)
    80003194:	bfcd                	j	80003186 <argraw+0x30>
    return p->trapframe->a2;
    80003196:	7d3c                	ld	a5,120(a0)
    80003198:	63c8                	ld	a0,128(a5)
    8000319a:	b7f5                	j	80003186 <argraw+0x30>
    return p->trapframe->a3;
    8000319c:	7d3c                	ld	a5,120(a0)
    8000319e:	67c8                	ld	a0,136(a5)
    800031a0:	b7dd                	j	80003186 <argraw+0x30>
    return p->trapframe->a4;
    800031a2:	7d3c                	ld	a5,120(a0)
    800031a4:	6bc8                	ld	a0,144(a5)
    800031a6:	b7c5                	j	80003186 <argraw+0x30>
    return p->trapframe->a5;
    800031a8:	7d3c                	ld	a5,120(a0)
    800031aa:	6fc8                	ld	a0,152(a5)
    800031ac:	bfe9                	j	80003186 <argraw+0x30>
  panic("argraw");
    800031ae:	00005517          	auipc	a0,0x5
    800031b2:	2ca50513          	addi	a0,a0,714 # 80008478 <states.0+0x148>
    800031b6:	ffffd097          	auipc	ra,0xffffd
    800031ba:	384080e7          	jalr	900(ra) # 8000053a <panic>

00000000800031be <fetchaddr>:
{
    800031be:	1101                	addi	sp,sp,-32
    800031c0:	ec06                	sd	ra,24(sp)
    800031c2:	e822                	sd	s0,16(sp)
    800031c4:	e426                	sd	s1,8(sp)
    800031c6:	e04a                	sd	s2,0(sp)
    800031c8:	1000                	addi	s0,sp,32
    800031ca:	84aa                	mv	s1,a0
    800031cc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800031ce:	fffff097          	auipc	ra,0xfffff
    800031d2:	a82080e7          	jalr	-1406(ra) # 80001c50 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800031d6:	753c                	ld	a5,104(a0)
    800031d8:	02f4f863          	bgeu	s1,a5,80003208 <fetchaddr+0x4a>
    800031dc:	00848713          	addi	a4,s1,8
    800031e0:	02e7e663          	bltu	a5,a4,8000320c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800031e4:	46a1                	li	a3,8
    800031e6:	8626                	mv	a2,s1
    800031e8:	85ca                	mv	a1,s2
    800031ea:	7928                	ld	a0,112(a0)
    800031ec:	ffffe097          	auipc	ra,0xffffe
    800031f0:	4fa080e7          	jalr	1274(ra) # 800016e6 <copyin>
    800031f4:	00a03533          	snez	a0,a0
    800031f8:	40a00533          	neg	a0,a0
}
    800031fc:	60e2                	ld	ra,24(sp)
    800031fe:	6442                	ld	s0,16(sp)
    80003200:	64a2                	ld	s1,8(sp)
    80003202:	6902                	ld	s2,0(sp)
    80003204:	6105                	addi	sp,sp,32
    80003206:	8082                	ret
    return -1;
    80003208:	557d                	li	a0,-1
    8000320a:	bfcd                	j	800031fc <fetchaddr+0x3e>
    8000320c:	557d                	li	a0,-1
    8000320e:	b7fd                	j	800031fc <fetchaddr+0x3e>

0000000080003210 <fetchstr>:
{
    80003210:	7179                	addi	sp,sp,-48
    80003212:	f406                	sd	ra,40(sp)
    80003214:	f022                	sd	s0,32(sp)
    80003216:	ec26                	sd	s1,24(sp)
    80003218:	e84a                	sd	s2,16(sp)
    8000321a:	e44e                	sd	s3,8(sp)
    8000321c:	1800                	addi	s0,sp,48
    8000321e:	892a                	mv	s2,a0
    80003220:	84ae                	mv	s1,a1
    80003222:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003224:	fffff097          	auipc	ra,0xfffff
    80003228:	a2c080e7          	jalr	-1492(ra) # 80001c50 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000322c:	86ce                	mv	a3,s3
    8000322e:	864a                	mv	a2,s2
    80003230:	85a6                	mv	a1,s1
    80003232:	7928                	ld	a0,112(a0)
    80003234:	ffffe097          	auipc	ra,0xffffe
    80003238:	540080e7          	jalr	1344(ra) # 80001774 <copyinstr>
  if(err < 0)
    8000323c:	00054763          	bltz	a0,8000324a <fetchstr+0x3a>
  return strlen(buf);
    80003240:	8526                	mv	a0,s1
    80003242:	ffffe097          	auipc	ra,0xffffe
    80003246:	c06080e7          	jalr	-1018(ra) # 80000e48 <strlen>
}
    8000324a:	70a2                	ld	ra,40(sp)
    8000324c:	7402                	ld	s0,32(sp)
    8000324e:	64e2                	ld	s1,24(sp)
    80003250:	6942                	ld	s2,16(sp)
    80003252:	69a2                	ld	s3,8(sp)
    80003254:	6145                	addi	sp,sp,48
    80003256:	8082                	ret

0000000080003258 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003258:	1101                	addi	sp,sp,-32
    8000325a:	ec06                	sd	ra,24(sp)
    8000325c:	e822                	sd	s0,16(sp)
    8000325e:	e426                	sd	s1,8(sp)
    80003260:	1000                	addi	s0,sp,32
    80003262:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003264:	00000097          	auipc	ra,0x0
    80003268:	ef2080e7          	jalr	-270(ra) # 80003156 <argraw>
    8000326c:	c088                	sw	a0,0(s1)
  return 0;
}
    8000326e:	4501                	li	a0,0
    80003270:	60e2                	ld	ra,24(sp)
    80003272:	6442                	ld	s0,16(sp)
    80003274:	64a2                	ld	s1,8(sp)
    80003276:	6105                	addi	sp,sp,32
    80003278:	8082                	ret

000000008000327a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000327a:	1101                	addi	sp,sp,-32
    8000327c:	ec06                	sd	ra,24(sp)
    8000327e:	e822                	sd	s0,16(sp)
    80003280:	e426                	sd	s1,8(sp)
    80003282:	1000                	addi	s0,sp,32
    80003284:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003286:	00000097          	auipc	ra,0x0
    8000328a:	ed0080e7          	jalr	-304(ra) # 80003156 <argraw>
    8000328e:	e088                	sd	a0,0(s1)
  return 0;
}
    80003290:	4501                	li	a0,0
    80003292:	60e2                	ld	ra,24(sp)
    80003294:	6442                	ld	s0,16(sp)
    80003296:	64a2                	ld	s1,8(sp)
    80003298:	6105                	addi	sp,sp,32
    8000329a:	8082                	ret

000000008000329c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000329c:	1101                	addi	sp,sp,-32
    8000329e:	ec06                	sd	ra,24(sp)
    800032a0:	e822                	sd	s0,16(sp)
    800032a2:	e426                	sd	s1,8(sp)
    800032a4:	e04a                	sd	s2,0(sp)
    800032a6:	1000                	addi	s0,sp,32
    800032a8:	84ae                	mv	s1,a1
    800032aa:	8932                	mv	s2,a2
  *ip = argraw(n);
    800032ac:	00000097          	auipc	ra,0x0
    800032b0:	eaa080e7          	jalr	-342(ra) # 80003156 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800032b4:	864a                	mv	a2,s2
    800032b6:	85a6                	mv	a1,s1
    800032b8:	00000097          	auipc	ra,0x0
    800032bc:	f58080e7          	jalr	-168(ra) # 80003210 <fetchstr>
}
    800032c0:	60e2                	ld	ra,24(sp)
    800032c2:	6442                	ld	s0,16(sp)
    800032c4:	64a2                	ld	s1,8(sp)
    800032c6:	6902                	ld	s2,0(sp)
    800032c8:	6105                	addi	sp,sp,32
    800032ca:	8082                	ret

00000000800032cc <syscall>:
[SYS_wait2]   sys_wait2,
};

void
syscall(void)
{
    800032cc:	1101                	addi	sp,sp,-32
    800032ce:	ec06                	sd	ra,24(sp)
    800032d0:	e822                	sd	s0,16(sp)
    800032d2:	e426                	sd	s1,8(sp)
    800032d4:	e04a                	sd	s2,0(sp)
    800032d6:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800032d8:	fffff097          	auipc	ra,0xfffff
    800032dc:	978080e7          	jalr	-1672(ra) # 80001c50 <myproc>
    800032e0:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800032e2:	07853903          	ld	s2,120(a0)
    800032e6:	0a893783          	ld	a5,168(s2)
    800032ea:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800032ee:	37fd                	addiw	a5,a5,-1
    800032f0:	4759                	li	a4,22
    800032f2:	00f76f63          	bltu	a4,a5,80003310 <syscall+0x44>
    800032f6:	00369713          	slli	a4,a3,0x3
    800032fa:	00005797          	auipc	a5,0x5
    800032fe:	1be78793          	addi	a5,a5,446 # 800084b8 <syscalls>
    80003302:	97ba                	add	a5,a5,a4
    80003304:	639c                	ld	a5,0(a5)
    80003306:	c789                	beqz	a5,80003310 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003308:	9782                	jalr	a5
    8000330a:	06a93823          	sd	a0,112(s2)
    8000330e:	a839                	j	8000332c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003310:	17848613          	addi	a2,s1,376
    80003314:	588c                	lw	a1,48(s1)
    80003316:	00005517          	auipc	a0,0x5
    8000331a:	16a50513          	addi	a0,a0,362 # 80008480 <states.0+0x150>
    8000331e:	ffffd097          	auipc	ra,0xffffd
    80003322:	266080e7          	jalr	614(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003326:	7cbc                	ld	a5,120(s1)
    80003328:	577d                	li	a4,-1
    8000332a:	fbb8                	sd	a4,112(a5)
  }
}
    8000332c:	60e2                	ld	ra,24(sp)
    8000332e:	6442                	ld	s0,16(sp)
    80003330:	64a2                	ld	s1,8(sp)
    80003332:	6902                	ld	s2,0(sp)
    80003334:	6105                	addi	sp,sp,32
    80003336:	8082                	ret

0000000080003338 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003338:	1101                	addi	sp,sp,-32
    8000333a:	ec06                	sd	ra,24(sp)
    8000333c:	e822                	sd	s0,16(sp)
    8000333e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003340:	fec40593          	addi	a1,s0,-20
    80003344:	4501                	li	a0,0
    80003346:	00000097          	auipc	ra,0x0
    8000334a:	f12080e7          	jalr	-238(ra) # 80003258 <argint>
    return -1;
    8000334e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003350:	00054963          	bltz	a0,80003362 <sys_exit+0x2a>
  exit(n);
    80003354:	fec42503          	lw	a0,-20(s0)
    80003358:	fffff097          	auipc	ra,0xfffff
    8000335c:	37c080e7          	jalr	892(ra) # 800026d4 <exit>
  return 0;  // not reached
    80003360:	4781                	li	a5,0
}
    80003362:	853e                	mv	a0,a5
    80003364:	60e2                	ld	ra,24(sp)
    80003366:	6442                	ld	s0,16(sp)
    80003368:	6105                	addi	sp,sp,32
    8000336a:	8082                	ret

000000008000336c <sys_getpid>:

uint64
sys_getpid(void)
{
    8000336c:	1141                	addi	sp,sp,-16
    8000336e:	e406                	sd	ra,8(sp)
    80003370:	e022                	sd	s0,0(sp)
    80003372:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003374:	fffff097          	auipc	ra,0xfffff
    80003378:	8dc080e7          	jalr	-1828(ra) # 80001c50 <myproc>
}
    8000337c:	5908                	lw	a0,48(a0)
    8000337e:	60a2                	ld	ra,8(sp)
    80003380:	6402                	ld	s0,0(sp)
    80003382:	0141                	addi	sp,sp,16
    80003384:	8082                	ret

0000000080003386 <sys_fork>:

uint64
sys_fork(void)
{
    80003386:	1141                	addi	sp,sp,-16
    80003388:	e406                	sd	ra,8(sp)
    8000338a:	e022                	sd	s0,0(sp)
    8000338c:	0800                	addi	s0,sp,16
  return fork();
    8000338e:	fffff097          	auipc	ra,0xfffff
    80003392:	cb4080e7          	jalr	-844(ra) # 80002042 <fork>
}
    80003396:	60a2                	ld	ra,8(sp)
    80003398:	6402                	ld	s0,0(sp)
    8000339a:	0141                	addi	sp,sp,16
    8000339c:	8082                	ret

000000008000339e <sys_wait>:

uint64
sys_wait(void)
{
    8000339e:	1101                	addi	sp,sp,-32
    800033a0:	ec06                	sd	ra,24(sp)
    800033a2:	e822                	sd	s0,16(sp)
    800033a4:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800033a6:	fe840593          	addi	a1,s0,-24
    800033aa:	4501                	li	a0,0
    800033ac:	00000097          	auipc	ra,0x0
    800033b0:	ece080e7          	jalr	-306(ra) # 8000327a <argaddr>
    800033b4:	87aa                	mv	a5,a0
    return -1;
    800033b6:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800033b8:	0007c863          	bltz	a5,800033c8 <sys_wait+0x2a>
  return wait(p);
    800033bc:	fe843503          	ld	a0,-24(s0)
    800033c0:	fffff097          	auipc	ra,0xfffff
    800033c4:	072080e7          	jalr	114(ra) # 80002432 <wait>
}
    800033c8:	60e2                	ld	ra,24(sp)
    800033ca:	6442                	ld	s0,16(sp)
    800033cc:	6105                	addi	sp,sp,32
    800033ce:	8082                	ret

00000000800033d0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800033d0:	7179                	addi	sp,sp,-48
    800033d2:	f406                	sd	ra,40(sp)
    800033d4:	f022                	sd	s0,32(sp)
    800033d6:	ec26                	sd	s1,24(sp)
    800033d8:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800033da:	fdc40593          	addi	a1,s0,-36
    800033de:	4501                	li	a0,0
    800033e0:	00000097          	auipc	ra,0x0
    800033e4:	e78080e7          	jalr	-392(ra) # 80003258 <argint>
    800033e8:	87aa                	mv	a5,a0
    return -1;
    800033ea:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800033ec:	0207c063          	bltz	a5,8000340c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800033f0:	fffff097          	auipc	ra,0xfffff
    800033f4:	860080e7          	jalr	-1952(ra) # 80001c50 <myproc>
    800033f8:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    800033fa:	fdc42503          	lw	a0,-36(s0)
    800033fe:	fffff097          	auipc	ra,0xfffff
    80003402:	bcc080e7          	jalr	-1076(ra) # 80001fca <growproc>
    80003406:	00054863          	bltz	a0,80003416 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000340a:	8526                	mv	a0,s1
}
    8000340c:	70a2                	ld	ra,40(sp)
    8000340e:	7402                	ld	s0,32(sp)
    80003410:	64e2                	ld	s1,24(sp)
    80003412:	6145                	addi	sp,sp,48
    80003414:	8082                	ret
    return -1;
    80003416:	557d                	li	a0,-1
    80003418:	bfd5                	j	8000340c <sys_sbrk+0x3c>

000000008000341a <sys_sleep>:

uint64
sys_sleep(void)
{
    8000341a:	7139                	addi	sp,sp,-64
    8000341c:	fc06                	sd	ra,56(sp)
    8000341e:	f822                	sd	s0,48(sp)
    80003420:	f426                	sd	s1,40(sp)
    80003422:	f04a                	sd	s2,32(sp)
    80003424:	ec4e                	sd	s3,24(sp)
    80003426:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003428:	fcc40593          	addi	a1,s0,-52
    8000342c:	4501                	li	a0,0
    8000342e:	00000097          	auipc	ra,0x0
    80003432:	e2a080e7          	jalr	-470(ra) # 80003258 <argint>
    return -1;
    80003436:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003438:	06054563          	bltz	a0,800034a2 <sys_sleep+0x88>
  acquire(&tickslock);
    8000343c:	00014517          	auipc	a0,0x14
    80003440:	52450513          	addi	a0,a0,1316 # 80017960 <tickslock>
    80003444:	ffffd097          	auipc	ra,0xffffd
    80003448:	78c080e7          	jalr	1932(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    8000344c:	00006917          	auipc	s2,0x6
    80003450:	be892903          	lw	s2,-1048(s2) # 80009034 <ticks>
  while(ticks - ticks0 < n){
    80003454:	fcc42783          	lw	a5,-52(s0)
    80003458:	cf85                	beqz	a5,80003490 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000345a:	00014997          	auipc	s3,0x14
    8000345e:	50698993          	addi	s3,s3,1286 # 80017960 <tickslock>
    80003462:	00006497          	auipc	s1,0x6
    80003466:	bd248493          	addi	s1,s1,-1070 # 80009034 <ticks>
    if(myproc()->killed){
    8000346a:	ffffe097          	auipc	ra,0xffffe
    8000346e:	7e6080e7          	jalr	2022(ra) # 80001c50 <myproc>
    80003472:	551c                	lw	a5,40(a0)
    80003474:	ef9d                	bnez	a5,800034b2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003476:	85ce                	mv	a1,s3
    80003478:	8526                	mv	a0,s1
    8000347a:	fffff097          	auipc	ra,0xfffff
    8000347e:	f54080e7          	jalr	-172(ra) # 800023ce <sleep>
  while(ticks - ticks0 < n){
    80003482:	409c                	lw	a5,0(s1)
    80003484:	412787bb          	subw	a5,a5,s2
    80003488:	fcc42703          	lw	a4,-52(s0)
    8000348c:	fce7efe3          	bltu	a5,a4,8000346a <sys_sleep+0x50>
  }
  release(&tickslock);
    80003490:	00014517          	auipc	a0,0x14
    80003494:	4d050513          	addi	a0,a0,1232 # 80017960 <tickslock>
    80003498:	ffffd097          	auipc	ra,0xffffd
    8000349c:	7ec080e7          	jalr	2028(ra) # 80000c84 <release>
  return 0;
    800034a0:	4781                	li	a5,0
}
    800034a2:	853e                	mv	a0,a5
    800034a4:	70e2                	ld	ra,56(sp)
    800034a6:	7442                	ld	s0,48(sp)
    800034a8:	74a2                	ld	s1,40(sp)
    800034aa:	7902                	ld	s2,32(sp)
    800034ac:	69e2                	ld	s3,24(sp)
    800034ae:	6121                	addi	sp,sp,64
    800034b0:	8082                	ret
      release(&tickslock);
    800034b2:	00014517          	auipc	a0,0x14
    800034b6:	4ae50513          	addi	a0,a0,1198 # 80017960 <tickslock>
    800034ba:	ffffd097          	auipc	ra,0xffffd
    800034be:	7ca080e7          	jalr	1994(ra) # 80000c84 <release>
      return -1;
    800034c2:	57fd                	li	a5,-1
    800034c4:	bff9                	j	800034a2 <sys_sleep+0x88>

00000000800034c6 <sys_kill>:

uint64
sys_kill(void)
{
    800034c6:	1101                	addi	sp,sp,-32
    800034c8:	ec06                	sd	ra,24(sp)
    800034ca:	e822                	sd	s0,16(sp)
    800034cc:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800034ce:	fec40593          	addi	a1,s0,-20
    800034d2:	4501                	li	a0,0
    800034d4:	00000097          	auipc	ra,0x0
    800034d8:	d84080e7          	jalr	-636(ra) # 80003258 <argint>
    800034dc:	87aa                	mv	a5,a0
    return -1;
    800034de:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800034e0:	0007c863          	bltz	a5,800034f0 <sys_kill+0x2a>
  return kill(pid);
    800034e4:	fec42503          	lw	a0,-20(s0)
    800034e8:	fffff097          	auipc	ra,0xfffff
    800034ec:	2c2080e7          	jalr	706(ra) # 800027aa <kill>
}
    800034f0:	60e2                	ld	ra,24(sp)
    800034f2:	6442                	ld	s0,16(sp)
    800034f4:	6105                	addi	sp,sp,32
    800034f6:	8082                	ret

00000000800034f8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800034f8:	1101                	addi	sp,sp,-32
    800034fa:	ec06                	sd	ra,24(sp)
    800034fc:	e822                	sd	s0,16(sp)
    800034fe:	e426                	sd	s1,8(sp)
    80003500:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003502:	00014517          	auipc	a0,0x14
    80003506:	45e50513          	addi	a0,a0,1118 # 80017960 <tickslock>
    8000350a:	ffffd097          	auipc	ra,0xffffd
    8000350e:	6c6080e7          	jalr	1734(ra) # 80000bd0 <acquire>
  xticks = ticks;
    80003512:	00006497          	auipc	s1,0x6
    80003516:	b224a483          	lw	s1,-1246(s1) # 80009034 <ticks>
  release(&tickslock);
    8000351a:	00014517          	auipc	a0,0x14
    8000351e:	44650513          	addi	a0,a0,1094 # 80017960 <tickslock>
    80003522:	ffffd097          	auipc	ra,0xffffd
    80003526:	762080e7          	jalr	1890(ra) # 80000c84 <release>
  return xticks;
}
    8000352a:	02049513          	slli	a0,s1,0x20
    8000352e:	9101                	srli	a0,a0,0x20
    80003530:	60e2                	ld	ra,24(sp)
    80003532:	6442                	ld	s0,16(sp)
    80003534:	64a2                	ld	s1,8(sp)
    80003536:	6105                	addi	sp,sp,32
    80003538:	8082                	ret

000000008000353a <sys_getprocs>:

// return the number of active processes in the system
// fill in user-provided data structure with pid,state,sz,ppid,name
uint64
sys_getprocs(void)
{
    8000353a:	1101                	addi	sp,sp,-32
    8000353c:	ec06                	sd	ra,24(sp)
    8000353e:	e822                	sd	s0,16(sp)
    80003540:	1000                	addi	s0,sp,32
  uint64 addr;  // user pointer to struct pstat

  if (argaddr(0, &addr) < 0)
    80003542:	fe840593          	addi	a1,s0,-24
    80003546:	4501                	li	a0,0
    80003548:	00000097          	auipc	ra,0x0
    8000354c:	d32080e7          	jalr	-718(ra) # 8000327a <argaddr>
    80003550:	87aa                	mv	a5,a0
    return -1;
    80003552:	557d                	li	a0,-1
  if (argaddr(0, &addr) < 0)
    80003554:	0007c863          	bltz	a5,80003564 <sys_getprocs+0x2a>
  return(procinfo(addr));
    80003558:	fe843503          	ld	a0,-24(s0)
    8000355c:	fffff097          	auipc	ra,0xfffff
    80003560:	41c080e7          	jalr	1052(ra) # 80002978 <procinfo>
}
    80003564:	60e2                	ld	ra,24(sp)
    80003566:	6442                	ld	s0,16(sp)
    80003568:	6105                	addi	sp,sp,32
    8000356a:	8082                	ret

000000008000356c <sys_wait2>:

uint64
sys_wait2(void)
{
    8000356c:	1101                	addi	sp,sp,-32
    8000356e:	ec06                	sd	ra,24(sp)
    80003570:	e822                	sd	s0,16(sp)
    80003572:	1000                	addi	s0,sp,32
  uint64 p1, p2;

  if(argaddr(0, &p1) < 0 || argaddr(1, &p2) < 0)  
    80003574:	fe840593          	addi	a1,s0,-24
    80003578:	4501                	li	a0,0
    8000357a:	00000097          	auipc	ra,0x0
    8000357e:	d00080e7          	jalr	-768(ra) # 8000327a <argaddr>
    return -1;
    80003582:	57fd                	li	a5,-1
  if(argaddr(0, &p1) < 0 || argaddr(1, &p2) < 0)  
    80003584:	02054563          	bltz	a0,800035ae <sys_wait2+0x42>
    80003588:	fe040593          	addi	a1,s0,-32
    8000358c:	4505                	li	a0,1
    8000358e:	00000097          	auipc	ra,0x0
    80003592:	cec080e7          	jalr	-788(ra) # 8000327a <argaddr>
    return -1;
    80003596:	57fd                	li	a5,-1
  if(argaddr(0, &p1) < 0 || argaddr(1, &p2) < 0)  
    80003598:	00054b63          	bltz	a0,800035ae <sys_wait2+0x42>
  return(wait2(p1, p2));
    8000359c:	fe043583          	ld	a1,-32(s0)
    800035a0:	fe843503          	ld	a0,-24(s0)
    800035a4:	fffff097          	auipc	ra,0xfffff
    800035a8:	49a080e7          	jalr	1178(ra) # 80002a3e <wait2>
    800035ac:	87aa                	mv	a5,a0
    800035ae:	853e                	mv	a0,a5
    800035b0:	60e2                	ld	ra,24(sp)
    800035b2:	6442                	ld	s0,16(sp)
    800035b4:	6105                	addi	sp,sp,32
    800035b6:	8082                	ret

00000000800035b8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800035b8:	7179                	addi	sp,sp,-48
    800035ba:	f406                	sd	ra,40(sp)
    800035bc:	f022                	sd	s0,32(sp)
    800035be:	ec26                	sd	s1,24(sp)
    800035c0:	e84a                	sd	s2,16(sp)
    800035c2:	e44e                	sd	s3,8(sp)
    800035c4:	e052                	sd	s4,0(sp)
    800035c6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800035c8:	00005597          	auipc	a1,0x5
    800035cc:	fb058593          	addi	a1,a1,-80 # 80008578 <syscalls+0xc0>
    800035d0:	00014517          	auipc	a0,0x14
    800035d4:	3a850513          	addi	a0,a0,936 # 80017978 <bcache>
    800035d8:	ffffd097          	auipc	ra,0xffffd
    800035dc:	568080e7          	jalr	1384(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800035e0:	0001c797          	auipc	a5,0x1c
    800035e4:	39878793          	addi	a5,a5,920 # 8001f978 <bcache+0x8000>
    800035e8:	0001c717          	auipc	a4,0x1c
    800035ec:	5f870713          	addi	a4,a4,1528 # 8001fbe0 <bcache+0x8268>
    800035f0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800035f4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035f8:	00014497          	auipc	s1,0x14
    800035fc:	39848493          	addi	s1,s1,920 # 80017990 <bcache+0x18>
    b->next = bcache.head.next;
    80003600:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003602:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003604:	00005a17          	auipc	s4,0x5
    80003608:	f7ca0a13          	addi	s4,s4,-132 # 80008580 <syscalls+0xc8>
    b->next = bcache.head.next;
    8000360c:	2b893783          	ld	a5,696(s2)
    80003610:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003612:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003616:	85d2                	mv	a1,s4
    80003618:	01048513          	addi	a0,s1,16
    8000361c:	00001097          	auipc	ra,0x1
    80003620:	4c2080e7          	jalr	1218(ra) # 80004ade <initsleeplock>
    bcache.head.next->prev = b;
    80003624:	2b893783          	ld	a5,696(s2)
    80003628:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000362a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000362e:	45848493          	addi	s1,s1,1112
    80003632:	fd349de3          	bne	s1,s3,8000360c <binit+0x54>
  }
}
    80003636:	70a2                	ld	ra,40(sp)
    80003638:	7402                	ld	s0,32(sp)
    8000363a:	64e2                	ld	s1,24(sp)
    8000363c:	6942                	ld	s2,16(sp)
    8000363e:	69a2                	ld	s3,8(sp)
    80003640:	6a02                	ld	s4,0(sp)
    80003642:	6145                	addi	sp,sp,48
    80003644:	8082                	ret

0000000080003646 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003646:	7179                	addi	sp,sp,-48
    80003648:	f406                	sd	ra,40(sp)
    8000364a:	f022                	sd	s0,32(sp)
    8000364c:	ec26                	sd	s1,24(sp)
    8000364e:	e84a                	sd	s2,16(sp)
    80003650:	e44e                	sd	s3,8(sp)
    80003652:	1800                	addi	s0,sp,48
    80003654:	892a                	mv	s2,a0
    80003656:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003658:	00014517          	auipc	a0,0x14
    8000365c:	32050513          	addi	a0,a0,800 # 80017978 <bcache>
    80003660:	ffffd097          	auipc	ra,0xffffd
    80003664:	570080e7          	jalr	1392(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003668:	0001c497          	auipc	s1,0x1c
    8000366c:	5c84b483          	ld	s1,1480(s1) # 8001fc30 <bcache+0x82b8>
    80003670:	0001c797          	auipc	a5,0x1c
    80003674:	57078793          	addi	a5,a5,1392 # 8001fbe0 <bcache+0x8268>
    80003678:	02f48f63          	beq	s1,a5,800036b6 <bread+0x70>
    8000367c:	873e                	mv	a4,a5
    8000367e:	a021                	j	80003686 <bread+0x40>
    80003680:	68a4                	ld	s1,80(s1)
    80003682:	02e48a63          	beq	s1,a4,800036b6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003686:	449c                	lw	a5,8(s1)
    80003688:	ff279ce3          	bne	a5,s2,80003680 <bread+0x3a>
    8000368c:	44dc                	lw	a5,12(s1)
    8000368e:	ff3799e3          	bne	a5,s3,80003680 <bread+0x3a>
      b->refcnt++;
    80003692:	40bc                	lw	a5,64(s1)
    80003694:	2785                	addiw	a5,a5,1
    80003696:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003698:	00014517          	auipc	a0,0x14
    8000369c:	2e050513          	addi	a0,a0,736 # 80017978 <bcache>
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	5e4080e7          	jalr	1508(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    800036a8:	01048513          	addi	a0,s1,16
    800036ac:	00001097          	auipc	ra,0x1
    800036b0:	46c080e7          	jalr	1132(ra) # 80004b18 <acquiresleep>
      return b;
    800036b4:	a8b9                	j	80003712 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036b6:	0001c497          	auipc	s1,0x1c
    800036ba:	5724b483          	ld	s1,1394(s1) # 8001fc28 <bcache+0x82b0>
    800036be:	0001c797          	auipc	a5,0x1c
    800036c2:	52278793          	addi	a5,a5,1314 # 8001fbe0 <bcache+0x8268>
    800036c6:	00f48863          	beq	s1,a5,800036d6 <bread+0x90>
    800036ca:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800036cc:	40bc                	lw	a5,64(s1)
    800036ce:	cf81                	beqz	a5,800036e6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036d0:	64a4                	ld	s1,72(s1)
    800036d2:	fee49de3          	bne	s1,a4,800036cc <bread+0x86>
  panic("bget: no buffers");
    800036d6:	00005517          	auipc	a0,0x5
    800036da:	eb250513          	addi	a0,a0,-334 # 80008588 <syscalls+0xd0>
    800036de:	ffffd097          	auipc	ra,0xffffd
    800036e2:	e5c080e7          	jalr	-420(ra) # 8000053a <panic>
      b->dev = dev;
    800036e6:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800036ea:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800036ee:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800036f2:	4785                	li	a5,1
    800036f4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800036f6:	00014517          	auipc	a0,0x14
    800036fa:	28250513          	addi	a0,a0,642 # 80017978 <bcache>
    800036fe:	ffffd097          	auipc	ra,0xffffd
    80003702:	586080e7          	jalr	1414(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80003706:	01048513          	addi	a0,s1,16
    8000370a:	00001097          	auipc	ra,0x1
    8000370e:	40e080e7          	jalr	1038(ra) # 80004b18 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003712:	409c                	lw	a5,0(s1)
    80003714:	cb89                	beqz	a5,80003726 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003716:	8526                	mv	a0,s1
    80003718:	70a2                	ld	ra,40(sp)
    8000371a:	7402                	ld	s0,32(sp)
    8000371c:	64e2                	ld	s1,24(sp)
    8000371e:	6942                	ld	s2,16(sp)
    80003720:	69a2                	ld	s3,8(sp)
    80003722:	6145                	addi	sp,sp,48
    80003724:	8082                	ret
    virtio_disk_rw(b, 0);
    80003726:	4581                	li	a1,0
    80003728:	8526                	mv	a0,s1
    8000372a:	00003097          	auipc	ra,0x3
    8000372e:	f28080e7          	jalr	-216(ra) # 80006652 <virtio_disk_rw>
    b->valid = 1;
    80003732:	4785                	li	a5,1
    80003734:	c09c                	sw	a5,0(s1)
  return b;
    80003736:	b7c5                	j	80003716 <bread+0xd0>

0000000080003738 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003738:	1101                	addi	sp,sp,-32
    8000373a:	ec06                	sd	ra,24(sp)
    8000373c:	e822                	sd	s0,16(sp)
    8000373e:	e426                	sd	s1,8(sp)
    80003740:	1000                	addi	s0,sp,32
    80003742:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003744:	0541                	addi	a0,a0,16
    80003746:	00001097          	auipc	ra,0x1
    8000374a:	46c080e7          	jalr	1132(ra) # 80004bb2 <holdingsleep>
    8000374e:	cd01                	beqz	a0,80003766 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003750:	4585                	li	a1,1
    80003752:	8526                	mv	a0,s1
    80003754:	00003097          	auipc	ra,0x3
    80003758:	efe080e7          	jalr	-258(ra) # 80006652 <virtio_disk_rw>
}
    8000375c:	60e2                	ld	ra,24(sp)
    8000375e:	6442                	ld	s0,16(sp)
    80003760:	64a2                	ld	s1,8(sp)
    80003762:	6105                	addi	sp,sp,32
    80003764:	8082                	ret
    panic("bwrite");
    80003766:	00005517          	auipc	a0,0x5
    8000376a:	e3a50513          	addi	a0,a0,-454 # 800085a0 <syscalls+0xe8>
    8000376e:	ffffd097          	auipc	ra,0xffffd
    80003772:	dcc080e7          	jalr	-564(ra) # 8000053a <panic>

0000000080003776 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003776:	1101                	addi	sp,sp,-32
    80003778:	ec06                	sd	ra,24(sp)
    8000377a:	e822                	sd	s0,16(sp)
    8000377c:	e426                	sd	s1,8(sp)
    8000377e:	e04a                	sd	s2,0(sp)
    80003780:	1000                	addi	s0,sp,32
    80003782:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003784:	01050913          	addi	s2,a0,16
    80003788:	854a                	mv	a0,s2
    8000378a:	00001097          	auipc	ra,0x1
    8000378e:	428080e7          	jalr	1064(ra) # 80004bb2 <holdingsleep>
    80003792:	c92d                	beqz	a0,80003804 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003794:	854a                	mv	a0,s2
    80003796:	00001097          	auipc	ra,0x1
    8000379a:	3d8080e7          	jalr	984(ra) # 80004b6e <releasesleep>

  acquire(&bcache.lock);
    8000379e:	00014517          	auipc	a0,0x14
    800037a2:	1da50513          	addi	a0,a0,474 # 80017978 <bcache>
    800037a6:	ffffd097          	auipc	ra,0xffffd
    800037aa:	42a080e7          	jalr	1066(ra) # 80000bd0 <acquire>
  b->refcnt--;
    800037ae:	40bc                	lw	a5,64(s1)
    800037b0:	37fd                	addiw	a5,a5,-1
    800037b2:	0007871b          	sext.w	a4,a5
    800037b6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800037b8:	eb05                	bnez	a4,800037e8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800037ba:	68bc                	ld	a5,80(s1)
    800037bc:	64b8                	ld	a4,72(s1)
    800037be:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800037c0:	64bc                	ld	a5,72(s1)
    800037c2:	68b8                	ld	a4,80(s1)
    800037c4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800037c6:	0001c797          	auipc	a5,0x1c
    800037ca:	1b278793          	addi	a5,a5,434 # 8001f978 <bcache+0x8000>
    800037ce:	2b87b703          	ld	a4,696(a5)
    800037d2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800037d4:	0001c717          	auipc	a4,0x1c
    800037d8:	40c70713          	addi	a4,a4,1036 # 8001fbe0 <bcache+0x8268>
    800037dc:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800037de:	2b87b703          	ld	a4,696(a5)
    800037e2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800037e4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800037e8:	00014517          	auipc	a0,0x14
    800037ec:	19050513          	addi	a0,a0,400 # 80017978 <bcache>
    800037f0:	ffffd097          	auipc	ra,0xffffd
    800037f4:	494080e7          	jalr	1172(ra) # 80000c84 <release>
}
    800037f8:	60e2                	ld	ra,24(sp)
    800037fa:	6442                	ld	s0,16(sp)
    800037fc:	64a2                	ld	s1,8(sp)
    800037fe:	6902                	ld	s2,0(sp)
    80003800:	6105                	addi	sp,sp,32
    80003802:	8082                	ret
    panic("brelse");
    80003804:	00005517          	auipc	a0,0x5
    80003808:	da450513          	addi	a0,a0,-604 # 800085a8 <syscalls+0xf0>
    8000380c:	ffffd097          	auipc	ra,0xffffd
    80003810:	d2e080e7          	jalr	-722(ra) # 8000053a <panic>

0000000080003814 <bpin>:

void
bpin(struct buf *b) {
    80003814:	1101                	addi	sp,sp,-32
    80003816:	ec06                	sd	ra,24(sp)
    80003818:	e822                	sd	s0,16(sp)
    8000381a:	e426                	sd	s1,8(sp)
    8000381c:	1000                	addi	s0,sp,32
    8000381e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003820:	00014517          	auipc	a0,0x14
    80003824:	15850513          	addi	a0,a0,344 # 80017978 <bcache>
    80003828:	ffffd097          	auipc	ra,0xffffd
    8000382c:	3a8080e7          	jalr	936(ra) # 80000bd0 <acquire>
  b->refcnt++;
    80003830:	40bc                	lw	a5,64(s1)
    80003832:	2785                	addiw	a5,a5,1
    80003834:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003836:	00014517          	auipc	a0,0x14
    8000383a:	14250513          	addi	a0,a0,322 # 80017978 <bcache>
    8000383e:	ffffd097          	auipc	ra,0xffffd
    80003842:	446080e7          	jalr	1094(ra) # 80000c84 <release>
}
    80003846:	60e2                	ld	ra,24(sp)
    80003848:	6442                	ld	s0,16(sp)
    8000384a:	64a2                	ld	s1,8(sp)
    8000384c:	6105                	addi	sp,sp,32
    8000384e:	8082                	ret

0000000080003850 <bunpin>:

void
bunpin(struct buf *b) {
    80003850:	1101                	addi	sp,sp,-32
    80003852:	ec06                	sd	ra,24(sp)
    80003854:	e822                	sd	s0,16(sp)
    80003856:	e426                	sd	s1,8(sp)
    80003858:	1000                	addi	s0,sp,32
    8000385a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000385c:	00014517          	auipc	a0,0x14
    80003860:	11c50513          	addi	a0,a0,284 # 80017978 <bcache>
    80003864:	ffffd097          	auipc	ra,0xffffd
    80003868:	36c080e7          	jalr	876(ra) # 80000bd0 <acquire>
  b->refcnt--;
    8000386c:	40bc                	lw	a5,64(s1)
    8000386e:	37fd                	addiw	a5,a5,-1
    80003870:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003872:	00014517          	auipc	a0,0x14
    80003876:	10650513          	addi	a0,a0,262 # 80017978 <bcache>
    8000387a:	ffffd097          	auipc	ra,0xffffd
    8000387e:	40a080e7          	jalr	1034(ra) # 80000c84 <release>
}
    80003882:	60e2                	ld	ra,24(sp)
    80003884:	6442                	ld	s0,16(sp)
    80003886:	64a2                	ld	s1,8(sp)
    80003888:	6105                	addi	sp,sp,32
    8000388a:	8082                	ret

000000008000388c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000388c:	1101                	addi	sp,sp,-32
    8000388e:	ec06                	sd	ra,24(sp)
    80003890:	e822                	sd	s0,16(sp)
    80003892:	e426                	sd	s1,8(sp)
    80003894:	e04a                	sd	s2,0(sp)
    80003896:	1000                	addi	s0,sp,32
    80003898:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000389a:	00d5d59b          	srliw	a1,a1,0xd
    8000389e:	0001c797          	auipc	a5,0x1c
    800038a2:	7b67a783          	lw	a5,1974(a5) # 80020054 <sb+0x1c>
    800038a6:	9dbd                	addw	a1,a1,a5
    800038a8:	00000097          	auipc	ra,0x0
    800038ac:	d9e080e7          	jalr	-610(ra) # 80003646 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800038b0:	0074f713          	andi	a4,s1,7
    800038b4:	4785                	li	a5,1
    800038b6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800038ba:	14ce                	slli	s1,s1,0x33
    800038bc:	90d9                	srli	s1,s1,0x36
    800038be:	00950733          	add	a4,a0,s1
    800038c2:	05874703          	lbu	a4,88(a4)
    800038c6:	00e7f6b3          	and	a3,a5,a4
    800038ca:	c69d                	beqz	a3,800038f8 <bfree+0x6c>
    800038cc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800038ce:	94aa                	add	s1,s1,a0
    800038d0:	fff7c793          	not	a5,a5
    800038d4:	8f7d                	and	a4,a4,a5
    800038d6:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800038da:	00001097          	auipc	ra,0x1
    800038de:	120080e7          	jalr	288(ra) # 800049fa <log_write>
  brelse(bp);
    800038e2:	854a                	mv	a0,s2
    800038e4:	00000097          	auipc	ra,0x0
    800038e8:	e92080e7          	jalr	-366(ra) # 80003776 <brelse>
}
    800038ec:	60e2                	ld	ra,24(sp)
    800038ee:	6442                	ld	s0,16(sp)
    800038f0:	64a2                	ld	s1,8(sp)
    800038f2:	6902                	ld	s2,0(sp)
    800038f4:	6105                	addi	sp,sp,32
    800038f6:	8082                	ret
    panic("freeing free block");
    800038f8:	00005517          	auipc	a0,0x5
    800038fc:	cb850513          	addi	a0,a0,-840 # 800085b0 <syscalls+0xf8>
    80003900:	ffffd097          	auipc	ra,0xffffd
    80003904:	c3a080e7          	jalr	-966(ra) # 8000053a <panic>

0000000080003908 <balloc>:
{
    80003908:	711d                	addi	sp,sp,-96
    8000390a:	ec86                	sd	ra,88(sp)
    8000390c:	e8a2                	sd	s0,80(sp)
    8000390e:	e4a6                	sd	s1,72(sp)
    80003910:	e0ca                	sd	s2,64(sp)
    80003912:	fc4e                	sd	s3,56(sp)
    80003914:	f852                	sd	s4,48(sp)
    80003916:	f456                	sd	s5,40(sp)
    80003918:	f05a                	sd	s6,32(sp)
    8000391a:	ec5e                	sd	s7,24(sp)
    8000391c:	e862                	sd	s8,16(sp)
    8000391e:	e466                	sd	s9,8(sp)
    80003920:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003922:	0001c797          	auipc	a5,0x1c
    80003926:	71a7a783          	lw	a5,1818(a5) # 8002003c <sb+0x4>
    8000392a:	cbc1                	beqz	a5,800039ba <balloc+0xb2>
    8000392c:	8baa                	mv	s7,a0
    8000392e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003930:	0001cb17          	auipc	s6,0x1c
    80003934:	708b0b13          	addi	s6,s6,1800 # 80020038 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003938:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000393a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000393c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000393e:	6c89                	lui	s9,0x2
    80003940:	a831                	j	8000395c <balloc+0x54>
    brelse(bp);
    80003942:	854a                	mv	a0,s2
    80003944:	00000097          	auipc	ra,0x0
    80003948:	e32080e7          	jalr	-462(ra) # 80003776 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000394c:	015c87bb          	addw	a5,s9,s5
    80003950:	00078a9b          	sext.w	s5,a5
    80003954:	004b2703          	lw	a4,4(s6)
    80003958:	06eaf163          	bgeu	s5,a4,800039ba <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    8000395c:	41fad79b          	sraiw	a5,s5,0x1f
    80003960:	0137d79b          	srliw	a5,a5,0x13
    80003964:	015787bb          	addw	a5,a5,s5
    80003968:	40d7d79b          	sraiw	a5,a5,0xd
    8000396c:	01cb2583          	lw	a1,28(s6)
    80003970:	9dbd                	addw	a1,a1,a5
    80003972:	855e                	mv	a0,s7
    80003974:	00000097          	auipc	ra,0x0
    80003978:	cd2080e7          	jalr	-814(ra) # 80003646 <bread>
    8000397c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000397e:	004b2503          	lw	a0,4(s6)
    80003982:	000a849b          	sext.w	s1,s5
    80003986:	8762                	mv	a4,s8
    80003988:	faa4fde3          	bgeu	s1,a0,80003942 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000398c:	00777693          	andi	a3,a4,7
    80003990:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003994:	41f7579b          	sraiw	a5,a4,0x1f
    80003998:	01d7d79b          	srliw	a5,a5,0x1d
    8000399c:	9fb9                	addw	a5,a5,a4
    8000399e:	4037d79b          	sraiw	a5,a5,0x3
    800039a2:	00f90633          	add	a2,s2,a5
    800039a6:	05864603          	lbu	a2,88(a2)
    800039aa:	00c6f5b3          	and	a1,a3,a2
    800039ae:	cd91                	beqz	a1,800039ca <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039b0:	2705                	addiw	a4,a4,1
    800039b2:	2485                	addiw	s1,s1,1
    800039b4:	fd471ae3          	bne	a4,s4,80003988 <balloc+0x80>
    800039b8:	b769                	j	80003942 <balloc+0x3a>
  panic("balloc: out of blocks");
    800039ba:	00005517          	auipc	a0,0x5
    800039be:	c0e50513          	addi	a0,a0,-1010 # 800085c8 <syscalls+0x110>
    800039c2:	ffffd097          	auipc	ra,0xffffd
    800039c6:	b78080e7          	jalr	-1160(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800039ca:	97ca                	add	a5,a5,s2
    800039cc:	8e55                	or	a2,a2,a3
    800039ce:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800039d2:	854a                	mv	a0,s2
    800039d4:	00001097          	auipc	ra,0x1
    800039d8:	026080e7          	jalr	38(ra) # 800049fa <log_write>
        brelse(bp);
    800039dc:	854a                	mv	a0,s2
    800039de:	00000097          	auipc	ra,0x0
    800039e2:	d98080e7          	jalr	-616(ra) # 80003776 <brelse>
  bp = bread(dev, bno);
    800039e6:	85a6                	mv	a1,s1
    800039e8:	855e                	mv	a0,s7
    800039ea:	00000097          	auipc	ra,0x0
    800039ee:	c5c080e7          	jalr	-932(ra) # 80003646 <bread>
    800039f2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800039f4:	40000613          	li	a2,1024
    800039f8:	4581                	li	a1,0
    800039fa:	05850513          	addi	a0,a0,88
    800039fe:	ffffd097          	auipc	ra,0xffffd
    80003a02:	2ce080e7          	jalr	718(ra) # 80000ccc <memset>
  log_write(bp);
    80003a06:	854a                	mv	a0,s2
    80003a08:	00001097          	auipc	ra,0x1
    80003a0c:	ff2080e7          	jalr	-14(ra) # 800049fa <log_write>
  brelse(bp);
    80003a10:	854a                	mv	a0,s2
    80003a12:	00000097          	auipc	ra,0x0
    80003a16:	d64080e7          	jalr	-668(ra) # 80003776 <brelse>
}
    80003a1a:	8526                	mv	a0,s1
    80003a1c:	60e6                	ld	ra,88(sp)
    80003a1e:	6446                	ld	s0,80(sp)
    80003a20:	64a6                	ld	s1,72(sp)
    80003a22:	6906                	ld	s2,64(sp)
    80003a24:	79e2                	ld	s3,56(sp)
    80003a26:	7a42                	ld	s4,48(sp)
    80003a28:	7aa2                	ld	s5,40(sp)
    80003a2a:	7b02                	ld	s6,32(sp)
    80003a2c:	6be2                	ld	s7,24(sp)
    80003a2e:	6c42                	ld	s8,16(sp)
    80003a30:	6ca2                	ld	s9,8(sp)
    80003a32:	6125                	addi	sp,sp,96
    80003a34:	8082                	ret

0000000080003a36 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003a36:	7179                	addi	sp,sp,-48
    80003a38:	f406                	sd	ra,40(sp)
    80003a3a:	f022                	sd	s0,32(sp)
    80003a3c:	ec26                	sd	s1,24(sp)
    80003a3e:	e84a                	sd	s2,16(sp)
    80003a40:	e44e                	sd	s3,8(sp)
    80003a42:	e052                	sd	s4,0(sp)
    80003a44:	1800                	addi	s0,sp,48
    80003a46:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003a48:	47ad                	li	a5,11
    80003a4a:	04b7fe63          	bgeu	a5,a1,80003aa6 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003a4e:	ff45849b          	addiw	s1,a1,-12
    80003a52:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003a56:	0ff00793          	li	a5,255
    80003a5a:	0ae7e463          	bltu	a5,a4,80003b02 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003a5e:	08052583          	lw	a1,128(a0)
    80003a62:	c5b5                	beqz	a1,80003ace <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003a64:	00092503          	lw	a0,0(s2)
    80003a68:	00000097          	auipc	ra,0x0
    80003a6c:	bde080e7          	jalr	-1058(ra) # 80003646 <bread>
    80003a70:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a72:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a76:	02049713          	slli	a4,s1,0x20
    80003a7a:	01e75593          	srli	a1,a4,0x1e
    80003a7e:	00b784b3          	add	s1,a5,a1
    80003a82:	0004a983          	lw	s3,0(s1)
    80003a86:	04098e63          	beqz	s3,80003ae2 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003a8a:	8552                	mv	a0,s4
    80003a8c:	00000097          	auipc	ra,0x0
    80003a90:	cea080e7          	jalr	-790(ra) # 80003776 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a94:	854e                	mv	a0,s3
    80003a96:	70a2                	ld	ra,40(sp)
    80003a98:	7402                	ld	s0,32(sp)
    80003a9a:	64e2                	ld	s1,24(sp)
    80003a9c:	6942                	ld	s2,16(sp)
    80003a9e:	69a2                	ld	s3,8(sp)
    80003aa0:	6a02                	ld	s4,0(sp)
    80003aa2:	6145                	addi	sp,sp,48
    80003aa4:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003aa6:	02059793          	slli	a5,a1,0x20
    80003aaa:	01e7d593          	srli	a1,a5,0x1e
    80003aae:	00b504b3          	add	s1,a0,a1
    80003ab2:	0504a983          	lw	s3,80(s1)
    80003ab6:	fc099fe3          	bnez	s3,80003a94 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003aba:	4108                	lw	a0,0(a0)
    80003abc:	00000097          	auipc	ra,0x0
    80003ac0:	e4c080e7          	jalr	-436(ra) # 80003908 <balloc>
    80003ac4:	0005099b          	sext.w	s3,a0
    80003ac8:	0534a823          	sw	s3,80(s1)
    80003acc:	b7e1                	j	80003a94 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003ace:	4108                	lw	a0,0(a0)
    80003ad0:	00000097          	auipc	ra,0x0
    80003ad4:	e38080e7          	jalr	-456(ra) # 80003908 <balloc>
    80003ad8:	0005059b          	sext.w	a1,a0
    80003adc:	08b92023          	sw	a1,128(s2)
    80003ae0:	b751                	j	80003a64 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003ae2:	00092503          	lw	a0,0(s2)
    80003ae6:	00000097          	auipc	ra,0x0
    80003aea:	e22080e7          	jalr	-478(ra) # 80003908 <balloc>
    80003aee:	0005099b          	sext.w	s3,a0
    80003af2:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003af6:	8552                	mv	a0,s4
    80003af8:	00001097          	auipc	ra,0x1
    80003afc:	f02080e7          	jalr	-254(ra) # 800049fa <log_write>
    80003b00:	b769                	j	80003a8a <bmap+0x54>
  panic("bmap: out of range");
    80003b02:	00005517          	auipc	a0,0x5
    80003b06:	ade50513          	addi	a0,a0,-1314 # 800085e0 <syscalls+0x128>
    80003b0a:	ffffd097          	auipc	ra,0xffffd
    80003b0e:	a30080e7          	jalr	-1488(ra) # 8000053a <panic>

0000000080003b12 <iget>:
{
    80003b12:	7179                	addi	sp,sp,-48
    80003b14:	f406                	sd	ra,40(sp)
    80003b16:	f022                	sd	s0,32(sp)
    80003b18:	ec26                	sd	s1,24(sp)
    80003b1a:	e84a                	sd	s2,16(sp)
    80003b1c:	e44e                	sd	s3,8(sp)
    80003b1e:	e052                	sd	s4,0(sp)
    80003b20:	1800                	addi	s0,sp,48
    80003b22:	89aa                	mv	s3,a0
    80003b24:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003b26:	0001c517          	auipc	a0,0x1c
    80003b2a:	53250513          	addi	a0,a0,1330 # 80020058 <itable>
    80003b2e:	ffffd097          	auipc	ra,0xffffd
    80003b32:	0a2080e7          	jalr	162(ra) # 80000bd0 <acquire>
  empty = 0;
    80003b36:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b38:	0001c497          	auipc	s1,0x1c
    80003b3c:	53848493          	addi	s1,s1,1336 # 80020070 <itable+0x18>
    80003b40:	0001e697          	auipc	a3,0x1e
    80003b44:	fc068693          	addi	a3,a3,-64 # 80021b00 <log>
    80003b48:	a039                	j	80003b56 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b4a:	02090b63          	beqz	s2,80003b80 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b4e:	08848493          	addi	s1,s1,136
    80003b52:	02d48a63          	beq	s1,a3,80003b86 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003b56:	449c                	lw	a5,8(s1)
    80003b58:	fef059e3          	blez	a5,80003b4a <iget+0x38>
    80003b5c:	4098                	lw	a4,0(s1)
    80003b5e:	ff3716e3          	bne	a4,s3,80003b4a <iget+0x38>
    80003b62:	40d8                	lw	a4,4(s1)
    80003b64:	ff4713e3          	bne	a4,s4,80003b4a <iget+0x38>
      ip->ref++;
    80003b68:	2785                	addiw	a5,a5,1
    80003b6a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b6c:	0001c517          	auipc	a0,0x1c
    80003b70:	4ec50513          	addi	a0,a0,1260 # 80020058 <itable>
    80003b74:	ffffd097          	auipc	ra,0xffffd
    80003b78:	110080e7          	jalr	272(ra) # 80000c84 <release>
      return ip;
    80003b7c:	8926                	mv	s2,s1
    80003b7e:	a03d                	j	80003bac <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b80:	f7f9                	bnez	a5,80003b4e <iget+0x3c>
    80003b82:	8926                	mv	s2,s1
    80003b84:	b7e9                	j	80003b4e <iget+0x3c>
  if(empty == 0)
    80003b86:	02090c63          	beqz	s2,80003bbe <iget+0xac>
  ip->dev = dev;
    80003b8a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b8e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b92:	4785                	li	a5,1
    80003b94:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b98:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b9c:	0001c517          	auipc	a0,0x1c
    80003ba0:	4bc50513          	addi	a0,a0,1212 # 80020058 <itable>
    80003ba4:	ffffd097          	auipc	ra,0xffffd
    80003ba8:	0e0080e7          	jalr	224(ra) # 80000c84 <release>
}
    80003bac:	854a                	mv	a0,s2
    80003bae:	70a2                	ld	ra,40(sp)
    80003bb0:	7402                	ld	s0,32(sp)
    80003bb2:	64e2                	ld	s1,24(sp)
    80003bb4:	6942                	ld	s2,16(sp)
    80003bb6:	69a2                	ld	s3,8(sp)
    80003bb8:	6a02                	ld	s4,0(sp)
    80003bba:	6145                	addi	sp,sp,48
    80003bbc:	8082                	ret
    panic("iget: no inodes");
    80003bbe:	00005517          	auipc	a0,0x5
    80003bc2:	a3a50513          	addi	a0,a0,-1478 # 800085f8 <syscalls+0x140>
    80003bc6:	ffffd097          	auipc	ra,0xffffd
    80003bca:	974080e7          	jalr	-1676(ra) # 8000053a <panic>

0000000080003bce <fsinit>:
fsinit(int dev) {
    80003bce:	7179                	addi	sp,sp,-48
    80003bd0:	f406                	sd	ra,40(sp)
    80003bd2:	f022                	sd	s0,32(sp)
    80003bd4:	ec26                	sd	s1,24(sp)
    80003bd6:	e84a                	sd	s2,16(sp)
    80003bd8:	e44e                	sd	s3,8(sp)
    80003bda:	1800                	addi	s0,sp,48
    80003bdc:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003bde:	4585                	li	a1,1
    80003be0:	00000097          	auipc	ra,0x0
    80003be4:	a66080e7          	jalr	-1434(ra) # 80003646 <bread>
    80003be8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003bea:	0001c997          	auipc	s3,0x1c
    80003bee:	44e98993          	addi	s3,s3,1102 # 80020038 <sb>
    80003bf2:	02000613          	li	a2,32
    80003bf6:	05850593          	addi	a1,a0,88
    80003bfa:	854e                	mv	a0,s3
    80003bfc:	ffffd097          	auipc	ra,0xffffd
    80003c00:	12c080e7          	jalr	300(ra) # 80000d28 <memmove>
  brelse(bp);
    80003c04:	8526                	mv	a0,s1
    80003c06:	00000097          	auipc	ra,0x0
    80003c0a:	b70080e7          	jalr	-1168(ra) # 80003776 <brelse>
  if(sb.magic != FSMAGIC)
    80003c0e:	0009a703          	lw	a4,0(s3)
    80003c12:	102037b7          	lui	a5,0x10203
    80003c16:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003c1a:	02f71263          	bne	a4,a5,80003c3e <fsinit+0x70>
  initlog(dev, &sb);
    80003c1e:	0001c597          	auipc	a1,0x1c
    80003c22:	41a58593          	addi	a1,a1,1050 # 80020038 <sb>
    80003c26:	854a                	mv	a0,s2
    80003c28:	00001097          	auipc	ra,0x1
    80003c2c:	b56080e7          	jalr	-1194(ra) # 8000477e <initlog>
}
    80003c30:	70a2                	ld	ra,40(sp)
    80003c32:	7402                	ld	s0,32(sp)
    80003c34:	64e2                	ld	s1,24(sp)
    80003c36:	6942                	ld	s2,16(sp)
    80003c38:	69a2                	ld	s3,8(sp)
    80003c3a:	6145                	addi	sp,sp,48
    80003c3c:	8082                	ret
    panic("invalid file system");
    80003c3e:	00005517          	auipc	a0,0x5
    80003c42:	9ca50513          	addi	a0,a0,-1590 # 80008608 <syscalls+0x150>
    80003c46:	ffffd097          	auipc	ra,0xffffd
    80003c4a:	8f4080e7          	jalr	-1804(ra) # 8000053a <panic>

0000000080003c4e <iinit>:
{
    80003c4e:	7179                	addi	sp,sp,-48
    80003c50:	f406                	sd	ra,40(sp)
    80003c52:	f022                	sd	s0,32(sp)
    80003c54:	ec26                	sd	s1,24(sp)
    80003c56:	e84a                	sd	s2,16(sp)
    80003c58:	e44e                	sd	s3,8(sp)
    80003c5a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003c5c:	00005597          	auipc	a1,0x5
    80003c60:	9c458593          	addi	a1,a1,-1596 # 80008620 <syscalls+0x168>
    80003c64:	0001c517          	auipc	a0,0x1c
    80003c68:	3f450513          	addi	a0,a0,1012 # 80020058 <itable>
    80003c6c:	ffffd097          	auipc	ra,0xffffd
    80003c70:	ed4080e7          	jalr	-300(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c74:	0001c497          	auipc	s1,0x1c
    80003c78:	40c48493          	addi	s1,s1,1036 # 80020080 <itable+0x28>
    80003c7c:	0001e997          	auipc	s3,0x1e
    80003c80:	e9498993          	addi	s3,s3,-364 # 80021b10 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c84:	00005917          	auipc	s2,0x5
    80003c88:	9a490913          	addi	s2,s2,-1628 # 80008628 <syscalls+0x170>
    80003c8c:	85ca                	mv	a1,s2
    80003c8e:	8526                	mv	a0,s1
    80003c90:	00001097          	auipc	ra,0x1
    80003c94:	e4e080e7          	jalr	-434(ra) # 80004ade <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c98:	08848493          	addi	s1,s1,136
    80003c9c:	ff3498e3          	bne	s1,s3,80003c8c <iinit+0x3e>
}
    80003ca0:	70a2                	ld	ra,40(sp)
    80003ca2:	7402                	ld	s0,32(sp)
    80003ca4:	64e2                	ld	s1,24(sp)
    80003ca6:	6942                	ld	s2,16(sp)
    80003ca8:	69a2                	ld	s3,8(sp)
    80003caa:	6145                	addi	sp,sp,48
    80003cac:	8082                	ret

0000000080003cae <ialloc>:
{
    80003cae:	715d                	addi	sp,sp,-80
    80003cb0:	e486                	sd	ra,72(sp)
    80003cb2:	e0a2                	sd	s0,64(sp)
    80003cb4:	fc26                	sd	s1,56(sp)
    80003cb6:	f84a                	sd	s2,48(sp)
    80003cb8:	f44e                	sd	s3,40(sp)
    80003cba:	f052                	sd	s4,32(sp)
    80003cbc:	ec56                	sd	s5,24(sp)
    80003cbe:	e85a                	sd	s6,16(sp)
    80003cc0:	e45e                	sd	s7,8(sp)
    80003cc2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cc4:	0001c717          	auipc	a4,0x1c
    80003cc8:	38072703          	lw	a4,896(a4) # 80020044 <sb+0xc>
    80003ccc:	4785                	li	a5,1
    80003cce:	04e7fa63          	bgeu	a5,a4,80003d22 <ialloc+0x74>
    80003cd2:	8aaa                	mv	s5,a0
    80003cd4:	8bae                	mv	s7,a1
    80003cd6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003cd8:	0001ca17          	auipc	s4,0x1c
    80003cdc:	360a0a13          	addi	s4,s4,864 # 80020038 <sb>
    80003ce0:	00048b1b          	sext.w	s6,s1
    80003ce4:	0044d593          	srli	a1,s1,0x4
    80003ce8:	018a2783          	lw	a5,24(s4)
    80003cec:	9dbd                	addw	a1,a1,a5
    80003cee:	8556                	mv	a0,s5
    80003cf0:	00000097          	auipc	ra,0x0
    80003cf4:	956080e7          	jalr	-1706(ra) # 80003646 <bread>
    80003cf8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003cfa:	05850993          	addi	s3,a0,88
    80003cfe:	00f4f793          	andi	a5,s1,15
    80003d02:	079a                	slli	a5,a5,0x6
    80003d04:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003d06:	00099783          	lh	a5,0(s3)
    80003d0a:	c785                	beqz	a5,80003d32 <ialloc+0x84>
    brelse(bp);
    80003d0c:	00000097          	auipc	ra,0x0
    80003d10:	a6a080e7          	jalr	-1430(ra) # 80003776 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d14:	0485                	addi	s1,s1,1
    80003d16:	00ca2703          	lw	a4,12(s4)
    80003d1a:	0004879b          	sext.w	a5,s1
    80003d1e:	fce7e1e3          	bltu	a5,a4,80003ce0 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003d22:	00005517          	auipc	a0,0x5
    80003d26:	90e50513          	addi	a0,a0,-1778 # 80008630 <syscalls+0x178>
    80003d2a:	ffffd097          	auipc	ra,0xffffd
    80003d2e:	810080e7          	jalr	-2032(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    80003d32:	04000613          	li	a2,64
    80003d36:	4581                	li	a1,0
    80003d38:	854e                	mv	a0,s3
    80003d3a:	ffffd097          	auipc	ra,0xffffd
    80003d3e:	f92080e7          	jalr	-110(ra) # 80000ccc <memset>
      dip->type = type;
    80003d42:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003d46:	854a                	mv	a0,s2
    80003d48:	00001097          	auipc	ra,0x1
    80003d4c:	cb2080e7          	jalr	-846(ra) # 800049fa <log_write>
      brelse(bp);
    80003d50:	854a                	mv	a0,s2
    80003d52:	00000097          	auipc	ra,0x0
    80003d56:	a24080e7          	jalr	-1500(ra) # 80003776 <brelse>
      return iget(dev, inum);
    80003d5a:	85da                	mv	a1,s6
    80003d5c:	8556                	mv	a0,s5
    80003d5e:	00000097          	auipc	ra,0x0
    80003d62:	db4080e7          	jalr	-588(ra) # 80003b12 <iget>
}
    80003d66:	60a6                	ld	ra,72(sp)
    80003d68:	6406                	ld	s0,64(sp)
    80003d6a:	74e2                	ld	s1,56(sp)
    80003d6c:	7942                	ld	s2,48(sp)
    80003d6e:	79a2                	ld	s3,40(sp)
    80003d70:	7a02                	ld	s4,32(sp)
    80003d72:	6ae2                	ld	s5,24(sp)
    80003d74:	6b42                	ld	s6,16(sp)
    80003d76:	6ba2                	ld	s7,8(sp)
    80003d78:	6161                	addi	sp,sp,80
    80003d7a:	8082                	ret

0000000080003d7c <iupdate>:
{
    80003d7c:	1101                	addi	sp,sp,-32
    80003d7e:	ec06                	sd	ra,24(sp)
    80003d80:	e822                	sd	s0,16(sp)
    80003d82:	e426                	sd	s1,8(sp)
    80003d84:	e04a                	sd	s2,0(sp)
    80003d86:	1000                	addi	s0,sp,32
    80003d88:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d8a:	415c                	lw	a5,4(a0)
    80003d8c:	0047d79b          	srliw	a5,a5,0x4
    80003d90:	0001c597          	auipc	a1,0x1c
    80003d94:	2c05a583          	lw	a1,704(a1) # 80020050 <sb+0x18>
    80003d98:	9dbd                	addw	a1,a1,a5
    80003d9a:	4108                	lw	a0,0(a0)
    80003d9c:	00000097          	auipc	ra,0x0
    80003da0:	8aa080e7          	jalr	-1878(ra) # 80003646 <bread>
    80003da4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003da6:	05850793          	addi	a5,a0,88
    80003daa:	40d8                	lw	a4,4(s1)
    80003dac:	8b3d                	andi	a4,a4,15
    80003dae:	071a                	slli	a4,a4,0x6
    80003db0:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003db2:	04449703          	lh	a4,68(s1)
    80003db6:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003dba:	04649703          	lh	a4,70(s1)
    80003dbe:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003dc2:	04849703          	lh	a4,72(s1)
    80003dc6:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003dca:	04a49703          	lh	a4,74(s1)
    80003dce:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003dd2:	44f8                	lw	a4,76(s1)
    80003dd4:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003dd6:	03400613          	li	a2,52
    80003dda:	05048593          	addi	a1,s1,80
    80003dde:	00c78513          	addi	a0,a5,12
    80003de2:	ffffd097          	auipc	ra,0xffffd
    80003de6:	f46080e7          	jalr	-186(ra) # 80000d28 <memmove>
  log_write(bp);
    80003dea:	854a                	mv	a0,s2
    80003dec:	00001097          	auipc	ra,0x1
    80003df0:	c0e080e7          	jalr	-1010(ra) # 800049fa <log_write>
  brelse(bp);
    80003df4:	854a                	mv	a0,s2
    80003df6:	00000097          	auipc	ra,0x0
    80003dfa:	980080e7          	jalr	-1664(ra) # 80003776 <brelse>
}
    80003dfe:	60e2                	ld	ra,24(sp)
    80003e00:	6442                	ld	s0,16(sp)
    80003e02:	64a2                	ld	s1,8(sp)
    80003e04:	6902                	ld	s2,0(sp)
    80003e06:	6105                	addi	sp,sp,32
    80003e08:	8082                	ret

0000000080003e0a <idup>:
{
    80003e0a:	1101                	addi	sp,sp,-32
    80003e0c:	ec06                	sd	ra,24(sp)
    80003e0e:	e822                	sd	s0,16(sp)
    80003e10:	e426                	sd	s1,8(sp)
    80003e12:	1000                	addi	s0,sp,32
    80003e14:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e16:	0001c517          	auipc	a0,0x1c
    80003e1a:	24250513          	addi	a0,a0,578 # 80020058 <itable>
    80003e1e:	ffffd097          	auipc	ra,0xffffd
    80003e22:	db2080e7          	jalr	-590(ra) # 80000bd0 <acquire>
  ip->ref++;
    80003e26:	449c                	lw	a5,8(s1)
    80003e28:	2785                	addiw	a5,a5,1
    80003e2a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e2c:	0001c517          	auipc	a0,0x1c
    80003e30:	22c50513          	addi	a0,a0,556 # 80020058 <itable>
    80003e34:	ffffd097          	auipc	ra,0xffffd
    80003e38:	e50080e7          	jalr	-432(ra) # 80000c84 <release>
}
    80003e3c:	8526                	mv	a0,s1
    80003e3e:	60e2                	ld	ra,24(sp)
    80003e40:	6442                	ld	s0,16(sp)
    80003e42:	64a2                	ld	s1,8(sp)
    80003e44:	6105                	addi	sp,sp,32
    80003e46:	8082                	ret

0000000080003e48 <ilock>:
{
    80003e48:	1101                	addi	sp,sp,-32
    80003e4a:	ec06                	sd	ra,24(sp)
    80003e4c:	e822                	sd	s0,16(sp)
    80003e4e:	e426                	sd	s1,8(sp)
    80003e50:	e04a                	sd	s2,0(sp)
    80003e52:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003e54:	c115                	beqz	a0,80003e78 <ilock+0x30>
    80003e56:	84aa                	mv	s1,a0
    80003e58:	451c                	lw	a5,8(a0)
    80003e5a:	00f05f63          	blez	a5,80003e78 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003e5e:	0541                	addi	a0,a0,16
    80003e60:	00001097          	auipc	ra,0x1
    80003e64:	cb8080e7          	jalr	-840(ra) # 80004b18 <acquiresleep>
  if(ip->valid == 0){
    80003e68:	40bc                	lw	a5,64(s1)
    80003e6a:	cf99                	beqz	a5,80003e88 <ilock+0x40>
}
    80003e6c:	60e2                	ld	ra,24(sp)
    80003e6e:	6442                	ld	s0,16(sp)
    80003e70:	64a2                	ld	s1,8(sp)
    80003e72:	6902                	ld	s2,0(sp)
    80003e74:	6105                	addi	sp,sp,32
    80003e76:	8082                	ret
    panic("ilock");
    80003e78:	00004517          	auipc	a0,0x4
    80003e7c:	7d050513          	addi	a0,a0,2000 # 80008648 <syscalls+0x190>
    80003e80:	ffffc097          	auipc	ra,0xffffc
    80003e84:	6ba080e7          	jalr	1722(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e88:	40dc                	lw	a5,4(s1)
    80003e8a:	0047d79b          	srliw	a5,a5,0x4
    80003e8e:	0001c597          	auipc	a1,0x1c
    80003e92:	1c25a583          	lw	a1,450(a1) # 80020050 <sb+0x18>
    80003e96:	9dbd                	addw	a1,a1,a5
    80003e98:	4088                	lw	a0,0(s1)
    80003e9a:	fffff097          	auipc	ra,0xfffff
    80003e9e:	7ac080e7          	jalr	1964(ra) # 80003646 <bread>
    80003ea2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ea4:	05850593          	addi	a1,a0,88
    80003ea8:	40dc                	lw	a5,4(s1)
    80003eaa:	8bbd                	andi	a5,a5,15
    80003eac:	079a                	slli	a5,a5,0x6
    80003eae:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003eb0:	00059783          	lh	a5,0(a1)
    80003eb4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003eb8:	00259783          	lh	a5,2(a1)
    80003ebc:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003ec0:	00459783          	lh	a5,4(a1)
    80003ec4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003ec8:	00659783          	lh	a5,6(a1)
    80003ecc:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ed0:	459c                	lw	a5,8(a1)
    80003ed2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ed4:	03400613          	li	a2,52
    80003ed8:	05b1                	addi	a1,a1,12
    80003eda:	05048513          	addi	a0,s1,80
    80003ede:	ffffd097          	auipc	ra,0xffffd
    80003ee2:	e4a080e7          	jalr	-438(ra) # 80000d28 <memmove>
    brelse(bp);
    80003ee6:	854a                	mv	a0,s2
    80003ee8:	00000097          	auipc	ra,0x0
    80003eec:	88e080e7          	jalr	-1906(ra) # 80003776 <brelse>
    ip->valid = 1;
    80003ef0:	4785                	li	a5,1
    80003ef2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ef4:	04449783          	lh	a5,68(s1)
    80003ef8:	fbb5                	bnez	a5,80003e6c <ilock+0x24>
      panic("ilock: no type");
    80003efa:	00004517          	auipc	a0,0x4
    80003efe:	75650513          	addi	a0,a0,1878 # 80008650 <syscalls+0x198>
    80003f02:	ffffc097          	auipc	ra,0xffffc
    80003f06:	638080e7          	jalr	1592(ra) # 8000053a <panic>

0000000080003f0a <iunlock>:
{
    80003f0a:	1101                	addi	sp,sp,-32
    80003f0c:	ec06                	sd	ra,24(sp)
    80003f0e:	e822                	sd	s0,16(sp)
    80003f10:	e426                	sd	s1,8(sp)
    80003f12:	e04a                	sd	s2,0(sp)
    80003f14:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003f16:	c905                	beqz	a0,80003f46 <iunlock+0x3c>
    80003f18:	84aa                	mv	s1,a0
    80003f1a:	01050913          	addi	s2,a0,16
    80003f1e:	854a                	mv	a0,s2
    80003f20:	00001097          	auipc	ra,0x1
    80003f24:	c92080e7          	jalr	-878(ra) # 80004bb2 <holdingsleep>
    80003f28:	cd19                	beqz	a0,80003f46 <iunlock+0x3c>
    80003f2a:	449c                	lw	a5,8(s1)
    80003f2c:	00f05d63          	blez	a5,80003f46 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003f30:	854a                	mv	a0,s2
    80003f32:	00001097          	auipc	ra,0x1
    80003f36:	c3c080e7          	jalr	-964(ra) # 80004b6e <releasesleep>
}
    80003f3a:	60e2                	ld	ra,24(sp)
    80003f3c:	6442                	ld	s0,16(sp)
    80003f3e:	64a2                	ld	s1,8(sp)
    80003f40:	6902                	ld	s2,0(sp)
    80003f42:	6105                	addi	sp,sp,32
    80003f44:	8082                	ret
    panic("iunlock");
    80003f46:	00004517          	auipc	a0,0x4
    80003f4a:	71a50513          	addi	a0,a0,1818 # 80008660 <syscalls+0x1a8>
    80003f4e:	ffffc097          	auipc	ra,0xffffc
    80003f52:	5ec080e7          	jalr	1516(ra) # 8000053a <panic>

0000000080003f56 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003f56:	7179                	addi	sp,sp,-48
    80003f58:	f406                	sd	ra,40(sp)
    80003f5a:	f022                	sd	s0,32(sp)
    80003f5c:	ec26                	sd	s1,24(sp)
    80003f5e:	e84a                	sd	s2,16(sp)
    80003f60:	e44e                	sd	s3,8(sp)
    80003f62:	e052                	sd	s4,0(sp)
    80003f64:	1800                	addi	s0,sp,48
    80003f66:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f68:	05050493          	addi	s1,a0,80
    80003f6c:	08050913          	addi	s2,a0,128
    80003f70:	a021                	j	80003f78 <itrunc+0x22>
    80003f72:	0491                	addi	s1,s1,4
    80003f74:	01248d63          	beq	s1,s2,80003f8e <itrunc+0x38>
    if(ip->addrs[i]){
    80003f78:	408c                	lw	a1,0(s1)
    80003f7a:	dde5                	beqz	a1,80003f72 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f7c:	0009a503          	lw	a0,0(s3)
    80003f80:	00000097          	auipc	ra,0x0
    80003f84:	90c080e7          	jalr	-1780(ra) # 8000388c <bfree>
      ip->addrs[i] = 0;
    80003f88:	0004a023          	sw	zero,0(s1)
    80003f8c:	b7dd                	j	80003f72 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f8e:	0809a583          	lw	a1,128(s3)
    80003f92:	e185                	bnez	a1,80003fb2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f94:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f98:	854e                	mv	a0,s3
    80003f9a:	00000097          	auipc	ra,0x0
    80003f9e:	de2080e7          	jalr	-542(ra) # 80003d7c <iupdate>
}
    80003fa2:	70a2                	ld	ra,40(sp)
    80003fa4:	7402                	ld	s0,32(sp)
    80003fa6:	64e2                	ld	s1,24(sp)
    80003fa8:	6942                	ld	s2,16(sp)
    80003faa:	69a2                	ld	s3,8(sp)
    80003fac:	6a02                	ld	s4,0(sp)
    80003fae:	6145                	addi	sp,sp,48
    80003fb0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003fb2:	0009a503          	lw	a0,0(s3)
    80003fb6:	fffff097          	auipc	ra,0xfffff
    80003fba:	690080e7          	jalr	1680(ra) # 80003646 <bread>
    80003fbe:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003fc0:	05850493          	addi	s1,a0,88
    80003fc4:	45850913          	addi	s2,a0,1112
    80003fc8:	a021                	j	80003fd0 <itrunc+0x7a>
    80003fca:	0491                	addi	s1,s1,4
    80003fcc:	01248b63          	beq	s1,s2,80003fe2 <itrunc+0x8c>
      if(a[j])
    80003fd0:	408c                	lw	a1,0(s1)
    80003fd2:	dde5                	beqz	a1,80003fca <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003fd4:	0009a503          	lw	a0,0(s3)
    80003fd8:	00000097          	auipc	ra,0x0
    80003fdc:	8b4080e7          	jalr	-1868(ra) # 8000388c <bfree>
    80003fe0:	b7ed                	j	80003fca <itrunc+0x74>
    brelse(bp);
    80003fe2:	8552                	mv	a0,s4
    80003fe4:	fffff097          	auipc	ra,0xfffff
    80003fe8:	792080e7          	jalr	1938(ra) # 80003776 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003fec:	0809a583          	lw	a1,128(s3)
    80003ff0:	0009a503          	lw	a0,0(s3)
    80003ff4:	00000097          	auipc	ra,0x0
    80003ff8:	898080e7          	jalr	-1896(ra) # 8000388c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ffc:	0809a023          	sw	zero,128(s3)
    80004000:	bf51                	j	80003f94 <itrunc+0x3e>

0000000080004002 <iput>:
{
    80004002:	1101                	addi	sp,sp,-32
    80004004:	ec06                	sd	ra,24(sp)
    80004006:	e822                	sd	s0,16(sp)
    80004008:	e426                	sd	s1,8(sp)
    8000400a:	e04a                	sd	s2,0(sp)
    8000400c:	1000                	addi	s0,sp,32
    8000400e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004010:	0001c517          	auipc	a0,0x1c
    80004014:	04850513          	addi	a0,a0,72 # 80020058 <itable>
    80004018:	ffffd097          	auipc	ra,0xffffd
    8000401c:	bb8080e7          	jalr	-1096(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004020:	4498                	lw	a4,8(s1)
    80004022:	4785                	li	a5,1
    80004024:	02f70363          	beq	a4,a5,8000404a <iput+0x48>
  ip->ref--;
    80004028:	449c                	lw	a5,8(s1)
    8000402a:	37fd                	addiw	a5,a5,-1
    8000402c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000402e:	0001c517          	auipc	a0,0x1c
    80004032:	02a50513          	addi	a0,a0,42 # 80020058 <itable>
    80004036:	ffffd097          	auipc	ra,0xffffd
    8000403a:	c4e080e7          	jalr	-946(ra) # 80000c84 <release>
}
    8000403e:	60e2                	ld	ra,24(sp)
    80004040:	6442                	ld	s0,16(sp)
    80004042:	64a2                	ld	s1,8(sp)
    80004044:	6902                	ld	s2,0(sp)
    80004046:	6105                	addi	sp,sp,32
    80004048:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000404a:	40bc                	lw	a5,64(s1)
    8000404c:	dff1                	beqz	a5,80004028 <iput+0x26>
    8000404e:	04a49783          	lh	a5,74(s1)
    80004052:	fbf9                	bnez	a5,80004028 <iput+0x26>
    acquiresleep(&ip->lock);
    80004054:	01048913          	addi	s2,s1,16
    80004058:	854a                	mv	a0,s2
    8000405a:	00001097          	auipc	ra,0x1
    8000405e:	abe080e7          	jalr	-1346(ra) # 80004b18 <acquiresleep>
    release(&itable.lock);
    80004062:	0001c517          	auipc	a0,0x1c
    80004066:	ff650513          	addi	a0,a0,-10 # 80020058 <itable>
    8000406a:	ffffd097          	auipc	ra,0xffffd
    8000406e:	c1a080e7          	jalr	-998(ra) # 80000c84 <release>
    itrunc(ip);
    80004072:	8526                	mv	a0,s1
    80004074:	00000097          	auipc	ra,0x0
    80004078:	ee2080e7          	jalr	-286(ra) # 80003f56 <itrunc>
    ip->type = 0;
    8000407c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004080:	8526                	mv	a0,s1
    80004082:	00000097          	auipc	ra,0x0
    80004086:	cfa080e7          	jalr	-774(ra) # 80003d7c <iupdate>
    ip->valid = 0;
    8000408a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000408e:	854a                	mv	a0,s2
    80004090:	00001097          	auipc	ra,0x1
    80004094:	ade080e7          	jalr	-1314(ra) # 80004b6e <releasesleep>
    acquire(&itable.lock);
    80004098:	0001c517          	auipc	a0,0x1c
    8000409c:	fc050513          	addi	a0,a0,-64 # 80020058 <itable>
    800040a0:	ffffd097          	auipc	ra,0xffffd
    800040a4:	b30080e7          	jalr	-1232(ra) # 80000bd0 <acquire>
    800040a8:	b741                	j	80004028 <iput+0x26>

00000000800040aa <iunlockput>:
{
    800040aa:	1101                	addi	sp,sp,-32
    800040ac:	ec06                	sd	ra,24(sp)
    800040ae:	e822                	sd	s0,16(sp)
    800040b0:	e426                	sd	s1,8(sp)
    800040b2:	1000                	addi	s0,sp,32
    800040b4:	84aa                	mv	s1,a0
  iunlock(ip);
    800040b6:	00000097          	auipc	ra,0x0
    800040ba:	e54080e7          	jalr	-428(ra) # 80003f0a <iunlock>
  iput(ip);
    800040be:	8526                	mv	a0,s1
    800040c0:	00000097          	auipc	ra,0x0
    800040c4:	f42080e7          	jalr	-190(ra) # 80004002 <iput>
}
    800040c8:	60e2                	ld	ra,24(sp)
    800040ca:	6442                	ld	s0,16(sp)
    800040cc:	64a2                	ld	s1,8(sp)
    800040ce:	6105                	addi	sp,sp,32
    800040d0:	8082                	ret

00000000800040d2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800040d2:	1141                	addi	sp,sp,-16
    800040d4:	e422                	sd	s0,8(sp)
    800040d6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800040d8:	411c                	lw	a5,0(a0)
    800040da:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800040dc:	415c                	lw	a5,4(a0)
    800040de:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800040e0:	04451783          	lh	a5,68(a0)
    800040e4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800040e8:	04a51783          	lh	a5,74(a0)
    800040ec:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800040f0:	04c56783          	lwu	a5,76(a0)
    800040f4:	e99c                	sd	a5,16(a1)
}
    800040f6:	6422                	ld	s0,8(sp)
    800040f8:	0141                	addi	sp,sp,16
    800040fa:	8082                	ret

00000000800040fc <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040fc:	457c                	lw	a5,76(a0)
    800040fe:	0ed7e963          	bltu	a5,a3,800041f0 <readi+0xf4>
{
    80004102:	7159                	addi	sp,sp,-112
    80004104:	f486                	sd	ra,104(sp)
    80004106:	f0a2                	sd	s0,96(sp)
    80004108:	eca6                	sd	s1,88(sp)
    8000410a:	e8ca                	sd	s2,80(sp)
    8000410c:	e4ce                	sd	s3,72(sp)
    8000410e:	e0d2                	sd	s4,64(sp)
    80004110:	fc56                	sd	s5,56(sp)
    80004112:	f85a                	sd	s6,48(sp)
    80004114:	f45e                	sd	s7,40(sp)
    80004116:	f062                	sd	s8,32(sp)
    80004118:	ec66                	sd	s9,24(sp)
    8000411a:	e86a                	sd	s10,16(sp)
    8000411c:	e46e                	sd	s11,8(sp)
    8000411e:	1880                	addi	s0,sp,112
    80004120:	8baa                	mv	s7,a0
    80004122:	8c2e                	mv	s8,a1
    80004124:	8ab2                	mv	s5,a2
    80004126:	84b6                	mv	s1,a3
    80004128:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000412a:	9f35                	addw	a4,a4,a3
    return 0;
    8000412c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000412e:	0ad76063          	bltu	a4,a3,800041ce <readi+0xd2>
  if(off + n > ip->size)
    80004132:	00e7f463          	bgeu	a5,a4,8000413a <readi+0x3e>
    n = ip->size - off;
    80004136:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000413a:	0a0b0963          	beqz	s6,800041ec <readi+0xf0>
    8000413e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004140:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004144:	5cfd                	li	s9,-1
    80004146:	a82d                	j	80004180 <readi+0x84>
    80004148:	020a1d93          	slli	s11,s4,0x20
    8000414c:	020ddd93          	srli	s11,s11,0x20
    80004150:	05890613          	addi	a2,s2,88
    80004154:	86ee                	mv	a3,s11
    80004156:	963a                	add	a2,a2,a4
    80004158:	85d6                	mv	a1,s5
    8000415a:	8562                	mv	a0,s8
    8000415c:	ffffe097          	auipc	ra,0xffffe
    80004160:	6c0080e7          	jalr	1728(ra) # 8000281c <either_copyout>
    80004164:	05950d63          	beq	a0,s9,800041be <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004168:	854a                	mv	a0,s2
    8000416a:	fffff097          	auipc	ra,0xfffff
    8000416e:	60c080e7          	jalr	1548(ra) # 80003776 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004172:	013a09bb          	addw	s3,s4,s3
    80004176:	009a04bb          	addw	s1,s4,s1
    8000417a:	9aee                	add	s5,s5,s11
    8000417c:	0569f763          	bgeu	s3,s6,800041ca <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004180:	000ba903          	lw	s2,0(s7)
    80004184:	00a4d59b          	srliw	a1,s1,0xa
    80004188:	855e                	mv	a0,s7
    8000418a:	00000097          	auipc	ra,0x0
    8000418e:	8ac080e7          	jalr	-1876(ra) # 80003a36 <bmap>
    80004192:	0005059b          	sext.w	a1,a0
    80004196:	854a                	mv	a0,s2
    80004198:	fffff097          	auipc	ra,0xfffff
    8000419c:	4ae080e7          	jalr	1198(ra) # 80003646 <bread>
    800041a0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800041a2:	3ff4f713          	andi	a4,s1,1023
    800041a6:	40ed07bb          	subw	a5,s10,a4
    800041aa:	413b06bb          	subw	a3,s6,s3
    800041ae:	8a3e                	mv	s4,a5
    800041b0:	2781                	sext.w	a5,a5
    800041b2:	0006861b          	sext.w	a2,a3
    800041b6:	f8f679e3          	bgeu	a2,a5,80004148 <readi+0x4c>
    800041ba:	8a36                	mv	s4,a3
    800041bc:	b771                	j	80004148 <readi+0x4c>
      brelse(bp);
    800041be:	854a                	mv	a0,s2
    800041c0:	fffff097          	auipc	ra,0xfffff
    800041c4:	5b6080e7          	jalr	1462(ra) # 80003776 <brelse>
      tot = -1;
    800041c8:	59fd                	li	s3,-1
  }
  return tot;
    800041ca:	0009851b          	sext.w	a0,s3
}
    800041ce:	70a6                	ld	ra,104(sp)
    800041d0:	7406                	ld	s0,96(sp)
    800041d2:	64e6                	ld	s1,88(sp)
    800041d4:	6946                	ld	s2,80(sp)
    800041d6:	69a6                	ld	s3,72(sp)
    800041d8:	6a06                	ld	s4,64(sp)
    800041da:	7ae2                	ld	s5,56(sp)
    800041dc:	7b42                	ld	s6,48(sp)
    800041de:	7ba2                	ld	s7,40(sp)
    800041e0:	7c02                	ld	s8,32(sp)
    800041e2:	6ce2                	ld	s9,24(sp)
    800041e4:	6d42                	ld	s10,16(sp)
    800041e6:	6da2                	ld	s11,8(sp)
    800041e8:	6165                	addi	sp,sp,112
    800041ea:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041ec:	89da                	mv	s3,s6
    800041ee:	bff1                	j	800041ca <readi+0xce>
    return 0;
    800041f0:	4501                	li	a0,0
}
    800041f2:	8082                	ret

00000000800041f4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041f4:	457c                	lw	a5,76(a0)
    800041f6:	10d7e863          	bltu	a5,a3,80004306 <writei+0x112>
{
    800041fa:	7159                	addi	sp,sp,-112
    800041fc:	f486                	sd	ra,104(sp)
    800041fe:	f0a2                	sd	s0,96(sp)
    80004200:	eca6                	sd	s1,88(sp)
    80004202:	e8ca                	sd	s2,80(sp)
    80004204:	e4ce                	sd	s3,72(sp)
    80004206:	e0d2                	sd	s4,64(sp)
    80004208:	fc56                	sd	s5,56(sp)
    8000420a:	f85a                	sd	s6,48(sp)
    8000420c:	f45e                	sd	s7,40(sp)
    8000420e:	f062                	sd	s8,32(sp)
    80004210:	ec66                	sd	s9,24(sp)
    80004212:	e86a                	sd	s10,16(sp)
    80004214:	e46e                	sd	s11,8(sp)
    80004216:	1880                	addi	s0,sp,112
    80004218:	8b2a                	mv	s6,a0
    8000421a:	8c2e                	mv	s8,a1
    8000421c:	8ab2                	mv	s5,a2
    8000421e:	8936                	mv	s2,a3
    80004220:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004222:	00e687bb          	addw	a5,a3,a4
    80004226:	0ed7e263          	bltu	a5,a3,8000430a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000422a:	00043737          	lui	a4,0x43
    8000422e:	0ef76063          	bltu	a4,a5,8000430e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004232:	0c0b8863          	beqz	s7,80004302 <writei+0x10e>
    80004236:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004238:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000423c:	5cfd                	li	s9,-1
    8000423e:	a091                	j	80004282 <writei+0x8e>
    80004240:	02099d93          	slli	s11,s3,0x20
    80004244:	020ddd93          	srli	s11,s11,0x20
    80004248:	05848513          	addi	a0,s1,88
    8000424c:	86ee                	mv	a3,s11
    8000424e:	8656                	mv	a2,s5
    80004250:	85e2                	mv	a1,s8
    80004252:	953a                	add	a0,a0,a4
    80004254:	ffffe097          	auipc	ra,0xffffe
    80004258:	61e080e7          	jalr	1566(ra) # 80002872 <either_copyin>
    8000425c:	07950263          	beq	a0,s9,800042c0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004260:	8526                	mv	a0,s1
    80004262:	00000097          	auipc	ra,0x0
    80004266:	798080e7          	jalr	1944(ra) # 800049fa <log_write>
    brelse(bp);
    8000426a:	8526                	mv	a0,s1
    8000426c:	fffff097          	auipc	ra,0xfffff
    80004270:	50a080e7          	jalr	1290(ra) # 80003776 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004274:	01498a3b          	addw	s4,s3,s4
    80004278:	0129893b          	addw	s2,s3,s2
    8000427c:	9aee                	add	s5,s5,s11
    8000427e:	057a7663          	bgeu	s4,s7,800042ca <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004282:	000b2483          	lw	s1,0(s6)
    80004286:	00a9559b          	srliw	a1,s2,0xa
    8000428a:	855a                	mv	a0,s6
    8000428c:	fffff097          	auipc	ra,0xfffff
    80004290:	7aa080e7          	jalr	1962(ra) # 80003a36 <bmap>
    80004294:	0005059b          	sext.w	a1,a0
    80004298:	8526                	mv	a0,s1
    8000429a:	fffff097          	auipc	ra,0xfffff
    8000429e:	3ac080e7          	jalr	940(ra) # 80003646 <bread>
    800042a2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800042a4:	3ff97713          	andi	a4,s2,1023
    800042a8:	40ed07bb          	subw	a5,s10,a4
    800042ac:	414b86bb          	subw	a3,s7,s4
    800042b0:	89be                	mv	s3,a5
    800042b2:	2781                	sext.w	a5,a5
    800042b4:	0006861b          	sext.w	a2,a3
    800042b8:	f8f674e3          	bgeu	a2,a5,80004240 <writei+0x4c>
    800042bc:	89b6                	mv	s3,a3
    800042be:	b749                	j	80004240 <writei+0x4c>
      brelse(bp);
    800042c0:	8526                	mv	a0,s1
    800042c2:	fffff097          	auipc	ra,0xfffff
    800042c6:	4b4080e7          	jalr	1204(ra) # 80003776 <brelse>
  }

  if(off > ip->size)
    800042ca:	04cb2783          	lw	a5,76(s6)
    800042ce:	0127f463          	bgeu	a5,s2,800042d6 <writei+0xe2>
    ip->size = off;
    800042d2:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800042d6:	855a                	mv	a0,s6
    800042d8:	00000097          	auipc	ra,0x0
    800042dc:	aa4080e7          	jalr	-1372(ra) # 80003d7c <iupdate>

  return tot;
    800042e0:	000a051b          	sext.w	a0,s4
}
    800042e4:	70a6                	ld	ra,104(sp)
    800042e6:	7406                	ld	s0,96(sp)
    800042e8:	64e6                	ld	s1,88(sp)
    800042ea:	6946                	ld	s2,80(sp)
    800042ec:	69a6                	ld	s3,72(sp)
    800042ee:	6a06                	ld	s4,64(sp)
    800042f0:	7ae2                	ld	s5,56(sp)
    800042f2:	7b42                	ld	s6,48(sp)
    800042f4:	7ba2                	ld	s7,40(sp)
    800042f6:	7c02                	ld	s8,32(sp)
    800042f8:	6ce2                	ld	s9,24(sp)
    800042fa:	6d42                	ld	s10,16(sp)
    800042fc:	6da2                	ld	s11,8(sp)
    800042fe:	6165                	addi	sp,sp,112
    80004300:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004302:	8a5e                	mv	s4,s7
    80004304:	bfc9                	j	800042d6 <writei+0xe2>
    return -1;
    80004306:	557d                	li	a0,-1
}
    80004308:	8082                	ret
    return -1;
    8000430a:	557d                	li	a0,-1
    8000430c:	bfe1                	j	800042e4 <writei+0xf0>
    return -1;
    8000430e:	557d                	li	a0,-1
    80004310:	bfd1                	j	800042e4 <writei+0xf0>

0000000080004312 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004312:	1141                	addi	sp,sp,-16
    80004314:	e406                	sd	ra,8(sp)
    80004316:	e022                	sd	s0,0(sp)
    80004318:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000431a:	4639                	li	a2,14
    8000431c:	ffffd097          	auipc	ra,0xffffd
    80004320:	a80080e7          	jalr	-1408(ra) # 80000d9c <strncmp>
}
    80004324:	60a2                	ld	ra,8(sp)
    80004326:	6402                	ld	s0,0(sp)
    80004328:	0141                	addi	sp,sp,16
    8000432a:	8082                	ret

000000008000432c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000432c:	7139                	addi	sp,sp,-64
    8000432e:	fc06                	sd	ra,56(sp)
    80004330:	f822                	sd	s0,48(sp)
    80004332:	f426                	sd	s1,40(sp)
    80004334:	f04a                	sd	s2,32(sp)
    80004336:	ec4e                	sd	s3,24(sp)
    80004338:	e852                	sd	s4,16(sp)
    8000433a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000433c:	04451703          	lh	a4,68(a0)
    80004340:	4785                	li	a5,1
    80004342:	00f71a63          	bne	a4,a5,80004356 <dirlookup+0x2a>
    80004346:	892a                	mv	s2,a0
    80004348:	89ae                	mv	s3,a1
    8000434a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000434c:	457c                	lw	a5,76(a0)
    8000434e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004350:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004352:	e79d                	bnez	a5,80004380 <dirlookup+0x54>
    80004354:	a8a5                	j	800043cc <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004356:	00004517          	auipc	a0,0x4
    8000435a:	31250513          	addi	a0,a0,786 # 80008668 <syscalls+0x1b0>
    8000435e:	ffffc097          	auipc	ra,0xffffc
    80004362:	1dc080e7          	jalr	476(ra) # 8000053a <panic>
      panic("dirlookup read");
    80004366:	00004517          	auipc	a0,0x4
    8000436a:	31a50513          	addi	a0,a0,794 # 80008680 <syscalls+0x1c8>
    8000436e:	ffffc097          	auipc	ra,0xffffc
    80004372:	1cc080e7          	jalr	460(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004376:	24c1                	addiw	s1,s1,16
    80004378:	04c92783          	lw	a5,76(s2)
    8000437c:	04f4f763          	bgeu	s1,a5,800043ca <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004380:	4741                	li	a4,16
    80004382:	86a6                	mv	a3,s1
    80004384:	fc040613          	addi	a2,s0,-64
    80004388:	4581                	li	a1,0
    8000438a:	854a                	mv	a0,s2
    8000438c:	00000097          	auipc	ra,0x0
    80004390:	d70080e7          	jalr	-656(ra) # 800040fc <readi>
    80004394:	47c1                	li	a5,16
    80004396:	fcf518e3          	bne	a0,a5,80004366 <dirlookup+0x3a>
    if(de.inum == 0)
    8000439a:	fc045783          	lhu	a5,-64(s0)
    8000439e:	dfe1                	beqz	a5,80004376 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800043a0:	fc240593          	addi	a1,s0,-62
    800043a4:	854e                	mv	a0,s3
    800043a6:	00000097          	auipc	ra,0x0
    800043aa:	f6c080e7          	jalr	-148(ra) # 80004312 <namecmp>
    800043ae:	f561                	bnez	a0,80004376 <dirlookup+0x4a>
      if(poff)
    800043b0:	000a0463          	beqz	s4,800043b8 <dirlookup+0x8c>
        *poff = off;
    800043b4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800043b8:	fc045583          	lhu	a1,-64(s0)
    800043bc:	00092503          	lw	a0,0(s2)
    800043c0:	fffff097          	auipc	ra,0xfffff
    800043c4:	752080e7          	jalr	1874(ra) # 80003b12 <iget>
    800043c8:	a011                	j	800043cc <dirlookup+0xa0>
  return 0;
    800043ca:	4501                	li	a0,0
}
    800043cc:	70e2                	ld	ra,56(sp)
    800043ce:	7442                	ld	s0,48(sp)
    800043d0:	74a2                	ld	s1,40(sp)
    800043d2:	7902                	ld	s2,32(sp)
    800043d4:	69e2                	ld	s3,24(sp)
    800043d6:	6a42                	ld	s4,16(sp)
    800043d8:	6121                	addi	sp,sp,64
    800043da:	8082                	ret

00000000800043dc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800043dc:	711d                	addi	sp,sp,-96
    800043de:	ec86                	sd	ra,88(sp)
    800043e0:	e8a2                	sd	s0,80(sp)
    800043e2:	e4a6                	sd	s1,72(sp)
    800043e4:	e0ca                	sd	s2,64(sp)
    800043e6:	fc4e                	sd	s3,56(sp)
    800043e8:	f852                	sd	s4,48(sp)
    800043ea:	f456                	sd	s5,40(sp)
    800043ec:	f05a                	sd	s6,32(sp)
    800043ee:	ec5e                	sd	s7,24(sp)
    800043f0:	e862                	sd	s8,16(sp)
    800043f2:	e466                	sd	s9,8(sp)
    800043f4:	e06a                	sd	s10,0(sp)
    800043f6:	1080                	addi	s0,sp,96
    800043f8:	84aa                	mv	s1,a0
    800043fa:	8b2e                	mv	s6,a1
    800043fc:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800043fe:	00054703          	lbu	a4,0(a0)
    80004402:	02f00793          	li	a5,47
    80004406:	02f70363          	beq	a4,a5,8000442c <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000440a:	ffffe097          	auipc	ra,0xffffe
    8000440e:	846080e7          	jalr	-1978(ra) # 80001c50 <myproc>
    80004412:	17053503          	ld	a0,368(a0)
    80004416:	00000097          	auipc	ra,0x0
    8000441a:	9f4080e7          	jalr	-1548(ra) # 80003e0a <idup>
    8000441e:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004420:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004424:	4cb5                	li	s9,13
  len = path - s;
    80004426:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004428:	4c05                	li	s8,1
    8000442a:	a87d                	j	800044e8 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    8000442c:	4585                	li	a1,1
    8000442e:	4505                	li	a0,1
    80004430:	fffff097          	auipc	ra,0xfffff
    80004434:	6e2080e7          	jalr	1762(ra) # 80003b12 <iget>
    80004438:	8a2a                	mv	s4,a0
    8000443a:	b7dd                	j	80004420 <namex+0x44>
      iunlockput(ip);
    8000443c:	8552                	mv	a0,s4
    8000443e:	00000097          	auipc	ra,0x0
    80004442:	c6c080e7          	jalr	-916(ra) # 800040aa <iunlockput>
      return 0;
    80004446:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004448:	8552                	mv	a0,s4
    8000444a:	60e6                	ld	ra,88(sp)
    8000444c:	6446                	ld	s0,80(sp)
    8000444e:	64a6                	ld	s1,72(sp)
    80004450:	6906                	ld	s2,64(sp)
    80004452:	79e2                	ld	s3,56(sp)
    80004454:	7a42                	ld	s4,48(sp)
    80004456:	7aa2                	ld	s5,40(sp)
    80004458:	7b02                	ld	s6,32(sp)
    8000445a:	6be2                	ld	s7,24(sp)
    8000445c:	6c42                	ld	s8,16(sp)
    8000445e:	6ca2                	ld	s9,8(sp)
    80004460:	6d02                	ld	s10,0(sp)
    80004462:	6125                	addi	sp,sp,96
    80004464:	8082                	ret
      iunlock(ip);
    80004466:	8552                	mv	a0,s4
    80004468:	00000097          	auipc	ra,0x0
    8000446c:	aa2080e7          	jalr	-1374(ra) # 80003f0a <iunlock>
      return ip;
    80004470:	bfe1                	j	80004448 <namex+0x6c>
      iunlockput(ip);
    80004472:	8552                	mv	a0,s4
    80004474:	00000097          	auipc	ra,0x0
    80004478:	c36080e7          	jalr	-970(ra) # 800040aa <iunlockput>
      return 0;
    8000447c:	8a4e                	mv	s4,s3
    8000447e:	b7e9                	j	80004448 <namex+0x6c>
  len = path - s;
    80004480:	40998633          	sub	a2,s3,s1
    80004484:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004488:	09acd863          	bge	s9,s10,80004518 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    8000448c:	4639                	li	a2,14
    8000448e:	85a6                	mv	a1,s1
    80004490:	8556                	mv	a0,s5
    80004492:	ffffd097          	auipc	ra,0xffffd
    80004496:	896080e7          	jalr	-1898(ra) # 80000d28 <memmove>
    8000449a:	84ce                	mv	s1,s3
  while(*path == '/')
    8000449c:	0004c783          	lbu	a5,0(s1)
    800044a0:	01279763          	bne	a5,s2,800044ae <namex+0xd2>
    path++;
    800044a4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044a6:	0004c783          	lbu	a5,0(s1)
    800044aa:	ff278de3          	beq	a5,s2,800044a4 <namex+0xc8>
    ilock(ip);
    800044ae:	8552                	mv	a0,s4
    800044b0:	00000097          	auipc	ra,0x0
    800044b4:	998080e7          	jalr	-1640(ra) # 80003e48 <ilock>
    if(ip->type != T_DIR){
    800044b8:	044a1783          	lh	a5,68(s4)
    800044bc:	f98790e3          	bne	a5,s8,8000443c <namex+0x60>
    if(nameiparent && *path == '\0'){
    800044c0:	000b0563          	beqz	s6,800044ca <namex+0xee>
    800044c4:	0004c783          	lbu	a5,0(s1)
    800044c8:	dfd9                	beqz	a5,80004466 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    800044ca:	865e                	mv	a2,s7
    800044cc:	85d6                	mv	a1,s5
    800044ce:	8552                	mv	a0,s4
    800044d0:	00000097          	auipc	ra,0x0
    800044d4:	e5c080e7          	jalr	-420(ra) # 8000432c <dirlookup>
    800044d8:	89aa                	mv	s3,a0
    800044da:	dd41                	beqz	a0,80004472 <namex+0x96>
    iunlockput(ip);
    800044dc:	8552                	mv	a0,s4
    800044de:	00000097          	auipc	ra,0x0
    800044e2:	bcc080e7          	jalr	-1076(ra) # 800040aa <iunlockput>
    ip = next;
    800044e6:	8a4e                	mv	s4,s3
  while(*path == '/')
    800044e8:	0004c783          	lbu	a5,0(s1)
    800044ec:	01279763          	bne	a5,s2,800044fa <namex+0x11e>
    path++;
    800044f0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044f2:	0004c783          	lbu	a5,0(s1)
    800044f6:	ff278de3          	beq	a5,s2,800044f0 <namex+0x114>
  if(*path == 0)
    800044fa:	cb9d                	beqz	a5,80004530 <namex+0x154>
  while(*path != '/' && *path != 0)
    800044fc:	0004c783          	lbu	a5,0(s1)
    80004500:	89a6                	mv	s3,s1
  len = path - s;
    80004502:	8d5e                	mv	s10,s7
    80004504:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004506:	01278963          	beq	a5,s2,80004518 <namex+0x13c>
    8000450a:	dbbd                	beqz	a5,80004480 <namex+0xa4>
    path++;
    8000450c:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000450e:	0009c783          	lbu	a5,0(s3)
    80004512:	ff279ce3          	bne	a5,s2,8000450a <namex+0x12e>
    80004516:	b7ad                	j	80004480 <namex+0xa4>
    memmove(name, s, len);
    80004518:	2601                	sext.w	a2,a2
    8000451a:	85a6                	mv	a1,s1
    8000451c:	8556                	mv	a0,s5
    8000451e:	ffffd097          	auipc	ra,0xffffd
    80004522:	80a080e7          	jalr	-2038(ra) # 80000d28 <memmove>
    name[len] = 0;
    80004526:	9d56                	add	s10,s10,s5
    80004528:	000d0023          	sb	zero,0(s10)
    8000452c:	84ce                	mv	s1,s3
    8000452e:	b7bd                	j	8000449c <namex+0xc0>
  if(nameiparent){
    80004530:	f00b0ce3          	beqz	s6,80004448 <namex+0x6c>
    iput(ip);
    80004534:	8552                	mv	a0,s4
    80004536:	00000097          	auipc	ra,0x0
    8000453a:	acc080e7          	jalr	-1332(ra) # 80004002 <iput>
    return 0;
    8000453e:	4a01                	li	s4,0
    80004540:	b721                	j	80004448 <namex+0x6c>

0000000080004542 <dirlink>:
{
    80004542:	7139                	addi	sp,sp,-64
    80004544:	fc06                	sd	ra,56(sp)
    80004546:	f822                	sd	s0,48(sp)
    80004548:	f426                	sd	s1,40(sp)
    8000454a:	f04a                	sd	s2,32(sp)
    8000454c:	ec4e                	sd	s3,24(sp)
    8000454e:	e852                	sd	s4,16(sp)
    80004550:	0080                	addi	s0,sp,64
    80004552:	892a                	mv	s2,a0
    80004554:	8a2e                	mv	s4,a1
    80004556:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004558:	4601                	li	a2,0
    8000455a:	00000097          	auipc	ra,0x0
    8000455e:	dd2080e7          	jalr	-558(ra) # 8000432c <dirlookup>
    80004562:	e93d                	bnez	a0,800045d8 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004564:	04c92483          	lw	s1,76(s2)
    80004568:	c49d                	beqz	s1,80004596 <dirlink+0x54>
    8000456a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000456c:	4741                	li	a4,16
    8000456e:	86a6                	mv	a3,s1
    80004570:	fc040613          	addi	a2,s0,-64
    80004574:	4581                	li	a1,0
    80004576:	854a                	mv	a0,s2
    80004578:	00000097          	auipc	ra,0x0
    8000457c:	b84080e7          	jalr	-1148(ra) # 800040fc <readi>
    80004580:	47c1                	li	a5,16
    80004582:	06f51163          	bne	a0,a5,800045e4 <dirlink+0xa2>
    if(de.inum == 0)
    80004586:	fc045783          	lhu	a5,-64(s0)
    8000458a:	c791                	beqz	a5,80004596 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000458c:	24c1                	addiw	s1,s1,16
    8000458e:	04c92783          	lw	a5,76(s2)
    80004592:	fcf4ede3          	bltu	s1,a5,8000456c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004596:	4639                	li	a2,14
    80004598:	85d2                	mv	a1,s4
    8000459a:	fc240513          	addi	a0,s0,-62
    8000459e:	ffffd097          	auipc	ra,0xffffd
    800045a2:	83a080e7          	jalr	-1990(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    800045a6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045aa:	4741                	li	a4,16
    800045ac:	86a6                	mv	a3,s1
    800045ae:	fc040613          	addi	a2,s0,-64
    800045b2:	4581                	li	a1,0
    800045b4:	854a                	mv	a0,s2
    800045b6:	00000097          	auipc	ra,0x0
    800045ba:	c3e080e7          	jalr	-962(ra) # 800041f4 <writei>
    800045be:	872a                	mv	a4,a0
    800045c0:	47c1                	li	a5,16
  return 0;
    800045c2:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045c4:	02f71863          	bne	a4,a5,800045f4 <dirlink+0xb2>
}
    800045c8:	70e2                	ld	ra,56(sp)
    800045ca:	7442                	ld	s0,48(sp)
    800045cc:	74a2                	ld	s1,40(sp)
    800045ce:	7902                	ld	s2,32(sp)
    800045d0:	69e2                	ld	s3,24(sp)
    800045d2:	6a42                	ld	s4,16(sp)
    800045d4:	6121                	addi	sp,sp,64
    800045d6:	8082                	ret
    iput(ip);
    800045d8:	00000097          	auipc	ra,0x0
    800045dc:	a2a080e7          	jalr	-1494(ra) # 80004002 <iput>
    return -1;
    800045e0:	557d                	li	a0,-1
    800045e2:	b7dd                	j	800045c8 <dirlink+0x86>
      panic("dirlink read");
    800045e4:	00004517          	auipc	a0,0x4
    800045e8:	0ac50513          	addi	a0,a0,172 # 80008690 <syscalls+0x1d8>
    800045ec:	ffffc097          	auipc	ra,0xffffc
    800045f0:	f4e080e7          	jalr	-178(ra) # 8000053a <panic>
    panic("dirlink");
    800045f4:	00004517          	auipc	a0,0x4
    800045f8:	1ac50513          	addi	a0,a0,428 # 800087a0 <syscalls+0x2e8>
    800045fc:	ffffc097          	auipc	ra,0xffffc
    80004600:	f3e080e7          	jalr	-194(ra) # 8000053a <panic>

0000000080004604 <namei>:

struct inode*
namei(char *path)
{
    80004604:	1101                	addi	sp,sp,-32
    80004606:	ec06                	sd	ra,24(sp)
    80004608:	e822                	sd	s0,16(sp)
    8000460a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000460c:	fe040613          	addi	a2,s0,-32
    80004610:	4581                	li	a1,0
    80004612:	00000097          	auipc	ra,0x0
    80004616:	dca080e7          	jalr	-566(ra) # 800043dc <namex>
}
    8000461a:	60e2                	ld	ra,24(sp)
    8000461c:	6442                	ld	s0,16(sp)
    8000461e:	6105                	addi	sp,sp,32
    80004620:	8082                	ret

0000000080004622 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004622:	1141                	addi	sp,sp,-16
    80004624:	e406                	sd	ra,8(sp)
    80004626:	e022                	sd	s0,0(sp)
    80004628:	0800                	addi	s0,sp,16
    8000462a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000462c:	4585                	li	a1,1
    8000462e:	00000097          	auipc	ra,0x0
    80004632:	dae080e7          	jalr	-594(ra) # 800043dc <namex>
}
    80004636:	60a2                	ld	ra,8(sp)
    80004638:	6402                	ld	s0,0(sp)
    8000463a:	0141                	addi	sp,sp,16
    8000463c:	8082                	ret

000000008000463e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000463e:	1101                	addi	sp,sp,-32
    80004640:	ec06                	sd	ra,24(sp)
    80004642:	e822                	sd	s0,16(sp)
    80004644:	e426                	sd	s1,8(sp)
    80004646:	e04a                	sd	s2,0(sp)
    80004648:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000464a:	0001d917          	auipc	s2,0x1d
    8000464e:	4b690913          	addi	s2,s2,1206 # 80021b00 <log>
    80004652:	01892583          	lw	a1,24(s2)
    80004656:	02892503          	lw	a0,40(s2)
    8000465a:	fffff097          	auipc	ra,0xfffff
    8000465e:	fec080e7          	jalr	-20(ra) # 80003646 <bread>
    80004662:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004664:	02c92683          	lw	a3,44(s2)
    80004668:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000466a:	02d05863          	blez	a3,8000469a <write_head+0x5c>
    8000466e:	0001d797          	auipc	a5,0x1d
    80004672:	4c278793          	addi	a5,a5,1218 # 80021b30 <log+0x30>
    80004676:	05c50713          	addi	a4,a0,92
    8000467a:	36fd                	addiw	a3,a3,-1
    8000467c:	02069613          	slli	a2,a3,0x20
    80004680:	01e65693          	srli	a3,a2,0x1e
    80004684:	0001d617          	auipc	a2,0x1d
    80004688:	4b060613          	addi	a2,a2,1200 # 80021b34 <log+0x34>
    8000468c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000468e:	4390                	lw	a2,0(a5)
    80004690:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004692:	0791                	addi	a5,a5,4
    80004694:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004696:	fed79ce3          	bne	a5,a3,8000468e <write_head+0x50>
  }
  bwrite(buf);
    8000469a:	8526                	mv	a0,s1
    8000469c:	fffff097          	auipc	ra,0xfffff
    800046a0:	09c080e7          	jalr	156(ra) # 80003738 <bwrite>
  brelse(buf);
    800046a4:	8526                	mv	a0,s1
    800046a6:	fffff097          	auipc	ra,0xfffff
    800046aa:	0d0080e7          	jalr	208(ra) # 80003776 <brelse>
}
    800046ae:	60e2                	ld	ra,24(sp)
    800046b0:	6442                	ld	s0,16(sp)
    800046b2:	64a2                	ld	s1,8(sp)
    800046b4:	6902                	ld	s2,0(sp)
    800046b6:	6105                	addi	sp,sp,32
    800046b8:	8082                	ret

00000000800046ba <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800046ba:	0001d797          	auipc	a5,0x1d
    800046be:	4727a783          	lw	a5,1138(a5) # 80021b2c <log+0x2c>
    800046c2:	0af05d63          	blez	a5,8000477c <install_trans+0xc2>
{
    800046c6:	7139                	addi	sp,sp,-64
    800046c8:	fc06                	sd	ra,56(sp)
    800046ca:	f822                	sd	s0,48(sp)
    800046cc:	f426                	sd	s1,40(sp)
    800046ce:	f04a                	sd	s2,32(sp)
    800046d0:	ec4e                	sd	s3,24(sp)
    800046d2:	e852                	sd	s4,16(sp)
    800046d4:	e456                	sd	s5,8(sp)
    800046d6:	e05a                	sd	s6,0(sp)
    800046d8:	0080                	addi	s0,sp,64
    800046da:	8b2a                	mv	s6,a0
    800046dc:	0001da97          	auipc	s5,0x1d
    800046e0:	454a8a93          	addi	s5,s5,1108 # 80021b30 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046e4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046e6:	0001d997          	auipc	s3,0x1d
    800046ea:	41a98993          	addi	s3,s3,1050 # 80021b00 <log>
    800046ee:	a00d                	j	80004710 <install_trans+0x56>
    brelse(lbuf);
    800046f0:	854a                	mv	a0,s2
    800046f2:	fffff097          	auipc	ra,0xfffff
    800046f6:	084080e7          	jalr	132(ra) # 80003776 <brelse>
    brelse(dbuf);
    800046fa:	8526                	mv	a0,s1
    800046fc:	fffff097          	auipc	ra,0xfffff
    80004700:	07a080e7          	jalr	122(ra) # 80003776 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004704:	2a05                	addiw	s4,s4,1
    80004706:	0a91                	addi	s5,s5,4
    80004708:	02c9a783          	lw	a5,44(s3)
    8000470c:	04fa5e63          	bge	s4,a5,80004768 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004710:	0189a583          	lw	a1,24(s3)
    80004714:	014585bb          	addw	a1,a1,s4
    80004718:	2585                	addiw	a1,a1,1
    8000471a:	0289a503          	lw	a0,40(s3)
    8000471e:	fffff097          	auipc	ra,0xfffff
    80004722:	f28080e7          	jalr	-216(ra) # 80003646 <bread>
    80004726:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004728:	000aa583          	lw	a1,0(s5)
    8000472c:	0289a503          	lw	a0,40(s3)
    80004730:	fffff097          	auipc	ra,0xfffff
    80004734:	f16080e7          	jalr	-234(ra) # 80003646 <bread>
    80004738:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000473a:	40000613          	li	a2,1024
    8000473e:	05890593          	addi	a1,s2,88
    80004742:	05850513          	addi	a0,a0,88
    80004746:	ffffc097          	auipc	ra,0xffffc
    8000474a:	5e2080e7          	jalr	1506(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000474e:	8526                	mv	a0,s1
    80004750:	fffff097          	auipc	ra,0xfffff
    80004754:	fe8080e7          	jalr	-24(ra) # 80003738 <bwrite>
    if(recovering == 0)
    80004758:	f80b1ce3          	bnez	s6,800046f0 <install_trans+0x36>
      bunpin(dbuf);
    8000475c:	8526                	mv	a0,s1
    8000475e:	fffff097          	auipc	ra,0xfffff
    80004762:	0f2080e7          	jalr	242(ra) # 80003850 <bunpin>
    80004766:	b769                	j	800046f0 <install_trans+0x36>
}
    80004768:	70e2                	ld	ra,56(sp)
    8000476a:	7442                	ld	s0,48(sp)
    8000476c:	74a2                	ld	s1,40(sp)
    8000476e:	7902                	ld	s2,32(sp)
    80004770:	69e2                	ld	s3,24(sp)
    80004772:	6a42                	ld	s4,16(sp)
    80004774:	6aa2                	ld	s5,8(sp)
    80004776:	6b02                	ld	s6,0(sp)
    80004778:	6121                	addi	sp,sp,64
    8000477a:	8082                	ret
    8000477c:	8082                	ret

000000008000477e <initlog>:
{
    8000477e:	7179                	addi	sp,sp,-48
    80004780:	f406                	sd	ra,40(sp)
    80004782:	f022                	sd	s0,32(sp)
    80004784:	ec26                	sd	s1,24(sp)
    80004786:	e84a                	sd	s2,16(sp)
    80004788:	e44e                	sd	s3,8(sp)
    8000478a:	1800                	addi	s0,sp,48
    8000478c:	892a                	mv	s2,a0
    8000478e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004790:	0001d497          	auipc	s1,0x1d
    80004794:	37048493          	addi	s1,s1,880 # 80021b00 <log>
    80004798:	00004597          	auipc	a1,0x4
    8000479c:	f0858593          	addi	a1,a1,-248 # 800086a0 <syscalls+0x1e8>
    800047a0:	8526                	mv	a0,s1
    800047a2:	ffffc097          	auipc	ra,0xffffc
    800047a6:	39e080e7          	jalr	926(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    800047aa:	0149a583          	lw	a1,20(s3)
    800047ae:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800047b0:	0109a783          	lw	a5,16(s3)
    800047b4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800047b6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800047ba:	854a                	mv	a0,s2
    800047bc:	fffff097          	auipc	ra,0xfffff
    800047c0:	e8a080e7          	jalr	-374(ra) # 80003646 <bread>
  log.lh.n = lh->n;
    800047c4:	4d34                	lw	a3,88(a0)
    800047c6:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800047c8:	02d05663          	blez	a3,800047f4 <initlog+0x76>
    800047cc:	05c50793          	addi	a5,a0,92
    800047d0:	0001d717          	auipc	a4,0x1d
    800047d4:	36070713          	addi	a4,a4,864 # 80021b30 <log+0x30>
    800047d8:	36fd                	addiw	a3,a3,-1
    800047da:	02069613          	slli	a2,a3,0x20
    800047de:	01e65693          	srli	a3,a2,0x1e
    800047e2:	06050613          	addi	a2,a0,96
    800047e6:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800047e8:	4390                	lw	a2,0(a5)
    800047ea:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800047ec:	0791                	addi	a5,a5,4
    800047ee:	0711                	addi	a4,a4,4
    800047f0:	fed79ce3          	bne	a5,a3,800047e8 <initlog+0x6a>
  brelse(buf);
    800047f4:	fffff097          	auipc	ra,0xfffff
    800047f8:	f82080e7          	jalr	-126(ra) # 80003776 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800047fc:	4505                	li	a0,1
    800047fe:	00000097          	auipc	ra,0x0
    80004802:	ebc080e7          	jalr	-324(ra) # 800046ba <install_trans>
  log.lh.n = 0;
    80004806:	0001d797          	auipc	a5,0x1d
    8000480a:	3207a323          	sw	zero,806(a5) # 80021b2c <log+0x2c>
  write_head(); // clear the log
    8000480e:	00000097          	auipc	ra,0x0
    80004812:	e30080e7          	jalr	-464(ra) # 8000463e <write_head>
}
    80004816:	70a2                	ld	ra,40(sp)
    80004818:	7402                	ld	s0,32(sp)
    8000481a:	64e2                	ld	s1,24(sp)
    8000481c:	6942                	ld	s2,16(sp)
    8000481e:	69a2                	ld	s3,8(sp)
    80004820:	6145                	addi	sp,sp,48
    80004822:	8082                	ret

0000000080004824 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004824:	1101                	addi	sp,sp,-32
    80004826:	ec06                	sd	ra,24(sp)
    80004828:	e822                	sd	s0,16(sp)
    8000482a:	e426                	sd	s1,8(sp)
    8000482c:	e04a                	sd	s2,0(sp)
    8000482e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004830:	0001d517          	auipc	a0,0x1d
    80004834:	2d050513          	addi	a0,a0,720 # 80021b00 <log>
    80004838:	ffffc097          	auipc	ra,0xffffc
    8000483c:	398080e7          	jalr	920(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    80004840:	0001d497          	auipc	s1,0x1d
    80004844:	2c048493          	addi	s1,s1,704 # 80021b00 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004848:	4979                	li	s2,30
    8000484a:	a039                	j	80004858 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000484c:	85a6                	mv	a1,s1
    8000484e:	8526                	mv	a0,s1
    80004850:	ffffe097          	auipc	ra,0xffffe
    80004854:	b7e080e7          	jalr	-1154(ra) # 800023ce <sleep>
    if(log.committing){
    80004858:	50dc                	lw	a5,36(s1)
    8000485a:	fbed                	bnez	a5,8000484c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000485c:	5098                	lw	a4,32(s1)
    8000485e:	2705                	addiw	a4,a4,1
    80004860:	0007069b          	sext.w	a3,a4
    80004864:	0027179b          	slliw	a5,a4,0x2
    80004868:	9fb9                	addw	a5,a5,a4
    8000486a:	0017979b          	slliw	a5,a5,0x1
    8000486e:	54d8                	lw	a4,44(s1)
    80004870:	9fb9                	addw	a5,a5,a4
    80004872:	00f95963          	bge	s2,a5,80004884 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004876:	85a6                	mv	a1,s1
    80004878:	8526                	mv	a0,s1
    8000487a:	ffffe097          	auipc	ra,0xffffe
    8000487e:	b54080e7          	jalr	-1196(ra) # 800023ce <sleep>
    80004882:	bfd9                	j	80004858 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004884:	0001d517          	auipc	a0,0x1d
    80004888:	27c50513          	addi	a0,a0,636 # 80021b00 <log>
    8000488c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000488e:	ffffc097          	auipc	ra,0xffffc
    80004892:	3f6080e7          	jalr	1014(ra) # 80000c84 <release>
      break;
    }
  }
}
    80004896:	60e2                	ld	ra,24(sp)
    80004898:	6442                	ld	s0,16(sp)
    8000489a:	64a2                	ld	s1,8(sp)
    8000489c:	6902                	ld	s2,0(sp)
    8000489e:	6105                	addi	sp,sp,32
    800048a0:	8082                	ret

00000000800048a2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800048a2:	7139                	addi	sp,sp,-64
    800048a4:	fc06                	sd	ra,56(sp)
    800048a6:	f822                	sd	s0,48(sp)
    800048a8:	f426                	sd	s1,40(sp)
    800048aa:	f04a                	sd	s2,32(sp)
    800048ac:	ec4e                	sd	s3,24(sp)
    800048ae:	e852                	sd	s4,16(sp)
    800048b0:	e456                	sd	s5,8(sp)
    800048b2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800048b4:	0001d497          	auipc	s1,0x1d
    800048b8:	24c48493          	addi	s1,s1,588 # 80021b00 <log>
    800048bc:	8526                	mv	a0,s1
    800048be:	ffffc097          	auipc	ra,0xffffc
    800048c2:	312080e7          	jalr	786(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    800048c6:	509c                	lw	a5,32(s1)
    800048c8:	37fd                	addiw	a5,a5,-1
    800048ca:	0007891b          	sext.w	s2,a5
    800048ce:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800048d0:	50dc                	lw	a5,36(s1)
    800048d2:	e7b9                	bnez	a5,80004920 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800048d4:	04091e63          	bnez	s2,80004930 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800048d8:	0001d497          	auipc	s1,0x1d
    800048dc:	22848493          	addi	s1,s1,552 # 80021b00 <log>
    800048e0:	4785                	li	a5,1
    800048e2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800048e4:	8526                	mv	a0,s1
    800048e6:	ffffc097          	auipc	ra,0xffffc
    800048ea:	39e080e7          	jalr	926(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800048ee:	54dc                	lw	a5,44(s1)
    800048f0:	06f04763          	bgtz	a5,8000495e <end_op+0xbc>
    acquire(&log.lock);
    800048f4:	0001d497          	auipc	s1,0x1d
    800048f8:	20c48493          	addi	s1,s1,524 # 80021b00 <log>
    800048fc:	8526                	mv	a0,s1
    800048fe:	ffffc097          	auipc	ra,0xffffc
    80004902:	2d2080e7          	jalr	722(ra) # 80000bd0 <acquire>
    log.committing = 0;
    80004906:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000490a:	8526                	mv	a0,s1
    8000490c:	ffffe097          	auipc	ra,0xffffe
    80004910:	c4e080e7          	jalr	-946(ra) # 8000255a <wakeup>
    release(&log.lock);
    80004914:	8526                	mv	a0,s1
    80004916:	ffffc097          	auipc	ra,0xffffc
    8000491a:	36e080e7          	jalr	878(ra) # 80000c84 <release>
}
    8000491e:	a03d                	j	8000494c <end_op+0xaa>
    panic("log.committing");
    80004920:	00004517          	auipc	a0,0x4
    80004924:	d8850513          	addi	a0,a0,-632 # 800086a8 <syscalls+0x1f0>
    80004928:	ffffc097          	auipc	ra,0xffffc
    8000492c:	c12080e7          	jalr	-1006(ra) # 8000053a <panic>
    wakeup(&log);
    80004930:	0001d497          	auipc	s1,0x1d
    80004934:	1d048493          	addi	s1,s1,464 # 80021b00 <log>
    80004938:	8526                	mv	a0,s1
    8000493a:	ffffe097          	auipc	ra,0xffffe
    8000493e:	c20080e7          	jalr	-992(ra) # 8000255a <wakeup>
  release(&log.lock);
    80004942:	8526                	mv	a0,s1
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	340080e7          	jalr	832(ra) # 80000c84 <release>
}
    8000494c:	70e2                	ld	ra,56(sp)
    8000494e:	7442                	ld	s0,48(sp)
    80004950:	74a2                	ld	s1,40(sp)
    80004952:	7902                	ld	s2,32(sp)
    80004954:	69e2                	ld	s3,24(sp)
    80004956:	6a42                	ld	s4,16(sp)
    80004958:	6aa2                	ld	s5,8(sp)
    8000495a:	6121                	addi	sp,sp,64
    8000495c:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000495e:	0001da97          	auipc	s5,0x1d
    80004962:	1d2a8a93          	addi	s5,s5,466 # 80021b30 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004966:	0001da17          	auipc	s4,0x1d
    8000496a:	19aa0a13          	addi	s4,s4,410 # 80021b00 <log>
    8000496e:	018a2583          	lw	a1,24(s4)
    80004972:	012585bb          	addw	a1,a1,s2
    80004976:	2585                	addiw	a1,a1,1
    80004978:	028a2503          	lw	a0,40(s4)
    8000497c:	fffff097          	auipc	ra,0xfffff
    80004980:	cca080e7          	jalr	-822(ra) # 80003646 <bread>
    80004984:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004986:	000aa583          	lw	a1,0(s5)
    8000498a:	028a2503          	lw	a0,40(s4)
    8000498e:	fffff097          	auipc	ra,0xfffff
    80004992:	cb8080e7          	jalr	-840(ra) # 80003646 <bread>
    80004996:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004998:	40000613          	li	a2,1024
    8000499c:	05850593          	addi	a1,a0,88
    800049a0:	05848513          	addi	a0,s1,88
    800049a4:	ffffc097          	auipc	ra,0xffffc
    800049a8:	384080e7          	jalr	900(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    800049ac:	8526                	mv	a0,s1
    800049ae:	fffff097          	auipc	ra,0xfffff
    800049b2:	d8a080e7          	jalr	-630(ra) # 80003738 <bwrite>
    brelse(from);
    800049b6:	854e                	mv	a0,s3
    800049b8:	fffff097          	auipc	ra,0xfffff
    800049bc:	dbe080e7          	jalr	-578(ra) # 80003776 <brelse>
    brelse(to);
    800049c0:	8526                	mv	a0,s1
    800049c2:	fffff097          	auipc	ra,0xfffff
    800049c6:	db4080e7          	jalr	-588(ra) # 80003776 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049ca:	2905                	addiw	s2,s2,1
    800049cc:	0a91                	addi	s5,s5,4
    800049ce:	02ca2783          	lw	a5,44(s4)
    800049d2:	f8f94ee3          	blt	s2,a5,8000496e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800049d6:	00000097          	auipc	ra,0x0
    800049da:	c68080e7          	jalr	-920(ra) # 8000463e <write_head>
    install_trans(0); // Now install writes to home locations
    800049de:	4501                	li	a0,0
    800049e0:	00000097          	auipc	ra,0x0
    800049e4:	cda080e7          	jalr	-806(ra) # 800046ba <install_trans>
    log.lh.n = 0;
    800049e8:	0001d797          	auipc	a5,0x1d
    800049ec:	1407a223          	sw	zero,324(a5) # 80021b2c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800049f0:	00000097          	auipc	ra,0x0
    800049f4:	c4e080e7          	jalr	-946(ra) # 8000463e <write_head>
    800049f8:	bdf5                	j	800048f4 <end_op+0x52>

00000000800049fa <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800049fa:	1101                	addi	sp,sp,-32
    800049fc:	ec06                	sd	ra,24(sp)
    800049fe:	e822                	sd	s0,16(sp)
    80004a00:	e426                	sd	s1,8(sp)
    80004a02:	e04a                	sd	s2,0(sp)
    80004a04:	1000                	addi	s0,sp,32
    80004a06:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004a08:	0001d917          	auipc	s2,0x1d
    80004a0c:	0f890913          	addi	s2,s2,248 # 80021b00 <log>
    80004a10:	854a                	mv	a0,s2
    80004a12:	ffffc097          	auipc	ra,0xffffc
    80004a16:	1be080e7          	jalr	446(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004a1a:	02c92603          	lw	a2,44(s2)
    80004a1e:	47f5                	li	a5,29
    80004a20:	06c7c563          	blt	a5,a2,80004a8a <log_write+0x90>
    80004a24:	0001d797          	auipc	a5,0x1d
    80004a28:	0f87a783          	lw	a5,248(a5) # 80021b1c <log+0x1c>
    80004a2c:	37fd                	addiw	a5,a5,-1
    80004a2e:	04f65e63          	bge	a2,a5,80004a8a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004a32:	0001d797          	auipc	a5,0x1d
    80004a36:	0ee7a783          	lw	a5,238(a5) # 80021b20 <log+0x20>
    80004a3a:	06f05063          	blez	a5,80004a9a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004a3e:	4781                	li	a5,0
    80004a40:	06c05563          	blez	a2,80004aaa <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a44:	44cc                	lw	a1,12(s1)
    80004a46:	0001d717          	auipc	a4,0x1d
    80004a4a:	0ea70713          	addi	a4,a4,234 # 80021b30 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004a4e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a50:	4314                	lw	a3,0(a4)
    80004a52:	04b68c63          	beq	a3,a1,80004aaa <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004a56:	2785                	addiw	a5,a5,1
    80004a58:	0711                	addi	a4,a4,4
    80004a5a:	fef61be3          	bne	a2,a5,80004a50 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004a5e:	0621                	addi	a2,a2,8
    80004a60:	060a                	slli	a2,a2,0x2
    80004a62:	0001d797          	auipc	a5,0x1d
    80004a66:	09e78793          	addi	a5,a5,158 # 80021b00 <log>
    80004a6a:	97b2                	add	a5,a5,a2
    80004a6c:	44d8                	lw	a4,12(s1)
    80004a6e:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a70:	8526                	mv	a0,s1
    80004a72:	fffff097          	auipc	ra,0xfffff
    80004a76:	da2080e7          	jalr	-606(ra) # 80003814 <bpin>
    log.lh.n++;
    80004a7a:	0001d717          	auipc	a4,0x1d
    80004a7e:	08670713          	addi	a4,a4,134 # 80021b00 <log>
    80004a82:	575c                	lw	a5,44(a4)
    80004a84:	2785                	addiw	a5,a5,1
    80004a86:	d75c                	sw	a5,44(a4)
    80004a88:	a82d                	j	80004ac2 <log_write+0xc8>
    panic("too big a transaction");
    80004a8a:	00004517          	auipc	a0,0x4
    80004a8e:	c2e50513          	addi	a0,a0,-978 # 800086b8 <syscalls+0x200>
    80004a92:	ffffc097          	auipc	ra,0xffffc
    80004a96:	aa8080e7          	jalr	-1368(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    80004a9a:	00004517          	auipc	a0,0x4
    80004a9e:	c3650513          	addi	a0,a0,-970 # 800086d0 <syscalls+0x218>
    80004aa2:	ffffc097          	auipc	ra,0xffffc
    80004aa6:	a98080e7          	jalr	-1384(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    80004aaa:	00878693          	addi	a3,a5,8
    80004aae:	068a                	slli	a3,a3,0x2
    80004ab0:	0001d717          	auipc	a4,0x1d
    80004ab4:	05070713          	addi	a4,a4,80 # 80021b00 <log>
    80004ab8:	9736                	add	a4,a4,a3
    80004aba:	44d4                	lw	a3,12(s1)
    80004abc:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004abe:	faf609e3          	beq	a2,a5,80004a70 <log_write+0x76>
  }
  release(&log.lock);
    80004ac2:	0001d517          	auipc	a0,0x1d
    80004ac6:	03e50513          	addi	a0,a0,62 # 80021b00 <log>
    80004aca:	ffffc097          	auipc	ra,0xffffc
    80004ace:	1ba080e7          	jalr	442(ra) # 80000c84 <release>
}
    80004ad2:	60e2                	ld	ra,24(sp)
    80004ad4:	6442                	ld	s0,16(sp)
    80004ad6:	64a2                	ld	s1,8(sp)
    80004ad8:	6902                	ld	s2,0(sp)
    80004ada:	6105                	addi	sp,sp,32
    80004adc:	8082                	ret

0000000080004ade <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004ade:	1101                	addi	sp,sp,-32
    80004ae0:	ec06                	sd	ra,24(sp)
    80004ae2:	e822                	sd	s0,16(sp)
    80004ae4:	e426                	sd	s1,8(sp)
    80004ae6:	e04a                	sd	s2,0(sp)
    80004ae8:	1000                	addi	s0,sp,32
    80004aea:	84aa                	mv	s1,a0
    80004aec:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004aee:	00004597          	auipc	a1,0x4
    80004af2:	c0258593          	addi	a1,a1,-1022 # 800086f0 <syscalls+0x238>
    80004af6:	0521                	addi	a0,a0,8
    80004af8:	ffffc097          	auipc	ra,0xffffc
    80004afc:	048080e7          	jalr	72(ra) # 80000b40 <initlock>
  lk->name = name;
    80004b00:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004b04:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b08:	0204a423          	sw	zero,40(s1)
}
    80004b0c:	60e2                	ld	ra,24(sp)
    80004b0e:	6442                	ld	s0,16(sp)
    80004b10:	64a2                	ld	s1,8(sp)
    80004b12:	6902                	ld	s2,0(sp)
    80004b14:	6105                	addi	sp,sp,32
    80004b16:	8082                	ret

0000000080004b18 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004b18:	1101                	addi	sp,sp,-32
    80004b1a:	ec06                	sd	ra,24(sp)
    80004b1c:	e822                	sd	s0,16(sp)
    80004b1e:	e426                	sd	s1,8(sp)
    80004b20:	e04a                	sd	s2,0(sp)
    80004b22:	1000                	addi	s0,sp,32
    80004b24:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b26:	00850913          	addi	s2,a0,8
    80004b2a:	854a                	mv	a0,s2
    80004b2c:	ffffc097          	auipc	ra,0xffffc
    80004b30:	0a4080e7          	jalr	164(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    80004b34:	409c                	lw	a5,0(s1)
    80004b36:	cb89                	beqz	a5,80004b48 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004b38:	85ca                	mv	a1,s2
    80004b3a:	8526                	mv	a0,s1
    80004b3c:	ffffe097          	auipc	ra,0xffffe
    80004b40:	892080e7          	jalr	-1902(ra) # 800023ce <sleep>
  while (lk->locked) {
    80004b44:	409c                	lw	a5,0(s1)
    80004b46:	fbed                	bnez	a5,80004b38 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004b48:	4785                	li	a5,1
    80004b4a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004b4c:	ffffd097          	auipc	ra,0xffffd
    80004b50:	104080e7          	jalr	260(ra) # 80001c50 <myproc>
    80004b54:	591c                	lw	a5,48(a0)
    80004b56:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004b58:	854a                	mv	a0,s2
    80004b5a:	ffffc097          	auipc	ra,0xffffc
    80004b5e:	12a080e7          	jalr	298(ra) # 80000c84 <release>
}
    80004b62:	60e2                	ld	ra,24(sp)
    80004b64:	6442                	ld	s0,16(sp)
    80004b66:	64a2                	ld	s1,8(sp)
    80004b68:	6902                	ld	s2,0(sp)
    80004b6a:	6105                	addi	sp,sp,32
    80004b6c:	8082                	ret

0000000080004b6e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b6e:	1101                	addi	sp,sp,-32
    80004b70:	ec06                	sd	ra,24(sp)
    80004b72:	e822                	sd	s0,16(sp)
    80004b74:	e426                	sd	s1,8(sp)
    80004b76:	e04a                	sd	s2,0(sp)
    80004b78:	1000                	addi	s0,sp,32
    80004b7a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b7c:	00850913          	addi	s2,a0,8
    80004b80:	854a                	mv	a0,s2
    80004b82:	ffffc097          	auipc	ra,0xffffc
    80004b86:	04e080e7          	jalr	78(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    80004b8a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b8e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b92:	8526                	mv	a0,s1
    80004b94:	ffffe097          	auipc	ra,0xffffe
    80004b98:	9c6080e7          	jalr	-1594(ra) # 8000255a <wakeup>
  release(&lk->lk);
    80004b9c:	854a                	mv	a0,s2
    80004b9e:	ffffc097          	auipc	ra,0xffffc
    80004ba2:	0e6080e7          	jalr	230(ra) # 80000c84 <release>
}
    80004ba6:	60e2                	ld	ra,24(sp)
    80004ba8:	6442                	ld	s0,16(sp)
    80004baa:	64a2                	ld	s1,8(sp)
    80004bac:	6902                	ld	s2,0(sp)
    80004bae:	6105                	addi	sp,sp,32
    80004bb0:	8082                	ret

0000000080004bb2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004bb2:	7179                	addi	sp,sp,-48
    80004bb4:	f406                	sd	ra,40(sp)
    80004bb6:	f022                	sd	s0,32(sp)
    80004bb8:	ec26                	sd	s1,24(sp)
    80004bba:	e84a                	sd	s2,16(sp)
    80004bbc:	e44e                	sd	s3,8(sp)
    80004bbe:	1800                	addi	s0,sp,48
    80004bc0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004bc2:	00850913          	addi	s2,a0,8
    80004bc6:	854a                	mv	a0,s2
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	008080e7          	jalr	8(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004bd0:	409c                	lw	a5,0(s1)
    80004bd2:	ef99                	bnez	a5,80004bf0 <holdingsleep+0x3e>
    80004bd4:	4481                	li	s1,0
  release(&lk->lk);
    80004bd6:	854a                	mv	a0,s2
    80004bd8:	ffffc097          	auipc	ra,0xffffc
    80004bdc:	0ac080e7          	jalr	172(ra) # 80000c84 <release>
  return r;
}
    80004be0:	8526                	mv	a0,s1
    80004be2:	70a2                	ld	ra,40(sp)
    80004be4:	7402                	ld	s0,32(sp)
    80004be6:	64e2                	ld	s1,24(sp)
    80004be8:	6942                	ld	s2,16(sp)
    80004bea:	69a2                	ld	s3,8(sp)
    80004bec:	6145                	addi	sp,sp,48
    80004bee:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004bf0:	0284a983          	lw	s3,40(s1)
    80004bf4:	ffffd097          	auipc	ra,0xffffd
    80004bf8:	05c080e7          	jalr	92(ra) # 80001c50 <myproc>
    80004bfc:	5904                	lw	s1,48(a0)
    80004bfe:	413484b3          	sub	s1,s1,s3
    80004c02:	0014b493          	seqz	s1,s1
    80004c06:	bfc1                	j	80004bd6 <holdingsleep+0x24>

0000000080004c08 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004c08:	1141                	addi	sp,sp,-16
    80004c0a:	e406                	sd	ra,8(sp)
    80004c0c:	e022                	sd	s0,0(sp)
    80004c0e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004c10:	00004597          	auipc	a1,0x4
    80004c14:	af058593          	addi	a1,a1,-1296 # 80008700 <syscalls+0x248>
    80004c18:	0001d517          	auipc	a0,0x1d
    80004c1c:	03050513          	addi	a0,a0,48 # 80021c48 <ftable>
    80004c20:	ffffc097          	auipc	ra,0xffffc
    80004c24:	f20080e7          	jalr	-224(ra) # 80000b40 <initlock>
}
    80004c28:	60a2                	ld	ra,8(sp)
    80004c2a:	6402                	ld	s0,0(sp)
    80004c2c:	0141                	addi	sp,sp,16
    80004c2e:	8082                	ret

0000000080004c30 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004c30:	1101                	addi	sp,sp,-32
    80004c32:	ec06                	sd	ra,24(sp)
    80004c34:	e822                	sd	s0,16(sp)
    80004c36:	e426                	sd	s1,8(sp)
    80004c38:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004c3a:	0001d517          	auipc	a0,0x1d
    80004c3e:	00e50513          	addi	a0,a0,14 # 80021c48 <ftable>
    80004c42:	ffffc097          	auipc	ra,0xffffc
    80004c46:	f8e080e7          	jalr	-114(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c4a:	0001d497          	auipc	s1,0x1d
    80004c4e:	01648493          	addi	s1,s1,22 # 80021c60 <ftable+0x18>
    80004c52:	0001e717          	auipc	a4,0x1e
    80004c56:	fae70713          	addi	a4,a4,-82 # 80022c00 <ftable+0xfb8>
    if(f->ref == 0){
    80004c5a:	40dc                	lw	a5,4(s1)
    80004c5c:	cf99                	beqz	a5,80004c7a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c5e:	02848493          	addi	s1,s1,40
    80004c62:	fee49ce3          	bne	s1,a4,80004c5a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004c66:	0001d517          	auipc	a0,0x1d
    80004c6a:	fe250513          	addi	a0,a0,-30 # 80021c48 <ftable>
    80004c6e:	ffffc097          	auipc	ra,0xffffc
    80004c72:	016080e7          	jalr	22(ra) # 80000c84 <release>
  return 0;
    80004c76:	4481                	li	s1,0
    80004c78:	a819                	j	80004c8e <filealloc+0x5e>
      f->ref = 1;
    80004c7a:	4785                	li	a5,1
    80004c7c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c7e:	0001d517          	auipc	a0,0x1d
    80004c82:	fca50513          	addi	a0,a0,-54 # 80021c48 <ftable>
    80004c86:	ffffc097          	auipc	ra,0xffffc
    80004c8a:	ffe080e7          	jalr	-2(ra) # 80000c84 <release>
}
    80004c8e:	8526                	mv	a0,s1
    80004c90:	60e2                	ld	ra,24(sp)
    80004c92:	6442                	ld	s0,16(sp)
    80004c94:	64a2                	ld	s1,8(sp)
    80004c96:	6105                	addi	sp,sp,32
    80004c98:	8082                	ret

0000000080004c9a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c9a:	1101                	addi	sp,sp,-32
    80004c9c:	ec06                	sd	ra,24(sp)
    80004c9e:	e822                	sd	s0,16(sp)
    80004ca0:	e426                	sd	s1,8(sp)
    80004ca2:	1000                	addi	s0,sp,32
    80004ca4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004ca6:	0001d517          	auipc	a0,0x1d
    80004caa:	fa250513          	addi	a0,a0,-94 # 80021c48 <ftable>
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	f22080e7          	jalr	-222(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004cb6:	40dc                	lw	a5,4(s1)
    80004cb8:	02f05263          	blez	a5,80004cdc <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004cbc:	2785                	addiw	a5,a5,1
    80004cbe:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004cc0:	0001d517          	auipc	a0,0x1d
    80004cc4:	f8850513          	addi	a0,a0,-120 # 80021c48 <ftable>
    80004cc8:	ffffc097          	auipc	ra,0xffffc
    80004ccc:	fbc080e7          	jalr	-68(ra) # 80000c84 <release>
  return f;
}
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	60e2                	ld	ra,24(sp)
    80004cd4:	6442                	ld	s0,16(sp)
    80004cd6:	64a2                	ld	s1,8(sp)
    80004cd8:	6105                	addi	sp,sp,32
    80004cda:	8082                	ret
    panic("filedup");
    80004cdc:	00004517          	auipc	a0,0x4
    80004ce0:	a2c50513          	addi	a0,a0,-1492 # 80008708 <syscalls+0x250>
    80004ce4:	ffffc097          	auipc	ra,0xffffc
    80004ce8:	856080e7          	jalr	-1962(ra) # 8000053a <panic>

0000000080004cec <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004cec:	7139                	addi	sp,sp,-64
    80004cee:	fc06                	sd	ra,56(sp)
    80004cf0:	f822                	sd	s0,48(sp)
    80004cf2:	f426                	sd	s1,40(sp)
    80004cf4:	f04a                	sd	s2,32(sp)
    80004cf6:	ec4e                	sd	s3,24(sp)
    80004cf8:	e852                	sd	s4,16(sp)
    80004cfa:	e456                	sd	s5,8(sp)
    80004cfc:	0080                	addi	s0,sp,64
    80004cfe:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004d00:	0001d517          	auipc	a0,0x1d
    80004d04:	f4850513          	addi	a0,a0,-184 # 80021c48 <ftable>
    80004d08:	ffffc097          	auipc	ra,0xffffc
    80004d0c:	ec8080e7          	jalr	-312(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004d10:	40dc                	lw	a5,4(s1)
    80004d12:	06f05163          	blez	a5,80004d74 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004d16:	37fd                	addiw	a5,a5,-1
    80004d18:	0007871b          	sext.w	a4,a5
    80004d1c:	c0dc                	sw	a5,4(s1)
    80004d1e:	06e04363          	bgtz	a4,80004d84 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004d22:	0004a903          	lw	s2,0(s1)
    80004d26:	0094ca83          	lbu	s5,9(s1)
    80004d2a:	0104ba03          	ld	s4,16(s1)
    80004d2e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004d32:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004d36:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004d3a:	0001d517          	auipc	a0,0x1d
    80004d3e:	f0e50513          	addi	a0,a0,-242 # 80021c48 <ftable>
    80004d42:	ffffc097          	auipc	ra,0xffffc
    80004d46:	f42080e7          	jalr	-190(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    80004d4a:	4785                	li	a5,1
    80004d4c:	04f90d63          	beq	s2,a5,80004da6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004d50:	3979                	addiw	s2,s2,-2
    80004d52:	4785                	li	a5,1
    80004d54:	0527e063          	bltu	a5,s2,80004d94 <fileclose+0xa8>
    begin_op();
    80004d58:	00000097          	auipc	ra,0x0
    80004d5c:	acc080e7          	jalr	-1332(ra) # 80004824 <begin_op>
    iput(ff.ip);
    80004d60:	854e                	mv	a0,s3
    80004d62:	fffff097          	auipc	ra,0xfffff
    80004d66:	2a0080e7          	jalr	672(ra) # 80004002 <iput>
    end_op();
    80004d6a:	00000097          	auipc	ra,0x0
    80004d6e:	b38080e7          	jalr	-1224(ra) # 800048a2 <end_op>
    80004d72:	a00d                	j	80004d94 <fileclose+0xa8>
    panic("fileclose");
    80004d74:	00004517          	auipc	a0,0x4
    80004d78:	99c50513          	addi	a0,a0,-1636 # 80008710 <syscalls+0x258>
    80004d7c:	ffffb097          	auipc	ra,0xffffb
    80004d80:	7be080e7          	jalr	1982(ra) # 8000053a <panic>
    release(&ftable.lock);
    80004d84:	0001d517          	auipc	a0,0x1d
    80004d88:	ec450513          	addi	a0,a0,-316 # 80021c48 <ftable>
    80004d8c:	ffffc097          	auipc	ra,0xffffc
    80004d90:	ef8080e7          	jalr	-264(ra) # 80000c84 <release>
  }
}
    80004d94:	70e2                	ld	ra,56(sp)
    80004d96:	7442                	ld	s0,48(sp)
    80004d98:	74a2                	ld	s1,40(sp)
    80004d9a:	7902                	ld	s2,32(sp)
    80004d9c:	69e2                	ld	s3,24(sp)
    80004d9e:	6a42                	ld	s4,16(sp)
    80004da0:	6aa2                	ld	s5,8(sp)
    80004da2:	6121                	addi	sp,sp,64
    80004da4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004da6:	85d6                	mv	a1,s5
    80004da8:	8552                	mv	a0,s4
    80004daa:	00000097          	auipc	ra,0x0
    80004dae:	34c080e7          	jalr	844(ra) # 800050f6 <pipeclose>
    80004db2:	b7cd                	j	80004d94 <fileclose+0xa8>

0000000080004db4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004db4:	715d                	addi	sp,sp,-80
    80004db6:	e486                	sd	ra,72(sp)
    80004db8:	e0a2                	sd	s0,64(sp)
    80004dba:	fc26                	sd	s1,56(sp)
    80004dbc:	f84a                	sd	s2,48(sp)
    80004dbe:	f44e                	sd	s3,40(sp)
    80004dc0:	0880                	addi	s0,sp,80
    80004dc2:	84aa                	mv	s1,a0
    80004dc4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004dc6:	ffffd097          	auipc	ra,0xffffd
    80004dca:	e8a080e7          	jalr	-374(ra) # 80001c50 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004dce:	409c                	lw	a5,0(s1)
    80004dd0:	37f9                	addiw	a5,a5,-2
    80004dd2:	4705                	li	a4,1
    80004dd4:	04f76763          	bltu	a4,a5,80004e22 <filestat+0x6e>
    80004dd8:	892a                	mv	s2,a0
    ilock(f->ip);
    80004dda:	6c88                	ld	a0,24(s1)
    80004ddc:	fffff097          	auipc	ra,0xfffff
    80004de0:	06c080e7          	jalr	108(ra) # 80003e48 <ilock>
    stati(f->ip, &st);
    80004de4:	fb840593          	addi	a1,s0,-72
    80004de8:	6c88                	ld	a0,24(s1)
    80004dea:	fffff097          	auipc	ra,0xfffff
    80004dee:	2e8080e7          	jalr	744(ra) # 800040d2 <stati>
    iunlock(f->ip);
    80004df2:	6c88                	ld	a0,24(s1)
    80004df4:	fffff097          	auipc	ra,0xfffff
    80004df8:	116080e7          	jalr	278(ra) # 80003f0a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004dfc:	46e1                	li	a3,24
    80004dfe:	fb840613          	addi	a2,s0,-72
    80004e02:	85ce                	mv	a1,s3
    80004e04:	07093503          	ld	a0,112(s2)
    80004e08:	ffffd097          	auipc	ra,0xffffd
    80004e0c:	852080e7          	jalr	-1966(ra) # 8000165a <copyout>
    80004e10:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004e14:	60a6                	ld	ra,72(sp)
    80004e16:	6406                	ld	s0,64(sp)
    80004e18:	74e2                	ld	s1,56(sp)
    80004e1a:	7942                	ld	s2,48(sp)
    80004e1c:	79a2                	ld	s3,40(sp)
    80004e1e:	6161                	addi	sp,sp,80
    80004e20:	8082                	ret
  return -1;
    80004e22:	557d                	li	a0,-1
    80004e24:	bfc5                	j	80004e14 <filestat+0x60>

0000000080004e26 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004e26:	7179                	addi	sp,sp,-48
    80004e28:	f406                	sd	ra,40(sp)
    80004e2a:	f022                	sd	s0,32(sp)
    80004e2c:	ec26                	sd	s1,24(sp)
    80004e2e:	e84a                	sd	s2,16(sp)
    80004e30:	e44e                	sd	s3,8(sp)
    80004e32:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004e34:	00854783          	lbu	a5,8(a0)
    80004e38:	c3d5                	beqz	a5,80004edc <fileread+0xb6>
    80004e3a:	84aa                	mv	s1,a0
    80004e3c:	89ae                	mv	s3,a1
    80004e3e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e40:	411c                	lw	a5,0(a0)
    80004e42:	4705                	li	a4,1
    80004e44:	04e78963          	beq	a5,a4,80004e96 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e48:	470d                	li	a4,3
    80004e4a:	04e78d63          	beq	a5,a4,80004ea4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e4e:	4709                	li	a4,2
    80004e50:	06e79e63          	bne	a5,a4,80004ecc <fileread+0xa6>
    ilock(f->ip);
    80004e54:	6d08                	ld	a0,24(a0)
    80004e56:	fffff097          	auipc	ra,0xfffff
    80004e5a:	ff2080e7          	jalr	-14(ra) # 80003e48 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004e5e:	874a                	mv	a4,s2
    80004e60:	5094                	lw	a3,32(s1)
    80004e62:	864e                	mv	a2,s3
    80004e64:	4585                	li	a1,1
    80004e66:	6c88                	ld	a0,24(s1)
    80004e68:	fffff097          	auipc	ra,0xfffff
    80004e6c:	294080e7          	jalr	660(ra) # 800040fc <readi>
    80004e70:	892a                	mv	s2,a0
    80004e72:	00a05563          	blez	a0,80004e7c <fileread+0x56>
      f->off += r;
    80004e76:	509c                	lw	a5,32(s1)
    80004e78:	9fa9                	addw	a5,a5,a0
    80004e7a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e7c:	6c88                	ld	a0,24(s1)
    80004e7e:	fffff097          	auipc	ra,0xfffff
    80004e82:	08c080e7          	jalr	140(ra) # 80003f0a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e86:	854a                	mv	a0,s2
    80004e88:	70a2                	ld	ra,40(sp)
    80004e8a:	7402                	ld	s0,32(sp)
    80004e8c:	64e2                	ld	s1,24(sp)
    80004e8e:	6942                	ld	s2,16(sp)
    80004e90:	69a2                	ld	s3,8(sp)
    80004e92:	6145                	addi	sp,sp,48
    80004e94:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e96:	6908                	ld	a0,16(a0)
    80004e98:	00000097          	auipc	ra,0x0
    80004e9c:	3c0080e7          	jalr	960(ra) # 80005258 <piperead>
    80004ea0:	892a                	mv	s2,a0
    80004ea2:	b7d5                	j	80004e86 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004ea4:	02451783          	lh	a5,36(a0)
    80004ea8:	03079693          	slli	a3,a5,0x30
    80004eac:	92c1                	srli	a3,a3,0x30
    80004eae:	4725                	li	a4,9
    80004eb0:	02d76863          	bltu	a4,a3,80004ee0 <fileread+0xba>
    80004eb4:	0792                	slli	a5,a5,0x4
    80004eb6:	0001d717          	auipc	a4,0x1d
    80004eba:	cf270713          	addi	a4,a4,-782 # 80021ba8 <devsw>
    80004ebe:	97ba                	add	a5,a5,a4
    80004ec0:	639c                	ld	a5,0(a5)
    80004ec2:	c38d                	beqz	a5,80004ee4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ec4:	4505                	li	a0,1
    80004ec6:	9782                	jalr	a5
    80004ec8:	892a                	mv	s2,a0
    80004eca:	bf75                	j	80004e86 <fileread+0x60>
    panic("fileread");
    80004ecc:	00004517          	auipc	a0,0x4
    80004ed0:	85450513          	addi	a0,a0,-1964 # 80008720 <syscalls+0x268>
    80004ed4:	ffffb097          	auipc	ra,0xffffb
    80004ed8:	666080e7          	jalr	1638(ra) # 8000053a <panic>
    return -1;
    80004edc:	597d                	li	s2,-1
    80004ede:	b765                	j	80004e86 <fileread+0x60>
      return -1;
    80004ee0:	597d                	li	s2,-1
    80004ee2:	b755                	j	80004e86 <fileread+0x60>
    80004ee4:	597d                	li	s2,-1
    80004ee6:	b745                	j	80004e86 <fileread+0x60>

0000000080004ee8 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004ee8:	715d                	addi	sp,sp,-80
    80004eea:	e486                	sd	ra,72(sp)
    80004eec:	e0a2                	sd	s0,64(sp)
    80004eee:	fc26                	sd	s1,56(sp)
    80004ef0:	f84a                	sd	s2,48(sp)
    80004ef2:	f44e                	sd	s3,40(sp)
    80004ef4:	f052                	sd	s4,32(sp)
    80004ef6:	ec56                	sd	s5,24(sp)
    80004ef8:	e85a                	sd	s6,16(sp)
    80004efa:	e45e                	sd	s7,8(sp)
    80004efc:	e062                	sd	s8,0(sp)
    80004efe:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004f00:	00954783          	lbu	a5,9(a0)
    80004f04:	10078663          	beqz	a5,80005010 <filewrite+0x128>
    80004f08:	892a                	mv	s2,a0
    80004f0a:	8b2e                	mv	s6,a1
    80004f0c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f0e:	411c                	lw	a5,0(a0)
    80004f10:	4705                	li	a4,1
    80004f12:	02e78263          	beq	a5,a4,80004f36 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f16:	470d                	li	a4,3
    80004f18:	02e78663          	beq	a5,a4,80004f44 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f1c:	4709                	li	a4,2
    80004f1e:	0ee79163          	bne	a5,a4,80005000 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004f22:	0ac05d63          	blez	a2,80004fdc <filewrite+0xf4>
    int i = 0;
    80004f26:	4981                	li	s3,0
    80004f28:	6b85                	lui	s7,0x1
    80004f2a:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004f2e:	6c05                	lui	s8,0x1
    80004f30:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004f34:	a861                	j	80004fcc <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004f36:	6908                	ld	a0,16(a0)
    80004f38:	00000097          	auipc	ra,0x0
    80004f3c:	22e080e7          	jalr	558(ra) # 80005166 <pipewrite>
    80004f40:	8a2a                	mv	s4,a0
    80004f42:	a045                	j	80004fe2 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004f44:	02451783          	lh	a5,36(a0)
    80004f48:	03079693          	slli	a3,a5,0x30
    80004f4c:	92c1                	srli	a3,a3,0x30
    80004f4e:	4725                	li	a4,9
    80004f50:	0cd76263          	bltu	a4,a3,80005014 <filewrite+0x12c>
    80004f54:	0792                	slli	a5,a5,0x4
    80004f56:	0001d717          	auipc	a4,0x1d
    80004f5a:	c5270713          	addi	a4,a4,-942 # 80021ba8 <devsw>
    80004f5e:	97ba                	add	a5,a5,a4
    80004f60:	679c                	ld	a5,8(a5)
    80004f62:	cbdd                	beqz	a5,80005018 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004f64:	4505                	li	a0,1
    80004f66:	9782                	jalr	a5
    80004f68:	8a2a                	mv	s4,a0
    80004f6a:	a8a5                	j	80004fe2 <filewrite+0xfa>
    80004f6c:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004f70:	00000097          	auipc	ra,0x0
    80004f74:	8b4080e7          	jalr	-1868(ra) # 80004824 <begin_op>
      ilock(f->ip);
    80004f78:	01893503          	ld	a0,24(s2)
    80004f7c:	fffff097          	auipc	ra,0xfffff
    80004f80:	ecc080e7          	jalr	-308(ra) # 80003e48 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f84:	8756                	mv	a4,s5
    80004f86:	02092683          	lw	a3,32(s2)
    80004f8a:	01698633          	add	a2,s3,s6
    80004f8e:	4585                	li	a1,1
    80004f90:	01893503          	ld	a0,24(s2)
    80004f94:	fffff097          	auipc	ra,0xfffff
    80004f98:	260080e7          	jalr	608(ra) # 800041f4 <writei>
    80004f9c:	84aa                	mv	s1,a0
    80004f9e:	00a05763          	blez	a0,80004fac <filewrite+0xc4>
        f->off += r;
    80004fa2:	02092783          	lw	a5,32(s2)
    80004fa6:	9fa9                	addw	a5,a5,a0
    80004fa8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004fac:	01893503          	ld	a0,24(s2)
    80004fb0:	fffff097          	auipc	ra,0xfffff
    80004fb4:	f5a080e7          	jalr	-166(ra) # 80003f0a <iunlock>
      end_op();
    80004fb8:	00000097          	auipc	ra,0x0
    80004fbc:	8ea080e7          	jalr	-1814(ra) # 800048a2 <end_op>

      if(r != n1){
    80004fc0:	009a9f63          	bne	s5,s1,80004fde <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004fc4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004fc8:	0149db63          	bge	s3,s4,80004fde <filewrite+0xf6>
      int n1 = n - i;
    80004fcc:	413a04bb          	subw	s1,s4,s3
    80004fd0:	0004879b          	sext.w	a5,s1
    80004fd4:	f8fbdce3          	bge	s7,a5,80004f6c <filewrite+0x84>
    80004fd8:	84e2                	mv	s1,s8
    80004fda:	bf49                	j	80004f6c <filewrite+0x84>
    int i = 0;
    80004fdc:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004fde:	013a1f63          	bne	s4,s3,80004ffc <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004fe2:	8552                	mv	a0,s4
    80004fe4:	60a6                	ld	ra,72(sp)
    80004fe6:	6406                	ld	s0,64(sp)
    80004fe8:	74e2                	ld	s1,56(sp)
    80004fea:	7942                	ld	s2,48(sp)
    80004fec:	79a2                	ld	s3,40(sp)
    80004fee:	7a02                	ld	s4,32(sp)
    80004ff0:	6ae2                	ld	s5,24(sp)
    80004ff2:	6b42                	ld	s6,16(sp)
    80004ff4:	6ba2                	ld	s7,8(sp)
    80004ff6:	6c02                	ld	s8,0(sp)
    80004ff8:	6161                	addi	sp,sp,80
    80004ffa:	8082                	ret
    ret = (i == n ? n : -1);
    80004ffc:	5a7d                	li	s4,-1
    80004ffe:	b7d5                	j	80004fe2 <filewrite+0xfa>
    panic("filewrite");
    80005000:	00003517          	auipc	a0,0x3
    80005004:	73050513          	addi	a0,a0,1840 # 80008730 <syscalls+0x278>
    80005008:	ffffb097          	auipc	ra,0xffffb
    8000500c:	532080e7          	jalr	1330(ra) # 8000053a <panic>
    return -1;
    80005010:	5a7d                	li	s4,-1
    80005012:	bfc1                	j	80004fe2 <filewrite+0xfa>
      return -1;
    80005014:	5a7d                	li	s4,-1
    80005016:	b7f1                	j	80004fe2 <filewrite+0xfa>
    80005018:	5a7d                	li	s4,-1
    8000501a:	b7e1                	j	80004fe2 <filewrite+0xfa>

000000008000501c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000501c:	7179                	addi	sp,sp,-48
    8000501e:	f406                	sd	ra,40(sp)
    80005020:	f022                	sd	s0,32(sp)
    80005022:	ec26                	sd	s1,24(sp)
    80005024:	e84a                	sd	s2,16(sp)
    80005026:	e44e                	sd	s3,8(sp)
    80005028:	e052                	sd	s4,0(sp)
    8000502a:	1800                	addi	s0,sp,48
    8000502c:	84aa                	mv	s1,a0
    8000502e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005030:	0005b023          	sd	zero,0(a1)
    80005034:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005038:	00000097          	auipc	ra,0x0
    8000503c:	bf8080e7          	jalr	-1032(ra) # 80004c30 <filealloc>
    80005040:	e088                	sd	a0,0(s1)
    80005042:	c551                	beqz	a0,800050ce <pipealloc+0xb2>
    80005044:	00000097          	auipc	ra,0x0
    80005048:	bec080e7          	jalr	-1044(ra) # 80004c30 <filealloc>
    8000504c:	00aa3023          	sd	a0,0(s4)
    80005050:	c92d                	beqz	a0,800050c2 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005052:	ffffc097          	auipc	ra,0xffffc
    80005056:	a8e080e7          	jalr	-1394(ra) # 80000ae0 <kalloc>
    8000505a:	892a                	mv	s2,a0
    8000505c:	c125                	beqz	a0,800050bc <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000505e:	4985                	li	s3,1
    80005060:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005064:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005068:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000506c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005070:	00003597          	auipc	a1,0x3
    80005074:	6d058593          	addi	a1,a1,1744 # 80008740 <syscalls+0x288>
    80005078:	ffffc097          	auipc	ra,0xffffc
    8000507c:	ac8080e7          	jalr	-1336(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    80005080:	609c                	ld	a5,0(s1)
    80005082:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005086:	609c                	ld	a5,0(s1)
    80005088:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000508c:	609c                	ld	a5,0(s1)
    8000508e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005092:	609c                	ld	a5,0(s1)
    80005094:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005098:	000a3783          	ld	a5,0(s4)
    8000509c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800050a0:	000a3783          	ld	a5,0(s4)
    800050a4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800050a8:	000a3783          	ld	a5,0(s4)
    800050ac:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800050b0:	000a3783          	ld	a5,0(s4)
    800050b4:	0127b823          	sd	s2,16(a5)
  return 0;
    800050b8:	4501                	li	a0,0
    800050ba:	a025                	j	800050e2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800050bc:	6088                	ld	a0,0(s1)
    800050be:	e501                	bnez	a0,800050c6 <pipealloc+0xaa>
    800050c0:	a039                	j	800050ce <pipealloc+0xb2>
    800050c2:	6088                	ld	a0,0(s1)
    800050c4:	c51d                	beqz	a0,800050f2 <pipealloc+0xd6>
    fileclose(*f0);
    800050c6:	00000097          	auipc	ra,0x0
    800050ca:	c26080e7          	jalr	-986(ra) # 80004cec <fileclose>
  if(*f1)
    800050ce:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800050d2:	557d                	li	a0,-1
  if(*f1)
    800050d4:	c799                	beqz	a5,800050e2 <pipealloc+0xc6>
    fileclose(*f1);
    800050d6:	853e                	mv	a0,a5
    800050d8:	00000097          	auipc	ra,0x0
    800050dc:	c14080e7          	jalr	-1004(ra) # 80004cec <fileclose>
  return -1;
    800050e0:	557d                	li	a0,-1
}
    800050e2:	70a2                	ld	ra,40(sp)
    800050e4:	7402                	ld	s0,32(sp)
    800050e6:	64e2                	ld	s1,24(sp)
    800050e8:	6942                	ld	s2,16(sp)
    800050ea:	69a2                	ld	s3,8(sp)
    800050ec:	6a02                	ld	s4,0(sp)
    800050ee:	6145                	addi	sp,sp,48
    800050f0:	8082                	ret
  return -1;
    800050f2:	557d                	li	a0,-1
    800050f4:	b7fd                	j	800050e2 <pipealloc+0xc6>

00000000800050f6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800050f6:	1101                	addi	sp,sp,-32
    800050f8:	ec06                	sd	ra,24(sp)
    800050fa:	e822                	sd	s0,16(sp)
    800050fc:	e426                	sd	s1,8(sp)
    800050fe:	e04a                	sd	s2,0(sp)
    80005100:	1000                	addi	s0,sp,32
    80005102:	84aa                	mv	s1,a0
    80005104:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005106:	ffffc097          	auipc	ra,0xffffc
    8000510a:	aca080e7          	jalr	-1334(ra) # 80000bd0 <acquire>
  if(writable){
    8000510e:	02090d63          	beqz	s2,80005148 <pipeclose+0x52>
    pi->writeopen = 0;
    80005112:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005116:	21848513          	addi	a0,s1,536
    8000511a:	ffffd097          	auipc	ra,0xffffd
    8000511e:	440080e7          	jalr	1088(ra) # 8000255a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005122:	2204b783          	ld	a5,544(s1)
    80005126:	eb95                	bnez	a5,8000515a <pipeclose+0x64>
    release(&pi->lock);
    80005128:	8526                	mv	a0,s1
    8000512a:	ffffc097          	auipc	ra,0xffffc
    8000512e:	b5a080e7          	jalr	-1190(ra) # 80000c84 <release>
    kfree((char*)pi);
    80005132:	8526                	mv	a0,s1
    80005134:	ffffc097          	auipc	ra,0xffffc
    80005138:	8ae080e7          	jalr	-1874(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    8000513c:	60e2                	ld	ra,24(sp)
    8000513e:	6442                	ld	s0,16(sp)
    80005140:	64a2                	ld	s1,8(sp)
    80005142:	6902                	ld	s2,0(sp)
    80005144:	6105                	addi	sp,sp,32
    80005146:	8082                	ret
    pi->readopen = 0;
    80005148:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000514c:	21c48513          	addi	a0,s1,540
    80005150:	ffffd097          	auipc	ra,0xffffd
    80005154:	40a080e7          	jalr	1034(ra) # 8000255a <wakeup>
    80005158:	b7e9                	j	80005122 <pipeclose+0x2c>
    release(&pi->lock);
    8000515a:	8526                	mv	a0,s1
    8000515c:	ffffc097          	auipc	ra,0xffffc
    80005160:	b28080e7          	jalr	-1240(ra) # 80000c84 <release>
}
    80005164:	bfe1                	j	8000513c <pipeclose+0x46>

0000000080005166 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005166:	711d                	addi	sp,sp,-96
    80005168:	ec86                	sd	ra,88(sp)
    8000516a:	e8a2                	sd	s0,80(sp)
    8000516c:	e4a6                	sd	s1,72(sp)
    8000516e:	e0ca                	sd	s2,64(sp)
    80005170:	fc4e                	sd	s3,56(sp)
    80005172:	f852                	sd	s4,48(sp)
    80005174:	f456                	sd	s5,40(sp)
    80005176:	f05a                	sd	s6,32(sp)
    80005178:	ec5e                	sd	s7,24(sp)
    8000517a:	e862                	sd	s8,16(sp)
    8000517c:	1080                	addi	s0,sp,96
    8000517e:	84aa                	mv	s1,a0
    80005180:	8aae                	mv	s5,a1
    80005182:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005184:	ffffd097          	auipc	ra,0xffffd
    80005188:	acc080e7          	jalr	-1332(ra) # 80001c50 <myproc>
    8000518c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000518e:	8526                	mv	a0,s1
    80005190:	ffffc097          	auipc	ra,0xffffc
    80005194:	a40080e7          	jalr	-1472(ra) # 80000bd0 <acquire>
  while(i < n){
    80005198:	0b405363          	blez	s4,8000523e <pipewrite+0xd8>
  int i = 0;
    8000519c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000519e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800051a0:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800051a4:	21c48b93          	addi	s7,s1,540
    800051a8:	a089                	j	800051ea <pipewrite+0x84>
      release(&pi->lock);
    800051aa:	8526                	mv	a0,s1
    800051ac:	ffffc097          	auipc	ra,0xffffc
    800051b0:	ad8080e7          	jalr	-1320(ra) # 80000c84 <release>
      return -1;
    800051b4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800051b6:	854a                	mv	a0,s2
    800051b8:	60e6                	ld	ra,88(sp)
    800051ba:	6446                	ld	s0,80(sp)
    800051bc:	64a6                	ld	s1,72(sp)
    800051be:	6906                	ld	s2,64(sp)
    800051c0:	79e2                	ld	s3,56(sp)
    800051c2:	7a42                	ld	s4,48(sp)
    800051c4:	7aa2                	ld	s5,40(sp)
    800051c6:	7b02                	ld	s6,32(sp)
    800051c8:	6be2                	ld	s7,24(sp)
    800051ca:	6c42                	ld	s8,16(sp)
    800051cc:	6125                	addi	sp,sp,96
    800051ce:	8082                	ret
      wakeup(&pi->nread);
    800051d0:	8562                	mv	a0,s8
    800051d2:	ffffd097          	auipc	ra,0xffffd
    800051d6:	388080e7          	jalr	904(ra) # 8000255a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800051da:	85a6                	mv	a1,s1
    800051dc:	855e                	mv	a0,s7
    800051de:	ffffd097          	auipc	ra,0xffffd
    800051e2:	1f0080e7          	jalr	496(ra) # 800023ce <sleep>
  while(i < n){
    800051e6:	05495d63          	bge	s2,s4,80005240 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    800051ea:	2204a783          	lw	a5,544(s1)
    800051ee:	dfd5                	beqz	a5,800051aa <pipewrite+0x44>
    800051f0:	0289a783          	lw	a5,40(s3)
    800051f4:	fbdd                	bnez	a5,800051aa <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800051f6:	2184a783          	lw	a5,536(s1)
    800051fa:	21c4a703          	lw	a4,540(s1)
    800051fe:	2007879b          	addiw	a5,a5,512
    80005202:	fcf707e3          	beq	a4,a5,800051d0 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005206:	4685                	li	a3,1
    80005208:	01590633          	add	a2,s2,s5
    8000520c:	faf40593          	addi	a1,s0,-81
    80005210:	0709b503          	ld	a0,112(s3)
    80005214:	ffffc097          	auipc	ra,0xffffc
    80005218:	4d2080e7          	jalr	1234(ra) # 800016e6 <copyin>
    8000521c:	03650263          	beq	a0,s6,80005240 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005220:	21c4a783          	lw	a5,540(s1)
    80005224:	0017871b          	addiw	a4,a5,1
    80005228:	20e4ae23          	sw	a4,540(s1)
    8000522c:	1ff7f793          	andi	a5,a5,511
    80005230:	97a6                	add	a5,a5,s1
    80005232:	faf44703          	lbu	a4,-81(s0)
    80005236:	00e78c23          	sb	a4,24(a5)
      i++;
    8000523a:	2905                	addiw	s2,s2,1
    8000523c:	b76d                	j	800051e6 <pipewrite+0x80>
  int i = 0;
    8000523e:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005240:	21848513          	addi	a0,s1,536
    80005244:	ffffd097          	auipc	ra,0xffffd
    80005248:	316080e7          	jalr	790(ra) # 8000255a <wakeup>
  release(&pi->lock);
    8000524c:	8526                	mv	a0,s1
    8000524e:	ffffc097          	auipc	ra,0xffffc
    80005252:	a36080e7          	jalr	-1482(ra) # 80000c84 <release>
  return i;
    80005256:	b785                	j	800051b6 <pipewrite+0x50>

0000000080005258 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005258:	715d                	addi	sp,sp,-80
    8000525a:	e486                	sd	ra,72(sp)
    8000525c:	e0a2                	sd	s0,64(sp)
    8000525e:	fc26                	sd	s1,56(sp)
    80005260:	f84a                	sd	s2,48(sp)
    80005262:	f44e                	sd	s3,40(sp)
    80005264:	f052                	sd	s4,32(sp)
    80005266:	ec56                	sd	s5,24(sp)
    80005268:	e85a                	sd	s6,16(sp)
    8000526a:	0880                	addi	s0,sp,80
    8000526c:	84aa                	mv	s1,a0
    8000526e:	892e                	mv	s2,a1
    80005270:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005272:	ffffd097          	auipc	ra,0xffffd
    80005276:	9de080e7          	jalr	-1570(ra) # 80001c50 <myproc>
    8000527a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000527c:	8526                	mv	a0,s1
    8000527e:	ffffc097          	auipc	ra,0xffffc
    80005282:	952080e7          	jalr	-1710(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005286:	2184a703          	lw	a4,536(s1)
    8000528a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000528e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005292:	02f71463          	bne	a4,a5,800052ba <piperead+0x62>
    80005296:	2244a783          	lw	a5,548(s1)
    8000529a:	c385                	beqz	a5,800052ba <piperead+0x62>
    if(pr->killed){
    8000529c:	028a2783          	lw	a5,40(s4)
    800052a0:	ebc9                	bnez	a5,80005332 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800052a2:	85a6                	mv	a1,s1
    800052a4:	854e                	mv	a0,s3
    800052a6:	ffffd097          	auipc	ra,0xffffd
    800052aa:	128080e7          	jalr	296(ra) # 800023ce <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052ae:	2184a703          	lw	a4,536(s1)
    800052b2:	21c4a783          	lw	a5,540(s1)
    800052b6:	fef700e3          	beq	a4,a5,80005296 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052ba:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052bc:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052be:	05505463          	blez	s5,80005306 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    800052c2:	2184a783          	lw	a5,536(s1)
    800052c6:	21c4a703          	lw	a4,540(s1)
    800052ca:	02f70e63          	beq	a4,a5,80005306 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800052ce:	0017871b          	addiw	a4,a5,1
    800052d2:	20e4ac23          	sw	a4,536(s1)
    800052d6:	1ff7f793          	andi	a5,a5,511
    800052da:	97a6                	add	a5,a5,s1
    800052dc:	0187c783          	lbu	a5,24(a5)
    800052e0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052e4:	4685                	li	a3,1
    800052e6:	fbf40613          	addi	a2,s0,-65
    800052ea:	85ca                	mv	a1,s2
    800052ec:	070a3503          	ld	a0,112(s4)
    800052f0:	ffffc097          	auipc	ra,0xffffc
    800052f4:	36a080e7          	jalr	874(ra) # 8000165a <copyout>
    800052f8:	01650763          	beq	a0,s6,80005306 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052fc:	2985                	addiw	s3,s3,1
    800052fe:	0905                	addi	s2,s2,1
    80005300:	fd3a91e3          	bne	s5,s3,800052c2 <piperead+0x6a>
    80005304:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005306:	21c48513          	addi	a0,s1,540
    8000530a:	ffffd097          	auipc	ra,0xffffd
    8000530e:	250080e7          	jalr	592(ra) # 8000255a <wakeup>
  release(&pi->lock);
    80005312:	8526                	mv	a0,s1
    80005314:	ffffc097          	auipc	ra,0xffffc
    80005318:	970080e7          	jalr	-1680(ra) # 80000c84 <release>
  return i;
}
    8000531c:	854e                	mv	a0,s3
    8000531e:	60a6                	ld	ra,72(sp)
    80005320:	6406                	ld	s0,64(sp)
    80005322:	74e2                	ld	s1,56(sp)
    80005324:	7942                	ld	s2,48(sp)
    80005326:	79a2                	ld	s3,40(sp)
    80005328:	7a02                	ld	s4,32(sp)
    8000532a:	6ae2                	ld	s5,24(sp)
    8000532c:	6b42                	ld	s6,16(sp)
    8000532e:	6161                	addi	sp,sp,80
    80005330:	8082                	ret
      release(&pi->lock);
    80005332:	8526                	mv	a0,s1
    80005334:	ffffc097          	auipc	ra,0xffffc
    80005338:	950080e7          	jalr	-1712(ra) # 80000c84 <release>
      return -1;
    8000533c:	59fd                	li	s3,-1
    8000533e:	bff9                	j	8000531c <piperead+0xc4>

0000000080005340 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005340:	de010113          	addi	sp,sp,-544
    80005344:	20113c23          	sd	ra,536(sp)
    80005348:	20813823          	sd	s0,528(sp)
    8000534c:	20913423          	sd	s1,520(sp)
    80005350:	21213023          	sd	s2,512(sp)
    80005354:	ffce                	sd	s3,504(sp)
    80005356:	fbd2                	sd	s4,496(sp)
    80005358:	f7d6                	sd	s5,488(sp)
    8000535a:	f3da                	sd	s6,480(sp)
    8000535c:	efde                	sd	s7,472(sp)
    8000535e:	ebe2                	sd	s8,464(sp)
    80005360:	e7e6                	sd	s9,456(sp)
    80005362:	e3ea                	sd	s10,448(sp)
    80005364:	ff6e                	sd	s11,440(sp)
    80005366:	1400                	addi	s0,sp,544
    80005368:	892a                	mv	s2,a0
    8000536a:	dea43423          	sd	a0,-536(s0)
    8000536e:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005372:	ffffd097          	auipc	ra,0xffffd
    80005376:	8de080e7          	jalr	-1826(ra) # 80001c50 <myproc>
    8000537a:	84aa                	mv	s1,a0

  begin_op();
    8000537c:	fffff097          	auipc	ra,0xfffff
    80005380:	4a8080e7          	jalr	1192(ra) # 80004824 <begin_op>

  if((ip = namei(path)) == 0){
    80005384:	854a                	mv	a0,s2
    80005386:	fffff097          	auipc	ra,0xfffff
    8000538a:	27e080e7          	jalr	638(ra) # 80004604 <namei>
    8000538e:	c93d                	beqz	a0,80005404 <exec+0xc4>
    80005390:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005392:	fffff097          	auipc	ra,0xfffff
    80005396:	ab6080e7          	jalr	-1354(ra) # 80003e48 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000539a:	04000713          	li	a4,64
    8000539e:	4681                	li	a3,0
    800053a0:	e5040613          	addi	a2,s0,-432
    800053a4:	4581                	li	a1,0
    800053a6:	8556                	mv	a0,s5
    800053a8:	fffff097          	auipc	ra,0xfffff
    800053ac:	d54080e7          	jalr	-684(ra) # 800040fc <readi>
    800053b0:	04000793          	li	a5,64
    800053b4:	00f51a63          	bne	a0,a5,800053c8 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800053b8:	e5042703          	lw	a4,-432(s0)
    800053bc:	464c47b7          	lui	a5,0x464c4
    800053c0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800053c4:	04f70663          	beq	a4,a5,80005410 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800053c8:	8556                	mv	a0,s5
    800053ca:	fffff097          	auipc	ra,0xfffff
    800053ce:	ce0080e7          	jalr	-800(ra) # 800040aa <iunlockput>
    end_op();
    800053d2:	fffff097          	auipc	ra,0xfffff
    800053d6:	4d0080e7          	jalr	1232(ra) # 800048a2 <end_op>
  }
  return -1;
    800053da:	557d                	li	a0,-1
}
    800053dc:	21813083          	ld	ra,536(sp)
    800053e0:	21013403          	ld	s0,528(sp)
    800053e4:	20813483          	ld	s1,520(sp)
    800053e8:	20013903          	ld	s2,512(sp)
    800053ec:	79fe                	ld	s3,504(sp)
    800053ee:	7a5e                	ld	s4,496(sp)
    800053f0:	7abe                	ld	s5,488(sp)
    800053f2:	7b1e                	ld	s6,480(sp)
    800053f4:	6bfe                	ld	s7,472(sp)
    800053f6:	6c5e                	ld	s8,464(sp)
    800053f8:	6cbe                	ld	s9,456(sp)
    800053fa:	6d1e                	ld	s10,448(sp)
    800053fc:	7dfa                	ld	s11,440(sp)
    800053fe:	22010113          	addi	sp,sp,544
    80005402:	8082                	ret
    end_op();
    80005404:	fffff097          	auipc	ra,0xfffff
    80005408:	49e080e7          	jalr	1182(ra) # 800048a2 <end_op>
    return -1;
    8000540c:	557d                	li	a0,-1
    8000540e:	b7f9                	j	800053dc <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005410:	8526                	mv	a0,s1
    80005412:	ffffd097          	auipc	ra,0xffffd
    80005416:	902080e7          	jalr	-1790(ra) # 80001d14 <proc_pagetable>
    8000541a:	8b2a                	mv	s6,a0
    8000541c:	d555                	beqz	a0,800053c8 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000541e:	e7042783          	lw	a5,-400(s0)
    80005422:	e8845703          	lhu	a4,-376(s0)
    80005426:	c735                	beqz	a4,80005492 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005428:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000542a:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    8000542e:	6a05                	lui	s4,0x1
    80005430:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005434:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005438:	6d85                	lui	s11,0x1
    8000543a:	7d7d                	lui	s10,0xfffff
    8000543c:	ac1d                	j	80005672 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000543e:	00003517          	auipc	a0,0x3
    80005442:	30a50513          	addi	a0,a0,778 # 80008748 <syscalls+0x290>
    80005446:	ffffb097          	auipc	ra,0xffffb
    8000544a:	0f4080e7          	jalr	244(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000544e:	874a                	mv	a4,s2
    80005450:	009c86bb          	addw	a3,s9,s1
    80005454:	4581                	li	a1,0
    80005456:	8556                	mv	a0,s5
    80005458:	fffff097          	auipc	ra,0xfffff
    8000545c:	ca4080e7          	jalr	-860(ra) # 800040fc <readi>
    80005460:	2501                	sext.w	a0,a0
    80005462:	1aa91863          	bne	s2,a0,80005612 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80005466:	009d84bb          	addw	s1,s11,s1
    8000546a:	013d09bb          	addw	s3,s10,s3
    8000546e:	1f74f263          	bgeu	s1,s7,80005652 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80005472:	02049593          	slli	a1,s1,0x20
    80005476:	9181                	srli	a1,a1,0x20
    80005478:	95e2                	add	a1,a1,s8
    8000547a:	855a                	mv	a0,s6
    8000547c:	ffffc097          	auipc	ra,0xffffc
    80005480:	bd6080e7          	jalr	-1066(ra) # 80001052 <walkaddr>
    80005484:	862a                	mv	a2,a0
    if(pa == 0)
    80005486:	dd45                	beqz	a0,8000543e <exec+0xfe>
      n = PGSIZE;
    80005488:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000548a:	fd49f2e3          	bgeu	s3,s4,8000544e <exec+0x10e>
      n = sz - i;
    8000548e:	894e                	mv	s2,s3
    80005490:	bf7d                	j	8000544e <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005492:	4481                	li	s1,0
  iunlockput(ip);
    80005494:	8556                	mv	a0,s5
    80005496:	fffff097          	auipc	ra,0xfffff
    8000549a:	c14080e7          	jalr	-1004(ra) # 800040aa <iunlockput>
  end_op();
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	404080e7          	jalr	1028(ra) # 800048a2 <end_op>
  p = myproc();
    800054a6:	ffffc097          	auipc	ra,0xffffc
    800054aa:	7aa080e7          	jalr	1962(ra) # 80001c50 <myproc>
    800054ae:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800054b0:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    800054b4:	6785                	lui	a5,0x1
    800054b6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800054b8:	97a6                	add	a5,a5,s1
    800054ba:	777d                	lui	a4,0xfffff
    800054bc:	8ff9                	and	a5,a5,a4
    800054be:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800054c2:	6609                	lui	a2,0x2
    800054c4:	963e                	add	a2,a2,a5
    800054c6:	85be                	mv	a1,a5
    800054c8:	855a                	mv	a0,s6
    800054ca:	ffffc097          	auipc	ra,0xffffc
    800054ce:	f3c080e7          	jalr	-196(ra) # 80001406 <uvmalloc>
    800054d2:	8c2a                	mv	s8,a0
  ip = 0;
    800054d4:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800054d6:	12050e63          	beqz	a0,80005612 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    800054da:	75f9                	lui	a1,0xffffe
    800054dc:	95aa                	add	a1,a1,a0
    800054de:	855a                	mv	a0,s6
    800054e0:	ffffc097          	auipc	ra,0xffffc
    800054e4:	148080e7          	jalr	328(ra) # 80001628 <uvmclear>
  stackbase = sp - PGSIZE;
    800054e8:	7afd                	lui	s5,0xfffff
    800054ea:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800054ec:	df043783          	ld	a5,-528(s0)
    800054f0:	6388                	ld	a0,0(a5)
    800054f2:	c925                	beqz	a0,80005562 <exec+0x222>
    800054f4:	e9040993          	addi	s3,s0,-368
    800054f8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800054fc:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800054fe:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005500:	ffffc097          	auipc	ra,0xffffc
    80005504:	948080e7          	jalr	-1720(ra) # 80000e48 <strlen>
    80005508:	0015079b          	addiw	a5,a0,1
    8000550c:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005510:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005514:	13596363          	bltu	s2,s5,8000563a <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005518:	df043d83          	ld	s11,-528(s0)
    8000551c:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005520:	8552                	mv	a0,s4
    80005522:	ffffc097          	auipc	ra,0xffffc
    80005526:	926080e7          	jalr	-1754(ra) # 80000e48 <strlen>
    8000552a:	0015069b          	addiw	a3,a0,1
    8000552e:	8652                	mv	a2,s4
    80005530:	85ca                	mv	a1,s2
    80005532:	855a                	mv	a0,s6
    80005534:	ffffc097          	auipc	ra,0xffffc
    80005538:	126080e7          	jalr	294(ra) # 8000165a <copyout>
    8000553c:	10054363          	bltz	a0,80005642 <exec+0x302>
    ustack[argc] = sp;
    80005540:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005544:	0485                	addi	s1,s1,1
    80005546:	008d8793          	addi	a5,s11,8
    8000554a:	def43823          	sd	a5,-528(s0)
    8000554e:	008db503          	ld	a0,8(s11)
    80005552:	c911                	beqz	a0,80005566 <exec+0x226>
    if(argc >= MAXARG)
    80005554:	09a1                	addi	s3,s3,8
    80005556:	fb3c95e3          	bne	s9,s3,80005500 <exec+0x1c0>
  sz = sz1;
    8000555a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000555e:	4a81                	li	s5,0
    80005560:	a84d                	j	80005612 <exec+0x2d2>
  sp = sz;
    80005562:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005564:	4481                	li	s1,0
  ustack[argc] = 0;
    80005566:	00349793          	slli	a5,s1,0x3
    8000556a:	f9078793          	addi	a5,a5,-112
    8000556e:	97a2                	add	a5,a5,s0
    80005570:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005574:	00148693          	addi	a3,s1,1
    80005578:	068e                	slli	a3,a3,0x3
    8000557a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000557e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005582:	01597663          	bgeu	s2,s5,8000558e <exec+0x24e>
  sz = sz1;
    80005586:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000558a:	4a81                	li	s5,0
    8000558c:	a059                	j	80005612 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000558e:	e9040613          	addi	a2,s0,-368
    80005592:	85ca                	mv	a1,s2
    80005594:	855a                	mv	a0,s6
    80005596:	ffffc097          	auipc	ra,0xffffc
    8000559a:	0c4080e7          	jalr	196(ra) # 8000165a <copyout>
    8000559e:	0a054663          	bltz	a0,8000564a <exec+0x30a>
  p->trapframe->a1 = sp;
    800055a2:	078bb783          	ld	a5,120(s7)
    800055a6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800055aa:	de843783          	ld	a5,-536(s0)
    800055ae:	0007c703          	lbu	a4,0(a5)
    800055b2:	cf11                	beqz	a4,800055ce <exec+0x28e>
    800055b4:	0785                	addi	a5,a5,1
    if(*s == '/')
    800055b6:	02f00693          	li	a3,47
    800055ba:	a039                	j	800055c8 <exec+0x288>
      last = s+1;
    800055bc:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800055c0:	0785                	addi	a5,a5,1
    800055c2:	fff7c703          	lbu	a4,-1(a5)
    800055c6:	c701                	beqz	a4,800055ce <exec+0x28e>
    if(*s == '/')
    800055c8:	fed71ce3          	bne	a4,a3,800055c0 <exec+0x280>
    800055cc:	bfc5                	j	800055bc <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    800055ce:	4641                	li	a2,16
    800055d0:	de843583          	ld	a1,-536(s0)
    800055d4:	178b8513          	addi	a0,s7,376
    800055d8:	ffffc097          	auipc	ra,0xffffc
    800055dc:	83e080e7          	jalr	-1986(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    800055e0:	070bb503          	ld	a0,112(s7)
  p->pagetable = pagetable;
    800055e4:	076bb823          	sd	s6,112(s7)
  p->sz = sz;
    800055e8:	078bb423          	sd	s8,104(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800055ec:	078bb783          	ld	a5,120(s7)
    800055f0:	e6843703          	ld	a4,-408(s0)
    800055f4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800055f6:	078bb783          	ld	a5,120(s7)
    800055fa:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800055fe:	85ea                	mv	a1,s10
    80005600:	ffffc097          	auipc	ra,0xffffc
    80005604:	7b0080e7          	jalr	1968(ra) # 80001db0 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005608:	0004851b          	sext.w	a0,s1
    8000560c:	bbc1                	j	800053dc <exec+0x9c>
    8000560e:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005612:	df843583          	ld	a1,-520(s0)
    80005616:	855a                	mv	a0,s6
    80005618:	ffffc097          	auipc	ra,0xffffc
    8000561c:	798080e7          	jalr	1944(ra) # 80001db0 <proc_freepagetable>
  if(ip){
    80005620:	da0a94e3          	bnez	s5,800053c8 <exec+0x88>
  return -1;
    80005624:	557d                	li	a0,-1
    80005626:	bb5d                	j	800053dc <exec+0x9c>
    80005628:	de943c23          	sd	s1,-520(s0)
    8000562c:	b7dd                	j	80005612 <exec+0x2d2>
    8000562e:	de943c23          	sd	s1,-520(s0)
    80005632:	b7c5                	j	80005612 <exec+0x2d2>
    80005634:	de943c23          	sd	s1,-520(s0)
    80005638:	bfe9                	j	80005612 <exec+0x2d2>
  sz = sz1;
    8000563a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000563e:	4a81                	li	s5,0
    80005640:	bfc9                	j	80005612 <exec+0x2d2>
  sz = sz1;
    80005642:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005646:	4a81                	li	s5,0
    80005648:	b7e9                	j	80005612 <exec+0x2d2>
  sz = sz1;
    8000564a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000564e:	4a81                	li	s5,0
    80005650:	b7c9                	j	80005612 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005652:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005656:	e0843783          	ld	a5,-504(s0)
    8000565a:	0017869b          	addiw	a3,a5,1
    8000565e:	e0d43423          	sd	a3,-504(s0)
    80005662:	e0043783          	ld	a5,-512(s0)
    80005666:	0387879b          	addiw	a5,a5,56
    8000566a:	e8845703          	lhu	a4,-376(s0)
    8000566e:	e2e6d3e3          	bge	a3,a4,80005494 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005672:	2781                	sext.w	a5,a5
    80005674:	e0f43023          	sd	a5,-512(s0)
    80005678:	03800713          	li	a4,56
    8000567c:	86be                	mv	a3,a5
    8000567e:	e1840613          	addi	a2,s0,-488
    80005682:	4581                	li	a1,0
    80005684:	8556                	mv	a0,s5
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	a76080e7          	jalr	-1418(ra) # 800040fc <readi>
    8000568e:	03800793          	li	a5,56
    80005692:	f6f51ee3          	bne	a0,a5,8000560e <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005696:	e1842783          	lw	a5,-488(s0)
    8000569a:	4705                	li	a4,1
    8000569c:	fae79de3          	bne	a5,a4,80005656 <exec+0x316>
    if(ph.memsz < ph.filesz)
    800056a0:	e4043603          	ld	a2,-448(s0)
    800056a4:	e3843783          	ld	a5,-456(s0)
    800056a8:	f8f660e3          	bltu	a2,a5,80005628 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800056ac:	e2843783          	ld	a5,-472(s0)
    800056b0:	963e                	add	a2,a2,a5
    800056b2:	f6f66ee3          	bltu	a2,a5,8000562e <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800056b6:	85a6                	mv	a1,s1
    800056b8:	855a                	mv	a0,s6
    800056ba:	ffffc097          	auipc	ra,0xffffc
    800056be:	d4c080e7          	jalr	-692(ra) # 80001406 <uvmalloc>
    800056c2:	dea43c23          	sd	a0,-520(s0)
    800056c6:	d53d                	beqz	a0,80005634 <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    800056c8:	e2843c03          	ld	s8,-472(s0)
    800056cc:	de043783          	ld	a5,-544(s0)
    800056d0:	00fc77b3          	and	a5,s8,a5
    800056d4:	ff9d                	bnez	a5,80005612 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800056d6:	e2042c83          	lw	s9,-480(s0)
    800056da:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800056de:	f60b8ae3          	beqz	s7,80005652 <exec+0x312>
    800056e2:	89de                	mv	s3,s7
    800056e4:	4481                	li	s1,0
    800056e6:	b371                	j	80005472 <exec+0x132>

00000000800056e8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800056e8:	7179                	addi	sp,sp,-48
    800056ea:	f406                	sd	ra,40(sp)
    800056ec:	f022                	sd	s0,32(sp)
    800056ee:	ec26                	sd	s1,24(sp)
    800056f0:	e84a                	sd	s2,16(sp)
    800056f2:	1800                	addi	s0,sp,48
    800056f4:	892e                	mv	s2,a1
    800056f6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800056f8:	fdc40593          	addi	a1,s0,-36
    800056fc:	ffffe097          	auipc	ra,0xffffe
    80005700:	b5c080e7          	jalr	-1188(ra) # 80003258 <argint>
    80005704:	04054063          	bltz	a0,80005744 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005708:	fdc42703          	lw	a4,-36(s0)
    8000570c:	47bd                	li	a5,15
    8000570e:	02e7ed63          	bltu	a5,a4,80005748 <argfd+0x60>
    80005712:	ffffc097          	auipc	ra,0xffffc
    80005716:	53e080e7          	jalr	1342(ra) # 80001c50 <myproc>
    8000571a:	fdc42703          	lw	a4,-36(s0)
    8000571e:	01e70793          	addi	a5,a4,30 # fffffffffffff01e <end+0xffffffff7ffd901e>
    80005722:	078e                	slli	a5,a5,0x3
    80005724:	953e                	add	a0,a0,a5
    80005726:	611c                	ld	a5,0(a0)
    80005728:	c395                	beqz	a5,8000574c <argfd+0x64>
    return -1;
  if(pfd)
    8000572a:	00090463          	beqz	s2,80005732 <argfd+0x4a>
    *pfd = fd;
    8000572e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005732:	4501                	li	a0,0
  if(pf)
    80005734:	c091                	beqz	s1,80005738 <argfd+0x50>
    *pf = f;
    80005736:	e09c                	sd	a5,0(s1)
}
    80005738:	70a2                	ld	ra,40(sp)
    8000573a:	7402                	ld	s0,32(sp)
    8000573c:	64e2                	ld	s1,24(sp)
    8000573e:	6942                	ld	s2,16(sp)
    80005740:	6145                	addi	sp,sp,48
    80005742:	8082                	ret
    return -1;
    80005744:	557d                	li	a0,-1
    80005746:	bfcd                	j	80005738 <argfd+0x50>
    return -1;
    80005748:	557d                	li	a0,-1
    8000574a:	b7fd                	j	80005738 <argfd+0x50>
    8000574c:	557d                	li	a0,-1
    8000574e:	b7ed                	j	80005738 <argfd+0x50>

0000000080005750 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005750:	1101                	addi	sp,sp,-32
    80005752:	ec06                	sd	ra,24(sp)
    80005754:	e822                	sd	s0,16(sp)
    80005756:	e426                	sd	s1,8(sp)
    80005758:	1000                	addi	s0,sp,32
    8000575a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000575c:	ffffc097          	auipc	ra,0xffffc
    80005760:	4f4080e7          	jalr	1268(ra) # 80001c50 <myproc>
    80005764:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005766:	0f050793          	addi	a5,a0,240
    8000576a:	4501                	li	a0,0
    8000576c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000576e:	6398                	ld	a4,0(a5)
    80005770:	cb19                	beqz	a4,80005786 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005772:	2505                	addiw	a0,a0,1
    80005774:	07a1                	addi	a5,a5,8
    80005776:	fed51ce3          	bne	a0,a3,8000576e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000577a:	557d                	li	a0,-1
}
    8000577c:	60e2                	ld	ra,24(sp)
    8000577e:	6442                	ld	s0,16(sp)
    80005780:	64a2                	ld	s1,8(sp)
    80005782:	6105                	addi	sp,sp,32
    80005784:	8082                	ret
      p->ofile[fd] = f;
    80005786:	01e50793          	addi	a5,a0,30
    8000578a:	078e                	slli	a5,a5,0x3
    8000578c:	963e                	add	a2,a2,a5
    8000578e:	e204                	sd	s1,0(a2)
      return fd;
    80005790:	b7f5                	j	8000577c <fdalloc+0x2c>

0000000080005792 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005792:	715d                	addi	sp,sp,-80
    80005794:	e486                	sd	ra,72(sp)
    80005796:	e0a2                	sd	s0,64(sp)
    80005798:	fc26                	sd	s1,56(sp)
    8000579a:	f84a                	sd	s2,48(sp)
    8000579c:	f44e                	sd	s3,40(sp)
    8000579e:	f052                	sd	s4,32(sp)
    800057a0:	ec56                	sd	s5,24(sp)
    800057a2:	0880                	addi	s0,sp,80
    800057a4:	89ae                	mv	s3,a1
    800057a6:	8ab2                	mv	s5,a2
    800057a8:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800057aa:	fb040593          	addi	a1,s0,-80
    800057ae:	fffff097          	auipc	ra,0xfffff
    800057b2:	e74080e7          	jalr	-396(ra) # 80004622 <nameiparent>
    800057b6:	892a                	mv	s2,a0
    800057b8:	12050e63          	beqz	a0,800058f4 <create+0x162>
    return 0;

  ilock(dp);
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	68c080e7          	jalr	1676(ra) # 80003e48 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800057c4:	4601                	li	a2,0
    800057c6:	fb040593          	addi	a1,s0,-80
    800057ca:	854a                	mv	a0,s2
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	b60080e7          	jalr	-1184(ra) # 8000432c <dirlookup>
    800057d4:	84aa                	mv	s1,a0
    800057d6:	c921                	beqz	a0,80005826 <create+0x94>
    iunlockput(dp);
    800057d8:	854a                	mv	a0,s2
    800057da:	fffff097          	auipc	ra,0xfffff
    800057de:	8d0080e7          	jalr	-1840(ra) # 800040aa <iunlockput>
    ilock(ip);
    800057e2:	8526                	mv	a0,s1
    800057e4:	ffffe097          	auipc	ra,0xffffe
    800057e8:	664080e7          	jalr	1636(ra) # 80003e48 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800057ec:	2981                	sext.w	s3,s3
    800057ee:	4789                	li	a5,2
    800057f0:	02f99463          	bne	s3,a5,80005818 <create+0x86>
    800057f4:	0444d783          	lhu	a5,68(s1)
    800057f8:	37f9                	addiw	a5,a5,-2
    800057fa:	17c2                	slli	a5,a5,0x30
    800057fc:	93c1                	srli	a5,a5,0x30
    800057fe:	4705                	li	a4,1
    80005800:	00f76c63          	bltu	a4,a5,80005818 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005804:	8526                	mv	a0,s1
    80005806:	60a6                	ld	ra,72(sp)
    80005808:	6406                	ld	s0,64(sp)
    8000580a:	74e2                	ld	s1,56(sp)
    8000580c:	7942                	ld	s2,48(sp)
    8000580e:	79a2                	ld	s3,40(sp)
    80005810:	7a02                	ld	s4,32(sp)
    80005812:	6ae2                	ld	s5,24(sp)
    80005814:	6161                	addi	sp,sp,80
    80005816:	8082                	ret
    iunlockput(ip);
    80005818:	8526                	mv	a0,s1
    8000581a:	fffff097          	auipc	ra,0xfffff
    8000581e:	890080e7          	jalr	-1904(ra) # 800040aa <iunlockput>
    return 0;
    80005822:	4481                	li	s1,0
    80005824:	b7c5                	j	80005804 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005826:	85ce                	mv	a1,s3
    80005828:	00092503          	lw	a0,0(s2)
    8000582c:	ffffe097          	auipc	ra,0xffffe
    80005830:	482080e7          	jalr	1154(ra) # 80003cae <ialloc>
    80005834:	84aa                	mv	s1,a0
    80005836:	c521                	beqz	a0,8000587e <create+0xec>
  ilock(ip);
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	610080e7          	jalr	1552(ra) # 80003e48 <ilock>
  ip->major = major;
    80005840:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005844:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005848:	4a05                	li	s4,1
    8000584a:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000584e:	8526                	mv	a0,s1
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	52c080e7          	jalr	1324(ra) # 80003d7c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005858:	2981                	sext.w	s3,s3
    8000585a:	03498a63          	beq	s3,s4,8000588e <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000585e:	40d0                	lw	a2,4(s1)
    80005860:	fb040593          	addi	a1,s0,-80
    80005864:	854a                	mv	a0,s2
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	cdc080e7          	jalr	-804(ra) # 80004542 <dirlink>
    8000586e:	06054b63          	bltz	a0,800058e4 <create+0x152>
  iunlockput(dp);
    80005872:	854a                	mv	a0,s2
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	836080e7          	jalr	-1994(ra) # 800040aa <iunlockput>
  return ip;
    8000587c:	b761                	j	80005804 <create+0x72>
    panic("create: ialloc");
    8000587e:	00003517          	auipc	a0,0x3
    80005882:	eea50513          	addi	a0,a0,-278 # 80008768 <syscalls+0x2b0>
    80005886:	ffffb097          	auipc	ra,0xffffb
    8000588a:	cb4080e7          	jalr	-844(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    8000588e:	04a95783          	lhu	a5,74(s2)
    80005892:	2785                	addiw	a5,a5,1
    80005894:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005898:	854a                	mv	a0,s2
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	4e2080e7          	jalr	1250(ra) # 80003d7c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800058a2:	40d0                	lw	a2,4(s1)
    800058a4:	00003597          	auipc	a1,0x3
    800058a8:	ed458593          	addi	a1,a1,-300 # 80008778 <syscalls+0x2c0>
    800058ac:	8526                	mv	a0,s1
    800058ae:	fffff097          	auipc	ra,0xfffff
    800058b2:	c94080e7          	jalr	-876(ra) # 80004542 <dirlink>
    800058b6:	00054f63          	bltz	a0,800058d4 <create+0x142>
    800058ba:	00492603          	lw	a2,4(s2)
    800058be:	00003597          	auipc	a1,0x3
    800058c2:	ec258593          	addi	a1,a1,-318 # 80008780 <syscalls+0x2c8>
    800058c6:	8526                	mv	a0,s1
    800058c8:	fffff097          	auipc	ra,0xfffff
    800058cc:	c7a080e7          	jalr	-902(ra) # 80004542 <dirlink>
    800058d0:	f80557e3          	bgez	a0,8000585e <create+0xcc>
      panic("create dots");
    800058d4:	00003517          	auipc	a0,0x3
    800058d8:	eb450513          	addi	a0,a0,-332 # 80008788 <syscalls+0x2d0>
    800058dc:	ffffb097          	auipc	ra,0xffffb
    800058e0:	c5e080e7          	jalr	-930(ra) # 8000053a <panic>
    panic("create: dirlink");
    800058e4:	00003517          	auipc	a0,0x3
    800058e8:	eb450513          	addi	a0,a0,-332 # 80008798 <syscalls+0x2e0>
    800058ec:	ffffb097          	auipc	ra,0xffffb
    800058f0:	c4e080e7          	jalr	-946(ra) # 8000053a <panic>
    return 0;
    800058f4:	84aa                	mv	s1,a0
    800058f6:	b739                	j	80005804 <create+0x72>

00000000800058f8 <sys_dup>:
{
    800058f8:	7179                	addi	sp,sp,-48
    800058fa:	f406                	sd	ra,40(sp)
    800058fc:	f022                	sd	s0,32(sp)
    800058fe:	ec26                	sd	s1,24(sp)
    80005900:	e84a                	sd	s2,16(sp)
    80005902:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005904:	fd840613          	addi	a2,s0,-40
    80005908:	4581                	li	a1,0
    8000590a:	4501                	li	a0,0
    8000590c:	00000097          	auipc	ra,0x0
    80005910:	ddc080e7          	jalr	-548(ra) # 800056e8 <argfd>
    return -1;
    80005914:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005916:	02054363          	bltz	a0,8000593c <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000591a:	fd843903          	ld	s2,-40(s0)
    8000591e:	854a                	mv	a0,s2
    80005920:	00000097          	auipc	ra,0x0
    80005924:	e30080e7          	jalr	-464(ra) # 80005750 <fdalloc>
    80005928:	84aa                	mv	s1,a0
    return -1;
    8000592a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000592c:	00054863          	bltz	a0,8000593c <sys_dup+0x44>
  filedup(f);
    80005930:	854a                	mv	a0,s2
    80005932:	fffff097          	auipc	ra,0xfffff
    80005936:	368080e7          	jalr	872(ra) # 80004c9a <filedup>
  return fd;
    8000593a:	87a6                	mv	a5,s1
}
    8000593c:	853e                	mv	a0,a5
    8000593e:	70a2                	ld	ra,40(sp)
    80005940:	7402                	ld	s0,32(sp)
    80005942:	64e2                	ld	s1,24(sp)
    80005944:	6942                	ld	s2,16(sp)
    80005946:	6145                	addi	sp,sp,48
    80005948:	8082                	ret

000000008000594a <sys_read>:
{
    8000594a:	7179                	addi	sp,sp,-48
    8000594c:	f406                	sd	ra,40(sp)
    8000594e:	f022                	sd	s0,32(sp)
    80005950:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005952:	fe840613          	addi	a2,s0,-24
    80005956:	4581                	li	a1,0
    80005958:	4501                	li	a0,0
    8000595a:	00000097          	auipc	ra,0x0
    8000595e:	d8e080e7          	jalr	-626(ra) # 800056e8 <argfd>
    return -1;
    80005962:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005964:	04054163          	bltz	a0,800059a6 <sys_read+0x5c>
    80005968:	fe440593          	addi	a1,s0,-28
    8000596c:	4509                	li	a0,2
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	8ea080e7          	jalr	-1814(ra) # 80003258 <argint>
    return -1;
    80005976:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005978:	02054763          	bltz	a0,800059a6 <sys_read+0x5c>
    8000597c:	fd840593          	addi	a1,s0,-40
    80005980:	4505                	li	a0,1
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	8f8080e7          	jalr	-1800(ra) # 8000327a <argaddr>
    return -1;
    8000598a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000598c:	00054d63          	bltz	a0,800059a6 <sys_read+0x5c>
  return fileread(f, p, n);
    80005990:	fe442603          	lw	a2,-28(s0)
    80005994:	fd843583          	ld	a1,-40(s0)
    80005998:	fe843503          	ld	a0,-24(s0)
    8000599c:	fffff097          	auipc	ra,0xfffff
    800059a0:	48a080e7          	jalr	1162(ra) # 80004e26 <fileread>
    800059a4:	87aa                	mv	a5,a0
}
    800059a6:	853e                	mv	a0,a5
    800059a8:	70a2                	ld	ra,40(sp)
    800059aa:	7402                	ld	s0,32(sp)
    800059ac:	6145                	addi	sp,sp,48
    800059ae:	8082                	ret

00000000800059b0 <sys_write>:
{
    800059b0:	7179                	addi	sp,sp,-48
    800059b2:	f406                	sd	ra,40(sp)
    800059b4:	f022                	sd	s0,32(sp)
    800059b6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059b8:	fe840613          	addi	a2,s0,-24
    800059bc:	4581                	li	a1,0
    800059be:	4501                	li	a0,0
    800059c0:	00000097          	auipc	ra,0x0
    800059c4:	d28080e7          	jalr	-728(ra) # 800056e8 <argfd>
    return -1;
    800059c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059ca:	04054163          	bltz	a0,80005a0c <sys_write+0x5c>
    800059ce:	fe440593          	addi	a1,s0,-28
    800059d2:	4509                	li	a0,2
    800059d4:	ffffe097          	auipc	ra,0xffffe
    800059d8:	884080e7          	jalr	-1916(ra) # 80003258 <argint>
    return -1;
    800059dc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059de:	02054763          	bltz	a0,80005a0c <sys_write+0x5c>
    800059e2:	fd840593          	addi	a1,s0,-40
    800059e6:	4505                	li	a0,1
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	892080e7          	jalr	-1902(ra) # 8000327a <argaddr>
    return -1;
    800059f0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059f2:	00054d63          	bltz	a0,80005a0c <sys_write+0x5c>
  return filewrite(f, p, n);
    800059f6:	fe442603          	lw	a2,-28(s0)
    800059fa:	fd843583          	ld	a1,-40(s0)
    800059fe:	fe843503          	ld	a0,-24(s0)
    80005a02:	fffff097          	auipc	ra,0xfffff
    80005a06:	4e6080e7          	jalr	1254(ra) # 80004ee8 <filewrite>
    80005a0a:	87aa                	mv	a5,a0
}
    80005a0c:	853e                	mv	a0,a5
    80005a0e:	70a2                	ld	ra,40(sp)
    80005a10:	7402                	ld	s0,32(sp)
    80005a12:	6145                	addi	sp,sp,48
    80005a14:	8082                	ret

0000000080005a16 <sys_close>:
{
    80005a16:	1101                	addi	sp,sp,-32
    80005a18:	ec06                	sd	ra,24(sp)
    80005a1a:	e822                	sd	s0,16(sp)
    80005a1c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005a1e:	fe040613          	addi	a2,s0,-32
    80005a22:	fec40593          	addi	a1,s0,-20
    80005a26:	4501                	li	a0,0
    80005a28:	00000097          	auipc	ra,0x0
    80005a2c:	cc0080e7          	jalr	-832(ra) # 800056e8 <argfd>
    return -1;
    80005a30:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005a32:	02054463          	bltz	a0,80005a5a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005a36:	ffffc097          	auipc	ra,0xffffc
    80005a3a:	21a080e7          	jalr	538(ra) # 80001c50 <myproc>
    80005a3e:	fec42783          	lw	a5,-20(s0)
    80005a42:	07f9                	addi	a5,a5,30
    80005a44:	078e                	slli	a5,a5,0x3
    80005a46:	953e                	add	a0,a0,a5
    80005a48:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005a4c:	fe043503          	ld	a0,-32(s0)
    80005a50:	fffff097          	auipc	ra,0xfffff
    80005a54:	29c080e7          	jalr	668(ra) # 80004cec <fileclose>
  return 0;
    80005a58:	4781                	li	a5,0
}
    80005a5a:	853e                	mv	a0,a5
    80005a5c:	60e2                	ld	ra,24(sp)
    80005a5e:	6442                	ld	s0,16(sp)
    80005a60:	6105                	addi	sp,sp,32
    80005a62:	8082                	ret

0000000080005a64 <sys_fstat>:
{
    80005a64:	1101                	addi	sp,sp,-32
    80005a66:	ec06                	sd	ra,24(sp)
    80005a68:	e822                	sd	s0,16(sp)
    80005a6a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a6c:	fe840613          	addi	a2,s0,-24
    80005a70:	4581                	li	a1,0
    80005a72:	4501                	li	a0,0
    80005a74:	00000097          	auipc	ra,0x0
    80005a78:	c74080e7          	jalr	-908(ra) # 800056e8 <argfd>
    return -1;
    80005a7c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a7e:	02054563          	bltz	a0,80005aa8 <sys_fstat+0x44>
    80005a82:	fe040593          	addi	a1,s0,-32
    80005a86:	4505                	li	a0,1
    80005a88:	ffffd097          	auipc	ra,0xffffd
    80005a8c:	7f2080e7          	jalr	2034(ra) # 8000327a <argaddr>
    return -1;
    80005a90:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a92:	00054b63          	bltz	a0,80005aa8 <sys_fstat+0x44>
  return filestat(f, st);
    80005a96:	fe043583          	ld	a1,-32(s0)
    80005a9a:	fe843503          	ld	a0,-24(s0)
    80005a9e:	fffff097          	auipc	ra,0xfffff
    80005aa2:	316080e7          	jalr	790(ra) # 80004db4 <filestat>
    80005aa6:	87aa                	mv	a5,a0
}
    80005aa8:	853e                	mv	a0,a5
    80005aaa:	60e2                	ld	ra,24(sp)
    80005aac:	6442                	ld	s0,16(sp)
    80005aae:	6105                	addi	sp,sp,32
    80005ab0:	8082                	ret

0000000080005ab2 <sys_link>:
{
    80005ab2:	7169                	addi	sp,sp,-304
    80005ab4:	f606                	sd	ra,296(sp)
    80005ab6:	f222                	sd	s0,288(sp)
    80005ab8:	ee26                	sd	s1,280(sp)
    80005aba:	ea4a                	sd	s2,272(sp)
    80005abc:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005abe:	08000613          	li	a2,128
    80005ac2:	ed040593          	addi	a1,s0,-304
    80005ac6:	4501                	li	a0,0
    80005ac8:	ffffd097          	auipc	ra,0xffffd
    80005acc:	7d4080e7          	jalr	2004(ra) # 8000329c <argstr>
    return -1;
    80005ad0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ad2:	10054e63          	bltz	a0,80005bee <sys_link+0x13c>
    80005ad6:	08000613          	li	a2,128
    80005ada:	f5040593          	addi	a1,s0,-176
    80005ade:	4505                	li	a0,1
    80005ae0:	ffffd097          	auipc	ra,0xffffd
    80005ae4:	7bc080e7          	jalr	1980(ra) # 8000329c <argstr>
    return -1;
    80005ae8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005aea:	10054263          	bltz	a0,80005bee <sys_link+0x13c>
  begin_op();
    80005aee:	fffff097          	auipc	ra,0xfffff
    80005af2:	d36080e7          	jalr	-714(ra) # 80004824 <begin_op>
  if((ip = namei(old)) == 0){
    80005af6:	ed040513          	addi	a0,s0,-304
    80005afa:	fffff097          	auipc	ra,0xfffff
    80005afe:	b0a080e7          	jalr	-1270(ra) # 80004604 <namei>
    80005b02:	84aa                	mv	s1,a0
    80005b04:	c551                	beqz	a0,80005b90 <sys_link+0xde>
  ilock(ip);
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	342080e7          	jalr	834(ra) # 80003e48 <ilock>
  if(ip->type == T_DIR){
    80005b0e:	04449703          	lh	a4,68(s1)
    80005b12:	4785                	li	a5,1
    80005b14:	08f70463          	beq	a4,a5,80005b9c <sys_link+0xea>
  ip->nlink++;
    80005b18:	04a4d783          	lhu	a5,74(s1)
    80005b1c:	2785                	addiw	a5,a5,1
    80005b1e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b22:	8526                	mv	a0,s1
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	258080e7          	jalr	600(ra) # 80003d7c <iupdate>
  iunlock(ip);
    80005b2c:	8526                	mv	a0,s1
    80005b2e:	ffffe097          	auipc	ra,0xffffe
    80005b32:	3dc080e7          	jalr	988(ra) # 80003f0a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005b36:	fd040593          	addi	a1,s0,-48
    80005b3a:	f5040513          	addi	a0,s0,-176
    80005b3e:	fffff097          	auipc	ra,0xfffff
    80005b42:	ae4080e7          	jalr	-1308(ra) # 80004622 <nameiparent>
    80005b46:	892a                	mv	s2,a0
    80005b48:	c935                	beqz	a0,80005bbc <sys_link+0x10a>
  ilock(dp);
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	2fe080e7          	jalr	766(ra) # 80003e48 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005b52:	00092703          	lw	a4,0(s2)
    80005b56:	409c                	lw	a5,0(s1)
    80005b58:	04f71d63          	bne	a4,a5,80005bb2 <sys_link+0x100>
    80005b5c:	40d0                	lw	a2,4(s1)
    80005b5e:	fd040593          	addi	a1,s0,-48
    80005b62:	854a                	mv	a0,s2
    80005b64:	fffff097          	auipc	ra,0xfffff
    80005b68:	9de080e7          	jalr	-1570(ra) # 80004542 <dirlink>
    80005b6c:	04054363          	bltz	a0,80005bb2 <sys_link+0x100>
  iunlockput(dp);
    80005b70:	854a                	mv	a0,s2
    80005b72:	ffffe097          	auipc	ra,0xffffe
    80005b76:	538080e7          	jalr	1336(ra) # 800040aa <iunlockput>
  iput(ip);
    80005b7a:	8526                	mv	a0,s1
    80005b7c:	ffffe097          	auipc	ra,0xffffe
    80005b80:	486080e7          	jalr	1158(ra) # 80004002 <iput>
  end_op();
    80005b84:	fffff097          	auipc	ra,0xfffff
    80005b88:	d1e080e7          	jalr	-738(ra) # 800048a2 <end_op>
  return 0;
    80005b8c:	4781                	li	a5,0
    80005b8e:	a085                	j	80005bee <sys_link+0x13c>
    end_op();
    80005b90:	fffff097          	auipc	ra,0xfffff
    80005b94:	d12080e7          	jalr	-750(ra) # 800048a2 <end_op>
    return -1;
    80005b98:	57fd                	li	a5,-1
    80005b9a:	a891                	j	80005bee <sys_link+0x13c>
    iunlockput(ip);
    80005b9c:	8526                	mv	a0,s1
    80005b9e:	ffffe097          	auipc	ra,0xffffe
    80005ba2:	50c080e7          	jalr	1292(ra) # 800040aa <iunlockput>
    end_op();
    80005ba6:	fffff097          	auipc	ra,0xfffff
    80005baa:	cfc080e7          	jalr	-772(ra) # 800048a2 <end_op>
    return -1;
    80005bae:	57fd                	li	a5,-1
    80005bb0:	a83d                	j	80005bee <sys_link+0x13c>
    iunlockput(dp);
    80005bb2:	854a                	mv	a0,s2
    80005bb4:	ffffe097          	auipc	ra,0xffffe
    80005bb8:	4f6080e7          	jalr	1270(ra) # 800040aa <iunlockput>
  ilock(ip);
    80005bbc:	8526                	mv	a0,s1
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	28a080e7          	jalr	650(ra) # 80003e48 <ilock>
  ip->nlink--;
    80005bc6:	04a4d783          	lhu	a5,74(s1)
    80005bca:	37fd                	addiw	a5,a5,-1
    80005bcc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005bd0:	8526                	mv	a0,s1
    80005bd2:	ffffe097          	auipc	ra,0xffffe
    80005bd6:	1aa080e7          	jalr	426(ra) # 80003d7c <iupdate>
  iunlockput(ip);
    80005bda:	8526                	mv	a0,s1
    80005bdc:	ffffe097          	auipc	ra,0xffffe
    80005be0:	4ce080e7          	jalr	1230(ra) # 800040aa <iunlockput>
  end_op();
    80005be4:	fffff097          	auipc	ra,0xfffff
    80005be8:	cbe080e7          	jalr	-834(ra) # 800048a2 <end_op>
  return -1;
    80005bec:	57fd                	li	a5,-1
}
    80005bee:	853e                	mv	a0,a5
    80005bf0:	70b2                	ld	ra,296(sp)
    80005bf2:	7412                	ld	s0,288(sp)
    80005bf4:	64f2                	ld	s1,280(sp)
    80005bf6:	6952                	ld	s2,272(sp)
    80005bf8:	6155                	addi	sp,sp,304
    80005bfa:	8082                	ret

0000000080005bfc <sys_unlink>:
{
    80005bfc:	7151                	addi	sp,sp,-240
    80005bfe:	f586                	sd	ra,232(sp)
    80005c00:	f1a2                	sd	s0,224(sp)
    80005c02:	eda6                	sd	s1,216(sp)
    80005c04:	e9ca                	sd	s2,208(sp)
    80005c06:	e5ce                	sd	s3,200(sp)
    80005c08:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005c0a:	08000613          	li	a2,128
    80005c0e:	f3040593          	addi	a1,s0,-208
    80005c12:	4501                	li	a0,0
    80005c14:	ffffd097          	auipc	ra,0xffffd
    80005c18:	688080e7          	jalr	1672(ra) # 8000329c <argstr>
    80005c1c:	18054163          	bltz	a0,80005d9e <sys_unlink+0x1a2>
  begin_op();
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	c04080e7          	jalr	-1020(ra) # 80004824 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005c28:	fb040593          	addi	a1,s0,-80
    80005c2c:	f3040513          	addi	a0,s0,-208
    80005c30:	fffff097          	auipc	ra,0xfffff
    80005c34:	9f2080e7          	jalr	-1550(ra) # 80004622 <nameiparent>
    80005c38:	84aa                	mv	s1,a0
    80005c3a:	c979                	beqz	a0,80005d10 <sys_unlink+0x114>
  ilock(dp);
    80005c3c:	ffffe097          	auipc	ra,0xffffe
    80005c40:	20c080e7          	jalr	524(ra) # 80003e48 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005c44:	00003597          	auipc	a1,0x3
    80005c48:	b3458593          	addi	a1,a1,-1228 # 80008778 <syscalls+0x2c0>
    80005c4c:	fb040513          	addi	a0,s0,-80
    80005c50:	ffffe097          	auipc	ra,0xffffe
    80005c54:	6c2080e7          	jalr	1730(ra) # 80004312 <namecmp>
    80005c58:	14050a63          	beqz	a0,80005dac <sys_unlink+0x1b0>
    80005c5c:	00003597          	auipc	a1,0x3
    80005c60:	b2458593          	addi	a1,a1,-1244 # 80008780 <syscalls+0x2c8>
    80005c64:	fb040513          	addi	a0,s0,-80
    80005c68:	ffffe097          	auipc	ra,0xffffe
    80005c6c:	6aa080e7          	jalr	1706(ra) # 80004312 <namecmp>
    80005c70:	12050e63          	beqz	a0,80005dac <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005c74:	f2c40613          	addi	a2,s0,-212
    80005c78:	fb040593          	addi	a1,s0,-80
    80005c7c:	8526                	mv	a0,s1
    80005c7e:	ffffe097          	auipc	ra,0xffffe
    80005c82:	6ae080e7          	jalr	1710(ra) # 8000432c <dirlookup>
    80005c86:	892a                	mv	s2,a0
    80005c88:	12050263          	beqz	a0,80005dac <sys_unlink+0x1b0>
  ilock(ip);
    80005c8c:	ffffe097          	auipc	ra,0xffffe
    80005c90:	1bc080e7          	jalr	444(ra) # 80003e48 <ilock>
  if(ip->nlink < 1)
    80005c94:	04a91783          	lh	a5,74(s2)
    80005c98:	08f05263          	blez	a5,80005d1c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c9c:	04491703          	lh	a4,68(s2)
    80005ca0:	4785                	li	a5,1
    80005ca2:	08f70563          	beq	a4,a5,80005d2c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005ca6:	4641                	li	a2,16
    80005ca8:	4581                	li	a1,0
    80005caa:	fc040513          	addi	a0,s0,-64
    80005cae:	ffffb097          	auipc	ra,0xffffb
    80005cb2:	01e080e7          	jalr	30(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005cb6:	4741                	li	a4,16
    80005cb8:	f2c42683          	lw	a3,-212(s0)
    80005cbc:	fc040613          	addi	a2,s0,-64
    80005cc0:	4581                	li	a1,0
    80005cc2:	8526                	mv	a0,s1
    80005cc4:	ffffe097          	auipc	ra,0xffffe
    80005cc8:	530080e7          	jalr	1328(ra) # 800041f4 <writei>
    80005ccc:	47c1                	li	a5,16
    80005cce:	0af51563          	bne	a0,a5,80005d78 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005cd2:	04491703          	lh	a4,68(s2)
    80005cd6:	4785                	li	a5,1
    80005cd8:	0af70863          	beq	a4,a5,80005d88 <sys_unlink+0x18c>
  iunlockput(dp);
    80005cdc:	8526                	mv	a0,s1
    80005cde:	ffffe097          	auipc	ra,0xffffe
    80005ce2:	3cc080e7          	jalr	972(ra) # 800040aa <iunlockput>
  ip->nlink--;
    80005ce6:	04a95783          	lhu	a5,74(s2)
    80005cea:	37fd                	addiw	a5,a5,-1
    80005cec:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005cf0:	854a                	mv	a0,s2
    80005cf2:	ffffe097          	auipc	ra,0xffffe
    80005cf6:	08a080e7          	jalr	138(ra) # 80003d7c <iupdate>
  iunlockput(ip);
    80005cfa:	854a                	mv	a0,s2
    80005cfc:	ffffe097          	auipc	ra,0xffffe
    80005d00:	3ae080e7          	jalr	942(ra) # 800040aa <iunlockput>
  end_op();
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	b9e080e7          	jalr	-1122(ra) # 800048a2 <end_op>
  return 0;
    80005d0c:	4501                	li	a0,0
    80005d0e:	a84d                	j	80005dc0 <sys_unlink+0x1c4>
    end_op();
    80005d10:	fffff097          	auipc	ra,0xfffff
    80005d14:	b92080e7          	jalr	-1134(ra) # 800048a2 <end_op>
    return -1;
    80005d18:	557d                	li	a0,-1
    80005d1a:	a05d                	j	80005dc0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005d1c:	00003517          	auipc	a0,0x3
    80005d20:	a8c50513          	addi	a0,a0,-1396 # 800087a8 <syscalls+0x2f0>
    80005d24:	ffffb097          	auipc	ra,0xffffb
    80005d28:	816080e7          	jalr	-2026(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d2c:	04c92703          	lw	a4,76(s2)
    80005d30:	02000793          	li	a5,32
    80005d34:	f6e7f9e3          	bgeu	a5,a4,80005ca6 <sys_unlink+0xaa>
    80005d38:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d3c:	4741                	li	a4,16
    80005d3e:	86ce                	mv	a3,s3
    80005d40:	f1840613          	addi	a2,s0,-232
    80005d44:	4581                	li	a1,0
    80005d46:	854a                	mv	a0,s2
    80005d48:	ffffe097          	auipc	ra,0xffffe
    80005d4c:	3b4080e7          	jalr	948(ra) # 800040fc <readi>
    80005d50:	47c1                	li	a5,16
    80005d52:	00f51b63          	bne	a0,a5,80005d68 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005d56:	f1845783          	lhu	a5,-232(s0)
    80005d5a:	e7a1                	bnez	a5,80005da2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d5c:	29c1                	addiw	s3,s3,16
    80005d5e:	04c92783          	lw	a5,76(s2)
    80005d62:	fcf9ede3          	bltu	s3,a5,80005d3c <sys_unlink+0x140>
    80005d66:	b781                	j	80005ca6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005d68:	00003517          	auipc	a0,0x3
    80005d6c:	a5850513          	addi	a0,a0,-1448 # 800087c0 <syscalls+0x308>
    80005d70:	ffffa097          	auipc	ra,0xffffa
    80005d74:	7ca080e7          	jalr	1994(ra) # 8000053a <panic>
    panic("unlink: writei");
    80005d78:	00003517          	auipc	a0,0x3
    80005d7c:	a6050513          	addi	a0,a0,-1440 # 800087d8 <syscalls+0x320>
    80005d80:	ffffa097          	auipc	ra,0xffffa
    80005d84:	7ba080e7          	jalr	1978(ra) # 8000053a <panic>
    dp->nlink--;
    80005d88:	04a4d783          	lhu	a5,74(s1)
    80005d8c:	37fd                	addiw	a5,a5,-1
    80005d8e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d92:	8526                	mv	a0,s1
    80005d94:	ffffe097          	auipc	ra,0xffffe
    80005d98:	fe8080e7          	jalr	-24(ra) # 80003d7c <iupdate>
    80005d9c:	b781                	j	80005cdc <sys_unlink+0xe0>
    return -1;
    80005d9e:	557d                	li	a0,-1
    80005da0:	a005                	j	80005dc0 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005da2:	854a                	mv	a0,s2
    80005da4:	ffffe097          	auipc	ra,0xffffe
    80005da8:	306080e7          	jalr	774(ra) # 800040aa <iunlockput>
  iunlockput(dp);
    80005dac:	8526                	mv	a0,s1
    80005dae:	ffffe097          	auipc	ra,0xffffe
    80005db2:	2fc080e7          	jalr	764(ra) # 800040aa <iunlockput>
  end_op();
    80005db6:	fffff097          	auipc	ra,0xfffff
    80005dba:	aec080e7          	jalr	-1300(ra) # 800048a2 <end_op>
  return -1;
    80005dbe:	557d                	li	a0,-1
}
    80005dc0:	70ae                	ld	ra,232(sp)
    80005dc2:	740e                	ld	s0,224(sp)
    80005dc4:	64ee                	ld	s1,216(sp)
    80005dc6:	694e                	ld	s2,208(sp)
    80005dc8:	69ae                	ld	s3,200(sp)
    80005dca:	616d                	addi	sp,sp,240
    80005dcc:	8082                	ret

0000000080005dce <sys_open>:

uint64
sys_open(void)
{
    80005dce:	7131                	addi	sp,sp,-192
    80005dd0:	fd06                	sd	ra,184(sp)
    80005dd2:	f922                	sd	s0,176(sp)
    80005dd4:	f526                	sd	s1,168(sp)
    80005dd6:	f14a                	sd	s2,160(sp)
    80005dd8:	ed4e                	sd	s3,152(sp)
    80005dda:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ddc:	08000613          	li	a2,128
    80005de0:	f5040593          	addi	a1,s0,-176
    80005de4:	4501                	li	a0,0
    80005de6:	ffffd097          	auipc	ra,0xffffd
    80005dea:	4b6080e7          	jalr	1206(ra) # 8000329c <argstr>
    return -1;
    80005dee:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005df0:	0c054163          	bltz	a0,80005eb2 <sys_open+0xe4>
    80005df4:	f4c40593          	addi	a1,s0,-180
    80005df8:	4505                	li	a0,1
    80005dfa:	ffffd097          	auipc	ra,0xffffd
    80005dfe:	45e080e7          	jalr	1118(ra) # 80003258 <argint>
    80005e02:	0a054863          	bltz	a0,80005eb2 <sys_open+0xe4>

  begin_op();
    80005e06:	fffff097          	auipc	ra,0xfffff
    80005e0a:	a1e080e7          	jalr	-1506(ra) # 80004824 <begin_op>

  if(omode & O_CREATE){
    80005e0e:	f4c42783          	lw	a5,-180(s0)
    80005e12:	2007f793          	andi	a5,a5,512
    80005e16:	cbdd                	beqz	a5,80005ecc <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005e18:	4681                	li	a3,0
    80005e1a:	4601                	li	a2,0
    80005e1c:	4589                	li	a1,2
    80005e1e:	f5040513          	addi	a0,s0,-176
    80005e22:	00000097          	auipc	ra,0x0
    80005e26:	970080e7          	jalr	-1680(ra) # 80005792 <create>
    80005e2a:	892a                	mv	s2,a0
    if(ip == 0){
    80005e2c:	c959                	beqz	a0,80005ec2 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005e2e:	04491703          	lh	a4,68(s2)
    80005e32:	478d                	li	a5,3
    80005e34:	00f71763          	bne	a4,a5,80005e42 <sys_open+0x74>
    80005e38:	04695703          	lhu	a4,70(s2)
    80005e3c:	47a5                	li	a5,9
    80005e3e:	0ce7ec63          	bltu	a5,a4,80005f16 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005e42:	fffff097          	auipc	ra,0xfffff
    80005e46:	dee080e7          	jalr	-530(ra) # 80004c30 <filealloc>
    80005e4a:	89aa                	mv	s3,a0
    80005e4c:	10050263          	beqz	a0,80005f50 <sys_open+0x182>
    80005e50:	00000097          	auipc	ra,0x0
    80005e54:	900080e7          	jalr	-1792(ra) # 80005750 <fdalloc>
    80005e58:	84aa                	mv	s1,a0
    80005e5a:	0e054663          	bltz	a0,80005f46 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005e5e:	04491703          	lh	a4,68(s2)
    80005e62:	478d                	li	a5,3
    80005e64:	0cf70463          	beq	a4,a5,80005f2c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005e68:	4789                	li	a5,2
    80005e6a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005e6e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005e72:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005e76:	f4c42783          	lw	a5,-180(s0)
    80005e7a:	0017c713          	xori	a4,a5,1
    80005e7e:	8b05                	andi	a4,a4,1
    80005e80:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e84:	0037f713          	andi	a4,a5,3
    80005e88:	00e03733          	snez	a4,a4
    80005e8c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e90:	4007f793          	andi	a5,a5,1024
    80005e94:	c791                	beqz	a5,80005ea0 <sys_open+0xd2>
    80005e96:	04491703          	lh	a4,68(s2)
    80005e9a:	4789                	li	a5,2
    80005e9c:	08f70f63          	beq	a4,a5,80005f3a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005ea0:	854a                	mv	a0,s2
    80005ea2:	ffffe097          	auipc	ra,0xffffe
    80005ea6:	068080e7          	jalr	104(ra) # 80003f0a <iunlock>
  end_op();
    80005eaa:	fffff097          	auipc	ra,0xfffff
    80005eae:	9f8080e7          	jalr	-1544(ra) # 800048a2 <end_op>

  return fd;
}
    80005eb2:	8526                	mv	a0,s1
    80005eb4:	70ea                	ld	ra,184(sp)
    80005eb6:	744a                	ld	s0,176(sp)
    80005eb8:	74aa                	ld	s1,168(sp)
    80005eba:	790a                	ld	s2,160(sp)
    80005ebc:	69ea                	ld	s3,152(sp)
    80005ebe:	6129                	addi	sp,sp,192
    80005ec0:	8082                	ret
      end_op();
    80005ec2:	fffff097          	auipc	ra,0xfffff
    80005ec6:	9e0080e7          	jalr	-1568(ra) # 800048a2 <end_op>
      return -1;
    80005eca:	b7e5                	j	80005eb2 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005ecc:	f5040513          	addi	a0,s0,-176
    80005ed0:	ffffe097          	auipc	ra,0xffffe
    80005ed4:	734080e7          	jalr	1844(ra) # 80004604 <namei>
    80005ed8:	892a                	mv	s2,a0
    80005eda:	c905                	beqz	a0,80005f0a <sys_open+0x13c>
    ilock(ip);
    80005edc:	ffffe097          	auipc	ra,0xffffe
    80005ee0:	f6c080e7          	jalr	-148(ra) # 80003e48 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ee4:	04491703          	lh	a4,68(s2)
    80005ee8:	4785                	li	a5,1
    80005eea:	f4f712e3          	bne	a4,a5,80005e2e <sys_open+0x60>
    80005eee:	f4c42783          	lw	a5,-180(s0)
    80005ef2:	dba1                	beqz	a5,80005e42 <sys_open+0x74>
      iunlockput(ip);
    80005ef4:	854a                	mv	a0,s2
    80005ef6:	ffffe097          	auipc	ra,0xffffe
    80005efa:	1b4080e7          	jalr	436(ra) # 800040aa <iunlockput>
      end_op();
    80005efe:	fffff097          	auipc	ra,0xfffff
    80005f02:	9a4080e7          	jalr	-1628(ra) # 800048a2 <end_op>
      return -1;
    80005f06:	54fd                	li	s1,-1
    80005f08:	b76d                	j	80005eb2 <sys_open+0xe4>
      end_op();
    80005f0a:	fffff097          	auipc	ra,0xfffff
    80005f0e:	998080e7          	jalr	-1640(ra) # 800048a2 <end_op>
      return -1;
    80005f12:	54fd                	li	s1,-1
    80005f14:	bf79                	j	80005eb2 <sys_open+0xe4>
    iunlockput(ip);
    80005f16:	854a                	mv	a0,s2
    80005f18:	ffffe097          	auipc	ra,0xffffe
    80005f1c:	192080e7          	jalr	402(ra) # 800040aa <iunlockput>
    end_op();
    80005f20:	fffff097          	auipc	ra,0xfffff
    80005f24:	982080e7          	jalr	-1662(ra) # 800048a2 <end_op>
    return -1;
    80005f28:	54fd                	li	s1,-1
    80005f2a:	b761                	j	80005eb2 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005f2c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005f30:	04691783          	lh	a5,70(s2)
    80005f34:	02f99223          	sh	a5,36(s3)
    80005f38:	bf2d                	j	80005e72 <sys_open+0xa4>
    itrunc(ip);
    80005f3a:	854a                	mv	a0,s2
    80005f3c:	ffffe097          	auipc	ra,0xffffe
    80005f40:	01a080e7          	jalr	26(ra) # 80003f56 <itrunc>
    80005f44:	bfb1                	j	80005ea0 <sys_open+0xd2>
      fileclose(f);
    80005f46:	854e                	mv	a0,s3
    80005f48:	fffff097          	auipc	ra,0xfffff
    80005f4c:	da4080e7          	jalr	-604(ra) # 80004cec <fileclose>
    iunlockput(ip);
    80005f50:	854a                	mv	a0,s2
    80005f52:	ffffe097          	auipc	ra,0xffffe
    80005f56:	158080e7          	jalr	344(ra) # 800040aa <iunlockput>
    end_op();
    80005f5a:	fffff097          	auipc	ra,0xfffff
    80005f5e:	948080e7          	jalr	-1720(ra) # 800048a2 <end_op>
    return -1;
    80005f62:	54fd                	li	s1,-1
    80005f64:	b7b9                	j	80005eb2 <sys_open+0xe4>

0000000080005f66 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005f66:	7175                	addi	sp,sp,-144
    80005f68:	e506                	sd	ra,136(sp)
    80005f6a:	e122                	sd	s0,128(sp)
    80005f6c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005f6e:	fffff097          	auipc	ra,0xfffff
    80005f72:	8b6080e7          	jalr	-1866(ra) # 80004824 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f76:	08000613          	li	a2,128
    80005f7a:	f7040593          	addi	a1,s0,-144
    80005f7e:	4501                	li	a0,0
    80005f80:	ffffd097          	auipc	ra,0xffffd
    80005f84:	31c080e7          	jalr	796(ra) # 8000329c <argstr>
    80005f88:	02054963          	bltz	a0,80005fba <sys_mkdir+0x54>
    80005f8c:	4681                	li	a3,0
    80005f8e:	4601                	li	a2,0
    80005f90:	4585                	li	a1,1
    80005f92:	f7040513          	addi	a0,s0,-144
    80005f96:	fffff097          	auipc	ra,0xfffff
    80005f9a:	7fc080e7          	jalr	2044(ra) # 80005792 <create>
    80005f9e:	cd11                	beqz	a0,80005fba <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005fa0:	ffffe097          	auipc	ra,0xffffe
    80005fa4:	10a080e7          	jalr	266(ra) # 800040aa <iunlockput>
  end_op();
    80005fa8:	fffff097          	auipc	ra,0xfffff
    80005fac:	8fa080e7          	jalr	-1798(ra) # 800048a2 <end_op>
  return 0;
    80005fb0:	4501                	li	a0,0
}
    80005fb2:	60aa                	ld	ra,136(sp)
    80005fb4:	640a                	ld	s0,128(sp)
    80005fb6:	6149                	addi	sp,sp,144
    80005fb8:	8082                	ret
    end_op();
    80005fba:	fffff097          	auipc	ra,0xfffff
    80005fbe:	8e8080e7          	jalr	-1816(ra) # 800048a2 <end_op>
    return -1;
    80005fc2:	557d                	li	a0,-1
    80005fc4:	b7fd                	j	80005fb2 <sys_mkdir+0x4c>

0000000080005fc6 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005fc6:	7135                	addi	sp,sp,-160
    80005fc8:	ed06                	sd	ra,152(sp)
    80005fca:	e922                	sd	s0,144(sp)
    80005fcc:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005fce:	fffff097          	auipc	ra,0xfffff
    80005fd2:	856080e7          	jalr	-1962(ra) # 80004824 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fd6:	08000613          	li	a2,128
    80005fda:	f7040593          	addi	a1,s0,-144
    80005fde:	4501                	li	a0,0
    80005fe0:	ffffd097          	auipc	ra,0xffffd
    80005fe4:	2bc080e7          	jalr	700(ra) # 8000329c <argstr>
    80005fe8:	04054a63          	bltz	a0,8000603c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005fec:	f6c40593          	addi	a1,s0,-148
    80005ff0:	4505                	li	a0,1
    80005ff2:	ffffd097          	auipc	ra,0xffffd
    80005ff6:	266080e7          	jalr	614(ra) # 80003258 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ffa:	04054163          	bltz	a0,8000603c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005ffe:	f6840593          	addi	a1,s0,-152
    80006002:	4509                	li	a0,2
    80006004:	ffffd097          	auipc	ra,0xffffd
    80006008:	254080e7          	jalr	596(ra) # 80003258 <argint>
     argint(1, &major) < 0 ||
    8000600c:	02054863          	bltz	a0,8000603c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006010:	f6841683          	lh	a3,-152(s0)
    80006014:	f6c41603          	lh	a2,-148(s0)
    80006018:	458d                	li	a1,3
    8000601a:	f7040513          	addi	a0,s0,-144
    8000601e:	fffff097          	auipc	ra,0xfffff
    80006022:	774080e7          	jalr	1908(ra) # 80005792 <create>
     argint(2, &minor) < 0 ||
    80006026:	c919                	beqz	a0,8000603c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006028:	ffffe097          	auipc	ra,0xffffe
    8000602c:	082080e7          	jalr	130(ra) # 800040aa <iunlockput>
  end_op();
    80006030:	fffff097          	auipc	ra,0xfffff
    80006034:	872080e7          	jalr	-1934(ra) # 800048a2 <end_op>
  return 0;
    80006038:	4501                	li	a0,0
    8000603a:	a031                	j	80006046 <sys_mknod+0x80>
    end_op();
    8000603c:	fffff097          	auipc	ra,0xfffff
    80006040:	866080e7          	jalr	-1946(ra) # 800048a2 <end_op>
    return -1;
    80006044:	557d                	li	a0,-1
}
    80006046:	60ea                	ld	ra,152(sp)
    80006048:	644a                	ld	s0,144(sp)
    8000604a:	610d                	addi	sp,sp,160
    8000604c:	8082                	ret

000000008000604e <sys_chdir>:

uint64
sys_chdir(void)
{
    8000604e:	7135                	addi	sp,sp,-160
    80006050:	ed06                	sd	ra,152(sp)
    80006052:	e922                	sd	s0,144(sp)
    80006054:	e526                	sd	s1,136(sp)
    80006056:	e14a                	sd	s2,128(sp)
    80006058:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000605a:	ffffc097          	auipc	ra,0xffffc
    8000605e:	bf6080e7          	jalr	-1034(ra) # 80001c50 <myproc>
    80006062:	892a                	mv	s2,a0
  
  begin_op();
    80006064:	ffffe097          	auipc	ra,0xffffe
    80006068:	7c0080e7          	jalr	1984(ra) # 80004824 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000606c:	08000613          	li	a2,128
    80006070:	f6040593          	addi	a1,s0,-160
    80006074:	4501                	li	a0,0
    80006076:	ffffd097          	auipc	ra,0xffffd
    8000607a:	226080e7          	jalr	550(ra) # 8000329c <argstr>
    8000607e:	04054b63          	bltz	a0,800060d4 <sys_chdir+0x86>
    80006082:	f6040513          	addi	a0,s0,-160
    80006086:	ffffe097          	auipc	ra,0xffffe
    8000608a:	57e080e7          	jalr	1406(ra) # 80004604 <namei>
    8000608e:	84aa                	mv	s1,a0
    80006090:	c131                	beqz	a0,800060d4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006092:	ffffe097          	auipc	ra,0xffffe
    80006096:	db6080e7          	jalr	-586(ra) # 80003e48 <ilock>
  if(ip->type != T_DIR){
    8000609a:	04449703          	lh	a4,68(s1)
    8000609e:	4785                	li	a5,1
    800060a0:	04f71063          	bne	a4,a5,800060e0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800060a4:	8526                	mv	a0,s1
    800060a6:	ffffe097          	auipc	ra,0xffffe
    800060aa:	e64080e7          	jalr	-412(ra) # 80003f0a <iunlock>
  iput(p->cwd);
    800060ae:	17093503          	ld	a0,368(s2)
    800060b2:	ffffe097          	auipc	ra,0xffffe
    800060b6:	f50080e7          	jalr	-176(ra) # 80004002 <iput>
  end_op();
    800060ba:	ffffe097          	auipc	ra,0xffffe
    800060be:	7e8080e7          	jalr	2024(ra) # 800048a2 <end_op>
  p->cwd = ip;
    800060c2:	16993823          	sd	s1,368(s2)
  return 0;
    800060c6:	4501                	li	a0,0
}
    800060c8:	60ea                	ld	ra,152(sp)
    800060ca:	644a                	ld	s0,144(sp)
    800060cc:	64aa                	ld	s1,136(sp)
    800060ce:	690a                	ld	s2,128(sp)
    800060d0:	610d                	addi	sp,sp,160
    800060d2:	8082                	ret
    end_op();
    800060d4:	ffffe097          	auipc	ra,0xffffe
    800060d8:	7ce080e7          	jalr	1998(ra) # 800048a2 <end_op>
    return -1;
    800060dc:	557d                	li	a0,-1
    800060de:	b7ed                	j	800060c8 <sys_chdir+0x7a>
    iunlockput(ip);
    800060e0:	8526                	mv	a0,s1
    800060e2:	ffffe097          	auipc	ra,0xffffe
    800060e6:	fc8080e7          	jalr	-56(ra) # 800040aa <iunlockput>
    end_op();
    800060ea:	ffffe097          	auipc	ra,0xffffe
    800060ee:	7b8080e7          	jalr	1976(ra) # 800048a2 <end_op>
    return -1;
    800060f2:	557d                	li	a0,-1
    800060f4:	bfd1                	j	800060c8 <sys_chdir+0x7a>

00000000800060f6 <sys_exec>:

uint64
sys_exec(void)
{
    800060f6:	7145                	addi	sp,sp,-464
    800060f8:	e786                	sd	ra,456(sp)
    800060fa:	e3a2                	sd	s0,448(sp)
    800060fc:	ff26                	sd	s1,440(sp)
    800060fe:	fb4a                	sd	s2,432(sp)
    80006100:	f74e                	sd	s3,424(sp)
    80006102:	f352                	sd	s4,416(sp)
    80006104:	ef56                	sd	s5,408(sp)
    80006106:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006108:	08000613          	li	a2,128
    8000610c:	f4040593          	addi	a1,s0,-192
    80006110:	4501                	li	a0,0
    80006112:	ffffd097          	auipc	ra,0xffffd
    80006116:	18a080e7          	jalr	394(ra) # 8000329c <argstr>
    return -1;
    8000611a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000611c:	0c054b63          	bltz	a0,800061f2 <sys_exec+0xfc>
    80006120:	e3840593          	addi	a1,s0,-456
    80006124:	4505                	li	a0,1
    80006126:	ffffd097          	auipc	ra,0xffffd
    8000612a:	154080e7          	jalr	340(ra) # 8000327a <argaddr>
    8000612e:	0c054263          	bltz	a0,800061f2 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80006132:	10000613          	li	a2,256
    80006136:	4581                	li	a1,0
    80006138:	e4040513          	addi	a0,s0,-448
    8000613c:	ffffb097          	auipc	ra,0xffffb
    80006140:	b90080e7          	jalr	-1136(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006144:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006148:	89a6                	mv	s3,s1
    8000614a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000614c:	02000a13          	li	s4,32
    80006150:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006154:	00391513          	slli	a0,s2,0x3
    80006158:	e3040593          	addi	a1,s0,-464
    8000615c:	e3843783          	ld	a5,-456(s0)
    80006160:	953e                	add	a0,a0,a5
    80006162:	ffffd097          	auipc	ra,0xffffd
    80006166:	05c080e7          	jalr	92(ra) # 800031be <fetchaddr>
    8000616a:	02054a63          	bltz	a0,8000619e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000616e:	e3043783          	ld	a5,-464(s0)
    80006172:	c3b9                	beqz	a5,800061b8 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006174:	ffffb097          	auipc	ra,0xffffb
    80006178:	96c080e7          	jalr	-1684(ra) # 80000ae0 <kalloc>
    8000617c:	85aa                	mv	a1,a0
    8000617e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006182:	cd11                	beqz	a0,8000619e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006184:	6605                	lui	a2,0x1
    80006186:	e3043503          	ld	a0,-464(s0)
    8000618a:	ffffd097          	auipc	ra,0xffffd
    8000618e:	086080e7          	jalr	134(ra) # 80003210 <fetchstr>
    80006192:	00054663          	bltz	a0,8000619e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006196:	0905                	addi	s2,s2,1
    80006198:	09a1                	addi	s3,s3,8
    8000619a:	fb491be3          	bne	s2,s4,80006150 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000619e:	f4040913          	addi	s2,s0,-192
    800061a2:	6088                	ld	a0,0(s1)
    800061a4:	c531                	beqz	a0,800061f0 <sys_exec+0xfa>
    kfree(argv[i]);
    800061a6:	ffffb097          	auipc	ra,0xffffb
    800061aa:	83c080e7          	jalr	-1988(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061ae:	04a1                	addi	s1,s1,8
    800061b0:	ff2499e3          	bne	s1,s2,800061a2 <sys_exec+0xac>
  return -1;
    800061b4:	597d                	li	s2,-1
    800061b6:	a835                	j	800061f2 <sys_exec+0xfc>
      argv[i] = 0;
    800061b8:	0a8e                	slli	s5,s5,0x3
    800061ba:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    800061be:	00878ab3          	add	s5,a5,s0
    800061c2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800061c6:	e4040593          	addi	a1,s0,-448
    800061ca:	f4040513          	addi	a0,s0,-192
    800061ce:	fffff097          	auipc	ra,0xfffff
    800061d2:	172080e7          	jalr	370(ra) # 80005340 <exec>
    800061d6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061d8:	f4040993          	addi	s3,s0,-192
    800061dc:	6088                	ld	a0,0(s1)
    800061de:	c911                	beqz	a0,800061f2 <sys_exec+0xfc>
    kfree(argv[i]);
    800061e0:	ffffb097          	auipc	ra,0xffffb
    800061e4:	802080e7          	jalr	-2046(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061e8:	04a1                	addi	s1,s1,8
    800061ea:	ff3499e3          	bne	s1,s3,800061dc <sys_exec+0xe6>
    800061ee:	a011                	j	800061f2 <sys_exec+0xfc>
  return -1;
    800061f0:	597d                	li	s2,-1
}
    800061f2:	854a                	mv	a0,s2
    800061f4:	60be                	ld	ra,456(sp)
    800061f6:	641e                	ld	s0,448(sp)
    800061f8:	74fa                	ld	s1,440(sp)
    800061fa:	795a                	ld	s2,432(sp)
    800061fc:	79ba                	ld	s3,424(sp)
    800061fe:	7a1a                	ld	s4,416(sp)
    80006200:	6afa                	ld	s5,408(sp)
    80006202:	6179                	addi	sp,sp,464
    80006204:	8082                	ret

0000000080006206 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006206:	7139                	addi	sp,sp,-64
    80006208:	fc06                	sd	ra,56(sp)
    8000620a:	f822                	sd	s0,48(sp)
    8000620c:	f426                	sd	s1,40(sp)
    8000620e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006210:	ffffc097          	auipc	ra,0xffffc
    80006214:	a40080e7          	jalr	-1472(ra) # 80001c50 <myproc>
    80006218:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000621a:	fd840593          	addi	a1,s0,-40
    8000621e:	4501                	li	a0,0
    80006220:	ffffd097          	auipc	ra,0xffffd
    80006224:	05a080e7          	jalr	90(ra) # 8000327a <argaddr>
    return -1;
    80006228:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000622a:	0e054063          	bltz	a0,8000630a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000622e:	fc840593          	addi	a1,s0,-56
    80006232:	fd040513          	addi	a0,s0,-48
    80006236:	fffff097          	auipc	ra,0xfffff
    8000623a:	de6080e7          	jalr	-538(ra) # 8000501c <pipealloc>
    return -1;
    8000623e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006240:	0c054563          	bltz	a0,8000630a <sys_pipe+0x104>
  fd0 = -1;
    80006244:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006248:	fd043503          	ld	a0,-48(s0)
    8000624c:	fffff097          	auipc	ra,0xfffff
    80006250:	504080e7          	jalr	1284(ra) # 80005750 <fdalloc>
    80006254:	fca42223          	sw	a0,-60(s0)
    80006258:	08054c63          	bltz	a0,800062f0 <sys_pipe+0xea>
    8000625c:	fc843503          	ld	a0,-56(s0)
    80006260:	fffff097          	auipc	ra,0xfffff
    80006264:	4f0080e7          	jalr	1264(ra) # 80005750 <fdalloc>
    80006268:	fca42023          	sw	a0,-64(s0)
    8000626c:	06054963          	bltz	a0,800062de <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006270:	4691                	li	a3,4
    80006272:	fc440613          	addi	a2,s0,-60
    80006276:	fd843583          	ld	a1,-40(s0)
    8000627a:	78a8                	ld	a0,112(s1)
    8000627c:	ffffb097          	auipc	ra,0xffffb
    80006280:	3de080e7          	jalr	990(ra) # 8000165a <copyout>
    80006284:	02054063          	bltz	a0,800062a4 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006288:	4691                	li	a3,4
    8000628a:	fc040613          	addi	a2,s0,-64
    8000628e:	fd843583          	ld	a1,-40(s0)
    80006292:	0591                	addi	a1,a1,4
    80006294:	78a8                	ld	a0,112(s1)
    80006296:	ffffb097          	auipc	ra,0xffffb
    8000629a:	3c4080e7          	jalr	964(ra) # 8000165a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000629e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800062a0:	06055563          	bgez	a0,8000630a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800062a4:	fc442783          	lw	a5,-60(s0)
    800062a8:	07f9                	addi	a5,a5,30
    800062aa:	078e                	slli	a5,a5,0x3
    800062ac:	97a6                	add	a5,a5,s1
    800062ae:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800062b2:	fc042783          	lw	a5,-64(s0)
    800062b6:	07f9                	addi	a5,a5,30
    800062b8:	078e                	slli	a5,a5,0x3
    800062ba:	00f48533          	add	a0,s1,a5
    800062be:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800062c2:	fd043503          	ld	a0,-48(s0)
    800062c6:	fffff097          	auipc	ra,0xfffff
    800062ca:	a26080e7          	jalr	-1498(ra) # 80004cec <fileclose>
    fileclose(wf);
    800062ce:	fc843503          	ld	a0,-56(s0)
    800062d2:	fffff097          	auipc	ra,0xfffff
    800062d6:	a1a080e7          	jalr	-1510(ra) # 80004cec <fileclose>
    return -1;
    800062da:	57fd                	li	a5,-1
    800062dc:	a03d                	j	8000630a <sys_pipe+0x104>
    if(fd0 >= 0)
    800062de:	fc442783          	lw	a5,-60(s0)
    800062e2:	0007c763          	bltz	a5,800062f0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800062e6:	07f9                	addi	a5,a5,30
    800062e8:	078e                	slli	a5,a5,0x3
    800062ea:	97a6                	add	a5,a5,s1
    800062ec:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800062f0:	fd043503          	ld	a0,-48(s0)
    800062f4:	fffff097          	auipc	ra,0xfffff
    800062f8:	9f8080e7          	jalr	-1544(ra) # 80004cec <fileclose>
    fileclose(wf);
    800062fc:	fc843503          	ld	a0,-56(s0)
    80006300:	fffff097          	auipc	ra,0xfffff
    80006304:	9ec080e7          	jalr	-1556(ra) # 80004cec <fileclose>
    return -1;
    80006308:	57fd                	li	a5,-1
}
    8000630a:	853e                	mv	a0,a5
    8000630c:	70e2                	ld	ra,56(sp)
    8000630e:	7442                	ld	s0,48(sp)
    80006310:	74a2                	ld	s1,40(sp)
    80006312:	6121                	addi	sp,sp,64
    80006314:	8082                	ret
	...

0000000080006320 <kernelvec>:
    80006320:	7111                	addi	sp,sp,-256
    80006322:	e006                	sd	ra,0(sp)
    80006324:	e40a                	sd	sp,8(sp)
    80006326:	e80e                	sd	gp,16(sp)
    80006328:	ec12                	sd	tp,24(sp)
    8000632a:	f016                	sd	t0,32(sp)
    8000632c:	f41a                	sd	t1,40(sp)
    8000632e:	f81e                	sd	t2,48(sp)
    80006330:	fc22                	sd	s0,56(sp)
    80006332:	e0a6                	sd	s1,64(sp)
    80006334:	e4aa                	sd	a0,72(sp)
    80006336:	e8ae                	sd	a1,80(sp)
    80006338:	ecb2                	sd	a2,88(sp)
    8000633a:	f0b6                	sd	a3,96(sp)
    8000633c:	f4ba                	sd	a4,104(sp)
    8000633e:	f8be                	sd	a5,112(sp)
    80006340:	fcc2                	sd	a6,120(sp)
    80006342:	e146                	sd	a7,128(sp)
    80006344:	e54a                	sd	s2,136(sp)
    80006346:	e94e                	sd	s3,144(sp)
    80006348:	ed52                	sd	s4,152(sp)
    8000634a:	f156                	sd	s5,160(sp)
    8000634c:	f55a                	sd	s6,168(sp)
    8000634e:	f95e                	sd	s7,176(sp)
    80006350:	fd62                	sd	s8,184(sp)
    80006352:	e1e6                	sd	s9,192(sp)
    80006354:	e5ea                	sd	s10,200(sp)
    80006356:	e9ee                	sd	s11,208(sp)
    80006358:	edf2                	sd	t3,216(sp)
    8000635a:	f1f6                	sd	t4,224(sp)
    8000635c:	f5fa                	sd	t5,232(sp)
    8000635e:	f9fe                	sd	t6,240(sp)
    80006360:	bb3fc0ef          	jal	ra,80002f12 <kerneltrap>
    80006364:	6082                	ld	ra,0(sp)
    80006366:	6122                	ld	sp,8(sp)
    80006368:	61c2                	ld	gp,16(sp)
    8000636a:	7282                	ld	t0,32(sp)
    8000636c:	7322                	ld	t1,40(sp)
    8000636e:	73c2                	ld	t2,48(sp)
    80006370:	7462                	ld	s0,56(sp)
    80006372:	6486                	ld	s1,64(sp)
    80006374:	6526                	ld	a0,72(sp)
    80006376:	65c6                	ld	a1,80(sp)
    80006378:	6666                	ld	a2,88(sp)
    8000637a:	7686                	ld	a3,96(sp)
    8000637c:	7726                	ld	a4,104(sp)
    8000637e:	77c6                	ld	a5,112(sp)
    80006380:	7866                	ld	a6,120(sp)
    80006382:	688a                	ld	a7,128(sp)
    80006384:	692a                	ld	s2,136(sp)
    80006386:	69ca                	ld	s3,144(sp)
    80006388:	6a6a                	ld	s4,152(sp)
    8000638a:	7a8a                	ld	s5,160(sp)
    8000638c:	7b2a                	ld	s6,168(sp)
    8000638e:	7bca                	ld	s7,176(sp)
    80006390:	7c6a                	ld	s8,184(sp)
    80006392:	6c8e                	ld	s9,192(sp)
    80006394:	6d2e                	ld	s10,200(sp)
    80006396:	6dce                	ld	s11,208(sp)
    80006398:	6e6e                	ld	t3,216(sp)
    8000639a:	7e8e                	ld	t4,224(sp)
    8000639c:	7f2e                	ld	t5,232(sp)
    8000639e:	7fce                	ld	t6,240(sp)
    800063a0:	6111                	addi	sp,sp,256
    800063a2:	10200073          	sret
    800063a6:	00000013          	nop
    800063aa:	00000013          	nop
    800063ae:	0001                	nop

00000000800063b0 <timervec>:
    800063b0:	34051573          	csrrw	a0,mscratch,a0
    800063b4:	e10c                	sd	a1,0(a0)
    800063b6:	e510                	sd	a2,8(a0)
    800063b8:	e914                	sd	a3,16(a0)
    800063ba:	6d0c                	ld	a1,24(a0)
    800063bc:	7110                	ld	a2,32(a0)
    800063be:	6194                	ld	a3,0(a1)
    800063c0:	96b2                	add	a3,a3,a2
    800063c2:	e194                	sd	a3,0(a1)
    800063c4:	4589                	li	a1,2
    800063c6:	14459073          	csrw	sip,a1
    800063ca:	6914                	ld	a3,16(a0)
    800063cc:	6510                	ld	a2,8(a0)
    800063ce:	610c                	ld	a1,0(a0)
    800063d0:	34051573          	csrrw	a0,mscratch,a0
    800063d4:	30200073          	mret
	...

00000000800063da <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800063da:	1141                	addi	sp,sp,-16
    800063dc:	e422                	sd	s0,8(sp)
    800063de:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800063e0:	0c0007b7          	lui	a5,0xc000
    800063e4:	4705                	li	a4,1
    800063e6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800063e8:	c3d8                	sw	a4,4(a5)
}
    800063ea:	6422                	ld	s0,8(sp)
    800063ec:	0141                	addi	sp,sp,16
    800063ee:	8082                	ret

00000000800063f0 <plicinithart>:

void
plicinithart(void)
{
    800063f0:	1141                	addi	sp,sp,-16
    800063f2:	e406                	sd	ra,8(sp)
    800063f4:	e022                	sd	s0,0(sp)
    800063f6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063f8:	ffffc097          	auipc	ra,0xffffc
    800063fc:	82c080e7          	jalr	-2004(ra) # 80001c24 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006400:	0085171b          	slliw	a4,a0,0x8
    80006404:	0c0027b7          	lui	a5,0xc002
    80006408:	97ba                	add	a5,a5,a4
    8000640a:	40200713          	li	a4,1026
    8000640e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006412:	00d5151b          	slliw	a0,a0,0xd
    80006416:	0c2017b7          	lui	a5,0xc201
    8000641a:	97aa                	add	a5,a5,a0
    8000641c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006420:	60a2                	ld	ra,8(sp)
    80006422:	6402                	ld	s0,0(sp)
    80006424:	0141                	addi	sp,sp,16
    80006426:	8082                	ret

0000000080006428 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006428:	1141                	addi	sp,sp,-16
    8000642a:	e406                	sd	ra,8(sp)
    8000642c:	e022                	sd	s0,0(sp)
    8000642e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006430:	ffffb097          	auipc	ra,0xffffb
    80006434:	7f4080e7          	jalr	2036(ra) # 80001c24 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006438:	00d5151b          	slliw	a0,a0,0xd
    8000643c:	0c2017b7          	lui	a5,0xc201
    80006440:	97aa                	add	a5,a5,a0
  return irq;
}
    80006442:	43c8                	lw	a0,4(a5)
    80006444:	60a2                	ld	ra,8(sp)
    80006446:	6402                	ld	s0,0(sp)
    80006448:	0141                	addi	sp,sp,16
    8000644a:	8082                	ret

000000008000644c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000644c:	1101                	addi	sp,sp,-32
    8000644e:	ec06                	sd	ra,24(sp)
    80006450:	e822                	sd	s0,16(sp)
    80006452:	e426                	sd	s1,8(sp)
    80006454:	1000                	addi	s0,sp,32
    80006456:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006458:	ffffb097          	auipc	ra,0xffffb
    8000645c:	7cc080e7          	jalr	1996(ra) # 80001c24 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006460:	00d5151b          	slliw	a0,a0,0xd
    80006464:	0c2017b7          	lui	a5,0xc201
    80006468:	97aa                	add	a5,a5,a0
    8000646a:	c3c4                	sw	s1,4(a5)
}
    8000646c:	60e2                	ld	ra,24(sp)
    8000646e:	6442                	ld	s0,16(sp)
    80006470:	64a2                	ld	s1,8(sp)
    80006472:	6105                	addi	sp,sp,32
    80006474:	8082                	ret

0000000080006476 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006476:	1141                	addi	sp,sp,-16
    80006478:	e406                	sd	ra,8(sp)
    8000647a:	e022                	sd	s0,0(sp)
    8000647c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000647e:	479d                	li	a5,7
    80006480:	06a7c863          	blt	a5,a0,800064f0 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80006484:	0001d717          	auipc	a4,0x1d
    80006488:	b7c70713          	addi	a4,a4,-1156 # 80023000 <disk>
    8000648c:	972a                	add	a4,a4,a0
    8000648e:	6789                	lui	a5,0x2
    80006490:	97ba                	add	a5,a5,a4
    80006492:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006496:	e7ad                	bnez	a5,80006500 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006498:	00451793          	slli	a5,a0,0x4
    8000649c:	0001f717          	auipc	a4,0x1f
    800064a0:	b6470713          	addi	a4,a4,-1180 # 80025000 <disk+0x2000>
    800064a4:	6314                	ld	a3,0(a4)
    800064a6:	96be                	add	a3,a3,a5
    800064a8:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800064ac:	6314                	ld	a3,0(a4)
    800064ae:	96be                	add	a3,a3,a5
    800064b0:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800064b4:	6314                	ld	a3,0(a4)
    800064b6:	96be                	add	a3,a3,a5
    800064b8:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800064bc:	6318                	ld	a4,0(a4)
    800064be:	97ba                	add	a5,a5,a4
    800064c0:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800064c4:	0001d717          	auipc	a4,0x1d
    800064c8:	b3c70713          	addi	a4,a4,-1220 # 80023000 <disk>
    800064cc:	972a                	add	a4,a4,a0
    800064ce:	6789                	lui	a5,0x2
    800064d0:	97ba                	add	a5,a5,a4
    800064d2:	4705                	li	a4,1
    800064d4:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800064d8:	0001f517          	auipc	a0,0x1f
    800064dc:	b4050513          	addi	a0,a0,-1216 # 80025018 <disk+0x2018>
    800064e0:	ffffc097          	auipc	ra,0xffffc
    800064e4:	07a080e7          	jalr	122(ra) # 8000255a <wakeup>
}
    800064e8:	60a2                	ld	ra,8(sp)
    800064ea:	6402                	ld	s0,0(sp)
    800064ec:	0141                	addi	sp,sp,16
    800064ee:	8082                	ret
    panic("free_desc 1");
    800064f0:	00002517          	auipc	a0,0x2
    800064f4:	2f850513          	addi	a0,a0,760 # 800087e8 <syscalls+0x330>
    800064f8:	ffffa097          	auipc	ra,0xffffa
    800064fc:	042080e7          	jalr	66(ra) # 8000053a <panic>
    panic("free_desc 2");
    80006500:	00002517          	auipc	a0,0x2
    80006504:	2f850513          	addi	a0,a0,760 # 800087f8 <syscalls+0x340>
    80006508:	ffffa097          	auipc	ra,0xffffa
    8000650c:	032080e7          	jalr	50(ra) # 8000053a <panic>

0000000080006510 <virtio_disk_init>:
{
    80006510:	1101                	addi	sp,sp,-32
    80006512:	ec06                	sd	ra,24(sp)
    80006514:	e822                	sd	s0,16(sp)
    80006516:	e426                	sd	s1,8(sp)
    80006518:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000651a:	00002597          	auipc	a1,0x2
    8000651e:	2ee58593          	addi	a1,a1,750 # 80008808 <syscalls+0x350>
    80006522:	0001f517          	auipc	a0,0x1f
    80006526:	c0650513          	addi	a0,a0,-1018 # 80025128 <disk+0x2128>
    8000652a:	ffffa097          	auipc	ra,0xffffa
    8000652e:	616080e7          	jalr	1558(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006532:	100017b7          	lui	a5,0x10001
    80006536:	4398                	lw	a4,0(a5)
    80006538:	2701                	sext.w	a4,a4
    8000653a:	747277b7          	lui	a5,0x74727
    8000653e:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006542:	0ef71063          	bne	a4,a5,80006622 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006546:	100017b7          	lui	a5,0x10001
    8000654a:	43dc                	lw	a5,4(a5)
    8000654c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000654e:	4705                	li	a4,1
    80006550:	0ce79963          	bne	a5,a4,80006622 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006554:	100017b7          	lui	a5,0x10001
    80006558:	479c                	lw	a5,8(a5)
    8000655a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000655c:	4709                	li	a4,2
    8000655e:	0ce79263          	bne	a5,a4,80006622 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006562:	100017b7          	lui	a5,0x10001
    80006566:	47d8                	lw	a4,12(a5)
    80006568:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000656a:	554d47b7          	lui	a5,0x554d4
    8000656e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006572:	0af71863          	bne	a4,a5,80006622 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006576:	100017b7          	lui	a5,0x10001
    8000657a:	4705                	li	a4,1
    8000657c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000657e:	470d                	li	a4,3
    80006580:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006582:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006584:	c7ffe6b7          	lui	a3,0xc7ffe
    80006588:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000658c:	8f75                	and	a4,a4,a3
    8000658e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006590:	472d                	li	a4,11
    80006592:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006594:	473d                	li	a4,15
    80006596:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006598:	6705                	lui	a4,0x1
    8000659a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000659c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800065a0:	5bdc                	lw	a5,52(a5)
    800065a2:	2781                	sext.w	a5,a5
  if(max == 0)
    800065a4:	c7d9                	beqz	a5,80006632 <virtio_disk_init+0x122>
  if(max < NUM)
    800065a6:	471d                	li	a4,7
    800065a8:	08f77d63          	bgeu	a4,a5,80006642 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800065ac:	100014b7          	lui	s1,0x10001
    800065b0:	47a1                	li	a5,8
    800065b2:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800065b4:	6609                	lui	a2,0x2
    800065b6:	4581                	li	a1,0
    800065b8:	0001d517          	auipc	a0,0x1d
    800065bc:	a4850513          	addi	a0,a0,-1464 # 80023000 <disk>
    800065c0:	ffffa097          	auipc	ra,0xffffa
    800065c4:	70c080e7          	jalr	1804(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800065c8:	0001d717          	auipc	a4,0x1d
    800065cc:	a3870713          	addi	a4,a4,-1480 # 80023000 <disk>
    800065d0:	00c75793          	srli	a5,a4,0xc
    800065d4:	2781                	sext.w	a5,a5
    800065d6:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800065d8:	0001f797          	auipc	a5,0x1f
    800065dc:	a2878793          	addi	a5,a5,-1496 # 80025000 <disk+0x2000>
    800065e0:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800065e2:	0001d717          	auipc	a4,0x1d
    800065e6:	a9e70713          	addi	a4,a4,-1378 # 80023080 <disk+0x80>
    800065ea:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800065ec:	0001e717          	auipc	a4,0x1e
    800065f0:	a1470713          	addi	a4,a4,-1516 # 80024000 <disk+0x1000>
    800065f4:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800065f6:	4705                	li	a4,1
    800065f8:	00e78c23          	sb	a4,24(a5)
    800065fc:	00e78ca3          	sb	a4,25(a5)
    80006600:	00e78d23          	sb	a4,26(a5)
    80006604:	00e78da3          	sb	a4,27(a5)
    80006608:	00e78e23          	sb	a4,28(a5)
    8000660c:	00e78ea3          	sb	a4,29(a5)
    80006610:	00e78f23          	sb	a4,30(a5)
    80006614:	00e78fa3          	sb	a4,31(a5)
}
    80006618:	60e2                	ld	ra,24(sp)
    8000661a:	6442                	ld	s0,16(sp)
    8000661c:	64a2                	ld	s1,8(sp)
    8000661e:	6105                	addi	sp,sp,32
    80006620:	8082                	ret
    panic("could not find virtio disk");
    80006622:	00002517          	auipc	a0,0x2
    80006626:	1f650513          	addi	a0,a0,502 # 80008818 <syscalls+0x360>
    8000662a:	ffffa097          	auipc	ra,0xffffa
    8000662e:	f10080e7          	jalr	-240(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    80006632:	00002517          	auipc	a0,0x2
    80006636:	20650513          	addi	a0,a0,518 # 80008838 <syscalls+0x380>
    8000663a:	ffffa097          	auipc	ra,0xffffa
    8000663e:	f00080e7          	jalr	-256(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    80006642:	00002517          	auipc	a0,0x2
    80006646:	21650513          	addi	a0,a0,534 # 80008858 <syscalls+0x3a0>
    8000664a:	ffffa097          	auipc	ra,0xffffa
    8000664e:	ef0080e7          	jalr	-272(ra) # 8000053a <panic>

0000000080006652 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006652:	7119                	addi	sp,sp,-128
    80006654:	fc86                	sd	ra,120(sp)
    80006656:	f8a2                	sd	s0,112(sp)
    80006658:	f4a6                	sd	s1,104(sp)
    8000665a:	f0ca                	sd	s2,96(sp)
    8000665c:	ecce                	sd	s3,88(sp)
    8000665e:	e8d2                	sd	s4,80(sp)
    80006660:	e4d6                	sd	s5,72(sp)
    80006662:	e0da                	sd	s6,64(sp)
    80006664:	fc5e                	sd	s7,56(sp)
    80006666:	f862                	sd	s8,48(sp)
    80006668:	f466                	sd	s9,40(sp)
    8000666a:	f06a                	sd	s10,32(sp)
    8000666c:	ec6e                	sd	s11,24(sp)
    8000666e:	0100                	addi	s0,sp,128
    80006670:	8aaa                	mv	s5,a0
    80006672:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006674:	00c52c83          	lw	s9,12(a0)
    80006678:	001c9c9b          	slliw	s9,s9,0x1
    8000667c:	1c82                	slli	s9,s9,0x20
    8000667e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006682:	0001f517          	auipc	a0,0x1f
    80006686:	aa650513          	addi	a0,a0,-1370 # 80025128 <disk+0x2128>
    8000668a:	ffffa097          	auipc	ra,0xffffa
    8000668e:	546080e7          	jalr	1350(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    80006692:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006694:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006696:	0001dc17          	auipc	s8,0x1d
    8000669a:	96ac0c13          	addi	s8,s8,-1686 # 80023000 <disk>
    8000669e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    800066a0:	4b0d                	li	s6,3
    800066a2:	a0ad                	j	8000670c <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    800066a4:	00fc0733          	add	a4,s8,a5
    800066a8:	975e                	add	a4,a4,s7
    800066aa:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800066ae:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800066b0:	0207c563          	bltz	a5,800066da <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800066b4:	2905                	addiw	s2,s2,1
    800066b6:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    800066b8:	19690c63          	beq	s2,s6,80006850 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    800066bc:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800066be:	0001f717          	auipc	a4,0x1f
    800066c2:	95a70713          	addi	a4,a4,-1702 # 80025018 <disk+0x2018>
    800066c6:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800066c8:	00074683          	lbu	a3,0(a4)
    800066cc:	fee1                	bnez	a3,800066a4 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800066ce:	2785                	addiw	a5,a5,1
    800066d0:	0705                	addi	a4,a4,1
    800066d2:	fe979be3          	bne	a5,s1,800066c8 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800066d6:	57fd                	li	a5,-1
    800066d8:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800066da:	01205d63          	blez	s2,800066f4 <virtio_disk_rw+0xa2>
    800066de:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800066e0:	000a2503          	lw	a0,0(s4)
    800066e4:	00000097          	auipc	ra,0x0
    800066e8:	d92080e7          	jalr	-622(ra) # 80006476 <free_desc>
      for(int j = 0; j < i; j++)
    800066ec:	2d85                	addiw	s11,s11,1
    800066ee:	0a11                	addi	s4,s4,4
    800066f0:	ff2d98e3          	bne	s11,s2,800066e0 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066f4:	0001f597          	auipc	a1,0x1f
    800066f8:	a3458593          	addi	a1,a1,-1484 # 80025128 <disk+0x2128>
    800066fc:	0001f517          	auipc	a0,0x1f
    80006700:	91c50513          	addi	a0,a0,-1764 # 80025018 <disk+0x2018>
    80006704:	ffffc097          	auipc	ra,0xffffc
    80006708:	cca080e7          	jalr	-822(ra) # 800023ce <sleep>
  for(int i = 0; i < 3; i++){
    8000670c:	f8040a13          	addi	s4,s0,-128
{
    80006710:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006712:	894e                	mv	s2,s3
    80006714:	b765                	j	800066bc <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006716:	0001f697          	auipc	a3,0x1f
    8000671a:	8ea6b683          	ld	a3,-1814(a3) # 80025000 <disk+0x2000>
    8000671e:	96ba                	add	a3,a3,a4
    80006720:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006724:	0001d817          	auipc	a6,0x1d
    80006728:	8dc80813          	addi	a6,a6,-1828 # 80023000 <disk>
    8000672c:	0001f697          	auipc	a3,0x1f
    80006730:	8d468693          	addi	a3,a3,-1836 # 80025000 <disk+0x2000>
    80006734:	6290                	ld	a2,0(a3)
    80006736:	963a                	add	a2,a2,a4
    80006738:	00c65583          	lhu	a1,12(a2)
    8000673c:	0015e593          	ori	a1,a1,1
    80006740:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006744:	f8842603          	lw	a2,-120(s0)
    80006748:	628c                	ld	a1,0(a3)
    8000674a:	972e                	add	a4,a4,a1
    8000674c:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006750:	20050593          	addi	a1,a0,512
    80006754:	0592                	slli	a1,a1,0x4
    80006756:	95c2                	add	a1,a1,a6
    80006758:	577d                	li	a4,-1
    8000675a:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000675e:	00461713          	slli	a4,a2,0x4
    80006762:	6290                	ld	a2,0(a3)
    80006764:	963a                	add	a2,a2,a4
    80006766:	03078793          	addi	a5,a5,48
    8000676a:	97c2                	add	a5,a5,a6
    8000676c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    8000676e:	629c                	ld	a5,0(a3)
    80006770:	97ba                	add	a5,a5,a4
    80006772:	4605                	li	a2,1
    80006774:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006776:	629c                	ld	a5,0(a3)
    80006778:	97ba                	add	a5,a5,a4
    8000677a:	4809                	li	a6,2
    8000677c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006780:	629c                	ld	a5,0(a3)
    80006782:	97ba                	add	a5,a5,a4
    80006784:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006788:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    8000678c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006790:	6698                	ld	a4,8(a3)
    80006792:	00275783          	lhu	a5,2(a4)
    80006796:	8b9d                	andi	a5,a5,7
    80006798:	0786                	slli	a5,a5,0x1
    8000679a:	973e                	add	a4,a4,a5
    8000679c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    800067a0:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800067a4:	6698                	ld	a4,8(a3)
    800067a6:	00275783          	lhu	a5,2(a4)
    800067aa:	2785                	addiw	a5,a5,1
    800067ac:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800067b0:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800067b4:	100017b7          	lui	a5,0x10001
    800067b8:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800067bc:	004aa783          	lw	a5,4(s5)
    800067c0:	02c79163          	bne	a5,a2,800067e2 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800067c4:	0001f917          	auipc	s2,0x1f
    800067c8:	96490913          	addi	s2,s2,-1692 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800067cc:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800067ce:	85ca                	mv	a1,s2
    800067d0:	8556                	mv	a0,s5
    800067d2:	ffffc097          	auipc	ra,0xffffc
    800067d6:	bfc080e7          	jalr	-1028(ra) # 800023ce <sleep>
  while(b->disk == 1) {
    800067da:	004aa783          	lw	a5,4(s5)
    800067de:	fe9788e3          	beq	a5,s1,800067ce <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800067e2:	f8042903          	lw	s2,-128(s0)
    800067e6:	20090713          	addi	a4,s2,512
    800067ea:	0712                	slli	a4,a4,0x4
    800067ec:	0001d797          	auipc	a5,0x1d
    800067f0:	81478793          	addi	a5,a5,-2028 # 80023000 <disk>
    800067f4:	97ba                	add	a5,a5,a4
    800067f6:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800067fa:	0001f997          	auipc	s3,0x1f
    800067fe:	80698993          	addi	s3,s3,-2042 # 80025000 <disk+0x2000>
    80006802:	00491713          	slli	a4,s2,0x4
    80006806:	0009b783          	ld	a5,0(s3)
    8000680a:	97ba                	add	a5,a5,a4
    8000680c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006810:	854a                	mv	a0,s2
    80006812:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006816:	00000097          	auipc	ra,0x0
    8000681a:	c60080e7          	jalr	-928(ra) # 80006476 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000681e:	8885                	andi	s1,s1,1
    80006820:	f0ed                	bnez	s1,80006802 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006822:	0001f517          	auipc	a0,0x1f
    80006826:	90650513          	addi	a0,a0,-1786 # 80025128 <disk+0x2128>
    8000682a:	ffffa097          	auipc	ra,0xffffa
    8000682e:	45a080e7          	jalr	1114(ra) # 80000c84 <release>
}
    80006832:	70e6                	ld	ra,120(sp)
    80006834:	7446                	ld	s0,112(sp)
    80006836:	74a6                	ld	s1,104(sp)
    80006838:	7906                	ld	s2,96(sp)
    8000683a:	69e6                	ld	s3,88(sp)
    8000683c:	6a46                	ld	s4,80(sp)
    8000683e:	6aa6                	ld	s5,72(sp)
    80006840:	6b06                	ld	s6,64(sp)
    80006842:	7be2                	ld	s7,56(sp)
    80006844:	7c42                	ld	s8,48(sp)
    80006846:	7ca2                	ld	s9,40(sp)
    80006848:	7d02                	ld	s10,32(sp)
    8000684a:	6de2                	ld	s11,24(sp)
    8000684c:	6109                	addi	sp,sp,128
    8000684e:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006850:	f8042503          	lw	a0,-128(s0)
    80006854:	20050793          	addi	a5,a0,512
    80006858:	0792                	slli	a5,a5,0x4
  if(write)
    8000685a:	0001c817          	auipc	a6,0x1c
    8000685e:	7a680813          	addi	a6,a6,1958 # 80023000 <disk>
    80006862:	00f80733          	add	a4,a6,a5
    80006866:	01a036b3          	snez	a3,s10
    8000686a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    8000686e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006872:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006876:	7679                	lui	a2,0xffffe
    80006878:	963e                	add	a2,a2,a5
    8000687a:	0001e697          	auipc	a3,0x1e
    8000687e:	78668693          	addi	a3,a3,1926 # 80025000 <disk+0x2000>
    80006882:	6298                	ld	a4,0(a3)
    80006884:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006886:	0a878593          	addi	a1,a5,168
    8000688a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000688c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000688e:	6298                	ld	a4,0(a3)
    80006890:	9732                	add	a4,a4,a2
    80006892:	45c1                	li	a1,16
    80006894:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006896:	6298                	ld	a4,0(a3)
    80006898:	9732                	add	a4,a4,a2
    8000689a:	4585                	li	a1,1
    8000689c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800068a0:	f8442703          	lw	a4,-124(s0)
    800068a4:	628c                	ld	a1,0(a3)
    800068a6:	962e                	add	a2,a2,a1
    800068a8:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    800068ac:	0712                	slli	a4,a4,0x4
    800068ae:	6290                	ld	a2,0(a3)
    800068b0:	963a                	add	a2,a2,a4
    800068b2:	058a8593          	addi	a1,s5,88
    800068b6:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800068b8:	6294                	ld	a3,0(a3)
    800068ba:	96ba                	add	a3,a3,a4
    800068bc:	40000613          	li	a2,1024
    800068c0:	c690                	sw	a2,8(a3)
  if(write)
    800068c2:	e40d1ae3          	bnez	s10,80006716 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800068c6:	0001e697          	auipc	a3,0x1e
    800068ca:	73a6b683          	ld	a3,1850(a3) # 80025000 <disk+0x2000>
    800068ce:	96ba                	add	a3,a3,a4
    800068d0:	4609                	li	a2,2
    800068d2:	00c69623          	sh	a2,12(a3)
    800068d6:	b5b9                	j	80006724 <virtio_disk_rw+0xd2>

00000000800068d8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800068d8:	1101                	addi	sp,sp,-32
    800068da:	ec06                	sd	ra,24(sp)
    800068dc:	e822                	sd	s0,16(sp)
    800068de:	e426                	sd	s1,8(sp)
    800068e0:	e04a                	sd	s2,0(sp)
    800068e2:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800068e4:	0001f517          	auipc	a0,0x1f
    800068e8:	84450513          	addi	a0,a0,-1980 # 80025128 <disk+0x2128>
    800068ec:	ffffa097          	auipc	ra,0xffffa
    800068f0:	2e4080e7          	jalr	740(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800068f4:	10001737          	lui	a4,0x10001
    800068f8:	533c                	lw	a5,96(a4)
    800068fa:	8b8d                	andi	a5,a5,3
    800068fc:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800068fe:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006902:	0001e797          	auipc	a5,0x1e
    80006906:	6fe78793          	addi	a5,a5,1790 # 80025000 <disk+0x2000>
    8000690a:	6b94                	ld	a3,16(a5)
    8000690c:	0207d703          	lhu	a4,32(a5)
    80006910:	0026d783          	lhu	a5,2(a3)
    80006914:	06f70163          	beq	a4,a5,80006976 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006918:	0001c917          	auipc	s2,0x1c
    8000691c:	6e890913          	addi	s2,s2,1768 # 80023000 <disk>
    80006920:	0001e497          	auipc	s1,0x1e
    80006924:	6e048493          	addi	s1,s1,1760 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006928:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000692c:	6898                	ld	a4,16(s1)
    8000692e:	0204d783          	lhu	a5,32(s1)
    80006932:	8b9d                	andi	a5,a5,7
    80006934:	078e                	slli	a5,a5,0x3
    80006936:	97ba                	add	a5,a5,a4
    80006938:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000693a:	20078713          	addi	a4,a5,512
    8000693e:	0712                	slli	a4,a4,0x4
    80006940:	974a                	add	a4,a4,s2
    80006942:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006946:	e731                	bnez	a4,80006992 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006948:	20078793          	addi	a5,a5,512
    8000694c:	0792                	slli	a5,a5,0x4
    8000694e:	97ca                	add	a5,a5,s2
    80006950:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006952:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006956:	ffffc097          	auipc	ra,0xffffc
    8000695a:	c04080e7          	jalr	-1020(ra) # 8000255a <wakeup>

    disk.used_idx += 1;
    8000695e:	0204d783          	lhu	a5,32(s1)
    80006962:	2785                	addiw	a5,a5,1
    80006964:	17c2                	slli	a5,a5,0x30
    80006966:	93c1                	srli	a5,a5,0x30
    80006968:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000696c:	6898                	ld	a4,16(s1)
    8000696e:	00275703          	lhu	a4,2(a4)
    80006972:	faf71be3          	bne	a4,a5,80006928 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006976:	0001e517          	auipc	a0,0x1e
    8000697a:	7b250513          	addi	a0,a0,1970 # 80025128 <disk+0x2128>
    8000697e:	ffffa097          	auipc	ra,0xffffa
    80006982:	306080e7          	jalr	774(ra) # 80000c84 <release>
}
    80006986:	60e2                	ld	ra,24(sp)
    80006988:	6442                	ld	s0,16(sp)
    8000698a:	64a2                	ld	s1,8(sp)
    8000698c:	6902                	ld	s2,0(sp)
    8000698e:	6105                	addi	sp,sp,32
    80006990:	8082                	ret
      panic("virtio_disk_intr status");
    80006992:	00002517          	auipc	a0,0x2
    80006996:	ee650513          	addi	a0,a0,-282 # 80008878 <syscalls+0x3c0>
    8000699a:	ffffa097          	auipc	ra,0xffffa
    8000699e:	ba0080e7          	jalr	-1120(ra) # 8000053a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
