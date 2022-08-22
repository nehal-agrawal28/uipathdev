public without sharing class PartnerApplicationForms_PP extends fflib_SObjectDomain {
  public PartnerApplicationForms_PP(List<Partner_Application_Form__c> records) {
    super(records, Partner_Application_Form__c.SObjectType);

    Configuration.disableTriggerCRUDSecurity();
  }

  public static PartnerApplicationForms_PP newInstance(Set<Id> ids) {
    return (PartnerApplicationForms_PP) Application_PP.Domain.newInstance(ids);
  }

  public static PartnerApplicationForms_PP newInstance(List<Partner_Application_Form__c> records) {
    return (PartnerApplicationForms_PP) Application_PP.Domain.newInstance(
      records,
      Schema.Partner_Application_Form__c.SObjectType
    );
  }

  public override void onAfterInsert() {
    shareWithDistributors();
    updateRelatedLeadToAvoidAutoReassign();
    PAFIntegrationService.publishInsertsToRDC(records);
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    onChangeApplicationStatus();
    PAFIntegrationService.publishUpdatesToRDC(Records, existingRecords);
  }

  public override void onBeforeInsert() {
    recalculateCorruptionPerceptionLevel();
    assignFormToCountriesDefaultManager();
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    onChangeApplicationStatusUpdateDate();
    onChangeUIPathStatusUpdateDate();
    recalculateCorruptionPerceptionLevel();
  }

  private void assignFormToCountriesDefaultManager() {
    Map<String, Id> managerIdByCountry = DefaultApplicationManagers_PP.newInstance(
        DefaultApplicationManagersSelector_PP.newWithoutSharingInstance().selectAll()
      )
      .getManagerIdByCountry();

    setOwnerIdByCountry(managerIdByCountry);
  }

  private void updateRelatedLeadToAvoidAutoReassign() {
    LeadsService_PP.updateRelatedLeadToAvoidAutoReassign(getLeadIds());
  }

  private void onChangeApplicationStatus() {
    Set<SObjectField> changedFields = new Set<SObjectField>{ Partner_Application_Form__c.Application_Status__c };

    List<SObject> changedRecords = getChangedRecords(changedFields);

    if (changedRecords.isEmpty())
      return;

    List<Partner_Application_Form__c> acceptStatuses = new List<Partner_Application_Form__c>();

    for (Partner_Application_Form__c changedRecord : (List<Partner_Application_Form__c>) changedRecords) {
      if (changedRecord.Application_Status__c == 'Accept') {
        acceptStatuses.add(changedRecord);
      }
    }

    if (!acceptStatuses.isEmpty()) {
      EmailsService_PP.sendApplicationStatusChange(acceptStatuses);
    }
  }

  private void onChangeUIPathStatusUpdateDate() {
    Set<SObjectField> changedFields = new Set<SObjectField>{ Partner_Application_Form__c.UIPath_Status__c };

    List<SObject> changedRecords = getChangedRecords(changedFields);

    if (changedRecords.isEmpty())
      return;

    for (Partner_Application_Form__c changedRecord : (List<Partner_Application_Form__c>) changedRecords) {
      changedRecord.UIPath_Status_Date__c = System.now();
    }
  }

  private void onChangeApplicationStatusUpdateDate() {
    Set<SObjectField> changedFields = new Set<SObjectField>{ Partner_Application_Form__c.Application_Status__c };

    List<SObject> changedRecords = getChangedRecords(changedFields);

    if (changedRecords.isEmpty())
      return;

    for (Partner_Application_Form__c changedRecord : (List<Partner_Application_Form__c>) changedRecords) {
      changedRecord.Application_Status_Date__c = System.now();
    }
  }

  public Set<Id> getLeadIds() {
    return Utilities_PP.pluckIdField(getRecords(), Partner_Application_Form__c.Lead__c);
  }

  public Set<Id> getOwnerIds() {
    return Utilities_PP.pluckIdField(getRecords(), Partner_Application_Form__c.OwnerId);
  }

  public void shareWithDistributors() {
    PartnerApplicationFormsService_PP.shareWithDistributors(Records);
  }

  private void recalculateCorruptionPerceptionLevel() {
    Map<String, List<Partner_Application_Form__c>> formsByCountry = getFormsByCountry();
    Map<String, Integer> scoreByCountry = getScoreByCountry(formsByCountry.keySet());

    for (String country : scoreByCountry.keySet()) {
      if (formsByCountry.containsKey(country) == false)
        continue;

      if (scoreByCountry.get(country) <= 43) {
        PartnerApplicationForms_PP.newInstance(formsByCountry.get(country)).setCorruptionPerceptionRisk(true);
      } else {
        PartnerApplicationForms_PP.newInstance(formsByCountry.get(country)).setCorruptionPerceptionRisk(false);
      }
    }
  }

  private void setCorruptionPerceptionRisk(Boolean value) {
    setFieldValue(Partner_Application_Form__c.CorruptionPerceptionRisk__c, value);
  }

  private Map<String, Integer> getScoreByCountry(Set<String> countryNames) {
    Map<String, Integer> result = new Map<String, Integer>();
    CorruptionPerceptionsIndexes_PP cpis = CorruptionPerceptionsIndexes_PP.newInstance(
      CorruptionPerceptionsIndexSelector_PP.newInstance().selectByName(countryNames)
    );
    if (cpis.isEmpty())
      return result;

    return cpis.getScoreByName();
  }

  private Map<String, List<Partner_Application_Form__c>> getFormsByCountry() {
    Map<String, List<Partner_Application_Form__c>> result = new Map<String, List<Partner_Application_Form__c>>();
    PartnerApplicationForms_PP forms = PartnerApplicationForms_PP.newInstance(getRecords());

    // first try to get the country from the formula field
    PartnerApplicationForms_PP withCountry = forms.selectWithCountry();
    PartnerApplicationForms_PP withoutCountry = forms.selectWithoutCountry();
    if (withCountry.isNotEmpty()) {
      result.putAll(withCountry.getRecordsByCountry());
    }
    // if there are any records left without formula field set (e.g. on new record creations),
    if (withoutCountry.isNotEmpty()) {
      // try to get the country from the linked Lead.Country field
      PartnerApplicationForms_PP withLeads = withoutCountry.selectWithLead().selectWithoutContact();
      if (withLeads.isNotEmpty()) {
        result.putAll(getFormsByCountryFromLead(withLeads));
      }
      // try to get the country from the linked Contact.Account.BillingCountry field
      PartnerApplicationForms_PP withContacts = withoutCountry.selectWithoutLead().selectWithContact();
      if (withContacts.isNotEmpty()) {
        result.putAll(getFormsByCountryFromContact(withContacts));
      }
    }
    return result;
  }

  private Map<String, List<Partner_Application_Form__c>> getFormsByCountryFromContact(
    PartnerApplicationForms_PP forms
  ) {
    Map<String, List<Partner_Application_Form__c>> result = new Map<String, List<Partner_Application_Form__c>>();
    // Get the contacts from the forms
    Map<Id, Id> contactIdByFormId = forms.getContactIdById();
    Contacts_PP contacts = Contacts_PP.newInstance(
      ContactsSelector_PP.newInstance().selectById(new Set<Id>(contactIdByFormId.values()), false)
    );
    Map<Id, Id> accountIdByContactId = contacts.getAccountIdById();
    // Get the account records for the contacts
    Accounts_PP accounts = Accounts_PP.newInstance(
      AccountsSelector_PP.newInstance().selectById(new Set<Id>(accountIdByContactId.values()), false)
    );
    Map<Id, String> countryByAccountId = accounts.getBillingCountryById();

    for (Partner_Application_Form__c form : forms.getPartnerApplicationForms()) {
      Id contactId = form.Contact__c;
      if (accountIdByContactId.containsKey(contactId) == false)
        continue;
      Id accountId = accountIdByContactId.get(contactId);
      if (countryByAccountId.containsKey(accountId) == false)
        continue;
      String country = countryByAccountId.get(accountId);

      if (result.containsKey(country) == false) {
        result.put(country, new List<Partner_Application_Form__c>());
      }
      result.get(country).add(form);
    }
    return result;
  }

  private Map<String, List<Partner_Application_Form__c>> getFormsByCountryFromLead(PartnerApplicationForms_PP forms) {
    Map<String, List<Partner_Application_Form__c>> result = new Map<String, List<Partner_Application_Form__c>>();
    // Get the leads
    Leads_PP leads = Leads_PP.newInstance(
      LeadsSelector_PP.newInstance() // Leads selector is already without sharing
        .selectById(forms.getLeadIds(), false)
    );
    if (leads.isEmpty())
      return result;

    Map<Id, String> countryByLeadId = leads.getCountryById();

    for (Partner_Application_Form__c form : forms.getPartnerApplicationForms()) {
      Id leadId = form.Lead__c;
      if (countryByLeadId.containsKey(leadId) == false)
        continue;
      String country = countryByLeadId.get(leadId);
      if (result.containsKey(country) == false) {
        result.put(country, new List<Partner_Application_Form__c>());
      }
      result.get(country).add(form);
    }
    return result;
  }

  // Domain methods - START - Should be moved to the domain class once the new fflib packages are installed
  private Map<Id, Id> getContactIdById() {
    Map<Id, Id> result = new Map<Id, Id>();
    for (Partner_Application_Form__c form : getPartnerApplicationForms()) {
      result.put(form.Id, form.Contact__c);
    }
    return result;
  }

  public Map<String, List<Partner_Application_Form__c>> getRecordsByCountry() {
    Map<String, List<Partner_Application_Form__c>> result = new Map<String, List<Partner_Application_Form__c>>();
    for (Partner_Application_Form__c form : getPartnerApplicationForms()) {
      if (form.get(Partner_Application_Form__c.Country__c) == null)
        continue;
      String country = String.valueOf(form.get(Partner_Application_Form__c.Country__c));
      if (result.containsKey(country) == false) {
        result.put(country, new List<Partner_Application_Form__c>());
      }
      result.get(country).add(form);
    }
    return result;
  }

  public List<Partner_Application_Form__c> getPartnerApplicationForms() {
    return (List<Partner_Application_Form__c>) getRecords();
  }

  public PartnerApplicationForms_PP selectByIdNotIn(Set<Id> ids) {
    List<Partner_Application_Form__c> result = new List<Partner_Application_Form__c>();
    for (Partner_Application_Form__c form : getPartnerApplicationForms()) {
      if (ids.contains(form.Id))
        continue;
      result.add(form);
    }
    return new PartnerApplicationForms_PP(result);
  }

  public PartnerApplicationForms_PP selectByStatus(Set<String> statuses) {
    List<Partner_Application_Form__c> result = new List<Partner_Application_Form__c>();
    for (Partner_Application_Form__c form : getPartnerApplicationForms()) {
      if (statuses.contains(form.UIPath_Status__c))
        result.add(form);
      else
        continue;
    }
    return new PartnerApplicationForms_PP(result);
  }

  public PartnerApplicationForms_PP selectByComplianceStatusNotIn(Set<String> complianceStatuses) {
    List<Partner_Application_Form__c> result = new List<Partner_Application_Form__c>();
    for (Partner_Application_Form__c form : getPartnerApplicationForms()) {
      if (complianceStatuses.contains(form.UiPath_Compliance_Status__c))
        continue;
      result.add(form);
    }
    return new PartnerApplicationForms_PP(result);
  }

  public PartnerApplicationForms_PP selectWith(Schema.SObjectField sObjectField) {
    List<Partner_Application_Form__c> result = new List<Partner_Application_Form__c>();
    for (Partner_Application_Form__c record : getPartnerApplicationForms()) {
      if (record.get(sObjectField) == null)
        continue;
      result.add(record);
    }
    return new PartnerApplicationForms_PP(result);
  }

  private PartnerApplicationForms_PP selectWithContact() {
    return selectWith(Partner_Application_Form__c.Contact__c);
  }

  private PartnerApplicationForms_PP selectWithCountry() {
    return selectWith(Schema.Partner_Application_Form__c.Country__c);
  }

  public PartnerApplicationForms_PP selectWithLead() {
    return selectWith(Schema.Partner_Application_Form__c.Lead__c);
  }

  public PartnerApplicationForms_PP selectWithout(Schema.SObjectField sObjectField) {
    List<Partner_Application_Form__c> result = new List<Partner_Application_Form__c>();
    for (Partner_Application_Form__c record : getPartnerApplicationForms()) {
      if (record.get(sObjectField) != null)
        continue;
      result.add(record);
    }
    return new PartnerApplicationForms_PP(result);
  }

  public PartnerApplicationForms_PP selectWithoutContact() {
    return selectWithout(Schema.Partner_Application_Form__c.Contact__c);
  }

  private PartnerApplicationForms_PP selectWithoutCountry() {
    return selectWithout(Schema.Partner_Application_Form__c.Country__c);
  }

  private PartnerApplicationForms_PP selectWithoutLead() {
    return selectWithout(Schema.Partner_Application_Form__c.Lead__c);
  }

  public PartnerApplicationForms_PP selectWithoutMPASentDate() {
    List<Partner_Application_Form__c> result = new List<Partner_Application_Form__c>();
    for (Partner_Application_Form__c record : getPartnerApplicationForms()) {
      if (record.MPA_Sent_Date__c != null)
        continue;
      result.add(record);
    }
    return new PartnerApplicationForms_PP(result);
  }

  public PartnerApplicationForms_PP setMPASentDate(Datetime dt) {
    for (Partner_Application_Form__c record : getPartnerApplicationForms()) {
      record.MPA_Sent_Date__c = dt;
    }
    return this;
  }

  public PartnerApplicationForms_PP setOwnerIdByCountry(Map<String, Id> ownerIdByCountry) {
    setFieldValue(
      Schema.Partner_Application_Form__c.Country__c,
      Schema.Partner_Application_Form__c.OwnerId,
      ownerIdByCountry
    );
    return this;
  }

  private virtual void setFieldValue(
    Schema.SObjectField sObjectStringFieldToCheck,
    Schema.SObjectField sObjectFieldToUpdate,
    Map<String, Object> values
  ) {
    for (SObject record : getRecords()) {
      String keyValue = (String) record.get(sObjectStringFieldToCheck);
      if (values?.containsKey(keyValue)) {
        record.put(sObjectFieldToUpdate, values.get(keyValue));
      }
    }
  }

  // Domain methods - END

  public class Constructor implements fflib_SObjectDomain.IConstructable2 {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new PartnerApplicationForms_PP(sObjectList);
    }

    public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType) {
      return new PartnerApplicationForms_PP(sObjectList);
    }
  }
}