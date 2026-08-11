# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026  Alexey Gladkov <gladkov.alexey@gmail.com>

VERBOSE ?=
V ?= $(VERBOSE)

REPO   = overlay
ARCH   = x86_64

PKGS    = $(wildcard src/*)
SRCINFO = $(addsuffix .srcinfo,$(PKGS))

GPGKEY ?= 4CFFD434
USER   ?= builder

help:
	@echo
	@echo "update-package - publish packages"
	@echo "repo           - update repository"
	@echo

all: $(PKGS)

update-packages:
	@echo "processing $@ ..."
	@find src/ -type f -name '*.pkg.tar.*' -exec mv -vft packages/$(REPO)/os/$(ARCH)/ -- '{}' '+'
	@find src/ -type f -name '*.tar.*' -delete

repo:
	@echo "processing $@ ..."
	@rm -f -- packages/$(REPO)/os/$(ARCH)/overlay.db.*
	@find packages/$(REPO)/os/$(ARCH)/ -type f -a -name '*.pkg.tar.zst' \
	  -execdir repo-add --verify --sign --key $(GPGKEY) overlay.db.tar.gz '{}' '+'
	@find packages/ -name '*.old' -o -name '*.old.*' -delete

$(PKGS):
	@echo "processing $@ ..."
	@unshare --setuid=$$(id -u $(USER)) --wd="$@" -- \
	 makepkg --skippgpcheck --syncdeps --cleanbuild --force --sign --key $(GPGKEY)
	@rm -rf -- "$@/src" "$@/pkg"

$(SRCINFO):
	@echo "processing $@ ..."
	@d="$@"; d="$${d%.srcinfo}"; \
	 unshare --setuid=$$(id -u $(USER)) --wd="$$d" -- \
	 makepkg --printsrcinfo > "$$d/".SRCINFO

.PHONY: $(PKGS) $(SRCINFO)
