@IsTest
private class CasesTriggerHandlerTest_PP {
  @IsTest
  static void itShouldSetTheMPADate() {
    // GIVEN one case record and two Partner Application Forms one with an one without MPA Sent Date

    // Create mock case record
    final Id accountId = fflib_IDGenerator.generate(Schema.Account.SObjectType);
    final Id caseId = fflib_IDGenerator.generate(Schema.Case.SObjectType);
    final Id recordTypeLegalRequestId = fflib_RecordTypeId.getByDeveloperName(
      'Case',
      CasesTriggerHandler_PP.RECORDTYPE_LEGAL_REQUEST
    );
    final Case record = new Case(
      Id = caseId,
      RecordTypeId = recordTypeLegalRequestId,
      AccountId = accountId,
      Status = CasesTriggerHandler_PP.STATUS_OUT_FOR_SIGNATURE,
      Document_Type__c = new List<String>(CasesTriggerHandler_PP.LEGAL_CASE_DOCUMENT_TYPES).get(0)
    );

    CasesTriggerHandler_PP triggerHandler = new CasesTriggerHandler_PP(new List<Case>{ record });

    // Create mock partner application form
    final Id pafIdA = fflib_IDGenerator.generate(Schema.Partner_Application_Form__c.SObjectType);
    final Id pafIdB = fflib_IDGenerator.generate(Schema.Partner_Application_Form__c.SObjectType);
    final Partner_Application_Form__c pafA = new Partner_Application_Form__c(Id = pafIdA, Account__c = accountId);
    final Partner_Application_Form__c pafB = new Partner_Application_Form__c(
      Id = pafIdB,
      Account__c = accountId,
      MPA_Sent_Date__c = Datetime.now()
    );
    final List<Partner_Application_Form__c> pafs = new List<Partner_Application_Form__c>{ pafA, pafB };

    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork unitOfWorkMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
    PartnerApplicationFormsSelector_PP selectorMock = (PartnerApplicationFormsSelector_PP) mocks.mock(
      PartnerApplicationFormsSelector_PP.class
    );

    mocks.startStubbing();
    mocks.when(selectorMock.sObjectType()).thenReturn(Partner_Application_Form__c.SObjectType);
    mocks.when(selectorMock.selectByAccountId(new Set<Id>{ accountId })).thenReturn(pafs);
    mocks.stopStubbing();

    Application_PP.ElevatedSelector.setMock(selectorMock);
    Application_PP.UnitOfWork.setMock(unitOfWorkMock);

    // WHEN we the case creation triggers the logic
    System.Test.startTest();
    triggerHandler.onLegalRequestOutForSignatureSetSentDateOnPartnerApplicationForm(unitOfWorkMock);
    System.Test.stopTest();

    // THEN only the Partner Application Form without MPA sent date should now have a sent date.
    fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass(fflib_ISObjectUnitOfWork.class);
    ((fflib_ISObjectUnitOfWork) mocks.verify(unitOfWorkMock))
      .registerDirty((List<Partner_Application_Form__c>) argument.capture());

    List<Partner_Application_Form__c> result = (List<Partner_Application_Form__c>) argument.getValue();
    System.assertEquals(1, result.size(), 'Incorrect amount of records send to the unit-of-work');
    System.assertEquals(pafIdA, result.get(0).Id, 'Wrong record send to the unit-of-work');
    System.assertNotEquals(null, result.get(0).MPA_Sent_Date__c, 'Field was not populated');
  }
}