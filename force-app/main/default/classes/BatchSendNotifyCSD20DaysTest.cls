@IsTest(isParallel=false)
public class BatchSendNotifyCSD20DaysTest {

	@testSetup static void createTestData(){
 
        Profile  CSMProfile= [SELECT Id FROM Profile WHERE Name = 'Customer Success Manager'];
       
        UserRole csdRole = new UserRole(Name = 'Customer Success');
        insert csdRole;
            
        User testUser = createTestUser(csdRole.Id, CSMProfile.Id, 'Test FirstName', 'Test LastName');  
        insert testUser;
    }
    
    @isTest static void test20DaysCSDNotifictaion(){
        
	    Test.startTest();
        
        User userObj = [SELECT Id FROM User WHERE firstname = 'Test FirstName' LIMIT 1];
        
        Account accObj = new Account();
        accObj.Name =  'Test Account';
        accObj.RecordTypeId = Utilities.getRecordTypeId('Customer', 'Account');
        accObj.BillingStreet = 'Test  Street';
        accObj.BillingCity = 'Test City';
        accObj.BillingPostalCode = '123abc';
        accObj.BillingCountry = 'United Kingdom';
        accObj.Country__c = 'United Kingdom';
        accObj.Phone = '12345678';
        accObj.Industry = 'Others';
        accObj.CSD__c = userObj.Id;
            
        insert accObj;
        
        Contact contactObj = new Contact();
        contactObj.AccountId = accObj.id;
        contactObj.FirstName = 'Test';
        contactObj.LastName = String.valueOf(System.now());
        contactObj.Email = 'test123123asd@asdawe.com';
        contactObj.Title = 'Title';
        contactObj.Department__c = 'IT';
        
        insert contactObj;
        
        Id incidentRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Incident').getRecordTypeId();

        Case CaseObj = new Case(Status = 'Customer Action',Origin = 'Web',Priority='Medium',Country__c='United States',
                              Time_Zone__c ='GMT-05:00  Eastern Standard Time',RecordTypeId = incidentRecordTypeID, 
                              AccountId = accObj.Id, ContactId = contactObj.Id 
                              );
        insert CaseObj;
        
        CaseObj.Status_Customer_Action_Time_Stamp__c = System.today().addDays(-1* Integer.valueOf(Label.Customer_Action_Days_Threshold));
        
        update caseObj;
        
        String CRON_EXP = '0 0 3 * * ?';
        
	    String jobId = System.schedule('Scheulde CSD Notification 20 days', CRON_EXP, new ScheduleBatchSendNotifyCSD20Days());
        
	    CronTrigger ct = [Select Id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id=:jobId];
	    System.assertEquals(0,ct.TimesTriggered);	
        
	    Test.stopTest();

    }
    
    
    public static User createTestUser(Id roleId, Id profID, String fName, String lName)
    {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
       
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User tuser = new User(  firstname = fName,
                                lastName = lName,
                                email = uniqueName + '@test' + orgId + '.org',
                                Username = uniqueName + '@test' + orgId + '.org',
                                EmailEncodingKey = 'ISO-8859-1',
                                Alias = uniqueName.substring(18, 23),
                                TimeZoneSidKey = 'America/Los_Angeles',
                                LocaleSidKey = 'en_US',
                                LanguageLocaleKey = 'en_US',
                                ProfileId = profId,
                                UserRoleId = roleId);
        return tuser;
    }
}