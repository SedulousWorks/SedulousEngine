/* SPDX-License-Identifier: MIT */
/* The single translation unit that instantiates bcdec.
 *
 * bcdec is header-only: every caller that wants the bodies rather than the declarations
 * defines BCDEC_IMPLEMENTATION first, and exactly one of them may. This file is that one, so
 * the Beef side links an ordinary archive and binds the header's C functions directly. */

#define BCDEC_IMPLEMENTATION
/* The precise BC4 / BC5 entry points: without this the header declares only the three
 * argument UNSIGNED decoders, so a signed block (BC4S / BC5S, and ATI1 / ATI2 authored
 * signed) would silently decode as unsigned. It also adds bcdec_bc4_float / bcdec_bc5_float,
 * which is how a signed block is read back without going through a byte. */
#define BCDEC_BC4BC5_PRECISE
#include "bcdec.h"
