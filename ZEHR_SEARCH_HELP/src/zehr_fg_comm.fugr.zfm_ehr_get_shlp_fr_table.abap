FUNCTION zfm_ehr_get_shlp_fr_table.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     REFERENCE(IV_LANGU) TYPE  LANGU DEFAULT SY-LANGU
*"     REFERENCE(IV_ZVERS) TYPE  MOLGA DEFAULT '28'
*"     REFERENCE(IS_ZTHR0015) TYPE  ZTHR0015
*"     REFERENCE(IV_TYPE) TYPE  FLAG DEFAULT ''
*"     REFERENCE(IV_LIKE) TYPE  ZEHRVALUE OPTIONAL
*"  EXPORTING
*"     REFERENCE(ES_HEAD) TYPE  ZSHR_SHH_HEAD
*"  TABLES
*"      IT_SHH_CONDITION STRUCTURE  ZSHR_F4_CONDITION OPTIONAL
*"      ET_SHH_DATA STRUCTURE  ZSHR_F4_TAB
*"----------------------------------------------------------------------
  TYPES:ty_conds TYPE string.
  TYPES:BEGIN OF ty_field,
          field TYPE string,
          value TYPE string,
        END OF ty_field.

  FIELD-SYMBOLS:<fs_itab>  TYPE ANY TABLE,
                <fs_line>  TYPE any,
                <fs_value> TYPE any.

  DATA:lv_field TYPE string,
       lv_value TYPE string.
  DATA:lv_tabname TYPE string,
       lv_key     TYPE string,
       lv_text    TYPE string,
       lv_fielda  TYPE string.


  DATA:lt_conds TYPE STANDARD TABLE OF ty_conds,
       ls_conds TYPE ty_conds.
  DATA:lt_field TYPE STANDARD TABLE OF ty_field,
       ls_field TYPE ty_field.
  DATA:lv_jointab TYPE string.
  DATA:lv_fieldname TYPE string.
  DATA:lv_tablename TYPE string.
  DATA lr_struc  TYPE REF TO cl_abap_structdescr.
  DATA lr_table  TYPE REF TO cl_abap_tabledescr.
  DATA lr_type   TYPE REF TO cl_abap_typedescr.
  DATA lr_data   TYPE REF TO cl_abap_datadescr.
  DATA lt_comp   TYPE  abap_component_tab.
  DATA ls_comp   LIKE LINE OF  lt_comp.
  DATA dyn_wa    TYPE REF TO data.
  DATA dyn_table TYPE REF TO data.
  DATA lv_disfield TYPE c LENGTH 60.

  DATA:lv_content TYPE string,
       lv_where   TYPE string,
       lv_from    TYPE string.
  DATA:lv_field1 TYPE string,
       lv_field2 TYPE string.
  DATA:lv_dtabname   TYPE ddobjname,
       lv_dfieldname TYPE dfies-fieldname.
  DATA:lt_dfies_tab TYPE STANDARD TABLE OF dfies,
       ls_dfies_tab TYPE dfies,
       lv_like      TYPE string,
       lv_str       TYPE string.

*将条件按 '|'分拆
  IF is_zthr0015-zcond IS NOT INITIAL.
    SPLIT is_zthr0015-zcond AT '|' INTO lv_field lv_value."LV_VALUE JOIN条件
  ENDIF.

  CLEAR lt_conds.
  SPLIT lv_field AT ';' INTO TABLE lt_conds.

  CLEAR lt_field.
  LOOP AT lt_conds INTO ls_conds.
    SPLIT ls_conds AT '=' INTO ls_field-field ls_field-value.
    COLLECT ls_field INTO lt_field.
  ENDLOOP.

*表
*如果存在PA0001~PERNR形式则需要按~拆开
  SPLIT is_zthr0015-zfkey AT '~' INTO lv_jointab lv_key.
  IF lv_key IS INITIAL.
    lv_fieldname = is_zthr0015-zfkey.
    lv_tablename = is_zthr0015-zznam.
    CONDENSE:lv_fieldname NO-GAPS,lv_tablename NO-GAPS.
    IF lv_fieldname IS NOT INITIAL.
      lv_key     = lv_tablename && '~' && lv_fieldname."表~字段
    ENDIF.
  ELSE.
    lv_tablename = lv_jointab.
    lv_fieldname = lv_key."IS_ZTHR0015-ZFKEY.
    CONDENSE:lv_fieldname NO-GAPS.
    lv_key     = is_zthr0015-zfkey."表~字段
  ENDIF.
  lv_fielda  = lv_key.

  CLEAR lt_comp.
*创建字段类型
  lv_disfield = lv_tablename && '-' && lv_fieldname.
  CALL METHOD cl_abap_datadescr=>describe_by_name
    EXPORTING
      p_name         = lv_disfield
    RECEIVING
      p_descr_ref    = lr_type
    EXCEPTIONS
      type_not_found = 1
      OTHERS         = 2.

  ls_comp-name  = lv_fieldname.
  ls_comp-type ?= lr_type.
  lv_field1 = lv_fieldname.
  APPEND ls_comp TO lt_comp.

*  IF ES_HEAD IS REQUESTED.
*获取字段描述
  lv_dtabname = lv_fieldname.
  lv_dfieldname = lv_tablename.
  CLEAR lt_dfies_tab.
  CALL FUNCTION 'DDIF_FIELDINFO_GET'
    EXPORTING
      tabname        = lv_dtabname
      fieldname      = lv_dfieldname
      langu          = iv_langu
    TABLES
      dfies_tab      = lt_dfies_tab
    EXCEPTIONS
      not_found      = 1
      internal_error = 2
      OTHERS         = 3.
  IF sy-subrc <> 0.
    CLEAR ls_dfies_tab.
    READ TABLE lt_dfies_tab INTO ls_dfies_tab WITH KEY  tabname = lv_dtabname fieldname = lv_dfieldname.
    es_head-key = ls_dfies_tab-scrtext_m.
  ENDIF.




  CLEAR: lv_jointab, lv_key.
  SPLIT is_zthr0015-zftxt AT '~' INTO lv_jointab lv_key.
  IF lv_key IS INITIAL.
    lv_fieldname = is_zthr0015-zftxt.
    lv_tablename = is_zthr0015-zznam.
    CONDENSE:lv_fieldname NO-GAPS,lv_tablename NO-GAPS.
    IF lv_fieldname IS NOT INITIAL.
      lv_text     = lv_tablename && '~' && lv_fieldname."表~字段
    ENDIF.
    lv_disfield = lv_tablename && '-' && lv_fieldname.
  ELSE.
    lv_tablename = lv_jointab.
    lv_fieldname = lv_key.
    lv_disfield = lv_tablename && '-' && lv_key."LV_FIELDNAME.
    CONDENSE:lv_fieldname NO-GAPS.
    lv_text     = is_zthr0015-zftxt."LV_FIELDNAME."表~字段
  ENDIF.

*获取字段描述
  lv_dtabname = lv_fieldname.
  lv_dfieldname = lv_tablename.
  CLEAR lt_dfies_tab.
  CALL FUNCTION 'DDIF_FIELDINFO_GET'
    EXPORTING
      tabname        = lv_dtabname
      fieldname      = lv_dfieldname
      langu          = iv_langu
    TABLES
      dfies_tab      = lt_dfies_tab
    EXCEPTIONS
      not_found      = 1
      internal_error = 2
      OTHERS         = 3.
  IF sy-subrc <> 0.
    CLEAR ls_dfies_tab.
    READ TABLE lt_dfies_tab INTO ls_dfies_tab WITH KEY  tabname = lv_dtabname fieldname = lv_dfieldname.
    es_head-value = ls_dfies_tab-scrtext_m.
  ENDIF.
*  ENDIF.


*  LV_DISFIELD = LV_TABLENAME && '-' && LV_FIELDNAME.
  CALL METHOD cl_abap_datadescr=>describe_by_name
    EXPORTING
      p_name         = lv_disfield
    RECEIVING
      p_descr_ref    = lr_type
    EXCEPTIONS
      type_not_found = 1
      OTHERS         = 2.

  ls_comp-name  = lv_fieldname.
  ls_comp-type ?= lr_type.
  lv_field2 = lv_fieldname.
  IF ls_comp-name IS NOT INITIAL.
    APPEND ls_comp TO lt_comp.
  ENDIF.


  IF  lt_comp[] IS NOT INITIAL.
*根据字段目录创建动态结构类型
    CALL METHOD cl_abap_structdescr=>create
      EXPORTING
        p_components = lt_comp
      RECEIVING
        p_result     = lr_struc.

*根据动态结构创建动态内表类型
    CALL METHOD cl_abap_tabledescr=>create
      EXPORTING
        p_line_type = lr_struc
      RECEIVING
        p_result    = lr_table.

*参照动态结构类型和动态内表类型创建内表与工作区
    CREATE DATA dyn_wa    TYPE HANDLE lr_struc.
    CREATE DATA dyn_table TYPE HANDLE lr_table.

*指定内表与工作区到字段符号
    ASSIGN dyn_wa->*    TO <fs_line>.
    ASSIGN dyn_table->* TO <fs_itab>.

  ENDIF.

  CLEAR lv_content."SQL字段内容
  CLEAR:lv_key,lv_text.
  lv_key = is_zthr0015-zfkey.
  lv_text = is_zthr0015-zftxt.
  CONCATENATE lv_key  space lv_text  INTO lv_content  RESPECTING BLANKS.
  IF lv_content IS INITIAL.
    RETURN.
  ENDIF.

  IF iv_like IS NOT INITIAL.
    CLEAR lv_like.
    CONDENSE:lv_text NO-GAPS.
    CONCATENATE lv_text space 'LIKE' space '''%' iv_like '%''' INTO lv_like RESPECTING BLANKS.
  ENDIF.


  CLEAR lv_from."SQL From子句
  DATA:lv_zzname TYPE string.
  lv_zzname = is_zthr0015-zznam.

  CONCATENATE lv_zzname space lv_value INTO lv_from     RESPECTING BLANKS.
  IF lv_from IS INITIAL.
    RETURN.
  ENDIF.

*Where条件的处理
  CLEAR lv_where.
  SEARCH is_zthr0015-zcond FOR 'LIKE' IN CHARACTER MODE.
  IF sy-subrc = 0.
    lv_where = is_zthr0015-zcond.
  ELSE.
    LOOP AT lt_field INTO ls_field.

      CLEAR it_shh_condition.
      IF iv_type = ''.
        READ TABLE it_shh_condition WITH KEY field = ls_field-field. """"
      ELSE.
        READ TABLE it_shh_condition WITH KEY field = ls_field-value. """"
      ENDIF.

      IF sy-subrc EQ 0.
        ls_field-value = it_shh_condition-value.
      ENDIF.
*国家分组
      IF ls_field-value = '&MOLGA'.
        ls_field-value = iv_zvers.
      ENDIF.
*语言
      IF ls_field-value = '&LANGU'.
        ls_field-value = iv_langu.
      ENDIF.

      IF lv_where IS INITIAL.
        IF ls_field-value IS NOT INITIAL.
          CONCATENATE ls_field-field  ' =  '''    ls_field-value  '''' INTO lv_where RESPECTING BLANKS.
*        ELSE.
*          CONCATENATE ls_field-field  '' INTO lv_where RESPECTING BLANKS.
        ENDIF.
      ELSE.
        IF ls_field-value IS NOT INITIAL.
          CONCATENATE lv_where  ' AND '  ls_field-field  ' =  '''    ls_field-value  '''' INTO lv_where RESPECTING BLANKS.
*        ELSE.
*          CONCATENATE lv_where  ' AND '  ls_field-field INTO lv_where RESPECTING BLANKS.
        ENDIF.
      ENDIF.

    ENDLOOP.

  ENDIF.

  IF lv_where IS INITIAL AND lv_like IS NOT INITIAL.
    lv_where = lv_like.
  ELSEIF  lv_where IS NOT INITIAL AND lv_like IS NOT INITIAL.

    CONCATENATE lv_where  ' AND ' lv_like INTO lv_where RESPECTING BLANKS.
  ENDIF.


  REFRESH  <fs_itab>.
  IF lv_where IS NOT INITIAL.
    SELECT (lv_content)  FROM (lv_from) INTO TABLE <fs_itab>
      WHERE (lv_where).
  ELSE.
    SELECT (lv_content)  FROM (lv_from) INTO TABLE <fs_itab>.
  ENDIF.



  REFRESH et_shh_data.
  LOOP AT <fs_itab> INTO <fs_line>.
    ASSIGN COMPONENT lv_field1 OF STRUCTURE <fs_line> TO <fs_value>.
    IF sy-subrc EQ 0.
      et_shh_data-key = <fs_value>.
      ASSIGN COMPONENT lv_field2 OF STRUCTURE <fs_line> TO <fs_value>.
      IF sy-subrc EQ 0.
        et_shh_data-value = <fs_value>.
        lv_key = et_shh_data-key.
        lv_value = et_shh_data-value.
        IF is_zthr0015-zdkey = 'X'.
          CONCATENATE lv_key space lv_value INTO et_shh_data-value RESPECTING BLANKS.
        ELSE.
          et_shh_data-value = lv_value.
        ENDIF.
      ELSE.
        et_shh_data-value = et_shh_data-key.
      ENDIF.
      IF et_shh_data-value IS INITIAL.
        et_shh_data-value = et_shh_data-key.
      ENDIF.
      COLLECT et_shh_data.
    ENDIF.
    CLEAR et_shh_data.
  ENDLOOP.

*  IF is_zthr0015-zznam = 'T510G'.
*    DELETE  et_shh_data WHERE key = 'Z1' OR key = 'Z9'.
*  ENDIF.

ENDFUNCTION.
