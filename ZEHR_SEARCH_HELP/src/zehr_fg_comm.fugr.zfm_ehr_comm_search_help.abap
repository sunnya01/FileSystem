FUNCTION zfm_ehr_comm_search_help .
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     REFERENCE(IV_SHHID) TYPE  ZEHRSHHID
*"     REFERENCE(IV_LANGU) TYPE  LANGU DEFAULT SY-LANGU
*"     REFERENCE(IV_USER) TYPE  PERNR_D OPTIONAL
*"     REFERENCE(IV_DATUM) TYPE  DATUM DEFAULT SY-DATUM
*"     REFERENCE(IV_ZVERS) TYPE  ZEHRVER DEFAULT '28'
*"  TABLES
*"      ET_SHH_DATA STRUCTURE  ZSHR_F4_TAB
*"      IT_SHH_CONDITION STRUCTURE  ZSHR_F4_CONDITION OPTIONAL
*"----------------------------------------------------------------------
  DATA:ls_zthr0015  TYPE zthr0015,
       ls_zthr0015t TYPE zthr0015t.

  DATA:lt_str       TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA:BEGIN OF lt_fields OCCURS 0,
         fielda TYPE string,
         fieldb TYPE string,
       END OF lt_fields.
  DATA:lt_shh_condition TYPE STANDARD TABLE OF  zshr_f4_condition,
       ls_shh_condition TYPE  zshr_f4_condition.


  DATA:lv_molga    TYPE molga.
  lv_molga = iv_zvers.

  IF iv_shhid = '00019'.
    IF 1 = 1 .
    ENDIF.
  ENDIF.
  CLEAR ls_zthr0015.
  SELECT SINGLE * INTO ls_zthr0015 FROM zthr0015
    WHERE shhid = iv_shhid.

  CLEAR ls_zthr0015t.
  SELECT SINGLE * INTO ls_zthr0015t FROM zthr0015t
    WHERE shhid = iv_shhid AND
          langu = sy-langu.

  REFRESH et_shh_data.

  CASE ls_zthr0015-zzhlp.
    WHEN 'D'."域
      PERFORM frm_get_domain_values TABLES et_shh_data USING ls_zthr0015 sy-langu .
    WHEN 'F'."函数

      REFRESH lt_str.
      SPLIT ls_zthr0015-zcond AT ';' INTO TABLE lt_str.
      CLEAR:lt_fields.
      LOOP AT lt_str.
        SPLIT lt_str AT '=' INTO lt_fields-fielda lt_fields-fieldb.
        APPEND lt_fields.
      ENDLOOP.

      REFRESH lt_shh_condition.
      LOOP AT lt_fields.
        CLEAR it_shh_condition.
        READ TABLE it_shh_condition WITH KEY field = lt_fields-fieldb.
        IF sy-subrc EQ 0.
          lt_fields-fieldb = it_shh_condition-value.

        ENDIF.
        ls_shh_condition-field = lt_fields-fielda.
        ls_shh_condition-value = lt_fields-fieldb.
        APPEND ls_shh_condition TO lt_shh_condition.

      ENDLOOP.

      CALL FUNCTION ls_zthr0015-zznam
        EXPORTING
          iv_datum         = iv_datum
          iv_langu         = sy-langu
          iv_molga         = lv_molga
        TABLES
          et_shh_data      = et_shh_data[]
          it_shh_condition = lt_shh_condition[].

    WHEN 'H'."搜索帮助
      CALL FUNCTION 'ZFM_EHR_GET_SHLP_FR_SHLP'
        EXPORTING
          iv_langu         = sy-langu
          iv_zvers         = iv_zvers
          is_zthr0015      = ls_zthr0015
        TABLES
          it_shh_condition = it_shh_condition
          et_shh_data      = et_shh_data.
    WHEN 'S'."信息类型子类型

      CALL FUNCTION 'ZFM_EHR_GET_SHLP_FR_SUBTY'
        EXPORTING
          iv_langu         = sy-langu
          iv_zvers         = iv_zvers
          is_zthr0015      = ls_zthr0015
          iv_user          = iv_user
        TABLES
          it_shh_condition = it_shh_condition
          et_shh_data      = et_shh_data.

    WHEN 'T'."数据表
      PERFORM frm_get_shh_from_table TABLES et_shh_data it_shh_condition USING ls_zthr0015 sy-langu iv_datum iv_zvers .
      IF iv_shhid = '00019'.
        DELETE  et_shh_data WHERE key = '1000'.
        DELETE  et_shh_data WHERE key = 'LV18'."KVSP009 删除LV18 公司假  20220707
      ENDIF.
    WHEN OTHERS.
  ENDCASE.

*  LOOP AT et_shh_data.
*    CONCATENATE et_shh_data-key et_shh_data-value INTO et_shh_data-value SEPARATED BY space RESPECTING BLANKS.
*    MODIFY et_shh_data.
*  ENDLOOP.

  IF iv_shhid = '00115'.
  ELSE.
    IF ls_zthr0015-zsort = 'X'.
      SORT et_shh_data BY key .
    ELSE.
      SORT et_shh_data BY value .
    ENDIF.
  ENDIF.

  IF iv_shhid = 'PM005'.
    DELETE et_shh_data[] WHERE key > '70'.
  ELSE.
    CLEAR et_shh_data.
    et_shh_data-key = ' '.
    INSERT et_shh_data INDEX 1.
  ENDIF.




ENDFUNCTION.
