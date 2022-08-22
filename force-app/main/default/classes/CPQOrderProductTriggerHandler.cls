/**
* @author Slalom
* @date 24/08/2020
* @description Event listeners for Order Product Trigger. This class should ideally delegate work to Domain/Service classes
* @revision #1: Initial Version
*/

public without sharing class CPQOrderProductTriggerHandler extends TriggerHandler{
    /** 
    * After Update logic
    */
    public override void afterUpdate(){
        this.processContractedOrderProducts(trigger.oldMap,trigger.newMap);
    }
    public override void beforeInsert(){
        this.copyBillingFrequencyOrderToOrderProducts(trigger.new);
    }
    /** 
    * @Description: Process contracted order products when subscriptions are generated for them and mark the corresponding Order ready for integration
    * @RETURN: 
    * @PARAM:       Map<Id,SObject> oldMap - Trigger context of old order products Map
                    Map<Id,sObject> newMap - Trigger context of new order products Map
    */
    public void processContractedOrderProducts(Map<Id,sObject> oldMap, Map<Id,sObject> newMap){
        Map<Id,OrderItem> oldOrderProductsMap = (Map<Id,OrderItem>)oldMap;
        Map<Id,OrderItem> newOrderProductsMap = (Map<Id,OrderItem>)newMap;
            
        Set<Id> orderIDsToSyncSet = new Set<Id>();
        List<Order> ordersToUpdate = new List<Order>();
        List<Order> ordersToSyncLst = new List<Order>();

        //create list of Order Ids whose Order Products were updated to link with corresponding subscriptions & contract
        for(OrderItem newOrdProd : newOrderProductsMap.values()){
            if(oldOrderProductsMap.get(newOrdProd.id).SBQQ__Subscription__c == null && newOrdProd.SBQQ__Subscription__c != null && newOrdProd.SBQQ__Contracted__c){
                if(!orderIDsToSyncSet.contains(newOrdProd.OrderId)){
                    orderIDsToSyncSet.add(newOrdProd.OrderId);
                }
            }
        }

        //fetch the orders with their sync status
        if(!orderIDsToSyncSet.isEmpty()){
            ordersToSyncLst = [SELECT Id, Sync_Status__c FROM Order WHERE Id IN :orderIDsToSyncSet];
        }

        //Mark the order ready for integration only if Sync Status is not set to Do Not Sync   
        if(!ordersToSyncLst.isEmpty()){
            for(Order ord: ordersToSyncLst){
                if(ord.Sync_Status__c != Constants.ORDER_SYNC_STATUS_DO_NOT_SYNC){
                    ord.Sync_Status__c = Constants.ORDER_SYNC_STATUS_VALID;
                    ordersToUpdate.add(ord);
                }
            }
            try{
                if(!ordersToUpdate.isEmpty()){
                    update ordersToUpdate;
                }
            }catch(Exception exp){
                system.debug('CPQOrderProductTriggerHandler :: processContractedOrderProducts :: Error occured while updating Orders: '+ exp.getMessage());
            }
           
        }
    }
    public void copyBillingFrequencyOrderToOrderProducts(List<sObject> newList){
       List<OrderItem> orderItems = (List<OrderItem>)newList;
        //get order ids in set 
        Set<id> orderIds = new Set<id>();
        for(OrderItem orderitem : orderItems){
            orderIds.add(orderitem.orderid);
        }
        //map of orderid and billing frequency
        Map<Id,String> OrderAndBillingFrequencyMap = new map<Id,String>();
        for(order odr : ([SELECT id, billing_frequency__c FROM Order WHERE id IN: orderIds])){
            OrderAndBillingFrequencyMap.put(odr.id, odr.billing_frequency__c);
        }
        for(OrderItem orderitem : orderItems){
                orderitem.SBQQ__BillingFrequency__c = OrderAndBillingFrequencyMap.get(orderitem.orderid);       
        }
    }
}