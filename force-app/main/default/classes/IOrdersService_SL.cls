public interface IOrdersService_SL {
  Map<Id, Order> syncFieldOnCancelledOrders(Set<Id> replacementOrderIds, SObjectField field);
}