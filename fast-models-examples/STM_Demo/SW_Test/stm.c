/*
 * STM Example
 *
 * Copyright (c) 2015-2016 ARM, Inc.  All rights reserved.
 *
 */

#include<stdio.h>
#include "stm.h"

/*
 * Coresight Lock Access
 */
void stmUnlock(struct STM *stm)
{
	/*
	 * Only unlock if locks are required.
	 *
	 * Technically this would be true of any
	 * APB transaction that didn't come through
	 * the CoreSight DAP..
	 */
	if (stm->APB->STMLSR & STMLSR_SLI)
	{
		stm->APB->STMLAR = STMLAR_UNLOCK;
		while ((stm->APB->STMLSR & STMLSR_SLK) == STMLSR_SLK);
			// wait for unlock to be reflected
	}
}

void stmLock(struct STM *stm)
{
	/*
	 * Only lock if locks are required.
	 */
	if (stm->APB->STMLSR & STMLSR_SLI)
	{
		/* and not already locked.. */
		if (!(stm->APB->STMLSR & STMLSR_SLK))
		{
			stm->APB->STMLAR = STMLAR_LOCK;
			while ((stm->APB->STMLSR & STMLSR_SLK) == 0x0);
				// wait for lock to be reflected
		}
	}
}

static void stmTCSRSet(struct STM *stm, unsigned int flags)
{
	stm->APB->STMTCSR = (stm->APB->STMTCSR | flags);
}

static void stmTCSRClr(struct STM *stm, unsigned int flags)
{
	stm->APB->STMTCSR = (stm->APB->STMTCSR & (~flags));
}


/*
 * Enable STM tracing
 */

void stmEnable(struct STM *stm)
{
	stmTCSRSet(stm, STMTCSR_EN);
}

void stmDisable(struct STM *stm)
{
	/*
	 * STM Architecture Spec v1.1 (IHI00054B) 2.3.10:
	 * ~~
	 * To ensure that all writes to the STM stimulus ports are traced
	 * before disabling the STM, ARM recommends that software writes
	 * to the stimulus port then reads from any stimulus port before
	 * clearing STMTCSR.EN. This is only required if the same piece of
	 * software is writing to the stimulus ports and disabling the STM.
	 * ~~
	 *
	 * Technically.. we might want a DSB barrier here too..
	 */
	volatile unsigned int dummy = STM32(stm->AXI, 0, G_FLAG);

	stmTCSRClr(stm, STMTCSR_EN);
}

/*
 * Configuration helpers
 */

void stmWaitForIdle(struct STM *stm)
{
	while (stm->APB->STMTCSR & STMTCSR_BUSY);
}

unsigned int stmSynchronization(struct STM *stm, unsigned int en)
{
	switch (stm->FEAT1R & STMFEAT1_SYNCEN) {
		case STMFEAT1_SYNCEN_OK:
			if (en) {
				stmTCSRSet(stm, STMTCSR_SYNCEN);
			} else {
				stmTCSRClr(stm, STMTCSR_SYNCEN);
			}
			return en;

		/*
		 * Periodic sync might be always enabled, or not
		 * available, in which case we just return the
		 * current state
		 */
		case STMFEAT1_SYNCEN_ALWAYS:
			return 1;

		case STMFEAT1_SYNCEN_NOIMPL:
		default:
			return 0;
	}
}

unsigned int stmCompression(struct STM *stm, unsigned int en)
{
	unsigned int spcomp = stm->FEAT2R & STMFEAT2_SPCOMP;

	switch (spcomp) {
		case STMFEAT2_SPCOMP_OK:
			if (en) {
				stmTCSRSet(stm, STMTCSR_COMPEN);
			} else {
				stmTCSRClr(stm, STMTCSR_COMPEN);
			}
			return en;

		/*
		 * Compression might be always enabled, or not
		 * available, in which case we just return the
		 * current state
		 */
		case STMFEAT2_SPCOMP_ALWAYS:
			return 1;

		case STMFEAT2_SPCOMP_NOIMPL:
		default:
			return 0;
	}
}

unsigned int stmTimestamping(struct STM *stm, unsigned int en)
{
	/*
	 * Timestamping not supported -- don't do anything
	 */
	if ((stm->FEAT1R & STMFEAT1_TS) == STMFEAT1_TS_NOIMPL)
		return 0;

	/*
	 *  Timestamping is supported but we don't care if they're
	 * differential or absolute.. just enable it per request
	 */
	if (en) {
		stmTCSRSet(stm, STMTCSR_TSEN);
	} else {
		stmTCSRClr(stm, STMTCSR_TSEN);
	}

	return en;
}

/*
 * stmTRACEID(stm, traceid)
 *
 * Set STM's TRACEID (which goes out over ATB bus ATBID)
 *
 * Note it is illegal per CoreSight to set the trace ID
 * to 0x00 or one of the reserved values (0x70 onwards)
 * (see IHI0029D D4.2.4 Special trace source IDs).
 *
 * This function doesn't do anything if you pass one of
 * those values, and will return 0 for an invalid value..
 */
unsigned int stmTRACEID(struct STM *stm, unsigned int traceid)
{
	unsigned int tcsr;
	unsigned int current_traceid;

	tcsr = stm->APB->STMTCSR;
	current_traceid = ((tcsr >> TRACEID_SHIFT) & TRACEID_MASK);

	if ((traceid > 0x00) && (traceid < 0x70)) {
		/*
		 * We try not to corrupt the Trace ID if it's already
		 * valid -- it implies someone already set it up, either
		 * an external debugger or previous software.
		 *
		 * So, if we got a Trace ID that's in the valid range,
		 * and the Trace ID is currently invalid, set it,
		 * otherwise try not to do anything.
		 */
		if (!current_traceid) {
			traceid = traceid & TRACEID_MASK;
			tcsr = (stm->APB->STMTCSR & ~(TRACEID_MASK << TRACEID_SHIFT));
			stm->APB->STMTCSR = (tcsr | (traceid << TRACEID_SHIFT));

			return traceid;
		}
	}

	return current_traceid;
}

/*
 * stmHEDisableAll(stm)
 *
 * Disables HW Event tracing -- note that there is also a
 * STMTCSR.HWTEN bit which would globally disable this, but on
 * ARM's STM when synthesized for HW Event Trace, it's not
 * implemented.
 *
 * For now we're assuming that there are only 32 events (we
 * ignore the value of STMHEFEAT1R.NUMHE) and just check to
 * see if the STMHEERR and STMHETER registers exist so we
 * can disable the events.
 */
void stmHEDisableEventsAll(struct STM *stm)
{
	if ((stm->FEAT1R & STMFEAT1_HWTEN) == STMFEAT1_HWTEN_NOIMPL) {
		if (stm->HE) {
			stm->HE->STMHEBSR = 0x00000000;

			if (stm->HEFEAT1R & STMHEFEAT1_HEERR)
				stm->HE->STMHEERR = 0x00000000;

			if (stm->HEFEAT1R & STMHEFEAT1_HETER)
				stm->HE->STMHETER = 0x00000000;
		}
	} else {
		if ((stm->FEAT1R & STMFEAT1_HWTEN) == STMFEAT1_HWTEN_OK) {
			stmTCSRClr(stm, STMTCSR_HWTEN);
		}
	}
}


void stmHEEnable(struct STM *stm)
{
	if (stm->HE)
		stm->HE->STMHEMCR = (stm->HE->STMHEMCR | 0x1);
}

void stmHEDisable(struct STM *stm)
{
	if (stm->HE)
		stm->HE->STMHEMCR = (stm->HE->STMHEMCR & ~(0x1));
}

unsigned int stmNumStimulusPorts(struct STM *stm)
{
	return (stm->DEVID & 0x1ffff);
}

unsigned int stmEnablePortsAll(struct STM *stm)
{
	if (1) {
		/*
		 * Set STMPSCR.PORTCTL to 0x0 to ensure port selection is not
		 * used. STMPSCR.PORTSEL is ignored and STMSPER and STMSPTER
		 * bits apply equally to all groups of ports.
		 *
		 * Whether the STM has 32 or 65536 ports, they'll all be
		 * enabled.
		 */
		stm->APB->STMSPSCR = 0x00000000;
	} else {
		/* Alternatively:
		 *
		 * Set STMPSCR.PORTCTL to 0x3 to ensure the port selection
		 * applies to both STMSPER and STMSPTER.
		 *
		 * Set STMPSCR.PORTSEL to 0x800 which selects all stimulus
		 * port groups in the same way that STMPSCR.PORTCTL = 0x0
		 * would effect.
		 */
		stm->APB->STMSPSCR = 0x80000003;
	}

	if ((stm->FEAT2R & STMFEAT2_SPER) == STMFEAT2_SPER_OK)
		stm->APB->STMSPER = 0xffffffff;

	if ((stm->FEAT2R & STMFEAT2_SPTER) == STMFEAT2_SPTER_OK)
		stm->APB->STMSPTER = 0xffffffff;

	return stmNumStimulusPorts(stm);
}

unsigned int stmDisablePortsAll(struct STM *stm)
{
	stm->APB->STMSPSCR = 0x00000000;

	if ((stm->FEAT2R & STMFEAT2_SPER) == STMFEAT2_SPER_OK)
		stm->APB->STMSPER = 0x00000000;

	if ((stm->FEAT2R & STMFEAT2_SPTER) == STMFEAT2_SPTER_OK)
		stm->APB->STMSPTER = 0x00000000;

	return stmNumStimulusPorts(stm);
}


/*
 * stmSetTimestampFrequency(stm, freq)
 *
 * Inform trace decoders of the timestamp counter frequency, by
 * way of correctly generating FREQ and FREQ_TS packets. Configuring
 * this register is not optional if it is writable!
 */

void stmSetTimestampFrequency(struct STM *stm, unsigned int freq)
{
	if (stm->FEAT1R & STMFEAT1_TSFREQ) {
		stm->APB->STMTSFREQR = freq;
	}
}

/*
 * stmForceTimestamp(stm)
 *
 * If possible, use the STMTSSTIMR register to force output of a
 * Timestamp packet, usually by upgrading an existing data packet,
 * for instance D32M -> D32MTS.
 *
 * If STMTCSR.TSEN is 0 then nothing will happen.
 */

void stmForceTimestamp(struct STM *stm)
{
	if (stm->FEAT1R & STMFEAT1_FORCETS)
		stm->APB->STMTSSTIMR = 1;
}

/*
 * stmSetSyncFrequency(stm, bytes)
 *
 * Request the STM periodically output an ASYNC packet every "bytes"
 * of trace output. This will only have an effect if STMTCSR.SYNCEN
 * is enabled, if implemented.
 */

void stmSetSyncFrequency(struct STM *stm, unsigned int bytes)
{
	/* We only support setting it in bytes.. */
	if ((stm->FEAT1R & STMFEAT1_SYNCR) > STMFEAT1_SYNCR_NOMODE) {
		stm->APB->STMSYNCR = (bytes & 0xfff);
	}
}

/*
 * stmInitFeatures(stm)
 *
 * Keep caches of the feature registers in the STM structure so that
 * when we read them we're just doing Normal memory accesses and not
 * going out to the APB control interface. These registers never
 * change, so a Device memory access to them is slow and unecessary.
 *
 * Perform a run through on all the feature registers we can get a
 * hold on, and fix them up so they have "reasonable" values, that
 * way we can check for features without being too complicated
 * later.
 *
 *
 * Some of the feature checks require STMTCSR.EN to be disabled, so
 * this has to be called really very early..
 */

void stmInitFeatures(struct STM *stm)
{
	unsigned int i;

	stm->FEAT1R = stm->APB->STMFEAT1R;
	stm->FEAT2R = stm->APB->STMFEAT2R;
	stm->FEAT3R = stm->APB->STMFEAT3R;
	stm->DEVARCH = stm->APB->STMDEVARCH;
	stm->DEVID = stm->APB->STMDEVID;
	stm->HE = (void *) 0L;
	stm->HEFEAT1R = 0;
	stm->DMA = (void *) 0L;

	stm->NumPorts = 65536;
	stm->DSize = ((stm->FEAT2R & 0xF000) >> 12) ? 64 : 32;

	for (i = 0; i <= 3; i++) {
		/* Go over all the STM IMPDEF blocks, save the IDR and find HE and DMA control */
		unsigned int class;

		stm->IMPDEFIDR[i] = stm->APB->IMPDEF[3-i][63];
		class = stm->IMPDEFIDR[i] & 0xF;

		switch (class) {
			case 0x1:
				stm->HE = (struct stmHE *) ((&stm->APB->IMPDEF[3-i][0]));
				stm->HEFEAT1R = stm->HE->STMHEFEAT1R;
				break;
			case 0x2:
				stm->DMA = (struct stmDMA *) ((&stm->APB->IMPDEF[3-i][0]));
				break;
		}
	}

	/* Fix up timestamping */
	if ((stm->FEAT1R & STMFEAT1_TS) == STMFEAT1_TS_RSVD) {
		/* Fix up an undefined value as "not implemented" */
		stm->FEAT1R = ( (stm->FEAT1R & (~STMFEAT1_TS)) | STMFEAT1_TS_NOIMPL );
	}

	/* Fix up Synchronization support */
	if ((stm->FEAT1R & STMFEAT1_SYNCR) == STMFEAT1_SYNCR_UNDEF)
	{
		/*
		 * STMSYNCR support is defined by the SYNCR reacting to a write.
		 */
		unsigned int syncf = (stm->FEAT1R & (~STMFEAT1_SYNCR));
		unsigned int syncr;

		stm->APB->STMSYNCR = 0x00001fff;
		syncr = stm->APB->STMSYNCR;

		if (syncr == 0x00001fff) {
			stm->FEAT1R = syncf | STMFEAT1_SYNCR_OKMODE;
		} else if (syncr == 0x00000fff) {
			stm->FEAT1R = syncf | STMFEAT1_SYNCR_NOMODE;
		} else {
			stm->FEAT1R = syncf | STMFEAT1_SYNCR_NOIMPL;
		}
	}

	if ((stm->FEAT1R & STMFEAT1_SYNCR) > STMFEAT1_SYNCR_NOMODE)
	{
		/*
		 *  if STMSYNCR exists then STMTCSR.SYNCEN is always 1
		 *  (STMTCSR note c)
		 */
		stm->FEAT1R = (stm->FEAT1R & (~STMFEAT1_SYNCEN)) | STMFEAT1_SYNCEN_ALWAYS;
	}
	else if ((stm->FEAT1R & STMFEAT1_SYNCEN) == STMFEAT1_SYNCEN_UNDEF)
	{
		/*
		 * SYNCEN support is defined by the TCSR reacting to a write,
		 * so perform that test write and fix up stm->FEAT1R to reflect
		 * whether it's programmable or not..
		 */
		stm->APB->STMTCSR = stm->APB->STMTCSR | STMTCSR_SYNCEN;
		if (stm->APB->STMTCSR & STMTCSR_SYNCEN) {
			stm->FEAT1R = (stm->FEAT1R & (~STMFEAT1_SYNCEN)) | STMFEAT1_SYNCEN_OK;
		}
	}

	/* Fix up Hardware Trace Enable support */
	if ((stm->FEAT1R & STMFEAT1_HWTEN) == STMFEAT1_HWTEN_UNDEF)
	{
		/*
		 * HWTEN support is defined by the TCSR reacting to a write.
		 */
		stm->APB->STMTCSR = stm->APB->STMTCSR | STMTCSR_HWTEN;
		if ((stm->APB->STMTCSR & STMTCSR_HWTEN))
			stm->FEAT1R = (stm->FEAT1R & (~STMFEAT1_HWTEN)) | STMFEAT1_HWTEN_OK;
	}
	else if ((stm->FEAT1R & STMFEAT1_HWTEN) == STMFEAT1_HWTEN_RSVD)
	{
		/*
		 * Fix up an undefined value as "not implemented"
		 */
		stm->FEAT1R = (stm->FEAT1R & (~STMFEAT1_HWTEN)) | STMFEAT1_HWTEN_NOIMPL;
	}

	/* Fix up Compression support */
	if ((stm->FEAT2R & STMFEAT2_SPCOMP) == STMFEAT2_SPCOMP_UNDEF)
	{
		/*
		 * COMPEN support is defined by the TCSR reacting to a write,
		 * so perform that test write and fix up stm->FEAT1R to reflect
		 * whether it's programmable or not..
		 */
		stm->APB->STMTCSR = stm->APB->STMTCSR | STMTCSR_COMPEN;
		if (stm->APB->STMTCSR & STMTCSR_COMPEN)
			stm->FEAT2R = (stm->FEAT2R & (~STMFEAT2_SPCOMP)) | STMFEAT2_SPCOMP_OK;
	}

	/* Fix up SPTER support */
	if ((stm->FEAT2R & STMFEAT2_SPTER) == STMFEAT2_SPTER_UNDEF)
	{
		/*
		 * Presence of STMSPTER is defined by STMSPTER reacting to
		 * a write -- test it and fix up stm->FEAT2R to reflect the
		 * result
		 */
		stm->APB->STMSPTER = 0xffffffff;
		if (stm->APB->STMSPTER > 0) {
			stm->FEAT2R = (stm->FEAT2R & (~STMFEAT2_SPTER)) | STMFEAT2_SPTER_OK;
		}
	}
}

/*
 * Platform code needs to allocate and fill in a struct STM
 * with pointers to the base address for APB and AXI memory
 * regions.
 *
 * See stm_retarget.c for usage of gSTM and fputc impl.
 */

void stmInit(struct STM *stm, struct stmAPB *apb, struct stmAXI *axi)
{
	unsigned int tcsrflags;
	unsigned int i;

	stm->APB = apb;
	stm->AXI = axi;

	/*
	 * Toggle the Lock Access register and disable the STM
	 * for the time being
	 */

	stmUnlock(stm);
	stmDisable(stm);
	stmWaitForIdle(stm);

	stmInitFeatures(stm);

	stmHEDisableEventsAll(stm);
	stmHEDisable(stm);

	stmSetTimestampFrequency(stm, CONFIG_STM_TIMESTAMP_FREQUENCY);
	stmTimestamping(stm, 1);

	stmSetSyncFrequency(stm, CONFIG_STM_SYNC_FREQUENCY);
	stmSynchronization(stm, 1);

	stmCompression(stm, CONFIG_STM_USE_COMPRESSION);

#if defined(CONFIG_STM_USE_TRACEID)
	/* STM Architecture Spec v1.1 (IHI00054B) 2.3.10:
	 * ~~
	 * To avoid trace stream corruption, the STM must be disabled with
	 * STMTCSR.EN == 0b0 and the STMTCSR.BUSY bit polled until it is 0b0
	 * before STMTCSR.TRACEID is modified.
	 * ~~
	 * We already disabled the STMTCSR.EN bit and stmWaitForIdle() will
	 * wait for STMTCSR.BUSY to be 0.
	 */
	stmWaitForIdle(stm);
	stmTRACEID(stm, CONFIG_STM_USE_TRACEID);
#endif

	stmEnablePortsAll(stm);

	stmEnable(stm);
}

void stmUninit(struct STM *stm)
{
	stmDisable(stm);
	stmWaitForIdle(stm);
	stmLock(stm);
}

/*
 *
 * address = stmPortAddress(base, port, flags)
 *
 * If you want to access the stimulus ports without the stmAXI structure and
 * without using the macros, then you can generate an offset address using
 * stmPortAddress().
 *
 * Flags is some combination of:
 *
 * GUARANTEED or INVARIANT
 * MARKED
 * TIMESTAMPED
 * FLAG
 * TRIGGER
 *
 * Guaranteed and invariant semantics are mutually exclusive so if you
 * specify both, it defaults to guaranteed.
 *
 * As an example:
 *
 * Generate an address for Channel 0 TRIG_TS packet (implicitly non-data):
 *
 * 	 address = stmPortAddress(AXI_BASE, 0, (TRIGGER | TIMESTAMPED))
 *
 * Generate an address for Channel 5 FLAG_TS packet (implicitly non-data):
 *
 * 	 address = stmPortAddress(AXI_BASE, 5, (FLAG | INVARIANT | TIMESTAMPED))
 *
 * Generate an address for Channel 3 Dn packet with GUARANTEED semantics:
 *
 * 	 address = stmPortAddress(AXI_BASE, 3, (GUARANTEED))
 *
 * Generate an address for Channel 4 DnM_TS packet with GUARANTEED semantics:
 *
 * 	 address = stmPortAddress(AXI_BASE, 4, (GUARANTEED | MARKED | TIMESTAMPED))
 *
 * Obviously where data output is possible that depends on what you
 * do with the address you get out..
 *
 */
unsigned long stmPortAddress(unsigned long base, unsigned int channel, unsigned int flags)
{
	/*
	 * We don't actually use this function but it is a nice example of
	 * how the different STM stimulus types map to a stimulus register
	 * address. Based on the way we want the stimulus to go out we can
	 * generate an address, which we can then write with an appropriate
	 * sized access to generate that 'sized' packet
	 *
	 * See 3.3 Address decoding in STM Architecture Spec v1.1 (IHI0054B)
	 */

	unsigned long address = 0;

	/*
	 * STM extended stimulus port bits are a little backwards.
	 *
	 * Address bit	[7] makes a packet	Guaranteed if clear
	 * 									Invariant if set
	 * 				[4] makes a packet	Marked if clear
	 * 									Unmarked if set
	 * 				[3] makes a packet	Timestamped if clear
	 * 									Untimestamped if set
	 */

	// if flags GUARANTEED or not INVARIANT
	if ((flags & GUARANTEED) || !(flags & INVARIANT)) {
		address &= ~__GUARANTEED;
	} else {
		// default to INVARIANT
		address |= __GUARANTEED;
	}

	if (flags & TIMESTAMPED)
		address &= ~__TIMESTAMPED;
	else
		address |= __TIMESTAMPED;

	/*
	 * EXCEPT when:
	 * 				[6:5] determines if it's non-DATA (b11)
	 * 				[4] is TRIGGER (or nFLAG if you prefer)
	 * 				[7] and [3] retain their meaning as above
	 *
	 * we let the API deal with using DATA, TRIGGER or FLAG
	 * flag items in an intuitive manner
	 */

	if ((flags & TRIGGER) || (flags & FLAG)) {
		address |= __NONDATA;
		if ((flags & TRIGGER) || !(flags & FLAG))
			address &= ~__TRIGGERnFLAG;
		else if (flags & FLAG)
			address |= __TRIGGERnFLAG;
	} else {
		if (flags & MARKED)
			address &= ~__MARKED;
		else
			address |= __MARKED;
	}

	return ((unsigned long) (base + (channel << 9) + address));
}

/*
 * void stmSendString(stm, channel, string)
 *
 * We specifically write a byte to ensure that we get a D8 packet,
 * although that limits the function to 8-bit encodings.
 *
 * It doesn't matter what we use for the last write (if we see
 * a null character) -- G_FLAGTS has no data except the flag and
 * the timestamp, so a 32-bit access will be just fine..
*/

void stmSendString(struct STM *stm, unsigned int channel, const char *string)
{
	/*
	 * Send a string to the STM extended stimulus registers
	 * The first character goes out as D8M (Marker) packet
	 * The last character is followed by a Timestamp packet
	 *
	 * This is the Annex C example from the STPv2 spec
	 *
	 * For a retargeted example see stm_retarget.c
	 */
	struct stmAXI *axi = stm->AXI;

	int first = 1;

	while(*string != '\0')
	{
		/*
		 * If the character is a linefeed, then don't output
		 * it -- just reset our 'first' state to 1 so that
		 * the next character (the start of the next line)
		 * is marked
		 */
		if (*string == '\n') {
			STM32(axi, channel, G_FLAGTS) = *string++;
			first = 1;
		} else {
			/*
			 * Continue to output characters -- if it's the
			 * first character in a string, or just after a
			 * linefeed (handled above), mark it.
			 */
			if (first) {
				STM8(axi, channel, G_DM) = (*string++);
				first = 0;
			} else {
				STM8(axi, channel, G_D) = (*string++);
			}
		}
	}

	/*
	 * Flag the end of the string
	 *
	 * Access size doesn't matter as we have no data for flag
	 * packets
	 */
	STM32(axi, channel, G_FLAGTS) = 0x0;
}

int stm_fputc(struct STM *stm, int c, FILE *f) {
    struct stmAXI *axi = stm->AXI;
    STM8(axi, 0, G_D) = (char )c;
    return 0;
}
