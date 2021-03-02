/* REXX  TCP/IP  subtype 02                                        */
/* The TCP  Connection Termination record  is collected whenever   */
/* a TCP connection is closed or aborted. This record contains     */
/* all pertinent information about the connection, such as elapsed */
/* time, bytes transferred, and so on.                             */
/*-----------------------------------------------------------------*/
/* From an original implementation by Mile Pekic, published in     */
/* Xephon TCP/SNA Update, September 2005 edition.                  */
/*-----------------------------------------------------------------*/
/* CHANGE HISTORY                                                  */
/* ==============                                                  */
/* 20210303 Vic Cross  Addition of CSV generation                  */
/* 20210226 Vic Cross  Bug fix in local IP address                 */
/* 20210223 Vic Cross  Sample addition of AT-TLS report criterion  */
/*                                                                 */
/*-----------------------------------------------------------------*/
Numeric digits 32
ADDRESS TSO
userid=SYSVAR(SYSUID)
/*-----------------------------------------------------------*/
/* Part 1: Handle report files allocation & datasets         */
/*         existence                                         */
/*-----------------------------------------------------------*/
conc = userid||'.conc.rep'       /* Connection close report */
conccsv = userid||'.conc.csv'    /* Connection close report */
cons = userid||'.cons.rep'       /* Connection close stat report */
conscsv = userid||'.cons.csv'    /* Connection close stat report */
x = MSG('ON')
IF SYSDSN(conc) = 'OK'
  THEN  "DELETE  "conc"  PURGE"
"ALLOC FILE(CONN) DA("conc")",
  "UNIT(SYSALLDA) NEW TRACKS  SPACE(29,29)  CATALOG",
  "REUSE RELEASE LRECL(275) RECFM(F B)"
IF SYSDSN(conccsv) = 'OK'
  THEN  "DELETE  "conccsv"  PURGE"
"ALLOC FILE(CONNCSV) DA("conccsv")",
  "UNIT(SYSALLDA) NEW TRACKS  SPACE(29,29)  CATALOG",
  "REUSE RELEASE LRECL(275) RECFM(F B)"
IF SYSDSN(cons) = 'OK'
  THEN  "DELETE  "cons"  PURGE"
"ALLOC FILE(CONNS) DA("cons")",
  "UNIT(SYSALLDA) NEW TRACKS  SPACE(29,29)  CATALOG",
  "REUSE RELEASE LRECL(115) RECFM(F B)"
IF SYSDSN(conscsv) = 'OK'
  THEN  "DELETE  "conscsv"  PURGE"
"ALLOC FILE(CONNSCSV) DA("conscsv")",
  "UNIT(SYSALLDA) NEW TRACKS  SPACE(29,29)  CATALOG",
  "REUSE RELEASE LRECL(115) RECFM(F B)"
/*---------------------------------------------------------*/
/* Print TCP Connection Termination report header          */
/*---------------------------------------------------------*/
hdr.1 = left('TCP Connection Termination report',50)
hdr.2 = left(' ',1,' ')
hdr.3 = left('Report produced on',18),
        ||left(' ',1,' ')||left(date(),12),
        ||left('at',3,' ')||left(time(),10)
hdr.4 = left(' ',1,' ')
"EXECIO * DISKW CONN(STEM hdr.)"
hd.1 = left("PART 2: Connection termination detail report:",50)
hd.2 = left(' ',1,' ')
hd.3 = left("Connection ended at:",24)
hd.4 = left("Date",12)          left("time",14) ,
       left("Duration",12)      left("Dur.sec",7) ,
       left("ASName",8)         left("Sec.  ID",7) ,
       left("ASID",5)           left("User ID",8) ,
       left("Status",7)         left("Conn ID",7) ,
       left("Protocol",8)       left("Application",23) ,
       left("LIP",9)            left("LPN",7) ,
       left("RIP",9)            left("RPN",4) ,
       left("RTT",4)            left("RVA",6) ,
       left("M.R",7)            left("InB",3) ,
       left("InB.sec",7 )       left("OutB",4) ,
       left("OutB.sec",8 )      left("InSG",6) ,
       left("OutSG",5)          left("SGsize",6) ,
       left("Rxmit",5)          left("WSend",7) ,
       left("WMax",8)           left("WCong",6) ,
       left("SWidx",7)          left("CWidx",6)
hd.5 = left('-',272,'-')
/*---------------------------------------------------------*/
/*  Print TCP Connection Termination statistics report hd. */
/*---------------------------------------------------------*/
sdr.1 = left('TCP Connection Termination statistics report',80)
sdr.2 = left(' ',1,' ')
sdr.3 = left('Report produced on',18),
        ||left(' ',1,' ')||left(date(),12),
        ||left('at',3,' ')||left(time(),10)
sdr.4 = left(' ',1,' ')
"EXECIO * DISKW CONNS(STEM sdr.)"
hs.1 = left(' ',1,' ')
hs.2 = left("Port",4)           left("Protocol",8) ,
       left("Application",18)   left("used",4) ,
       left("Conn.time",11)     left("Rxmit",9) ,
       left("InB",8)            left("OutB",6) ,
       left("InSG",5)           left("OutSG",11) ,
       left("InB  %",11)        left("OutB  %",13)
hs.3 = left('-',112,'-')
"EXECIO * DISKW CONNS(STEM hs.)"
xhd.1 = hd.2
xhd.2 = left("PART 3: Connections with retransmissions > 5:",60)
xhd.3 = hd.2; xhd.4 = hd.3
xhd.5 = hd.4; xhd.6 = hd.5
rhd.1 = hd.2
rhd.2 = left("PART 4: Connections with Round Trip Time > 400 ms.",60)
rhd.3 = hd.2; rhd.4 = hd.3
rhd.5 = hd.4; rhd.6 = hd.5
chd.1 = hd.2
chd.2 = left("PART 5: Connections with congestion window > 10 max.",70)
chd.3 = hd.2; chd.4 = hd.3
chd.5 = hd.4; chd.6 = hd.5
/* -------------------------------------------------------------*/
hdcsv.1 = "Date,time,Duration,Dur.sec,ASName,Sec.ID,ASID,UserID,"||,
          "Status,Conn ID,Application,LIP,LPN,RIP,RPN,"||,
          "RTT,RVA,M.R,InB,InBsec,OutB,OutBsec,InSG,OutSG,SGsize,"||,
          "Rxmit,WSend,WMax,WCong,SWidx,CWidx"
"EXECIO * DISKW CONNCSV(STEM hdcsv.)"
/* ---------------------------------------------------------*/
/* Set various counters to zero                             */
/* ---------------------------------------------------------*/
inrec = 0; xmit = 0; totinsg  = 0
rtt   = 0; cw   = 0; totoutsg = 0
port_count. = 0; port_time. = 0
port_inb.   = 0; totinb     = 0
port_outb.  = 0; totoutb    = 0
port_ins.   = 0; port_xmm.  = 0
port_outs.  = 0; Tot_elap   = 0
Tot_xmit    = 0; Tot_con    = 0
/* ---------------------------------------------------------*/
/*                      Main processing loop                */
/* ---------------------------------------------------------*/
DO FOREVER
  "EXECIO 1 DISKR SMFREC"
  IF RC /= 0 THEN call End_of_file
  else do
    inrec = inrec + 1
    PARSE PULL record
    PARSE VAR record header 41 rest
    SMF119HDType= c2d(substr(header,2,1)) /* Record type */
    call SMFREC_header
  end
End
/*---------------------------------------------------------*/
/* Print "End of file" summary stat                        */
/*---------------------------------------------------------*/
End_of_file:
Select
  when xmit > 0 then do
    "EXECIO * DISKW CONN (STEM xhd.)"
    "EXECIO * DISKW CONN (STEM xm.)"
  end
  otherwise nop
End
Select
  when rtt > 0 then do
    "EXECIO * DISKW CONN (STEM rhd.)"
    "EXECIO * DISKW CONN (STEM trip.)"
  end
  otherwise nop
End
Select
  when cw > 0 then do
    "EXECIO * DISKW CONN (STEM chd.)"
    "EXECIO * DISKW CONN (STEM 0conw.)"
  end
  otherwise nop
End

lgg.1  = "                                     "
lgg.2  = "LEGEND:                              "
lgg.3  = "    "
lgg.4  = "End date     - Connection end date: connection entered       "
lgg.5  = "               TIMEWAIT or LASTACK state. "
lgg.6  = "End time     - Time of connection end.        "
lgg.7  = "Duration     - Connection duration in hh:mm:ss.tt format. "
lgg.8  = "Dur.sec      - Connection duration in seconds. "
lgg.9  = "ASName       - Started task qualifier or address space name of "
lgg.10 = "               address space that writes this SMF record. "
lgg.11 = "Sec. ID      - User ID of security context under which this "
lgg.12 = "               SMF record is written. "
lgg.13 = "ASID         - ASID of address space that writes this SMF rec. "
lgg.14 = "User ID      - TCP socket resource name: address space name of "
lgg.15 = "               address space that closed this TCP connection. "
lgg.16 = "Status       - Socket status: "
lgg.17 = "                 Passive Open (server socket) "
lgg.18 = "                 Active Open  (client socket) "
lgg.19 = "Conn ID      - TCP socket resource ID (Connection ID). "
lgg.20 = "LIP          - Local IP address at time of connection close. "
lgg.21 = "LPN          - Local port number at time of connection close. "
lgg.22 = "RIP          - Remote IP address at time of connection close. "
lgg.23 = "RPN          - Remote port number at time of connection close. "
lgg.24 = "RTT          - Round Trip Time in milliseconds. "
lgg.25 = "RVA          - Round Trip Time Variance. "
lgg.26 = "M.R          - Max Rate of traffic in this service class. "
lgg.27 = "InB          - Inbound byte count. "
lgg.28 = "InB.sec      - Inbound byte per second. "
lgg.29 = "OutB         - Outbound byte count. "
lgg.30 = "OutB.sec     - Outbound byte per second. "
lgg.31 = "InSG         - Inbound segment count. "
lgg.32 = "OutSG        - Outbound segment count. "
lgg.33 = "SGsize       - Send Segment Size. "
lgg.34 = "Rxmit        - Number of times retransmission was required. "
lgg.35 = "WSend        - Send Window Size at time of connection close. "
lgg.36 = "WMax         - Maximum Send Window Size. "
lgg.37 = "WCong        - Congestion Window Size at time of close. "
lgg.38 = "SWidx        - Send Window index (ratio to Maximum Send Window) "
lgg.39 = "CWidx        - Congestion Window index (vs Maximum Send Window) "
"EXECIO  *  DISKW  CONN  (STEM  lgg.)"
slg.1  = "                                                      "
slg.2  = "LEGEND: "
slg.3  = " "
slg.4  = "Application - The name of application using the port "
slg.5  = "Used - The number of connection using this port "
slg.6  = "Conn.time - Total connection time for this port "
slg.7  = "Rxmit - Total number of retransmission for this port "
slg.8  = "InB - Total Inbound byte count for this port "
slg.9  = "OutB - Total Outbound byte count fort this port "
slg.10 = "InSG - Total Inbound segment count for this poer "
slg.11 = "OutSG - Total Outbound segment count fort this port "
slg.12 = "InB% - Pct of total Inbound byte count for this port "
slg.13 = "OutB% - Pct of total Outbound byte count for this port"
ss.1 = left('-',88,'-')
DO lpn = 1 to 9999
if port_count.lpn > 0 then
  call printline right(lpn,4) , /* Port number                 */
  left(Pxlate(lpn),26) ,        /* Port description            */
  right(port_count.lpn,4) ,     /* Number of port connections  */
  smf(port_time.lpn) ,          /* Connection time             */
  right(port_xmm.lpn,4) ,       /* Retransmissions             */
  right(port_inb.lpn,9) ,       /* Inbound byte count          */
  right(port_outb.lpn,9) ,      /* Total Outbound byte count   */
  right(port_ins.lpn,6) ,       /* Inbound segment count       */
  right(port_outs.lpn,6) ,      /* Outbound segment count      */
  format((port_inb.lpn/totinb)*100,6,4) ,
  format((port_outb.lpn/totoutb)*100,6,4)
end
"EXECIO * DISKW CONNS(STEM ss.)"
call printline left("TOTAL:",31)   right(Tot_con,4) ,
               smf(Tot_elap)       right(Tot_xmit,4) ,
               right(totinb,9)     right(totoutb,9) ,
               right(totinsg,6)    right(totoutsg,6)
"EXECIO * DISKW CONNS(STEM slg.)"
/*  Close & free all allocated files */
"EXECIO 0 DISKR CONN   (FINIS"
"EXECIO 0 DISKR CONNS  (FINIS"
"EXECIO 0 DISKR CONNCSV   (FINIS"
"EXECIO 0 DISKR CONNSCSV  (FINIS"
"EXECIO 0 DISKR SMFREC (FINIS"
say "TCP Connection report file: "conc
say "TCP Connection Statistic report file: "cons
"FREE FILE(CONN SMFREC)"
EXIT 0
SMFREC_header:
/*---------------------------------------------------------------------*/
/* Part 2: Get SMF record header segment                               */
/*---------------------------------------------------------------------*/
s119HDType= c2d(substr(header,2,1))             /* Record type         */
s119HDTime = SMF(c2d(substr(header,03,04)))     /* Record written time */
s119HDDate ,
  = substr(c2x(substr(header,07,04)),3,5)       /* Record written date */
s119HDSID = substr(header,11,04)                /* System id           */
s119HDSSI = substr(header,15,02)                /* Subsystem ID        */
SubType = c2d(substr(header,19,02))
s119SD_TRN = c2d(substr(header,21,02))
s119IDOff  = c2d(substr(header,25,04)) /* Offset to TCP/IP Id       */
s119IDLen  = c2d(substr(header,29,02)) /* Length of TCP/IP Id.sec.  */
s119IDNum  = c2d(substr(header,31,02)) /* Number of TCP/IP Id       */
s119S1Off  = c2d(substr(header,33,04)) /* Offset to TCP Conn. close */
s119S1Len  = c2d(substr(header,37,02)) /* Length of TCP Conn. close */
s119S1Num  = c2d(substr(header,39,02)) /* Number of TCP Conn. close */
smfdate= left(Date('N',s119HDDate,'J'),11)
Select
  when s119IDNum > 0 then call TCPIP_id
  otherwise nop
End
return
TCPIP_id:
/*---------------------------------------------------------------*/
/* Part 3: Common TCP/IP Identification Section - present in     */
/* every SMF type 119 record produced by the TCP/IP stack.       */
/* Its purpose is to identify the system and stack responsible   */
/* for producing the record.                                     */
/*---------------------------------------------------------------*/
PARSE var rest
off01 = s119IDOff - 43
s119TI_SYSName     = substr(rest,off01,8)    /* System name         */
s119TI_SysplexName = substr(rest,off01+8,8)  /* Sysplex name        */
s119TI_Stack       = substr(rest,off01+16,8) /* Stack name          */
s119TI_ReleaseID   = substr(rest,off01+24,8) /* CS/390 release id.  */
s119TI_Comp        = substr(rest,off01+32,8) /* TCP/IP subcomponent */
s119TI_ASName      = substr(rest,off01+40,8) /* ASID name of writer */
s119TI_UserID      = substr(rest,off01+48,8) /* User ID of security */
s119TI_ASID   = c2x(substr(rest,off01+58,2)) /* ASID of writer      */
s119TI_Reason      = substr(rest,off01+60,1) /* Reason for writing  */
Select
  when s119TI_Comp = 'CSSMTP  ' then comp = "z/CS SMTP"
  when s119TI_Comp = 'FTPC    ' then comp = "FTP Client"
  when s119TI_Comp = 'FTPS    ' then comp = "FTP Server"
  when s119TI_Comp = 'IDS3270 ' then comp = "3270 IDS  "
  when s119TI_Comp = 'IKE     ' then comp = "IKE daemon"
  when s119TI_Comp = 'IP      ' then comp = "IP layer  "
  when s119TI_Comp = 'SMCD    ' then comp = "SMC Direct"
  when s119TI_Comp = 'SMCR    ' then comp = "SMC RDMA  "
  when s119TI_Comp = 'STACK   ' then comp = "Entire TCP/IP stack"
  when s119TI_Comp = 'TCP     ' then comp = "TCP layer     "
  when s119TI_Comp = 'TN3270C ' then comp = "TN3270 Client "
  when s119TI_Comp = 'TN3270S ' then comp = "TN3270 Server "
  when s119TI_Comp = 'UDP     ' then comp = "UDP layer     "
  otherwise                          comp = "... error ... "
End
s119TI_ReasonIntInc  = 'C0'x
s119TI_ReasonInt     = '80'x
s119TI_ReasonIEndInc = '60'x
s119TI_ReasonIEnd    = '20'x
s119TI_ReasonIShtInc = '50'x
s119TI_ReasonISht    = '10'x
s119TI_ReasonEvtMore = '48'x
s119TI_ReasonEvt     = '08'x
if bitand(s119TI_Reason,s119TI_ReasonIntInc ) = s119TI_ReasonIntInc then
  reason = 'C0 Interval statistics record, more records follow'
if bitand(s119TI_Reason,s119TI_ReasonInt ) = s119TI_ReasonInt then
  reason = '80 Interval statistics record, last record in set'
if bitand(s119TI_Reason,s119TI_ReasonIEndInc) =  s119TI_ReasonIEndInc then
  reason = '60 End-of-statistics record, more records follow'
if bitand(s119TI_Reason,s119TI_ReasonIEnd ) = s119TI_ReasonIEnd then
  reason = '20 End-of-statistics record, last record in set'
if bitand(s119TI_Reason,s119TI_ReasonIShtInc) = s119TI_ReasonIShtInc then
  reason = '50 Shutdown starts record, more records follow'
if bitand(s119TI_Reason,s119TI_ReasonISht ) = s119TI_ReasonISht then
  reason = '10 Shutdown starts record, last record in set'
if bitand(s119TI_Reason,s119TI_ReasonEvtMore ) = s119TI_ReasonEvtMore then
  reason = '48 Event record, more records follow'
if bitand(s119TI_Reason,s119TI_ReasonEvt ) = s119TI_ReasonEvt then
  reason = '08 Event record, last record in set'
/*-----------------------------------------------------------*/
/* Print System identification                               */
/*-----------------------------------------------------------*/
Select
  when inrec = 1 then do
    hds.1 = left("PART 1: SYSTEM ID:",44)
    hds.2 = left("System ID.  :",13) left(s119HDSID,8)
    hds.3 = left("System name :",13) left(s119TI_SYSName,8)
    hds.4 = left("Sysplex Name:",13) left(s119TI_SysplexName,8)
    hds.5 = left("Stack name  :",13) left(s119TI_Stack,8)
    hds.6 = left("Release ID  :",13) left(s119TI_ReleaseID,8)
    hds.7 = left(' ',1,' ')
    "EXECIO * DISKW CONN(STEM hds.)"
    "EXECIO * DISKW CONN(STEM hd.)"
  end
  otherwise nop
End
Select
  when s119S1Num > 0 then call TCP_close
  otherwise nop
End
return
TCP_close: procedure EXPOSE      ,
port_count. port_inb. port_outb. ,
trip. conw. port_ins. port_outs. ,
s119S1Off   s119TI_UserID  s119TI_ASName s119TI_ASID,
rest inrec xmit rtt cw xm. Tot_xmit Tot_con   totinsg ,
totinb totoutb port_xmm.  port_time. Tot_elap totoutsg
/*-----------------------------------------------------------------*/
/* Part 4: TCP Connection Termination section                      */
/* Two notes:                                                      */
/* Since this information duplicates all of the information        */
/* contained in the TCP Connection Initiation record, it is        */
/* recommended that users only collect the TCP Connection          */
/* Termination record.                                             */
/* Because this record is generated for every single TCP connection*/
/* this can generate significant load on a server and rapidly fill */
/* the SMF datasets. Care should be exercised in its use.          */
/*-----------------------------------------------------------------*/
PARSE var rest
off   = s119S1Off -43
s119_TTRName    = substr(rest,off,8)         /* Socket resource name  */
s119_TTConnID   = c2d(substr(rest,off+8,4))  /* TCP connection id     */
s119_TTTTLSCS   = substr(rest,off+12,1)      /* AT-TLS conn status    */
s119_TTTTLSPS   = substr(rest,off+13,1)      /* AT-TLS policy status  */
s119_TTTermCode = substr(rest,off+14,1)      /* Conn Termination code */
s119_TTSMCStatus= substr(rest,off+15,1)      /* SMC-R status          */
s119_TTSubTask  = c2d(substr(rest,off+16,4)) /* Subtask name: address */
                                             /* of  MVS  TCB for the  */
                                             /* task that owns this   */
                                             /* connection. Note that */
                                             /* this is not the       */
                                             /* subtask value specifie*/
                                             /* on an INITAPI call.   */
s119_TTSTime    = smf(c2d(substr(rest,off+20,4)))
                                             /* Connection start time */
s119_TTSDate    = ,                          /* Connection start date */
         substr(c2x(substr(rest,off+24,4)),3,5)
s119_TTETime=smf(c2d(substr(rest,off+28,4))) /* Connection end time   */
s119_TTEDate = ,                             /* Connection end date   */
substr(c2x(substr(rest,off+32,4)),3,5)
condate = left(Date('N',s119_TTSDate,'J'),11)
enddate = left(Date('N',s119_TTEDate,'J'),11)
start    =     c2d(substr(rest,off+20,4))    /* Connection start time */
endt     =     c2d(substr(rest,off+28,4))    /* Connection end time   */
elap     = cross(endt,start)
Tot_elap = Tot_elap + elap
elaps    = smf(elap)
s119_TTRIP =     substr(rest,off+36,16)      /* Remote IP addr.(IPv6 )*/
s119_TTRIPRsvd       = substr(rest,off+36,12)  /*Unused if IPv4 format*/
s119_TTRIPRsvd10     = substr(rest,off+36,10)        /* IPv6 reserved */
s119_TTRIPFmt1       = c2d(substr(rest,off+46,1))
                                             /*IPv4 address format - 1*/
s119_TTRIPFmt2       = c2d(substr(rest,off+47,1))
                                             /*IPv4 address format - 2*/
s119_TTRIP_IPv41     = c2d(substr(rest,off+48,1))
                                             /*IPv4 piece 1 of address*/
s119_TTRIP_IPv42     = c2d(substr(rest,off+49,1))
                                             /*IPv4 piece 2 of address*/
s119_TTRIP_IPv43     = c2d(substr(rest,off+50,1))
                                             /*IPv4 piece 3 of address*/
s119_TTRIP_IPv44     = c2d(substr(rest,off+51,1))
                                             /*IPv4 piece 4 of address*/
fmt = s119_TTRIPFmt1||"."||s119_TTRIPFmt2
Rip = s119_TTRIP_IPv41||"."||s119_TTRIP_IPv42||"."||,
  s119_TTRIP_IPv43||"."||s119_TTRIP_IPv44
s119_TTLIP =     substr(rest,off+52,16)  /* Local IP address (IPv6)   */
s119_TTLIPRsvd = substr(rest,off+52,12)  /* Unused if IPv4 addressing */
s119_TTLIPRsvd10=substr(rest,off+52,10)      /* IPv6 reserved         */
s119_TTLIPFmt1= c2d(substr(rest,off+62,1))   /* IPv4 address flagg1   */
s119_TTLIPFmt2= c2d(substr(rest,off+63,1))   /* IPv4 address flagg2   */
s119_TTLIP_IPv1 = c2d(substr(rest,off+64,1)) /*IPv4 piece 1 of address*/
s119_TTLIP_IPv2 = c2d(substr(rest,off+65,1)) /*IPv4 piece 2 of address*/
s119_TTLIP_IPv3 = c2d(substr(rest,off+66,1)) /*IPv4 piece 3 of address*/
s119_TTLIP_IPv4 = c2d(substr(rest,off+67,1)) /*IPv4 piece 4 of address*/
Lip = s119_TTLIP_IPv1||"."||s119_TTLIP_IPv2||"."||,
  s119_TTLIP_IPv3||"."||s119_TTLIP_IPv4
s119_TTRPort =c2d(substr(rest,off+68,2))     /* Remote port           */
s119_TTLPort =c2d(substr(rest,off+70,2))     /* Local port            */
s119_TTInBytes =c2d(substr(rest,off+72,8))   /* Inbound byte count    */
s119_TTOutBytes=c2d(substr(rest,off+80,8))   /* Outbound byte count   */
s119_TTSWS =c2d(substr(rest,off+88,4))       /* Send window size      */
s119_TTMSWS =c2d(substr(rest,off+92,4))      /* Max send window size  */
s119_TTCWS  =c2d(substr(rest,off+96,4))      /* Congestion window size*/
s119_TTSMS=c2d(substr(rest,off+100,4))   /* Send segment size at close*/
s119_TTRTT=c2d(substr(rest,off+104,4))   /* Round trip time at close  */
s119_TTRVA=c2d(substr(rest,off+108,4))       /* RTT variance at close */
s119_TTStatus =c2x(substr(rest,off+112,1))   /* Socket status         */
Select
  when s119_TTStatus = '00' then Socket = 'Server'
  otherwise                      Socket = 'Client'
End
s119_TTTOS =c2x(substr(rest,off+113,1))      /* Type of service       */
s119_TTXRT=c2d(substr(rest,off+114,2))     /* Number of retransmits   */
s119_TTProf=   substr(rest,off+116,32)     /* Service profile name    */
s119_TTPol = substr(rest,off+148,32)       /* Service policy name     */
s119_TTInSeg=c2d(substr(rest,off+180,8))   /* Inbound segment count   */
s119_TTOutSeg=c2d(substr(rest,off+188,8))  /* Outbound segment count  */
totinsg        = totinsg  + s119_TTInSeg
totoutsg       = totoutsg + s119_TTOutSeg
Tot_xmit       = Tot_xmit + s119_TTXRT
Tot_con        = Tot_con  + 1
trm            = s119_TTXRT
ins            = s119_TTInSeg
outs           = s119_TTOutSeg
lpn            = s119_TTLPort
inb            = s119_TTInBytes
outx           = s119_TTOutBytes
totinb         = totinb  + inb
totoutb        = totoutb + outx
port_count.lpn = port_count.lpn + 1
port_xmm.lpn   = port_xmm.lpn   + trm
port_inb.lpn   = port_inb.lpn   + inb
port_outb.lpn  = port_outb.lpn  + outx
port_ins.lpn   = port_ins.lpn   + ins
port_outs.lpn  = port_outs.lpn  + outs
port_time.lpn  = port_time.lpn  + elap
/*-----------------------------------------------------------------*/
/* Calculate:                                                      */
/* 1. Send window index                                            */
/* 2. Congestion window index                                      */
/* 3. Inbound byte rate (per second)                               */
/* 4. Outbound byte rate (per second)                              */
/* 5. Max traffic rate                                             */
/*-----------------------------------------------------------------*/
Select
  when (s119_TTSWS > 0) then do
    if s119_TTMSWS > 0 then ,
      senwindex = format(((s119_TTSWS/s119_TTMSWS)*100),4,2)
    end
  otherwise senwindex = 'n.a'
End
Select
  when (s119_TTCWS > 0) then do
    if s119_TTMSWS > 0 then ,
      congindex = format(((s119_TTCWS/s119_TTMSWS)*100),4,2)
  end
  otherwise congindex = 'n.a'
End
Select
  when (s119_TTInBytes > 0) then do
    if elap > 0 then insec = ,
      format((s119_TTInBytes/elap/100),7,2)
  end
  otherwise insec = 0
End
Select
  when (s119_TTOutBytes > 0) then do
    if elap > 0 then outsec = ,
      format((s119_TTOutBytes/elap/100),7,2)
  end
  otherwise outsec = 0
End
Select
  when s119_TTRTT > 0 then  ,
    maxrate = format(((s119_TTCWS/s119_TTRTT)/1.024),8,0)
  otherwise maxrate = "n.a"
End
/* Print */
protd = Pxlate(s119_TTLPort)
rc.1 = left(enddate,12),             /* Connection end time        */
       left(s119_TTETime,13),        /* Connection end time        */
       left(elaps,12)       ,        /* Connection in hh:mm:ss:tt  */
       right(elap/100,8)    ,        /* Connection duration (sec.) */
       left(s119TI_ASName,8),        /* ASID name of writer        */
       left(s119TI_UserID,8),        /* User ID of security        */
       left(s119TI_ASID,4)  ,        /* ASID of writer             */
       left(s119_TTRName,8) ,        /* TCP socket name            */
       left(socket,7)       ,        /* Socket status              */
       left(s119_TTConnID,8),        /* Connection ID              */
       left(protd,26)       ,        /* Port description           */
       left(Lip,13)         ,        /* Local IP address           */
       right(s119_TTLPort,4),        /* Local port number          */
       left(Rip,13)         ,        /* Remote IP address          */
       right(s119_TTRPort,4),        /* Remote port number         */
       right(s119_TTRTT,3)  ,        /* Round Trip Time            */
       right(s119_TTRVA,4)  ,        /* Round Trip Time Variance   */
       right(MaxRate,8)     ,        /* Max Rate                   */
       right(s119_TTInBytes,5),      /* Inbound byte count         */
       right(insec,6)       ,        /* Inbound byte per sec.      */
       right(s119_TTOutBytes,5),     /* Outbound byte count        */
       right(outsec,6)      ,        /* Outbound byte per sec.     */
       right(s119_TTInSeg,6),        /* Inbound segment count      */
       right(s119_TTOutSeg,6),       /* Outbound segment count     */
       right(s119_TTSMS,6)  ,        /* Send Segment Size          */
       right(s119_TTXRT,3)  ,        /* Number of retransmission   */
       right(s119_TTSWS,8)  ,        /* Send Window Size           */
       right(s119_TTMSWS,7) ,        /* Maximum Send Window Size   */
       right(s119_TTCWS,7)  ,        /* Congestion Window Size     */
       right(senwindex,7)   ,        /* Send Window index          */
       right(congindex,7)            /* Congestion Window index    */
  "EXECIO * DISKW CONN(STEM rc.)"
rccsv.1 = enddate","||,              /* Connection end time        */
            s119_TTETime","||,       /* Connection end time        */
            elaps","||,              /* Connection in hh:mm:ss:tt  */
             elap/100","||,          /* Connection duration (sec.) */
       s119TI_ASName","||,           /* ASID name of writer        */
       s119TI_UserID","||,           /* User ID of security        */
       s119TI_ASID","||,             /* ASID of writer             */
       s119_TTRName","||,            /* TCP socket name            */
       socket","||,                  /* Socket status              */
       s119_TTConnID","||,           /* Connection ID              */
       protd","||,                   /* Port description           */
       Lip","||,                     /* Local IP address           */
       s119_TTLPort","||,            /* Local port number          */
       Rip","||,                     /* Remote IP address          */
       s119_TTRPort","||,            /* Remote port number         */
       s119_TTRTT","||,              /* Round Trip Time            */
       s119_TTRVA","||,              /* Round Trip Time Variance   */
       MaxRate","||,                 /* Max Rate                   */
       s119_TTInBytes","||,          /* Inbound byte count         */
       insec","||,                   /* Inbound byte per sec.      */
       s119_TTOutBytes","||,         /* Outbound byte count        */
       outsec","||,                  /* Outbound byte per sec.     */
       s119_TTInSeg","||,            /* Inbound segment count      */
       s119_TTOutSeg","||,           /* Outbound segment count     */
       s119_TTSMS","||,              /* Send Segment Size          */
       s119_TTXRT","||,              /* Number of retransmission   */
       s119_TTSWS","||,              /* Send Window Size           */
       s119_TTMSWS","||,             /* Maximum Send Window Size   */
       s119_TTCWS","||,              /* Congestion Window Size     */
       senwindex","||,               /* Send Window index          */
       congindex                     /* Congestion Window index    */
  "EXECIO * DISKW CONNCSV(STEM rccsv.)"
/*------------------------------------------------------------------*/
/* Select records for PART 3, PART 4 & PART 5 of report:            */
/*        PART 3: Connections with retransmissions > 5              */
/*        PART 4: Connections with Round Trip Time > 400 ms         */
/*        PART 5: Connections with congestion window > 10 max       */
/*        PART 6: Connections Secured by AT-TLS                     */
/*------------------------------------------------------------------*/
Select
  when s119_TTXRT > 5 then do
    xmit = xmit + 1
    xm.xmit = rc.1
    xmcsv.xmit = rccsv.1
  end
  otherwise nop
End
Select
  when s119_TTRTT > 400 then do
    rtt = rtt + 1
    trip.rtt = rc.1
  end
  otherwise nop
End
Select
  when (s119_TTMSWS > 0) then do
    if (s119_TTCWS > s119_TTMSWS*10) then do
      cw = cw + 1
      conw.cw = rc.1
    end;
  end
  otherwise nop
End
If s119_TTTTLSCS = X'03' then do
  tls = tls + 1
  attls.tls = rc.1
  Select
    when portnumber = 23 then do /* Telnet */
      tntls = tntls + 1
      attls_tn.tntls = rc.1
    end
    when portnumber = 21 then do /* FTP    */
      fttls = fttls + 1
      attls_ft.fttls = rc.1
    end
    when portnumber = 25 then do /* SMTP   */
      smtls = smtls + 1
      attls_sm.smtls = rc.1
    end
    otherwise do                 /* others */
      mstls = mstls + 1
      attls_ms.mstls = rc.1
    end
  end
End
return
SMF: procedure
/*-------------------------------------------------------------*/
/* REXX - convert an SMF time to hh:mm:ss:hd format            */
/*-------------------------------------------------------------*/
arg time
time1 = time % 100
hh = time1 % 3600;                    hh = right("0"||hh,2)
mm = (time1 % 60) - (hh * 60);        mm = right("0"||mm,2)
ss = time1 - (hh * 3600) - (mm * 60); ss = right("0"||ss,2)
fr = time //  1000;                   fr = right("0"||fr,2)
rtime = hh||":"||mm||":"||ss||":"||fr
return rtime
CROSS: procedure
/*-------------------------------------------------------------*/
/*        Cover the midnight crossover                         */
/*-------------------------------------------------------------*/
arg endtime,startime
select
  when endtime >= startime then nop
  otherwise  endtime = endtime + 8640000
end
diftm = endtime - startime
return diftm

Printline:
/*-------------------------------------------------------------*/
/*         Print each report line                              */
/*-------------------------------------------------------------*/
PARSE arg lineout1
"EXECIO 1 DISKW CONNS (STEM lineout)"
if rc \= 0 then do
  say "printline RC =" RC
  exit rc
end                                        /* end of printline */
Return

Pxlate:
/*---------------------------------------------------------------*/
/* Port assignment lookup table                                  */
/* Please note that this is only a sample list which must        */
/* be updated to reflect your installation's port assignment.    */
/*---------------------------------------------------------------*/
Parse Arg port
Select
  when port =    7 then Des = "TCP/UDP Echo            "
  when port =    9 then Des = "TCP/UDP Discard         "
  when port =   19 then Des = "TCP/UDP CharGen         "
  when port =   20 then Des = "TCP FTP (data)          "
  when port =   21 then Des = "TCP FTP (control)       "
  when port =   23 then Des = "TCP Telnet              "
  when port =   25 then Des = "TCP SMTP Server         "
  when port =   53 then Des = "TCP/UDP DNS             "
  when port =   80 then Des = "TCP HTTP                "
  when port =  111 then Des = "TCP/UDP Portmap         "
  when port =  135 then Des = "UDP NCS Loc.Broker      "
  when port =  161 then Des = "UDP SNMP Agent          "
  when port =  162 then Des = "UDP SNMP Query          "
  when port =  443 then Des = "TCP HTTPS               "
  when port =  512 then Des = "TCP Remote Exec         "
  when port =  514 then Des = "TCP Remote Exec         "
  when port =  515 then Des = "TCP LPD Server          "
  when port =  520 then Des = "UDP OROUTED Serv        "
  when port =  580 then Des = "UDP NCPROUTE Serv       "
  when port =  750 then Des = "TCP/UDP Kerberos        "
  when port =  751 then Des = "TCP/UDP Kerberos Admin  "
  when port = 1389 then Des = "TCP LDAP                "
  when port = 1443 then Des = "TCP HTTPS               "
  when port = 1933 then Des = "TCP ILM MA Port         "
  when port = 1934 then Des = "TCP ILM AA Port         "
  when port = 1933 then Des = "TCP ILM MT Agent        "
  when port = 1934 then Des = "TCP ILM LM Appl Agent   "
  when port = 2809 then Des = "TCP ORB port            "
  when port = 3000 then Des = "TCP Prod CICS Socket    "
  when port = 3001 then Des = "TCP Test1 CICS Socket   "
  when port = 3002 then Des = "TCP Test2 CICS Socket   "
  when port = 4463 then Des = "TCP DB2                 "
  when port = 8080 then Des = "TCP HTTP Server Alt port"
  when port = 8801 then Des = "TCP RMF/PM Java         "
  when port = 8880 then Des = "TCP SOAP JMX Conn.      "
  when port = 9080 then Des = "TCP HTTP port           "
  otherwise             Des = "   fill in gap          "
End
Return Des
