/**********************************************************
 * Auther        :  UiPath
 * CreatedBy     :  Raghu Rankawat
 * CreatedDate   :  13-Sep-2020
 * Description   :  controller class for cpqOrderProducts LWC
 *
 * Modifications :
 * [DD-MMM-YYYY] : [Name] : [Description]
 **********************************************************/

public with sharing class CPQOrderProductsController {

    public class CPQOrderProductsWrapper{
        @AuraEnabled public Order order{get;set;}
        @AuraEnabled public List<OrderItem> orderItems{get;set;}
        @AuraEnabled public List<OptionWrapper> productList{get;set;}
        @AuraEnabled public List<OptionWrapper> deploymentList{get;set;}
        @AuraEnabled public List<OptionWrapper> orchestrationTypeList{get;set;}
        @AuraEnabled public List<OptionWrapper> fieldPermissionList{get;set;}
    }

    public class OptionWrapper{
        @AuraEnabled public String label{get;set;}
        @AuraEnabled public String value{get;set;}
        
        OptionWrapper(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

    @AuraEnabled
    public static CPQOrderProductsWrapper getInitialData(String orderId){
        CPQOrderProductsWrapper wrapper = new CPQOrderProductsWrapper();

        wrapper.order = [SELECT Id, OrderNumber FROM Order WHERE Id = :orderId];

        wrapper.orderItems = [SELECT Id, Product_Version__c, Deployment_Version__c, Orchestration_type__c,
                                    License_Codes__c,SBQQ__RequiredBy__c, Product2.Name,
                                    Quantity, ServiceDate, EndDate
                                FROM OrderItem
                                WHERE OrderId = :orderId];

        wrapper.productList = getOrderProductPicklist('Product_Version__c');
        wrapper.deploymentList = getOrderProductPicklist('Deployment_Version__c');
        wrapper.orchestrationTypeList = getOrderProductPicklist('Orchestration_type__c');
        wrapper.fieldPermissionList = getOrderProductUpdateFLS(new List<String>{
            'Product_Version__c',
            'Deployment_Version__c',
            'License_Codes__c',
            'Orchestration_type__c'
        });

        return wrapper;
    }

    @AuraEnabled
    public static void saveOrderProducts(List<OrderItem> orderItems){
        try{
            update orderItems;
        }
        catch(Exception e){
            System.debug('Error : ' + e.getMessage());
            throw new AuraHandledException('Error in CPQOrderProductsController.saveOrderProducts');
        }
    }

    public static List<OptionWrapper> getOrderProductPicklist(String fieldAPI) {
        Schema.SObjectField fieldResult = Schema.sObjectType.OrderItem.fields.getMap().get(fieldAPI);
        List<OptionWrapper> pList = new List<OptionWrapper>();
        for(Schema.PicklistEntry p : fieldResult.getDescribe().getPicklistValues()){
            pList.add(new OptionWrapper(p.getLabel(), p.getValue()));
        }     
        return pList;
    }

    public static List<OptionWrapper> getOrderProductUpdateFLS(List<String> fieldList) {
        List<OptionWrapper> fList = new List<OptionWrapper>();
        for(String field : fieldList){
            Schema.SObjectField fieldResult = Schema.sObjectType.OrderItem.fields.getMap().get(field);
            if(fieldResult.getDescribe().isUpdateable()){
                fList.add(new OptionWrapper(field, 'true'));
            }
            else{
                fList.add(new OptionWrapper(field, 'false'));
            }
        }     
        return fList;
    }
}