ifdef SystemRoot
	SYSTEM=Windows
else ifdef SYSTEMROOT
	SYSTEM=Windows
else
	SYSTEM=Other
endif

ifeq ($(SYSTEM), Windows)
	EXE=.exe
	PLATFORM_DEFINES=-DSYSTEM_WIN32 -D_CONSOLE
	PLATFORM_FLAGS=
	RM=cmd /c del /F
	RMR=cmd /c rd /S/Q
	MKDIR=cmd /c md
	CP=cmd /c copy /B
	PATHSEP2=\\
	PATHSEP=$(strip $(PATHSEP2))
	CMDSEP=&
else
	EXE=
	PLATFORM_DEFINES=-DSYSTEM_POSIX -DHAVE_SYS_TIME_H -DHAVE_UNISTD_H -DHAVE_SYS_STAT_H -DHAVE_FCNTL_H -DHAVE_SYS_RESOURCE_H -D_strdup=strdup -D_strlwr=strlwr -D_strupr=strupr -Dstricmp=strcasecmp -D_unlink=unlink -D_open=open -D_read=read -D_close=close
	PLATFORM_FLAGS=-pthread
	RM=rm -f
	RMR=rm -rf
	MKDIR=mkdir -p
	CP=cp
	PATHSEP2=/
	PATHSEP=$(strip $(PATHSEP2))
	CMDSEP=;
endif

CXX=g++

ARCH?=-m32
USER_FLAGS= -Ofast -funsafe-math-optimizations -funsafe-loop-optimizations -ffast-math -fgraphite-identity -march=native -mtune=native -msse4 -mavx -floop-interchange -mfpmath=sse -g
CFLAGS=-Wint-to-pointer-cast $(USER_FLAGS)

COMMON_DEFINES=-DSTDC_HEADERS $(PLATFORM_DEFINES) $(USER_DEFINES)

ifeq ($(ARCH),-m32)
	CHECKPLATFORM?=unix32
	COMMON_DEFINES += -DVERSION_LINUX
else ifeq ($(ARCH),-m64)
	CHECKPLATFORM?=unix64
	COMMON_DEFINES += -DVERSION_LINUX -DVERSION_64BIT
endif

CPPCHECK?=cppcheck
CPPCHECKFLAGS= --enable=warning --enable=portability --platform=$(CHECKPLATFORM) --language=c++ -I common --force --quiet

INSTALL_PATH?=/usr/local/bin

_COMMON_SOURCES=blockmem.cpp bspfile.cpp cmdlib.cpp cmdlinecfg.cpp filelib.cpp files.cpp log.cpp mathlib.cpp messages.cpp resourcelock.cpp scriplib.cpp threads.cpp winding.cpp stringlib.cpp filesystem.cpp
COMMON_SOURCES=$(addprefix common/,$(_COMMON_SOURCES))

USER_DEFINES=

INCLUDE_DIRS=-Itemplate -Icommon

BUILD_DIR=build$(ARCH)
BIN_DIR=bin$(ARCH)

HLCSG_SOURCES=ANSItoUTF8.cpp autowad.cpp brush.cpp brushunion.cpp hullfile.cpp map.cpp properties.cpp qcsg.cpp textures.cpp wadcfg.cpp wadinclude.cpp wadpath.cpp
HLCSG_OBJECTS=$(patsubst %.cpp,$(BUILD_DIR)/hlcsg/%.o,$(HLCSG_SOURCES))
HLCSG_COMMON_OBJECTS=$(patsubst %.cpp,$(BUILD_DIR)/hlcsg/%.o,$(COMMON_SOURCES))
HLCSG_DEFINES=-DHLCSG -DDOUBLEVEC_T

HLBSP_SOURCES=brink.cpp merge.cpp outside.cpp portals.cpp qbsp.cpp solidbsp.cpp surfaces.cpp tjunc.cpp writebsp.cpp
HLBSP_OBJECTS=$(patsubst %.cpp,$(BUILD_DIR)/hlbsp/%.o,$(HLBSP_SOURCES))
HLBSP_COMMON_OBJECTS=$(patsubst %.cpp,$(BUILD_DIR)/hlbsp/%.o,$(COMMON_SOURCES))
HLBSP_DEFINES=-DHLBSP -DDOUBLEVEC_T

HLVIS_SOURCES=flow.cpp vis.cpp zones.cpp ambient.cpp
HLVIS_OBJECTS=$(patsubst %.cpp,$(BUILD_DIR)/hlvis/%.o,$(HLVIS_SOURCES))
HLVIS_COMMON_OBJECTS=$(patsubst %.cpp,$(BUILD_DIR)/hlvis/%.o,$(COMMON_SOURCES))
HLVIS_DEFINES=-DHLVIS

HLRAD_SOURCES= progmesh.cpp meshtrace.cpp leaf_lighting.cpp studio.cpp meshdesc.cpp compress.cpp lightmap.cpp mathutil.cpp qrad.cpp sparse.cpp transfers.cpp vismatrix.cpp lerp.cpp loadtextures.cpp nomatrix.cpp  qradutil.cpp trace.cpp transparency.cpp vismatrixutil.cpp
HLRAD_OBJECTS=$(patsubst %.cpp,$(BUILD_DIR)/hlrad/%.o,$(HLRAD_SOURCES))
HLRAD_COMMON_OBJECTS=$(patsubst %.cpp,$(BUILD_DIR)/hlrad/%.o,$(COMMON_SOURCES))
HLRAD_DEFINES=-DHLRAD

TARGETS?=hlcsg hlbsp hlvis hlrad

OPTS=$(ARCH) $(CFLAGS) $(PLATFORM_FLAGS)

HLCSGDIRS=$(BUILD_DIR)$(PATHSEP)hlcsg$(PATHSEP)common
HLBSPDIRS=$(BUILD_DIR)$(PATHSEP)hlbsp$(PATHSEP)common
HLVISDIRS=$(BUILD_DIR)$(PATHSEP)hlvis$(PATHSEP)common
HLRADDIRS=$(BUILD_DIR)$(PATHSEP)hlrad$(PATHSEP)common

all : $(TARGETS)

$(HLCSGDIRS):
	-$(MKDIR) $@
$(HLBSPDIRS):
	-$(MKDIR) $@
$(HLVISDIRS):
	-$(MKDIR) $@
$(HLRADDIRS):
	-$(MKDIR) $@
$(BIN_DIR):
	-$(MKDIR) $@

hlcsg: $(BIN_DIR) $(HLCSGDIRS) $(BIN_DIR)/hlcsg$(EXE)
hlbsp: $(BIN_DIR) $(HLBSPDIRS) $(BIN_DIR)/hlbsp$(EXE)
hlvis: $(BIN_DIR) $(HLVISDIRS) $(BIN_DIR)/hlvis$(EXE)
hlrad: $(BIN_DIR) $(HLRADDIRS) $(BIN_DIR)/hlrad$(EXE)

checkhlcsg: hlcsg.log 
checkhlbsp: hlbsp.log 
checkhlvis: hlvis.log
checkhlrad: hlrad.log
checkcommon: common.log

hlcsg.log: $(COMMON_SOURCES) $(addprefix hlcsg$(PATHSEP), $(HLCSG_SOURCES))
	$(CPPCHECK) $(COMMON_DEFINES) $(HLCSG_DEFINES) $(CPPCHECKFLAGS) hlcsg 2>$@

hlbsp.log: $(COMMON_SOURCES) $(addprefix hlbsp$(PATHSEP), $(HLBSP_SOURCES))
	$(CPPCHECK) $(COMMON_DEFINES) $(HLBSP_DEFINES) $(CPPCHECKFLAGS) hlbsp 2>$@

hlvis.log: $(COMMON_SOURCES) $(addprefix hlvis$(PATHSEP), $(HLVIS_SOURCES))
	$(CPPCHECK) $(COMMON_DEFINES) $(HLVIS_DEFINES) $(CPPCHECKFLAGS) hlvis 2>$@

hlrad.log: $(COMMON_SOURCES) $(addprefix hlrad$(PATHSEP), $(HLRAD_SOURCES))
	$(CPPCHECK) $(COMMON_DEFINES) $(HLRAD_DEFINES) $(CPPCHECKFLAGS) hlrad 2>$@

common.log: $(COMMON_SOURCES)
	$(CPPCHECK) $(COMMON_DEFINES) $(CPPCHECKFLAGS) common 2>$@

# HLCSG
$(BIN_DIR)/hlcsg$(EXE): $(HLCSG_OBJECTS) $(HLCSG_COMMON_OBJECTS)
	$(CXX) $(OPTS) $(HLCSG_OBJECTS) $(HLCSG_COMMON_OBJECTS) -o $@

$(BUILD_DIR)/hlcsg/%.o : hlcsg/%.cpp
	$(CXX) -c $(OPTS) $(COMMON_DEFINES) $(HLCSG_DEFINES) $(INCLUDE_DIRS) $< -o $@
	
$(BUILD_DIR)/hlcsg/common/%.o : common/%.cpp
	$(CXX) -c $(OPTS) $(COMMON_DEFINES) $(HLCSG_DEFINES) $(INCLUDE_DIRS) $< -o $@

# HLBSP

$(BIN_DIR)/hlbsp$(EXE): $(HLBSP_OBJECTS) $(HLBSP_COMMON_OBJECTS)
	$(CXX) $(OPTS) $(HLBSP_OBJECTS) $(HLBSP_COMMON_OBJECTS) -o $@

$(BUILD_DIR)/hlbsp/%.o : hlbsp/%.cpp
	$(CXX) -c $(OPTS) $(COMMON_DEFINES) $(HLBSP_DEFINES) $(INCLUDE_DIRS) $< -o $@
	
$(BUILD_DIR)/hlbsp/common/%.o : common/%.cpp
	$(CXX) -c $(OPTS) $(COMMON_DEFINES) $(HLBSP_DEFINES) $(INCLUDE_DIRS) $< -o $@

# HLVIS

$(BIN_DIR)/hlvis$(EXE): $(HLVIS_OBJECTS) $(HLVIS_COMMON_OBJECTS)
	$(CXX) $(OPTS) $(HLVIS_OBJECTS) $(HLVIS_COMMON_OBJECTS) -o $@

$(BUILD_DIR)/hlvis/%.o : hlvis/%.cpp
	$(CXX) -c $(OPTS) $(COMMON_DEFINES) $(HLVIS_DEFINES) $(INCLUDE_DIRS) $< -o $@
	
$(BUILD_DIR)/hlvis/common/%.o : common/%.cpp
	$(CXX) -c $(OPTS) $(COMMON_DEFINES) $(HLVIS_DEFINES) $(INCLUDE_DIRS) $< -o $@

# HLRAD

$(BIN_DIR)/hlrad$(EXE): $(HLRAD_OBJECTS) $(HLRAD_COMMON_OBJECTS)
	$(CXX) $(OPTS) $(HLRAD_OBJECTS) $(HLRAD_COMMON_OBJECTS) -o $@

$(BUILD_DIR)/hlrad/%.o : hlrad/%.cpp
	$(CXX) -c $(OPTS) $(COMMON_DEFINES) $(HLRAD_DEFINES) $(INCLUDE_DIRS) $< -o $@
	
$(BUILD_DIR)/hlrad/common/%.o : common/%.cpp
	$(CXX) -c $(OPTS) $(COMMON_DEFINES) $(HLRAD_DEFINES) $(INCLUDE_DIRS) $< -o $@

clean: 
	-$(RMR) $(foreach target,$(TARGETS),$(BUILD_DIR)$(PATHSEP)$(target) )

distclean: clean
	-$(RMR) $(foreach target,$(TARGETS),$(BIN_DIR)$(PATHSEP)$(target)$(EXE))
	
install:
	-$(CP) $(BIN_DIR)$(PATHSEP)hlcsg$(EXE) $(INSTALL_PATH)$(PATHSEP)hlcsg
	-$(CP) $(BIN_DIR)$(PATHSEP)hlbsp$(EXE) $(INSTALL_PATH)$(PATHSEP)hlbsp
	-$(CP) $(BIN_DIR)$(PATHSEP)hlvis$(EXE) $(INSTALL_PATH)$(PATHSEP)hlvis
	-$(CP) $(BIN_DIR)$(PATHSEP)hlrad$(EXE) $(INSTALL_PATH)$(PATHSEP)hlrad

uninstall:
	-$(RM) $(INSTALL_PATH)$(PATHSEP)hlcsg $(INSTALL_PATH)$(PATHSEP)hlbsp $(INSTALL_PATH)$(PATHSEP)hlvis $(INSTALL_PATH)$(PATHSEP)hlrad

check: checkcommon checkhlcsg checkhlbsp checkhlrad checkhlvis

