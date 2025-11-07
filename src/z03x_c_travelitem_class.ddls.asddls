extend view entity Z03_C_TRAVELITEM with
{
  @Consumption.valueHelpDefinition: [ 
    { entity: { name: '/LRN/437_I_ClassStdVH', element: 'ClassID' } } ]
  Item._Extension.zzClassZ03
}
