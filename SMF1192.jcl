//IBM010S   JOB (SMFD),'VIC CROSS SYS',
//             NOTIFY=&SYSUID,
//             CLASS=A,MSGCLASS=H,MSGLEVEL=(1,1)
//*----------------------------------------------------------------*
//* UNLOAD SMF 119 subtype 2 RECORDS FROM LOGSTREAM                *
//* Also, change the DCB reference to match the name of your       *
//* weekly SMF dump dataset. Change the SPACE allocation values    *
//*----------------------------------------------------------------*
//CONDMP   EXEC  PGM=IFASMFDL,REGION=0M
//OUTDA    DD DSN=&&COPY,DISP=(NEW,PASS),
//           UNIT=SYSDA,SPACE=(CYL,(10,10),RLSE),
//           DCB=(RECFM=VBS,LRECL=32756,BLKSIZE=0)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
              LSNAME(IFASMF.ASGPLEX1.SYSTEM)
              RELATIVEDATE(BYDAY,7,7)
              OUTDD(OUTDA,TYPE(119(2)))
/*
//*----------------------------------------------------------------*
//* COPY VBS TO VB, DROP HEADER/TRAILER RECORDS, SORT ON DATE/TIME *
//* Note: change the CONSMF DSN=hlq.conrec to the name of          *
//* the dataset you'll use in the last step.                       *
//* Change the SPACE allocation values.                            *
//*----------------------------------------------------------------*
//CONSEL   EXEC PGM=ICETOOL
//DFSMSG   DD SYSOUT=*
//RAWSMF   DD DSN=&&COPY,DISP=(OLD,DELETE)
//CONSMF   DD DSN=&&SMFDAT,DISP=(NEW,PASS),
//            DCB=(RECFM=VB,LRECL=32756,BLKSIZE=0),UNIT=SYSDA,
//            SPACE=(CYL,(10,10),RLSE)
//CON1CNTL DD *
              OPTION DYNALLOC,VLSHRT,SPANINC=RC4
              INCLUDE COND=(6,1,BI,EQ,119,AND,23,2,BI,EQ,2)
              SORT FIELDS=(11,4,PD,A,7,4,BI,A)
/*
//TOOLMSG  DD SYSOUT=*
//REPORT   DD SYSOUT=*
//TOOLIN   DD *
              SORT FROM(RAWSMF) TO(CONSMF) USING(CON1)
/*
//*----------------------------------------------------------------*
//* FORMAT TCP/IP Connection termination TYPE 119 subtype 2 records*
//* Note: change the SYSEXEC DSN=your.rexx.library to the name     *
//* of the dataset where you have placed the TCPCONN REXX EXEC.    *
//* Also, change the SMFREC  DSN=hlq.conrec to the name of         *
//* the dataset you have created in the previous step.             *
//*----------------------------------------------------------------*
//CONREXX  EXEC PGM=IKJEFT01,REGION=0M,DYNAMNBR=50
//SYSEXEC  DD DSN=IBM010.MVS.JCL,DISP=SHR
//SMFREC   DD DSN=&&SMFDAT,DISP=(OLD,DELETE)
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
prof nopref
%TCPCONN
/*
