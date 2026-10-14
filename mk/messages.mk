# One look for build feedback.
# Usage: $(call mp_info,Building...)  $(call mp_success,Done)
# The text is printed as written: quotes, backslashes and $$ are not
# interpreted. Write a comma as $(mp_comma).
ifndef MP_MESSAGES_LOADED
MP_MESSAGES_LOADED := 1

# $(call mp_message,colour,prefix,text)
mp_message = @printf '%b%s%b\n' '$(1)' '$(2)$(call mp_sq,$(3))' '$(MP_RESET)'

mp_info = $(call mp_message,$(MP_BLUE),,$(1))
mp_success = $(call mp_message,$(MP_GREEN),✓ ,$(1))
mp_warning = $(call mp_message,$(MP_YELLOW),⚠ ,$(1))
mp_error = $(call mp_message,$(MP_RED),✗ ,$(1))
mp_note = $(call mp_message,$(MP_CYAN),,$(1))
endif
