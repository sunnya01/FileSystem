FUNCTION zfm_ehr_get_shlp_fr_domain.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     REFERENCE(IV_DOMNAME) TYPE  DOMNAME
*"     REFERENCE(IV_LANGU) TYPE  LANGU
*"     REFERENCE(IV_ZDKEY) TYPE  ZEHRZDKEY OPTIONAL
*"  EXPORTING
*"     REFERENCE(ES_HEAD) TYPE  ZSHR_SHH_HEAD
*"  TABLES
*"      ET_SHH_DATA STRUCTURE  ZSHR_F4_TAB
*"----------------------------------------------------------------------
  DATA:lt_values_tab TYPE STANDARD TABLE OF dd07v,
       ls_values_tab TYPE dd07v.
  DATA:ls_dd01t      TYPE dd01t.


  REFRESH lt_values_tab.
*  sy-langu = iv_langu.

  CALL FUNCTION 'GET_DOMAIN_VALUES'
    EXPORTING
      domname         = iv_domname
      text            = 'X'
    TABLES
      values_tab      = lt_values_tab
    EXCEPTIONS
      no_values_found = 1
      OTHERS          = 2.

  REFRESH et_shh_data.
  DATA:lv_key   TYPE string,
       lv_value TYPE string.
  LOOP AT lt_values_tab INTO ls_values_tab.
    CLEAR et_shh_data.
    lv_key = ls_values_tab-domvalue_l.
    lv_value = ls_values_tab-ddtext.

    et_shh_data-key   = ls_values_tab-domvalue_l.
    et_shh_data-value = ls_values_tab-ddtext.
    IF iv_zdkey = 'X'.
      CONCATENATE lv_key space lv_value INTO et_shh_data-value RESPECTING BLANKS.
    ENDIF.
    APPEND et_shh_data.
  ENDLOOP.

  if iv_domname = 'ZD_JXDJ'.
  else.
  SORT et_shh_data BY value.
  endif.
ENDFUNCTION.
