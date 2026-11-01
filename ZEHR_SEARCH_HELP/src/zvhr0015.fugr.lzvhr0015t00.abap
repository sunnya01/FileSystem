*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZVHR0015........................................*
TABLES: ZVHR0015, *ZVHR0015. "view work areas
CONTROLS: TCTRL_ZVHR0015
TYPE TABLEVIEW USING SCREEN '9000'.
DATA: BEGIN OF STATUS_ZVHR0015. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_ZVHR0015.
* Table for entries selected to show on screen
DATA: BEGIN OF ZVHR0015_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE ZVHR0015.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZVHR0015_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF ZVHR0015_TOTAL OCCURS 0010.
INCLUDE STRUCTURE ZVHR0015.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZVHR0015_TOTAL.

*.........table declarations:.................................*
TABLES: ZTHR0015                       .
TABLES: ZTHR0015T                      .
