@isTest
private class CustomerCommunityServicesCntlTest {
    @TestSetup
    private static void setUpData() {
        User portalAccountOwner = createPortalAccountOwner_1();  
        createCommunityUser_1(portalAccountOwner); 
        
        portalAccountOwner = createPortalAccountOwner();  
        createCommunityUser(portalAccountOwner); 
    }
    
    private static User createPortalAccountOwner_1() {  
        UserRole portalRole = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role', PortalType='None' );  
        insert portalRole;  
        System.debug('portalRole is ' + portalRole);  
        Profile sysAdminProfile = [Select Id from Profile where name = 'System Administrator'];  
        User portalAccountOwner = new User(  
            UserRoleId = portalRole.Id,  
            ProfileId = sysAdminProfile.Id,  
            Username = 'portalOwner.admin.cool@test.com',  
            Alias = 'Alias',  
            Email='portal.owner@test.com',  
            EmailEncodingKey='UTF-8',  
            Firstname='Portal',  
            Lastname='Owner',  
            LanguageLocaleKey='en_US',  
            LocaleSidKey='en_US',  
            TimeZoneSidKey = 'America/Los_Angeles'  
        );  
        Database.insert(portalAccountOwner);  
        return portalAccountOwner;  
    }  
    private static void createCommunityUser_1(User portalAccountOwner) {  
        System.runAs ( portalAccountOwner ) {  
            //Create account  
            Account newAccount = new Account (Name = 'Raj');
            newAccount.RecordTypeId = Utilities.getRecordTypeId('Customer', 'Account');
            newAccount.BillingStreet = 'Test  Street';
            newAccount.BillingCity = 'Test City';
            newAccount.BillingPostalCode = '123abc';
            newAccount.BillingCountry = 'United Kingdom';
            newAccount.Phone = '12345678';
            newAccount.Industry = 'Others';
            newAccount.Maintenance_Flag__c = 'Premium';
            newAccount.Support_Technical_Advisor__c = portalAccountOwner.Id;
            Database.insert(newAccount);  
            //Create contact  
            
            Contact c = new Contact (LastName = 'Tesr', AccountId = newAccount.Id, Email='portalContact' + System.currentTimeMillis() + '@test.com', Department__c = 'IT');
            Database.insert(c);  
            
            User communityUser = new User(  
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User'].Id,  
                FirstName = 'CommunityUserFirst',  
                LastName = 'CommunityUserLast',  
                Email = 'community.usertettest@test.com',  
                Username = 'community.user.test@test.com',  
                Title = 'Title',  
                Alias = 'Alias',  
                TimeZoneSidKey = 'America/Los_Angeles',  
                EmailEncodingKey = 'UTF-8',  
                LanguageLocaleKey = 'en_US',  
                LocaleSidKey = 'en_US',  
                ContactId = c.id  
            );  
            Database.insert(communityUser);  
        }  
    }
    
    private static User createPortalAccountOwner() {  
        UserRole portalRole = new UserRole(DeveloperName = 'MyCustomRole_1', Name = 'My Role', PortalType='None' );  
        insert portalRole;  
        Profile sysAdminProfile = [Select Id from Profile where name = 'System Administrator'];  
        User portalAccountOwner = new User(  
            UserRoleId = portalRole.Id,  
            ProfileId = sysAdminProfile.Id,  
            Username = 'portalOwner.admin.cool_1@test.com',  
            Alias = 'Alias',  
            Email='portal.owner@test.com',  
            EmailEncodingKey='UTF-8',  
            Firstname='Portal',  
            Lastname='Owner',  
            LanguageLocaleKey='en_US',  
            LocaleSidKey='en_US',  
            TimeZoneSidKey = 'America/Los_Angeles'  
        );  
        Database.insert(portalAccountOwner);  
        return portalAccountOwner;  
    }  
    private static void createCommunityUser(User portalAccountOwner) {  
        System.runAs ( portalAccountOwner ) {  
            //Create account  
            Account newAccount = new Account (Name = 'Rajkum');
            newAccount.RecordTypeId = Utilities.getRecordTypeId('Customer', 'Account');
            newAccount.BillingStreet = 'Test  Street';
            newAccount.BillingCity = 'Test City';
            newAccount.BillingPostalCode = '123abc';
            newAccount.BillingCountry = 'United Kingdom';
            newAccount.Phone = '12345678';
            newAccount.Industry = 'Others';
            newAccount.Maintenance_Flag__c = 'Premium';
            Database.insert(newAccount);  
            //Create contact  
            
            Contact c = new Contact (LastName = 'Tesr', AccountId = newAccount.Id, Email='portalContact' + System.currentTimeMillis() + '@test.com', Department__c = 'IT');
            Database.insert(c);  
            
            User communityUser = new User(  
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User'].Id,  
                FirstName = 'CommunityUserFirst',  
                LastName = 'CommunityUserLast',  
                Email = 'community.user.test_noPOC@test.com',  
                Username = 'community.user.test_noPOC@test.com',  
                Title = 'Title',  
                Alias = 'Alias',  
                TimeZoneSidKey = 'America/Los_Angeles',  
                EmailEncodingKey = 'UTF-8',  
                LanguageLocaleKey = 'en_US',  
                LocaleSidKey = 'en_US',  
                ContactId = c.id  
            );  
            Database.insert(communityUser);  
        }  
    }
    @isTest
    public static void test_1 () {
        User communityUser = [SELECT Id from USer where userName = 'community.user.test@test.com'];
        system.runAs(communityUser) {
            CustomerCommunityServicesCntl.getAccountInfo ();
            String res = CustomerCommunityServicesCntl.createTask ('infra');
            Map<String, Object> resMap =   (Map<String, Object>) JSON.deserializeUntyped(res);
            System.assertEquals(true, resMap.get('status'));
        }
    }
    @isTest
    public static void test_3 () {
        User communityUser = [SELECT Id from USer where userName = 'community.user.test@test.com'];
        system.runAs(communityUser) {
            CustomerCommunityServicesCntl.getAccountInfo ();
            String res = CustomerCommunityServicesCntl.createTask ('optimization');
            Map<String, Object> resMap =   (Map<String, Object>) JSON.deserializeUntyped(res);
            System.assertEquals(true, resMap.get('status'));
        }
    }
    @isTest
    public static void test_4 () {
        User communityUser = [SELECT Id from USer where userName = 'community.user.test@test.com'];
        system.runAs(communityUser) {
            CustomerCommunityServicesCntl.getAccountInfo ();
            String res = CustomerCommunityServicesCntl.createTask ('contactTechnicalAdvisor');
            Map<String, Object> resMap =   (Map<String, Object>) JSON.deserializeUntyped(res);
            System.assertEquals(true, resMap.get('status'));
        }
    }
    @isTest
    public static void test_blnak_taskType () {
        User communityUser = [SELECT Id from USer where userName = 'community.user.test@test.com'];
        system.runAs(communityUser) {
            CustomerCommunityServicesCntl.getAccountInfo ();
            String res = CustomerCommunityServicesCntl.createTask ('');
            Map<String, Object> resMap =   (Map<String, Object>) JSON.deserializeUntyped(res);
            System.assertEquals(false, resMap.get('status'));
            System.assertEquals('Empty task type', resMap.get('errorMessage'));
        }
    }
    @isTest
    public static void test_no_poc_user () {
        User communityUser = [SELECT Id from USer where userName = 'community.user.test_noPOC@test.com'];
        system.runAs(communityUser) {
            CustomerCommunityServicesCntl.getAccountInfo ();
            String res = CustomerCommunityServicesCntl.createTask ('contactTechnicalAdvisor');
            Map<String, Object> resMap =   (Map<String, Object>) JSON.deserializeUntyped(res);
            System.assertEquals(false, resMap.get('status'));
            System.assertEquals('POC user is not specified', resMap.get('errorMessage'));
        }
    }
    @isTest
    public static void test_invalid_task_type () {
        User communityUser = [SELECT Id from USer where userName = 'community.user.test@test.com'];
        system.runAs(communityUser) {
            CustomerCommunityServicesCntl.getAccountInfo ();
            String res = CustomerCommunityServicesCntl.createTask ('contactTechn');
            Map<String, Object> resMap =   (Map<String, Object>) JSON.deserializeUntyped(res);
            System.assertEquals(false, resMap.get('status'));
            System.assertEquals('cannot match the task type', resMap.get('errorMessage'));
        }
    }
    @isTest
    public static void test_getLatest_task_count () {
        User communityUser = [SELECT Id from USer where userName = 'community.user.test@test.com'];
        system.runAs(communityUser) {
            CustomerCommunityServicesCntl.getAccountInfo ();
            String res = CustomerCommunityServicesCntl.getLatestTaskCount();
        }
    }
    @isTest
    public static void test_task_creation_failure () {
        User communityUser = [SELECT Id from USer where userName = 'community.user.test@test.com'];
        system.runAs(communityUser) {
            CustomerCommunityServicesCntl.createNewTask(CustomerCommunityServicesCntl.COMMUNITY_CASE_TYPE_INFRA, 
                                                        CustomerCommunityServicesCntl.getCurrentUserInfo(UserInfo.getUserId()),
                                                        'Some task',
                                                        'some description');
        }
    }
    @isTest
    public static void test_2 () {
        User adminUser = [SELECT Id from USer where userName = 'portalOwner.admin.cool@test.com'];
        system.runAs(adminUser) {
            CustomerCommunityServicesCntl.getAccountInfo ();
        }
    }
    
    @isTest
    public static void premiumcasereationTest(){
        
        User communityUser = [SELECT Id from USer where userName = 'community.user.test@test.com']; 
        system.runAs(communityUser) {
            Test.startTest();
            Case caseObj = CustomerCommunityServicesCntl.createPremiumServiceCase(Date.today(), 'Test Desc','Test Subject');
            String caseNum = CustomerCommunityServicesCntl.caseNumber(String.valueof(caseObj.Id));
            List<String> serviceTypes = CustomerCommunityServicesCntl.getServiceTypes();
            String recType = CustomerCommunityServicesCntl.getRecordType();
            Case premCase = CustomerCommunityServicesCntl.createCaseForTechnicalAdvisor('premium');
            system.assert(caseObj.Id != null);
            system.assert(string.isNotBlank(caseNum));
            Test.stopTest();
            
        }
    }
        
    @isTest
    public static void fetchUserTest(){
        
        Test.startTest();
        User userObj = CustomerCommunityServicesCntl.fetchUser();
        String userId = CustomerCommunityServicesCntl.getCurrentUserId();
        Map<String,Troubleshooting_Videos__c> videos = CustomerCommunityServicesCntl.getVideoLinks();
        List<CustomerCommunityServicesCntl.ServiceMdtWrapper> reqQuestspremium = CustomerCommunityServicesCntl.getQuestionsforDescription('premium');
        List<CustomerCommunityServicesCntl.ServiceMdtWrapper> reqQuestspartner = CustomerCommunityServicesCntl.getQuestionsforDescription('partner');
        List<CustomerCommunityServicesCntl.ServiceMdtWrapper> reqQuestscustomer = CustomerCommunityServicesCntl.getQuestionsforDescription('customer');
        system.assert(userObj.Id != null);
        system.assert(String.isNotblank(userId));
        Test.stopTest();
        
    }

}