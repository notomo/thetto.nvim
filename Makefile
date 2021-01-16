
# required
# - ctags
# - grep
# - ps
# - git
# - find

test:
	vusted --shuffle -v
	@# vusted --shuffle -v --seed=SEED

.PHONY: test
