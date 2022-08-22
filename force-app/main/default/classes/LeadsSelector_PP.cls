public without sharing class LeadsSelector_PP extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Lead.Account__c,
      Lead.Company,
      Lead.Country,
      Lead.Disable_Owner_Change__c,
      Lead.Email,
      Lead.FirstName,
      Lead.Full_Name__c,
      Lead.Id,
      Lead.LastName,
      Lead.MiddleName,
      Lead.Overwrite_Account_Match__c,
      Lead.OwnerId,
      Lead.RecordTypeId,
      Lead.Status
    };
  }

  public static LeadsSelector_PP newInstance() {
    return (LeadsSelector_PP) Application_PP.Selector.newInstance(Schema.Lead.SObjectType);
  }

  public Schema.SObjectType getSObjectType() {
    return Lead.sObjectType;
  }

  public List<Lead> selectById(Set<Id> ids, Boolean withSharing) {
    if (withSharing)
      return (List<Lead>) selectSObjectsById(ids);
    else
      return (List<Lead>) Database.query(newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL());
  }

  public List<Lead> selectByEmail(Set<String> emails, Boolean withSharing) {
    if (withSharing)
      return (List<Lead>) Database.query(newQueryFactory(true, true, true).setCondition('Email IN :emails').toSOQL());
    else
      return (List<Lead>) Database.query(newQueryFactory(false, false, true).setCondition('Email IN :emails').toSOQL());
  }

  public List<Lead> selectByEmailNotConverted(Set<String> emails, Boolean withSharing) {
    if (withSharing)
      return (List<Lead>) Database.query(
        newQueryFactory(true, true, true)
          .setCondition('Email IN :emails AND Status NOT IN (\'Partner Contact\', \'Qualified\')')
          .toSOQL()
      );
    else
      return (List<Lead>) Database.query(
        newQueryFactory(false, false, true)
          .setCondition('Email IN :emails AND Status NOT IN (\'Partner Contact\', \'Qualified\')')
          .toSOQL()
      );
  }
}