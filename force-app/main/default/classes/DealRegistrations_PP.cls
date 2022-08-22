public with sharing class DealRegistrations_PP extends fflib_SObjectDomain {
  public static final String BPO_DEALTYPE_IS_NOT_ALLOWED = 'BPO deal type is not allowed because your Account does not have this agreement.';
  public static final String RESALE_DEALTYPE_IS_NOT_ALLOWED = 'Resale deal type is not allowed because your Account does not have this agreement.';

  public DealRegistrations_PP(List<DealRegistration__c> records) {
    super(records, DealRegistration__c.SObjectType);
  }

  public static Id SUBMITTED_RECORDTYPE_ID {
    get {
      if (null == SUBMITTED_RECORDTYPE_ID) {
        SUBMITTED_RECORDTYPE_ID = Schema.SObjectType.DealRegistration__c
          .getRecordTypeInfosByDeveloperName()
          .get('SubmittedDealRegistration')
          .getRecordTypeId();
      }
      return SUBMITTED_RECORDTYPE_ID;
    }
    set;
  }

  public override void onBeforeInsert() {
    validateAmountField();
    onDealTypeNFRorPIIAutomaticallySubmitDeal();
  }

  public override void onAfterInsert() {
    shareDealRegistrationToPartners();
    onDealTypeNFRorPIICreateOpportunity();
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    validateAmountField();
    onChangedDealTypeToNFRorPIIAutomaticallySubmitDeal();
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    onChangedRecordType();
    shareDealRegistrationToPartners();
  }

  public override void onBeforeDelete() {
    checkIfDeletable();
  }

  public override void onValidate(Map<Id, SObject> existingRecords) {
    validateDealTypeOnChangedRecordType();
  }

  private void validateDealTypeOnChangedRecordType() {
    List<SObject> changedRecords = getChangedRecords(new Set<Schema.SObjectField>{ DealRegistration__c.RecordTypeId });

    if (changedRecords.isEmpty())
      return;

    new DealRegistrations_PP(changedRecords).validateDealType();
  }

  private void validateDealType() {
    Map<Id, Account> accounts = new Map<Id, Account>(
      (List<Account>) AccountsSelector_PP.newInstance().selectSObjectsById(getAccountIds())
    );

    for (DealRegistration__c record : (List<DealRegistration__c>) getRecords()) {
      Account account = accounts.get(record.Account__c);
      if (
        record.DealType__c == 'BPO' &&
        account != null &&
        account.Partner_Reporting_Name__c != null &&
        account.Partner_Reporting_Name__c.contains('Ingram') == true &&
        account.Business_Partner_Contract__c != null &&
        (account.BillingCountryCode == 'IN' ||
        account.BillingCountryCode == 'CN' ||
        account.Business_Partner_Contract__c.contains('BPO') == true)
      ) {
        break;
      }

      if (
        record.DealType__c == 'BPO' &&
        account != null &&
        account.Business_Partner_Contract__c != null &&
        account.Business_Partner_Contract__c.contains('BPO') == false
      ) {
        record.addError(error(BPO_DEALTYPE_IS_NOT_ALLOWED, record, DealRegistration__c.DealType__c));
      } else if (
        record.DealType__c == 'Resale' &&
        account != null &&
        (account.Business_Partner_Contract__c == 'BPO' ||
        account.Business_Partner_Contract__c == 'BPO AAA' ||
        account.Business_Partner_Contract__c == 'MPA via Distributor BPO')
      ) {
        record.addError(error(RESALE_DEALTYPE_IS_NOT_ALLOWED, record, DealRegistration__c.DealType__c));
      }
    }
  }

  public Set<Id> getAccountIds() {
    Set<Id> result = new Set<Id>();
    for (DealRegistration__c record : (List<DealRegistration__c>) getRecords()) {
      if (record.Account__c == null)
        continue;

      result.add(record.Account__c);
    }
    return result;
  }

  public DealRegistrations_PP selectByDealType(Set<String> dealTypes) {
    List<DealRegistration__c> result = new List<DealRegistration__c>();
    for (DealRegistration__c record : (List<DealRegistration__c>) getRecords()) {
      if (dealTypes.contains(record.DealType__c)) {
        result.add(record);
      }
    }
    return new DealRegistrations_PP(result);
  }

  public DealRegistrations_PP setRecordTypeId(Id recordTypeId) {
    for (DealRegistration__c record : (List<DealRegistration__c>) getRecords()) {
      record.RecordTypeId = recordTypeId;
    }
    return this;
  }

  public DealRegistrations_PP submitDeals() {
    return setRecordTypeId(SUBMITTED_RECORDTYPE_ID);
  }

  private void onChangedRecordType() {
    List<SObject> changedRecords = getChangedRecords(new Set<Schema.SObjectField>{ DealRegistration__c.RecordTypeId });

    DealRegistrations_PP dealRegistrationsDomain = new DealRegistrations_PP(changedRecords).selectSubmittedDeals();

    if (dealRegistrationsDomain.getRecords().isEmpty())
      return;

    new DealRegistrations_PP(dealRegistrationsDomain.getRecords().deepClone(true, true, true)).createOpportunities();
  }

  private void onDealTypeNFRorPIICreateOpportunity() {
    DealRegistrations_PP dealRegistrations = selectByDealType(
      new Set<String>{ 'Partner Internal Infrastructure', 'NFR' }
    );

    if (dealRegistrations.getRecords().isEmpty())
      return;

    aSyncCreateOpportunities(dealRegistrations.getRecordIds());
  }

  public void createOpportunities() {
    ((DealRegistrationsService_PP) Application_PP.Service.newInstance(DealRegistrationsService_PP.class))
      .createOpportunitiesFromDealRegistrations(getDealRegistrations());
  }

  public static void aSyncCreateOpportunities(Set<Id> dealRegistrationIds) {
    AbstractQueueable.enqueue(new CreateOpportunitiesForDealRegQueueable(dealRegistrationIds));
  }

  public List<DealRegistration__c> getDealRegistrations() {
    return (List<DealRegistration__c>) getRecords();
  }
  private void onDealTypeNFRorPIIAutomaticallySubmitDeal() {
    DealRegistrations_PP dealRegistrations = selectByDealType(
      new Set<String>{ 'Partner Internal Infrastructure', 'NFR' }
    );

    if (dealRegistrations.getRecords().isEmpty())
      return;

    dealRegistrations.submitDeals();
  }

  private void onChangedDealTypeToNFRorPIIAutomaticallySubmitDeal() {
    List<SObject> changedRecords = getChangedRecords(new Set<Schema.SObjectField>{ DealRegistration__c.DealType__c });
    if (changedRecords.isEmpty())
      return;

    DealRegistrations_PP dealRegistrations = new DealRegistrations_PP(changedRecords)
      .selectByDealType(new Set<String>{ 'Partner Internal Infrastructure', 'NFR' });

    if (dealRegistrations.getRecords().isEmpty())
      return;

    dealRegistrations.submitDeals();
  }

  private DealRegistrations_PP selectSubmittedDeals() {
    List<DealRegistration__c> result = new List<DealRegistration__c>();

    for (DealRegistration__c deal : (List<DealRegistration__c>) Records) {
      if (deal.RecordTypeId == SUBMITTED_RECORDTYPE_ID) {
        result.add(deal);
      }
    }

    return new DealRegistrations_PP(result);
  }

  private void checkIfDeletable() {
    for (DealRegistration__c dealReg : (List<DealRegistration__c>) Records) {
      if (dealReg.RecordTypeId == DealRegistrationsService_PP.SUBMITTED_DEAL_REGISTRATION_RT) {
        DealRegistrationsService_PP service = (DealRegistrationsService_PP) Application_PP.Service.newInstance(
          DealRegistrationsService_PP.class
        );
        service.setErrorMessageGeneral(dealReg, System.Label.You_Can_Not_Delete_Submitted_Deal_Registration);
      }
    }
  }

  private void validateAmountField() {
    List<DealRegistration__c> newDealRegs = (List<DealRegistration__c>) Records;
    List<DealRegistration__c> changedRecords = getChangedRecords(
      new Set<Schema.SObjectField>{ DealRegistration__c.DealRegistrationAmount__c }
    );

    if (changedRecords.isEmpty() || newDealRegs[0].SkipAmountValidation__c)
      return;

    Map<Id, DealRegistration__c> dealRegsAmountChanged = (new Map<Id, DealRegistration__c>(changedRecords));

    DealRegistrationsService_PP dealRegistrationsService = (DealRegistrationsService_PP) Application_PP.Service.newInstance(
      DealRegistrationsService_PP.class
    );

    final Set<Id> dealRegIdsWithProducts = dealRegistrationsService.getDealRegIdsWithProducts(dealRegsAmountChanged);

    for (Id key : dealRegsAmountChanged.keySet()) {
      if (dealRegIdsWithProducts.contains(key)) {
        dealRegistrationsService.setErrorMessageOnAmount(dealRegsAmountChanged.get(key));
      }
    }

    resetSkipAmountValidation();
  }

  private void resetSkipAmountValidation() {
    for (DealRegistration__c dealReg : (List<DealRegistration__c>) Records) {
      if (dealReg.SkipAmountValidation__c) {
        dealReg.SkipAmountValidation__c = false;
      }
    }
  }

  private void shareDealRegistrationToPartners() {
    Set<Schema.SObjectField> fields = new Set<Schema.SObjectField>{
      DealRegistration__c.Account__c,
      DealRegistration__c.Distributor__c,
      DealRegistration__c.Tier2Partner__c
    };

    List<DealRegistration__c> dealRegistrations = Trigger.isInsert
      ? (List<DealRegistration__c>) getRecords()
      : (List<DealRegistration__c>) getChangedRecords(fields);

    List<DealRegistration__c> recordsToShare = new List<DealRegistration__c>();

    for (DealRegistration__c dealRegistration : dealRegistrations) {
      recordsToShare.add(dealRegistration);
    }

    if (!recordsToShare.isEmpty()) {
      DealRegistrationsService_PP service = (DealRegistrationsService_PP) Application_PP.Service.newInstance(
        DealRegistrationsService_PP.class
      );

      service.shareDealRegistrationToPartners(records);
    }
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable2 {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new DealRegistrations_PP(sObjectList);
    }

    public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType) {
      return new DealRegistrations_PP(sObjectList);
    }
  }
}