#include "ppmdlib.h"
#include <memory.h>

PPMD_EXTERN int PPMD_API PpmdCompress(PPMStream *inStrm, PPMStream *outStrm, UInt32 maxOrder, UInt32 saSize)
{
    UInt32 _restor = 0;

	CPpmd8 _ppmd;
	UInt32 val;

    Ppmd8_Construct(&_ppmd);
    if (!Ppmd8_Alloc(&_ppmd, saSize << 20, &outStrm->alloc))
        return -1;
    _ppmd.Stream.Out = outStrm;

    Ppmd8_RangeEnc_Init(&_ppmd);
    Ppmd8_Init(&_ppmd, maxOrder, _restor);

    val = (UInt32)((maxOrder - 1) + ((saSize - 1) << 4) + (_restor << 12));
    WriteStream(outStrm, (Byte)(val & 0xFF));
    WriteStream(outStrm, (Byte)(val >> 8));

    while (inStrm->avail > 0) {
        Ppmd8_EncodeSymbol(&_ppmd, ReadStream(inStrm));
    }
    Ppmd8_EncodeSymbol(&_ppmd, -1);
    Ppmd8_RangeEnc_FlushData(&_ppmd);

    return 0; //OK
}


PPMD_EXTERN int PPMD_API PpmdDecompress(PPMStream *inStrm, PPMStream *outStrm)
{
	int i;
	Byte buf[2];
	UInt32 val, order, mem, restor;
	CPpmd8 _ppmd;

    for (i = 0; i < 2; i++)
        buf[i] = ReadStream(inStrm);

    val = GetUi16(buf);
    order = (val & 0xF) + 1;
    mem = ((val >> 4) & 0xFF) + 1;
    restor = (val >> 12);
    if ((order < 2) || (restor > 2))
        return -1;

#ifdef __DEBUG
	Dbg("Construction");
#endif
    Ppmd8_Construct(&_ppmd);

    if (!Ppmd8_Alloc(&_ppmd, mem << 20, &outStrm->alloc))
        return -2;

    _ppmd.Stream.In = inStrm;
    if (!Ppmd8_RangeDec_Init(&_ppmd))
        return -1;
#ifdef __DEBUG
	Dbg("Initialization");
#endif
    Ppmd8_Init(&_ppmd, order, restor);

    while (inStrm->avail > 0) {
        i = Ppmd8_DecodeSymbol(&_ppmd);
        if (i > -1)
            WriteStream(outStrm, (Byte)i);
        else
            if (i != -1) {
#ifdef __DEBUG
				Dbg("Unexpected end of stream!");
#endif
				return -1;
			}
    }

    return 0;
}
