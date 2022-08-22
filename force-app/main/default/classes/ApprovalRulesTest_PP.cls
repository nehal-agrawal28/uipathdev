@IsTest(IsParallel=true)
private class ApprovalRulesTest_PP {
  @IsTest
  static void testNewInstanceWithIds() {
    final Id id = fflib_IDGenerator.generate(Schema.sbaa__ApprovalRule__c.SObjectType);
    final Set<Id> ids = new Set<Id>{ id };
    final List<sbaa__ApprovalRule__c> records = new List<sbaa__ApprovalRule__c>{ new sbaa__ApprovalRule__c(Id = id) };

    fflib_ApexMocks mocks = new fflib_ApexMocks();
    IApprovalRulesSelector_PP selectorMock = (IApprovalRulesSelector_PP) mocks.mock(IApprovalRulesSelector_PP.class);

    mocks.startStubbing();
    mocks.when(selectorMock.selectSObjectsById(ids)).thenReturn(records);
    mocks.stopStubbing();

    Application_PP.Selector.setMock(Schema.sbaa__ApprovalRule__c.SObjectType, selectorMock);

    System.Test.startTest();
    IApprovalRules_PP result = ApprovalRules_PP.newInstance(ids);
    System.Test.stopTest();

    System.assertEquals(records, result.getApprovalRules_PP());
  }

  @IsTest
  static void testNewInstanceWithRecords() {
    final List<sbaa__ApprovalRule__c> records = new List<sbaa__ApprovalRule__c>{
      new sbaa__ApprovalRule__c(Id = fflib_IDGenerator.generate(Schema.sbaa__ApprovalRule__c.SObjectType))
    };

    System.Test.startTest();
    IApprovalRules_PP result = ApprovalRules_PP.newInstance(records);
    System.Test.stopTest();

    System.assertEquals(records, result.getApprovalRules_PP());
  }
}