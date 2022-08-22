/**
* @File Name          : BatchSendNotifyCSD20Days.cls
* @Description        : SLTECH-7980 If case is in CA for > than 20 days - 
						send email notification to CSDs to that Account
* @Author             : 
* @Group              : 
* @Last Modified By   : 
* @Last Modified On   : 9/17/2020.
* @Modification Log   : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0    	9/17/2020  						     			Initial Version
**/
public class BatchSendNotifyCSD20Days implements Database.Batchable<sObject>{
    
    public OrgWideEmailAddress orgWideAddObj;
    public EmailTemplate templateId;
    public final String ORG_WIDE_ADDRESS = Label.UIPathOrgWideAddress;
    public final String EMAIL_TEMPLATE_NAME = Label.Notify20DaysCSDEmailTemplate;
    public final Boolean ARG_FALSE = FALSE;
    public Id incidentRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Incident').getRecordTypeId();

    public BatchSendNotifyCSD20Days(){
        orgWideAddObj = [ SELECT Id, DisplayName, Address from OrgWideEmailAddress WHERE Address= :ORG_WIDE_ADDRESS ];
        templateId = [ SELECT Id,Subject,Htmlvalue from EmailTemplate WHERE DeveloperName = :EMAIL_TEMPLATE_NAME ];
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        Date thresholdDate = System.today().addDays(-1* Integer.valueOf(Label.Customer_Action_Days_Threshold));
        return Database.getQueryLocator('SELECT Id, Subject, ContactId, Contact.Email, Account.Name, CaseNumber, Related_To__c, Account.CSD__r.Email, Account.CSD__c, Account.CSD__r.Id FROM CASE WHERE Account.CSD__r.isActive=True AND RecordTypeId =:incidentRecordTypeId AND Status=\'Customer Action\' AND DAY_ONLY(Status_Customer_Action_Time_Stamp__c) = :thresholdDate');
    }
    
    public void execute(Database.BatchableContext bc, List<Case> scope){
        
        List<Messaging.SingleEmailMessage> emailMessagesList = new List<Messaging.SingleEmailMessage>();
        List<Messaging.SingleEmailMessage> lstMsgsToSend = new List<Messaging.SingleEmailMessage>();
        for( Case caseObj : scope ){
            
            if( NULL != caseObj.Account.CSD__c ){
                Messaging.SingleEmailMessage mailObj = new Messaging.SingleEmailMessage();
                
                mailObj.setTemplateID(templateId.Id);
                mailObj.setSaveAsActivity(ARG_FALSE);
                mailObj.setWhatId(caseObj.Id);
                mailObj.setTargetObjectId(caseObj.ContactId); 
                mailObj.setToAddresses(new String[] { caseObj.Account.CSD__r.Email}); 
                mailObj.setOrgWideEmailAddressId(orgWideAddObj.id);
                
                emailMessagesList.add(mailObj);
                
            }
        }
        Savepoint sp = Database.setSavepoint();
        
        if( NULL != emailMessagesList && emailMessagesList.size() > 0  )
        	Messaging.sendEmail(emailMessagesList,false);
        
        Database.rollback(sp);
        
        //Sending Emails to Non-Contacts
        
        
        for (Messaging.SingleEmailMessage email : emailMessagesList) {
            Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
            emailToSend.setToAddresses(email.getToAddresses());
            emailToSend.setPlainTextBody(email.getPlainTextBody());
            emailToSend.setHTMLBody(email.getHTMLBody());
            emailToSend.setSubject(email.getSubject());
            emailToSend.setOrgWideEmailAddressId(orgWideAddObj.id);
            lstMsgsToSend.add(emailToSend);
        }
        
        try{
            if(null != lstMsgsToSend && lstMsgsToSend.size() > 0 ){
                if(!test.isRunningTest())
            		Messaging.sendEmail(lstMsgsToSend);
            }
        }catch(Exception error){
            throw (error);
        }  
        
        
    }
    
    public void finish(Database.BatchableContext bc){
        
    }   
}