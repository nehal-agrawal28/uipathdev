/**
* @author Slalom
* @date 07/08/2020
* @description Event listeners for Order Trigger. This class should ideally delegate work to Domain/Service classes
* @revision #1: Add Payment Cycle updates on Opportunities
            #2: Added Order Activation and Sync Status Change Processing
*/
public without sharing class CPQOrderTriggerHandler extends TriggerHandler {
   
    /** 
    * Before Update logic
    */
    public override void beforeUpdate(){
        this.processOrdersOnActivation(trigger.oldMap,trigger.newMap);
    }

    /** 
    * After Update logic
    */
    public override void afterUpdate(){
        //this.processBillingFreqChange(trigger.oldMap,trigger.newMap); -- TO DO
        this.updateBillingFrequenciesOnOrderProd(trigger.oldMap, trigger.new);
        this.updatePaymentCycleOnOpp(trigger.oldMap, trigger.new);
        this.processSyncStatusChange(trigger.oldMap,trigger.newMap);
    }

    /** 
    * Before Delete logic
    */
    public override void beforeDelete(){
        this.uncheckQuoteOrdered(trigger.old);
    }
    
    /**
    *  @Description: Updates the Billing Frequency of the Order Products with Billing Frequency of Order
    *  @param Map<Id, SObject>      oldOrderMap - Trigger context of old orders 
    *  @param List<SObject>         newOrders - Trigger context of new orders     
    */
    private void updateBillingFrequenciesOnOrderProd(Map<Id, SObject> oldOrderMap, List<SObject> newOrders){
        Map<Id, String> orderIdToBillingFrequency = buildBillingFrequencyMap(oldOrderMap, newOrders, 'Id');

        List<OrderItem> orderProducts = getOrderProducts(orderIdToBillingFrequency.keySet());
        List<OrderItem> orderProductsToUpdate  = new List<OrderItem>();
        
        // Assign Billing Frequencies of Order Products
        if(!orderProducts.isEmpty()){
            for(OrderItem orderProduct : orderProducts){
                if(orderIdToBillingFrequency.containsKey(orderProduct.OrderId) && orderIdToBillingFrequency.get(orderProduct.OrderId) != null){
                    orderProduct.SBQQ__BillingFrequency__c = orderIdToBillingFrequency.get(orderProduct.OrderId);
                    orderProductsToUpdate.add(orderProduct);
                }
            }
        }
        
        // Update the values of Order Products
        updateRecords(orderProductsToUpdate, (List<Order>) newOrders, Label.Update_Order_Product_Billing_Frequency_Error);
    }
    
    /**
    *  @Description: Given a list of records, do an Update
    *  @param List<sObject>      	recordToUpdate - Records to Update
    *  @param List<Order> orders    orders - Trigger context of new orders  
    *  @param String   				errorMessage - Message to display in case of error
    */
    private void updateRecords(List<sObject> recordsToUpdate, List<Order> orders, String errorMessage){
        // Update the values of Order Products
        if(!recordsToUpdate.isEmpty()){
            //List<Database.SaveResult> results;
            
            // handleError code is wrong TODO:refactor 
            // try{
            //     results = Database.update(recordsToUpdate, false); 
            // } catch(Exception e){
            //     this.handleError(results, orders, errorMessage);
            // }
            update recordsToUpdate;
        }
    }

    /**
    *  @Description: Builds a map of specified key to Billing Frequency
    *  @param Map<Id, SObject>                                  oldOrderMap - Trigger context of old orders 
    *  @param List<SObject>                                     newOrders - Trigger context of new orders  
    *  @param String                                            key - Key to use 
    *  @return Map<Id, String> orderIdToBillingFrequency        orderIdToBillingFrequency - Map of order Id to Billing Frequency
    */
    private Map<Id, String> buildBillingFrequencyMap(Map<Id, SObject> oldOrderMap, List<SObject> newOrders, String key){
        Map<Id, String> orderIdToBillingFrequency = new Map<Id, String>();

        // Check for Orders that match criteria and add Billing Frequency to Map
        for(Order newOrder : (List<Order>) newOrders){
            Order oldOrder = (Order) oldOrderMap.get(newOrder.Id);
            if(newOrder.Status == Constants.DRAFT_ORDER_STATUS){
                if(!String.isEmpty(newOrder.Billing_Frequency__c) && oldOrder.Billing_Frequency__c != newOrder.Billing_Frequency__c){
                    orderIdToBillingFrequency.put(String.valueOf(newOrder.get(key)), newOrder.Billing_Frequency__c);
                }
            }
        }

        return orderIdToBillingFrequency;
    }

    /**
    *  @Description: Given a set of Order IDs, get the corresponding Order Products
    *  @param Set<Id>           orderIds - Set of Order IDs
    *  @param List<OrderItem>   - Corresponding Order Products 
    */
    private List<OrderItem> getOrderProducts(Set<Id> orderIds){
        return [SELECT SBQQ__BillingFrequency__c, OrderId FROM OrderItem WHERE OrderId IN :orderIds];
    }

    /**
    *  @Description: Updates the Payment Cycle on the Order's Opportunity
    *  @param Map<Id, SObject>                                  oldOrderMap - Trigger context of old orders 
    *  @param List<SObject>                                     newOrders - Trigger context of new orders     
    */
    private void updatePaymentCycleOnOpp(Map<Id, SObject> oldOrderMap, List<SObject> newOrders){
        Map<Id, String> oppIdToBillingFrequency = buildBillingFrequencyMap(oldOrderMap, newOrders, 'OpportunityId');
        List<Opportunity> opportunities = getOpportunities(oppIdToBillingFrequency.keySet());

        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        
        // Assign Billing Frequencies of Opportunities
        if(!opportunities.isEmpty()){
            for(Opportunity oppItem : opportunities){
                if(oppIdToBillingFrequency.containsKey(oppItem.Id) && oppIdToBillingFrequency.get(oppItem.Id) != null){
                    oppItem.Payment_Cycle__c = oppIdToBillingFrequency.get(oppItem.Id);
                    opportunitiesToUpdate.add(oppItem);
                }
            }
        }
        
        // Update the values of Opportunities
        updateRecords(opportunitiesToUpdate, (List<Order>) newOrders, Label.Update_Opportunity_Payment_Cycle_Error);
    }
   
    /**
    *  @Description: Given a list of Orders, get the corresponding Opportunities
    *  @param List<SObject>     newOrders - Trigger context of new orders  
    *  @param List<Opportunity>   - Corresponding Opportunities 
    */
    private List<Opportunity> getOpportunities(Set<Id> oppIds){
       return [SELECT Payment_Cycle__c FROM Opportunity WHERE Id IN :oppIds];
    }

    

    /**
    *  @Description: Given a set of Quopte IDs, get the Quote records
    *  @param Set<Id>                      quoteIds - Set of Quote IDs   
    *  @return List<SBQQ__Quote__c>        - Corresponding Quote records
    */
    private List<SBQQ__Quote__c> getQuotes(Set<Id> quoteIds){
        return [SELECT Id, SBQQ__Ordered__c, (SELECT Id, ActivatedDate, ActivatedById FROM SBQQ__Orders__r) FROM SBQQ__Quote__c WHERE Id IN :quoteIds];
    }
    
    
    
    /**
    *  @Description: On delete of a draft Order, unchecks the SBQQ__Ordered__c field on the Quote if there are no Active Orders
    *  @param        Map<Id,SObject>oldOrderMap - Trigger context of old orders 
    */
    private void uncheckQuoteOrdered(List<SObject> oldOrders){
        Set<Id> quoteIds = new Set<Id>();

        // Get all Quote Ids
        for(Order order : (List<Order>) oldOrders){
            if(order.SBQQ__Quote__c != null){
                quoteIds.add(order.SBQQ__Quote__c);
            }
        }

        List<SBQQ__Quote__c> quotes = getQuotes(quoteIds);
        List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();

        for(SBQQ__Quote__c quote : quotes){
            if(!quote.SBQQ__Orders__r.isEmpty()){
                for(Order order  : quote.SBQQ__Orders__r){
                    if(order.ActivatedDate == null && order.ActivatedById == null && quote.SBQQ__Ordered__c == true){
                        quote.SBQQ__Ordered__c = false;
                        quotesToUpdate.add(quote);
                    }
                }
            }
        }

        if(!quotesToUpdate.isEmpty()){
            //List<Database.SaveResult> results;    

            // handleError code is wrong TODO:refactor
            // try{
            //     results = Database.update(quotesToUpdate, false); 
            // } catch(Exception e){
            //     this.handleError(results, (List<Order>) oldOrders, new Map<Id, SBQQ__Quote__c>(quotesToUpdate), Label.Quote_Contracted_Error);
            // }
            update quotesToUpdate;
         }
    }

    /** 
    * @Description: Process the Orders on Activation
    * @RETURN: 
    * @PARAM:       Map<Id,SObject> oldOrderMap - Trigger context of old orders Map
                    Map<Id,sObject> newOrderMap - Trigger context of new orders Map
    */
    private void processOrdersOnActivation(Map<Id,sObject> oldMap, Map<Id,sObject> newMap){    
        Map<Id,Order> oldOrderMap = (Map<Id,Order>)oldMap;
        Map<Id,Order> newOrderMap = (Map<Id,Order>)newMap;
            
        //create list of Orders that are being Activated
        Map<Id,Order> activatedOrdersToProcessMap = new Map<Id,Order>();
        for(Order newOrd : newOrderMap.values()){
            if(newOrd.status == Constants.ACTIVATED_ORDER_STATUS && oldOrderMap.get(newOrd.id).Status != newOrd.status){
                activatedOrdersToProcessMap.put(newOrd.id,newOrd);
            }
        }

        //Process the activated orders
        if(!activatedOrdersToProcessMap.isEmpty()){
            //Contract activated orders
             this.contractActivatedOrders(activatedOrdersToProcessMap);
            // update posting date field on order actiovation
            this.defaultPostingDateOnOrderActivation(activatedOrdersToProcessMap);
            
        }
    }   

    /** 
    * @Description: Contract the Order and update Sync Status field upon Order Activation
    * @RETURN: 
    * @PARAM:       Map<Id,Order> newActivatedOrdersMap - new activated orders map 
    */
    private void contractActivatedOrders(Map<Id,Order> newActivatedOrdersMap){
        //Fetch subscription order products for these orders
        list<Order> OrdersWithOrderItem = [SELECT Id, Sync_Status__c, (SELECT Id FROM OrderItems WHERE SBQQ__SubscriptionPricing__c != null) FROM Order WHERE Id IN: newActivatedOrdersMap.keySet()];
        
        for(Order ord : OrdersWithOrderItem){
            newActivatedOrdersMap.get(ord.id).SBQQ__Contracted__c = true;

            /* If Order do not contain any subscription order products then no subscriptions will be created and Order Sync Status is not set to "Do Not Sync", 
            then mark the record ready for integration */
            if(null != ord.OrderItems && ord.OrderItems.isEmpty() && ord.Sync_Status__c != Constants.ORDER_SYNC_STATUS_DO_NOT_SYNC){
                newActivatedOrdersMap.get(ord.id).Sync_Status__c = Constants.ORDER_SYNC_STATUS_VALID;
            }
        }
    }
    /** 
    * @Description: Update the posting date fields if blank upon Order Activation
    * @RETURN: 
    * @PARAM:       Map<Id,Order> newActivatedOrdersMap - new activated orders map 
    */
    private void defaultPostingDateOnOrderActivation(Map<Id,Order> newActivatedOrdersMap){
        for(Order ord : newActivatedOrdersMap.values()){
           //If Order Posting_Date__c is empty at time of order activation set the date to today's date.
            if(null == ord.Posting_Date__c ){
                ord.Posting_Date__c = system.today();
           }
        }
    }

    /** 
    * @Description: Process Order Sync Status change and make a callout to SF connector app order integration template
    * @RETURN: 
    * @PARAM:       Map<Id,SObject> oldOrderMap - Trigger context of old orders Map
                    Map<Id,sObject> newOrderMap - Trigger context of new orders Map
    */
    public void processSyncStatusChange(Map<Id,sObject> oldMap, Map<Id,sObject> newMap){
        Map<Id,Order> oldOrderMap = (Map<Id,Order>)oldMap;
        Map<Id,Order> newOrderMap = (Map<Id,Order>)newMap;
            
        //create list of Orders where Sync Status is changed to "Valid" or "Pending"
        Map<Id,Order> ordersToSyncMap = new Map<Id,Order>();
        for(Order newOrd : newOrderMap.values()){
            if(oldOrderMap.get(newOrd.id).Sync_Status__c != newOrd.Sync_Status__c && (newOrd.Sync_Status__c == Constants.ORDER_SYNC_STATUS_VALID || newOrd.Sync_Status__c == Constants.ORDER_SYNC_STATUS_PENDING)){
                ordersToSyncMap.put(newOrd.id,newOrd);
            }
        }

        //Call the SF Connector order integration template
        if(!ordersToSyncMap.isEmpty()){
            this.callUipathSFConnectorTemplate(ordersToSyncMap.keySet(), Constants.ORDER_INT_UIPATH_SF_CONNECTOR_TEMPLATE);
        }
    }

    /** 
    * @Description: Callout to SF connector managed app integration template (can be moved to a separate integration service if plan to use it for other integrations)
    * @RETURN: 
    * @PARAM:       Set<Id> recordsToSyncSet -  list of SF record ids to be integrated
                    String connectorTemplateName - Custom metadata teamplate name for UiPath SF Connector App
    */
    public void callUipathSFConnectorTemplate(Set<Id> recordsToSyncSet, String connectorTemplateName){
        List<UiPath.QueueNotificationRequest> queueRequestsLst = new List<UiPath.QueueNotificationRequest>();

        for(Id recId: recordsToSyncSet){
            UiPath.QueueNotificationRequest recordQueueReq = new UiPath.QueueNotificationRequest();
            recordQueueReq.templateName = connectorTemplateName;
            recordQueueReq.recordId = recId;
            queueRequestsLst.add(recordQueueReq);
        }

        //call the SF Connector integration service
        Uipath.QueueNotificationService.createNotifications(queueRequestsLst);
    }

    /**
    * @Description: Handles DML errors
    * @RETURN: 
    * @param List<Database.SaveResult>     results - SaveResults of the DML             
    * @param List<Order>                   orders - Orders being updated    
    * @param String                        errorMessage - Error message to display
    */
    public void handleError(List<Database.SaveResult> results, List<Order> orders, String errorMessage){
        if(!results.isEmpty() && results != null){
            for(Integer i  = 0; i < results.size(); i++){
                if(!results.get(i).isSuccess() && results.get(i) != null){
                    orders.get(i).addError(errorMessage);
                    System.debug('Error on updating Quote.' + results.get(i).getErrors());
                }
            }
        }
    }
}