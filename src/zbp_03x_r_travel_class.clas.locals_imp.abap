CLASS lhc_travelitem DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS ZZvalidateClass FOR VALIDATE ON SAVE
      IMPORTING keys FOR TravelItem~ZZvalidateClass.

ENDCLASS.

CLASS lhc_travelitem IMPLEMENTATION.

  METHOD ZZvalidateClass.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_Z03_R_TRAVEL DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_Z03_R_TRAVEL IMPLEMENTATION.

  METHOD save_modified.
    LOOP AT update-travelitem ASSIGNING FIELD-SYMBOL(<item>) WHERE %control-ZZClassZ03 = if_abap_behv=>mk-on.
      UPDATE z03_tritem
      SET zzclassz03 = @<item>-ZZClassZ03
      WHERE item_uuid = @<item>-ItemUuid.
    ENDLOOP.

    LOOP AT create-travelitem ASSIGNING <item> WHERE %control-ZZClassZ03 = if_abap_behv=>mk-on.
      UPDATE z03_tritem
      SET zzclassz03 = @<item>-ZZClassZ03
      WHERE item_uuid = @<item>-ItemUuid.
    ENDLOOP.

  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
