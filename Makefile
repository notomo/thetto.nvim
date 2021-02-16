
# required
# - ctags
# - grep
# - ps
# - git
# - find or where
# - apropos

test:
	vusted --shuffle -v
	@# vusted --shuffle -v --seed=SEED

.PHONY: test
