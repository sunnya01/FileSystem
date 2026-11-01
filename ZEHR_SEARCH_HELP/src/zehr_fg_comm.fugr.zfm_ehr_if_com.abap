FUNCTION zfm_ehr_if_com.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     VALUE(IV_IFNUM) TYPE  ZE_EHR_IFNUM
*"     VALUE(IV_INPUT) TYPE  STRING
*"  EXPORTING
*"     VALUE(ES_MESSAGE) TYPE  ZSEHR_MESSAGE
*"     VALUE(EV_OUTPUT) TYPE  STRING
*"----------------------------------------------------------------------
  FIELD-SYMBOLS: <lfs_json>      TYPE any,
                 <lfs_abap>      TYPE any,
                 <lfs_json_t>    TYPE table,
                 <lfs_abap_t>    TYPE table,
                 <lfs_abap_line> TYPE any,
                 <lfs_param>     TYPE any,
                 <lfs_value>     TYPE any.
  DATA:
    lt_param_info TYPE STANDARD TABLE OF zsehr_fuc_params,
    ls_param_info TYPE zsehr_fuc_params,
    lt_param      TYPE STANDARD TABLE OF zsehr_fuc_params,
    ls_param      TYPE zsehr_fuc_params,
    lt_input      TYPE zthr_param,
    lt_output     TYPE zthr_param,
    ls_input      TYPE zshr_param,
    ls_output     TYPE zshr_param,
    lt_param_log  TYPE STANDARD TABLE OF zshr_params,
    ls_param_log  TYPE zshr_params,
    ls_ztehr0003  TYPE ztehr0003,

    lt_ptab       TYPE abap_func_parmbind_tab,
    ls_ptab       TYPE abap_func_parmbind,
    lt_etab       TYPE abap_func_excpbind_tab,
    ls_etab       TYPE abap_func_excpbind,

    lv_func       TYPE rs38l_fnam,
    lv_str        TYPE string,
    lv_typename   TYPE dd40l-typename,
    lv_is_tabl    TYPE flag,
    ls_message    TYPE zsehr_message,
    ls_ztehr0001  TYPE ztehr0001,
    lv_line_type  TYPE REF TO cl_abap_structdescr,
    lv_table_type TYPE REF TO cl_abap_tabledescr,
    ls_struct     TYPE REF TO data,
    ls_table      TYPE REF TO data.
  DATA:lv_index TYPE i.
  DATA:lv_breakpoint TYPE c.
  DATA:lv_key   TYPE string.
  DATA:lt_iflog TYPE STANDARD TABLE OF ztehr_iflog,
       ls_iflog TYPE ztehr_iflog,
       lv_logid TYPE char20,
       lv_user  TYPE zehruser.

  IF iv_ifnum = 'REP00'.
    IF 1 = 1.
    ENDIF.
  ENDIF.


*通过接口编号获取接口的名称
  CLEAR ls_ztehr0001.
  SELECT SINGLE * INTO ls_ztehr0001 FROM ztehr0001
     WHERE ifnum = iv_ifnum.
  lv_func = ls_ztehr0001-ifnam.
  IF lv_func IS INITIAL.
    es_message-msgty = 'E'.
    MESSAGE e002(zmsg_01) INTO es_message-msgtx.
    RETURN.
  ENDIF.

  CLEAR lt_param_log.
  CLEAR lt_iflog.
*保存输入参数接口日志
  IF ls_ztehr0001-iflog = 'X'.
    LOOP AT lt_input INTO ls_input.
      MOVE-CORRESPONDING ls_input TO ls_param_log.
      ls_param_log-pkind = 'I'.
      APPEND ls_param_log TO lt_param_log.
    ENDLOOP.

  ENDIF.

*获取接口的参数
  CALL FUNCTION 'ZFM_EHR_GET_FUNC_INFO'
    EXPORTING
      iv_ifnum      = iv_ifnum
      iv_ifnam      = ls_ztehr0001-ifnam
    IMPORTING
      es_message    = ls_message
    TABLES
      et_param_info = lt_param_info.
  IF ls_message-msgty = 'E'.
    RETURN.
  ENDIF.

  CLEAR lt_param.
  LOOP AT lt_param_info INTO ls_param_info.
    ls_param-pkind = ls_param_info-pkind.
    ls_param-param = ls_param_info-param.
    ls_param-ztabl = ls_param_info-ztabl.
    ls_param-optio = ls_param_info-optio.
    ls_param-struc = ls_param_info-struc.
    ls_param-rfied = ls_param_info-rfied.
    COLLECT ls_param INTO lt_param.
    CLEAR ls_param.
  ENDLOOP.

  CLEAR lt_input.
  CALL FUNCTION 'ZFM_EHR_JSON_TO_ABAP'
    EXPORTING
      iv_json = iv_input
    IMPORTING
      ev_data = lt_input.
*******设置断点条件******
  DATA:lv_pernr TYPE pernr_d.
  READ TABLE lt_input INTO ls_input WITH KEY pname = 'IV_USER'.
  IF sy-subrc = 0.
    lv_user = ls_input-value.
    SELECT SINGLE *
      FROM zhrbc_t0005
      INTO @DATA(ls_0005)
      WHERE ifnum = @iv_ifnum.
    IF sy-subrc = 0.
      IF ls_0005-zuser = lv_user.
        DATA(lv_flag) = 'X'.
      ENDIF.
    ENDIF.
  ENDIF.
*******设置断点**********
  REFRESH: lt_ptab,lt_etab.

  LOOP AT lt_param INTO ls_param WHERE pkind  NE 'X'.

    CLEAR lv_str.
    IF ls_param-rfied IS NOT INITIAL.
      lv_str = ls_param-struc && '-' && ls_param-rfied.
    ELSE.
      lv_str = ls_param-struc.
    ENDIF.

    CLEAR   lv_index.
    LOOP AT lt_param_info INTO ls_param_info
                                WHERE param = ls_param-param.
      lv_index = lv_index + 1.
    ENDLOOP.

*读取参数的值,如果为输入参数且没有值就不作为函数的入参
    CLEAR ls_input.
    READ TABLE lt_input INTO ls_input WITH KEY pname = ls_param-param.
    IF sy-subrc NE 0 AND ls_param-pkind = 'I' AND ls_param-optio = 'X'.
      CONTINUE.
    ENDIF.

*判断登录人员是否合法
    IF ls_param-param = 'IV_USER' AND iv_ifnum = '00012'.
      IF ls_input-value IS NOT INITIAL.
        IF NOT ( ls_input-value GT '0' AND ls_input-value < '99999999' ).
          ls_message-msgty = 'E'.
          ls_message-msgtx = '登录人员编号不正确！'.
          RETURN.
        ENDIF.
      ENDIF.
    ENDIF.

    IF ls_param-param = 'IV_USER'.
      lv_user = ls_input-value.
    ENDIF.


*判断参考的是否为表类型
    CLEAR:lv_is_tabl, lv_typename.
    SELECT SINGLE typename INTO lv_typename FROM dd40l
        WHERE typename = lv_str.
    IF sy-subrc EQ 0.
      lv_is_tabl = 'X'.
    ENDIF.

    IF ls_param-pkind = 'T' OR ls_param-ztabl = 'X'."*表参数
      IF lv_is_tabl = 'X'.
        CREATE DATA  ls_table TYPE (lv_str).
      ELSE.
        CREATE DATA  ls_table TYPE STANDARD TABLE OF (lv_str).
      ENDIF.
      ASSIGN ls_table->*  TO <lfs_abap_t>.
      CLEAR <lfs_abap_t>.
      IF lv_str NE 'ZSHR_PARAM' AND lv_str NE 'ZTHR_PARAM'.
        CALL FUNCTION 'ZFM_EHR_JSON_TO_ABAP'
          EXPORTING
            iv_json = ls_input-value
          IMPORTING
            ev_data = <lfs_abap_t>.
      ELSE.
        CREATE DATA ls_struct LIKE LINE OF <lfs_abap_t>.
        ASSIGN  ls_struct->*  TO <lfs_abap>.
        ASSIGN COMPONENT 'VALUE' OF STRUCTURE <lfs_abap> TO <lfs_value>.
        <lfs_value> = ls_input-value.
        ASSIGN COMPONENT 'PNAME' OF STRUCTURE <lfs_abap> TO <lfs_value>.
        <lfs_value> = ls_input-pname.
        IF <lfs_abap> IS NOT INITIAL.
          APPEND <lfs_abap> TO <lfs_abap_t>.
        ENDIF.
      ENDIF.
    ELSE."非表类型参数
      CREATE DATA ls_struct TYPE (lv_str).
      ASSIGN ls_struct->* TO <lfs_abap>.
      IF lv_index > 1.
        IF lv_str NE 'ZSHR_PARAM'.
          CALL FUNCTION 'ZFM_EHR_JSON_TO_ABAP'
            EXPORTING
              iv_json = ls_input-value
            IMPORTING
              ev_data = <lfs_abap>.
        ELSE.
          ASSIGN COMPONENT 'VALUE' OF STRUCTURE <lfs_abap> TO <lfs_value>.
          <lfs_value> = ls_input-value.
          ASSIGN COMPONENT 'PNAME' OF STRUCTURE <lfs_abap> TO <lfs_value>.
          <lfs_value> = ls_input-pname.
        ENDIF.
      ELSE.
        <lfs_abap> = ls_input-value.
      ENDIF.
    ENDIF.


    CASE ls_param-pkind.
      WHEN 'I'."输入参数
        ls_ptab-name = ls_param-param.
        ls_ptab-kind = abap_func_exporting.
        IF ls_param-ztabl = 'X'.
          GET REFERENCE OF  <lfs_abap_t> INTO ls_ptab-value.
        ELSE.
          GET REFERENCE OF <lfs_abap>    INTO ls_ptab-value.
        ENDIF.
        INSERT ls_ptab INTO TABLE lt_ptab.
      WHEN 'E'."输出参数
        ls_ptab-name = ls_param-param.
        ls_ptab-kind = abap_func_importing.

        IF ls_param-ztabl = 'X'.
          GET REFERENCE OF  <lfs_abap_t> INTO ls_ptab-value.
        ELSE.
          GET REFERENCE OF <lfs_abap>    INTO ls_ptab-value.
        ENDIF.

        INSERT ls_ptab INTO TABLE lt_ptab.
      WHEN 'C'.
        ls_ptab-name = ls_param-param.
        ls_ptab-kind = abap_func_changing.
        IF ls_param-ztabl = 'X'.
          GET REFERENCE OF  <lfs_abap_t> INTO ls_ptab-value.
        ELSE.
          GET REFERENCE OF <lfs_abap>    INTO ls_ptab-value.
        ENDIF.

        INSERT ls_ptab INTO TABLE lt_ptab.
      WHEN 'T'.
        ls_ptab-name = ls_param-param.
        ls_ptab-kind = abap_func_tables.
        GET REFERENCE OF  <lfs_abap_t> INTO ls_ptab-value.
        INSERT ls_ptab INTO TABLE lt_ptab.

      WHEN 'X'.
        ls_etab-name = ls_param-param.
        ls_etab-value = 10.
        INSERT ls_etab INTO TABLE lt_etab.
      WHEN OTHERS.
    ENDCASE.
  ENDLOOP.
*动态调用函数
  CALL FUNCTION lv_func PARAMETER-TABLE lt_ptab EXCEPTION-TABLE lt_etab.
*获取输出参数的值
  LOOP AT lt_ptab INTO ls_ptab WHERE kind = abap_func_importing OR
                                     kind = abap_func_tables OR
                                     kind = abap_func_changing.

    CLEAR ls_output.
    ls_output-pname = ls_ptab-name.
    IF ls_output-pname = 'ES_MESSAGE' OR ls_output-pname = 'ES_MSG'.
      ASSIGN ls_ptab-value->* TO <lfs_abap>.
      ASSIGN COMPONENT 'MSGTY' OF STRUCTURE <lfs_abap> TO <lfs_value>.
      es_message-msgty = <lfs_value>.
      ASSIGN COMPONENT 'MSGTX' OF STRUCTURE <lfs_abap> TO <lfs_value>.
      es_message-msgtx = <lfs_value>.
    ENDIF.

    CLEAR ls_param.
    READ TABLE lt_param INTO ls_param WITH KEY param = ls_output-pname.
    IF ls_param-struc = 'ZSHR_PARAM'."用于处理JSON中包涵JSON的特殊处理.
      ASSIGN ls_ptab-value->* TO <lfs_abap>.
      ASSIGN COMPONENT 'VALUE' OF STRUCTURE <lfs_abap> TO <lfs_value>.
      ls_output-value = <lfs_value>.
      ASSIGN COMPONENT 'PNAME' OF STRUCTURE <lfs_abap> TO <lfs_value>.
      ls_output-pname = <lfs_value>.
    ELSEIF ls_param-struc = 'ZTHR_PARAM'."用于处理JSON中包涵JSON的特殊处理.
      ASSIGN ls_ptab-value->* TO <lfs_abap_t>.
      LOOP AT <lfs_abap_t> ASSIGNING <lfs_abap_line>.

        ASSIGN COMPONENT 'VALUE' OF STRUCTURE
            <lfs_abap_line> TO <lfs_value>.
        ls_output-value = <lfs_value>.
        ASSIGN COMPONENT 'PNAME' OF STRUCTURE
            <lfs_abap_line> TO <lfs_value>.
        ls_output-pname = <lfs_value>.
        APPEND  ls_output TO lt_output.
      ENDLOOP.
      CONTINUE.

    ELSE.
      IF ls_param-pkind = 'T' OR ls_param-ztabl = 'X'.

        ASSIGN ls_ptab-value->* TO <lfs_abap_t>.
        CALL FUNCTION 'ZFM_EHR_ABAP_TO_JSON'
          EXPORTING
            iv_data = <lfs_abap_t>
          IMPORTING
            ev_json = ls_output-value.
      ELSE.

        ASSIGN ls_ptab-value->* TO <lfs_abap>.
        CALL FUNCTION 'ZFM_EHR_ABAP_TO_JSON'
          EXPORTING
            iv_data = <lfs_abap>
          IMPORTING
            ev_json = ls_output-value.
      ENDIF.
    ENDIF.

    IF ls_output-value IS NOT INITIAL.
      APPEND ls_output TO lt_output.
    ENDIF.
  ENDLOOP.

**保存输出参数接口日志
  IF ls_ztehr0001-iflog = 'X'.
    LOOP AT lt_output INTO ls_output.
      MOVE-CORRESPONDING ls_output TO ls_param_log.
      ls_param_log-pkind = 'O'.
      APPEND ls_param_log TO lt_param_log.
    ENDLOOP.

    ls_iflog-ifnum = iv_ifnum.
    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        nr_range_nr             = '01'
        object                  = 'ZEHR_IFLOG'
      IMPORTING
        number                  = lv_logid
      EXCEPTIONS
        interval_not_found      = 1
        number_range_not_intern = 2
        object_not_found        = 3
        quantity_is_0           = 4
        quantity_is_not_1       = 5
        interval_overflow       = 6
        buffer_overflow         = 7
        OTHERS                  = 8.
    ls_iflog-guid  = lv_logid.
    ls_iflog-zuser = lv_user.
    PERFORM convert_datum_to_timestamps USING sy-datum sy-uzeit CHANGING ls_iflog-tstmp.
    CALL FUNCTION 'ZFM_EHR_ABAP_TO_JSON'
      EXPORTING
        iv_data = lt_param_log
      IMPORTING
        ev_json = ls_iflog-param.
    ls_iflog-msgty = es_message-msgty.
    ls_iflog-msgtx = es_message-msgtx.
    MODIFY ztehr_iflog FROM ls_iflog.
    COMMIT WORK.
  ENDIF.

  CALL FUNCTION 'ZFM_EHR_ABAP_TO_JSON'
    EXPORTING
      iv_data = lt_output
    IMPORTING
      ev_json = ev_output.

ENDFUNCTION.
