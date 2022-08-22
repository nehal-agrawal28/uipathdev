/**
 * @AUTHOR: UIPath
 * @DATE: 07/09/2021
 * @DESCRIPTION: Trigger for UserTerritory2Association object
 */
trigger UserTerritory2AssociationTrigger on UserTerritory2Association(
  before insert,
  after insert,
  after update,
  after delete,
  before update,
  before delete
) {
  fflib_SObjectDomain.triggerHandler(UserTerritory2Associations_ET.class);

}