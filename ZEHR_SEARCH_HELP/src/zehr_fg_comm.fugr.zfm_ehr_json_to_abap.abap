FUNCTION zfm_ehr_json_to_abap.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     REFERENCE(IV_JSON) TYPE  STRING
*"  EXPORTING
*"     REFERENCE(EV_DATA) TYPE  DATA
*"----------------------------------------------------------------------
*  CALL METHOD zcl_fdt_json=>json_to_data
*    EXPORTING
*      iv_json = iv_json
*    CHANGING
*      ca_data = ev_data.
  /ui2/cl_json=>deserialize( EXPORTING json = iv_json CHANGING data = ev_data ).
ENDFUNCTION.
