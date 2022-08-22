@IsTest(isParallel=true)
public class EmailMessageTriggerHandler_test {
public static TestMethod void emailmessagetest(){
    EmailMessageTriggerHandler handler1 = new EmailMessageTriggerHandler();
     Id RecordTypeIdEr = SupportConstants.incidentRtId;//Schema.SObjectType.Case.getRecordTypeInfosByName().get('Incident').getRecordTypeId();
    Account objAcc = new Account();
       objAcc.Name =  'Unassigned Account';
       objAcc.RecordTypeId = Utilities.getRecordTypeId('Customer', 'Account');
       objAcc.BillingStreet = 'Test  Street';
       objAcc.BillingCity = 'Test City';
       objAcc.BillingPostalCode = '123abc';
       objAcc.BillingCountry = 'United Kingdom';
       objAcc.Phone = '12345678';
       objAcc.Industry = 'Others';
       insert objAcc;
        Contact objcontact = new Contact(LastName='Test Contact',Email='dharani@warpdrivetech.in',AccountId=objAcc.Id, Department__c = 'IT');
        insert objcontact;
        
        Case objcase= new case(ContactId=objcontact.Id,status='Closed',Closure_Classification__c ='Enhancement Request', Steps_Performed__c='Steps performed',Resolution_Provided__c='Test Resolution provided',Solution__c='Test Resolution provided',Resolution_Summary__c ='Test Resolution provided',RecordTypeId = RecordTypeIdEr,UiPath_Srl_Signer_Title__c = 'Chief Financial Officer'/*,Resolution_from_L2__c='Test Resolution_from_L2 for ER'*/,Related_To__c = 'Studio',Sub_Component__c = 'Others');   
        insert objcase;
    EmailMessage[] newEmail = new EmailMessage[0];
newEmail.add(new EmailMessage(FromAddress = 'test@abc.org', Incoming = True, ToAddress= 'hello@670ocglw7xhomi4oyr5yw2zvf.8kp7yeag.8.case.salesforce.com', Subject = 'Test email', TextBody = '23456 ', ParentId = objcase.Id)); 

insert newEmail;
        
        
    EmailMessageTriggerHandler eth= new EmailMessageTriggerHandler(false,100);
    eth.onBeforInsert(newEmail);
    
}
}