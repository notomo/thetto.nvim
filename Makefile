PLUGIN_NAME:=$(basename $(notdir $(abspath .)))
SPEC_DIR:=./spec/lua/${PLUGIN_NAME}

test:
	vusted --shuffle ./spec/lua/thetto/init_spec.lua ./spec/lua/thetto/handler/init_spec.lua --exclude-tags=slow
.PHONY: test

test_all:
	vusted --shuffle
.PHONY: test_all

vendor:
	nvim --headless -i NONE -n +"lua require('vendorlib').install('${PLUGIN_NAME}', '${SPEC_DIR}/vendorlib.lua')" +"quitall!"
.PHONY: vendor
