*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTEHR0001.......................................*
DATA:  BEGIN OF STATUS_ZTEHR0001                     .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTEHR0001                     .
CONTROLS: TCTRL_ZTEHR0001
            TYPE TABLEVIEW USING SCREEN '9000'.
*.........table declarations:.................................*
TABLES: *ZTEHR0001                     .
TABLES: ZTEHR0001                      .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
