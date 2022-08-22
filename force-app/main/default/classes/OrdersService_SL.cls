public with sharing class OrdersService_SL implements IOrdersService_SL {
  private OrdersSelector_SL ordersSelector_SL {
    get {
      return (OrdersSelector_SL) Application_SL.Selector.newInstance(Order.SObjectType);
    }
    set;
  }

  public Map<Id, Order> syncFieldOnCancelledOrders(Set<Id> replacementOrderIds, SObjectField field) {
    Map<Id, Order> replacementOrders = new Map<Id, Order>(ordersSelector_SL.selectById(replacementOrderIds, false));

    List<Order> childOrders = ordersSelector_SL.getCancelledOrdersByReplacedOrders(replacementOrderIds);
    Map<Id, Order> childOrdersToUpdate = new Map<Id, Order>();

    for (Order order : childOrders) {
      Order parentOrder = replacementOrders.get(order.Replacement_Order__c);
      if (order.get(field) != parentOrder.get(field)) {
        order.put(field, parentOrder.get(field));
        childOrdersToUpdate.put(order.Id, order);
      }
    }

    DescribeFieldResult descrResult = field.getDescribe();
    String fieldName = descrResult.name;
    String fieldType = descrResult.getSoapType().name();
    Map<Id, Order> updatedOrders = (Map<Id, Order>) Collection.of(childOrdersToUpdate.values())
      .mapAll(new SetSobjectFieldFunction_SL(field, descrResult, fieldName, fieldType))
      .asMap(Map<Id, Order>.class);

    return updatedOrders;
  }
}