FUNCTION ZFM_EHR_GET_SHLP_FR_SUBTY.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     REFERENCE(IV_LANGU) TYPE  LANGU DEFAULT SY-LANGU
*"     REFERENCE(IV_ZVERS) TYPE  MOLGA DEFAULT '28'
*"     REFERENCE(IS_ZTHR0015) TYPE  ZTHR0015
*"     REFERENCE(IV_USER) TYPE  ZEHRUSER OPTIONAL
*"  EXPORTING
*"     REFERENCE(ES_HEAD) TYPE  ZSHR_SHH_HEAD
*"  TABLES
*"      IT_SHH_CONDITION STRUCTURE  ZSHR_F4_CONDITION OPTIONAL
*"      ET_SHH_DATA STRUCTURE  ZSHR_F4_TAB
*"----------------------------------------------------------------------
DATA:lv_infty TYPE infty,
       lv_pernr TYPE pernr_d,
       lv_molga TYPE molga,
       lv_flag  TYPE flag.
  DATA:lt_dfies TYPE icl_dfies_tab,
       ls_dfies TYPE dfies.
  DATA:lt_value_tab TYPE  hrvalue_tab,
       ls_value_tab LIKE LINE OF lt_value_tab,
       lt_field_tab TYPE  hrhelp_fields,
       ls_field_tab LIKE LINE OF lt_field_tab.
  DATA:lv_tabix     TYPE sy-tabix.
  DATA:lv_retfield  TYPE  dfies-fieldname.
  DATA:lv_tabid     TYPE sy-tabix.
  lv_infty = is_zthr0015-zznam.
  lv_pernr = iv_user.
  lv_molga = iv_zvers.

  CLEAR:lt_value_tab,lt_field_tab.

*获取人员的国家版本
  CALL FUNCTION 'HR_COUNTRYGROUPING_GET'
    EXPORTING
      pernr     = lv_pernr
      tclas     = 'A'
      begda     = sy-datum
      endda     = sy-datum
    IMPORTING
      molga     = lv_molga
    EXCEPTIONS
      not_found = 1
      OTHERS    = 2.

  IF lv_infty = '0185'.
    CLEAR lv_pernr.
  ENDIF.


  CALL FUNCTION 'HR_F4_GET_TABLES'
    EXPORTING
      infty                = lv_infty
      persnr               = lv_pernr
      tclas                = 'A'
      begda                = sy-datum
      endda                = sy-datum
      langu                = iv_langu
      molga                = lv_molga
    IMPORTING
      value_tab            = lt_value_tab
      field_tab            = lt_field_tab
      retfield             = lv_retfield
    EXCEPTIONS
      infty_not_found      = 1
      no_entries_found     = 2
      infty_not_supported  = 3
      infty_has_no_subties = 4
      OTHERS               = 5.


  CLEAR et_shh_data.
  LOOP AT lt_value_tab INTO ls_value_tab.

    CASE lv_infty .
      WHEN '2001'.
        lv_tabid = lv_tabid + 1.
        IF lv_tabid = 2.
          et_shh_data-key = ls_value_tab.
        ELSEIF lv_tabid = 3.
          et_shh_data-value  = ls_value_tab.
          COLLECT et_shh_data.
          CLEAR et_shh_data.
          lv_tabid = 0.
        ENDIF.
      WHEN '2006'.
        lv_tabid = lv_tabid + 1.
        IF lv_tabid = 3.
          et_shh_data-key = ls_value_tab.
        ELSEIF lv_tabid = 4.
          et_shh_data-value  = ls_value_tab.
          COLLECT et_shh_data.
          CLEAR et_shh_data.
          lv_tabid = 0.
        ENDIF.
      WHEN OTHERS.
        IF lv_retfield = 'LGART'.
          lv_tabid = lv_tabid + 1.
          IF lv_tabid = 5.
            lv_tabid = 1.
          ENDIF.

          IF lv_tabid = 1.
            et_shh_data-key = ls_value_tab.
          ELSEIF lv_tabid = 2.
            et_shh_data-value  = ls_value_tab.
            COLLECT et_shh_data.
            CLEAR et_shh_data.
          ENDIF.

        ELSE.
          IF lv_flag IS INITIAL.
            et_shh_data-key = ls_value_tab.
            lv_flag   = 'X'.
          ELSE.
            et_shh_data-value  = ls_value_tab.
            lv_flag      = space.
            COLLECT et_shh_data.
            CLEAR et_shh_data.
          ENDIF.
        ENDIF.
    ENDCASE.




  ENDLOOP.
  DATA:lv_key   TYPE string,
       lv_value TYPE string.

  LOOP AT et_shh_data .
    lv_key = et_shh_data-key.
    lv_value = et_shh_data-value.
    IF is_zthr0015-zdkey = 'X'.
      CONCATENATE lv_key space lv_value INTO et_shh_data-value  RESPECTING BLANKS.
    ELSE.
      et_shh_data-value = lv_value.
    ENDIF.
    MODIFY et_shh_data.
  ENDLOOP.

  IF es_head IS REQUESTED.
    CLEAR lv_tabix.
    LOOP AT lt_field_tab INTO ls_field_tab.
      lv_tabix = sy-tabix.
*获取字段描述
      CLEAR lt_dfies.
      CALL FUNCTION 'DDIF_FIELDINFO_GET'
        EXPORTING
          tabname        = ls_field_tab-tabname
          fieldname      = ls_field_tab-fieldname
          langu          = iv_langu
        TABLES
          dfies_tab      = lt_dfies
        EXCEPTIONS
          not_found      = 1
          internal_error = 2
          OTHERS         = 3.

      CLEAR ls_dfies.
      READ TABLE lt_dfies INTO ls_dfies WITH KEY fieldname = ls_field_tab-fieldname.
      IF lv_tabix = '1'.
        es_head-key =  ls_dfies-scrtext_m.
      ELSE.
        es_head-value =  ls_dfies-scrtext_m.

      ENDIF.
    ENDLOOP.
  ENDIF.




ENDFUNCTION.
