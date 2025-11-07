CLASS zcm_03_travel DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_abap_behv_message .
    INTERFACES if_t100_message .
    INTERFACES if_t100_dyn_msg .

    CONSTANTS: BEGIN OF already_canceled,
                 msgid TYPE symsgid VALUE '/LRN/S4D437',
                 msgno TYPE symsgno VALUE '130',
                 attr1 TYPE scx_attrname VALUE '',
                 attr2 TYPE scx_attrname VALUE '',
                 attr3 TYPE scx_attrname VALUE '',
                 attr4 TYPE scx_attrname VALUE '',
               END OF already_canceled.

    METHODS constructor
      IMPORTING
        !textid  LIKE if_t100_message=>t100key OPTIONAL
        "!previous LIKE previous OPTIONAL .
        severity LIKE if_abap_behv_message~m_severity OPTIONAL.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcm_03_travel IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor(
    "previous = previous
    ).
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.

    IF severity IS INITIAL.
      if_abap_behv_message~m_severity = if_abap_behv_message~severity-error.
    ELSE.
      if_abap_behv_message~m_severity = severity.
    ENDIF.

  ENDMETHOD.


ENDCLASS.
