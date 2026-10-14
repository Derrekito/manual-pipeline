# manual-pipeline - working on the pipeline itself.
# Projects use the pipeline through Makefile.include, not this file.

include mk/colors.mk
include mk/messages.mk
include mk/help_menu.mk

.DEFAULT_GOAL := help
.PHONY: help test manual example-logo

help:
	$(call mp_help_header,manual-pipeline - Command Reference)
	$(call mp_help_section,Pipeline Development)
	$(call mp_help_command,make test,Run the filter and template tests)
	$(call mp_help_command,make manual,Build the pipeline's own manual PDF)
	$(call mp_help_command,make example-logo,Rebuild the example logo PDF)
	$(call mp_help_section,Using the Pipeline)
	$(call mp_help_line,Projects include Makefile.include from their manual/)
	$(call mp_help_line,Makefile; see examples/Makefile.example.)
	$(call mp_help_footer,NO_COLOR=1 turns colours off)

test:
	$(call mp_info,Running filter and template tests...)
	@python3 -m unittest tests.test_filters
	$(call mp_success,Tests passed)

manual:
	$(call mp_info,Building the pipeline manual...)
	@$(MAKE) --no-print-directory -C manual pdf

example-logo:
	$(call mp_info,Rebuilding assets/logos/example-logo.pdf...)
	@set -eu; work=$$(mktemp -d); \
	trap 'rm -rf "$$work"' EXIT HUP INT TERM; \
	cd assets/logos; \
	lualatex -interaction=nonstopmode -halt-on-error -output-directory="$$work" example-logo.tex >/dev/null \
		|| { cat "$$work/example-logo.log" >&2; exit 1; }; \
	cp "$$work/example-logo.pdf" example-logo.pdf
	$(call mp_success,Example logo rebuilt)
