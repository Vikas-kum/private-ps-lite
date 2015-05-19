ifndef config
ifneq ("$(wildcard ./config.mk)","")
config = ./config.mk
else
config = make/config.mk
endif
endif

include $(config)
include make/ps.mk

ifndef OPT
OPT  = -O3 -ggdb
endif

ifndef DEPS_PATH
DEPS_PATH = $(shell pwd)/deps
endif

ifndef CORE_PATH
CORE_PATH = $(shell pwd)/../../dmlc-core
endif

WARN = -Wall -finline-functions
INCPATH = -I./src -I$(DEPS_PATH)/include -I$(CORE_PATH)/include
CFLAGS = -std=c++11 -msse2 $(WARN) $(OPT) $(INCPATH) $(PS_CFLAGS) $(EXTRA_CFLAGS)


PS_LIB = build/libps.a
PS_MAIN = build/libps_main.a

clean:
	rm -rf build
	find src -name "*.pb.[ch]*" -delete

ps: $(PS_LIB) $(PS_MAIN)

ps_srcs	= $(wildcard src/*.cc src/*/*.cc)
ps_protos	= $(wildcard src/proto/*.proto)
ps_objs	= $(patsubst src/%.proto, build/%.pb.o, $(ps_protos)) \
			  $(patsubst src/%.cc, build/%.o, $(ps_srcs))

build/libps.a: $(patsubst %.proto, %.pb.h, $(ps_protos)) $(ps_objs)
	ar crv $@ $(filter %.o, $?)

build/libps_main.a: build/ps_main.o
	ar crv $@ $?

build/%.o: src/%.cc
	@mkdir -p $(@D)
	$(CXX) $(INCPATH) -std=c++0x -MM -MT build/$*.o $< >build/$*.d
	$(CXX) $(CFLAGS) -c $< -o $@

%.pb.cc %.pb.h : %.proto
	${DEPS_PATH}/bin/protoc --cpp_out=./src --proto_path=./src $<

-include build/*/*.d
-include build/*/*/*.d
-include test/ps_test.mk
-include guide/ps_guide.mk
