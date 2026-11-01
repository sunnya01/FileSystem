FUNCTION zfm_ehr_get_shlp_fr_shlp.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     REFERENCE(IV_LANGU) TYPE  LANGU DEFAULT SY-LANGU
*"     REFERENCE(IV_ZVERS) TYPE  MOLGA DEFAULT '28'
*"     REFERENCE(IS_ZTHR0015) TYPE  ZTHR0015
*"  EXPORTING
*"     REFERENCE(ES_HEAD) TYPE  ZSHR_SHH_HEAD
*"  TABLES
*"      IT_SHH_CONDITION STRUCTURE  ZSHR_F4_CONDITION OPTIONAL
*"      ET_SHH_DATA STRUCTURE  ZSHR_F4_TAB
*"----------------------------------------------------------------------
  DATA:help_values TYPE STANDARD TABLE OF seahlpres,
       help_value  TYPE seahlpres.
  DATA:ls_shlp     TYPE shlp_descr_t.
  DATA:ls_ddfields TYPE dfies.

  DATA:ls_fields LIKE dfies,
       ls_selopt TYPE ddshselopt,
       lt_selopt TYPE ddshselops.
  DATA:lv_key   TYPE string,
       lv_value TYPE string.

  DATA:lv_offset    TYPE i.
  DATA:lv_leng      TYPE i.
  DATA:lt_str       TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA:BEGIN OF lt_fields OCCURS 0,
         fielda TYPE string,
         fieldb TYPE string,
       END OF lt_fields.

  CLEAR ls_shlp.
  ls_shlp-shlpname = is_zthr0015-zznam.
  ls_shlp-shlptype = 'SH'.

  CALL FUNCTION 'DD_SHLP_GET_HELPMETHOD'
    CHANGING
      shlp              = ls_shlp
    EXCEPTIONS
      field_not_found   = 1
      no_help_for_field = 2
      OTHERS            = 3.
  REFRESH ls_shlp-selopt.

*语言
  IF is_zthr0015-zfkey NE 'SPRAS'.
    CLEAR ls_ddfields.
    READ TABLE ls_shlp-fielddescr INTO ls_ddfields WITH KEY domname = 'SPRAS'.
    IF sy-subrc EQ 0.
      CLEAR ls_selopt.
      ls_selopt-shlpname  = ls_ddfields-tabname.
      ls_selopt-shlpfield = ls_ddfields-fieldname.
      ls_selopt-sign      = 'I'.
      ls_selopt-option    = 'EQ'.
      ls_selopt-low       = iv_langu.
      APPEND ls_selopt TO ls_shlp-selopt.
    ENDIF.
  ENDIF.

*国家分组
  IF is_zthr0015-zfkey NE 'MOLGA'.
    CLEAR ls_ddfields.
    READ TABLE ls_shlp-fielddescr INTO ls_ddfields WITH KEY domname = 'MOLGA'.
    IF sy-subrc EQ 0.
      CLEAR ls_selopt.
      ls_selopt-shlpname  = ls_ddfields-tabname.
      ls_selopt-shlpfield = ls_ddfields-fieldname.
      ls_selopt-sign      = 'I'.
      ls_selopt-option    = 'EQ'.
      ls_selopt-low       = iv_zvers .
      APPEND ls_selopt TO ls_shlp-selopt.
    ENDIF.
  ENDIF.

  LOOP AT it_shh_condition.
    CLEAR ls_ddfields.
    READ TABLE ls_shlp-fielddescr INTO ls_ddfields WITH KEY fieldname = it_shh_condition-field.
    IF sy-subrc EQ 0.
      CLEAR ls_selopt.
      ls_selopt-shlpname  = ls_ddfields-tabname.
      ls_selopt-shlpfield = ls_ddfields-fieldname.
      ls_selopt-sign      = 'I'.
      ls_selopt-option    = 'EQ'.
      ls_selopt-low       = it_shh_condition-value .
      APPEND ls_selopt TO ls_shlp-selopt.
    ENDIF.
  ENDLOOP.

  REFRESH lt_str.
  SPLIT is_zthr0015-zcond AT ';' INTO TABLE lt_str.
  LOOP AT lt_str.
    SPLIT lt_str AT '=' INTO lt_fields-fielda lt_fields-fieldb.
    APPEND lt_fields.
  ENDLOOP.

  REFRESH help_values.
  CALL FUNCTION 'DD_SHLP_GET_HELPVALUES'
    TABLES
      output_values               = help_values
    CHANGING
      shlp                        = ls_shlp
    EXCEPTIONS
      cursor_selection_impossible = 1
      OTHERS                      = 2.

  SORT ls_shlp-fielddescr BY position.

  IF es_head IS REQUESTED.
    CLEAR ls_fields.
    READ TABLE ls_shlp-fielddescr  INTO ls_fields WITH KEY fieldname = is_zthr0015-zfkey.
    es_head-key = ls_fields-scrtext_l.

    CLEAR ls_fields.
    READ TABLE ls_shlp-fielddescr  INTO ls_fields WITH KEY fieldname = is_zthr0015-zftxt.
    es_head-value = ls_fields-scrtext_l.
  ENDIF.



  REFRESH et_shh_data.
  LOOP AT help_values INTO help_value .

    LOOP AT ls_shlp-fielddescr  INTO ls_fields WHERE fieldname = is_zthr0015-zfkey OR  fieldname = is_zthr0015-zftxt .
      IF is_zthr0015-zznam = 'H_T517T' AND ls_fields-domname = 'SPRAS'.
        CONTINUE.
      ENDIF.
      lv_offset = ls_fields-offset / 2.

      lv_leng = ls_fields-leng.
      IF ls_fields-fieldname = is_zthr0015-zfkey.
        et_shh_data-key     = help_value-string+lv_offset(lv_leng).
      ELSE.
        et_shh_data-value   = help_value-string+lv_offset(lv_leng).
      ENDIF.
    ENDLOOP.

    COLLECT et_shh_data.
    CLEAR et_shh_data.

  ENDLOOP.

  LOOP AT  et_shh_data.
    lv_key = et_shh_data-key.
    lv_value = et_shh_data-value.
    IF is_zthr0015-zdkey = 'X'.
      CONCATENATE  lv_key space  lv_value INTO et_shh_data-value RESPECTING BLANKS.
    ELSE.
      et_shh_data-value = lv_value.
    ENDIF.
    MODIFY et_shh_data.

  ENDLOOP.




ENDFUNCTION.
