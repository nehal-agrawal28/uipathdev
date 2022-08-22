@IsTest(isParallel=true)
public class Ui_PickListController_test {
    
    public static testmethod void testmethod1()
    {
       String rtid = SupportConstants.incidentRtId;
       List<PickListValueWrapper> pvw =Ui_PickListController.picklistValuesByRecordType('case','Related_To__c',rtid);
       
        Ui_PickListController uopc=Ui_PickListController.parse('{ "_id" : "5c0693b62e4f6a7cbe39e438", "assignee" : { "id" : 116029920451, "name" : "Kiran Rao", "email" : "kiran.rao@uipath.com" } }');
        Ui_PickListController.Values v= new Ui_PickListController.Values();
    }
    

}