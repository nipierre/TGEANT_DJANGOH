      SUBROUTINE DJGSPH(L0,IMODE)
C***********************************************************************
C
C  DJGSPH
C
C  H.Spiesberger (05.07.99)
C  Interface to SOPHIA: Simulation of events with low mass and low Q2
C  for SOPHIA 1.5
C  update 08.08.2005 for djangoh, version 1.6
C
C***********************************************************************

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)
      COMMON /HSPARM/ POLARI,HPOLAR,LEPTID,LLEPT,LQUA
      COMMON /HSELAB/ SP,EELE,PELE,EPRO,PPRO
      COMMON /HSIKP/  S,T,UR,SS,TS,US,DKP,DKPS,DKQ,DKQS
      COMMON /HSCHNN/ ICHNN
      COMMON /DJPASS/ NTOT,NPASS,NFAILL
      COMMON /SPPASS/ NSOPH,NSPOUT,NFAILP,NSPACC
      COMMON /DJFAIL/ NFAILI(10)
      PARAMETER (NMXHEP=2000)
      COMMON /HEPEVT/ NEVHEP,NHEP,ISTHEP(NMXHEP),IDHEP(NMXHEP),
     &                JMOHEP(2,NMXHEP),JDAHEP(2,NMXHEP),
     &                PHEP(5,NMXHEP),VHKK(4,NMXHEP)
      COMMON /S_PLIST/ P_S(2000,5), LLIST(2000), NP, Ideb
      COMMON/LUJETS/N,K(4000,5),P(4000,5),V(4000,5)
      REAL*4 P,V
      COMMON /LEPTOU/ CUT(14),LST(40),PARL(30),X,Y,W2,Q2,U
C      REAL            CUT            ,PARL    ,X,Y,W2,Q2,U
      SAVE
      DIMENSION P_gam(4),P_nuc(4)
      LOGICAL FIRST
      DATA FIRST/.TRUE./

C...Header
      IF (FIRST) THEN
        FIRST=.FALSE.
        WRITE(6,9)
 9      FORMAT(
     1'**************************************************',
     2'*****************************',
     3//,10X,'                      Calling SOPHIA '
     4//,10X,' Event generator for photohadronic processes in'
     4,' astrophysics '
     6//,10X,'                       VERSION 1.5, '/
     7//,10X,'          by A.M"ucke, Ralph Engel, J.P.Rachen, '
     8//,10X,'            R.J.Protheroe, and Todor Stanev'
     9//,10X,'         Comput.Phys.Commun. 124 (2000) 290-314',//
     9' **************************************************',
     1'****************************',//)
      CALL INITIAL(13)
      ENDIF

C...Event accepted by HERACLES
      NTOT=NTOT+1
C...reset counters for failed trials
      DO 1 INF=1,10
 1    NFAILI(INF)=0
      NSPACC=0
      NFLMAX=10

C...Determine momentum of virtual incoming photon
      IF (ICHNN.LE.2) THEN
C...non-radiative channels
        P_gam(1)=    -PHEP(1,1)
        P_gam(2)=    -PHEP(2,1)
        P_gam(3)=PELE-PHEP(3,1)
        P_gam(4)=EELE-PHEP(4,1)
        Q2=-T
      ELSE
C...radiative channels
        P_gam(1)=    -PHEP(1,1)-PHEP(1,3)
        P_gam(2)=    -PHEP(2,1)-PHEP(2,3)
        P_gam(3)=PELE-PHEP(3,1)-PHEP(3,3)
        P_gam(4)=EELE-PHEP(4,1)-PHEP(4,3)
        Q2=-TS
      ENDIF

C...Determine momentum of incoming nucleon
      P_nuc(1)=0D0
      P_nuc(2)=0D0
      P_nuc(3)=-PPRO
      P_nuc(4)=EPRO

      N=0
      NFAILS=0
C...Generate hadronic final state
  2   LST(21)=99
      CALL SOPHIA(L0,P_gam,P_nuc,Imode)
c      call print_event(1)
      IF (NP.EQ.0) THEN
        NFAILS=NFAILS+1
        IF (NFAILS.LT.NFLMAX) GOTO 2
        GOTO 30
      ENDIF
C...Event passed fragmentation
      IF (NP.NE.0) THEN
        LST(21)=0
        LST(36)=2
        NSOPH=NSOPH+1
        NSPACC=1
      ENDIF

      IP1=0
C...Set initial state, first lepton:
      IP1=IP1+1
      K(IP1,1)=21
      K(IP1,2)=-LLEPT*10-LEPTID
      K(IP1,3)=0
      K(IP1,4)=0
      K(IP1,5)=0
      P(IP1,1)=0.
      P(IP1,2)=0.
      P(IP1,3)=PELE
      P(IP1,4)=EELE
      IF (K(IP1,2).EQ.-11.OR.K(IP1,2).EQ.11) THEN
        P(IP1,5)= 0.000511
      ELSE IF (K(IP1,2).EQ.-13.OR.K(IP1,2).EQ.13) THEN
        P(IP1,5)= 0.10566
      ENDIF
C...then nucleon = proton
      IP1=IP1+1
      K(IP1,1)=21
      K(IP1,2)=2212
      K(IP1,3)=0
      K(IP1,4)=0
      K(IP1,5)=0
      P(IP1,1)=0.
      P(IP1,2)=0.
      P(IP1,3)=-PPRO
      P(IP1,5)=0.938272
      P(IP1,4)=EPRO

C...Virtual boson (non-radiative case)
      IP1=IP1+1
      K(IP1,1)=21
      K(IP1,2)=23
      K(IP1,3)=1
      K(IP1,4)=0
      K(IP1,5)=0
      IF(ICHNN.EQ.1.OR.ICHNN.EQ.2) THEN
        DO 10 JG=1,4
          P(IP1,JG)=P(1,JG)-PHEP(JG,1)
 10     CONTINUE
        P(IP1,5)=-SQRT(Q2)
      ELSE
C...Virtual boson (radiative case)
        DO 11 JG=1,4
c...corrected (pointed out by VL: 14.08.05)
c          P(IP1,JG)=P(1,JG)-PHEP(JG,1)-P(JG,3)
          P(IP1,JG)=P(1,JG)-PHEP(JG,1)-PHEP(JG,3)
 11     CONTINUE
        P(IP1,5)=-SQRT(Q2)
      ENDIF

C...scattered lepton
      IP1=IP1+1
      DO 12 J=1,5
        P(IP1,J)=PHEP(J,1)
 12   CONTINUE
      WRITE(33,*) IP1
      WRITE(33,*) P(IP1,1),P(IP1,2),P(IP1,3),P(IP1,4),P(IP1,5)
      K(IP1,1)=ISTHEP(1)
      K(IP1,2)=IDHEP(1)
      K(IP1,3)=1
      K(IP1,4)=JDAHEP(1,1)
      K(IP1,5)=JDAHEP(2,1)
C...radiative photon
      IF (ICHNN.GT.2) THEN
        IP1=IP1+1
        DO 13 J=1,5
          P(IP1,J)=PHEP(J,3)
 13     CONTINUE
        WRITE(33,*) IP1
        WRITE(33,*) P(IP1,1),P(IP1,2),P(IP1,3),P(IP1,4),P(IP1,5)
        K(IP1,1)=ISTHEP(3)
        K(IP1,2)=IDHEP(3)
        K(IP1,3)=1
        IF(ICHNN.EQ.6.OR.ICHNN.EQ.8.OR.ICHNN.EQ.12) THEN
          K(IP1,3)=1
        ELSE
          K(IP1,3)=4
        ENDIF
        K(IP1,4)=JDAHEP(1,3)
        K(IP1,5)=JDAHEP(2,3)
      ENDIF

C...Hadronic final state from SOPHIA
      DO 20 IP=1,NP
        IF (ABS(LLIST(IP)).LT.50) THEN
          IP1=IP1+1
          WRITE(33,*) IP, IP1
          WRITE(33,*) P_S(IP,1),P_S(IP,2),P_S(IP,3),P_S(IP,4),P_S(IP,5)
          P(IP1,1)=P_S(IP,1)
          P(IP1,2)=P_S(IP,2)
          P(IP1,3)=P_S(IP,3)
          P(IP1,4)=P_S(IP,4)
          P(IP1,5)=P_S(IP,5)
          WRITE(33,*) P(IP1,1),P(IP1,2),P(IP1,3),P(IP1,4),P_S(IP,5)
          K(IP1,1)=1
          K(IP1,2)=ICON_SIB_PDG(LLIST(IP))
          K(IP1,3)=0
          K(IP1,4)=0
          K(IP1,5)=0
        ENDIF
 20   CONTINUE
      N=IP1
      RETURN

 30   CALL SPHLEV
      NFAILP=NFAILP+1
      RETURN

      END

C***********************************************************************

      SUBROUTINE DJGNOE
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)
      COMMON /SPPASS/ NSOPH,NSPOUT,NFAILP,NSPACC
      PARAMETER (NMXHEP=2000)
      COMMON /HEPEVT/ NEVHEP,NHEP,ISTHEP(NMXHEP),IDHEP(NMXHEP),
     &                JMOHEP(2,NMXHEP),JDAHEP(2,NMXHEP),
     &                PHEP(5,NMXHEP),VHKK(4,NMXHEP)
      COMMON/LUJETS/N,K(4000,5),P(4000,5),V(4000,5)
      REAL*4 P,V
      COMMON /LEPTOU/ CUT(14),LST(40),PARL(30),X,Y,W2,Q2,U
      SAVE
      N=0
      LST(21)=99
      NSPOUT=NSPOUT+1
      RETURN
      END

C***********************************************************************

      SUBROUTINE SPHLEV
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)
Chs...Restore event record from SOPHIA when hadronization has failed
      COMMON /HSPARM/ POLARI,HPOLAR,LEPTID,LLEPT,LQUA
      COMMON /HSELAB/ SP,EELE,PELE,EPRO,PPRO
      COMMON/LUJETS/N,K(4000,5),P(4000,5),V(4000,5)
      COMMON /LEPTOU/ CUT(14),LST(40),PARL(30),X,Y,W2,Q2,U
      PARAMETER (NMXHEP=2000)
      COMMON /HSCHNN/ ICHNN
      double precision PHEP,VHKK
      COMMON /HEPEVT/ NEVHEP,NHEP,ISTHEP(NMXHEP),IDHEP(NMXHEP),
     &             JMOHEP(2,NMXHEP),JDAHEP(2,NMXHEP),
     &             PHEP(5,NMXHEP),VHKK(4,NMXHEP)

C...Set initial state, first lepton:
      K(1,1)=21
      K(1,2)=-LLEPT*10-LEPTID
      K(1,3)=0
      K(1,4)=0
      K(1,5)=0
      P(1,1)=0.
      P(1,2)=0.
      P(1,3)=PELE
      IF (K(1,2).EQ.-1.OR.K(1,2).EQ.1) THEN
        P(1,5)= 0.000511
      ELSE IF (K(1,2).EQ.-3.OR.K(1,2).EQ.3) THEN
        P(1,5)= 0.10566
      ENDIF
      P(1,4)=SQRT(P(1,3)**2+P(1,5)**2)

C...then nucleon = proton
      K(2,1)=21
      K(2,2)=2212
      K(2,3)=0
      K(2,4)=0
      K(2,5)=0
      P(2,1)=0.
      P(2,2)=0.
      P(2,3)=-PPRO
      P(2,5)=0.938272
      P(2,4)=EPRO

C...Final electron from HS
      DO 20 J=1,5
   20 P(4,J)=PHEP(J,1)
      K(4,1)=ISTHEP(1)
      K(4,2)=IDHEP(1)
      K(4,3)=1
      K(4,4)=JDAHEP(1,1)
      K(4,5)=JDAHEP(2,1)
      N=4

C...Bremsstrahlung photon
      IF (ICHNN.EQ.6.OR.ICHNN.EQ.7.OR.ICHNN.EQ.8
     &   .OR.ICHNN.EQ.12) THEN
        N=N+1
        K(5,1)=ISTHEP(3)
        K(5,2)=IDHEP(3)
C...radiated gamma has origin in e or e'
        IF(ICHNN.EQ.6.OR.ICHNN.EQ.8.OR.ICHNN.EQ.12) THEN
          K(5,3)=1
        ELSE
          K(5,3)=4
        ENDIF
        K(5,4)=JDAHEP(1,3)
        K(5,5)=JDAHEP(2,3)
        DO 30 J=1,5
   30   P(5,J)=PHEP(J,3)
        DO 40 JV=1,4
   40   V(5,JV)=VHKK(JV,3)
C...virtual boson (radiative case)
        DO 50 JG=1,4
   50   P(3,JG)=P(1,JG)-PHEP(JG,1)-PHEP(JG,3)
        P(3,5)=-SQRT(Q2)
      ELSEIF(ICHNN.EQ.1.OR.ICHNN.EQ.2) THEN
C...virtual boson (non-radiative case)
        DO 60 JG=1,4
   60   P(3,JG)=P(1,JG)-PHEP(JG,1)
        P(3,5)=-SQRT(Q2)
      ENDIF
      K(3,1)=21
      K(3,2)=23
      K(3,3)=1
      K(3,3)=1
      K(3,5)=0

C...Unfragmented hadronic final state
C...scattered quark
      N=N+1
      DO 70 J=1,5
   70 P(N,J)=PHEP(J,2)
      K(N,1)=ISTHEP(2)
      K(N,2)=IDHEP(2)
      K(N,3)=1
      K(N,4)=JDAHEP(1,2)
      K(N,5)=JDAHEP(2,2)
C...spectator
      N=N+1
      DO 80 J=1,5
   80 P(N,J)=PHEP(J,4)
      K(N,1)=ISTHEP(4)
      K(N,2)=IDHEP(4)
      K(N,3)=1
      K(N,4)=JDAHEP(1,4)
      K(N,5)=JDAHEP(2,4)

      RETURN
      END

C***********************************************************************

       subroutine SOPHIA(L0,P_gam,P_nuc,Imode)
C***********************************************************************
C
C  SOPHIA 1.5
C
C  A. M\"ucke, R. Engel, J.P. Rachen, R.J. Protheroe, and T. Stanev:
C  {\it SOPHIA -- Monte Carlo simulations for photohadronic processes in
C  astrophysics.} BA-99-33 (astro-ph/9903478),
C  submitted to Comp. Phys. Commun.
C
C***********************************************************************

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)
      SAVE

      DIMENSION P_gam(4),P_nuc(4)

       COMMON /S_RUN/ SQS, S, Q2MIN, XMIN, ZMIN, kb, kt, a1, a2, Nproc
       COMMON /S_PLIST/ SP(2000,5), LLIST(2000), NP, Ideb
       COMMON /S_MASS1/ AM(49), AM2(49)
       COMMON /S_CHP/ S_LIFE(49), ICHP(49), ISTR(49), IBAR(49)
       COMMON /S_CSYDEC/ CBR(102), IDB(49), KDEC(612), LBARP(49)

      CHARACTER NAMPRES*6
      COMMON /RES_PROP/ AMRES(9), SIG0(9),WIDTH(9),
     +                    NAMPRES(0:9)

      CHARACTER NAMPRESp*6
      COMMON /RES_PROPp/ AMRESp(9), BGAMMAp(9),WIDTHp(9),
     +                    RATIOJp(9),NAMPRESp(0:9)

      CHARACTER NAMPRESn*6
      COMMON /RES_PROPn/ AMRESn(9), BGAMMAn(9),WIDTHn(9),
     +                    RATIOJn(9),NAMPRESn(0:9)

       DOUBLE PRECISION P_sum(4),PC(4),GamBet(4)

c       DATA pi /3.141593D0/
       DATA pm /0.93827D0/
       DATA IRESMAX /9/
       DATA Icount / 0 /
       data iphpi / 0 /

c****** INPUT **************************************************
c E0 = energy of incident proton (in lab frame) [in GeV]
c eps = energy of incident photon [in GeV] (in lab frame)
c theta = angle between incident proton and photon [in degrees]
c L0 = code number of the incident nucleon
c***************************************************************
c** calculate eps_prime = photon energy in nuclear rest frame,
c**             sqrt(s) = CMF energy of the N\gamma-system

       Esum  = P_nuc(4)+P_gam(4)
       PXsum = P_nuc(1)+P_gam(1)
       PYsum = P_nuc(2)+P_gam(2)
       PZsum = P_nuc(3)+P_gam(3)
       IQchr = ICHP(1)+ICHP(L0)
       IQbar = IBAR(1)+IBAR(L0)


C  calculate Lorentz boost and rotation
       P_sum(1) = P_nuc(1)+P_gam(1)
       P_sum(2) = P_nuc(2)+P_gam(2)
       P_sum(3) = P_nuc(3)+P_gam(3)
       P_sum(4) = P_nuc(4)+P_gam(4)

       s = (P_sum(4)-P_sum(3))*(P_sum(4)+P_sum(3))
     &     -P_sum(1)**2-P_sum(2)**2

       sqsm = sqrt(s)

       eps_prime = (s-pm*pm)/2.D0/pm
C  Lorentz transformation into c.m. system
      DO I=1,4
        GamBet(I) = P_sum(I)/sqsm
      ENDDO
C  calculate rotation angles
      IF(GamBet(4).lt.1.d5) then
C  transform nucleon vector
        GamBet(1) = -GamBet(1)
        GamBet(2) = -GamBet(2)
        GamBet(3) = -GamBet(3)
        CALL PO_ALTRA(GamBet(4),GamBet(1),GamBet(2),GamBet(3),
     &                P_nuc(1),P_nuc(2),P_nuc(3),P_nuc(4),Ptot,
     &                PC(1),PC(2),PC(3),PC(4))
        GamBet(1) = -GamBet(1)
        GamBet(2) = -GamBet(2)
        GamBet(3) = -GamBet(3)
C  rotation angle: nucleon moves along +z
        COD = PC(3)/Ptot
        SID = SQRT(PC(1)**2+PC(2)**2)/Ptot
        COF = 1.D0
        SIF = 0.D0
        IF(Ptot*SID.GT.1.D-5) THEN
          COF=PC(1)/(SID*Ptot)
          SIF=PC(2)/(SID*Ptot)
          Anorf=SQRT(COF*COF+SIF*SIF)
          COF=COF/Anorf
          SIF=SIF/Anorf
        ENDIF
      else
        COD = 1.D0
        SID = 0.D0
        COF = 1.D0
        SIF = 0.D0
      endif

c... check for threshold:
       sth = 1.1646D0
       if (s.lt.sth) then
        iphpi=iphpi+1
        if (iphpi.le.10) then
        print*,'input energy below threshold for photopion production !'
        print*,'sqrt(s) = ',sqrt(s)
        print*,'only first 10 warnings printed'
        endif
        NP = 0
        RETURN
       endif

 200  continue
      Icount = Icount+1
      Imode = 0

c*******************************************************************
c decide which process occurs:                                   ***
c (1) decay of resonance                                         ***
c (2) direct pion production (interaction of photon with         ***
c     virtual pions in nucleon cloud) and diffractive scattering ***
c (3) multipion production                                       ***
c*******************************************************************

       call dec_inter3(eps_prime,Imode,L0)

c*********************************************
c******* PARTICLE PRODUCTION *****************
c*********************************************
c  42   continue
       if (Imode.le.5) then
c... direct/multipion/diffractive scattering production channel:
        call GAMMA_H(sqsm,L0,Imode,Ifbad)
        if(Ifbad.ne.0) then
          print *,' eventgen: simulation of particle production failed'
          goto 200
        endif
       else if (Imode.eq.6) then
c... Resonances:
c... decide which resonance decays with ID=IRES in list:
c... IRESMAX = number of considered resonances = 9 so far
       IRES = 0
 46    call dec_res2(eps_prime,IRES,IRESMAX,L0)
       Nproc = 10+IRES
       call dec_proc2(eps_prime,IPROC,IRANGE,IRES,L0)
c 2-particle decay of resonance in CM system:
       NP = 2
       call res_decay3(IRES,IPROC,IRANGE,s,L0,nbad)
       if (nbad.eq.1) then
         print *,' eventgen: event rejected by res_decay3'
         goto 46
       endif
       call DECSIB
       else
        print*,'invalid Imode !!'
        STOP
       endif

c... consider only stable particles:
 18     istable=0
        do 16 i=1,NP
         if (abs(LLIST(i)).lt.10000) then
          istable = istable+1
          LLIST(istable) = LLIST(i)
          SP(istable,1) = SP(i,1)
          SP(istable,2) = SP(i,2)
          SP(istable,3) = SP(i,3)
          SP(istable,4) = SP(i,4)
          SP(istable,5) = SP(i,5)
         endif
  16    continue
        if (NP.gt.istable) then
         do i=istable+1,NP
          LLIST(i) = 0
          SP(i,1) = 0.
          SP(i,2) = 0.
          SP(i,3) = 0.
          SP(i,4) = 0.
          SP(i,5) = 0.
         enddo
        endif
        NP = istable

c***********************************************
c transformation from CM-system to lab-system: *
c***********************************************

      DO I=1,NP
        CALL PO_TRANS(SP(I,1),SP(I,2),SP(I,3),COD,SID,COF,SIF,
     &    PC(1),PC(2),PC(3))
        PC(4) = SP(I,4)
        CALL PO_ALTRA(GamBet(4),GamBet(1),GamBet(2),GamBet(3),
     &    PC(1),PC(2),PC(3),PC(4),Ptot,
     &    SP(I,1),SP(I,2),SP(I,3),SP(I,4))
      ENDDO

      call check_event(Icount,Esum,PXsum,PYsum,PZsum,IQchr,IQbar,Irej)
      if(Irej.ne.0) then
        print *,' eventgen: event rejected by check_event'
        goto 200
      endif

      return

      END


c*****************************
c*** List of SUBROUTINES *****
C*****************************



      SUBROUTINE INITIAL(L0)

c*******************************************************************
c initialization routine
c*******************************************************************
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)
      SAVE
      COMMON /RES_PROP/ AMRES(9),SIG0(9),WIDTH(9),
     +                    NAMPRES(0:9)
      COMMON /RES_PROPp/ AMRESp(9), BGAMMAp(9),WIDTHp(9),
     +                    RATIOJp(9),NAMPRESp(0:9)
      COMMON /RES_PROPn/ AMRESn(9), BGAMMAn(9),WIDTHn(9),
     +                    RATIOJn(9),NAMPRESn(0:9)
      COMMON /S_MASS1/ AM(49), AM2(49)
      CHARACTER NAMPRESp*6, NAMPRESn*6
      CHARACTER NAMPRES*6
C...for interface to DJANGOH
      COMMON /SPPASS/ NSOPH,NSPOUT,NFAILP,NSPACC

      NSOPH=0
      NSPOUT=0
      NFAILP=0

*      print *,'settings of resonance parameters:'
*      print *,
*    &   'name, nom.mass [GeV], width [GeV], sigma0 [mub], bgamma*10^3'

       if (L0.eq.13) then
       do i=1,9
        SIG0(i) = 4.893089117D0/AM2(13)*RATIOJp(i)*BGAMMAp(i)
        AMRES(i) = AMRESp(i)
        WIDTH(i) = WIDTHp(i)
        NAMPRES(i) = NAMPRESp(i)
*      print*,NAMPRES(i), real(AMRES(i)), real(WIDTH(i)),
*    &          real(SIG0(i)), real(BGAMMAp(i))
       enddo
       endif

       if (L0.eq.14) then
       do i=1,9
        SIG0(i) = 4.893089117D0/AM2(14)*RATIOJn(i)*BGAMMAn(i)
        AMRES(i) = AMRESn(i)
        WIDTH(i) = WIDTHn(i)
        NAMPRES(i) = NAMPRESn(i)
*      print*,NAMPRES(i), real(AMRES(i)), real(WIDTH(i)),
*    &         real(SIG0(i)), real(BGAMMAn(i))
       enddo
       endif

       RETURN
       END


      DOUBLE PRECISION function crossection(x,NDIR,NL0)

      IMPLICIT DOUBLE PRECISION (A-M,O-Z)
      IMPLICIT INTEGER (N)

      SAVE

      CHARACTER NAMPRES*6
      COMMON /RES_PROP/ AMRES(9), SIG0(9),WIDTH(9),
     +                    NAMPRES(0:9)

      DIMENSION sig_res(9)

       external breitwigner, Ef, singleback, twoback

       DATA pm /0.93827D0/
       DATA sth /1.1646D0/

c*****************************************************
C calculates crossection of N-gamma-interaction
C (see thesis of J.Rachen, p.45ff and corrections
C  report from 27/04/98, 5/05/98, 22/05/98 of J.Rachen)
C*****************************************************
c** Date: 20/01/98   **
c** correct.:27/04/98**
c** update: 23/05/98 **
c** author: A.Muecke **
c**********************
c
c x = eps_prime in GeV
c       x = eps_prime
       s = pm*pm+2.D0*pm*x

       if (s.lt.sth) then
c       if (x.lt.0.15275) then
        crossection = 0.
c        print*,'BELOW P\GAMMA THRESHOLD !'
        RETURN
       endif
       if (x.gt.10.D0) then
c only multipion production:
        cross_res = 0.D0
        cross_dir = 0.D0
        cross_dir1 = 0.D0
        cross_dir2 = 0.D0
        goto 10
       endif

c****************************
c RESONANCES:
c****************************

      cross_res = 0.D0

       cross_res = breitwigner(SIG0(1),WIDTH(1),AMRES(1),x)
     &              *Ef(x,0.152D0,0.17D0)
       sig_res(1) = cross_res
      DO N=2,9

        sig_res(N) = breitwigner(SIG0(N),WIDTH(N),AMRES(N),x)
     &              *Ef(x,0.15D0,0.38D0)
        cross_res = cross_res + sig_res(N)

      ENDDO

c****************************
c DIRECT CHANNEL:
c****************************

       if((x.gt.0.1D0).and.(x.lt.0.6D0)) then
         cross_dir1 = singleback(x)
     &               + 40.D0*exp(-(x-0.29D0)**2/0.002D0)
     &               - 15.D0*exp(-(x-0.37D0)**2/0.002D0)
       else
         cross_dir1 = singleback(x)
       endif
       cross_dir2 = twoback(x)

       cross_dir = cross_dir1 + cross_dir2

c****************************
c FRAGMENTATION 2:
c****************************
 10   continue
       if (NL0.eq.13) then
        cross_frag2 = 80.3D0*Ef(x,0.5D0,0.1D0)*(s**(-0.34D0))
       else if (NL0.eq.14) then
c        cross_frag2 = 72.3*Ef(x,0.5D0,0.1D0)*(s**(-0.34))
        cross_frag2 = 60.2D0*Ef(x,0.5D0,0.1D0)*(s**(-0.34D0))
       endif

c****************************************************
c MULTIPION PRODUCTION/FRAGMENTATION 1 CROSS SECTION
c****************************************************
       if (x.gt.0.85D0) then
        ss1 = (x-.85D0)/.69D0
        if (NL0.eq.13) then
         ss2 = 29.3D0*(s**(-.34D0))+59.3D0*(s**.095D0)
        else if (NL0.eq.14) then
         ss2 = 26.4D0*(s**(-.34D0))+59.3D0*(s**.095D0)
        endif
        cs_multidiff = (1.-exp(-ss1))*ss2
        cs_multi = 0.89D0*cs_multidiff

c****************************
c DIFFRACTIVE SCATTERING:
c****************************

        ss1 = ((x-.85D0)**.75D0)/.64D0
        ss2 = 74.1D0*(x**(-.44D0))+62.D0*(s**.08D0)
        cs_tmp = 0.96D0*(1.D0-exp(-ss1))*ss2
        cross_diffr1 = 0.14D0*cs_tmp
        cross_diffr2 = 0.013D0*cs_tmp
        cs_delta = cross_frag2 - (cross_diffr1+cross_diffr2-cross_diffr)
        if(cs_delta.lt.0.D0) then
          cross_frag2 = 0.D0
          cs_multi = cs_multi+cs_delta
        else
          cross_frag2 = cs_delta
        endif
        cross_diffr = cross_diffr1 + cross_diffr2
        cs_multidiff = cs_multi + cross_diffr

       else
        cross_diffr = 0.D0
        cross_diffr1 = 0.D0
        cross_diffr2 = 0.D0
        cs_multidiff = 0.D0
        cs_multi = 0.D0
       endif

       if (NDIR.eq.3) then

        crossection = cross_res+cross_dir+cs_multidiff+cross_frag2
        RETURN

       else if (NDIR.eq.0) then

        crossection = cross_res+cross_dir+cross_diffr+cross_frag2
        RETURN

       else if (NDIR.eq.2) then

        crossection = cross_res+cross_dir
        RETURN

       else if (NDIR.eq.1) then

        crossection = cross_res
        RETURN

       else if (NDIR.eq.4) then

        crossection = cross_dir
        RETURN

       else if (NDIR.eq.5) then

        crossection = cs_multi
        RETURN

       else if (NDIR.eq.6) then

        crossection = cross_res+cross_dir2
        RETURN

       else if (NDIR.eq.7) then

        crossection = cross_res+cross_dir1
        RETURN

       else if (NDIR.eq.8) then

        crossection = cross_res+cross_dir+cross_diffr1
        RETURN

       else if (NDIR.eq.9) then

        crossection = cross_res+cross_dir+cross_diffr
        RETURN

       else if (NDIR.eq.10) then

        crossection = cross_diffr
        RETURN

       else if ((NDIR.ge.11).and.(NDIR.le.19)) then

        crossection = sig_res(NDIR-10)
        RETURN

       else

        print*,'wrong input NDIR in crossection.f !'
        STOP

       endif

       END


       DOUBLE PRECISION function breitwigner(sigma_0,Gamma,
     &                     DMM,eps_prime)

       IMPLICIT DOUBLE PRECISION (A-M,O-Z)
       IMPLICIT INTEGER (N)

       SAVE

c***************************************************************************
c calculates Breit-Wigner cross section of a resonance with width Gamma [GeV],
c mass DMM [GeV], max. cross section sigma_0 [mubarn] and total mass of the
c interaction s [GeV]
c***************************************************************************
       pm = 0.93827D0
       s = pm*pm+2.D0*pm*eps_prime
       gam2s = Gamma*Gamma*s
       breitwigner = sigma_0
     &              *(s/eps_prime**2)*gam2s/((s-DMM*DMM)**2+gam2s)

       RETURN

       END


      DOUBLE PRECISION function Pl(x,xth,xmax,alpha)

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)

       SAVE

       if (xth.gt.x) then
        Pl = 0.
        RETURN
       endif

       a = alpha*xmax/xth
       prod1 = ((x-xth)/(xmax-xth))**(a-alpha)
       prod2 = (x/xmax)**(-a)
       Pl = prod1*prod2

       END


      DOUBLE PRECISION function Ef(x,th,w)

      IMPLICIT DOUBLE PRECISION (A-M,O-Z)
      IMPLICIT INTEGER (N)

       SAVE

       wth = w+th
       if (x.le.th) then
        Ef = 0.
        RETURN
       else if (x.gt.th.and.x.lt.wth) then
        Ef = (x-th)/w
        RETURN
       else if (x.ge.wth) then
        Ef = 1.
        RETURN
       else
        print*,'error in function EF'
        STOP
       endif

       END



      subroutine dec_inter3(eps_prime,Imode,L0)

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)
      SAVE

       DOUBLE PRECISION RNDM
       external RNDM

c*** decides which process takes place at eps_prime ********
c (6) excitation/decay of resonance                      ***
c (2) direct pion production: N\gamma --> N \pi          ***
c (3) direct pion production: N\gamma --> \Delta \pi     ***
c (1) diffractive scattering: N\gamma --> N \rho         ***
c (4) diffractive scattering: N\gamma --> N \omega       ***
c (0) multipion production (fragmentation)               ***
c (5) fragmentation in resonance region                  ***
c***********************************************************
c** Date: 15/04/98   **
c** author: A.Muecke **
c**********************
       tot = crossection(eps_prime,3,L0)
       if (tot.eq.0.) tot = 1.D0
       prob1 = crossection(eps_prime,1,L0)/tot
       prob2 = crossection(eps_prime,7,L0)/tot
       prob3 = crossection(eps_prime,2,L0)/tot
       prob4 = crossection(eps_prime,8,L0)/tot
       prob5 = crossection(eps_prime,9,L0)/tot
       prob6 = crossection(eps_prime,0,L0)/tot
       prob7 = 1.D0
       rn = RNDM(0)
       if (rn.lt.prob1) then
        Imode = 6
c ... --> resonance decay
        RETURN
       else if (prob1.le.rn.and.rn.lt.prob2) then
        Imode = 2
c ... --> direct channel: N\gamma --> N\pi
        RETURN
       else if (prob2.le.rn.and.rn.lt.prob3) then
        Imode = 3
c ... --> direct channel: N\gamma --> \Delta \pi
        RETURN
       else if (prob3.le.rn.and.rn.lt.prob4) then
        Imode = 1
c ... --> diffractive scattering: N\gamma --> N \rho
        RETURN
       else if (prob4.le.rn.and.rn.lt.prob5) then
        Imode = 4
c ... --> diffractive scattering: N\gamma --> N \omega
        RETURN
       else if (prob5.le.rn.and.rn.lt.prob6) then
        Imode = 5
c ... --> fragmentation (2) in resonance region
        return
       else if (prob6.le.rn.and.rn.lt.1.) then
        Imode = 0
c ... --> fragmentation mode/multipion production
        RETURN
       else if (rn.eq.1.D0) then
        Imode = 0
        RETURN
       else
        print*,'error in dec_inter.f !'
        STOP
       endif

        END


      SUBROUTINE PROC_TWOPART(LA,LB,AMD,Lres,Pres,costheta,nbad)

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)

      COMMON /S_MASS1/ AM(49), AM2(49)
      COMMON /RES_FLAG/ FRES(49),XLIMRES(49)
      SAVE
      DIMENSION Pres(2000,5),Lres(2000)

c***********************************************************
c  2-particle decay of CMF mass AMD INTO  M1 + M2
C  NUCLEON ENERGY E0 [in GeV];
C  E1,E2 [in GeV] are energies of decay products
c  LA,LB are code numbers of decay products
c  P1(1:5),P2(1:5) are 5-momenta of particles LA,LB;
c  resulting momenta are calculated in CM frame;
c  costheta is cos of scattering angle in CM frame
c  this program also checks if the resulting particles are
c  resonances; if yes, it is also allowed to decay a
c  mass AMD < M1 + M2 by using the width of the resonance(s)
c***********************************************************
c** Date: 20/01/98   **
c** correct.:19/02/98**
c** author: A.Muecke **
c**********************

        nbad = 0
c        ND = 2
        SM1 = AM(LA)
        if (LB.eq.0) then
c... for Landau-Model:
         SM2 = 2.D0*AM(7)
        else
         SM2 = AM(LB)
        endif
	E1 = (AMD*AMD + SM1*SM1 - SM2*SM2)/AMD/2.D0
	E2 = (AMD*AMD + SM2*SM2 - SM1*SM1)/AMD/2.D0
c... check if SM1+SM2 < AMD:
        if ((SM1+SM2).gt.AMD) then
c... if one of the decay products is a resonance, this 'problem' can
c    be solved by using a reduced mass for the resonance and assume that
c    this resonance is produced at its threshold;
         if (FRES(LA).eq.1.D0) then
c ...      particle LA is a resonance:
          SM1 = AMD-SM2
	  E1 = SM1
	  E2 = AMD-E1
         if (E1.lt.XLIMRES(LA).or.E2.lt.XLIMRES(LB)) nbad = 1
         endif
        if (FRES(LB).eq.1.D0) then
c ...      particle LB is a resonance:
          SM2 = AMD-SM1
	  E2 = SM2
         E1 = AMD-E2
          if (E1.lt.XLIMRES(LA).or.E2.lt.XLIMRES(LB)) nbad = 1
         endif
c ...     both particles are NOT resonances: -> error !
         if (FRES(LA).eq.0.D0.and.FRES(LB).eq.0.D0) then
          print*,'SM1 + SM2 > AMD in PROC_TWOPART',SM1,SM2,AMD,LA,LB
          STOP
         endif
        endif

       if (nbad.eq.0) then
	PC = SQRT((E1*E1 - SM1*SM1))
        Pres(1,4) = E1
        Pres(2,4) = E2
        Pres(1,5) = SM1
        Pres(2,5) = SM2


C *********************************************************
c theta is scattering angle in CM frame:
        r = RNDM(0)
        P1Z= PC*costheta
        P2Z=-PC*costheta

        P1X = sqrt(r*(PC*PC-P1Z*P1Z))
        P2X = sqrt(r*(PC*PC-P2Z*P2Z))
        P1Y = sqrt((1.D0-r)*(PC*PC-P1Z*P1Z))
        P2Y = sqrt((1.D0-r)*(PC*PC-P2Z*P2Z))
        if(RNDM(0).lt.0.5D0) then
          P1X = -P1X
        else
          P2X = -P2X
        endif
        if(RNDM(0).lt.0.5D0) then
          P1Y = -P1Y
        else
          P2Y = -P2Y
        endif

        Pres(1,1) = P1X
        Pres(1,2) = P1Y
        Pres(1,3) = P1Z
        Pres(2,1) = P2X
        Pres(2,2) = P2Y
        Pres(2,3) = P2Z
        Lres(1) = LA
        Lres(2) = LB
       endif

        RETURN

        END


      subroutine dec_res2(eps_prime,IRES,IRESMAX,L0)

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)

       SAVE

c*****************************************************************************
c*** decides which resonance with ID=IRES in list takes place at eps_prime ***
c*****************************************************************************
c** Date: 20/01/98   **
c** author: A.Muecke **
c**********************

       DIMENSION prob_sum(9)
c       CHARACTER NAMPRESp*6,NAMPRESn*6


c*** sum of all resonances:
       sumres = 0.D0
       do 12 j=1,IRESMAX
        j10 = j+10
        sumres = sumres+crossection(eps_prime,j10,L0)
        prob_sum(j) = sumres
  12   continue


       r = RNDM(0)

       IRES = 0
       i = 0
       prob = 0.D0
 10    continue
       i = i+1
       probold = prob
       prob = prob_sum(i)/sumres
       if (r.ge.probold.and.r.lt.prob) then
         IRES = i
         RETURN
       endif
       if (i.lt.IRESMAX) goto 10
       if (r.eq.1.D0) IRES = i
       if (IRES.eq.0) then
         print*,'no resonance possible !'
         STOP
       endif

       RETURN

       END


      subroutine dec_proc2(x,IPROC,IRANGE,IRES,L0)

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)

       SAVE

c**********************************************************************
c*** decide which decay with ID=IPROC of resonance IRES takes place ***
c**********************************************************************
c** Date: 20/01/98   **
c** correct.: 27/04/98*
c** author: A.Muecke **
c**********************

       COMMON /S_RESp/ CBRRES1p(18),CBRRES2p(36),CBRRES3p(26),
     +  RESLIMp(36),ELIMITSp(9),KDECRES1p(90),KDECRES2p(180),
     +  KDECRES3p(130),IDBRES1p(9),IDBRES2p(9),IDBRES3p(9)
       COMMON /S_RESn/ CBRRES1n(18),CBRRES2n(36),CBRRES3n(22),
     +  RESLIMn(36),ELIMITSn(9),KDECRES1n(90),KDECRES2n(180),
     +  KDECRES3n(110),IDBRES1n(9),IDBRES2n(9),IDBRES3n(9)
       DIMENSION prob_sum(0:9)

c      x = eps_prime
c ... choose arrays /S_RESp/ for charged resonances,
c ...        arrays /S_RESn/ for neutral resonances
       if (L0.eq.13) then
c ... charged resonances:

       r = RNDM(0)
c... determine the energy range of the resonance:
       nlim = ELIMITSp(IRES)
       istart = (IRES-1)*4+1
       if (nlim.gt.0) then
         do ie=istart,nlim-2+istart
           reslimp1 = RESLIMp(ie)
           reslimp2 = RESLIMp(ie+1)
          if (x.le.reslimp2.and.x.gt.reslimp1) then
           IRANGE = ie+1-istart
          endif
         enddo
       else
         irange = 1
  13   endif



       IPROC = -1
       i = 0
       prob_sum(0) = 0.D0

       if (IRANGE.eq.1) then
        j = IDBRES1p(IRES)-1
        if (j.eq.-1) then
         print*,'invalid resonance in energy range 1'
        endif
 10     continue
        j = j+1
        i = i+1
        prob_sum(i) = CBRRES1p(j)
        if (r.ge.prob_sum(i-1).and.r.lt.prob_sum(i)) then
         IPROC = j
        endif
        if (prob_sum(i).lt.1.D0) goto 10
        if (r.eq.1.D0) IPROC = j
        if (IPROC.eq.-1) then
         print*,'no resonance decay possible !'
        endif

       else if (IRANGE.eq.2) then
        j = IDBRES2p(IRES)-1
        if (j.eq.-1) then
         print*,'invalid resonance in energy range 2'
        endif
 11     continue
        j = j+1
        i = i+1
        prob_sum(i) = CBRRES2p(j)
        if (r.ge.prob_sum(i-1).and.r.lt.prob_sum(i)) then
         IPROC = j
        endif
        if (prob_sum(i).lt.1.D0) goto 11
        if (r.eq.1.D0) IPROC = j
        if (IPROC.eq.-1) then
         print*,'no resonance decay possible !'
        endif

       else if (IRANGE.eq.3) then
        j = IDBRES3p(IRES)-1
        if (j.eq.-1) then
         print*,'invalid resonance in energy range 3'
        endif
 12     continue
        j = j+1
        i = i+1
        prob_sum(i) = CBRRES3p(j)
        if (r.ge.prob_sum(i-1).and.r.lt.prob_sum(i)) then
         IPROC = j
        endif
        if (prob_sum(i).lt.1.D0) goto 12
        if (r.eq.1.D0) IPROC = j
        if (IPROC.eq.-1) then
         print*,'no resonance decay possible !'
        endif

        else
         print*,'invalid IRANGE in DEC_PROC2'
        endif

       RETURN


         else if (L0.eq.14) then
c ... neutral resonances:

       r = RNDM(0)
c... determine the energy range of the resonance:
       nlim = ELIMITSn(IRES)
       istart = (IRES-1)*4+1
       if (nlim.gt.0) then
         do ie=istart,nlim-2+istart
          if (x.le.RESLIMn(ie+1).and.x.gt.RESLIMn(ie)) then
           IRANGE = ie+1-istart
          endif
         enddo
       else
         irange = 1
       endif


       IPROC = -1
       i = 0
       prob_sum(0) = 0.D0

       if (IRANGE.eq.1) then
        j = IDBRES1n(IRES)-1
        if (j.eq.-1) then
         print*,'invalid resonance in this energy range'
        endif
 20     continue
        j = j+1
        i = i+1
        prob_sum(i) = CBRRES1n(j)
        if (r.ge.prob_sum(i-1).and.r.lt.prob_sum(i)) then
         IPROC = j
        endif
        if (prob_sum(i).lt.1.D0) goto 20
        if (r.eq.1.D0) IPROC = j
        if (IPROC.eq.-1) then
         print*,'no resonance decay possible !'
        endif

       else if (IRANGE.eq.2) then
        j = IDBRES2n(IRES)-1
        if (j.eq.-1) then
         print*,'invalid resonance in this energy range'
        endif
 21     continue
        j = j+1
        i = i+1
        prob_sum(i) = CBRRES2n(j)
        if (r.ge.prob_sum(i-1).and.r.lt.prob_sum(i)) then
         IPROC = j
        endif
        if (prob_sum(i).lt.1.D0) goto 21
        if (r.eq.1.) IPROC = j
        if (IPROC.eq.-1) then
         print*,'no resonance decay possible !'
        endif

       else if (IRANGE.eq.3) then
        j = IDBRES3n(IRES)-1
        if (j.eq.-1) then
         print*,'invalid resonance in this energy range'
        endif
 22     continue
        j = j+1
        i = i+1
        prob_sum(i) = CBRRES3n(j)
        if (r.ge.prob_sum(i-1).and.r.lt.prob_sum(i)) then
         IPROC = j
        endif
        if (prob_sum(i).lt.1.D0) goto 22
        if (r.eq.1.D0) IPROC = j
        if (IPROC.eq.-1) then
         print*,'no resonance decay possible !'
        endif

        else
         print*,'invalid IRANGE in DEC_PROC2'
        endif

       RETURN

       else
        print*,'no valid L0 in DEC_PROC !'
        STOP
       endif

       END


       SUBROUTINE RES_DECAY3(IRES,IPROC,IRANGE,s,L0,nbad)

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)

       SAVE

       COMMON /S_RESp/ CBRRES1p(18),CBRRES2p(36),CBRRES3p(26),
     +  RESLIMp(36),ELIMITSp(9),KDECRES1p(90),KDECRES2p(180),
     +  KDECRES3p(130),IDBRES1p(9),IDBRES2p(9),IDBRES3p(9)
       COMMON /S_RESn/ CBRRES1n(18),CBRRES2n(36),CBRRES3n(22),
     +  RESLIMn(36),ELIMITSn(9),KDECRES1n(90),KDECRES2n(180),
     +  KDECRES3n(110),IDBRES1n(9),IDBRES2n(9),IDBRES3n(9)
       COMMON /S_PLIST/ SP(2000,5), LLIST(2000), NP, Ideb
c       COMMON /S_CNAM/ NAMP (0:49)
c      CHARACTER NAMP*6, NAMPRESp*6, NAMPRESn*6

*      external scatangle, proc_twopart

c********************************************************
c  RESONANCE AMD with code number IRES  INTO  M1 + M2
C  PROTON ENERGY E0 [in GeV] IN DMM [in GeV]
C  E1,E2 [in GeV] are energies of decay products
c  LA,LB are code numbers of decay products
c  P(1,1:5),P(2,1:5) are 5-momenta of particles LA,LB;
c  resulting momenta are calculated in CM frame;
c  ANGLESCAT is cos of scattering angle in CM frame
c********************************************************
c** Date: 20/01/98   **
c** correct.:28/04/98**
c** author: A.Muecke **
c**********************

c... determine decay products LA, LB:
        NP = 2
        if (L0.eq.13) then
c ... proton is incident nucleon:
        if (IRANGE.eq.1) then
         LA = KDECRES1p(5*(IPROC-1)+3)
         LB = KDECRES1p(5*(IPROC-1)+4)
        else if (IRANGE.eq.2) then
         LA = KDECRES2p(5*(IPROC-1)+3)
         LB = KDECRES2p(5*(IPROC-1)+4)
        else if (IRANGE.eq.3) then
         LA = KDECRES3p(5*(IPROC-1)+3)
         LB = KDECRES3p(5*(IPROC-1)+4)
        else
          print*,'error in res_decay3'
        endif
        else if (L0.eq.14) then
c ... neutron is incident nucleon:
        if (IRANGE.eq.1) then
         LA = KDECRES1n(5*(IPROC-1)+3)
         LB = KDECRES1n(5*(IPROC-1)+4)
        else if (IRANGE.eq.2) then
         LA = KDECRES2n(5*(IPROC-1)+3)
         LB = KDECRES2n(5*(IPROC-1)+4)
        else if (IRANGE.eq.3) then
         LA = KDECRES3n(5*(IPROC-1)+3)
         LB = KDECRES3n(5*(IPROC-1)+4)
        else
          print*,'error in res_decay3'
        endif

        else
         print*,'no valid L0 in RES_DECAY'
         STOP
        endif

        LLIST(1) = LA
        LLIST(2) = LB

c... sample scattering angle:
       call scatangle(anglescat,IRES,L0)

c ... 2-particle decay:
        call proc_twopart(LA,LB,sqrt(s),LLIST,P,anglescat,nbad)

        RETURN

        END

c***********************************************************
C calculates functions for crossection of direct channel
c NOT isospin-corrected, simply a samelsurium of functions
c x is eps_prime in GeV (see main program)
C (see thesis of J.Rachen, p.45ff)
c note: neglect strange- and eta-channel
C***********************************************************
c** Date: 27/04/98   **
c** last chg:23/05/98**
c** author: A.Muecke **
c**********************
c

       DOUBLE PRECISION FUNCTION singleback(x)
c****************************
c SINGLE PION CHANNEL
c****************************
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)

       SAVE
       singleback = 92.7D0*Pl(x,.152D0,.25D0,2.D0)

       END


       DOUBLE PRECISION FUNCTION twoback(x)
c*****************************
c TWO PION PRODUCTION
c*****************************
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)

       SAVE
       twoback = 37.7D0*Pl(x,.4D0,.6D0,2.D0)

       END


      subroutine scatangle(anglescat,IRES,L0)

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)

       SAVE

c*******************************************************************
c This routine samples the cos of the scattering angle for a given *
c resonance IRES and incident nucleon L0; it is exact for         **
c one-pion decay channel and if there is no                       **
c other contribution to the cross section from another resonance  **
c and an approximation for an overlay of resonances;              **
c for decay channels other than the one-pion decay a isotropic    **
c distribution is used                                            **
c*******************************************************************
c** Date: 16/02/98   **
c** author: A.Muecke **
c**********************

       COMMON /S_PLIST/ SP(2000,5), LLIST(2000), NP, Ideb

c ... use rejection method for sampling:
       LA = LLIST(1)
       LB = LLIST(2)
  10   continue
       r = RNDM(0)
c*** sample anglescat random between -1 ... 1 **
      anglescat = 2.D0*(r-0.5D0)
c ... distribution is isotropic for other than one-pion decays:
       if ((LA.eq.13.or.LA.eq.14).and.LB.ge.6.and.LB.le.8) then
        prob = probangle(IRES,L0,anglescat)
       else
        prob = 0.5D0
       endif
       r = RNDM(0)
       if (r.le.prob) then
          RETURN
        else
         goto 10
       endif
 12   continue

       END

      DOUBLE PRECISION function probangle(IRES,L0,z)

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)

       SAVE

c********************************************************************
c probability distribution for scattering angle of given resonance **
c IRES and incident nucleon L0 ;                                   **
c z is cosine of scattering angle in CMF frame                     **
c********************************************************************

       if (IRES.eq.4.or.IRES.eq.5.or.IRES.eq.2) then
c ... N1535 andf N1650 decay isotropically.
        probangle = 0.5D0
        return
       endif

       if (IRES.eq.1) then
c ... for D1232:
        probangle =  0.636263D0 - 0.408790D0*z*z
        return
       endif

       if (IRES.eq.3.and.L0.eq.14) then
c ... for N1520 and incident n:
        probangle =  0.673669D0 - 0.521007D0*z*z
        return
       endif

       if (IRES.eq.3.and.L0.eq.13) then
c ... for N1520 and incident p:
        probangle =  0.739763D0 - 0.719288D0*z*z
        return
       endif

       if (IRES.eq.6.and.L0.eq.14) then
c ... for N1680 (more precisely: N1675) and incident n:
        q=z*z
        probangle = 0.254005D0 + 1.427918D0*q - 1.149888D0*q*q
        return
       endif


       if (IRES.eq.6.and.L0.eq.13) then
c ... for N1680 and incident p:
        q=z*z
        probangle = 0.189855D0 + 2.582610D0*q - 2.753625D0*q*q
        return
       endif

      if (IRES.eq.7) then
c ... for D1700:
       probangle =  0.450238D0 + 0.149285D0*z*z
       return
      endif


      if (IRES.eq.8) then
c ... for D1905:
       q=z*z
       probangle = 0.230034D0 + 1.859396D0*q - 1.749161D0*q*q
       return
      endif


      if (IRES.eq.9) then
c ... for D1950:
       q=z*z
       probangle = 0.397430D0 - 1.498240D0*q + 5.880814D0*q*q
     &                - 4.019252D0*q*q*q
       return
      endif

      print*,'error in function probangle !'
      STOP
      END

C->
       DOUBLE PRECISION FUNCTION GAUSS (FUN, A,B)
c*********************************************************
C	Returns the  8 points Gauss-Legendre integral
C	of function FUN from A to B
c       this routine was provided by T.Stanev
c*********************************************************
c** Date: 20/01/98   **
c** A.Muecke         **
c**********************

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)
      SAVE

      EXTERNAL FUN

C...........................................................
	DIMENSION X(8), W(8)
	DATA X /.0950125098D0,.2816035507D0,.4580167776D0,.6178762444D0
     +         ,.7554044083D0,.8656312023D0,.9445750230D0,.9894009349D0/
	DATA W /.1894506104D0,.1826034150D0,.1691565193D0,.1495959888D0
     +        ,.1246289712D0,.0951585116D0,.0622535239D0, .0271524594D0/
        if (A-1.D-10.le.B.and.A+1.D-10.ge.B) then
         GAUSS = 0.D0
c         print*,'A=B in integration routine'
         RETURN
        endif
	XM = 0.5D0*(B+A)
	XR = 0.5D0*(B-A)
	SS = 0.D0
	DO NJ=1,8
	  DX = XR*X(NJ)
	  SS = SS + W(NJ) * (FUN(XM+DX) + FUN(XM-DX))
	ENDDO
	GAUSS = XR*SS
	RETURN
	END





C->
c***************************
c** last change: 12/10/98 **
c** author:      A.Muecke **
c***************************
      BLOCK DATA DATDEC
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)
      SAVE
       COMMON /S_PLIST/ SP(2000,5), LLIST(2000), NP, Ideb
       COMMON /S_CSYDEC/ CBR(102), IDB(49), KDEC(612), LBARP(49)
      COMMON /S_MASS1/ AM(49), AM2(49)
      COMMON /S_CHP/  S_LIFE(49), ICHP(49), ISTR(49), IBAR(49)
      COMMON /S_CNAM/ NAMP (0:49)

      CHARACTER NAMPRESp*6
      COMMON /RES_PROPp/ AMRESp(9), BGAMMAp(9),WIDTHp(9),
     +                    RATIOJp(9),NAMPRESp(0:9)

      CHARACTER NAMPRESn*6
      COMMON /RES_PROPn/ AMRESn(9), BGAMMAn(9),WIDTHn(9),
     +                    RATIOJn(9),NAMPRESn(0:9)

       COMMON /S_RESp/ CBRRES1p(18),CBRRES2p(36),CBRRES3p(26),
     +  RESLIMp(36),ELIMITSp(9),KDECRES1p(90),KDECRES2p(180),
     +  KDECRES3p(130),IDBRES1p(9),IDBRES2p(9),IDBRES3p(9)
       COMMON /S_RESn/ CBRRES1n(18),CBRRES2n(36),CBRRES3n(22),
     +  RESLIMn(36),ELIMITSn(9),KDECRES1n(90),KDECRES2n(180),
     +  KDECRES3n(110),IDBRES1n(9),IDBRES2n(9),IDBRES3n(9)
      COMMON /RES_FLAG/ FRES(49),XLIMRES(49)
c       COMMON /LCH/ LCH(49)
      CHARACTER NAMP*6

      DATA Ideb / 0 /

c       DATA LCH/0,1,-1,1,-1,0,1,-1,1,-1,0,0,1,5*0,1,5*0,1,-1,0,
c     +     1,-1,0,0,0,0,1,0,-1,0,-1,0,2,1,0,-1,1,0,-1,0,-1,-1/
      DATA FRES /0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     +    1,1,1,0,0,0,0,1,1,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,1/
      DATA XLIMRES /0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.
     +     ,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,
     +    .275,.275,.28,0.,0.,0.,0.,.41,.9954,0.,0.,0.,0.,0.,0.,
     +     1.078,1.08,1.078,1.08,0,0,0,0,0,1/
      DATA AMRESp / 1.231,1.440,1.515,1.525,1.675,1.680,1.690,
     +           1.895,1.950/
      DATA AMRESn / 1.231,1.440,1.515,1.525,1.675,1.675,1.690,
     +           1.895,1.950/
      DATA IDBRES1p /
     +  1,3,5,7,9,11,13,15,17/
      DATA IDBRES2p /
     +  0,1,6,11,14,19,24,27,32/
      DATA IDBRES3p /
     +  0,0,1,0,3,9,16,21,26/
      DATA IDBRES1n /
     +  1,3,5,7,9,11,13,15,17/
      DATA IDBRES2n /
     +  0,1,6,11,14,19,24,27,32/
      DATA IDBRES3n /
     +  0,0,1,0,3,0,9,14,19/

      DATA CBRRES1p /
     +   .667,1.,.667,1.,.667,1.,.667,1.,.667,1.,.667,1.,.667,1.,
     +   .667,1.,.667,1./
      DATA CBRRES1n /
     +   .667,1.,.667,1.,.667,1.,.667,1.,.667,1.,.667,1.,.667,1.,
     +   .667,1.,.667,1./
c... according to Joerg's report 4/98:
c      DATA CBRRES2p /
c     +   .400,.600,.800,.933,1.,.334,.5,.75,.9167,1.,.334,.5,1.,
c     +    .567,.85,.925,.975,1.,.434,.65,.825,.942,1.,.400,.467,1.,
c     +    .667,1.,.4,.6,.76,.787,1./
c... according to Joerg's report 5/98:
c      DATA CBRRES2p /
c     +   .333,.5,.750,.917,1.,.4,.6,.7,.833,1.,.167,.25,1.,
c     +    .567,.85,.925,.975,1.,.434,.65,.825,.942,1.,.4,.467,1.,
c     +    .667,1.,.466,.7,.82,.84,1./
c... according to Joerg's report 22/5/98:
C************************** settings of version 1.0 ********************
*     DATA CBRRES2p /
*    +   .333,.5,.750,.917,1.,.4,.6,.7,.833,1.,.167,.25,1.,
*    +    .567,.85,.925,.975,1.,.434,.65,.825,.942,1.,.4,.467,1.,
*    +    .5,.75,.85,.867,1.,.466,.7,.82,.84,1./
*     DATA CBRRES2n /
*    +   .333,.5,.750,.917,1.,.4,.6,.7,.833,1.,.167,.25,1.,
*    +    .567,.85,.925,.975,1.,.267,.4,.7,.9,1.,.4,.467,1.,
*    +    .5,.75,.85,.867,1.,.466,.7,.82,.84,1./
C************************** after Joergs cross check *******************
*     DATA CBRRES2p /
*    +   .333,.5,.750,.917,1.,.4,.6,.8,.933,1.,.167,.25,1.,
*    +    .567,.85,.925,.975,1.,.433,.65,.825,.942,1.,.4,.467,1.,
*    +    .5,.75,.85,.867,1.,.466,.7,.82,.84,1./
*     DATA CBRRES2n /
*    +   .333,.5,.750,.917,1.,.4,.6,.8,.933,1.,.167,.25,1.,
*    +    .567,.85,.925,.975,1.,.267,.4,.7,.9,1.,.4,.467,1.,
*    +    .5,.75,.85,.867,1.,.466,.7,.82,.84,1./
C************************** settings of version 1.0 ********************
c      DATA CBRRES2p /
c     +   .333,.5,.750,.917,1.,.4,.6,.7,.833,1.,.167,.25,1.,
c     +    .567,.85,.925,.975,1.,.434,.65,.825,.942,1.,.4,.467,1.,
c     +    .5,.75,.85,.867,1.,.466,.7,.82,.84,1./
c      DATA CBRRES2n /
c     +   .333,.5,.750,.917,1.,.4,.6,.7,.833,1.,.167,.25,1.,
c     +    .567,.85,.925,.975,1.,.267,.4,.7,.9,1.,.4,.467,1.,
c     +    .5,.75,.85,.867,1.,.466,.7,.82,.84,1./
C************************** settings of version 1.4 (Joerg's report 8/10/98) *********
      DATA CBRRES2p /
     +   .333,.5,.750,.917,1.,.333,.5,.75,.917,1.,.167,.25,1.,
     +    .567,.85,.925,.975,1.,.433,.65,.825,.942,1.,.4,.467,1.,
     +    .267,.4,.64,.68,1.,.4,.6,.76,.787,1./
      DATA CBRRES2n /
     +   .333,.5,.750,.917,1.,.333,.5,.75,.917,1.,.167,.25,1.,
     +    .567,.85,.925,.975,1.,.267,.4,.7,.9,1.,.4,.467,1.,
     +    .267,.4,.64,.68,1.,.4,.6,.76,.787,1./
      DATA CBRRES3p /
     + .333,1.,.467,.7,.775,.825,.85,1.,.367,.55,.7,
     +  1.,.08,.093,.2,.733,1.,.667,1.,
     + .2,.3,.46,.487,.7,.9,1./
      DATA CBRRES3n /
     + .333,1.,.467,.7,.775,.825,.85,1.,
     + .08,.093,.2,.733,1.,.667,1.,
     + .2,.3,.46,.487,.7,.9,1./
C***********************************************************************
c... according to Joerg's report 4/98:
c      DATA CBRRES3p /
c     + .333,1.,.467,.7,.775,.825,.85,1.,.167,.25,.425,.542,.6,.733,
c     +  1.,.16,.187,.4,.8,1.,.267,.4,.560,.587,.8,.933,1./
c... according to Joerg's report 5/98:
c      DATA CBRRES3p /
c     + .333,1.,.467,.7,.775,.825,.85,1.,.367,.55,.725,.842,.9,.933,
c     +  1.,.16,.187,.4,.8,1.,.333,.5,.62,.64,.8,.933,1./
c... according to Joerg's report 22/5/98:
c      DATA CBRRES3p /
c     + .333,1.,.467,.7,.775,.825,.85,1.,.367,.55,.725,.842,.9,.933,
c     +  1.,.16,.187,.4,.8,1.,.1,.117,.25,.75,1.,
c     + .333,.5,.62,.64,.8,.933,1./
c      DATA CBRRES3n /
c     + .333,1.,.467,.7,.775,.825,.85,1.,
c     +  .16,.187,.4,.8,1.,.1,.117,.25,.75,1.,
c     + .333,.5,.62,.64,.8,.933,1./

      DATA KDECRES1p /
     +   2,0,13,6,0,2,0,14,7,0,2,0,14,7,0,2,0,13,6,0,2,0,14,7,0,
     +   2,0,13,6,0,2,0,14,7,0,2,0,13,6,0,2,0,14,7,0,2,0,13,6,0,
     +   2,0,14,7,0,2,0,13,6,0,2,0,13,6,0,2,0,14,7,0,2,0,13,6,0,
     +   2,0,14,7,0,2,0,13,6,0,2,0,14,7,0/
      DATA KDECRES2p /
     +   2,0,14,7,0,2,0,13,6,0,2,0,40,8,0,2,0,41,6,0,2,0,42,7,0,
     +   2,0,14,7,0,2,0,13,6,0,2,0,40,8,0,2,0,41,6,0,2,0,42,7,0,
     +   2,0,14,7,0,2,0,13,6,0,2,0,13,23,0,2,0,14,7,0,2,0,13,6,0,
     +   2,0,40,8,0,2,0,41,6,0,2,0,42,7,0,
     +   2,0,14,7,0,2,0,13,6,0,2,0,40,8,0,2,0,41,6,0,2,0,42,7,0,
     +   2,0,40,8,0,2,0,41,6,0,2,0,42,7,0,
     +   2,0,13,6,0,2,0,14,7,0,2,0,40,8,0,2,0,41,6,0,2,0,42,7,0,
     +   2,0,13,6,0,2,0,14,7,0,2,0,40,8,0,2,0,41,6,0,2,0,42,7,0/
c      DATA KDECRES3p /
c     +   2,0,13,27,0,2,0,14,25,0,
c     +   2,0,14,7,0,2,0,13,6,0,2,0,40,8,0,2,0,41,6,0,2,0,42,7,0,
c     +   2,0,39,9,0,
c     +   2,0,14,7,0,2,0,13,6,0,2,0,40,8,0,2,0,41,6,0,2,0,42,7,0,
c     +   2,0,13,27,0,2,0,14,25,0,2,0,40,8,0,2,0,41,6,0,2,0,42,7,0,
c     +   2,0,13,27,0,2,0,14,25,0,
c     +   2,0,40,8,0,2,0,41,6,0,2,0,42,7,0,2,0,13,27,0,2,0,14,25,0,
c     +   2,0,13,6,0,2,0,14,7,0,
c     +   2,0,40,8,0,2,0,41,6,0,2,0,42,7,0,2,0,13,27,0,2,0,14,25,0/
      DATA KDECRES3p /
     +   2,0,13,27,0,2,0,14,25,0,
     +   2,0,14,7,0,2,0,13,6,0,2,0,40,8,0,2,0,41,6,0,2,0,42,7,0,
     +   2,0,39,9,0,
     +   2,0,14,7,0,2,0,13,6,0,
     +   2,0,13,27,0,2,0,14,25,0,2,0,40,8,0,2,0,41,6,0,2,0,42,7,0,
     +   2,0,13,27,0,2,0,14,25,0,
     +   2,0,13,27,0,2,0,14,25,0,
     +   2,0,13,6,0,2,0,14,7,0,
     +   2,0,40,8,0,2,0,41,6,0,2,0,42,7,0,2,0,13,27,0,2,0,14,25,0/
      DATA KDECRES1n /
     +   2,0,14,6,0,2,0,13,8,0,2,0,13,8,0,2,0,14,6,0,2,0,13,8,0,
     +   2,0,14,6,0,2,0,13,8,0,2,0,14,6,0,2,0,13,8,0,2,0,14,6,0,
     +   2,0,13,8,0,2,0,14,6,0,2,0,14,6,0,2,0,13,8,0,2,0,14,6,0,
     +   2,0,13,8,0,2,0,14,6,0,2,0,13,8,0/
      DATA KDECRES2n /
     +   2,0,13,8,0,2,0,14,6,0,2,0,43,7,0,2,0,42,6,0,2,0,41,8,0,
     +   2,0,13,8,0,2,0,14,6,0,2,0,43,7,0,2,0,42,6,0,2,0,41,8,0,
     +   2,0,13,8,0,2,0,14,6,0,2,0,14,23,0,2,0,13,8,0,2,0,14,6,0,
     +   2,0,43,7,0,2,0,42,6,0,2,0,41,8,0,
     +   2,0,13,8,0,2,0,14,6,0,2,0,43,7,0,2,0,42,6,0,2,0,41,8,0,
     +   2,0,43,7,0,2,0,42,6,0,2,0,41,8,0,
     +   2,0,14,6,0,2,0,13,8,0,2,0,43,7,0,2,0,42,6,0,2,0,41,8,0,
     +   2,0,14,6,0,2,0,13,8,0,2,0,43,7,0,2,0,42,6,0,2,0,41,8,0/
c      DATA KDECRES3n /
c     +   2,0,14,27,0,2,0,13,26,0,
c     +   2,0,13,8,0,2,0,14,6,0,2,0,43,7,0,2,0,42,6,0,2,0,41,8,0,
c     +   2,0,39,21,0,
c     +   2,0,43,7,0,2,0,42,6,0,2,0,41,8,0,
c     +   2,0,14,27,0,2,0,13,26,0,
c     +   2,0,43,7,0,2,0,42,6,0,2,0,41,8,0,2,0,14,27,0,2,0,13,26,0,
c     +   2,0,14,6,0,2,0,13,8,0,
c     +   2,0,43,7,0,2,0,42,6,0,2,0,41,8,0,2,0,14,27,0,2,0,13,26,0/
      DATA KDECRES3n /
     +   2,0,14,27,0,2,0,13,26,0,
     +   2,0,13,8,0,2,0,14,6,0,2,0,43,7,0,2,0,42,6,0,2,0,41,8,0,
     +   2,0,39,21,0,
     +   2,0,43,7,0,2,0,42,6,0,2,0,41,8,0,
     +   2,0,14,27,0,2,0,13,26,0,
     +   2,0,14,27,0,2,0,13,26,0,
     +   2,0,14,6,0,2,0,13,8,0,
     +   2,0,43,7,0,2,0,42,6,0,2,0,41,8,0,2,0,14,27,0,2,0,13,26,0/
      DATA RESLIMp /
     +   0.,0.,0.,0.,0.,.54,10.,0.,0.,.54,1.09,10.,
     +   0.,.71,10.,0.,0.,.54,.918,10.,
     +   0.,.54,1.09,10.,0.,.54,1.09,10.,
     +   0.,.54,1.09,10.,0.,.54,1.09,10./
      DATA RESLIMn /
     +   0.,.0,.0,.0,0.,.54,10.,0.,0.,.54,1.09,10.,
     +   0.,.71,10.,0.,0.,.54,.918,10.,
     +   0.,.54,10.,0.,0.,.54,1.09,10.,0.,.54,1.09,10.,
     +   0.,.54,1.09,10./
      DATA ELIMITSp /0,3,4,3,4,4,4,4,4/
      DATA ELIMITSn /0,3,4,3,4,3,4,4,4/
      DATA NAMPRESp /
     +      '      ','D+1232','N+1440','N+1520','N+1535','N+1650',
     +      'N+1680','D+1700','D+1905','D+1950'/
      DATA NAMPRESn /
     +      '      ','D01232','N01440','N01520','N01535','N01650',
     +      'N01675','D01700','D01905','D01950'/
***********************************************************************
*     DATA SIG0p /
*    +      511.1,7.75,131.6,40.4,8.2,59.3,37.7,2.9,14.3/
***********************************************************************
c      DATA SIG0p /
c     +      30.0137,1.3895,31.1253,7.5034,2.7790,21.6765,14.4510,
c     +      1.6674,8.8929 /
c... setting of SOPHIA1.4:
c      DATA SIG0p /
c     +      31.1254,1.3895,25.5673,6.9476,2.7791,17.5081,11.1162,
c     +      1.6674,11.1162 /
      DATA BGAMMAp /
     +      5.6,0.5,4.6,2.5,1.0,2.1,2.0,0.2,1.0/
      DATA RATIOJp /
     +      1.,0.5,1.,0.5,0.5,1.5,1.,1.5,2./
      DATA WIDTHp /
     +      .11,.35,.11,.10,.16,.125,.29,.35,.3/
***********************************************************************
*     DATA SIG0n /
*    +      578.3,7.75,131.6,22.5,8.2,13.7,37.7,2.9,14.3/
***********************************************************************
c      DATA SIG0n /
c     +      33.9044,1.3895,30.0137,5.5581,0.0000, 5.0027,14.4510,
c     +      1.6674,8.8929 /
c... setting of SOPHIA1.4:
c      DATA SIG0n /
c     +      33.8086,0.8314,16.6272,6.9280,0.0000, 1.6627,11.0848,
c     +      1.6627,11.0848 /
      DATA BGAMMAn /
     +      6.1,0.3,4.0,2.5,0.,0.2,2.0,0.2,1.0/
      DATA RATIOJn /
     +      1.,0.5,1.,0.5,0.5,1.5,1.,1.5,2./
      DATA WIDTHn /
     +      .11,.35,.11,.10,.16,.15,.29,.35,.3/


      DATA CBR /3*1.,0.,1.,1.,0.6351,0.8468,0.9027,0.9200,0.9518,1.,
     +   0.6351,0.8468,0.9027,0.9200,0.9518,1.,0.2160,0.3398,0.4748,
     +   0.6098,0.8049,1.,0.6861,1.,3*0.,0.5,1.,0.5,1.,
     +   0.3890,0.7080,0.9440,0.9930,1.,0.,0.4420,0.6470,0.9470,0.9770,
     +   0.9990,4*1.,0.6670,1.,9*0.,0.6670,1.,0.6670,1.,0.6670,1.,
     +   0.8880,0.9730,1.,0.4950,0.8390,0.9870,1.,0.5160,5*1.,0.6410,1.,
     +   1.,0.67,1.,0.33,1.,1.,0.88,0.94,1.,0.88,0.94,1.,0.88,0.94,1.,
     +   0.33,1.,0.67,1.,0.678,0.914,1./
      DATA AM / 0.,2*0.511E-3, 2*0.10566, 0.13497, 2*0.13957,
     +   2*0.49365, 2*0.49767, 0.93827, 0.93957, 4*0.,0.93827,
     +   0.93957, 2*0.49767, 0.54880,0.95750,2*0.76830,0.76860,
     +   2*0.89183,2*0.89610,0.78195,1.01941,1.18937,1.19255,
     +   1.19743,1.31490,1.32132,1.11563,1.23100,1.23500,
     +   1.23400,1.23300,1.38280,1.38370,1.38720,
     +   1.53180,1.53500,1.67243 /
      DATA AM2 /0.,2*2.61121E-07,2*0.011164,0.018217,0.019480,
     + 0.019480,0.243690,0.243690,0.247675,0.247675,0.880351,0.882792,
     + 0.000000,0.000000,0.000000,0.000000,0.880351,0.882792,0.247675,
     + 0.247675,0.301181,0.916806,0.590285,0.590285,0.590746,0.795361,
     + 0.795361,0.802995,0.802995,0.611446,1.039197,1.414601,1.422176,
     + 1.433839,1.728962,1.745887,1.244630,1.515361,1.525225,1.522765,
     + 1.520289,1.912136,1.914626,1.924324,2.346411,2.356225,2.797022/
      DATA IDB /
     +    0,0,0,1,2,3,5,6,7,13,19,25,8*0,30,32,34,40,46,47,48,49,60,62,
     +    64,66,69,73,75,76,77,78,79,81,82,84,86,87,90,93,96,98,100/
      DATA KDEC /
     + 3,1,15,2,18,0,3,1,16,3,17,0,2,0,1,1,8*0,2,0,4,17,0,0,2,0,5,18,0,
     + 0,2,0,4,17,0,0,2,0,7,6,0,0,3,0,7,7,8,0,3,0,7,6,6,0,3,1,17,4,6,0,
     + 3,1,15,2,6,0,2,0,5,18,0,0,2,0,8,6,0,0,3,0,8,8,7,0,3,0,8,6,6,0,3,
     + 1,18,5,6,0,3,1,16,3,6,0,3,0,6,6,6,0,3,0,7,8,6,0,3,1,18,5,7,0,3,
     + 1,17,4,8,0,3,1,16,3,7,0,3,1,15,2,8,0,2,0,7,8,0,0,2,0,6,6,20*0,1,
     + 0,11,3*0,1,0,12,0,0,0,1,0,11,0,0,0,1,0,12,0,0,0,2,0,1,1,0,0,3,0,
     + 6,6,6,0,3,0,7,8,6,0,3,0,1,7,8,0,3,0,1,3,2,7*0,3,0,7,8,23,0,3,0,6
     + ,6,23,0,2,0,1,27,0,0,2,0,1,32,0,0,2,0,1,1,0,0,3,0,6,6,6,0,2,0,7,
     + 6,0,0,2,0,8,6,0,0,2,0,7,8,0,0,2,0,21,7,0,0,2,0,9,6,0,0,54*0,2,0,
     + 22,8,0,0,2,0,10,6,0,0,2,0,9,8,0,0,2,0,21,6,0,0,2,0,10,7,0,0,
     + 2,0,22,6,0,0,3,0,7,8,6,0,2,0,1,6,0,0,2,0,7,8,0,0,2,0,9,10,0,
     + 0,2,0,11,12,0,0,3,0,7,
     + 8,6,0,2,0,1,23,0,0,2,0,13,6,0,0,2,0,14,7,0,0,2,0,39,1,0,0,2,
     + 0,14,8,0,0,2,0,39,6,0,0,2,0,39,8,0,0,2,0,13,8,0,0,2,0,
     + 14,6,0,0,2,0,13,7,0,0,2,0,13,6,
     + 0,0,2,0,14,7,0,0,2,0,13,8,0,0,2,0,14,6,0,0,2,0,14,8,0,0,2,0,
     + 39,7,0,0,2,0,34,6,0,0,2,0,35,7,0,0,2,0,39,6,0,0,2,0,34,8,0,0,
     + 2,0,36,7,0,0,2,0,39,8,0,0,2,
     + 0,35,8,0,0,2,0,36,6,0,0,2,0,37,6,0,0,2,0,38,7,0,0,2,0,
     + 37,8,0,0,2,0,38,6,0,0,2,0,39,10,0,0,2,0,37,8,0,0,2,0,38,6,0,0/
      DATA LBARP/1,3,2,5,4,6,8,7,10,9,11,12,-13,-14,16,15,18,17,13,14,
     +  22,21,23,24,26,25,27,29,28,31,30,32,33,-34,-35,-36,-37,-38,-39,
     +  -40,-41,-42,-43,-44,-45,-46,-47,-48,-49/
      DATA ICHP /0,1,-1,1,-1,0,1,-1,1,-1,0,0,1,0,4*0,-1,0,4*0,
     +    1,-1,0,1,-1,4*0,1,0,-1,0,-1,0,2,1,0,-1,1,0,-1,0,-1,-1/
      DATA ISTR /8*0,-1,+1,10,10,8*0,-1,+1,5*0,-1,+1,-1,+1,2*0,
     +           3*1,2*2,1,4*0,3*1,2*2,3 /
      DATA IBAR /12*0,2*1,4*0,2*-1,13*0,16*1/
      DATA NAMP /
     +     '     ','gam   ','e+','e-','mu+','mu-','pi0',
     +     'pi+','pi-','k+', 'k-', 'k0l','k0s',
     +     'p', 'n', 'nue', 'nueb', 'num', 'numb', 'pbar', 'nbar',
     +     'k0', 'k0b', 'eta', 'etap', 'rho+', 'rho-','rho0',
     +     'k*+','k*-','k*0','k*0b','omeg', 'phi', 'SIG+', 'SIG0',
     +     'SIG-','XI0','XI-','LAM','DELT++','DELT+','DELT0','DELT-',
     +     'SIG*+ ','SIG*0','SIG*-', 'XI*0', 'XI*-', 'OME*-'/
      DATA S_LIFE /0.,0.,0.,2.197D-6,2.197D-6,8.4D-17,2.6033D-8,
     + 2.6033D-8,
     + 0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,
     + 0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,
     + 0.,0.,0./
      END
C->
      BLOCK DATA PARAM_INI
C....This block data contains default values
C.   of the parameters used in fragmentation
C................................................
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)
      SAVE
      COMMON /S_CZDIS/ FA, FB0
      COMMON /S_CZDISs/ FAs1, fAs2
      COMMON /S_CZLEAD/ CLEAD, FLEAD
      COMMON /S_CPSPL/ CCHIK(3,6:14)
      COMMON /S_CQDIS/ PPT0 (33),ptflag
      COMMON /S_CDIF0/ FFD, FBD, FDD
      COMMON /S_CFLAFR/ PAR(8)
C...Longitudinal Fragmentation function
      DATA FA /0.5/, FB0 /0.8/
C...Longitudinal Fragmentation function for leading baryons
       DATA CLEAD  /0.0/, FLEAD  /0.6/
c      strange fragmentation
      data FAs1 /3./, fAs2 /3./
c      data FAs1 /0./, fAs2 /0./
C...pT of sea partons
      DATA PTFLAG /1./
      DATA PPT0 /0.30,0.30,0.450,30*0.60/
C...Splitting parameters
      DATA CCHIK /21*2.,6*3./
C...Parameters of flavor formation
      DATA PAR /0.04,0.25,0.25,0.14,0.3,0.3,0.15,0./
      END


      SUBROUTINE gamma_h(Ecm,ip1,Imode,ifbad)
C**********************************************************************
C
C     simple simulation of low-energy interactions (R.E. 03/98)
C
C     changed to simulate superposition of reggeon and pomeron exchange
C     interface to Lund / JETSET 7.4 fragmentation
C                                                  (R.E. 08/98)
C
C
C
C     input: ip1    incoming particle
C                   13 - p
C                   14 - n
C            Ecm    CM energy in GeV
C            Imode  interaction mode
C                   0 - multi-pion fragmentation
C                   5 - fragmentation in resonance region
C                   1 - quasi-elastic / diffractive interaction
C                       (p/n-gamma  --> n/p rho)
C                   4 - quasi-elastic / diffractive interaction
C                       (p/n-gamma  --> n/p omega)
C                   2 - direct interaction (p/n-gamma  --> n/p pi)
C                   3 - direct interaction (p/n-gamma  --> delta pi)
C            IFBAD control flag
C                  (0  all OK,
C                   1  generation of interaction not possible)
C
C**********************************************************************

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)

      COMMON /S_RUN/ SQS, S, Q2MIN, XMIN, ZMIN, kb, kt, a1, a2, Nproc
      COMMON /S_PLIST/ SP(2000,5), LLIST(2000), NP, Ideb
      COMMON /S_CHP/ S_LIFE(49), ICHP(49), ISTR(49), IBAR(49)
      COMMON /S_MASS1/ AM(49), AM2(49)
      COMMON /S_CFLAFR/ PAR(8)
      SAVE

      DIMENSION P_dec(10,5), P_in(5)
      DIMENSION xs1(2), xs2(2), xmi(2), xma(2)
      DIMENSION LL(10), Ijoin(4)

      DOUBLE PRECISION PA1(4), PA2(4), P1(4), P2(4)

      DATA Ic / 0 /

C  second particle is always photon
      IP2 = 1
C  parameters of pi0 suppression
C... 50% suppression:
      a1 = 0.5D0
      a2 = 0.5D0
C... no suppression:
c      a1 = 0.D0
c      a2 = 1.D0
C  parameter of strangeness suppression
      PAR(2) = 0.18D0

      ifbad = 0
      SQS = Ecm
      S = SQS*SQS
      Ic = Ic+1

*     xm_p = AM(13)
*     xm_pi = 0.135
*     plab = (Ecm**2-xm_p**2)/(2.*xm_p)


      IF((Imode.eq.1).or.(Imode.eq.4)) THEN

C***********************************************************************

C  simulation of diffraction

        ipa = ip1
        ipb = ip2

        if(Imode.eq.1) then
          Nproc = 1
          if(ip1.eq.1) then
            ipa = 27
          else if(ip2.eq.1) then
            ipb = 27
          endif
        else if(Imode.eq.4) then
          Nproc = 4
          if(ip1.eq.1) then
            ipa = 32
          else if(ip2.eq.1) then
            ipb = 32
          endif
        endif

        am_a = AM(ipa)
        am_b = AM(ipb)
        if(am_a+am_b.ge.Ecm-1.D-2) am_a = Ecm - am_b-1.D-2

C  find t range
        e1 = 0.5D0*(Ecm + AM(ip1)**2/Ecm - AM(ip2)**2/Ecm)
        if(e1.gt.100.D0*AM(ip1)) then
          pcm1 = e1 - 0.5D0*AM(ip1)**2/e1
        else
          pcm1 = sqrt((e1-AM(ip1))*(e1+AM(ip1)))
        endif
        e3 = 0.5D0*(Ecm + am_a**2/Ecm - am_b**2/Ecm)
        if(e3.gt.100.D0*am_a) then
          pcm3 = e3 - 0.5D0*am_a**2/e3
        else
          pcm3 = sqrt((e3-am_a)*(e3+am_a))
        endif
        t0 = ((AM(ip1)**2-am_a**2-AM(ip2)**2+am_b**2)/(2.D0*Ecm))**2
     &      -(pcm1-pcm3)**2-0.0001D0
        t1 = ((AM(ip1)**2-am_a**2-AM(ip2)**2+am_b**2)/(2.D0*Ecm))**2
     &      -(pcm1+pcm3)**2+0.0001D0

C  sample t
        b = 6.D0
        t = 1.D0/b*log((exp(b*t0)-exp(b*t1))*RNDM(0)+exp(b*t1))

C  kinematics
        pl = (2.D0*e1*e3+t-AM(ip1)**2-am_a**2)/(2.D0*pcm1)
        pt = (pcm3-pl)*(pcm3+pl)
        if(pt.lt.0.D0) then
          pl = sign(pcm3,pl)
          pt = 1.D-6
        else
          pt = sqrt(pt)
        endif
        phi = 6.28318530717959D0*RNDM(0)

        LLIST(1) = ipa
        SP(1,4) = e3
        SP(1,1) = SIN(phi)*pt
        SP(1,2) = COS(phi)*pt
        SP(1,3) = pl
        SP(1,5) = am_a
        LLIST(2) = ipb
        SP(2,1) = -SP(1,1)
        SP(2,2) = -SP(1,2)
        SP(2,3) = -SP(1,3)
        SP(2,4) = Ecm - SP(1,4)
        SP(2,5) = am_b
        np = 2

        call DECSIB

      ELSE IF((Imode.eq.2).or.(Imode.eq.3)) THEN

C***********************************************************************

C  simulation of direct p-gamma process

        if(ip1.eq.13) then
C  projectile is a proton
          if(Imode.eq.2) then
            Nproc = 2
            ipa = 14
            ipb = 7
          else
            Nproc = 3
            if(rndm(0).gt.0.25) then
              ipa = 40
              ipb = 8
            else
              ipa = 42
              ipb = 7
            endif
          endif
        else if(ip1.eq.14) then
C  projectile is a neutron
          if(Imode.eq.2) then
            Nproc = 2
            ipa = 13
            ipb = 8
          else
            Nproc = 3
            if(rndm(0).gt.0.25) then
              ipa = 43
              ipb = 7
            else
              ipa = 41
              ipb = 8
            endif
          endif
        endif

        am_a = AM(ipa)
        am_b = AM(ipb)
        if(am_a+am_b.ge.Ecm-1.e-3) am_a = Ecm - am_b-1.D-3

C  find t range
        e1 = 0.5D0*(Ecm + AM(ip1)**2/Ecm - AM(ip2)**2/Ecm)
        if(e1.gt.100.D0*AM(ip1)) then
          pcm1 = e1 - 0.5D0*AM(ip1)**2/e1
        else
          pcm1 = sqrt((e1-AM(ip1))*(e1+AM(ip1)))
        endif
        e3 = 0.5D0*(Ecm + am_a**2/Ecm - am_b**2/Ecm)
        if(e3.gt.100.D0*am_a) then
          pcm3 = e3 - 0.5D0*am_a**2/e3
        else
          pcm3 = sqrt((e3-am_a)*(e3+am_a))
        endif
        t0 = ((AM(ip1)**2-am_a**2-AM(ip2)**2+am_b**2)/(2.D0*Ecm))**2
     &      -(pcm1-pcm3)**2-0.0001D0
        t1 = ((AM(ip1)**2-am_a**2-AM(ip2)**2+am_b**2)/(2.D0*Ecm))**2
     &      -(pcm1+pcm3)**2+0.0001D0

C  sample t
        b = 12.D0
        t = 1./b*log((exp(b*t0)-exp(b*t1))*RNDM(0)+exp(b*t1))

C  kinematics
        pl = (2.D0*e1*e3+t-AM(ip1)**2-am_a**2)/(2.D0*pcm1)
        pt = (pcm3-pl)*(pcm3+pl)
        if(pt.lt.0.D0) then
          pl = sign(pcm3,pl)
          pt = 1.D-6
        else
          pt = sqrt(pt)
        endif
        phi = 6.28318530717959D0*RNDM(0)

        LLIST(1) = ipa
        SP(1,4) = e3
        SP(1,1) = SIN(phi)*pt
        SP(1,2) = COS(phi)*pt
        SP(1,3) = pl
        SP(1,5) = am_a
        LLIST(2) = ipb
        SP(2,1) = -SP(1,1)
        SP(2,2) = -SP(1,2)
        SP(2,3) = -SP(1,3)
        SP(2,4) = Ecm - SP(1,4)
        SP(2,5) = am_b
        np = 2

        call DECSIB

      ELSE

C***********************************************************************

C  simulation of multiparticle production via fragmentation

          Nproc = 0

          SIG_reg  = 129.D0*(S-AM(13)**2)**(-0.4525D0)
          SIG_pom  = 67.7D0*(S-AM(13)**2)**0.0808D0

          if(S.gt.2.6D0) then
            prob_reg = SIG_reg/(SIG_pom+SIG_reg)
          else
            prob_reg = 1.D0
          endif

          ptu =.36D0+.08D0*log10(sqs/30.D0)

          s1 = 1.2D0
          s2 = 0.6D0
          as1 = s1**2/S
          as2 = s2**2/S
          if(s1+s2.ge.sqs-0.2) then
            prob_reg = 1.D0
          endif

          itry = 0
 100      continue
          Istring = 0

C  avoid infinite looping
          itry = itry+1
          if(itry.gt.50) then
            print *,' gamma_h: more than 50 internal rejections,'
            print *,' called with ip1,ip2,Ecm,Imode:',ip1,ip2,Ecm,Imode
            ifbad = 1
            return
          endif

C  simulate reggeon (one-string topology)

          if(RNDM(0).lt.prob_reg) then

            do i=1,1000
              call valences(IP1,Ifl1a,Ifl1b)
              call valences(IP2,Ifl2a,Ifl2b)
              if(Ifl1b.eq.-Ifl2b) goto 200
            enddo
            print *,'gamma_h: simulation of reggeon impossible:',ip1,ip2
            goto 100

 200        continue

            np = 0
            Istring = 1

            ee = Ecm/2.D0
 250        continue
              pt = ptu*sqrt(-log(max(1.D-10,RNDM(0))))
            if(pt.ge.ee) goto 250
            phi = 6.2831853D0*RNDM(0)
            px = pt*COS(phi)
            py = pt*SIN(phi)

            pz = SQRT(ee**2-px**2-py**2)
            call lund_put(1,Ifl1a,px,py,pz,ee)
            px = -px
            py = -py
            pz = -pz
            call lund_put(2,Ifl2a,px,py,pz,ee)
            Ijoin(1) = 1
            Ijoin(2) = 2
            call lujoin(2,Ijoin)

            call lund_frag(Ecm,NP)
            if(NP.lt.0) then
              if(Ideb.ge.5)
     &          print *,' gamma_h: rejection (1) by lund_frag, sqs:',Ecm
              NP = 0
              goto 100
            endif

            do i=1,NP
              call lund_get(i,LLIST(i),
     &                      SP(i,1),SP(i,2),SP(i,3),SP(i,4),SP(i,5))
            enddo


C  simulate pomeron (two-string topology)

          else

            call valences(IP1,Ifl1a,Ifl1b)
            call valences(IP2,Ifl2a,Ifl2b)
            if(Ifl1a*Ifl2a.lt.0) then
              j = Ifl2a
              Ifl2a = Ifl2b
              Ifl2b = j
            endif

            pl1 = (1.D0+as1-as2)
            ps1 = 0.25D0*pl1**2-as1
            if(ps1.le.0.D0) then
              if(Ideb.ge.5) print *,' rejection by x-limits (1) ',Ecm
              prob_reg = 1.D0
              goto 100
            endif
            ps1 = sqrt(ps1)
            xmi(1) = 0.5D0*pl1-ps1
            xma(1) = 0.5D0*pl1+ps1

            pl2 = (1.D0+as2-as1)
            ps2 = 0.25D0*pl2**2-as2
            if(ps2.le.0.D0) then
              if(Ideb.ge.5) print *,' rejection by x-limits (2) ',Ecm
              prob_reg = 1.D0
              goto 100
            endif
            ps2 = sqrt(ps2)
            xmi(2) = 0.5D0*pl2-ps2
            xma(2) = 0.5D0*pl2+ps2

            if((xmi(1).ge.xma(1)+0.05D0).or.
     &         (xmi(2).ge.xma(2)+0.05D0)) then
              if(Ideb.ge.5) print *,' rejection by x-limits (3) ',Ecm
              prob_reg = 1.D0
              goto 100
            endif
            call PO_SELSX2(xs1,xs2,xmi,xma,as1,as2,Irej)
            if(Irej.ne.0) then
              if(Ideb.ge.5) print *,
     &          'gamma_h: rejection by PO_SELSX2, sqs,m1,m2:',Ecm,s1,s2
              prob_reg = 1.D0
              goto 100
            endif

            NP = 0
            Istring = 1

            ee = SQRT(XS1(1)*XS2(1))*Ecm/2.D0
 260        continue
              pt = ptu*sqrt(-log(max(1.D-10,RNDM(0))))
            if(pt.ge.ee) goto 260
            phi = 6.2831853D0*RNDM(0)
            px = pt*COS(phi)
            py = pt*SIN(phi)

            PA1(1) = px
            PA1(2) = py
            PA1(3) = XS1(1)*Ecm/2.D0
            PA1(4) = PA1(3)

            PA2(1) = -px
            PA2(2) = -py
            PA2(3) = -XS2(1)*Ecm/2.D0
            PA2(4) = -PA2(3)

            XM1 = 0.D0
            XM2 = 0.D0
            call PO_MSHELL(PA1,PA2,XM1,XM2,P1,P2)
            px = P1(1)
            py = P1(2)
            pz = P1(3)
            ee = P1(4)
            call lund_put(1,Ifl1a,px,py,pz,ee)
            px = P2(1)
            py = P2(2)
            pz = P2(3)
            ee = P2(4)
            call lund_put(2,Ifl2a,px,py,pz,ee)

            Ijoin(1) = 1
            Ijoin(2) = 2
            call lujoin(2,Ijoin)

            ee = SQRT(XS1(2)*XS2(2))*Ecm/2.D0
 270        continue
              pt = ptu*sqrt(-log(max(1.D-10,RNDM(0))))
            if(pt.ge.ee) goto 270
            phi = 6.2831853D0*RNDM(0)
            px = pt*COS(phi)
            py = pt*SIN(phi)

            PA1(1) = px
            PA1(2) = py
            PA1(3) = XS1(2)*Ecm/2.D0
            PA1(4) = PA1(3)

            PA2(1) = -px
            PA2(2) = -py
            PA2(3) = -XS2(2)*Ecm/2.D0
            PA2(4) = -PA2(3)

            XM1 = 0.D0
            XM2 = 0.D0
            call PO_MSHELL(PA1,PA2,XM1,XM2,P1,P2)

            px = P1(1)
            py = P1(2)
            pz = P1(3)
            ee = P1(4)
            call lund_put(3,Ifl1b,px,py,pz,ee)
            px = P2(1)
            py = P2(2)
            pz = P2(3)
            ee = P2(4)
            call lund_put(4,Ifl2b,px,py,pz,ee)

            Ijoin(1) = 3
            Ijoin(2) = 4
            call lujoin(2,Ijoin)

            call lund_frag(Ecm,NP)
            if(NP.lt.0) then
              if(Ideb.ge.5)
     &          print *,' gamma_h: rejection (2) by lund_frag, sqs:',Ecm
              NP = 0
              prob_reg = prob_reg+0.1D0
              goto 100
            endif

            do i=1,NP
              call lund_get(i,LLIST(i),
     &                      SP(i,1),SP(i,2),SP(i,3),SP(i,4),SP(i,5))
            enddo

          endif

          if(Ideb.ge.10) then
            print *,' multi-pion event',Istring,NP
            call print_event(1)
          endif

c... for fragmentation in resonance region:
          if (Imode.eq.5) goto 400

C  leading baryon/meson effect

          do j=1,np
            if(((LLIST(J).eq.13).or.(LLIST(J).eq.14))
     &         .and.(SP(j,3).lt.0.D0)) then
              if(rndm(0).lt.(2.D0*SP(j,4)/Ecm)**2) goto 100
            endif
            if((LLIST(J).ge.6).and.(LLIST(J).le.8)
     &         .and.(SP(j,3).lt.-0.4D0)) then
              if(rndm(0).lt.(2.D0*SP(j,4)/Ecm)**2) goto 100
            endif
          enddo

C  remove elastic/diffractive channels

          ima_0  = 0
          imb_0  = 0
          ima_1  = 0
          imb_1  = 0
          ima_2  = 0
          imb_2  = 0
          imul = 0

          if(ip1.eq.1) then
            iba_0 = 6
            iba_1 = 27
            iba_2 = 32
          else
            iba_0 = ip1
            iba_1 = ip1
            iba_2 = ip1
          endif
          if(ip2.eq.1) then
            ibb_0 = 6
            ibb_1 = 27
            ibb_2 = 32
          else
            ibb_0 = ip2
            ibb_1 = ip2
            ibb_2 = ip2
          endif

          do j=1,np
            l1 = abs(LLIST(J))
            if(l1.lt.10000) then
              if(LLIST(J).eq.iba_0) ima_0 = 1
              if(LLIST(J).eq.iba_1) ima_1 = 1
              if(LLIST(J).eq.iba_2) ima_2 = 1
              if(LLIST(J).eq.ibb_0) imb_0 = 1
              if(LLIST(J).eq.ibb_1) imb_1 = 1
              if(LLIST(J).eq.ibb_2) imb_2 = 1
              imul = imul+1
            endif
          enddo

          if(imul.eq.2) then
            if(ima_0*imb_0.eq.1) goto 100
            if(ima_1*imb_1.eq.1) goto 100
            if(ima_2*imb_2.eq.1) goto 100
          endif

C  remove direct channels

          if((imul.eq.2).and.
     &       (ip2.eq.1).and.((ip1.eq.13).or.(ip1.eq.14))) then

            ima_0  = 0
            imb_0  = 0
            ima_1  = 0
            imb_1  = 0
            ima_2  = 0
            imb_2  = 0
            ima_3  = 0
            imb_3  = 0

            if(ip1.eq.13) then
              iba_0 = 14
              ibb_0 = 7
              iba_1 = 40
              ibb_1 = 8
              iba_2 = 42
              ibb_2 = 7
              iba_3 = 13
              ibb_3 = 23
            else
              iba_0 = 13
              ibb_0 = 8
              iba_1 = 43
              ibb_1 = 7
              iba_2 = 41
              ibb_2 = 8
              iba_3 = 14
              ibb_3 = 23
            endif

            do j=1,np
              l1 = abs(LLIST(J))
              if(l1.lt.10000) then
                if(LLIST(J).eq.iba_0) ima_0 = 1
                if(LLIST(J).eq.iba_1) ima_1 = 1
                if(LLIST(J).eq.iba_2) ima_2 = 1
                if(LLIST(J).eq.iba_3) ima_3 = 1
                if(LLIST(J).eq.ibb_0) imb_0 = 1
                if(LLIST(J).eq.ibb_1) imb_1 = 1
                if(LLIST(J).eq.ibb_2) imb_2 = 1
                if(LLIST(J).eq.ibb_3) imb_3 = 1
              endif
            enddo

            if(ima_0*imb_0.eq.1) goto 100
            if(ima_1*imb_1.eq.1) goto 100
            if(ima_2*imb_2.eq.1) goto 100
            if(ima_3*imb_3.eq.1) goto 100

          endif

C  suppress events with many pi0's

          ima_0 = 0
          imb_0 = 0
          do j=1,np
C  neutral mesons
            if(LLIST(J).eq.6) ima_0 = ima_0+1
            if(LLIST(J).eq.11) ima_0 = ima_0+1
            if(LLIST(J).eq.12) ima_0 = ima_0+1
            if(LLIST(J).eq.21) ima_0 = ima_0+1
            if(LLIST(J).eq.22) ima_0 = ima_0+1
            if(LLIST(J).eq.23) ima_0 = ima_0+1
            if(LLIST(J).eq.24) ima_0 = ima_0+1
            if(LLIST(J).eq.27) ima_0 = ima_0+1
            if(LLIST(J).eq.32) ima_0 = ima_0+1
            if(LLIST(J).eq.33) ima_0 = ima_0+1
C  charged mesons
            if(LLIST(J).eq.7) imb_0 = imb_0+1
            if(LLIST(J).eq.8) imb_0 = imb_0+1
            if(LLIST(J).eq.9) imb_0 = imb_0+1
            if(LLIST(J).eq.10) imb_0 = imb_0+1
            if(LLIST(J).eq.25) imb_0 = imb_0+1
            if(LLIST(J).eq.26) imb_0 = imb_0+1
          enddo

          prob_1 = a1*DBLE(imb_0)/max(DBLE(ima_0+imb_0),1.D0)+a2

          if(RNDM(0).GT.prob_1) goto 100


C  correct multiplicity at very low energies

          ND = 0

          E_ref_1 = 1.6D0
          E_ref_2 = 1.95D0

          if((imul.eq.3)
     &       .and.(Ecm.gt.E_ref_1).and.(Ecm.lt.E_ref_2)) then

            ima_0 = 0
            ima_1 = 0
            ima_2 = 0
            imb_0 = 0
            imb_1 = 0
            iba_0 = 0
            iba_1 = 0
            iba_2 = 0
            ibb_0 = 0
            ibb_1 = 0
C  incoming proton
            if(ip1.eq.13) then
              iba_0 = 13
              iba_1 = 7
              iba_2 = 8
              ibb_0 = 14
              ibb_1 = 6
C  incoming neutron
            else if(ip1.eq.14) then
              iba_0 = 14
              iba_1 = 7
              iba_2 = 8
              ibb_0 = 13
              ibb_1 = 6
            endif
            do j=1,np
              if(LLIST(J).eq.iba_0) ima_0 = ima_0+1
              if(LLIST(J).eq.iba_1) ima_1 = ima_1+1
              if(LLIST(J).eq.iba_2) ima_2 = ima_2+1
              if(LLIST(J).eq.ibb_0) imb_0 = imb_0+1
              if(LLIST(J).eq.ibb_1) imb_1 = imb_1+1
            enddo

C  N gamma --> N pi+ pi-
            if(ima_0*ima_1*ima_2.eq.1) then
              Elog = LOG(Ecm)
              Elog_1 = LOG(E_ref_1)
              Elog_2 = LOG(E_ref_2)
              prob = 0.1D0*4.D0/(Elog_2-Elog_1)**2
     &                   *(Elog-Elog_1)*(Elog_2-Elog)

              if(RNDM(0).lt.prob) then
                LL(1) = ip1
                LL(2) = 7
                LL(3) = 8
                LL(4) = 6
                ND = 4
              endif

            endif

          endif


          E_ref_1 = 1.95D0
          E_ref_2 = 2.55D0

          if((imul.eq.4)
     &       .and.(Ecm.gt.E_ref_1).and.(Ecm.lt.E_ref_2)) then

            ima_0 = 0
            ima_1 = 0
            ima_2 = 0
            imb_0 = 0
            imb_1 = 0
            iba_0 = 0
            iba_1 = 0
            iba_2 = 0
            ibb_0 = 0
            ibb_1 = 0
C  incoming proton
            if(ip1.eq.13) then
              iba_0 = 13
              iba_1 = 7
              iba_2 = 8
              ibb_0 = 14
              ibb_1 = 6
C  incoming neutron
            else if(ip1.eq.14) then
              iba_0 = 14
              iba_1 = 7
              iba_2 = 8
              ibb_0 = 13
              ibb_1 = 6
            endif
            do j=1,np
              if(LLIST(J).eq.iba_0) ima_0 = ima_0+1
              if(LLIST(J).eq.iba_1) ima_1 = ima_1+1
              if(LLIST(J).eq.iba_2) ima_2 = ima_2+1
              if(LLIST(J).eq.ibb_0) imb_0 = imb_0+1
              if(LLIST(J).eq.ibb_1) imb_1 = imb_1+1
            enddo

C  N gamma --> N pi+ pi- pi0
            if(ima_0*ima_1*ima_2*imb_1.eq.1) then
              Elog = LOG(Ecm)
              Elog_2 = LOG(E_ref_2)
              Elog_1 = LOG(E_ref_1)
              prob = 0.1D0*4.D0/(Elog_2-Elog_1)**2
     &                   *(Elog-Elog_1)*(Elog_2-Elog)

              if(RNDM(0).lt.prob) then
                if(ip1.eq.13) then
                  LL(1) = 14
                  LL(2) = 7
                  LL(3) = 7
                  LL(4) = 8
                else
                  LL(1) = 13
                  LL(2) = 7
                  LL(3) = 8
                  LL(4) = 8
                endif
                ND = 4
              endif

            endif

          endif


          if(ND.gt.0) then
            P_in(1) = 0.D0
            P_in(2) = 0.D0
            P_in(3) = 0.D0
            P_in(4) = Ecm
            P_in(5) = Ecm
            call DECPAR(0,P_in,ND,LL,P_dec)
            Iflip = 0
            do j=1,ND
              LLIST(j) = LL(j)
              do k=1,5
                SP(j,k) = P_dec(j,k)
              enddo
              if(((LLIST(j).eq.13).or.(LLIST(j).eq.14))
     &           .and.(SP(j,3).lt.0.D0)) Iflip = 1
            enddo
            if(Iflip.ne.0) then
              do j=1,ND
                SP(j,3) = -SP(j,3)
              enddo
            endif
            NP = ND
          endif

c... for fragmentation in resonance region:
  400     continue

          call DECSIB

      ENDIF

      if(Ideb.ge.10) then
        if(Ideb.ge.20) then
          call print_event(2)
        else
          call print_event(1)
        endif
      endif

      IQchr = ICHP(ip1)+ICHP(ip2)
      IQbar = IBAR(ip1)+IBAR(ip2)
      call check_event(-Ic,Ecm,0.D0,0.D0,0.D0,IQchr,IQbar,Irej)

      end


      SUBROUTINE print_event(Iout)
C*********************************************************************
C
C  print final state particles
C
C                                                  (R.E. 03/98)
C
C**********************************************************************

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)

      COMMON /S_RUN/ SQS, S, Q2MIN, XMIN, ZMIN, kb, kt, a1, a2, Nproc
       COMMON /S_PLIST/ SP(2000,5), LLIST(2000), NP, Ideb
       COMMON /S_CSYDEC/ CBR(102), IDB(49), KDEC(612), LBARP(49)
      COMMON /S_CHP/ S_LIFE(49), ICHP(49), ISTR(49), IBAR(49)
      COMMON /S_MASS1/ AM(49), AM2(49)
      COMMON /S_CNAM/ NAMP (0:49)
      CHARACTER*6 NAMP
      CHARACTER CODE*18
      SAVE

      if(iout.gt.0) then

        print *,' --------------------------------------------------'

        if(Nproc.eq.1) then
           print *,' diffractive rho-0 production',Nproc
        else if(Nproc.eq.2) then
           print *,' direct interaction 1',Nproc
        else if(Nproc.eq.3) then
           print *,' direct interaction 2',Nproc
        else if(Nproc.eq.4) then
           print *,' diffractive omega production',Nproc
        else if(Nproc.eq.0) then
           print *,' multi-pion/fragmentation contribution',Nproc
        else if((Nproc.gt.10).and.(Nproc.lt.20)) then
           print *,' resonance production and decay',Nproc-10
        else
           print *,' unknown process',Nproc
        endif

        i0 = 0
        px = 0.D0
        py = 0.D0
        pz = 0.D0
        ee = 0.D0
        ichar = 0
        ibary = 0
        do j=1,np
          l1 = abs(LLIST(J))
          l = mod(llist(j),10000)
          if(l1.lt.10000) then
            px = px + SP(j,1)
            py = py + SP(j,2)
            pz = pz + SP(j,3)
            ee = ee + SP(j,4)
            ichar = ichar+sign(1,l)*ICHP(iabs(l))
            ibary = ibary+sign(1,l)*IBAR(iabs(l))
          endif
          if((l1.lt.10000).or.(Iout.GE.2)) then
            i0 = i0+1
            code = '                  '
            code(1:6) = namp(iabs(l))
            if (l .lt. 0) code(7:9) = 'bar'
            write (6,120) i0,CODE,l1*sign(1,l),sign(1,l)*ICHP(iabs(l)),
     &        (SP(j,k),k=1,4)
          endif
        enddo
        write (6,122) '   sum: ',px,py,pz,ee
        print *,' charge QN: ',ichar,'    baryon QN: ',ibary
        print *,' --------------------------------------------------'
120     FORMAT(1X,I4,1X,A18,1X,I6,1X,I2,1X,2(F9.3,2X),2(E9.3,2X))
122     FORMAT(7X,A8,20X,2(F9.3,2X),2(E9.3,2X))

      endif

      END


      SUBROUTINE check_event(Ic,Esum,PXsum,PYsum,PZsum,IQchr,IQbar,Irej)
C***********************************************************************
C
C  check quantum number conservation of final state
C
C                                                (R.E. 08/98)
C
C***********************************************************************

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)

      COMMON /S_RUN/ SQS, S, Q2MIN, XMIN, ZMIN, kb, kt, a1, a2, Nproc
       COMMON /S_PLIST/ SP(2000,5), LLIST(2000), NP, Ideb
       COMMON /S_CSYDEC/ CBR(102), IDB(49), KDEC(612), LBARP(49)
      COMMON /S_CHP/ S_LIFE(49), ICHP(49), ISTR(49), IBAR(49)
      COMMON /S_MASS1/ AM(49), AM2(49)
      COMMON /S_CNAM/ NAMP (0:49)
      CHARACTER*6 NAMP
      SAVE

      px = 0.D0
      py = 0.D0
      pz = 0.D0
      ee = 0.D0
      ichar = 0
      ibary = 0
      Iprint = 0

      PLscale = Esum
      PTscale = 1.D0

      do j=1,np
        l1 = abs(LLIST(J))
        l = mod(llist(j),10000)
        if(l1.lt.10000) then
          px = px + SP(j,1)
          py = py + SP(j,2)
          pz = pz + SP(j,3)
          ee = ee + SP(j,4)
c          xm2 = (P(j,4)-P(j,3))*(P(j,4)+P(j,3))
c     &         -P(j,1)**2-P(j,2)**2
c          if(ABS(xm2-P(j,5)**2)/MAX(AM(l1),1.D0).gt.0.1D0) then
c            print *,' vector has incorrect mass (line, particle)',J,l1
c            print *,' mass (theory, actual, p(l,5)): ',
c     &        AM(l1),sqrt(xm2),P(j,5)
c            Iprint = 1
c          endif
          ichar = ichar+sign(1,l)*ICHP(iabs(l))
          ibary = ibary+sign(1,l)*IBAR(iabs(l))
        endif
      enddo

      if(ichar.ne.IQchr) then
        print *,' charge conservation violated',Ic
        Iprint = 1
      endif
      if(ibary.ne.IQbar) then
        print *,' baryon number conservation violated',Ic
        Iprint = 1
      endif
      if(abs((px-PXsum)/MAX(PXsum,PTscale)).gt.1.D-3) then
        print *,' x momentum conservation violated',Ic
        Iprint = 1
      endif
      if(abs((py-PYsum)/MAX(PYsum,PTscale)).gt.1.D-3) then
        print *,' y momentum conservation violated',Ic
        Iprint = 1
      endif
      if(abs((pz-Pzsum)/MAX(ABS(PZsum),PLscale)).gt.1.D-3) then
        print *,' z momentum conservation violated',Ic
        Iprint = 1
      endif
      if(abs((ee-Esum)/MAX(Esum,1.D0)).gt.1.D-3) then
        print *,' energy conservation violated',Ic
        Iprint = 1
      endif

      if(Iprint.ne.0) call print_event(1)

      Irej = Iprint

      END


      SUBROUTINE valences(ip,ival1,ival2)
C**********************************************************************
C
C    valence quark composition of various particles  (R.E. 03/98)
C    (with special treatment of photons)
C
C**********************************************************************

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)

      SAVE

      if(ip.eq.1) then
c... photon couples to quark:
        if(rndm(0).gt.0.2D0) then
c... photon couples to meson: pion-cloud model
*       if(rndm(0).gt.0.7D0) then
          ival1 = 1
          ival2 = -1
        else
          ival1 = 2
          ival2 = -2
        endif
      else if(ip.eq.6) then
        if(rndm(0).gt.0.5D0) then
          ival1 = 1
          ival2 = -1
        else
          ival1 = 2
          ival2 = -2
        endif
      else if(ip.eq.7) then
        ival1 = 1
        ival2 = -2
      else if(ip.eq.8) then
        ival1 = 2
        ival2 = -1
      else if(ip.eq.13) then
        Xi = rndm(0)
        if(Xi.lt.0.3333D0) then
          ival1 = 12
          ival2 = 1
        else if(Xi.lt.0.6666D0) then
          ival1 = 21
          ival2 = 1
        else
          ival1 = 11
          ival2 = 2
        endif
      else if(ip.eq.14) then
        Xi = rndm(0)
        if(Xi.lt.0.3333D0) then
          ival1 = 12
          ival2 = 2
        else if(Xi.lt.0.6666D0) then
          ival1 = 21
          ival2 = 2
        else
          ival1 = 22
          ival2 = 1
        endif
      endif

      if((ip.lt.13).and.(rndm(0).lt.0.5D0)) then
        k = ival1
        ival1 = ival2
        ival2 = k
      endif

      END


      SUBROUTINE DECSIB
C***********************************************************************
C
C   Decay all unstable particle in SIBYLL
C   decayed particle have the code increased by 10000
C
C   (taken from SIBYLL 1.7, R.E. 04/98)
C
C***********************************************************************

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)

       COMMON /S_CSYDEC/ CBR(102), IDB(49), KDEC(612), LBARP(49)
       COMMON /S_PLIST/ SP(2000,5), LLIST(2000), NP, Ideb
      COMMON /S_PLIST1/ LLIST1(2000)
      SAVE

      DIMENSION P0(5), LL(10), PD(10,5)

      NN = 1
      DO J=1,NP
         LLIST1(J) = 0
      ENDDO
      DO WHILE (NN .LE. NP)
         L= LLIST(NN)
         IF (IDB(IABS(L)) .GT. 0)  THEN
            DO K=1,5
              P0(K) = SP(NN,K)
            ENDDO
            ND = 0
            CALL DECPAR (L,P0,ND,LL,PD)
            LLIST(NN) = LLIST(NN)+ISIGN(10000,LLIST(NN))
            DO J=1,ND
               DO K=1,5
                  SP(NP+J,K) = PD(J,K)
               ENDDO
               LLIST(NP+J)=LL(J)
               LLIST1(NP+J)=NN
            ENDDO
            NP=NP+ND
         ENDIF
         NN = NN+1
      ENDDO

      END


      SUBROUTINE DECPAR(LA,P0,ND,LL,P)
C***********************************************************************
C
C   This subroutine generates the decay of a particle
C   with ID = LA, and 5-momentum P0(1:5)
C   into ND particles of 5-momenta P(j,1:5) (j=1:ND)
C
C   If the initial particle code is LA=0
C   then ND and LL(1:ND) are considered as  input and
C   the routine generates a phase space decay into ND
C   particles of codes LL(1:nd)
C
C   (taken from SIBYLL 1.7, muon decay corrected, R.E. 04/98)
C
C***********************************************************************

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)

       COMMON /S_CSYDEC/ CBR(102), IDB(49), KDEC(612), LBARP(49)
      COMMON /S_MASS1/ AM(49), AM2(49)
      SAVE

      DIMENSION P0(5), LL(10), P(10,5)
      DIMENSION PV(10,5), RORD(10), UE(3),BE(3), FACN(3:10)

      DATA FACN /2.D0,5.D0,15.D0,60.D0,250.D0,
     +          1500.D0,12000.D0,120000.D0/
      DATA PI /3.1415926D0/

C...c.m.s. Momentum in two particle decays
      PAWT(A,B,C) = SQRT((A**2-(B+C)**2)*(A**2-(B-C)**2))/(2.D0*A)

C...Phase space decay into the particles in the list
      IF (LA .EQ. 0)  THEN
          MAT = 0
          MBST = 0
          PS = 0.
          DO J=1,ND
             P (J,5) = AM(IABS(LL(J)))
             PV(J,5) = AM(IABS(LL(J)))
             PS = PS+P(J,5)
          ENDDO
          DO J=1,4
             PV(1,J) = P0(J)
          ENDDO
          PV(1,5) = P0(5)
          GOTO 140
      ENDIF

C...Choose decay channel
      L = IABS(LA)
      ND=0
      IDC = IDB(L)-1
      IF (IDC+1 .LE.0)  RETURN
      RBR = RNDM(0)
110   IDC=IDC+1
      IF(RBR.GT.CBR(IDC))  GOTO 110

      KD =6*(IDC-1)+1
      ND = KDEC(KD)
      MAT= KDEC(KD+1)

      MBST=0
      IF (MAT .GT.0 .AND. P0(4) .GT. 20.D0*P0(5)) MBST=1
      IF (MAT .GT.0 .AND. MBST .EQ. 0)
     +        BETA = SQRT(P0(1)**2+P0(2)**2+P0(3)**2)/P0(4)

      PS = 0.D0
      DO J=1,ND
         LL(J) = KDEC(KD+1+J)
         P(J,5)  = AM(LL(J))
         PV(J,5) = AM(LL(J))
         PS = PS + P(J,5)
      ENDDO
      DO J=1,4
         PV(1,J) = 0.D0
         IF (MBST .EQ. 0)  PV(1,J) = P0(J)
      ENDDO
      IF (MBST .EQ. 1)  PV(1,4) = P0(5)
      PV(1,5) = P0(5)

140   IF (ND .EQ. 2) GOTO 280

      IF (ND .EQ. 1)  THEN
         DO J=1,4
            P(1,J) = P0(J)
         ENDDO
         RETURN
      ENDIF

C...Calculate maximum weight for ND-particle decay
      WWTMAX = 1.D0/FACN(ND)
      PMAX=PV(1,5)-PS+P(ND,5)
      PMIN=0.D0
      DO IL=ND-1,1,-1
         PMAX = PMAX+P(IL,5)
         PMIN = PMIN+P(IL+1,5)
         WWTMAX = WWTMAX*PAWT(PMAX,PMIN,P(IL,5))
      ENDDO

C...generation of the masses, compute weight, if rejected try again
240   RORD(1) = 1.D0
      DO 260 IL1=2,ND-1
      RSAV = RNDM(0)
      DO 250 IL2=IL1-1,1,-1
      IF(RSAV.LE.RORD(IL2))   GOTO 260
250     RORD(IL2+1)=RORD(IL2)
260     RORD(IL2+1)=RSAV
      RORD(ND) = 0.D0
      WT = 1.D0
      DO 270 IL=ND-1,1,-1
      PV(IL,5)=PV(IL+1,5)+P(IL,5)+(RORD(IL)-RORD(IL+1))*(PV(1,5)-PS)
270   WT=WT*PAWT(PV(IL,5),PV(IL+1,5),P(IL,5))
      IF (WT.LT.RNDM(0)*WWTMAX)   GOTO 240

C...Perform two particle decays in respective cm frame
280   DO 300 IL=1,ND-1
      PA=PAWT(PV(IL,5),PV(IL+1,5),P(IL,5))
      UE(3)=2.D0*RNDM(0)-1.D0
      PHI=2.D0*PI*RNDM(0)
      UT = SQRT(1.D0-UE(3)**2)
      UE(1) = UT*COS(PHI)
      UE(2) = UT*SIN(PHI)
      DO 290 J=1,3
      P(IL,J)=PA*UE(J)
290   PV(IL+1,J)=-PA*UE(J)
      P(IL,4)=SQRT(PA**2+P(IL,5)**2)
300   PV(IL+1,4)=SQRT(PA**2+PV(IL+1,5)**2)

C...Lorentz transform decay products to lab frame
      DO 310 J=1,4
310   P(ND,J)=PV(ND,J)
      DO 340 IL=ND-1,1,-1
      DO 320 J=1,3
320   BE(J)=PV(IL,J)/PV(IL,4)
      GA=PV(IL,4)/PV(IL,5)
      DO 340 I=IL,ND
      BEP = BE(1)*P(I,1)+BE(2)*P(I,2)+BE(3)*P(I,3)
      DO 330 J=1,3
330   P(I,J)=P(I,J)+GA*(GA*BEP/(1.+GA)+P(I,4))*BE(J)
340   P(I,4)=GA*(P(I,4)+BEP)

C...Weak decays
        IF (MAT .EQ. 1)  THEN
           F1=P(2,4)*P(3,4)-P(2,1)*P(3,1)-P(2,2)*P(3,2)-P(2,3)*P(3,3)
           IF (MBST.EQ.1)  WT = P0(5)*P(1,4)*F1
           IF (MBST.EQ.0)
     +     WT=F1*(P(1,4)*P0(4)-P(1,1)*P0(1)-P(1,2)*P0(2)-P(1,3)*P0(3))
           WTMAX = P0(5)**4/16.D0
           IF(WT.LT.RNDM(0)*WTMAX)   GOTO 240
        ENDIF


C...Boost back for rapidly moving particle
      IF (MBST .EQ. 1)   THEN
         DO 440 J=1,3
440      BE(J)=P0(J)/P0(4)
         GA= P0(4)/P0(5)
         DO 460 I=1,ND
         BEP=BE(1)*P(I,1)+BE(2)*P(I,2)+BE(3)*P(I,3)
         DO 450 J=1,3
450         P(I,J)=P(I,J)+GA*(GA*BEP/(1.+GA)+P(I,4))*BE(J)
460         P(I,4)=GA*(P(I,4)+BEP)
      ENDIF

C...labels for antiparticle decay
      IF (LA .LT. 0 .AND. L .GT. 18)  THEN
           DO J=1,ND
            LL(J) = LBARP(LL(J))
         ENDDO
      ENDIF

      END


      SUBROUTINE PO_ALTRA(GA,BGX,BGY,BGZ,PCX,PCY,PCZ,EC,P,PX,PY,PZ,E)
C*********************************************************************
C
C    arbitrary Lorentz transformation
C
C    (taken from PHOJET v1.12, R.E. 08/98)
C
C*********************************************************************
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      SAVE

      EP=PCX*BGX+PCY*BGY+PCZ*BGZ
      PE=EP/(GA+1.D0)+EC
      PX=PCX+BGX*PE
      PY=PCY+BGY*PE
      PZ=PCZ+BGZ*PE
      P=SQRT(PX*PX+PY*PY+PZ*PZ)
      E=GA*EC+EP

      END


      SUBROUTINE PO_TRANS(XO,YO,ZO,CDE,SDE,CFE,SFE,X,Y,Z)
C**********************************************************************
C
C    rotation of coordinate frame (1) de rotation around y axis
C                                 (2) fe rotation around z axis
C
C    (taken from PHOJET v1.12, R.E. 08/98)
C
C**********************************************************************
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      SAVE

      X= CDE*CFE*XO-SFE*YO+SDE*CFE*ZO
      Y= CDE*SFE*XO+CFE*YO+SDE*SFE*ZO
      Z=-SDE    *XO       +CDE    *ZO

      END


      SUBROUTINE PO_SELSX2(XS1,XS2,XMIN,XMAX,AS1,AS2,IREJ)
C***********************************************************************
C
C    select x values of soft string ends using PO_RNDBET
C
C    (taken from PHOJET v1.12, R.E. 08/98)
C
C***********************************************************************
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)
      SAVE

      DIMENSION XS1(2),XS2(2)
      DIMENSION XMIN(2),XMAX(2)

      IREJ = 0

      GAM1 = +1.5D0 + 1.D0
      GAM2 = -0.5D0 + 1.D0
      BET1 = -0.5D0 + 1.D0
      BET2 = -0.5D0 + 1.D0

      ITRY0 = 0
      DO 100 I=1,100

        ITRY1 = 0
 10     CONTINUE
          X1 = PO_RNDBET(GAM1,BET1)
          ITRY1 = ITRY1+1
          IF(ITRY1.GE.50) THEN
            IREJ = 1
            RETURN
          ENDIF
        IF((X1.LE.XMIN(1)).OR.(X1.GE.XMAX(1))) GOTO 10

        ITRY2 = 0
 11     CONTINUE
          X2 = PO_RNDBET(GAM2,BET2)
          ITRY2 = ITRY2+1
          IF(ITRY2.GE.50) THEN
            IREJ = 2
            RETURN
          ENDIF
        IF((X2.LE.XMIN(2)).OR.(X2.GE.XMAX(2))) GOTO 11

        X3 = 1.D0 - X1
        X4 = 1.D0 - X2
        IF(X1*X2.GT.AS1) THEN
          IF(X3*X4.GT.AS2) GOTO 300
        ENDIF
        ITRY0 = ITRY0+1

 100  CONTINUE

      IREJ = 3
      RETURN

 300  CONTINUE

      XS1(1) = X1
      XS1(2) = X3

      XS2(1) = X2
      XS2(2) = X4

      END


      DOUBLE PRECISION FUNCTION PO_RNDBET(GAM,ETA)
C********************************************************************
C
C    random number generation from beta
C    distribution in region  0 < X < 1.
C    F(X) = X**(GAM-1.)*(1.-X)**(ETA-1)*GAMM(ETA+GAM) / (GAMM(GAM
C                                                        *GAMM(ETA))
C
C    (taken from PHOJET v1.12, R.E. 08/98)
C
C********************************************************************
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)
      SAVE

      Y = PO_RNDGAM(1.D0,GAM)
      Z = PO_RNDGAM(1.D0,ETA)
      PO_RNDBET = Y/(Y+Z)

      END


      DOUBLE PRECISION FUNCTION PO_RNDGAM(ALAM,ETA)
C********************************************************************
C
C    random number selection from gamma distribution
C    F(X) = ALAM**ETA*X**(ETA-1)*EXP(-ALAM*X) / GAM(ETA)
C
C    (taken from PHOJET v1.12, R.E. 08/98)
C
C********************************************************************
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)
      SAVE

      NCOU=0
      N = ETA
      F = ETA - N
      IF(F.EQ.0.D0) GOTO 20
   10 R = RNDM(0)
      NCOU=NCOU+1
      IF (NCOU.GE.11) GOTO 20
      IF(R.LT.F/(F+2.71828D0)) GOTO 30
      YYY=LOG(RNDM(0)+1.e-7)/F
      IF(ABS(YYY).GT.50.D0) GOTO 20
      Y = EXP(YYY)
      IF(LOG(RNDM(0)+1.D-7).GT.-Y) GOTO 10
      GOTO 40
   20 Y = 0.D0
      GOTO 50
   30 Y = 1.D0-LOG(RNDM(0)+1.D-7)
      IF(RNDM(0).GT.Y**(F-1.D0)) GOTO 10
   40 IF(N.EQ.0) GOTO 70
   50 Z = 1.D0
      DO 60 I = 1,N
   60 Z = Z*RNDM(0)
      Y = Y-LOG(Z+1.D-7)
   70 PO_RNDGAM = Y/ALAM

      END


      SUBROUTINE lund_frag(SQS,NP)
C***********************************************************************
C
C   interface to Lund/Jetset fragmentation
C
C                                    (R.E. 08/98)
C
C***********************************************************************

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)

      COMMON/LUJETS/N,K(4000,5),P(4000,5),V(4000,5)
      REAL P,V
      COMMON/LUDAT1/MSTU(200),PARU(200),MSTJ(200),PARJ(200)
      REAL PARU,PARJ
      COMMON/LUDAT3/MDCY(500,3),MDME(2000,2),BRAT(2000),KFDP(2000,5)
      REAL BRAT
      SAVE


C  no title page

        MSTU(12) = 0

C  define some particles as stable

        MSTJ_22 = MSTJ(22)
        MSTJ(22) = 2

C  in addition pi0 stable

        KC=LUCOMP(111)
        MDCY_pi0 = MDCY(KC,1)
        MDCY(KC,1)=0


C  switch popcorn effect off

        MSTJ_12 = MSTJ(12)
        MSTJ(12) = 1

C  suppress all warning and error messages

        MSTU_22 = MSTU(22)
        MSTU(22) = 0
        MSTU_25 = MSTU(25)
        MSTU(25) = 0


C  set energy dependent parameters

      PARJ_36 = PARJ(36)
      IF(SQS.LT.2.D0) THEN
        PARJ(36) = 0.1D0
      ELSE IF(SQS.LT.4.D0) THEN
        PARJ(36) = 0.7D0*(SQS-2.D0)/2.D0+0.1D0
      ELSE
        PARJ(36) = 0.8D0
      ENDIF

C  fragment string configuration

      II = MSTU(21)
      MSTU(21) = 1
      CALL LUEXEC
      MSTU(21) = II

C  event accepted?

      if(MSTU(24).ne.0) then
        NP = -1
        return
      endif

      CALL LUEDIT(1)

      NP = KLU(0,1)

C  restore original parameter settings

      MSTJ(12) = MSTJ_12
      MSTJ(22) = MSTJ_22

      MSTU(22) = MSTU_22
      MSTU(25) = MSTU_25

      MDCY(KC,1) = MDCY_pi0

      PARJ(36) = PARJ_36

      END


      SUBROUTINE lund_put(I,IFL,PX,PY,PZ,EE)
C***********************************************************************
C
C   store initial configuration into Lund common block
C
C                                                      (R.E. 08/98)
C
C***********************************************************************

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)

      COMMON/LUJETS/N,K(4000,5),P(4000,5),V(4000,5)
      REAL P,V
      COMMON/LUDAT1/MSTU(200),PARU(200),MSTJ(200),PARJ(200)
      REAL PARU,PARJ
      COMMON/LUDAT3/MDCY(500,3),MDME(2000,2),BRAT(2000),KFDP(2000,5)
      REAL BRAT
      SAVE

      if(IFL.eq.1) then
        Il = 2
      else if(IFL.eq.-1) then
        Il = -2
      else if(IFL.eq.2) then
        Il = 1
      else if(IFL.eq.-2) then
        Il = -1
      else if(IFL.eq.11) then
        Il = 2203
      else if(IFL.eq.12) then
        Il = 2101
      else if(IFL.eq.21) then
        Il = 2103
      else if(IFL.eq.22) then
        Il = 1103
      else
        print *,' lund_put: unkown flavor code',IFL
      endif

      P(I,1) = PX
      P(I,2) = PY
      P(I,3) = PZ
      P(I,4) = EE
      P(I,5) = (EE-PZ)*(EE+PZ)-PX**2-PY**2

      K(I,1) = 1
      K(I,2) = Il
      K(I,3) = 0
      K(I,4) = 0
      K(I,5) = 0

      N = I

      END


      SUBROUTINE lund_get(I,IFL,PX,PY,PZ,EE,XM)
C***********************************************************************
C
C   read final states from Lund common block
C
C                                                      (R.E. 08/98)
C
C***********************************************************************

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER (I-N)

      COMMON/LUJETS/N,K(4000,5),P(4000,5),V(4000,5)
      REAL P,V
      COMMON/LUDAT1/MSTU(200),PARU(200),MSTJ(200),PARJ(200)
      REAL PARU,PARJ
      COMMON/LUDAT3/MDCY(500,3),MDME(2000,2),BRAT(2000),KFDP(2000,5)
      REAL BRAT
      SAVE

      REAL PLU

      PX = PLU(I,1)
      PY = PLU(I,2)
      PZ = PLU(I,3)
      EE = PLU(I,4)
      XM = PLU(I,5)

      Il = KLU(I,8)

C  convert particle ID

      IFL = ICON_PDG_SIB(Il)

      END

      INTEGER FUNCTION ICON_PDG_SIB(ID)
C************************************************************************
C
C   convert PDG particle codes to SIBYLL particle codes
C
C                                         (R.E. 09/97)
C
C************************************************************************
      SAVE

      DIMENSION ITABLE(49)
      DATA ITABLE /
*  gam
     &                  22,
*  e+
     &                 -11,
*  e-
     &                  11,
*  mu+
     &                 -13,
*  mu-
     &                  13,
*  pi0
     &                 111,
*  pi+
     &                 211,
*  pi-
     &                -211,
*  k+
     &                 321,
*  k-
     &                -321,
*  k0l
     &                 130,
*  k0s
     &                 310,
*  p
     &                2212,
*  n
     &                2112,
*  nue
     &                  12,
*  nueb
     &                 -12,
*  num
     &                  14,
*  numb
     &                 -14,
*  pbar
     &           -99999999,
*  nbar
     &           -99999999,
*  k0
     &                 311,
*  k0b
     &                -311,
*  eta
     &                 221,
*  etap
CHS     &                 311,
CHS
CHS                       should read 331
CHS changed:
     &                 331,
*  rho+
     &                 213,
*  rho-
     &                -213,
*  rho0
     &                 113,
*  k*+
     &                 323,
*  k*-
     &                -323,
*  k*0
     &                 313,
*  k*0b
     &                -313,
*  omeg
     &                 223,
*  phi
     &                 333,
*  SIG+
     &                3222,
*  SIG0
     &                3212,
*  SIG-
     &                3112,
*  XI0
     &                3322,
*  XI-
     &                3312,
*  LAM
     &                3122,
*  DELT++
     &                2224,
*  DELT+
     &                2214,
*  DELT0
     &                2114,
*  DELT-
     &                1114,
*  SIG*+
     &                3224,
*  SIG*0
     &                3214,
*  SIG*-
     &                3114,
*  XI*0
     &                3324,
*  XI*-
     &                3314,
*  OME*-
     &                3334 /



      IDPDG = ID

 100  CONTINUE
      IDA = ABS(ID)

      IF(IDA.GT.1000) THEN
        IS = IDA
        IC = SIGN(1,IDPDG)
      ELSE
        IS = IDPDG
        IC = 1
      ENDIF

      DO I=1,49
        IF(IS.EQ.ITABLE(I)) THEN
          ICON_PDG_SIB = I*IC
          RETURN
        ENDIF
      ENDDO

      IF(IDPDG.EQ.80000) THEN
        ICON_PDG_SIB = 13
      ELSE
*       IF(IDA.EQ.411) THEN
*         IDPDG = SIGN(311,IDPDG)
*       ELSE IF(IDA.EQ.421) THEN
*         IDPDG = SIGN(321,IDPDG)
*       ELSE IF(IDA.EQ.431) THEN
*         IDPDG = SIGN(331,IDPDG)
*       ELSE IF(IDA.EQ.4122) THEN
*         IDPDG = SIGN(3122,IDPDG)
*       ELSE IF(IDA.EQ.4222) THEN
*         IDPDG = SIGN(3222,IDPDG)
*       ELSE IF(IDA.EQ.4222) THEN
*         IDPDG = SIGN(3222,IDPDG)
*       ELSE
          print *,'ICON_PDG_DTU: no particle found for ',IDPDG
          ICON_PDG_SIB = 0
          RETURN
*       ENDIF
*       GOTO 100
      ENDIF

      END


      INTEGER FUNCTION ICON_SIB_PDG(ISIB)
C************************************************************************
C
C   convert SIBYLL particle codes to PDG particle codes
C
C                                         (H.S. 07/99)
C
C************************************************************************
      SAVE

      DIMENSION ITABLE(49)
      DATA ITABLE /
*  gam
     &                  22,
*  e+
     &                 -11,
*  e-
     &                  11,
*  mu+
     &                 -13,
*  mu-
     &                  13,
*  pi0
     &                 111,
*  pi+
     &                 211,
*  pi-
     &                -211,
*  k+
     &                 321,
*  k-
     &                -321,
*  k0l
     &                 130,
*  k0s
     &                 310,
*  p
     &                2212,
*  n
     &                2112,
*  nue
     &                  12,
*  nueb
     &                 -12,
*  num
     &                  14,
*  numb
     &                 -14,
*  pbar
     &           -99999999,
*  nbar
     &           -99999999,
*  k0
     &                 311,
*  k0b
     &                -311,
*  eta
     &                 221,
*  etap
CHS     &                 311,
CHS
CHS                       should read 331
CHS changed:
     &                 331,
*  rho+
     &                 213,
*  rho-
     &                -213,
*  rho0
     &                 113,
*  k*+
     &                 323,
*  k*-
     &                -323,
*  k*0
     &                 313,
*  k*0b
     &                -313,
*  omeg
     &                 223,
*  phi
     &                 333,
*  SIG+
     &                3222,
*  SIG0
     &                3212,
*  SIG-
     &                3112,
*  XI0
     &                3322,
*  XI-
     &                3312,
*  LAM
     &                3122,
*  DELT++
     &                2224,
*  DELT+
     &                2214,
*  DELT0
     &                2114,
*  DELT-
     &                1114,
*  SIG*+
     &                3224,
*  SIG*0
     &                3214,
*  SIG*-
     &                3114,
*  XI*0
     &                3324,
*  XI*-
     &                3314,
*  OME*-
     &                3334 /

      ISIBA=ABS(ISIB)
      IF (ISIBA.GE.50) THEN
        print *,'ICON_SIB_PDG: wrong particle code: ISIB= ',ISIB
        ICON_SIB_PDG=0
        RETURN
      ENDIF
      ISGN=SIGN(1,ISIB)
      ICON_SIB_PDG=ISGN*ITABLE(ISIBA)
      RETURN
      END



      SUBROUTINE PO_MSHELL(PA1,PA2,XM1,XM2,P1,P2)
C********************************************************************
C
C    rescaling of momenta of two partons to put both
C                                       on mass shell
C
C    input:       PA1,PA2   input momentum vectors
C                 XM1,2     desired masses of particles afterwards
C                 P1,P2     changed momentum vectors
C
C    (taken from PHOJET 1.12, R.E. 08/98)
C
C********************************************************************
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      SAVE

      PARAMETER ( DEPS = 1.D-5 )

      DIMENSION PA1(4),PA2(4),P1(4),P2(4)

C  Lorentz transformation into system CMS
      PX = PA1(1)+PA2(1)
      PY = PA1(2)+PA2(2)
      PZ = PA1(3)+PA2(3)
      EE = PA1(4)+PA2(4)
      XMS = EE**2-PX**2-PY**2-PZ**2
      XMS = SQRT(XMS)
      BGX = PX/XMS
      BGY = PY/XMS
      BGZ = PZ/XMS
      GAM = EE/XMS
      CALL PO_ALTRA(GAM,-BGX,-BGY,-BGZ,PA1(1),PA1(2),PA1(3),
     &           PA1(4),PTOT1,P1(1),P1(2),P1(3),P1(4))
C  rotation angles
      PTOT1 = MAX(DEPS,PTOT1)
      COD= P1(3)/PTOT1
      SID= SQRT((1.D0-COD)*(1.D0+COD))
      COF=1.D0
      SIF=0.D0
      IF(PTOT1*SID.GT.1.D-5) THEN
        COF=P1(1)/(SID*PTOT1)
        SIF=P1(2)/(SID*PTOT1)
        ANORF=SQRT(COF*COF+SIF*SIF)
        COF=COF/ANORF
        SIF=SIF/ANORF
      ENDIF

C  new CM momentum and energies (for masses XM1,XM2)
      XM12 = XM1**2
      XM22 = XM2**2
      SS   = XMS**2
      PCMP = PO_XLAM(SS,XM12,XM22)/(2.D0*XMS)
      EE1  = SQRT(XM12+PCMP**2)
      EE2  = XMS-EE1
C  back rotation
      CALL PO_TRANS(0.D0,0.D0,PCMP,COD,SID,COF,SIF,XX,YY,ZZ)
      CALL PO_ALTRA(GAM,BGX,BGY,BGZ,XX,YY,ZZ,EE1,
     &           PTOT1,P1(1),P1(2),P1(3),P1(4))
      CALL PO_ALTRA(GAM,BGX,BGY,BGZ,-XX,-YY,-ZZ,EE2,
     &           PTOT2,P2(1),P2(2),P2(3),P2(4))

      END


      DOUBLE PRECISION FUNCTION PO_XLAM(X,Y,Z)
C**********************************************************************
C
C     auxiliary function for two/three particle decay mode
C     (standard LAMBDA**(1/2) function)
C
C     (taken from PHOJET 1.12, R.E. 08/98)
C
C**********************************************************************
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      SAVE

      YZ=Y-Z
      XLAM=X*X-2.D0*X*(Y+Z)+YZ*YZ
      IF(XLAM.LT.0.D0) XLAM=-XLAM
      PO_XLAM=SQRT(XLAM)

      END


      DOUBLE PRECISION FUNCTION RNDM(IDUMMY)
C***********************************************************************
C
C     double precision random number generator
C
C***********************************************************************
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      SAVE

      REAL RLU

      RNDM = DBLE(RLU(IDUMMY))

      END
