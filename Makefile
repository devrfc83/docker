.PHONY: update-digests check-digests

update-digests:
	@bash scripts/update-digests.sh

check-digests:
	@bash scripts/update-digests.sh check
