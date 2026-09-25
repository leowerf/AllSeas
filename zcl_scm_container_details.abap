CLASS zcl_scm_container_details DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES:BEGIN OF ts_object,
            obknr TYPE objk-obknr,
          END OF ts_object,
          tt_objects TYPE STANDARD TABLE OF ts_object WITH NON-UNIQUE DEFAULT KEY.
    INTERFACES: if_sadl_exit_calc_element_read.
    METHODS get_pm_object_list IMPORTING iv_serialnumber   TYPE any
                               RETURNING VALUE(rt_objects) TYPE tt_objects.
    METHODS get_last_goods_movement IMPORTING it_objects        TYPE tt_objects
                                    RETURNING VALUE(rs_last_gm) TYPE mseg.
    METHODS get_movement_data IMPORTING is_goodsmovement   TYPE mseg
                              RETURNING VALUE(rs_mvt_data) TYPE mseg.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_scm_container_details IMPLEMENTATION.
  METHOD if_sadl_exit_calc_element_read~calculate.
    DATA: lt_data TYPE STANDARD TABLE OF zc_scm_container_details WITH NON-UNIQUE DEFAULT KEY.

    lt_data = CORRESPONDING #( it_original_data ).

    LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<fs_data>) WHERE stocktype = '06'. "In transit
      DATA(lt_objects)       = get_pm_object_list( <fs_data>-serialnumber ).
      DATA(ls_last_movement) = get_last_goods_movement( lt_objects ).
      DATA(ls_movement_data) = get_movement_data( ls_last_movement ).
      IF ls_movement_data IS NOT INITIAL.
        <fs_data>-STO_PurchaseOrder   = ls_movement_data-ebeln.
        <fs_data>-STO_StorageLocation = ls_movement_data-lgort.
      ENDIF.
      CLEAR: lt_objects, ls_last_movement, ls_movement_data.
    ENDLOOP.
*
    ct_calculated_data = CORRESPONDING #( lt_data ).
  ENDMETHOD.

  METHOD if_sadl_exit_calc_element_read~get_calculation_info.

  ENDMETHOD.

  METHOD get_pm_object_list.
    DATA(lc_taser) = CONV objk-taser( |SER03| ).

    SELECT obknr FROM objk
    WHERE sernr = @iv_serialnumber
    AND   taser = @lc_taser
    INTO CORRESPONDING FIELDS OF TABLE @rt_objects.
  ENDMETHOD.

  METHOD get_last_goods_movement.
    DATA(lc_movement_category) = CONV t156-kzbwa( |01| ).

    SELECT mblnr, mjahr, zeile
    FROM ser03
    JOIN t156
    ON ser03~bwart = t156~bwart
    FOR ALL ENTRIES IN @it_objects
    WHERE ser03~obknr = @it_objects-obknr
    AND t156~kzbwa    = @lc_movement_category  "Tranfers
    INTO TABLE @DATA(lt_data).

    SORT lt_data BY mblnr DESCENDING.

    rs_last_gm = CORRESPONDING #( lt_data[ 1 ] ).

  ENDMETHOD.

  METHOD get_movement_data.
    SELECT SINGLE mblnr, mjahr, zeile, ebeln, lgort
    FROM mseg
    WHERE mblnr = @is_goodsmovement-mblnr
    AND   mjahr = @is_goodsmovement-mjahr
    AND   zeile = @is_goodsmovement-zeile
    INTO CORRESPONDING FIELDS OF @rs_mvt_data.
  ENDMETHOD.
ENDCLASS.
