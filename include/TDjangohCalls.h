//==============================================================================
/*!

    \file                         TDjangohCalls.h
    \brief                        Storage of C++ structure mimicking FORTRAN
                                  common blocks
    \author                       Nicolas PIERRE
    \version                      1.1
    \date                         14/06/17
    Support :                     mail to : nicolas.pierre@cern.ch

    Contact : nicolas.pierre@cern.ch

    Djangoh event generator, written by H.Spiesberger.
    For the details about the generator look at djangoh manual :
      http://wwwthep.physik.uni-mainz.de/~hspiesb/djangoh/djangoh.html

*/
//==============================================================================
/* @(#)root/djangoh:$Id$ */

#ifndef ROOT_TDjangohCalls
#define ROOT_TDjangohCalls


// int   const KSUSY1  =  1000000;
// int   const KSUSY2  =  2000000;
// int   const KEXCIT  =  4000000;
// int   const KNDCAY  =  8000; //should be 4000 for 1

/// Djangoh common block Lujets
struct Lujets_t
{
 int    N;
 int    NPAD;
 int    K[5][4000];
 float  P[5][4000];
 float  V[5][4000];
};

/// Djangoh common block Ludat1
struct Ludat1_t
{
 int    MSTU[200];
 double PARU[200];
 int    MSTJ[200];
 double PARJ[200];
};

/// Djangoh common block Ludat2
struct Ludat2_t
{
 int    KCHG[4][500];
 double PMAS[4][500];
 double PARF[2000];
 double VCKM[4][4];
};

/// Djangoh common block DJKIN
struct Djkin_t
{
 double DJX;
 double DJY;
 double DJW2;
 double DJQ2;
 double DJU;
 double DJXHAD;
 double DJYHAD;
 double DJQ2HAD;
};

#endif
