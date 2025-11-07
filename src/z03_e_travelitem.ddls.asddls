@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Extension Include for travel items'
@Metadata.ignorePropagatedAnnotations: true
@AbapCatalog.extensibility:{
    extensible: true,
    allowNewDatasources: false, 
    dataSources: ['Item'],
    elementSuffix: 'Z03'
}
define view entity Z03_E_TravelItem
  as select from z03_tritem as Item
{
  key item_uuid   as ItemUuid
}
