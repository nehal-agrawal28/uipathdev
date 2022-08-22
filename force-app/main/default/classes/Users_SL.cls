public with sharing class Users_SL extends fflib_SObjectDomain implements IUsers_SL {
  public Users_SL(List<User> records) {
    super(records, User.SObjectType);
    Configuration.disableTriggerCRUDSecurity();
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    UserAdvancedApprovalQueueable_SL.populateApprovers(Records, existingRecords);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new Users_SL(sObjectList);
    }
  }
}