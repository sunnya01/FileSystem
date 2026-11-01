*----------------------------------------------------------------------*
***INCLUDE LZVHR0015I01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  LISTE_AFTER_DEL  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE liste_after_del INPUT.
  " 调用 SM30
  IF sy-ucomm = '&DEL'.
    CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
      EXPORTING
        action                     = 'S' "U=修改, S=显示
        view_name                  = 'ZTHR0015D'
        no_warning_for_clientindep = 'X' "跳过跨客户端警告
      EXCEPTIONS
        view_not_found             = 1
        OTHERS                     = 2.
    IF sy-subrc <> 0.
      MESSAGE '调用失败' TYPE 'E'.
    ENDIF.
  ENDIF.
ENDMODULE.
