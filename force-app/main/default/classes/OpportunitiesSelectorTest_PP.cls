@IsTest
private class OpportunitiesSelectorTest_PP {
  static testMethod void itShouldReturnTheSObjectType() {
    System.assertEquals(Schema.Opportunity.SObjectType, new OpportunitiesSelector_PP().getSObjectType());
  }

  static testMethod void itShouldReturnGroupById() {
    System.assert(
      new OpportunitiesSelector_PP()
        .selectById(new Set<Id>{ fflib_IDGenerator.generate(Opportunity.SObjectType) }, false)
        .isEmpty()
    );
  }

  static testMethod void itShouldQueryGroupByName() {
    System.assert(
      new OpportunitiesSelector_PP()
        .selectBySoldToPartnersOrTier2Partners(new Set<Id>{ fflib_IDGenerator.generate(Opportunity.SObjectType) })
        .isEmpty()
    );
  }
}