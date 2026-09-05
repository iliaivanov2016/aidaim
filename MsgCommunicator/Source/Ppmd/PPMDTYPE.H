/****************************************************************************
 *  This file is part of PPMd project                                       *
 *  Written and distributed to public domain by Dmitry Shkarin 1997,        *
 *  1999-2000                                                               *
 *  Contents: compilation parameters and miscelaneous definitions           *
 *  Comments: system & compiler dependent file                              *
 ****************************************************************************/
#if !defined(_PPMDTYPE_H_)
#define _PPMDTYPE_H_

const int MAX_O=16;                         /* maximum allowed model order */

//#define _WIN32_ENVIRONMENT_
//#include <wtypes.h>
typedef int   BOOL;
#define FALSE 0
#define TRUE  1
typedef unsigned char  BYTE;
typedef unsigned short WORD;
typedef unsigned long  DWORD;
typedef unsigned int   UINT;
typedef signed long    LONG;

#define _FASTCALL __fastcall
#define _STDCALL  __stdcall

#define _PACK_ATTR

template <class TMP_TYPE>
inline TMP_TYPE CLAMP(const TMP_TYPE& X,const TMP_TYPE& LoX,const TMP_TYPE& HiX) { return (X >= LoX)?((X <= HiX)?(X):(HiX)):(LoX); }
template <class TMP_TYPE>
inline void SWAP(TMP_TYPE& t1,TMP_TYPE& t2) { TMP_TYPE tmp=t1; t1=t2; t2=tmp; }
#ifdef FOR_DELPHI
extern void memcpy (void *dest, void *source, int count);
extern void memset (void *dest, BYTE b, int count);
extern char* aa_malloc(int count);
extern void aa_free(char *buffer);
#endif
#endif /* !defined(_PPMDTYPE_H_) */
