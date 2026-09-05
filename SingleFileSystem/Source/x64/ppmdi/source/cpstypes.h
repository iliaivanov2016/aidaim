#ifndef CPSTYPES_H
#define CPSTYPES_H

typedef struct PPMStream_s {
    Byte *buf;
    UInt32 pos;
    UInt32 avail;
    ISzAlloc alloc;
} PPMStream;

#endif // CPSTYPES_H
