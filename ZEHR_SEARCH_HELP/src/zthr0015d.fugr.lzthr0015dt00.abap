*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTHR0015D.......................................*
DATA:  BEGIN OF STATUS_ZTHR0015D                     .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTHR0015D                     .
CONTROLS: TCTRL_ZTHR0015D
            TYPE TABLEVIEW USING SCREEN '9000'.
*.........table declarations:.................................*
TABLES: *ZTHR0015D                     .
TABLES: ZTHR0015D                      .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
