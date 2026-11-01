FUNCTION ZFM_EHR_ABAP_TO_JSON.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     REFERENCE(IV_DATA) TYPE  DATA
*"  EXPORTING
*"     REFERENCE(EV_JSON) TYPE  STRING
*"----------------------------------------------------------------------
*  CALL METHOD zcl_fdt_json=>data_to_json2
*    EXPORTING
*      iv_data = iv_data
*    RECEIVING
*      rv_json = ev_json.
ENDFUNCTION.
