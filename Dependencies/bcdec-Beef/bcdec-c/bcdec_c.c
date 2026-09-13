/* SPDX-License-Identifier: MIT */
/* The single translation unit that instantiates bcdec.
 *
 * bcdec is header-only: every caller that wants the bodies rather than the declarations
 * defines BCDEC_IMPLEMENTATION first, and exactly one of them may. This file is that one, so
 * the Beef side links an ordinary archive and binds the header's C functions directly. */

#define BCDEC_IMPLEMENTATION
#include "bcdec.h"
