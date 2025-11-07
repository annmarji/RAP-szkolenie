CLASS lsc_z03_r_travel DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

  PRIVATE SECTION.
    METHODS map_message
      IMPORTING i_msg        TYPE symsg
      RETURNING VALUE(r_msg) TYPE REF TO if_abap_behv_message.

ENDCLASS.

CLASS lsc_z03_r_travel IMPLEMENTATION.

  METHOD save_modified.

    DATA(model) = NEW /lrn/cl_s4d437_tritem( i_table_name = 'Z03_TRITEM' ).

    LOOP AT delete-travelitem ASSIGNING FIELD-SYMBOL(<deleteitem>).
      DATA(msg_d) = model->delete_item( i_uuid = <deleteitem>-ItemUuid ).
      IF msg_d IS NOT INITIAL.
        APPEND VALUE #( %tky-itemuuid = <deleteitem>-ItemUuid
                        %msg = map_message( msg_d ) ) TO reported-travelitem.
      ENDIF.
    ENDLOOP.

    LOOP AT update-travelitem ASSIGNING FIELD-SYMBOL(<updateitem>).
      DATA(msg_u) = model->update_item( i_item = CORRESPONDING #( <updateitem> MAPPING FROM ENTITY )
                                        i_itemx = CORRESPONDING #( <updateitem> MAPPING
                                                   FROM ENTITY USING CONTROL ) ).
      IF msg_u IS NOT INITIAL.
        APPEND VALUE #( %tky-itemuuid = <updateitem>-ItemUuid
                        %msg = map_message( msg_u ) ) TO reported-travelitem.
      ENDIF.
    ENDLOOP.

    LOOP AT create-travelitem ASSIGNING FIELD-SYMBOL(<createitem>).
      DATA(msg_c) = model->create_item( i_item = CORRESPONDING #( <createitem> MAPPING FROM ENTITY ) ).
      IF msg_c IS NOT INITIAL.
        APPEND VALUE #( %tky-itemuuid = <createitem>-ItemUuid
                        %msg = map_message( msg_c ) ) TO reported-travelitem.
      ENDIF.
    ENDLOOP.

    IF create-travel IS NOT INITIAL.
      RAISE ENTITY EVENT z03_r_travel~TravelCreated
       FROM VALUE #( FOR line IN create-travel
                         ( AgencyId = line-AgencyId
                           TravelId = line-TravelId
                           origin = 'Z03_R_TRAVEL_PARAM' ) ).
    ENDIF.

  ENDMETHOD.

  METHOD map_message.
    DATA(severity) = SWITCH #( i_msg-msgty
                            WHEN 'S' THEN if_abap_behv_message=>severity-success
                            WHEN 'I' THEN if_abap_behv_message=>severity-information
                            WHEN 'W' THEN if_abap_behv_message=>severity-warning
                            WHEN 'E' THEN if_abap_behv_message=>severity-error
                            ELSE if_abap_behv_message=>severity-none ).

    r_msg = new_message( id = i_msg-msgid
                         number = i_msg-msgno
                         severity = severity
                         v1 = i_msg-msgv1
                         v2 = i_msg-msgv2
                         v3 = i_msg-msgv3
                         v4 = i_msg-msgv4 ).
  ENDMETHOD.

ENDCLASS.


CLASS lhc_travelitem DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS validateFlightDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR TravelItem~validateFlightDate.
    METHODS determineTravelDates FOR DETERMINE ON SAVE
      IMPORTING keys FOR TravelItem~determineTravelDates.

ENDCLASS.

CLASS lhc_travelitem IMPLEMENTATION.

  METHOD validateFlightDate.
    CONSTANTS c_area TYPE string VALUE `FLIGHTDATE`.

    READ ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY TravelItem
    FIELDS ( AgencyId TravelId FlightDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(TravelItems).

    LOOP AT TravelItems ASSIGNING FIELD-SYMBOL(<travelitem>).
      APPEND VALUE #( %tky = <travelitem>-%tky
                      %state_area = c_area ) TO reported-travelitem.
      IF <travelitem>-FlightDate IS INITIAL.
        APPEND VALUE #( %tky = <travelitem>-%tky ) TO failed-travelitem.
        APPEND VALUE #( %tky = <travelitem>-%tky
                        %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
                        %state_area = c_area
                        %path-travel = CORRESPONDING #( <travelitem> )
                        %element-FlightDate = if_abap_behv=>mk-on ) TO reported-travelitem.
      ELSEIF <travelitem>-flightdate < cl_abap_context_info=>get_system_date( ).
        APPEND VALUE #( %tky = <travelitem>-%tky ) TO failed-travelitem.
        APPEND VALUE #( %tky = <travelitem>-%tky
                        %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>flight_date_past )
                        %state_area = c_area
                        %path-travel = CORRESPONDING #( <travelitem> )
                        %element-FlightDate = if_abap_behv=>mk-on ) TO reported-travelitem.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD determineTravelDates.

    READ ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY travelItem
    FIELDS ( AgencyId TravelId FlightDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(TravelItems)

    BY \_Travel
    FIELDS ( BeginDate EndDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(Travels)
    LINK DATA(links).

    LOOP AT TravelItems ASSIGNING FIELD-SYMBOL(<item>).
      ASSIGN travels[ KEY id %tky = links[ KEY id source-%tky = <item>-%tky ]-target-%tky ]
      TO FIELD-SYMBOL(<travel>).

      IF <item>-flightdate > <travel>-EndDate.
        <travel>-EndDate = <item>-flightdate.
      ENDIF.

      IF <item>-flightdate >= cl_abap_context_info=>get_system_date( )
      AND <item>-flightdate < <travel>-BeginDate.
        <travel>-BeginDate = <item>-flightdate.
      ENDIF.

    ENDLOOP.

    MODIFY ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( BeginDate EndDate )
    WITH CORRESPONDING #( travels ).

  ENDMETHOD.

ENDCLASS.



CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.
    METHODS cancel_travel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~cancel_travel.
    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateCustomer.

    METHODS validateDescsription FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateDescsription.
    METHODS validateBeginDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateBeginDate.
    METHODS validateDateSequence FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateDateSequence.

    METHODS validateEndDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateEndDate.
    METHODS determineStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~determineStatus.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.
    METHODS determineduration FOR DETERMINE ON SAVE
      IMPORTING keys FOR travel~determineduration.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE Travel.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_authorizations.

    result = CORRESPONDING #( keys ).

    LOOP AT result ASSIGNING FIELD-SYMBOL(<result>).
      DATA(rc) = /lrn/cl_s4d437_model=>authority_check( i_agencyid = <result>-agencyid i_actvt = '02' ).
      IF rc <> 0.
        <result>-%action-cancel_travel = if_abap_behv=>auth-unauthorized.
        <result>-%update = if_abap_behv=>auth-unauthorized.
      ELSE.
        <result>-%action-cancel_travel = if_abap_behv=>auth-allowed.
        <result>-%update = if_abap_behv=>auth-allowed.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_global_authorizations.

  ENDMETHOD.


  METHOD cancel_travel.

    READ ENTITIES OF z03_R_TRAVEL IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).
      IF travel-status <> 'C'.
        MODIFY ENTITIES OF z03_r_travel IN LOCAL MODE
        ENTITY travel
        UPDATE FIELDS ( status )
        WITH VALUE #( ( %tky = travel-%tky status = 'C' ) ).

      ELSE.
        APPEND VALUE #( %tky = travel-%tky  ) TO failed-travel.
        APPEND VALUE #( %tky = travel-%tky
                        %msg = NEW zcm_03_travel( textid = zcm_03_travel=>already_canceled ) ) TO reported-travel.

      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateCustomer.
    CONSTANTS c_area TYPE string VALUE `CUSTOMER`.
    READ ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY travel
    FIELDS ( CustomerId )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travel).

    LOOP AT travel ASSIGNING FIELD-SYMBOL(<travel>).
      APPEND VALUE #( %tky = <travel>-%tky
                      %state_area = c_area ) TO reported-travel.
      IF <travel>-CustomerId IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
                        %state_area = c_area
                        %element-CustomerId = if_abap_behv=>mk-on ) TO reported-travel.
      ELSE.
        SELECT SINGLE FROM /DMO/I_Customer
        FIELDS CustomerID
        WHERE CustomerID = @<travel>-CustomerId
        INTO @DATA(dummy).
        IF sy-subrc <> 0.
          APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.
          APPEND VALUE #( %tky = <travel>-%tky
                          %msg = NEW /lrn/cm_s4d437( textid = /lrn/cm_s4d437=>customer_not_exist
                                                     customerid = <travel>-CustomerId )
                          "NEW zcm_03_travel( textid = /lrn/cm_s4d437=>customer_not_exist
                          "                          severity = if_abap_behv_message=>severity-error )
                          %state_area = c_area
                          %element-CustomerId = if_abap_behv=>mk-on ) TO reported-travel.
        ENDIF.
      ENDIF.
    ENDLOOP.


  ENDMETHOD.

  METHOD validateDescsription.
    CONSTANTS c_area TYPE string VALUE `DESC`.

    READ ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY travel
    FIELDS ( description )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travel).

    LOOP AT travel ASSIGNING FIELD-SYMBOL(<travel>).
      APPEND VALUE #( %tky = <travel>-%tky
                      %state_area = c_area ) TO reported-travel.

      IF <travel>-Description IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
                        %state_area = c_area
                        %element-Description = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateBeginDate.
    CONSTANTS c_area TYPE string VALUE `BEGINDATE`.

    READ ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY travel
    FIELDS ( BeginDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travel).

*get_instance_features( keys = corresponding #( keys ) requested_features =  ).

    LOOP AT travel ASSIGNING FIELD-SYMBOL(<travel>).
      APPEND VALUE #( %tky = <travel>-%tky
                      %state_area = c_area ) TO reported-travel.
      IF <travel>-BeginDate IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
                        %state_area = c_area
                        %element-BeginDate = if_abap_behv=>mk-on ) TO reported-travel.
      ELSEIF <travel>-begindate < cl_abap_context_info=>get_system_date( ).
        APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>begin_date_past )
                        %state_area = c_area
                        %element-BeginDate = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD validateDateSequence.
    CONSTANTS c_area TYPE string VALUE `SEQUENCE`.

    READ ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY travel
    FIELDS ( BeginDate EndDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travel).

    LOOP AT travel ASSIGNING FIELD-SYMBOL(<travel>).
      APPEND VALUE #( %tky = <travel>-%tky
                      %state_area = c_area ) TO reported-travel.
      IF <travel>-BeginDate > <travel>-EndDate.
        APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>dates_wrong_sequence )
                        %state_area = c_area
                        %element = VALUE #( BeginDate = if_abap_behv=>mk-on
                                            EndDate = if_abap_behv=>mk-on ) ) TO reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD validateEndDate.
    CONSTANTS c_area TYPE string VALUE `ENDDATE`.

    READ ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY travel
    FIELDS ( EndDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travel).

    LOOP AT travel ASSIGNING FIELD-SYMBOL(<travel>).
      APPEND VALUE #( %tky = <travel>-%tky
                      %state_area = c_area ) TO reported-travel.
      IF <travel>-EndDate IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
                        %state_area = c_area
                        %element-endDate = if_abap_behv=>mk-on ) TO reported-travel.
      ELSEIF <travel>-EndDate < cl_abap_context_info=>get_system_date( ).
        APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>end_date_past )
                        %state_area = c_area
                        %element-EndDate = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD earlynumbering_create.

    DATA(agencyid) = /lrn/cl_s4d437_model=>get_agency_by_user( ).

    mapped-travel = CORRESPONDING #( entities ).

    LOOP AT mapped-travel ASSIGNING FIELD-SYMBOL(<mapping>).
      <mapping>-AgencyId = agencyid.
      <mapping>-TravelId = /lrn/cl_s4d437_model=>get_next_travelid( ).
    ENDLOOP.

  ENDMETHOD.

  METHOD determineStatus.
    READ ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY travel
    FIELDS ( Status )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    DELETE travels WHERE status IS NOT INITIAL.
    IF travels IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY travel
    UPDATE FIELDS ( status )
    WITH VALUE #( FOR key IN travels ( %tky = key-%tky
                                       Status = 'N' ) )
    REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).


  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY travel
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      APPEND CORRESPONDING #( <travel> ) TO result ASSIGNING FIELD-SYMBOL(<result>).

      IF <travel>-%is_draft = if_abap_behv=>mk-on.
        READ ENTITIES OF z03_r_travel IN LOCAL MODE
        ENTITY travel
        ALL FIELDS
        WITH VALUE #( ( %key = <travel>-%key
                        %is_draft = if_abap_behv=>mk-off ) )
        RESULT DATA(travels_active).

        IF travels_active IS NOT INITIAL.
          <travel>-BeginDate = travels_active[ 1 ]-BeginDate.
          " <travel>-BeginDate = travels_active[ %key = <travel>-%key ]-BeginDate.
          <travel>-EndDate = travels_active[ 1 ]-EndDate.
        ELSE.
          CLEAR <travel>-BeginDate.
          CLEAR <travel>-EndDate.
        ENDIF.
      ENDIF.
      IF <travel>-Status = 'C' OR ( <travel>-EndDate IS NOT INITIAL AND <travel>-EndDate < cl_abap_context_info=>get_system_date(  ) ).
        <result>-%update = if_abap_behv=>fc-o-disabled.
        <result>-%action-cancel_travel = if_abap_behv=>fc-o-disabled.
      ELSE.
        <result>-%update = if_abap_behv=>fc-o-enabled.
        <result>-%action-cancel_travel = if_abap_behv=>fc-o-enabled.
      ENDIF.

      IF <travel>-BeginDate IS NOT INITIAL AND <travel>-BeginDate < cl_abap_context_info=>get_system_date(  ) .
        <result>-%field-CustomerId = if_abap_behv=>fc-f-read_only.
        <result>-%field-BeginDate = if_abap_behv=>fc-f-read_only.
      ELSE.
        <result>-%field-CustomerId = if_abap_behv=>fc-f-mandatory.
        <result>-%field-BeginDate = if_abap_behv=>fc-f-mandatory.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD determineDuration.

    READ ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY travel
    FIELDS ( BeginDate EndDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      <travel>-duration = <travel>-EndDate - <travel>-BeginDate.
    ENDLOOP.

    MODIFY ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY travel
    UPDATE FIELDS ( Duration )
    WITH CORRESPONDING #( travels ).

  ENDMETHOD.

ENDCLASS.
