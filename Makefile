
# required
# - ctags
# - grep
# - ps
# - git
# - find or where
# - apropos

test:
	vusted --shuffle
	@# vusted --shuffle -v --seed=SEED

.PHONY: test
