      PROGRAM RADCOOL
C
C***************************************************************
C THE PROGRAM CALCULATES THE COOLING POTENTIAL FOR A GIVEN AREA
C THE COOLING POTENTIAL IS EVALUATED IN TERMS OF THE STAGNATION 
C TEMPERATURE AND THE NET RADIATIVE FLUX OF A RADIATOR
C ATHANASSIOS ARGIRIOU 7 - 5 - 1990
C***************************************************************
C
C CONSTANTS
C
      DATA SBOLTZ/5.67E-08/
C
C RADIATOR CHARACTERISTICS
C
      DATA ERAD/.9/,XR,YR,ZR,DZR/2.,.5,.01,.002/
C
C WINDSCREEN CHARACTERISTICS
C
       DATA TRANS/.75/,DWSC/1.56E-02/,CWSC/.46/,Z1/.03/
C
C FUNCTIONS
C
      TFOUT(T,TS,D,V,CP,U,X,Z)=TS+(T-TS)*EXP(-U*X/D/V/CP/Z)
C
C
C INPUT PARAMETERS
C
      WRITE(*,9001)
 9001 FORMAT(1X,'ENTER DAY   MONTH    LATITUDE')
      READ(*,*)DAY,MONTH,SLAT
C
      WRITE(*,9000)
 9000 FORMAT(1X,'ENTER MEAN AMB. TEMP (C), TEMP AMPL (C), RH(%),
     *WIND VEL (m/s), SKY COV')
      READ(*,*)TMEAN,TAMPL,RH,WV,OSC
C
C     WRITE(*,9002)
C9002 FORMAT(1X,'ENTER FLUID VELOCITY')
C     READ(*,*)FV
      DO 20 J=1,10
      FV=FLOAT(J)-.5
      WRITE(*,9600)FV
 9600 FORMAT(1X,'FLUID VELOCITY=',F4.1)
C
C DAILY COOLING PERIOD
C
      CALL COOLPER(DAY,MONTH,SLAT,ISTART,ISTOP)
C
C INITIALISATION
C
      WRITE(*,9100)
 9100 FORMAT(19X,'NO WINDSCREEN',12X,'WINDSCREEN')
      WRITE(*,9200)
 9200 FORMAT(1X,'HOUR  T AMB    T STAG   DT   T OUT',4X,
     *'T STAG   DT   T OUT')
C
      DO 10 I=ISTART,ISTOP
C
      IF (I.LE.24) THEN
      TIME=FLOAT(I)
      ELSE
      TIME=FLOAT(I-24)
      ENDIF
C
C AMBIENT TEMPERATURE CALCULATION
C
      TA=TSIN(TMEAN,TAMPL,TIME)
C
C CALCULATION OF THE THERMOPHYSICAL PARAMETERS
C
      ESKY=EBERD(TDEW(RH,TA),TIME)*CA(OSC)
      HE0=HW0(WV)+4.*ERAD*SBOLTZ*(TA+273.15)**3
      HE1=HW1(WV)+4.*TRANS*ERAD*SBOLTZ*(TA+273.15)**3
      CALL HFLU(TA,XR,FV,HF)
      U0=1./(1./HE0+1./HF+DZR/CSTEEL(TA))
      U1=1./(1./HE1+1./HF+DZR/CSTEEL(TA))
C
C STAGNATION TEMPERATURE
C
      TSTAG0=STAG(TA,ERAD,ESKY,HE0)
      TSTAG1=STAG(TA,ERAD*TRANS,ESKY,HE1)
C
C FLUID OUTLET TEMPERATURE
C
      TF0=TFOUT(TA,TSTAG0,DAIR(TA),FV,CPAIR(TA),U0,XR,ZR)
      TF1=TFOUT(TA,TSTAG1,DAIR(TA),FV,CPAIR(TA),U1,XR,ZR)
C
C COOLING POWER
C
      TM0=(TA+TF0)/2.
      TM1=(TA+TF1)/2.
      Q0=Q0+POWER(TA,TF0,FV,DAIR(TM0),CPAIR(TM0),XR,ZR)
      Q1=Q1+POWER(TA,TF1,FV,DAIR(TM1),CPAIR(TM1),XR,ZR)
C
C CONDENSATION CONTROL
C
      CALL DEWTEST(TA,TF1,TM1,RH,HF,WV,Z1)
C
C RESULTS
C
      WRITE(*,9005)TIME,TA,TSTAG0,TA-TSTAG0,TF0,TSTAG1,
     *TA-TSTAG1,TF1
 9005 FORMAT(2X,F3.0,3X,F4.1,2(5X,F4.1,3(3X,F4.1)))
 10   CONTINUE
      WRITE(*,9500)Q0,Q1
 9500 FORMAT(/,1X,'DAILY COOLING LOAD WITHOUT WINDSCREEN  ',F7.2,
     *2X,'Wh/m2',/,1X,'DAILY COOLING LOAD WITH    WINDSCREEN  '
     *F7.2,2X,'Wh/m2',//)
      Q0=0.
      Q1=0.
 20   CONTINUE
      END
C
      SUBROUTINE HFLU(TA,X,FV,HF)
C***************************************************************
C CONVECTIVE HEAT TRANSFER COEFFICIENT FOR FORCED CONVECTION
C UNDER A HORIZONTAL PLATE
C ATHANASSIOS ARGIRIOU, 30 - 5 - 1990
C***************************************************************
C
      REY=RE(FV,X,DAIR(TA),DVAIR(TA))
      PRA=PR(CPAIR(TA),DVAIR(TA),CAIR(TA))
      IF (REY.LE.500000.)THEN
      HF=.664*REY**.5*PRA**(1./3.)*CAIR(TA)/X
      ELSE
      HF=PRA**(1./3.)*(.036*REY**.8-836.)*CAIR(TA)/X
      ENDIF
      RETURN
      END
C
      SUBROUTINE COOLPER(DAY,MONTH,SLAT,ISTART,ISTOP)
C***************************************************************
C DETERMINATION OF THE NOCTURNAL COOLING PERIOD
C ATHANASSIOS ARGIRIOU, 30 - 5 - 1990
C***************************************************************
C
      CALL SDEC(DAY,MONTH,DEC)
      CALL RISET(SLAT,DEC,SR,SST,DLG)
      DAY1=DAY+1.
      CALL SDEC(DAY1,MONTH,DEC1)
      CALL RISET(SLAT,DEC1,SR1,SST1,DLG1)
      ISTART=IFIX(SST)+1
      ISTOP=IFIX(SR1)+24
      RETURN
      END
C
C
      FUNCTION STAG(T,ER,ES,HE)
C
C CALCULATION OF THE STAGNATION TEMPERATURE FOR AN UNCOVERED
C RADIATOR
C
      DATA SBOLTZ/5.67E-08/
      STAG=T-ER*SBOLTZ*(1.-ES)*(T+273.15)**4/HE
      RETURN
      END
C
C
      FUNCTION POWER(TA,TF,FV,D,CP,X,Z)
C
C CALCULATION OF THE COOLING LOAD (Wh/m2)
C
      POWER=D*FV*Z*CP*(TA-TF)/X
      RETURN
      END
C
C
      FUNCTION HRG(TRAD,Z1)
      HRG=CAIR(TRAD)/Z1
      RETURN 
      END
C
C
      SUBROUTINE DEWTEST(TA,TF1,TM1,RH,HF,WV,Z1)
C******************************************************************
C ROUTINE FOR CHECKING THE POSSIBILITY OF DEW FORMATION ON THE
C WINDSCREEN OF A RADIATOR
C ATHANASSIOS ARGIRIOU, 30 - 5 - 1990
C******************************************************************
C
      TRAD=TM1-DAIR(TM1)*FV*(TA-TF1)/HF
      TWSC=(TA*HW0(WV)+TRAD*HRG(TRAD,Z1))/(HW0(WV)+HRG(TRAD,Z1))
      IF((TWSC-TDEW(RH,TA)).GT.2.)THEN
      GO TO 800
      ELSE
         IF((TWSC-TDEW(RH,TA)).GT.1.)THEN
         WRITE(*,9800)
 9800    FORMAT(1X,'DANGER FOR DEW FORMATION')
         ELSE
         WRITE(*,9810)
 9810    FORMAT(1X,'ATTENTION!!-DEW FORMATION')
         ENDIF
      ENDIF
 800  RETURN
      END
