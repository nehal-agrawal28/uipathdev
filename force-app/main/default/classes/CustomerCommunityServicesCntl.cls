public without sharing class CustomerCommunityServicesCntl {
    
    public static final String COMMUNITY_CASE_TYPE_INFRA = 'Infrastructure Services';
    public static final String COMMUNITY_CASE_TYPE_OPTIMIZATION = 'Optimization Services';
    public static final String COMMUNITY_CASE_TYPE_CONTACT_TECHNICAL_SUPPORT = 'Contact Technical Support';
    
    
    @AuraEnabled 
    public static user fetchUser(){
        // query current user information  
        User oUser = [select id,Name,TimeZoneSidKey,Username,Alias,Country,Email,FirstName,LastName,IsActive,IsPortalEnabled 
                      FROM User Where id =: userInfo.getUserId()];
        return oUser;
    }
	@testvisible
    private static String getCurrentUserId () {
        return String.valueOf(UserInfo.getUserId());
    }
    @testvisible
    private static User getCurrentUser (Id userId) {
        return [SELECT Id, ContactId, Account.Name, Account.Support_Technical_Advisor__c, Contact.Name, AccountId FROM USER WHERE Id =: userId 
                AND ContactId != null 
                AND AccountId != null];
    }
    public static User getCurrentUserInfo (Id userId) {
        List<User> usrList = new List<User> (
            [SELECT Id, ContactId, Account.Name, Account.Support_Technical_Advisor__c, Contact.Name, AccountId FROM USER WHERE Id =: userId 
             AND ContactId != null 
             AND AccountId != null
             AND Account.Support_Technical_Advisor__c != null]
        );
        if (usrList.size () > 0) {
            return usrList[0];
        } else {
            return null;
        }
    }
    
    @AuraEnabled
    public static Map<String,Troubleshooting_Videos__c> getVideoLinks(){
        MAp<String,Troubleshooting_Videos__c> allVideoLinks = Troubleshooting_Videos__c.getAll();
        return allVideoLinks;
    }    
    
    @AuraEnabled
    public static string caseNumber(String recordId){
        Case caseCreated = [Select id,casenumber from Case where id=:recordId];
        return caseCreated.casenumber;
    }
    @AuraEnabled
    public static String getAccountInfo() {
        Map<String, Object> resMap = new Map <String, Object> ();
        try {
            List<User> userList = [SELECT Id, Name,ContactId,Contact.Name, AccountId, Account.Name, Account.Maintenance_Flag__c, Account.requests_this_quarter__c,Account.of_Proactive_services__c,
                                   Account.Recordtype.Name,Account.Support_Technical_Advisor__c,Account.Max_of_Services_Quarter__c
                                   FROM User 
                                   WHERE Id = :userInfo.getUserId() AND AccountId != null];
            if (userList.size() > 0) {
                resMap.put ('status', true);
                resMap.put ('result', userList[0]);
            } else {
                resMap.put ('status', false);
                resMap.put ('errorMessage', 'No such user found');
            }
        } catch (Exception e) {
            resMap.put ('status', false);
            resMap.put ('errorMessage', 'Exception :' + e.getStackTraceString() + '\n' + e.getMessage());
        }        
        return JSON.serialize(resMap);
    }
    
    @AuraEnabled
    public static String createTask(String taskType) {
        System.debug('Task :' + taskType);
        Map<String, Object> resMap = new Map <String, Object> ();
        if (String.isBlank(taskType)) {
            resMap.put ('status', false);
            resMap.put ('errorMessage', 'Empty task type');
        } else {
            User currentUser = getCurrentUserInfo (getCurrentUserId());
            
            if (currentUser != null) {
                String subject = '';
                String description = '';
                if (taskType.toLowerCase().equalsIgnoreCase ('infra') ) {
                    resMap.put ('status', true);
                    subject = currentUser.Account.Name + '\'s ' + currentUser.Contact.Name  + ' ' + Label.Customer_community_task_subject_additional_text + ' '  + COMMUNITY_CASE_TYPE_INFRA ;
                    description = currentUser.Account.Name + '\'s ' + currentUser.Contact.Name  + ' ' + Label.Customer_community_task_description_additional_text + ' ' + COMMUNITY_CASE_TYPE_INFRA;
                    createTask (COMMUNITY_CASE_TYPE_INFRA, currentUser.Id, subject, description);
                    //resMap.putAll (createNewTask (COMMUNITY_CASE_TYPE_INFRA, currentUser));
                } else if (taskType.toLowerCase().equalsIgnoreCase ('optimization')) {
                    resMap.put ('status', true);
                    subject = currentUser.Account.Name + '\'s ' + currentUser.Contact.Name  + ' ' + Label.Customer_community_task_subject_additional_text + ' '  + COMMUNITY_CASE_TYPE_OPTIMIZATION ;
                    description = currentUser.Account.Name + '\'s ' + currentUser.Contact.Name  + ' ' + Label.Customer_community_task_description_additional_text + ' ' + COMMUNITY_CASE_TYPE_OPTIMIZATION;                    
                    createTask (COMMUNITY_CASE_TYPE_OPTIMIZATION, currentUser.Id, subject, description);
                    //resMap.putAll (createNewTask (COMMUNITY_CASE_TYPE_OPTIMIZATION, currentUser));
                } else if (taskType.toLowerCase().equalsIgnoreCase ('contactTechnicalAdvisor')) {
                    resMap.put ('status', true);
                    subject = currentUser.Account.Name + '\'s ' + currentUser.Contact.Name  + ' ' + Label.Customer_community_task_subject_additional_text_for_contact_support ;
                    description = currentUser.Account.Name + '\'s ' + currentUser.Contact.Name  + ' ' + Label.Customer_community_task_description_additional_text_for_contact_support ;  
                    createTask (COMMUNITY_CASE_TYPE_CONTACT_TECHNICAL_SUPPORT, currentUser.Id, subject, description);
                    //resMap.putAll (createNewTask (COMMUNITY_CASE_TYPE_CONTACT_TECHNICAL_SUPPORT, currentUser));
                } else {
                    resMap.put ('status', false);
                    resMap.put ('errorMessage', 'cannot match the task type');
                }   
            } else {
                resMap.put ('status', false);
                resMap.put ('errorMessage', 'POC user is not specified');
                resMap.putAll (getTaskCount(getCurrentUser(getCurrentUserId())));
            } 
        }
        return JSON.serialize(resMap);
    }
    //Added by Dharani 24-05-2019 for Premium service in community
    @AuraEnabled
    public static List<String> getServiceTypes() {
        List<String> pickListValuesList = new List<String>();
        Schema.DescribeFieldResult fieldResult = Premium_Service__c.Service_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
            System.debug('Values in Rating are: '+pickListValuesList);
        }     
        return pickListValuesList;
    }
    @AuraEnabled
    public static String getRecordType() {
        String recordTypeId = SupportConstants.proactiveRtId;
        return recordTypeId;
    }
    
    //Added by Dharani 24-05-2019 for Premium service in community
    @AuraEnabled
    public static Case createPremiumServiceCase(Date stDate, String descr, String subject)
    { 
        Map<String, Object> resMap = new Map <String, Object> ();
        
        Id userid=userinfo.getUserId();
        User currentUser = getCurrentUserInfo (getCurrentUserId());
        
        Account currentAccount = [Select id,Support_Technical_Advisor__c, of_Proactive_services__c,requests_this_quarter__c from Account where id = :currentUser.AccountId];
        if (currentUser!=null)
        {
            
            Case premiumServicecase= new case();
            premiumServicecase.subject= subject;
            premiumServicecase.Case_Web_Form_Region__c='Premium Service';
            premiumServicecase.RecordTypeId=Supportconstants.proactiveRtId;
            premiumServicecase.Origin='Community';
            premiumServicecase.ContactId=currentUser.ContactId;
            premiumServicecase.Description= descr;
            premiumServicecase.Start_Date__c = stDate;
            premiumServicecase.ownerId = currentAccount.Support_Technical_Advisor__c;
            
            try
            {
                insert premiumServicecase ;
                premiumServicecase=[Select Id,CaseNumber from case where Id=:premiumServicecase.Id];
            }
            catch(exception e)
            {
                throw new AuraHandledException(e.getMessage());
            }
            
            return premiumServicecase;            
        }
        return null;
    }
    
    //Added by Akash on 16.09.2019
    @AuraEnabled
    public static List<ServiceMdtWrapper> getQuestionsforDescription(String accountType)
    {
        system.debug('accountType'+accountType);
        
        List<ServiceMdtWrapper> questions= new List<ServiceMdtWrapper>();
        String startingString = '';
        List<Premium_Services__mdt> PSList ;
        if(accountType.toLowerCase() == 'premium'){
            startingString = 'PCS';
            PSList = new List<Premium_Services__mdt>([Select servicetypes__c,Service_Type_description__c,Request_Type__c,Position__c from Premium_Services__mdt where Service_type__c = 'Premium' order by Position__c asc]);
        }
        
        else if(accountType.toLowerCase() == 'partner'){
            startingString = 'PS';
            PSList = new List<Premium_Services__mdt>([Select servicetypes__c,Service_Type_description__c,Request_Type__c,Position__c from Premium_Services__mdt where Service_type__c = 'Partner' order by Position__c]);
        }
        
        else if(accountType.toLowerCase() == 'customer'){
            startingString = 'CS';
            PSList = new List<Premium_Services__mdt>([Select servicetypes__c,Service_Type_description__c,Request_Type__c,Position__c from Premium_Services__mdt where Service_type__c = 'Customer' order by Position__c]);
        }
        
        
        system.debug('PSList '+ PSList);
        if(PSlist!=null)
        {
            For(Premium_Services__mdt ps:PSList)
            {
                ServiceMdtWrapper wrapper= new ServiceMdtWrapper();
                if(wrapper.Servicedesc == null)
                    wrapper.Servicedesc=ps.Service_Type_description__c;
                if(wrapper.ServiceType == null)
                    wrapper.ServiceType= ps.servicetypes__c;
                if(wrapper.RequestType == null)
                    wrapper.RequestType= ps.Request_Type__c;
                questions.add(wrapper);
            }
        }
        system.debug('questions '+ questions);
        return questions;
    }
    
    
    public class ServiceMdtWrapper{
        @AuraEnabled  public string Servicedesc{get;set;}
        @AuraEnabled  public string RequestType{get;set;}
        @AuraEnabled public String ServiceType{get;set;}   
    }
    //Added by dharani on 31/05/2019 for creation creation on community via technical advisor
    @AuraEnabled
    public static Case createCaseForTechnicalAdvisor(String ServiceType)
    {
        case returnresponse;
        Case premiumServicecase=new  Case();
        User currentUser = getCurrentUserInfo (getCurrentUserId());
        if (currentUser!=null){
            premiumServicecase.subject = currentUser.Account.Name + '\'s ' + currentUser.Contact.Name  + ' ' + Label.Customer_community_task_subject_additional_text_for_contact_support ;
            premiumServicecase.description = currentUser.Account.Name + '\'s ' + currentUser.Contact.Name  + ' ' + Label.Customer_community_task_description_additional_text_for_contact_support ;  
            premiumServicecase.Case_Web_Form_Region__c='Premium Service';
            premiumServicecase.RecordTypeId=Supportconstants.incidentRtId;
            premiumServicecase.Origin='Community';
            premiumServicecase.ContactId=currentUser.ContactId;  
            AssignmentRule AR = new AssignmentRule();
            
            AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
            premiumServicecase.setOptions(dmlOpts);
            system.debug(premiumServicecase);
            try{
                insert premiumServicecase;
                premiumServicecase=[Select Id,CaseNumber from case where Id=:premiumServicecase.Id];  
                return  returnresponse=premiumServicecase;
            }
            catch(exception e)
            {
                return null;
            }
            
        }
        else
        {
            return null;
        }
    }
    
    
    @future
    public static void createTask (String taskType, Id userId, String subject, String description) {
        Map<String, Object> res = createNewTask (taskType, getCurrentUserInfo (userId), subject, description);
        System.debug('Task :' + res);
    }
    
    public static Map<String, Object> createNewTask  (String taskType, User usr, String subject, String description) {
        Map<String, Object> resMap = new Map <String, Object> ();    
        Task tempTask = new Task ();
        tempTask.Subject = subject;
        tempTask.WhatId = usr.AccountId;
        tempTask.WhoId = usr.ContactId;
        tempTask.Status = 'Open';
        tempTask.Type = 'Call';
        tempTask.Community_Case_Type__c = taskType;
        tempTask.ActivityDate = System.today().addDays (Integer.valueOf(Label.Customer_Community_Task_Due_days));
        tempTask.OwnerId = usr.Account.Support_Technical_Advisor__c;
        tempTask.Description = description;
        
        Database.SaveResult res = Database.insert(tempTask, false);
        System.debug('tempTask :' + tempTask);
        System.debug('res :' + res);
        if (res.isSuccess()) {
            resMap.put ('status', true);
        } else {
            resMap.put ('status', false);            
        }
        resMap.putAll (getTaskCount (usr));
        return resMap;
    }
    
    @AuraEnabled
    public static String getLatestTaskCount () {
        return JSON.serialize(getTaskCount(getCurrentUser(getCurrentUserId())));
    }
    
    private static Map<String, String> getTaskCount (User usr) {
        Map<String, String> resMap = new Map <String, String> ();    
        for (AggregateResult a : [Select Count(Id) TotalItem, Community_Case_Type__c 
                                  FROM Task
                                  WHERE CreatedDate = Today 
                                  AND WhoId =: usr.ContactId 
                                  AND WhatId =: usr.AccountId
                                  AND Community_Case_Type__c != null 
                                  Group By Community_Case_Type__c]) {
                                      resMap.put (String.valueOf(a.get('Community_Case_Type__c')), String.valueOf(a.get ('TotalItem')));
                                  }
        System.debug('ResMap :' + resMap);
        return resMap;
    }
}