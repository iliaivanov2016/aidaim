#include "ppmdlib.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void *SzBigAlloc(void *, size_t size) { return malloc(size); }
static void SzBigFree(void *, void *address) { free(address); }
static ISzAlloc g_BigAlloc = { SzBigAlloc, SzBigFree };

void WriteStream(PPMStream *strm, Byte value)
{
    strm->buf[strm->pos] = value;
    strm->pos++; strm->avail--;
}

Byte ReadStream(PPMStream *strm) {
    Byte val = strm->buf[strm->pos];
    strm->pos++; strm->avail--;
    return val;
}

using namespace std;

const char *inBuf = "Africa This is sample file";

int main() {

	printf("Size of size_t = %u\n", sizeof(size_t));
	printf("Size of PpmdStream = %u\n", sizeof(PPMStream));

    Byte *outBuf = (Byte *) malloc(1024);
    UInt32 outSize = 1024;

    Byte *outBuf2 = (Byte *) malloc(1024);
    UInt32 outSize2 = 1024;

    PPMStream inStrm, outStrm;
    inStrm.buf  = (unsigned char *)inBuf;
    inStrm.pos = 0;
    inStrm.avail = strlen(inBuf);

    outStrm.buf = outBuf;
    outStrm.pos = 0;
    outStrm.avail = 1024;
    outStrm.alloc = g_BigAlloc;

    if (PpmdCompress(&inStrm, &outStrm, 6, 10) < 0) {
        printf("Error!\n");
		return 2;
    }

    inStrm.buf = outStrm.buf;
    inStrm.pos = 0;
    inStrm.avail = outStrm.pos;

    outStrm.buf = outBuf2;
    outStrm.avail = 1024;
    outStrm.pos = 0;

    if (PpmdDecompress(&inStrm, &outStrm) < 0) {
        printf("Decompression error!\n");
		return 2;
    }
	printf("Decompressed string = %s\n", outBuf2);
	getc(stdin);
    return 0;
}
