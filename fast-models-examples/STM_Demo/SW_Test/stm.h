/*
 * STM Example
 *
 * Copyright (c) 2015-2016 ARM, Inc.  All rights reserved.
 *
 */

#if !defined(__STM_H)
#define __STM_H

typedef unsigned int			STM_RO;
typedef volatile STM_RO 		STM_RW;
typedef STM_RW					STM_NA;
typedef volatile unsigned long	STM_STIM;

struct stmDMA;
struct stmHE;

#define TRACEID_MASK			(0x7f)
#define TRACEID_SHIFT			(16)

struct stmAPB {
	STM_RW STMSTIMR[32];
	STM_NA RSVD_0[608];
	STM_NA IMPDEF[4][64];
	STM_RW STMSPER;
	STM_NA RSVD_2[7];
	STM_RW STMSPTER;
	STM_NA RSVD_3[7];
	STM_RW STMPRIVMASKR;
	STM_NA RSVD_4[7];
	STM_RW STMSPSCR;
	STM_RW STMSPMSCR;
	STM_RW STMSPOVERRIDER;
	STM_RW STMSPMOVERRIDER;
	STM_RW STMSPTRIGCSR;
	STM_NA RSVD_5[3];
	STM_RW STMTCSR;
#define STMTCSR_EN		(1 << 0)
#define STMTCSR_TSEN	(1 << 1)
#define STMTCSR_SYNCEN	(1 << 2)
#define STMTCSR_HWTEN	(1 << 3)
#define STMTCSR_COMPEN	(1 << 5)
#define STMTCSR_BUSY	(1 << 23)
	STM_RW STMTSSTIMR;
	STM_NA RSVD_6;
	STM_RW STMTSFREQR;
	STM_RW STMSYNCR;
	STM_RW STMAUXCR;
	STM_NA RSVD_7[2];
	STM_RO STMFEAT1R;
#define STMFEAT1_TS				(1 << 4)
#define STMFEAT1_TS_DIFF		(0 << 4)
#define STMFEAT1_TS_ABS			(1 << 4)
#define STMFEAT1_TS_NOIMPL		(2 << 4)
#define STMFEAT1_TS_RSVD		(3 << 4)
#define STMFEAT1_TSFREQ			(1 << 6)
#define STMFEAT1_FORCETS		(1 << 7)
#define STMFEAT1_SYNCR			(3 << 8)
#define STMFEAT1_SYNCR_UNDEF	(0 << 0)
#define STMFEAT1_SYNCR_NOIMPL	(1 << 8)
#define STMFEAT1_SYNCR_NOMODE	(2 << 8)
#define STMFEAT1_SYNCR_OKMODE	(3 << 8)
#define STMFEAT1_HWTEN			(3 << 18)
#define STMFEAT1_HWTEN_UNDEF	(0 << 18)
#define STMFEAT1_HWTEN_NOIMPL	(1 << 18)
#define STMFEAT1_HWTEN_OK		(2 << 18)
#define STMFEAT1_HWTEN_RSVD		(3 << 18)
#define STMFEAT1_SYNCEN			(3 << 20)
#define STMFEAT1_SYNCEN_UNDEF	(0 << 20)
#define STMFEAT1_SYNCEN_NOIMPL	(1 << 20)
#define STMFEAT1_SYNCEN_ALWAYS	(2 << 20)
#define STMFEAT1_SYNCEN_OK		(3 << 20)
	STM_RO STMFEAT2R;
#define STMFEAT2_SPTER			(3 << 0)
#define STMFEAT2_SPTER_UNDEF	(0 << 0)
#define STMFEAT2_SPTER_NOIMPL	(1 << 0)
#define STMFEAT2_SPTER_OK		(2 << 0)
#define STMFEAT2_SPER			(1 << 2)
#define STMFEAT2_SPER_OK		(0 << 2)
#define STMFEAT2_SPER_NOIMPL	(1 << 2)
#define STMFEAT2_SPCOMP			(3 << 4)
#define STMFEAT2_SPCOMP_UNDEF	(0 << 4)
#define STMFEAT2_SPCOMP_NOIMPL	(1 << 4)
#define STMFEAT2_SPCOMP_ALWAYS  (2 << 4)
#define STMFEAT2_SPCOMP_OK		(3 << 4)
	STM_RO STMFEAT3R;
	STM_RO RSVD_8[15];
	union {
		STM_NA RSVD[6];
		struct STM_IT {
			STM_RW STMITTRIGGER;
			STM_RW STMITATBDATA0;
			STM_RW STMITATBCTR2;
			STM_RW STMITATBID;
			STM_RW STMITATBCTR0;
			STM_NA RSVD;
		} STMIT;
	} RSVD_9;
	STM_RW STMITCTRL;
	STM_NA RSVD_A[39];
	STM_RW STMCLAIMSET;
	STM_RW STMCLAIMCLR;
	STM_NA RSVD_B[2];
	STM_RW STMLAR;
#define STMLAR_UNLOCK	(0xc5acce55)
#define STMLAR_LOCK		(0x00000000)
	STM_RW STMLSR;
#define STMLSR_SLI		(1 << 0)
#define STMLSR_SLK		(1 << 1)
	STM_RW STMAUTHSTATUS;
	STM_RO STMDEVARCH;
	STM_RO RSVD_C[2];
	STM_RO STMDEVID;
	STM_RO STMDEVTYPE;
	STM_RO STMPIDR[8];
	STM_RO STMCIDR[4];
};

struct stmPort {
	STM_STIM	G_DMTS;
	STM_STIM	G_DM;
	STM_STIM	G_DTS;
	STM_STIM	G_D;
	STM_NA		G_reserved[16];

	STM_STIM	G_FLAGTS;
	STM_STIM	G_FLAG;
	STM_STIM	G_TRIGTS;
	STM_STIM	G_TRIG;

	STM_STIM	I_DMTS;
	STM_STIM	I_DM;
	STM_STIM	I_DTS;
	STM_STIM	I_D;
	STM_NA		I_reserved[16];

	STM_STIM	I_FLAGTS;
	STM_STIM	I_FLAG;
	STM_STIM	I_TRIGTS;
	STM_STIM	I_TRIG;
};

/* Implementation defined controls from STM Architecture v1.1 */

struct stmDMA {
	STM_NA RSVD_0;
	STM_RW STMDMASTARTR;
	STM_RW STMDMASTOPR;
	STM_RW STMDMASTATR;
	STM_RW STMDMACTLR;
	STM_NA RSVD_1[58];
	STM_RW STMDMAIDR;
};

struct stmHE {
	STM_RW STMHEERR;
	STM_NA RSVD_0[7];
	STM_RW STMHETER;
	STM_NA RSVD_1[15];
	STM_RW STMHEBSR;	/* NOTE: not present in Standard HE v1.0 */
	STM_RW STMHEMCR;
	STM_RW STMHEEXTMUXR;
	STM_NA RSVD_2[34];
	STM_RW STMHEMASTR;
	STM_RO STMHEFEAT1R;
#define STMHEFEAT1_HETER	(1 << 0)
#define STMHEFEAT1_HEERR	(1 << 2)
#define STMHEFEAT1_HECOMP	(3 << 4)
	STM_RO STMHEIDR;
};

/*
 * STM AXI Stimulus Interface
 *
 * The STM Architecture defines up to 65536 stimulus ports, all of which are
 * implemented on the STM and STM-500 from ARM, Ltd.
 */
struct stmAXI {
	/*
	 * access the port array based on the limit in
	 * (stmAPB->STMDEVID & 0x1fff) so nothing we
	 * can define at compile time..
	 */
	struct stmPort port[0];
};

struct STM {
	struct stmAPB *APB;
	struct stmAXI *AXI;

	struct stmDMA *DMA;
	struct stmHE  *HE;
	void		  *unused0;
	void		  *unused1;

	/* Feature Register Cache */
	unsigned int DEVARCH;
	unsigned int DEVID;
	unsigned int FEAT1R;
	unsigned int FEAT2R;
	unsigned int FEAT3R;
	unsigned int IMPDEFIDR[4];
	unsigned int HEFEAT1R;

	unsigned int NumPorts;
	unsigned int DSize;
};

extern struct STM *gSTM;

/*
 * STMn(port, class)
 *
 * Write an n-byte value to a stimulus port of a particular type (e.g. G_DMTS)
 */
#define STM8(a, p, type)  *((volatile unsigned char *) &((a)->port[p].type))
#define STM16(a, p, type) *((volatile unsigned short *) &((a)->port[p].type))
#define STM32(a, p, type) *((volatile unsigned int *) &((a)->port[p].type))
#define STM64(a, p, type) *((volatile unsigned long *) &((a)->port[p].type))

/*
 * unsigned long stmPortAddress(unsigned long base, unsigned int port, unsigned int flags)
 *
 * If you want to access the stimulus ports without the stmAXI structure and
 * without using the above macros, then you can generate an offset address using
 * stmPortAddress().
 *
 * Flags that are also address bits
 */
#define __GUARANTEED	(1 << 7)
#define __NONDATA		(3 << 5)
#define __MARKED		(1 << 4)
#define __TRIGGERnFLAG	(1 << 4)
#define __TIMESTAMPED 	(1 << 3)

/*
 * these are ONLY flags not address bits
 */
#define INVARIANT	(1 << 0)
#define FLAG		(1 << 1)
#define TRIGGER		(1 << 2)
#define TIMESTAMPED __TIMESTAMPED
#define MARKED		__MARKED
#define GUARANTEED	__GUARANTEED

extern unsigned long stmPortAddress(unsigned long base, unsigned int port, unsigned int flags);
extern void stmInit(struct STM *stm, struct stmAPB *apb, struct stmAXI *axi);
extern void stmSendString(struct STM *stm, unsigned int channel, const char *string);


/*
 * Required
 *
 * Timestamp frequency is more a hint to trace decoders
 * than any functional change in the STM itself. It allows
 * conversion of the output TS packets from raw binary
 * to hh:mm:ss.
 *
 * The frequency of sync generation will be handled in
 * hardware but its behaviour is somewhat undefined. By
 * starting trace you will get an ASYNC packet, but we
 * want it to be regular in case our output buffer wraps.
 *
 * By giving these values we get more predictable trace
 * decode.
 */
#   define  CONFIG_STM_TIMESTAMP_FREQUENCY  100000000L
#   define  CONFIG_STM_SYNC_FREQUENCY       1024

/*
 * Optional
 *
 * Compression is optional.
 *
 * Setting the Trace ID is *not* optional, but the
 * responsibility of setting it could be to the software
 * or an external debugger. Therefore, we only set the
 * value if an external debugger is not going to do it
 * for us.
 */
#   define  CONFIG_STM_USE_COMPRESSION  1
#   define  CONFIG_STM_USE_TRACEID      16

int stm_fputc(struct STM *stm, int c, FILE *f);

#endif /* !defined(__STM_H_) */
