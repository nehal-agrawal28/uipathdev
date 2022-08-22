@IsTest(IsParallel=true)
private class ApproversTest_PP {
  @IsTest
  static void testNewInstanceWithIds() {
    final Id id = fflib_IDGenerator.generate(Schema.sbaa__Approver__c.SObjectType);
    final Set<Id> ids = new Set<Id>{ id };
    final List<sbaa__Approver__c> records = new List<sbaa__Approver__c>{ new sbaa__Approver__c(Id = id) };

    fflib_ApexMocks mocks = new fflib_ApexMocks();
    IApproversSelector_PP selectorMock = (IApproversSelector_PP) mocks.mock(IApproversSelector_PP.class);

    mocks.startStubbing();
    mocks.when(selectorMock.selectSObjectsById(ids)).thenReturn(records);
    mocks.stopStubbing();

    Application_PP.Selector.setMock(Schema.sbaa__Approver__c.SObjectType, selectorMock);

    System.Test.startTest();
    IApprovers_PP result = Approvers_PP.newInstance(ids);
    System.Test.stopTest();

    System.assertEquals(records, result.getApprovers());
  }

  @IsTest
  static void testNewInstanceWithRecords() {
    final List<sbaa__Approver__c> records = new List<sbaa__Approver__c>{
      new sbaa__Approver__c(Id = fflib_IDGenerator.generate(Schema.sbaa__Approver__c.SObjectType))
    };

    System.Test.startTest();
    IApprovers_PP result = Approvers_PP.newInstance(records);
    System.Test.stopTest();

    System.assertEquals(records, result.getApprovers());
  }
}