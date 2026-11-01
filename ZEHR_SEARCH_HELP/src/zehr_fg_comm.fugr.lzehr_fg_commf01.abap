*----------------------------------------------------------------------*
***INCLUDE LZEHR_FG_COMMF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form FRM_GET_DOMAIN_VALUES
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ET_SHH_DATA
*&      --> LS_ZTHR0015
*&      --> IV_LANGU
*&---------------------------------------------------------------------*
FORM frm_get_domain_values  TABLES   pt_shh_data STRUCTURE zshr_f4_tab
                            USING    ps_zthr0015 TYPE zthr0015
                                     pv_langu    TYPE sy-langu.

  DATA:lv_domname    TYPE dd07l-domname.

  lv_domname = ps_zthr0015-zznam.
  CALL FUNCTION 'ZFM_EHR_GET_SHLP_FR_DOMAIN'
    EXPORTING
      iv_domname  = lv_domname
      iv_langu    = pv_langu
    TABLES
      et_shh_data = pt_shh_data.

ENDFORM.



*&---------------------------------------------------------------------*
*& Form FRM_GET_SHH_FROM_TABLE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ET_SHH_DATA
*&      --> IT_SHH_CONDITION
*&      --> LS_ZTHR0015
*&      --> IV_LANGU
*&      --> IV_DATUM
*&      --> IV_ZVERS
*&---------------------------------------------------------------------*
FORM frm_get_shh_from_table  TABLES   et_shh_data     STRUCTURE zshr_f4_tab
                                      it_shh_condition STRUCTURE zshr_f4_condition
                             USING    is_zthr0015 TYPE zthr0015
                                      iv_langu TYPE sy-langu
                                      iv_datum TYPE datum
                                      iv_zvers TYPE zehrver.
  CLEAR:et_shh_data.

  CALL FUNCTION 'ZFM_EHR_GET_SHLP_FR_TABLE'
    EXPORTING
      iv_langu         = iv_langu
      iv_zvers         = iv_zvers
      is_zthr0015      = is_zthr0015
      iv_type          = 'X'
    TABLES
      it_shh_condition = it_shh_condition
      et_shh_data      = et_shh_data.

ENDFORM.
