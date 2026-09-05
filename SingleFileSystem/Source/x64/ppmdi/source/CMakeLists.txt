cmake_minimum_required(VERSION 2.8)
project(ppmd)
add_definitions(-D__NO_STREAMS)
if (WIN32)
  set(CMAKE_C_FLAGS "/GS- /Gs16384 -nologo")
  set(CMAKE_C_FLAGS_DEBUG "/MDd")
  set(CMAKE_C_FLAGS_RELEASE "/MD")
elseif (UNIX)
endif()
set(CMAKE_CXX_FLAGS ${CMAKE_C_FLAGS})
set(CMAKE_CXX_FLAGS_DEBUG ${CMAKE_C_FLAGS_DEBUG})
set(CMAKE_CXX_FLAGS_RELEASE ${CMAKE_C_FLAGS_RELEASE})
if(CMAKE_SIZEOF_VOID_P EQUAL 4)
   set(OBJS_OUT_SUFFIX x86/)
elseif(CMAKE_SIZEOF_VOID_P EQUAL 8)
   set(OBJS_OUT_SUFFIX amd64/)
endif()
set(PPMD_FILES Ppmd8.c Ppmd8Dec.c Ppmd8Enc.c)
set(PPMDLIB_FILES ppmdlib.c)
add_library(ppmd ${PPMD_FILES})
add_library(ppmdlib ppmdlib.c)
#add_executable(test0 test0.cpp)
#target_link_libraries(test0 ppmdlib ppmd)

set(OBJS_DIR ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/ppmd.dir/)
set(PPMDLIB_OBJS_DIR ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/ppmdlib.dir/)
set(OBJS_OUT ${CMAKE_CURRENT_SOURCE_DIR}/../../objs/)
if (WIN32)
    set(OBJ_EXT c.obj)
elseif (UNIX)
    set(OBJ_EXT c.o)
endif()

install(FILES ${OBJS_DIR}Ppmd8Enc.${OBJ_EXT}
          ${OBJS_DIR}Ppmd8Dec.${OBJ_EXT}
          ${OBJS_DIR}Ppmd8.${OBJ_EXT}
          ${PPMDLIB_OBJS_DIR}ppmdlib.${OBJ_EXT}
	DESTINATION ${OBJS_OUT}${OBJS_OUT_SUFFIX})



