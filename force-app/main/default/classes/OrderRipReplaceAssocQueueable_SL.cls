public with sharing class OrderRipReplaceAssocQueueable_SL extends AbstractQueueable {
  private final List<SObject> orders;

  public OrderRipReplaceAssocQueueable_SL(List<SObject> orders) {
    super('OrderRipReplaceAssocQueueable_SL');
    this.orders = orders;
  }

  public override void work() {
    this.execute(this.orders);
  }

  private void execute(List<SObject> orders) {
    System.debug('OrderRipReplaceAssocQueueable_SL.execute() orders: ' + orders);

    //requery orders
    Set<Id> orderIds = new Set<Id>(Collection.of(orders).pluckIds());
    List<Order> orderList = [SELECT Id, SBQQ__Quote__r.Replacement_Quote__c FROM Order WHERE Id IN :orderIds];
    //

    List<Order> orderUpdateList = new List<Order>();

    Map<Id, Order> orderWitheRelationQuote = new Map<Id, Order>();

    for (Order o : orderList) {
      orderWitheRelationQuote.put(o.Id, o);
    }

    Set<Id> replacementQuoteIds = new Set<Id>(
      Collection.of(orderWitheRelationQuote.values()).pluckIds('SBQQ__Quote__r.Replacement_Quote__c')
    );

    List<Order> replacementOrders = [SELECT Id, SBQQ__Quote__c FROM Order WHERE SBQQ__Quote__c IN :replacementQuoteIds];

    Map<Id, Id> repQuoteToRepOrd = new Map<Id, Id>();

    for (Order repOrd : replacementOrders) {
      repQuoteToRepOrd.put(repOrd.SBQQ__Quote__c, repOrd.Id);
    }

    for (Order o : orderList) {
      if (
        orderWitheRelationQuote.containsKey(o.Id) &&
        orderWitheRelationQuote.get(o.Id).SBQQ__Quote__r.Replacement_Quote__c != null
      ) {
        Id replacementQuoteId = orderWitheRelationQuote.get(o.Id).SBQQ__Quote__r.Replacement_Quote__c;

        if (repQuoteToRepOrd.containsKey(replacementQuoteId)) {
          Id replacementOrderId = repQuoteToRepOrd.get(replacementQuoteId);
          o.Replacement_Order__c = replacementOrderId;
          orderUpdateList.add(o);
        }
      }
    }

    if (orderUpdateList.size() > 0) {
      System.debug('OrderRipReplaceAssocQueueable_SL.execute() orderUpdateList: ' + orderUpdateList);
      List<Database.SaveResult> saveResult;
      try {
        saveResult = Database.update(orderUpdateList);
      } catch (Exception e) {
        Logger.error(
          'Unable to update all/some Rip and Replace cancellation orders with their replacement order',
          saveResult
        );
        Logger.saveLog();
      }
    }
  }

  /*
   * Set parent order for in-scope cancellation orders
   */
  public static void setParent(List<Order> orders) {
    List<Order> scopeOrders = Collection.of(orders)
      .filter(Match.field(Order.SBQQ__Quote__c).hasValue())
      .filter(Match.field(Order.Cancellation_Transaction__c).equals(true))
      .asList();

    if (scopeOrders != null && scopeOrders.size() > 0) {
      System.debug('OrderRipReplaceAssocQueueable_SL.setParent() scopeOrders: ' + scopeOrders);
      OrderRipReplaceAssocQueueable_SL rrAssocQueue = new OrderRipReplaceAssocQueueable_SL(scopeOrders);

      if (!Test.isRunningTest()) {
        System.enqueueJob(rrAssocQueue);
      } else {
        rrAssocQueue.execute(scopeOrders);
      }
    }
  }
}