global class BatchToAutoCloseCaseFromCA implements Database.Batchable<sObject>, Database.Stateful{
    
    public Map<String,String> failedRecords;
    
    global BatchToAutoCloseCaseFromCA(){
        failedRecords = new Map<String,String>();
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        List<String> recordTypeNames = Label.Case3StrikeRuleRecordTypes.split(',');
        List<String> recordTypeIds = new List<String>();
        
        for(String recordTypeName : recordTypeNames){
            recordTypeIds.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId());
        }
        
        Date dateToConsider = System.today().addDays(-1* Integer.valueOf(Label.CaseAutoCloseFromCADays));
        String query;
        if(Test.isRunningTest()){
            query = 'Select Id, CaseNumber, Status, Status_Customer_Action_Time_Stamp__c, ContactId, Contact.Name, Contact.Email, SuppliedEmail, SuppliedName from Case where RecordTypeId in :recordTypeIds';
        }else{
            query = 'Select Id, CaseNumber, Status, Status_Customer_Action_Time_Stamp__c, ContactId, Contact.Name, Contact.Email, SuppliedEmail, SuppliedName from Case where RecordTypeId in :recordTypeIds and Origin!=\'Email\' and Status=\'Customer Action\' and DAY_ONLY(Status_Customer_Action_Time_Stamp__c) = :dateToConsider and Status_Sub_Category__c=\'3 Strike Rule\'';
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Case> scope){
        CaseMetadata_SV.isAutoCloseBatch = true;
        List<Case> casesToUpdate = new List<Case>();
        for(Case caseInScope : scope){
        	caseInScope.Status = 'Closed';
            caseInScope.Auto_Closed__c = true;
            casesToUpdate.add(caseInScope);
        }
        
        Database.SaveResult[] saveResults = Database.update(casesToUpdate, false);
        for(integer i=0;i < casesToUpdate.size(); i++){
            Case caseToUpdate = casesToUpdate[i];
            Database.SaveResult saveResult = saveResults[i];
            if(!saveResult.isSuccess() && !saveResult.getErrors().isEmpty()){
                failedRecords.put(caseToUpdate.CaseNumber,saveResult.getErrors()[0].getMessage());
            }
        }
        
    }
    
    global void finish(Database.BatchableContext bc){
        if(failedRecords!=null && !failedRecords.isEmpty()){
            OrgWideEmailAddress owa = [ SELECT Id, DisplayName, Address from OrgWideEmailAddress WHERE Address= 'uipathsupport@uipath.com' ];
            EmailTemplate template = [ SELECT Id,Subject,Htmlvalue from EmailTemplate WHERE DeveloperName = 'Case_Auto_Close_Errors' ];
            List<Messaging.SingleEmailMessage> lstMsgsToSend = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage mailObj = new Messaging.SingleEmailMessage();
            mailObj.setSubject(template.Subject);
            String tableValues = '';
            integer counter = 1;
            for(String failedRecord : failedRecords.keySet()){
                tableValues = tableValues + '<tr><td>'+counter+'</td><td>'+failedRecord+'</td><td>'+failedRecords.get(failedRecord)+'</td></tr>';
                counter++;
            }
            String htmlBody = template.HtmlValue.replace('{!tableValues}',tableValues);
            mailObj.setHtmlBody(htmlBody);
            mailObj.setSaveAsActivity(false);
            
            mailObj.setToAddresses(System.Label.SurveyErrorEmailRecepients.split(',')); 
            mailObj.setOrgWideEmailAddressId(owa.id);
            
            lstMsgsToSend.add(mailObj);
            Messaging.sendEmail(lstMsgsToSend);
        }
    }
    
    
}