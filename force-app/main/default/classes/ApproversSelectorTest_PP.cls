@IsTest
private class ApproversSelectorTest_PP {
  static testMethod void itShouldReturnTheSObjectType() {
    System.assertEquals(Schema.sbaa__Approver__c.SObjectType, new ApproversSelector_PP().getSObjectType());
  }

  static testMethod void itShouldReturnInstances() {
    ApproversSelector_PP.newInstance();
    ApproversSelector_PP.newWithoutSharingInstance();
    ApproversSelector_PP.newInheritedSharingInstance();
  }

  static testMethod void itShouldReturnById() {
    System.assert(
      ApproversSelector_PP.newInstance()
        .selectById(new Set<Id>{ fflib_IDGenerator.generate(sbaa__Approver__c.SObjectType) })
        .isEmpty()
    );

    System.assert(
      ApproversSelector_PP.newWithoutSharingInstance()
        .selectById(new Set<Id>{ fflib_IDGenerator.generate(sbaa__Approver__c.SObjectType) })
        .isEmpty()
    );
  }
}