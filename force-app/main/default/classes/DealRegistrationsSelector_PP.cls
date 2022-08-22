public with sharing class DealRegistrationsSelector_PP extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      DealRegistration__c.Account__c,
      DealRegistration__c.BPOOpportunity__c,
      DealRegistration__c.BusinessType__c,
      DealRegistration__c.CampaignId__c,
      DealRegistration__c.City__c,
      DealRegistration__c.CloseDate__c,
      DealRegistration__c.Competition__c,
      DealRegistration__c.Country__c,
      DealRegistration__c.CreatedById,
      DealRegistration__c.CurrencyIsoCode,
      DealRegistration__c.DealRegNotesComments__c,
      DealRegistration__c.DealRegistrationAmount__c,
      DealRegistration__c.DealType__c,
      DealRegistration__c.Distributor__c,
      DealRegistration__c.EndCustomerAccountName__c,
      DealRegistration__c.EndCustomerWebsite__c,
      DealRegistration__c.Id,
      DealRegistration__c.Name,
      DealRegistration__c.Opportunity__c,
      DealRegistration__c.OwnerId,
      DealRegistration__c.PartnerCompanySalesEmail__c,
      DealRegistration__c.PartnerCompanySalesPhone__c,
      DealRegistration__c.PartnerCompanySalesRep__c,
      DealRegistration__c.PartnerLeadSource__c,
      DealRegistration__c.PriceBook__c,
      DealRegistration__c.RecordTypeId,
      DealRegistration__c.Tier2Partner__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return DealRegistration__c.sObjectType;
  }

  public List<DealRegistration__c> selectById(Set<Id> ids, Boolean withSharing) {
    if (withSharing)
      return (List<DealRegistration__c>) selectSObjectsById(ids);
    else
      return (List<DealRegistration__c>) Database.query(
        newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL()
      );
  }

  public List<DealRegistration__c> selectByIdWithPriceBookName(Set<Id> ids, Boolean withSharing) {
    if (withSharing)
      return (List<DealRegistration__c>) Database.query(
        newQueryFactory(true, true, true).selectField('PriceBook__r.Name').setCondition('Id IN :ids').toSOQL()
      );
    else
      return (List<DealRegistration__c>) Database.query(
        newQueryFactory(false, false, true).selectField('PriceBook__r.Name').setCondition('Id IN :ids').toSOQL()
      );
  }

  public List<DealRegistration__c> selectByIdAndRTId(Set<Id> ids, Set<Id> RTIds, Boolean withSharing) {
    if (withSharing)
      return (List<DealRegistration__c>) Database.query(
        newQueryFactory(true, true, true).setCondition('Id IN :ids AND RecordTypeId IN :RTIds').toSOQL()
      );
    else
      return (List<DealRegistration__c>) Database.query(
        newQueryFactory(false, false, true).setCondition('Id IN :ids AND RecordTypeId IN :RTIds').toSOQL()
      );
  }

  public Database.QueryLocator queryLocatorWithoutOpportunityByRecordTypeIds(Set<Id> recordTypeIds) {
    return Database.getQueryLocator(
      newQueryFactory().setCondition('Opportunity__c = NULL AND RecordTypeId IN :recordTypeIds').toSOQL()
    );
  }

  public Database.QueryLocator queryLocatorWithPartnersByCreatedDate(Date createdDate) {
    return Database.getQueryLocator(
      newQueryFactory()
        .setCondition('(Distributor__c <> NULL OR Tier2Partner__c <> NULL) AND CreatedDate >= :createdDate')
        .toSOQL()
    );
  }

  public Database.QueryLocator queryLocatorDraftsOlderThan7Days() {
    return Database.getQueryLocator(
      newQueryFactory().setCondition('Status__c = \'Draft\' and CreatedDate < LAST_N_DAYS:7').toSOQL()
    );
  }
}