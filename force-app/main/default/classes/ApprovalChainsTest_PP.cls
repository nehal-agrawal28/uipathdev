@IsTest(IsParallel=true)
private class ApprovalChainsTest_PP {
  @IsTest
  static void testNewInstanceWithIds() {
    final Id id = fflib_IDGenerator.generate(Schema.sbaa__ApprovalChain__c.SObjectType);
    final Set<Id> ids = new Set<Id>{ id };
    final List<sbaa__ApprovalChain__c> records = new List<sbaa__ApprovalChain__c>{
      new sbaa__ApprovalChain__c(Id = id)
    };

    fflib_ApexMocks mocks = new fflib_ApexMocks();
    IApprovalChainsSelector_PP selectorMock = (IApprovalChainsSelector_PP) mocks.mock(IApprovalChainsSelector_PP.class);

    mocks.startStubbing();
    mocks.when(selectorMock.selectSObjectsById(ids)).thenReturn(records);
    mocks.stopStubbing();

    Application_PP.Selector.setMock(Schema.sbaa__ApprovalChain__c.SObjectType, selectorMock);

    System.Test.startTest();
    IApprovalChains_PP result = ApprovalChains_PP.newInstance(ids);
    System.Test.stopTest();

    System.assertEquals(records, result.getApprovalChains());
  }

  @IsTest
  static void testNewInstanceWithRecords() {
    final List<sbaa__ApprovalChain__c> records = new List<sbaa__ApprovalChain__c>{
      new sbaa__ApprovalChain__c(Id = fflib_IDGenerator.generate(Schema.sbaa__ApprovalChain__c.SObjectType))
    };

    System.Test.startTest();
    IApprovalChains_PP result = ApprovalChains_PP.newInstance(records);
    System.Test.stopTest();

    System.assertEquals(records, result.getApprovalChains());
  }
}