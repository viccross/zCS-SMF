# zCS-SMF
A little tool for analysing SMF 119 records from z/OS Communications Server IP Services.

## The Scene
The year is 2021.  SMF 119 provides a treasure trove of data ripe for analysis.  Most organisations have learned that the richness of data available in SMF 119 records is best plundered using a commercial tool fit-for-purpose.  Only with such a tool can the drudgery of manual parsing of bit fields and EBCDIC values be avoided, and the available wisdom easily extracted.

However, in a world where the popular choice can so often lead to a path of commodity dreariness, the brave few still choose to worship their SMF data with hand-woven tools.  Parsing the fields, assigning values to variables, calculating averages and peaks, and tabulating by protocol... these are the true seekers of wisdom, for they understand the true value and meaning of the data within.

They are... The Net Whisperers!

## The Purpose
This tool is a simple program to read TCP/IP connection records from SMF and perform simple analysis.  

More importantly, it is meant to illustrate that while it is possible for SMF analysis to be done using an "end-user" tool, it is not for the feint-hearted and should be considered to be a matter of serious programming effort and maintenance.  Many commercial products exist, and such tools should be seriously considered.

## The original Source
The tool has been modified from an original source in the Xephon TCP/SNA Update, September 2005 edition, in an article by Mile Pekic.  Full credit to Mile as the original author of this utility.  It is a testament to the original code, and to z/CS, that it ran almost unchanged on current z/OS some 15 years after original publishing.

## The Data
Records analysed by this tool are SMF type 119 subtype 2, the "TCP connection termination record".  This record is used rather than the subtype 1 record, which is the connection initiation record, because the subtype 2 record contains a superset of the data in the subtype 1 record.  Subtype 1 possibly is more interesting in real-time analysis, when it may be necessary at a point-in-time to know what sessions are in progress.  For historical traffic analysis however, since all the information in the subtype 1 record is also available in the subtype 2 record, processing only the subtype 2 records does not result in a loss of usable data.

Following IBM's documented recommendation to use SMF type 119 instead of type 118, SMF type 118 records are not and will not be processed by this tool.

## The Process
The tool comes in two parts: JCL to extract and sort the appropriate SMF records, and a REXX parser and reporter tool.  The JCL invokes the appropriate utilities to extract and sort the records, then invokes the analysis exec.

A single job stream performs all steps, and uses temporary datasets in between.  If you have large numbers of records and the extraction process is too intensive, the extraction and sorting steps could be separated into their own job stream that creates a staging dataset for use by the REXX utility.  The REXX utility (which itself is very lightweight) could then be run more frequently if needed.

### SMF record extraction
The example JCL assumes an SMF log stream, so it uses the utility `IFASMFDL` to extract records from the stream.  If you have SMF datasets instead of logstream, you will change the JCL to use `IFASMFDP` instead.  The example logstream is specified in the `LSNAME` selector; again if you are using datasets instead of logstream you will specify your SMF source using a `INDD` selector that references a DD card that points to your SMF dataset.

The `RELATIVEDATE` selector specifies the date range of the records to be extracted.  In our example we are selecting the past 7 days worth of data.  `BYDAY` indicates that the selection values are in days, the first `7` means to go 7 days into the past as the start date, and the second `7` means to extract 7 days of data.  Here is a different example:
* Job run on Julian day 21062 (3 March 2021) with selector `RELATIVEDATE(BYDAY,7,4)`:
  * Start date = 21062 - `7` = 21055 (24 February 2021)
  * End date = first day 21055 + next 3 days = 21058 (27 February 2021)
  * Total of `4` days of data extracted: 21055-21058 inclusive

You can see that specifying `BYDAY,7,7` does not include the current day.  If you need to extract data for the day on which the job is run, you would use a duration value one unit greater than the step back in time.  For example, to get the last 4 days worth of data inclusive of today would be `RELATIVEDATE(BYDAY,3,4)`.  To extract *only* today's data, you would use `RELATIVEDATE(BYDAY,0,1)`.  Note that the SMF unload utility will give RC=4 in these situations, and a message indicating that the end time specified is past current real time and will be truncated to the current time.

### REXX analysis EXEC
The REXX program `TCPCONN` processes each record as it is read from the input dataset.  The record is parsed, and certain additional values calculated (such as calculating average data rate for the session based on its duration).  The record is formatted and output to the full report dataset and to the full CSV dataset.  Some of the values from the record are added to aggregation variables collecting summarised data based on protocol.

The record is then tested against certain interesting criteria.  In the example, the criteria are:
* Retransmissions greater than 5
* Max RTT (round-trip time) greater than 400ms
* Congenstion window greater than 10

The record is written to a stem variable for the particular criteria if it meets any of them.  The example shows that it is failrly easy to extend the selection to include new criteria; the example shows a partially-impemented criterion for "connections secured by AT-TLS".

As mentioned, the original text-based reports have been expanded through the addition of CSV output data.  Using CSV makes it fairly easy to perform further analysis using a desktop tool.  Reading of the generated CSV file has been tested with both Microsoft Excel and Apple Numbers on macOS.

## Installation
Until I come up with a polished installation process, do the following:
* Download the `SMF1192` and `TCPCONN` files
* Upload to a convenient location where you keep your JCL and/or EXECs.  On my system I use the same PDS for these, but your system may vary.  Upload the files as TEXT so that they get converted to EBCDIC (usual stuff).
* Edit the `SMF1192` JCL for:
  * Correct SMF log stream or dataset (remember to change the unload utility as well if you use SMF datasets)
  * SMF extraction date range as appropriate
* Edit the `TCPCONN` EXEC for:
  * DS names of output files for the reports and CSV files

## Further development
This tool is not officially supported in any capacity.  Suggestions for enhancements are welcome but I make no commitment to expand the tool or implement any capabilities.  Having said that, I can see there are features that would be worthwhile:
* Addition of a "control" or "parameter" file to control runtime behaviour.  This could be used to selectively enable or disable certain reports, to change settings like date format, or other characteristics
* Merging of records: SMF 119 type 2 is a very small portion of the available data.  There are many other records available, such as those generated by TCP/IP components such as the TN3270 Server, FTP client and server, and so on.  Corellating the type 2 data at the TCP level with the other data captured in other records at the protocol level would be useful and allow a consolidated data view (rather than potentially having to cross-reference different reports).
* Generation of HTML output (including graphs, using a graphic generation tool).  HTML output could be served by a z/OS web server, but generation of graphics and more complex presentation is something that could best be performed in a zCX container.
* Coverage of UDP data in addition to TCP

Again I must stress -- while this is a functional tool, it's main purpose is as a tool to convey the complexity of SMF data analysis.  While "end-user" SMF parsing is possible, it is complex and error-prone and very difficuly to expand or enhance.

