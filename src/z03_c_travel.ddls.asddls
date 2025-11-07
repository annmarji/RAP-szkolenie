@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Flight Travel'
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
@Metadata.allowExtensions: true
define root view entity Z03_C_Travel
  provider contract transactional_query
  as projection on Z03_R_TRAVEL
{
  key AgencyId,
  key TravelId,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      Description,
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Customer_StdVH',
                                                     element: 'CustomerID' },
                                           additionalBinding: [{ localElement: 'Description',
                                                                 element: 'FirstName' ,
                                                                 usage: #RESULT }] }]
      CustomerId,
      BeginDate,
      EndDate,
      @EndUserText.label: 'Duration (days)'
      Duration,
      Status,
      ChangedAt,
      ChangedBy,
      LocChangedAt,

      _TravelItem : redirected to composition child Z03_C_TRAVELITEM
}
