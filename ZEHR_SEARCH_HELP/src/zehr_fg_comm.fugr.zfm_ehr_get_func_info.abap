FUNCTION ZFM_EHR_GET_FUNC_INFO.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     REFERENCE(IV_IFNUM) TYPE  ZE_EHR_IFNUM
*"     REFERENCE(IV_IFNAM) TYPE  FUNCNAME
*"     REFERENCE(IV_LANGU) TYPE  LANGU DEFAULT '1'
*"  EXPORTING
*"     REFERENCE(ES_MESSAGE) TYPE  ZSEHR_MESSAGE
*"  TABLES
*"      ET_PARAM_INFO STRUCTURE  ZSEHR_FUC_PARAMS
*"----------------------------------------------------------------------
  DATA:lt_params TYPE STANDARD TABLE OF rfc_funint,
       ls_params TYPE rfc_funint.
  DATA:ls_param_info  TYPE zsehr_fuc_params.
  DATA:lv_typename    TYPE dd40l-typename.
  DATA:lv_tabname     TYPE tabname.
  DATA:lt_fields TYPE icl_dfies_tab,
       ls_fields TYPE dfies.
  DATA:lt_dd40l TYPE STANDARD TABLE OF dd40l,
       ls_dd40l TYPE dd40l.


*获取函数参数
  REFRESH lt_params.
  CALL FUNCTION 'RFC_GET_FUNCTION_INTERFACE_US'
    EXPORTING
      funcname      = iv_ifnam
      language      = iv_langu
    TABLES
      params        = lt_params
    EXCEPTIONS
      fu_not_found  = 1
      nametab_fault = 2
      OTHERS        = 3.
  IF sy-subrc <> 0.
    es_message-msgty = 'E'.
    MESSAGE s001(zmsg_01) INTO es_message-msgtx WITH iv_ifnam .
    RETURN.
  ENDIF.

*获取函数参数
  REFRESH et_param_info.
  CLEAR   ls_param_info.
  CLEAR lt_dd40l.
  IF lt_params IS NOT INITIAL.
    SELECT * INTO TABLE lt_dd40l FROM dd40l
      FOR ALL ENTRIES IN lt_params
        WHERE typename =  lt_params-tabname.
  ENDIF.

  LOOP AT lt_params INTO ls_params.

    CLEAR ls_param_info.
    ls_param_info-ifnum      = iv_ifnum.
    ls_param_info-param      = ls_params-parameter.
    ls_param_info-pkind      = ls_params-paramclass.
    ls_param_info-optio      = ls_params-optional.
    ls_param_info-parat      = ls_params-paramtext.
    ls_param_info-intty      = ls_params-exid.
    ls_param_info-struc      = ls_params-tabname.
    ls_param_info-rfied      = ls_params-fieldname.

    IF ls_param_info-pkind = 'T'.
      ls_param_info-ztabl = 'X'.
    ELSE.
      CLEAR lv_typename.
      CLEAR ls_dd40l.
      READ TABLE lt_dd40l INTO ls_dd40l WITH KEY typename =  ls_params-tabname.
      IF sy-subrc EQ 0.
        ls_param_info-ztabl = 'X'.
      ENDIF.
    ENDIF.

*特殊类型处理
    IF ls_params-exid = 'u' OR ls_params-exid = 'h' OR ls_params-exid = 'v'.
      lv_tabname = ls_params-tabname.
      IF ls_params-exid = 'h'.
        CLEAR ls_dd40l.
        READ TABLE lt_dd40l INTO ls_dd40l WITH KEY typename =  ls_params-tabname.
        lv_tabname  = ls_dd40l-rowtype.
      ENDIF.

      REFRESH lt_fields.
      CALL FUNCTION 'ICL_GET_DDIC_INFO'
        EXPORTING
          iv_tabname            = lv_tabname
        IMPORTING
          et_dfies              = lt_fields
        EXCEPTIONS
          wrong_call            = 1
          erroneous_input_data  = 2
          ddic_data_read_failed = 3
          error_occurred        = 4
          OTHERS                = 5.
      LOOP AT lt_fields INTO ls_fields WHERE fieldname NE 'INCLUDE.'.
        ls_param_info-field      = ls_fields-fieldname.
        ls_param_info-parat      = ls_fields-fieldtext.
        ls_param_info-lengt      = ls_fields-leng.
        ls_param_info-posit      = ls_fields-position.
        ls_param_info-intty      = ls_fields-inttype.
        ls_param_info-decim      = ls_fields-decimals.
        APPEND ls_param_info TO et_param_info.
      ENDLOOP.
    ELSE.
      ls_param_info-field      = ''.
      ls_param_info-parat      = ls_params-paramtext.
      ls_param_info-lengt      = ls_params-intlength / 2.
      ls_param_info-intty      = ls_params-exid.
      ls_param_info-decim      = ls_params-decimals.
      APPEND ls_param_info TO et_param_info.
    ENDIF.
  ENDLOOP.




ENDFUNCTION.
