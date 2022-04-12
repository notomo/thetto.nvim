
# required
# - ctags
# - grep
# - ps
# - git
# - find or where
# - apropos

test:
	vusted --shuffle ./spec/lua/thetto/init_spec.lua --exclude-tags=slow
.PHONY: test

test_all:
	vusted --shuffle
.PHONY: test_all
