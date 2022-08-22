public with sharing class OrderPricebookFunction_SL implements SObjectToSObjectFunction {
  public OrderPriceBookFunction_SL(List<Order> records) {
  }

  private SObject apply(Order order) {
    order.Pricebook2Id = OpportunitiesService_SL.oppDefaultPricebookId;
    return order;
  }

  public SObject apply(SObject record) {
    return apply((Order) record);
  }

  public static void populatePricebookIdInScratchOrgs(List<Order> records) {
    Organization org = [SELECT IsSandbox, TrialExpirationDate FROM Organization];
    Boolean isScratchOrg = org.IsSandbox && org.TrialExpirationDate != null;

    if (isScratchOrg) {
      List<Order> eligibleRecords = Collection.of(records)
        .filter(Match.field(Order.Pricebook2Id).equals(null))
        .asList();

      if (!eligibleRecords.isEmpty()) {
        Collection.of(eligibleRecords).mapAll(new OrderPriceBookFunction_SL(eligibleRecords));
      }
    }
  }
}