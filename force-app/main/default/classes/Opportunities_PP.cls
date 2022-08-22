public without sharing class Opportunities_PP extends fflib_SObjectDomain {
  public Opportunities_PP(List<Opportunity> opportunities) {
    super(opportunities, Schema.Opportunity.SObjectType);
    Configuration.disableTriggerCRUDSecurity();
  }

  public override void onAfterInsert() {
    notifyByDealRegistrationStatus();
    shareOppToDistributorAndReseller();
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    notifyByDealRegistrationStatus();
    shareOppToDistributorAndReseller();
  }

  public override void onBeforeInsert() {
    onSoldToPartnerSetSendLicenseBccToNotificationEmail();
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    onChangedSoldToPartnerSetSendLicenseBccToNotificationEmail();
  }

  public Set<Id> getSoldToPartnerIds() {
    Set<Id> result = new Set<Id>();
    for (Opportunity record : getOpportunities()) {
      result.add(record.Sold_to_Partner__c);
    }
    return result;
  }

  public List<Opportunity> getOpportunities() {
    return (List<Opportunity>) getRecords();
  }

  public Map<Id, Set<Id>> getOpportunityIdsByAccountId() {
    Map<Id, Set<Id>> records = new Map<Id, Set<Id>>();
    for (Opportunity record : getOpportunities()) {
      if (records.containsKey(record.AccountId)) {
        records.get(record.AccountId).add(record.Id);
      } else {
        records.put(record.AccountId, new Set<Id>{ record.Id });
      }
    }
    return records;
  }

  public Map<Id, Set<Id>> getOpportunityIdsBySoldToPartnerId() {
    Map<Id, Set<Id>> records = new Map<Id, Set<Id>>();
    for (Opportunity record : getOpportunities()) {
      if (records.containsKey(record.Sold_to_Partner__c)) {
        records.get(record.Sold_to_Partner__c).add(record.Id);
      } else {
        records.put(record.Sold_to_Partner__c, new Set<Id>{ record.Id });
      }
    }
    return records;
  }

  public Opportunities_PP selectWithSoldToPartner() {
    List<Opportunity> result = new List<Opportunity>();
    for (Opportunity record : getOpportunities()) {
      if (record.Sold_to_Partner__c == null)
        continue;

      result.add(record);
    }
    return new Opportunities_PP(result);
  }

  private void notifyByDealRegistrationStatus() {
    Set<Schema.SObjectField> fields = new Set<Schema.SObjectField>{ Opportunity.Deal_Reg_Status__c };

    List<Opportunity> opportunities = Trigger.isInsert
      ? (List<Opportunity>) getRecords()
      : (List<Opportunity>) getChangedRecords(fields);

    List<Opportunity> approvedRecords = new List<Opportunity>();

    for (Opportunity opportunity : opportunities) {
      // originally from workflow, this does not work on trigger because Converted_from_Deal_Reg__c is set to true
      // in a separate transaction via process builder Deal_Registration_Approved_change_record_type.
      // alternatively, Converted_from_Deal_Reg__c can be added to getChangedRecords parameter
      //if (opportunity.Converted_from_Deal_Reg__c == true)
      //{
      if (opportunity.Deal_Reg_Status__c == 'Approved') {
        approvedRecords.add(opportunity);
      }
      //}
    }

    if (!approvedRecords.isEmpty()) {
      OpportunitiesService_PP opportunitiesService = (OpportunitiesService_PP) Application_PP.Service.newInstance(
        OpportunitiesService_PP.class
      );

      opportunitiesService.notifyDealRegistrationApproval(approvedRecords);
    }
  }

  @TestVisible
  private void onChangedSoldToPartnerSetSendLicenseBccToNotificationEmail() {
    List<Opportunity> changedRecords = getChangedRecords(
      new Set<Schema.SObjectField>{ Opportunity.Sold_to_Partner__c }
    );

    if (changedRecords.isEmpty())
      return;

    new Opportunities_PP(changedRecords).onSoldToPartnerSetSendLicenseBccToNotificationEmail();
  }

  @TestVisible
  private void onSoldToPartnerSetSendLicenseBccToNotificationEmail() {
    Opportunities_PP opportunities = selectWithSoldToPartner();

    if (opportunities.getRecords().isEmpty())
      return;

    opportunities.setSendLicenseBccToNotificationEmail();
  }

  private void setSendLicenseBccToNotificationEmail() {
    GenericNotifications_PP notifications = GenericNotifications_PP.newInstance(
      GenericNotificationsSelector_PP.newInstance()
        .selectByAccountIdsAndTypes(getSoldToPartnerIds(), new Set<String>{ 'Licensing' }, false)
    );

    if (notifications.getRecords().isEmpty())
      return;

    setSendLicenseBccBySoldToPartnerId(notifications.getEmailByAccountId());
  }

  public Opportunities_PP setSendLicenseBccBySoldToPartnerId(Map<Id, String> emailByAccountId) {
    for (Opportunity record : getOpportunities()) {
      if (emailByAccountId.containsKey(record.Sold_To_Partner__c))
        record.Send_licenses_bcc__c = emailByAccountId.get(record.Sold_To_Partner__c);
    }
    return this;
  }

  private void shareOppToDistributorAndReseller() {
    Set<Schema.SObjectField> fields = new Set<Schema.SObjectField>{
      Opportunity.Sold_to_Partner__c,
      Opportunity.Tier_2_Partner__c,
      Opportunity.OwnerId
    };

    List<Opportunity> opportunities = Trigger.isInsert
      ? (List<Opportunity>) getRecords()
      : (List<Opportunity>) getChangedRecords(fields);

    List<Opportunity> recordsToShare = new List<Opportunity>();
    List<Opportunity> recordsToUnshare = new List<Opportunity>();

    for (Opportunity opportunity : opportunities) {
      if (String.isBlank(opportunity.Sold_to_Partner__c) && String.isBlank(opportunity.Tier_2_Partner__c))
        continue;

      recordsToShare.add(opportunity);

      if (Trigger.isUpdate && ExistingRecords.containsKey(opportunity.Id)) {
        recordsToUnshare.add((Opportunity) ExistingRecords.get(opportunity.Id));
      }
    }

    if (!recordsToShare.isEmpty()) {
      AbstractQueueable.enqueue(new ShareOpportunityToPartnersAction_PP(recordsToShare, recordsToUnshare));
    }
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new Opportunities_PP(sObjectList);
    }
  }
}