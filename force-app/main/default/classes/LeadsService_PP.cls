public without sharing class LeadsService_PP {
  public static final String CONVERT_PARTNER_USER_LEAD_STATUS = 'Partner Contact';

  public Database.LeadConvertResult convertPartnerUserLead(Lead partnerLead, User partnerUser, Account partnerAccount) {
    Id leadBusinessPartnerRecordTypeId = Schema.SObjectType.Lead
      .getRecordTypeInfosByDeveloperName()
      .get('Business_Partner_Onboarding')
      .getRecordTypeId();

    partnerLead.RecordTypeId = leadBusinessPartnerRecordTypeId;
    partnerLead.Status = 'New';
    partnerLead.Overwrite_Account_Match__c = true;
    partnerLead.Account__c = partnerAccount.Id;
    partnerLead.Email = partnerUser.Email;
    partnerLead.FirstName = partnerUser.Firstname;
    partnerLead.MiddleName = '';
    partnerLead.LastName = partnerUser.Lastname;
    partnerLead.Department__c = 'Other';
    partnerLead.Department1__c = 'Other';

    fflib_ISObjectUnitOfWork unitOfWork = Application_PP.UnitOfWork.newInstance();
    unitOfWork.registerDirty(partnerLead);
    unitOfWork.commitWork();

    Database.LeadConvert leadConvert = new Database.LeadConvert();
    leadConvert.setLeadId(partnerLead.Id);
    leadConvert.setConvertedStatus(LeadsService_PP.CONVERT_PARTNER_USER_LEAD_STATUS);
    leadConvert.setDoNotCreateOpportunity(true);
    leadConvert.setAccountId(partnerAccount.Id);
    leadConvert.setOwnerId(partnerAccount.OwnerId);
    Database.LeadConvertResult leadConvertResult = Database.convertLead(leadConvert);

    return leadConvertResult;
  }

  @future
  public static void updatePAFOwner(Set<Id> leadIds) {
    if (leadIds.isEmpty())
      return;
    fflib_ISObjectUnitOfWork uow = Application_PP.UnitOfWork.newInstance();
    PartnerApplicationFormsSelector_PP pafSelector = (PartnerApplicationFormsSelector_PP) Application_PP.Selector.newInstance(
      Partner_Application_Form__c.SObjectType
    );
    LeadsSelector_PP leadsSelector = (LeadsSelector_PP) Application_PP.Selector.newInstance(Lead.SObjectType);
    Map<Id, Lead> leadsById = new Map<Id, Lead>((List<Lead>) leadsSelector.selectSObjectsById(leadIds));

    if (leadsById.isEmpty())
      return;

    List<Partner_Application_Form__c> pafsToUpdate = new List<Partner_Application_Form__c>();
    for (Partner_Application_Form__c paf : pafSelector.selectByLeadId(leadIds)) {
      if (paf.Lead__c == null)
        continue;
      if (leadsById.get(paf.Lead__c) == null)
        continue;
      if (leadsById.get(paf.Lead__c).OwnerId.getSobjectType() != Schema.User.SObjectType)
        continue;

      paf.OwnerId = leadsById.get(paf.Lead__c).OwnerId;
      pafsToUpdate.add(paf);
    }

    if (pafsToUpdate.isEmpty())
      return;

    uow.registerDirty(pafsToUpdate);
    uow.commitWork();
  }

  public static void updateRelatedLeadToAvoidAutoReassign(Set<Id> leadIds) {
    fflib_ISObjectUnitOfWork uow = Application_PP.UnitOfWork.newInstance();
    LeadsSelector_PP leadsSelector = (LeadsSelector_PP) Application_PP.Selector.newInstance(Lead.SObjectType);
    Leads_PP leadsDomain = (Leads_PP) Application_PP.Domain.newInstance(
      (List<Lead>) leadsSelector.selectSObjectsById(leadIds),
      Lead.SObjectType
    );

    uow.registerDirty(leadsDomain.disableAutoReassignOwner().getRecords());
    uow.commitWork();
  }
}