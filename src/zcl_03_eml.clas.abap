CLASS zcl_03_eml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .

    CONSTANTS c_agency_id TYPE /dmo/agency_id VALUE '070000'.
    CONSTANTS c_travel_id TYPE /dmo/travel_id VALUE '00004233'.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_03_eml IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    READ ENTITIES OF z03_r_travel
    ENTITY Travel
    ALL FIELDS WITH VALUE #( ( AgencyId = c_agency_id TravelId = c_travel_id ) )
    RESULT DATA(travels)
    FAILED DATA(failed).

    IF failed IS NOT INITIAL.
      out->Write( 'Error during reading Travel' ).
    ELSE.
      MODIFY ENTITIES OF z03_r_travel
      ENTITY travel
      UPDATE FIELDS ( description )
      WITH VALUE #( ( AgencyId = c_agency_id TravelId = c_travel_id Description = '2My new description' ) )
      FAILED failed.

      IF failed IS INITIAL.
        COMMIT ENTITIES.
        out->write( 'Description successfully updated' ).
      ELSE.
        ROLLBACK ENTITIES.
        out->write( 'Error during updating the description' ).
      ENDIF.

    ENDIF.
  ENDMETHOD.
ENDCLASS.
