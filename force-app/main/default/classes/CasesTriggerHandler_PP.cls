public class CasesTriggerHandler_PP extends fflib_SObjectDomain {
  @TestVisible
  private static final String RECORDTYPE_LEGAL_REQUEST = 'Legal_Request';
  @TestVisible
  private static final String STATUS_OUT_FOR_SIGNATURE = 'Out for Signature';

  @TestVisible
  private static final Set<String> LEGAL_CASE_DOCUMENT_TYPES = new Set<String>{
    'Affiliate Adoption Agreement',
    'Partner BPO Only Agreement',
    'Partner Resale + BPO Agreement',
    'Partner Resale Only Agreement'
  };

  public CasesTriggerHandler_PP(List<Case> records) {
    super(records, Schema.Case.SObjectType);
    Configuration.disableTriggerCRUDSecurity();
  }

  public override void onAfterInsert() {
    fflib_ISObjectUnitOfWork unitOfWork = Application_PP.UnitOfWork.newInstance();
    onLegalRequestOutForSignatureSetSentDateOnPartnerApplicationForm(unitOfWork);
    unitOfWork.commitWork();
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    fflib_ISObjectUnitOfWork unitOfWork = Application_PP.UnitOfWork.newInstance();
    onChangedStatusToOutForSignatureSetSentDateOnPartnerApplicationForm(unitOfWork);
    unitOfWork.commitWork();
  }

  private void onChangedStatusToOutForSignatureSetSentDateOnPartnerApplicationForm(
    fflib_ISObjectUnitOfWork unitOfWork
  ) {
    List<SObject> changedRecords = getChangedRecords(new Set<SObjectField>{ Case.Status });
    if (changedRecords.isEmpty())
      return;

    new CasesTriggerHandler_PP(changedRecords)
      .onLegalRequestOutForSignatureSetSentDateOnPartnerApplicationForm(unitOfWork);
  }

  @TestVisible
  private void onLegalRequestOutForSignatureSetSentDateOnPartnerApplicationForm(fflib_ISObjectUnitOfWork unitOfWork) {
    Cases_PP cases = Cases_PP.newInstance(getRecords())
      .selectByRecordTypeId(
        new Set<Id>{ fflib_RecordTypeId.getByDeveloperName(getSObjectType(), RECORDTYPE_LEGAL_REQUEST) }
      )
      .selectByDocumentType(LEGAL_CASE_DOCUMENT_TYPES)
      .selectByStatus(new Set<String>{ STATUS_OUT_FOR_SIGNATURE });
    if (cases.isEmpty())
      return;

    setSentDateOnPartnerApplicationForm(unitOfWork, cases);
  }

  private void setSentDateOnPartnerApplicationForm(fflib_ISObjectUnitOfWork unitOfWork, Cases_PP cases) {
    Set<Id> accountIds = cases.getAccountIds();
    PartnerApplicationForms_PP forms = PartnerApplicationForms_PP.newInstance(
        PartnerApplicationFormsSelector_PP.newWithoutSharingInstance().selectByAccountId(accountIds)
      )
      .selectWithoutMPASentDate();
    if (forms.isEmpty())
      return;

    forms.setMPASentDate(Datetime.now());

    unitOfWork.registerDirty(forms.getRecords());
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable2 {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new CasesTriggerHandler_PP(sObjectList);
    }

    public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType) {
      return new CasesTriggerHandler_PP(sObjectList);
    }
  }
}