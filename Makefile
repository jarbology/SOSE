.PHONY: all clean sync-assets compile-msg

ASSETS_DIR=assets
SRC_DIR=src
DEPS_DIR=deps
REL_DIR=release
BUILD_DIR=build
OBJ_DIR=$(BUILD_DIR)/obj

EXE_NAME=SoSE.exe
EXE=$(REL_DIR)/$(EXE_NAME)
EXE_BASE=tools/Titan-release.exe

MSGPACK_DIR=$(DEPS_DIR)/lua-msgpack
MSGPACK_SRC_FILES=msgpack.lua luabit.lua
MSGPACK_OBJ_FILES=$(MSGPACK_SRC_FILES:%.lua=$(OBJ_DIR)/$(MSGPACK_DIR)/%.luac)

ASSET_SPEC_FILES=$(shell find $(ASSETS_DIR) -name '*.lua')
ASSET_SPEC_OBJ_FILES=$(ASSET_SPEC_FILES:%.lua=$(OBJ_DIR)/%.luac)

SRC_FILES=$(shell find $(SRC_DIR) -name '*.lua')
OBJ_FILES=$(SRC_FILES:src/%.lua=$(OBJ_DIR)/%.luac) $(MSGPACK_OBJ_FILES) $(ASSET_SPEC_OBJ_FILES)
OBJ_TREE=$(sort $(dir $(OBJ_FILES)))

all: $(EXE) sync-assets

clean:
	rm -rf $(REL_DIR)
	rm -rf $(BUILD_DIR)

sync-assets: | $(REL_DIR)/
	@echo Synchronizing assets...
	@rsync -avm \
	       --delete \
	       --exclude '*.lua' \
	       --exclude 'raw' \
	       $(ASSETS_DIR) $(REL_DIR)

$(EXE): $(BUILD_DIR)/$(EXE_NAME).pre $(EXE_BASE) $(REL_DIR)/SDL2.dll
	@echo Making executable...
	@lua tools/zzipsetstub.lua $< $(EXE_BASE) $@
	@chmod +x $@

%.pre: %.base $(OBJ_FILES)
	@test $@ -nt $< || test ! -f $@ || (rm $@ && echo "Removed oudated bundle")
	@test -f $@ || cp $< $@
	@echo "Bundling sources..."
	$(eval OUTPUT_PATH=$(shell readlink -f $@))
	@cd $(OBJ_DIR) && zip -9 -u -r $(OUTPUT_PATH) .

$(BUILD_DIR)/$(EXE_NAME).base: $(EXE_BASE) | $(BUILD_DIR)/
	@echo Making base archive...
	@test ! -f $@ || rm $@
	@zip -0 -j $@ $<

$(OBJ_FILES): | $(OBJ_TREE)

$(OBJ_DIR)/assets/%.luac: assets/%.lua
	luajit -bg $< $@

$(OBJ_DIR)/deps/%.luac: deps/%.lua
	luajit -bg $< $@

$(OBJ_DIR)/%.luac: src/%.lua
	luajit -bg $< $@

%/:
	mkdir -p $@

$(REL_DIR)/SDL2.dll: tools/SDL2.dll | $(REL_DIR)/
	cp $< $@
