# Boxed help menus, as in MarketLens:
#
#   help:
#   	$(call mp_help_header,Title)
#   	$(call mp_help_section,Section)
#   	$(call mp_help_command,make target,What it does)
#   	$(call mp_help_line,Any other text)
#   	$(call mp_help_footer,A closing note)     # or mp_help_bottom
#
# Every line is MP_HELP_WIDTH wide; text that would not fit is cut. Text is
# printed as written (quotes, backslashes, % and $$ are not interpreted);
# write a comma as $(mp_comma).
ifndef MP_HELP_LOADED
MP_HELP_LOADED := 1

MP_HELP_WIDTH ?= 79
MP_HELP_COMMAND_WIDTH ?= 30
MP_HELP_INNER := $(shell echo $$(($(MP_HELP_WIDTH) - 2)))
MP_HELP_RULE := $(shell i=0; while [ $$i -lt $(MP_HELP_INNER) ]; do printf '═'; i=$$((i+1)); done)

# $(call mp_help_text,colour,indent,text): one bordered line. The text
# reaches awk through the environment, which awk does not unescape.
define mp_help_text
	@MP_T='$(call mp_sq,$(3))' awk 'BEGIN { \
		t = ENVIRON["MP_T"]; w = $(MP_HELP_INNER) - $(2); \
		if (length(t) > w) t = substr(t, 1, w); \
		printf "$(MP_CYAN)║$(MP_RESET)%*s$(1)%s$(MP_RESET)%*s$(MP_CYAN)║$(MP_RESET)\n", $(2), "", t, w - length(t), ""; \
	}'
endef

# $(call mp_help_command,command,description): command in a fixed column.
define mp_help_command
	@MP_C='$(call mp_sq,$(1))' MP_D='$(call mp_sq,$(2))' awk 'BEGIN { \
		c = ENVIRON["MP_C"]; d = ENVIRON["MP_D"]; w = $(MP_HELP_INNER) - 4; \
		if (length(c) > w) c = substr(c, 1, w); \
		pad = $(MP_HELP_COMMAND_WIDTH) - 4 - length(c); if (pad < 1) pad = 1; \
		if (length(c) + pad > w) pad = w - length(c); \
		room = w - length(c) - pad; \
		if (length(d) > room) d = substr(d, 1, room); \
		printf "$(MP_CYAN)║$(MP_RESET)    $(MP_BLUE)%s$(MP_RESET)%*s%s%*s$(MP_CYAN)║$(MP_RESET)\n", c, pad, "", d, room - length(d), ""; \
	}'
endef

mp_help_top = @printf '%b\n' '$(MP_CYAN)╔$(MP_HELP_RULE)╗$(MP_RESET)'
mp_help_bottom = @printf '%b\n' '$(MP_CYAN)╚$(MP_HELP_RULE)╝$(MP_RESET)'
mp_help_divider = @printf '%b\n' '$(MP_CYAN)╠$(MP_HELP_RULE)╣$(MP_RESET)'

define mp_help_header
	$(mp_help_top)
	$(call mp_help_text,$(MP_YELLOW),2,$(1))
endef

define mp_help_section
	$(mp_help_divider)
	$(call mp_help_text,$(MP_GREEN),2,$(1))
endef

mp_help_line = $(call mp_help_text,,2,$(1))
mp_help_empty = $(call mp_help_text,,0,)

define mp_help_footer
	$(mp_help_divider)
	$(call mp_help_text,$(MP_CYAN),2,$(1))
	$(mp_help_bottom)
endef
endif
