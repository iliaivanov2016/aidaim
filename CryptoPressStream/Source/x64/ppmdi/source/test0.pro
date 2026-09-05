QT -= core gui
TEMPLATE = app

DEFINES += __NO_STREAMS

SOURCES = test0.cpp \
        ppmdlib.c \
        Ppmd8.c \
        Ppmd8Dec.c \
        Ppmd8Enc.c

HEADERS = ppmdlib.h

