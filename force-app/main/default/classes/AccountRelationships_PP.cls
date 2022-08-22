public without sharing class AccountRelationships_PP extends fflib_SObjectDomain {
  public AccountRelationships_PP(List<AccountRelationship> sObjects) {
    super(sObjects);
    Configuration.disableTriggerCRUDSecurity();
  }

  public override void onAfterInsert() {
    shareToPartners();
    setRelationshipOnAccount();
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    shareToPartners();
  }

  private void setRelationshipOnAccount() {
    AccountsService_PP service = (AccountsService_PP) Application_PP.Service.newInstance(AccountsService_PP.class);
    service.setRelationshipOnAccount((List<AccountRelationship>) getRecords());
  }

  private void shareToPartners() {
    Set<Schema.SObjectField> fields = new Set<Schema.SObjectField>{
      AccountRelationship.AccountFromId,
      AccountRelationship.AccountToId
    };

    List<AccountRelationship> relationships = Trigger.isInsert
      ? (List<AccountRelationship>) getRecords()
      : (List<AccountRelationship>) getChangedRecords(fields);

    List<AccountRelationship> recordsToShare = new List<AccountRelationship>();

    for (AccountRelationship relationship : relationships) {
      if (relationship.AccountFromId == relationship.AccountToId)
        continue;

      recordsToShare.add(relationship);
    }

    System.debug('@@@ AccountRelationships_PP shareToPartners' + recordsToShare);

    if (!recordsToShare.isEmpty()) {
      AccountsService_PP service = (AccountsService_PP) Application_PP.Service.newInstance(AccountsService_PP.class);

      service.shareToPartners(recordsToShare);
    }
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjects) {
      return new AccountRelationships_PP(sObjects);
    }
  }
}