# Colours for help menus and messages, off when NO_COLOR is set to anything
# (no-color.org) or TERM=dumb. Names carry MP_ so a project that includes
# Makefile.include keeps its own RED, ECHO and the like.
ifndef MP_COLORS_LOADED
MP_COLORS_LOADED := 1

MP_CYAN := \033[36m
MP_GREEN := \033[32m
MP_YELLOW := \033[33m
MP_RED := \033[31m
MP_BLUE := \033[34m
MP_RESET := \033[0m

ifneq ($(NO_COLOR),)
  MP_PLAIN := 1
else ifeq ($(TERM),dumb)
  MP_PLAIN := 1
endif

ifdef MP_PLAIN
  MP_CYAN :=
  MP_GREEN :=
  MP_YELLOW :=
  MP_RED :=
  MP_BLUE :=
  MP_RESET :=
endif

# Text made safe inside a single-quoted shell word.
mp_sq = $(subst ','\'',$(1))
mp_comma := ,
endif
