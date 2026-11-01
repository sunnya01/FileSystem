PROCESS BEFORE OUTPUT.
  MODULE liste_initialisieren.
  LOOP AT extract WITH CONTROL
   tctrl_ztehr0001 CURSOR nextline.
    MODULE liste_show_liste.
  ENDLOOP.
*
PROCESS AFTER INPUT.
  MODULE liste_exit_command AT EXIT-COMMAND.
  MODULE liste_before_loop.
  LOOP AT extract.
    MODULE liste_init_workarea.
    CHAIN.
      FIELD ztehr0001-ifnum .
      FIELD ztehr0001-ifnam .
      FIELD ztehr0001-ifdec .
      FIELD ztehr0001-uname .
      FIELD ztehr0001-aedtm .
      FIELD ztehr0001-ifmrk .
      FIELD ztehr0001-iflog .
      MODULE set_update_flag ON CHAIN-REQUEST.
    ENDCHAIN.
    FIELD vim_marked MODULE liste_mark_checkbox.
    CHAIN.
      FIELD ztehr0001-ifnum .
      MODULE liste_update_liste.
    ENDCHAIN.
  ENDLOOP.
  MODULE liste_after_loop.

PROCESS ON VALUE-REQUEST.
  FIELD ztehr0001-ifnam MODULE help_request_1010.
