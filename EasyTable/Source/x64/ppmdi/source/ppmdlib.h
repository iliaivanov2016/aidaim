#ifndef _PPMDLIB_H
#define _PPMDLIB_H

#define PPMD_EXTERN
#define PPMD_API

#ifdef __cplusplus
extern "C" {
#endif

#include "Ppmd8.h"
#include "cpstypes.h"

PPMD_EXTERN int PPMD_API PpmdCompress(PPMStream *inStrm, PPMStream *outStrm, UInt32 maxOrder, UInt32 saSize);

PPMD_EXTERN int PPMD_API PpmdDecompress(PPMStream *inStrm, PPMStream *outStrm);

#ifdef __cplusplus
}
#endif

#endif //_PPMDLIST_H
