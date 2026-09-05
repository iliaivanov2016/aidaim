/****************************************************************************
 *  This file is part of PPMd project                                       *
 *  Written and distributed to public domain by Dmitry Shkarin 1997,        *
 *  1999-2000                                                               *
 *  Modified for compatibility with Delphi by AidAim Software, 2001			 *
 *  Contents: main routine                                                  *
 *  Comments: system & compiler dependent file                              *
 ****************************************************************************/
#define FOR_DELPHI
//#define TEST_COMPRESSION
#pragma option -O1
#define NULL 0
#define EOF -1
/*
#ifndef FOR_DELPHI
#include <stdio.h>
#include <stdlib.h>
#include <mem.h>
#include <sys\stat.h>
#include <stdio.h>
#endif
*/

#include "PPMdType.h"
#include "SubAlloc.hpp"
#include "Model.hpp"

  const DWORD Variant='G';
// returns size of compressed data
unsigned int _FASTCALL PPMCompressBuffer(char* inBuf, unsigned int inSize, char* outBuf,
										int Max_Order = 6,int SASize = 10)
{
 unsigned int inBytes = 0, outBytes = 0;

 int info,c;
 MaxOrder = Max_Order;
 info=(MaxOrder-1) | ((SASize-1) << 4) | ((Variant-'A') << 12);
 memcpy(outBuf,&info,sizeof(info));
 outBytes += sizeof(info);

	 if (! StartSubAllocator(SASize))
     return 0;
    ariInitEncoder();
    StartModel();
    for ( ; ; )
    {
		  if (inBytes >= inSize)
         c = EOF;
        else
			c = 0x000000FF & ((char)*(inBuf+inBytes++));

        if (MinContext->NumStats != 1)
        {
            MinContext->encodeSymbol1(c);
            ariEncodeSymbol();
        }
        else
        {
            MinContext->encodeBinSymbol(c);
            ariShiftEncodeSymbol(INT_BITS+PERIOD_BITS);
        }
        while ( !FoundState )
        {
	         ARI_ENC_NORMALIZE(outBuf,outBytes);
            do
            {
                OrderFall++;
                MinContext=MinContext->Suffix;
                if ( !MinContext )
                 goto STOP_ENCODING;
            } while (MinContext->NumStats == NumMasked);
            MinContext->encodeSymbol2(c);
            ariEncodeSymbol();
        }
        if (!OrderFall && FoundState->Successor->NumStats)
         MinContext=MedContext=FoundState->Successor;
        else
        {
            UpdateModel();
            if (EscCount == 0)
                    ClearMask();
        }
        ARI_ENC_NORMALIZE(outBuf,outBytes);
    }
STOP_ENCODING:
    StopModel();
    ARI_FLUSH_ENCODER(outBuf,outBytes);
	 StopSubAllocator();

 return outBytes;
}

unsigned int _FASTCALL PPMDecompressBuffer(char* inBuf, unsigned int inSize, char* outBuf)
{
 unsigned int inBytes = 0, outBytes = 0;
 int info = 0,c,SASize;
 memcpy(&info,inBuf,sizeof(info));
 inBytes += sizeof(info);

   MaxOrder = (info & 0x0F)+1;
   SASize   = ((info >> 4) & 0xFF)+1;
   DWORD Var=(info >> 12)+'A';
   if (Var != Variant)
    return 0;
   if (! StartSubAllocator(SASize))
    return 0;
   ARI_INIT_DECODER(inBuf,inBytes,inSize);
   StartModel();
   for ( ; ; ) {
        if (MinContext->NumStats != 1)      MinContext->decodeSymbol1();
        else                                MinContext->decodeBinSymbol();
        ariRemoveSubrange();
        while ( !FoundState ) {
            ARI_DEC_NORMALIZE(inBuf,inBytes,inSize);
            do {
                OrderFall++;                MinContext=MinContext->Suffix;
                if ( !MinContext )          goto STOP_DECODING;
            } while (MinContext->NumStats == NumMasked);
            MinContext->decodeSymbol2();    ariRemoveSubrange();
        }
        putSym(FoundState->Symbol,outBuf,outBytes);

        if (!OrderFall && FoundState->Successor->NumStats)
                MinContext=MedContext=FoundState->Successor;
        else {
            UpdateModel();
            if (EscCount == 0)
                    ClearMask();
        }
        ARI_DEC_NORMALIZE(inBuf,inBytes,inSize);
    }
STOP_DECODING:
    StopModel();

  StopSubAllocator();
  return outBytes;
}

int main()
{
#ifndef FOR_DELPHI
  struct stat statbuf;
  FILE *fi;
  char *inbuf, *outbuf;
  unsigned int insize,size;

   dfile = fopen("e:\\thrash\\debug.txt","wt");
   fclose(dfile);
   dfile = fopen("e:\\thrash\\debug.txt","at+");
   #ifdef TEST_COMPRESSION
   fi = fopen("e:\\thrash\\digest.doc","rb");
   #else
   fi = fopen("e:\\thrash\\test.ppm","rb");
   #endif
   if (fi == NULL)
    return -1;
   fstat(fileno(fi), &statbuf);
   insize = statbuf.st_size;
   inbuf = (char *)malloc(insize);
   outbuf = (char *)malloc(10<<20);
   fread(inbuf,insize,1,fi);
   fclose(fi);

   #ifdef TEST_COMPRESSION
   size = PPMCompressBuffer(inbuf,insize,outbuf,6,10);
   fi = fopen("e:\\thrash\\test.ppm","wb");
   #else
   size = PPMDecompressBuffer(inbuf,insize,outbuf);
   fi = fopen("e:\\thrash\\test.doc","wb");
   #endif
   if (fi == NULL)
    return -1;
   fwrite(outbuf,size,1,fi);
   fclose(fi);
#endif
   return 0;
}
