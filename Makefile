
# required
# - ctags
# - grep
# - ps
# - git
# - find

test:
	vusted ./test --shuffle -v
	@# vusted ./test --shuffle -v --seed=SEED

.PHONY: test
