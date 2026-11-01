*----------------------------------------------------------------------*
***INCLUDE LZEHR_FG_COMMF02.
*----------------------------------------------------------------------*

*{   INSERT         HRDK902557                                        1
*&---------------------------------------------------------------------*
*& Form CONVERT_DATUM_TO_TIMESTAMPS
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> SY_DATUM
*&      --> SY_UZEIT
*&      <-- LS_IFLOG_TSTMP
*&---------------------------------------------------------------------*

FORM convert_datum_to_timestamps USING p_date TYPE d
                                       p_time TYPE t
                                 CHANGING p_timestamp TYPE timestamp.
  DATA: l_timezone  LIKE ttzz-tzone.
  CONVERT DATE p_date
          TIME p_time
          INTO
          TIME STAMP p_timestamp  TIME ZONE l_timezone.
ENDFORM.
*}   INSERT
