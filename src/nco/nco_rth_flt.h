/* $Header: /data/zender/nco_20150216/nco/src/nco/nco_rth_flt.h,v 1.21 2006-01-20 18:29:39 zender Exp $ */

/* Purpose: Float-precision arithmetic */

/* Copyright (C) 1995--2005 Charlie Zender
   This software may be modified and/or re-distributed under the terms of the GNU General Public License (GPL) Version 2
   See http://www.gnu.ai.mit.edu/copyleft/gpl.html for full license text */

/* Usage:
   #include "nco_rth_flt.h" *//* Float-precision arithmetic */

#ifndef NCO_RTH_FLT_H
#define NCO_RTH_FLT_H

#ifdef HAVE_CONFIG_H
#include <config.h> /* Autotools tokens */
#endif /* !HAVE_CONFIG_H */

/* Standard header files */
#include <math.h> /* sin cos cos sin 3.14159 */

/* fxm stdio only needed for TODO ncap57 */
#include <stdio.h> /* stderr, FILE, NULL, etc. */
#include <stdlib.h> /* atof, atoi, malloc, getopt */

/* 3rd party vendors */
#include <netcdf.h> /* netCDF definitions and C library */
#include "nco_netcdf.h" /* NCO wrappers for netCDF C library */

/* Personal headers */

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#ifndef HPUX
  /* Math float prototypes required by AIX, Solaris, but not by Linux, IRIX
     20040708: HP-UX does not like these */
  /* Basic math: acos, asin, atan, cos, exp, fabs, log, log10, pow, sin, sqrt, tan */
  float acosf(float);
  float asinf(float);
  float atanf(float);
  float cosf(float);
  float expf(float);
  float fabsf(float);
  float logf(float);
  float log10f(float);
  float powf(float,float);
  float sinf(float);
  float sqrtf(float);
  float tanf(float);

  /* Advanced math: erf, erfc, gamma, rnd_nbr */
  float erff(float);
  float erfcf(float);
  float gammaf(float);
  float rnd_nbrf(float);

  /* Hyperbolic trigonometric: acosh, asinh, atanh, cosh, sinh, tanh */
  float acoshf(float);
  float asinhf(float);
  float atanhf(float);
  float coshf(float);
  float sinhf(float);
  float tanhf(float);

  /* Basic Rounding: ceil, floor */
  float ceilf(float);
  float floorf(float);

  /* Advanced Rounding: nearbyint, rint, round, trunc */
  float nearbyintf(float);
  float rintf(float);
  float roundf(float);
  float truncf(float);

#endif /* HPUX */

#ifdef __cplusplus
} /* end extern "C" */
#endif /* __cplusplus */

#endif /* NCO_RTH_FLT_H */
