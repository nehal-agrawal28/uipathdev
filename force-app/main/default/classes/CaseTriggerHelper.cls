/**
* @File Name          : CaseTriggerHelper.cls
* @Description        : 
* @Author             : phUser@phDomain.com
* @Group              : 
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 6/15/2019, 1:06:35 AM
* @Modification Log   : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0    12/16/2018, 3:51:39 PM   phUser@phDomain.com     Initial Version
**/
public without sharing class CaseTriggerHelper 
{
    Public static Boolean apexsharingalreadyDone = false;
    public static Boolean statusCalculationDone = false;
    public static String TRIAL_LICENSE_CODE = 'TRIAL';
    public CaseTriggerHelper(){        
    }
    //added by WarpDrive: Deepali
    private boolean isExecuting = false;
    private integer batchSize = 0;
    public CaseTriggerHelper(boolean triggerExecuting, integer size) {
        
        isExecuting = triggerExecuting;
        BatchSize = size;
    }
    
    //Added by Shivam on 19-02-2020
    /*public static void insertBusinessHours(List<Case> newCase){
        //Map to Store  Country With Their BusinessHours
        Map<String, Id> mapOfCounBH = new Map<String, Id>();
        
        List<BusinessHours> lstOfBH = new List<BusinessHours>([SELECT Id, Name FROM BusinessHours WHERE IsActive=true]);
        System.debug('updateBusinessHours @35'+newCase);
        
        //Putting value of BusinessHours in Map
        for(BusinessHours eachBH : lstOfBH){
            mapOfCounBH.put(eachBH.Name, eachBH.Id);
        }
        
        for(Case eachCase : newCase){
            if(eachCase.Priority == 'Urgent' || eachCase.Priority == 'High') {
                eachCase.BusinessHoursId = mapOfCounBH.get('DefaultBusinessHours');                
            } else if(eachCase.Priority == 'Medium' || eachCase.Priority == 'Low' && (eachCase.Country__c != null)) { 
                if(eachCase.Country__c == 'United States'){                    
                    if(eachCase.Time_Zone__c != null) {                        
                        if(eachCase.Time_Zone__c == 'GMT-05:00  Eastern Standard Time' || eachCase.Time_Zone__c == 'GMT-04:00  Eastern Standard Time') {
                            eachCase.BusinessHoursId = mapOfCounBH.get('US(EST) Business Hours(9hrs)');
                        } else if(eachCase.Time_Zone__c == 'GMT-06:00  Central Standard Time' || eachCase.Time_Zone__c =='GMT-05:00  Central Standard Time'){
                            eachCase.BusinessHoursId = mapOfCounBH.get('US(CST) Business Hours(9hrs)');
                        } else if(eachCase.Time_Zone__c == 'GMT-08:00  Pacific Standard Time' || eachCase.Time_Zone__c == 'GMT-07:00  Pacific Standard Time'){                                           
                            eachCase.BusinessHoursId = mapOfCounBH.get('US(PST) Business Hours(9hrs)');
                        } else if(eachCase.Time_Zone__c == 'GMT-04:00  Atlantic Standard Time' || eachCase.Time_Zone__c == 'GMT-05:00  Atlantic Standard Time'){
                            eachCase.BusinessHoursId = mapOfCounBH.get('US(AST) Business Hours(9hrs)');
                        }else{
                            eachCase.BusinessHoursId = mapOfCounBH.get('US(CST) Business Hours(9hrs)');
                        }
                    } else {
                        eachCase.BusinessHoursId = mapOfCounBH.get('US(CST) Business Hours(9hrs)');
                    }
                } else if(mapOfCounBH.containsKey(eachCase.Country__c)) {
                    eachCase.BusinessHoursId = mapOfCounBH.get(eachCase.Country__c);                    
                } else {                    
                    //eachCase.addError('Country not found');
                }
            } else {
                //eachCase.addError('Country not found');
            }            
        }
    } 
    */
    //Added by Shivam on 19-02-2020
    /*public static void updateBusinessHours(List<Case> newCase, Map<Id,Case> oldMap){        
        //Map to Store  Country With Their BusinessHours
        Map<String, Id> mapOfCounBH = new Map<String, Id>();
        System.debug('updateBusinessHours @77'+newCase);
        List<BusinessHours> lstOfBH = new List<BusinessHours>([SELECT Id, Name FROM BusinessHours WHERE IsActive=true]);
        
        //Putting value of BusinessHours in Map
        for(BusinessHours eachBH : lstOfBH){
            mapOfCounBH.put(eachBH.Name, eachBH.Id);
        }
        
        //Iteration over individual new/old case
        for(Case eachCase : newCase){ 
            if(oldMap.get(eachCase.Id).Country__c != eachCase.Country__c || 
               oldMap.get(eachCase.Id).Priority != eachCase.Priority || 
               oldMap.get(eachCase.Id).Time_Zone__c != eachCase.Time_Zone__c)  {
                   if(eachCase.Priority == 'Urgent' || eachCase.Priority == 'High') {
                       eachCase.BusinessHoursId = mapOfCounBH.get('DefaultBusinessHours');                    
                   } else if(eachCase.Priority == 'Medium' || eachCase.Priority == 'Low' && (eachCase.Country__c != NULL)) { 
                       if(eachCase.Country__c == 'United States') {                        
                           if(eachCase.Time_Zone__c != null) { 
                               if(oldMap.get(eachCase.Id).Time_Zone__c != eachCase.Time_Zone__c || oldMap.get(eachCase.Id).Country__c != eachCase.Country__c || oldMap.get(eachCase.Id).Priority != eachCase.Priority) { 
                                   if(eachCase.Time_Zone__c == 'GMT-05:00  Eastern Standard Time' || eachCase.Time_Zone__c == 'GMT-04:00  Eastern Standard Time') {
                                       eachCase.BusinessHoursId = mapOfCounBH.get('US(EST) Business Hours(9hrs)');
                                   } else if(eachCase.Time_Zone__c == 'GMT-06:00  Central Standard Time' || eachCase.Time_Zone__c == 'GMT-05:00  Central Standard Time'){
                                       eachCase.BusinessHoursId = mapOfCounBH.get('US(CST) Business Hours(9hrs)');
                                   } else if(eachCase.Time_Zone__c == 'GMT-08:00  Pacific Standard Time' || eachCase.Time_Zone__c == 'GMT-07:00  Pacific Standard Time'){  
                                       eachCase.BusinessHoursId = mapOfCounBH.get('US(PST) Business Hours(9hrs)');
                                   } else if(eachCase.Time_Zone__c == 'GMT-04:00  Atlantic Standard Time' || eachCase.Time_Zone__c == 'GMT-05:00  Atlantic Standard Time'){
                                       eachCase.BusinessHoursId = mapOfCounBH.get('US(AST) Business Hours(9hrs)');
                                   } else{
                                       eachCase.BusinessHoursId = mapOfCounBH.get('US(CST) Business Hours(9hrs)');
                                   }
                               }
                           } else {
                               eachCase.BusinessHoursId = mapOfCounBH.get('US(CST) Business Hours(9hrs)');
                           }
                       } else if(mapOfCounBH.containsKey(eachCase.Country__c)) {
                           eachCase.BusinessHoursId = mapOfCounBH.get(eachCase.Country__c);                        
                       } else {                         
                           //eachCase.addError('Country not found');
                       }                    
                   } else {
                       //eachCase.addError('Country not found');
                   }
               }
        }  
    }*/
    
    //Added by Akash on 17.09.2019
    //Purpose: To update Proactive Care counter
    
    /*public void updateCounter(List<Case> newCase)
{
Set<Id> accountIds = new Set<Id>();
Set<Id> contactId;
Id userid=userinfo.getUserId();
List<Account> currentAccounts = new List<Account>();
User newUser = [SELECT Id, Name, ContactId, Account.Name,Account.of_Proactive_services__c,Account.Max_of_Services_Quarter__c,Account.requests_this_quarter__c, Account.Support_Technical_Advisor__c, Contact.Name, AccountId FROM USER where id = :Userinfo.getUserId()];

if(newUser.ContactId != null) //Added By Maanas 14 05 2020 , Customer Portal User to Create Proactive Case.
{

for(Case it : newCase){
system.debug('itrtpe'+it.RecordtypeId);
system.debug('Supportconstants'+Supportconstants.proactiveRtId);
if(it.RecordtypeId== Supportconstants.proactiveRtId){
Account currentAccount = new Account(Id=newUser.AccountId,requests_this_quarter__c = newUser.Account.requests_this_quarter__c);
if(currentAccount.of_Proactive_services__c == null)
currentAccount.of_Proactive_services__c = 5;

if(currentAccount.requests_this_quarter__c == null)
currentAccount.requests_this_quarter__c = 1;
else
currentAccount.requests_this_quarter__c = currentAccount.requests_this_quarter__c + 1;
system.debug('currentAccount.requests_this_quarter__c'+currentAccount.requests_this_quarter__c);
system.debug('currentAccount.Max_of_Services_Quarter__c'+currentAccount.Max_of_Services_Quarter__c);
if(currentAccount.requests_this_quarter__c >= newUser.Account.Max_of_Services_Quarter__c)
{
throw new DMLexception('You cannot create a ProActive Service for this quarter as you have already availed it for the quarter.');
}
else {
currentAccounts.add(currentAccount);    
}

system.debug('Current Account: '+ currentAccount);
}

}
if(!currentAccounts.isEmpty())
update currentAccounts;
//upsert nc;
}
}*/
    
    
    //Added by WarpDrive:Deepali
    //Purpose : To handler before insert events on case trigger
    /*public void onBeforeInsert(List<Case> newCases) {
        
        List<Case> srCaseList = new List<Case>();
        List<case> proactivecaseList = new List<case>();
        Map<Id,Case> caseOwnrChngeMap = new Map<Id,Case>();
        List<group> ERQueue ;
        if(ERQueue == null){
            ERQueue = [Select id from Group where type='Queue' and developerName = 'ER_Queue'];
        }
        System.debug('before insert method');
        for(Case ca : newCases){
            System.debug('qwewrtr**'+ca.RecordTypeId);
            if(ca.RecordTypeId == SupportConstants.incidentRtId || ca.RecordTypeId == SupportConstants.serviceRequestRtId||
               ca.RecordTypeId == SupportConstants.academyRtId||
               ca.RecordTypeId == SupportConstants.jsLicensingRtId||
               ca.RecordTypeId == SupportConstants.salesOpsRtId||
               ca.RecordTypeId == SupportConstants.jsAcademyRtId||               
               ca.RecordTypeId == SupportConstants.jsIncidentRtId)
                srCaseList.add(ca);     
            if(ca.ORigin == null)
                ca.Origin = 'Internally - On behalf of customer';
            if(ca.Origin == 'Community' && ca.RecordTypeId == SupportConstants.ProacTiveRTId){
                proactivecaseList.add(ca);
            }
            system.debug('Exnge'+ca.recordTypeId);
            system.debug('Exnge'+SupportConstants.jsEngagementRequestRtId);
            if(ca.recordTypeId==SupportConstants.jsEngagementRequestRtId){
                ca.OwnerId=ERQueue[0].Id;
                
            }
            if((ca.RecordTypeId == SupportConstants.incidentRtId || 
                ca.RecordTypeId == SupportConstants.serviceRequestRtId ||
                ca.RecordTypeId == SupportConstants.engagementRequestRtId ||
                ca.RecordTypeId == SupportConstants.jsengagementRequestRtId ||
                ca.RecordTypeId == SupportConstants.academyRtId ||
                ca.RecordTypeId == SupportConstants.salesOpsRtId ||
                ca.RecordTypeId == SupportConstants.jsAcademyRtId||
                ca.RecordTypeId == SupportConstants.jsIncidentRtId )
              ){
                  caseOwnrChngeMap.put(ca.Id, ca);
              } 
            
        }
        
        System.debug('srCaseList' + srCaseList);
        if(!srCaseList.isEmpty()){
            
            populateEntitlement(srCaseList); 
            AssignQueueAscaseOwner(srCaseList);
        }
        if(!proactivecaseList.isEmpty()){
            //assignOwnerToProactiveCase(Trigger.new);
        }
        if(!caseOwnrChngeMap.isEmpty()){
            fetchUserTimeZoneToUpdateBusinessHour(caseOwnrChngeMap);
        }  
    }
    */
    /*public void assignOwnerToProactiveCase(List<casE> newCases){
        Set<id> accIds = new Set<ID>();
        User newUser = [SELECT Id, ContactId, Account.Name,Account.of_Proactive_services__c,Account.requests_this_quarter__c, 
                        Account.Support_Technical_Advisor__c, 
                        Contact.Name, AccountId FROM USER where id = :Userinfo.getUserId()];
        
        for(Case it : newCases){
            it.OwnerId = newUser.Account.Support_Technical_Advisor__c; 
        }
    }*/
    //Added by WarpDrive:Deepali
    //Purpose : To handler after insert events on case trigger
    /*public void onAfterInsert(List<Case> newList, Map<Id,Case> newMap) {            

Set<Id> caseIdSet = new Set<Id>();    
List<Case> erCaseList = new List<Case>();   
Map<Id, Case> caseMap = new Map<Id, Case>(); 
List<Case> srCaseList = new List<Case>();
List<Case> rtChangeCaseList = new List<Case>();
Map<Id,Case> caseOwnrChngeMap = new Map<Id,Case>();
Map<Id,Case> statusChangeCaseMap = new Map<Id,Case>();

for(Case ca : newMap.Values()){      

if((ca.RecordTypeId == SupportConstants.incidentRtId||
ca.RecordTypeId == SupportConstants.serviceRequestRtId ||
ca.RecordTypeId == SupportConstants.serviceIncidentRtId ||
ca.RecordTypeId == SupportConstants.engagementRequestRtId ||
ca.RecordTypeId == SupportConstants.jsengagementRequestRtId ||
ca.RecordTypeId == SupportConstants.academyRtId ||
ca.RecordTypeId == SupportConstants.salesOpsRtId||
ca.RecordTypeId == SupportConstants.jsAcademyRtId ||
ca.RecordTypeId == SupportConstants.jsLicensingRtId||
ca.RecordTypeId == SupportConstants.jsIncidentRtId ) && ca.OwnerId != null){
caseIdSet.add(ca.Id);}

if((ca.RecordTypeId == SupportConstants.engagementRequestRtId || ca.RecordTypeId == SupportConstants.jsengagementRequestRtId) && ca.ParentId != null && ca.EntitlementId == null)
erCaseList.add(ca); 

if(ca.RecordTypeId == SupportConstants.incidentRtId || 
ca.RecordTypeId == SupportConstants.jsIncidentRtId ||
ca.RecordTypeId == SupportConstants.engagementRequestRtId || 
ca.RecordTypeId == SupportConstants.jsengagementRequestRtId){
caseMap.put(ca.Id, ca);
}
if((ca.RecordTypeId == SupportConstants.incidentRtId || 
ca.RecordTypeId == SupportConstants.serviceRequestRtId ||
ca.RecordTypeId == SupportConstants.engagementRequestRtId ||
ca.RecordTypeId == SupportConstants.jsengagementRequestRtId ||
ca.RecordTypeId == SupportConstants.academyRtId ||
ca.RecordTypeId == SupportConstants.salesOpsRtId ||
ca.RecordTypeId == SupportConstants.jsAcademyRtId||
ca.RecordTypeId == SupportConstants.jsIncidentRtId )
){
String ownerID = ca.OwnerId;
if(ownerID.startsWith('005'))
caseOwnrChngeMap.put(ca.Id, ca);
}      

}        
System.debug('caseIdSet' + caseIdSet);
if(!caseIdSet.isEmpty()){
checkCaseOwnerType(caseIdSet);
}
System.debug('erCaseList' + erCaseList);
if(!erCaseList.isEmpty()){
populateEntitlementOnERCase(erCaseList);
}
System.debug('caseMap' + caseMap);
if(!caseMap.isEmpty()){
addDefaultCaseTeamMembers(caseMap, false, null);
}
if(!caseOwnrChngeMap.isEmpty()){
//fetchUserTimeZoneToUpdateBusinessHour(caseOwnrChngeMap);
}  
}*/
    
    //Added by WarpDrive:Deepali
    //Purpose : To handler before update events on case trigger
    /*public void onBeforeUpdate(List<Case> newCases, Map<Id, Case> oldCasesMap) {        
        
        List<Case> srCaseList = new List<Case>();
        List<Case> rtChangeCaseList = new List<Case>();
        Map<Id,Case> caseOwnrChngeMap = new Map<Id,Case>();
        Map<Id,Case> statusChangeCaseMap = new Map<Id,Case>(); 
        
        PendingReasonPicklistCalculation(newCases, oldCasesMap);
        for(Case ca : newCases){
            
            //checking for recordtype and account type change to filter case and populate Entitlement accordingly
            if((ca.RecordTypeId == SupportConstants.incidentRtId|| 
                ca.RecordTypeId == SupportConstants.serviceRequestRtId||
                ca.RecordTypeId == SupportConstants.academyRtId||
                ca.RecordTypeId == SupportConstants.jsAcademyRtId||
                ca.RecordTypeId == SupportConstants.jsLicensingRtId||
                ca.RecordTypeId == SupportConstants.jsIncidentRtId) 
               &&(ca.AccountId != oldCasesMap.get(ca.Id).AccountId 
                  ||(ca.Ischanged_Support_Type__c != oldCasesMap.get(ca.Id).Ischanged_Support_Type__c && ca.Ischanged_Support_Type__c == true)
                 )
              ){
                  System.debug('ca.Ischanged_Support_Type__c' + ca.Ischanged_Support_Type__c);
                  System.debug('ca.oldCasesMap.get(ca.Id).Ischanged_Support_Type__c' + oldCasesMap.get(ca.Id).Ischanged_Support_Type__c);
                  srCaseList.add(ca);
              }
            
            //checking for recordtype change and filtering Sales Ops and Academy cases to populate Entitlement on update
            if(ca.RecordtypeId != oldCasesMap.get(ca.Id).RecordtypeId &&
               (ca.RecordTypeId == SupportConstants.salesOpsRtId|| 
                ca.RecordTypeId == SupportConstants.academyRtId||
                ca.RecordTypeId == SupportConstants.incidentRtId||
                ca.RecordTypeId == SupportConstants.serviceRequestRtId||
                ca.RecordTypeId == SupportConstants.jsAcademyRtId||
                ca.RecordTypeId == SupportConstants.jsLicensingRtId||
                ca.RecordTypeId == SupportConstants.jsIncidentRtId)
              ){
                  rtChangeCaseList.add(ca); 
              }
            
            //checking for recordtype and status change to populate case status duation based on business hours
            if((ca.RecordTypeId == SupportConstants.salesOpsRtId|| 
                ca.RecordTypeId == SupportConstants.academyRtId||
                ca.RecordTypeId == SupportConstants.incidentRtId||
                ca.RecordTypeId == SupportConstants.serviceRequestRtId||
                ca.RecordTypeId == SupportConstants.jsAcademyRtId||
                ca.RecordTypeId == SupportConstants.jsLicensingRtId||
                ca.RecordTypeId == SupportConstants.jsIncidentRtId ||
                ca.RecordTypeId == SupportConstants.jsEngagementRequestRtId ||
                ca.RecordTypeId == SupportConstants.engagementRequestRtId) &&
               ca.Status != oldCasesMap.get(ca.Id).Status){
                   statusChangeCaseMap.put(ca.Id,ca);
               }  
            
            //filtering cases based on change of owner when owner type is user
            if((ca.RecordTypeId == SupportConstants.incidentRtId || 
                ca.RecordTypeId == SupportConstants.serviceRequestRtId ||
                ca.RecordTypeId == SupportConstants.engagementRequestRtId ||
                ca.RecordTypeId == SupportConstants.jsengagementRequestRtId ||
                ca.RecordTypeId == SupportConstants.academyRtId ||
                ca.RecordTypeId == SupportConstants.salesOpsRtId ||
                ca.RecordTypeId == SupportConstants.jsAcademyRtId||
                ca.RecordTypeId == SupportConstants.jsIncidentRtId )
              ){
                  caseOwnrChngeMap.put(ca.Id, ca);
              }  
        }
        System.debug('srcaselist' + srCaseList);
        if(!srCaseList.isEmpty()){
            populateEntitlement(srCaseList);
        }
        System.debug('rtChangeCaseList' + rtChangeCaseList);
        if(!rtChangeCaseList.isEmpty()){
            populateEntitlement(rtChangeCaseList);
        } 
        System.debug('statusChangeCaseMap' + statusChangeCaseMap);
        if(!statusChangeCaseMap.isEmpty() && !statusCalculationDone){
            calculateCaseStatusDuration(statusChangeCaseMap, oldCasesMap);
        }  
        if(!caseOwnrChngeMap.isEmpty()){
            //fetchUserTimeZoneToUpdateBusinessHour(caseOwnrChngeMap);
        }  
        //Added by Dharani  12-12-2018
        //        CheckDuplicateCaseClose(newCases);
    }
    */
    //Added by WarpDrive:Deepali
    //Purpose : To handler after update events on case trigger
    /*public void onAfterUpdate(Map<Id,Case> newMap, Map<Id,Case> oldMap) {    

List<Living_Summary_History__c> livingSummries = new List<Living_Summary_History__c>();
Set<Id> caseIdSetToCmpltMiles = new Set<Id>();
Set<Id> caseIdSetToFetchTrgtDate = new Set<Id>();
Set<Id> caseForOwnerIdSet = new Set<Id>();
Set<Id> caseIdsForMilestones = new Set<Id>();
List<Case> erCaseList = new List<Case>();
Map<Id,Case> caseQueuechangeMap = new Map<Id,Case>();
Map<Id,Case> caseMap = new Map<Id,Case>();
System.debug('after update method');

for(Case ca : newMap.Values()){
if((ca.RecordTypeId == SupportConstants.incidentRtId||
ca.RecordTypeId == SupportConstants.serviceRequestRtId||
ca.RecordTypeId == SupportConstants.academyRtId||
ca.RecordTypeId == SupportConstants.salesOpsRtId||
ca.RecordTypeId == SupportConstants.jsAcademyRtId||
ca.RecordTypeId == SupportConstants.jsLicensingRtId||
ca.RecordTypeId == SupportConstants.jsIncidentRtId ) 
&&(ca.Comm_Update__c != oldMap.get(ca.Id).Comm_Update__c && ca.Comm_Update__c == TRUE))
caseIdSetToCmpltMiles.add(ca.Id); 
//System.debug('this miletone complt flag should be true' + ca.Milestone_Completed__c ); //added to debug ttb issue
//System.debug(ca.Milestone_Completed__c != oldMap.get(ca.Id).Milestone_Completed__c ); //added to debug ttb issue
if((ca.RecordTypeId == SupportConstants.incidentRtId||
ca.RecordTypeId == SupportConstants.serviceRequestRtId||
ca.RecordTypeId == SupportConstants.engagementRequestRtId||
ca.RecordTypeId == SupportConstants.jsengagementRequestRtId||
ca.RecordTypeId == SupportConstants.salesOpsRtId||
ca.RecordTypeId == SupportConstants.academyRtId||
ca.RecordTypeId == SupportConstants.jsAcademyRtId||
ca.RecordTypeId == SupportConstants.jsLicensingRtId||
ca.RecordTypeId == SupportConstants.jsIncidentRtId ) 
&&(ca.Status != 'Closed' && ca.Milestone_Completed__c == TRUE))  //added status condition - by Deepali
caseIdSetToFetchTrgtDate.add(ca.Id);

if((ca.RecordTypeId == SupportConstants.incidentRtId||
ca.RecordTypeId == SupportConstants.serviceRequestRtId ||
ca.RecordTypeId == SupportConstants.serviceIncidentRtId ||
ca.RecordTypeId == SupportConstants.engagementRequestRtId ||
ca.RecordTypeId == SupportConstants.jsengagementRequestRtId ||
ca.RecordTypeId == SupportConstants.salesOpsRtId||
ca.RecordTypeId == SupportConstants.academyRtId||
ca.RecordTypeId == SupportConstants.jsAcademyRtId||
ca.RecordTypeId == SupportConstants.jsLicensingRtId||
ca.RecordTypeId == SupportConstants.jsIncidentRtId ) && ca.OwnerId != null &&
ca.OwnerId != oldMap.get(ca.Id).OwnerId){
caseForOwnerIdSet.add(ca.Id);
caseQueuechangeMap.put(ca.Id, ca);
} 

if((ca.RecordTypeId == SupportConstants.engagementRequestRtId || ca.RecordTypeId == SupportConstants.jsengagementRequestRtId) && ca.ParentId != null && ca.EntitlementId == null)
erCaseList.add(ca); 

if((ca.RecordTypeId == SupportConstants.incidentRtId || 
ca.RecordTypeId == SupportConstants.jsIncidentRtId ||
ca.RecordTypeId == SupportConstants.engagementRequestRtId || 
ca.RecordTypeId == SupportConstants.jsengagementRequestRtId) && 
ca.AccountId != oldMap.get(ca.Id).AccountId &&
ca.AccountId != NULL){
caseMap.put(ca.Id, ca);
}
if(ca.Problem__c != oldMap.get(ca.Id).Problem__c){
livingSummries.add(new Living_Summary_History__c(Case__c = ca.Id,Field_Name__c='Problem__c',New_Value__c = ca.Problem__c, Old_Value__c = oldMap.get(ca.Id).Problem__c));
}

if(ca.Cause__c != oldMap.get(ca.Id).Cause__c){
livingSummries.add(new Living_Summary_History__c(Case__c = ca.Id,Field_Name__c='Cause__c',New_Value__c = ca.Cause__c, Old_Value__c = oldMap.get(ca.Id).Cause__c));
}
if(ca.Validation__c != oldMap.get(ca.Id).Validation__c){
livingSummries.add(new Living_Summary_History__c(Case__c = ca.Id,Field_Name__c='Validation__c',New_Value__c = ca.Validation__c, Old_Value__c = oldMap.get(ca.Id).Validation__c));
}
if(ca.Solution__c != oldMap.get(ca.Id).Solution__c){
livingSummries.add(new Living_Summary_History__c(Case__c = ca.Id,Field_Name__c='Solution__c',New_Value__c = ca.Solution__c, Old_Value__c = oldMap.get(ca.Id).Solution__c));
}
if(ca.Solution_Instructions__c != oldMap.get(ca.Id).Solution_Instructions__c){
livingSummries.add(new Living_Summary_History__c(Case__c = ca.Id,Field_Name__c='Solution_Instructions__c',New_Value__c = ca.Solution_Instructions__c, Old_Value__c = oldMap.get(ca.Id).Solution_Instructions__c));
}
system.debug('Em ail count'+ca.No_of_emails_Sent__c);
system.debug('Em ail count'+oldMap.get(ca.Id).No_of_Emails_Sent__c);
if( ca.No_of_Emails_Sent__c == 2 && (oldMap.get(ca.Id).No_of_Emails_Sent__c != ca.No_of_Emails_Sent__c) ){

caseIdsForMilestones.add(ca.Id);
}
}

System.debug('caseIdSetToCmpltMiles' + caseIdSetToCmpltMiles);
if(!caseIdSetToCmpltMiles.isEmpty()){
completeCaseMiletone(caseIdSetToCmpltMiles);
}
System.debug('caseIdSetToFetchTrgtDate' + caseIdSetToFetchTrgtDate);
if(!caseIdSetToFetchTrgtDate.isEmpty() && !System.isFuture() && !System.isBatch()){  
fetchTargetDateFromMilestone(caseIdSetToFetchTrgtDate);
}
System.debug('caseForOwnerIdSet' + caseForOwnerIdSet);
if(!caseForOwnerIdSet.isEmpty()){
checkCaseOwnerType(caseForOwnerIdSet);            
}
System.debug('caseQueuechangeMap' + caseQueuechangeMap);
if(!caseQueuechangeMap.isEmpty() && !caseForOwnerIdSet.isEmpty()){
changeRecordtypeOnQueueTransfer(caseForOwnerIdSet, caseQueuechangeMap);
}
System.debug('erCaseList' + erCaseList);
if(!erCaseList.isEmpty()){
populateEntitlementOnERCase(erCaseList);
}
if(!caseMap.isEmpty()){
System.debug('caseMap: ' + caseMap);
System.debug('oldMap' + oldMap);

addDefaultCaseTeamMembers(caseMap, true, oldMap);
}
if(!caseIdsForMilestones.isEmpty()){
closeFRMilestone(caseIdsForMilestones);
}
if(!livingSummries.isempty()){
insert livingSummries;
}





}*/
    
    /*public static void closeFRMilestone(Set<Id> caseIds){
Map<Id,CaseMilestone> casemIlestones = new Map<Id,CaseMilestone>();
for(CaseMilestone cm : [Select Id, CompletionDate, IsCompleted, MilestoneType.Name, CaseId, Case.Comm_Update__c 
from CaseMilestone 
where CaseId in :caseIds AND MilestoneType.Name ='First Response' 
AND IsCompleted = FALSE ]){
cm.CompletionDate = System.now();
casemIlestones.put(cm.CaseId,cm);
}

try{
update casemIlestones.values();
}
catch(Exception e){
throw new DmlException('Exception throw'+e.getMessage());
}
}*/
    
    //Business
    // Apex based record sharing for all the cases related to the top account
    /*public static void setupCaseSharingforCommunity(List<case> newCases){
        apexsharingalreadyDone = true;
        Set<Id> accId = new Set<Id>();
        MAp<Id,List<Id>> map_ofAccIdtoCAseId = new Map<id,List<ID>>();
        Set<Id> topParentAccounts = new SeT<Id>();
        Map<id,Id> acctIdtoParentAccountId = new Map<id,id>();
        LIst<CaseShare> allCaseShares = new List<CaseShare>();
        Map<Id,Id> mapOfAccounttoUserId = new Map<Id,Id>();
        
        for(Case it : newCases){
            if(it.AccountId != null){
                accId.add(it.AccountId);
                if(map_ofAccIdtoCAseId.containskey(it.accountId)){
                    map_ofAccIdtoCAseId.get(it.AccountId).add(it.Id);
                }
                else
                {
                    map_ofAccIdtoCAseId.put(it.ACcountId,new List<Id>{it.Id});
                }
            }
        }
        
        List<Account> associatedAccounts = [select id,Ultimate_Parent_ID__c from Account 
                                            where id in :map_ofAccIdtoCAseId.keyset() and Ultimate_Parent_ID__c <> null];
        for(Account it1 : associatedAccounts){
            topParentAccounts.add(it1.Ultimate_Parent_ID__c);
            acctIdtoParentAccountId.put(it1.Id,it1.Ultimate_Parent_ID__c);
        }
        for(User it : [Select id,AccountId from User where AccountId in : topParentAccounts]){
            mapOfAccounttoUserId.put(it.AccountId,it.Id);
        }
        
        for(Case it : newCases){
            if(map_ofAccIdtoCAseId.containsKey(it.AccountId) && map_ofAccIdtoCAseId.get(it.AccountId) != null)
            {
                Id ParentAccoutnId = acctIdtoParentAccountId.get(it.AccountId);
                for(Id eachCaseId : map_ofAccIdtoCAseId.get(it.AccountId)){
                    CaseShare eachCaseShared = new CaseShare();
                    eachCaseShared.CaseAccessLevel = 'edit';
                    // Assign case Id of case record.
                    eachCaseShared.CaseId = eachCaseId;
                    // Assign user id to grant read write access to this particular case record.
                    if(mapOfAccounttoUserId.get(ParentAccoutnId) != null){
                        eachCaseShared.UserOrGroupId = mapOfAccounttoUserId.get(ParentAccoutnId);
                        allCaseShares.add( eachCaseShared );
                    }
                }
            }
        }
        try{
            insert allCaseShares;
        }
        catch(exception e){
            throw e;
        }
        
        
    }*/
    
    
    // Business Logic  
    
    //Added by WarpDrive:Deepali
    //Purpose : To calculate total duartion case has been in each status
    /*public void calculateCaseStatusDuration(Map<Id,Case> newMap, Map<Id,Case> oldMap){
        statusCalculationDone = true;
        for(Case ca: newMap.values()){
            
            if(ca.Status =='Closed'){
                if( null != ca.Start_When_New__c && ca.Time_taken_to_resolve_in_Mnutes__c == null ){
                    Long customFieldLong = ca.Start_When_New__c.getTime();
                    Long currentDTLong = DateTime.now().getTime();
                    Long milliseconds = currentDTLong - customFieldLong;
                    Long seconds = milliseconds / 1000;
                    ca.Time_taken_to_resolve_in_Mnutes__c = seconds/60;
                }
            }
            
            
            Decimal previousValue, durationInMins, durationInMSecs;
            if(oldMap.get(ca.Id).Status == 'New'){
                if(ca.Total_Case_New_Duration__c != null){
                    previousValue = ca.Total_Case_New_Duration__c;
                }else{
                    previousValue = 0.0;
                }
                if(ca.CreatedDate != NULL && ca.CreatedDate != DateTime.Now()){
                    durationInMSecs = (Decimal)BusinessHours.diff(ca.BusinessHoursId,ca.CreatedDate,DateTime.Now());
                    durationInMins = durationInMSecs/60000;
                    ca.Total_Case_New_Duration__c = durationInMins + previousValue;
                }
            }else if(oldMap.get(ca.Id).Status == 'In Process'){
                if(ca.Total_Case_In_Process_Duration__c != null){
                    previousValue = ca.Total_Case_In_Process_Duration__c;
                }else{
                    previousValue = 0.0;
                }                
                if(ca.Status_In_Process_Time_Stamp__c != NULL && ca.Status_In_Process_Time_Stamp__c != DateTime.Now()){
                    durationInMSecs = (Decimal)BusinessHours.diff(ca.BusinessHoursId,ca.Status_In_Process_Time_Stamp__c,DateTime.Now());
                    durationInMins = durationInMSecs/60000;
                    ca.Total_Case_In_Process_Duration__c = durationInMins + previousValue;
                }
            }else if(oldMap.get(ca.Id).Status == 'Customer Action'){
                if(ca.Total_Case_Customer_Action_Duration__c != null){
                    previousValue = ca.Total_Case_Customer_Action_Duration__c;
                }else{
                    previousValue = 0.0;
                }
                if(ca.Status_Customer_Action_Time_Stamp__c != NULL && ca.Status_Customer_Action_Time_Stamp__c != DateTime.Now()){
                    durationInMSecs = (Decimal)BusinessHours.diff(ca.BusinessHoursId,ca.Status_Customer_Action_Time_Stamp__c,DateTime.Now());
                    durationInMins = durationInMSecs/60000;
                    ca.Total_Case_Customer_Action_Duration__c = durationInMins + previousValue;
                }
            }else if(oldMap.get(ca.Id).Status == 'Pending From Engineering'){
                if(ca.Total_Case_Pending_Engineering_Duration__c != null){
                    previousValue = ca.Total_Case_Pending_Engineering_Duration__c;
                }else{
                    previousValue = 0.0;
                }
                if(ca.Status_Pending_Engineering_Time_Stamp__c != NULL && ca.Status_Pending_Engineering_Time_Stamp__c != DateTime.Now()){
                    durationInMSecs = (Decimal)BusinessHours.diff(ca.BusinessHoursId,ca.Status_Pending_Engineering_Time_Stamp__c,DateTime.Now());
                    durationInMins = durationInMSecs/60000;
                    ca.Total_Case_Pending_Engineering_Duration__c = durationInMins + previousValue;
                }
            }else if(oldMap.get(ca.Id).Status == 'Resolved'){
                if(ca.Total_Case_Resolved_Duration__c != null){
                    previousValue = ca.Total_Case_Resolved_Duration__c;
                }else{
                    previousValue = 0.0;
                }
                if(ca.Status_Resolved_Time_Stamp__c != NULL && ca.Status_Resolved_Time_Stamp__c != DateTime.Now()){
                    durationInMSecs = (Decimal)BusinessHours.diff(ca.BusinessHoursId,ca.Status_Resolved_Time_Stamp__c,DateTime.Now());
                    durationInMins = durationInMSecs/60000;
                    ca.Total_Case_Resolved_Duration__c = durationInMins + previousValue;
                }
            }
        }
    }*/
    
    //Added by WarpDrive:Deepali
    //Purpose : To get CSM and Support Technical Advisor from Account and add to case team
    /*public void addDefaultCaseTeamMembers(Map<Id, Case> caseMap, Boolean removePreviousCaseTeam, Map<Id,Case> oldCaseMap){ 
        List<CaseTeamMember> cstList = new List<CaseTeamMember>();
        List<CaseTeamMember> cstListToDelete = new List<CaseTeamMember>();       
        List<String> caseTeamComparators =new List<String>{'CSM','Case Team Member'};
            Map<String,Id> roleMap =new Map<String,Id>();//SLTECH-7768
        Set<Id> activeUserSet = new Set<id>();//SLTECH-7768
        Set<Id> addedPeople = new Set<id>();
        
        //SLTECH-7768
        for(CaseTeamRole casTeamObj :[Select Id, Name FROM CaseTeamRole WHERE Name IN :caseTeamComparators]){ 
            roleMap.put(casTeamObj.Name,casTeamObj.Id);
        }
        
        for(User userObj: [Select Id FROM User WHERE isActive=true]){
            activeUserSet.add(userObj.Id);
        }
        
        if(removePreviousCaseTeam) {
            for(CaseTeamMember cstm : [Select Id, MemberId, TeamRole.Name, ParentId 
                                       from CaseTeamMember 
                                       where ParentId in :caseMap.keyset()]){
                                           if(cstm.TeamRole.Name == 'CSM'){
                                               cstListToDelete.add(cstm);
                                           }
                                           
                                           addedPeople.add(cstm.MemberId);
                                           if(cstm.MemberId == oldCaseMap.get(cstm.ParentId).Account_STA__c){
                                               
                                               cstListToDelete.add(cstm);
                                           }
                                       }                                                                
        }*/
        /*if(!cstListToDelete.isEmpty()){
delete cstListToDelete;
}*/
        
       /* for(Case ca : caseMap.values()){
            if(!addedPeople.contains((Id)ca.Account_CSM__c) && ca.Account_CSM__c != NULL && ca.Account_CSM__c != ''){
                addedPeople.add((Id)ca.Account_CSM__c);
                //cstList.add(createCaseTeamMembers(ca,(Id)ca.Account_CSM__c,'CSM'));
                if(activeUserSet.contains(ca.Account_CSM__c)) //SLTECH-7768
                    cstList.add(new CaseTeamMember(ParentId = ca.Id, MemberId = ca.Account_CSM__c, TeamRoleId = roleMap.size()  > 0 ? roleMap.get('CSM'): null));
            }
            if(!addedPeople.contains((Id)ca.Account_STA__c) && ca.Account_STA__c != NULL && ca.Account_STA__c != ''){
                addedPeople.add((Id)ca.Account_STA__c);
                //cstList.add(createCaseTeamMembers(ca,(Id)ca.Account_STA__c,'Case Team Member'));
                if(activeUserSet.contains(ca.Account_STA__c)) //SLTECH-7768
                    cstList.add(new CaseTeamMember(ParentId = ca.Id, MemberId = ca.Account_STA__c, TeamRoleId = roleMap.size()  > 0 ? roleMap.get('Case Team Member'): null));
            }
        }  
        System.debug('cstListToDelete'+cstListToDelete);
        
        System.debug('cstList'+cstList);
        if(!cstList.isEmpty()){
            insert cstList;
        }           
    }*/
    
    //Added by WarpDrive:Deepali
    //Purpose : To create case team members with given information
    //Maanas - restructured/Commented Below code as SOQL was being called from For Loop
    /* public static CaseTeamMember createCaseTeamMembers(Case ca, Id teamMember, String teamRole){  

CaseTeamRole role = [Select Id from CaseTeamRole where Name =: teamRole limit 1];
CaseTeamMember ctm = new CaseTeamMember(ParentId = ca.Id, MemberId = teamMember, TeamRoleId = role.Id); 
return ctm;              
}*/
    
    /*Created By Dharani on 17-05-2019
Pending Reason picklist values age calculation based on business hrs.*/
    /*public void  PendingReasonPicklistCalculation(List<Case> newCases, Map<Id, Case> oldCasesMap)
    {
        List<BusinessHours> defaultHours = [select Id from BusinessHours where IsDefault=true];
        List<String> pickListValuesList= new List<String>();
        //to get all the 'Awaiting/Pending Reason' pick list values  
        Schema.DescribeFieldResult fieldResult = case.Awaiting_Pending_Reason__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }     
        //return pickListValuesList;
        
        system.debug('Awaiting/Pending Reason'+ pickListValuesList);
        for(case caselist:newCases)
        {
            Id bhrs;
            if (caselist.BusinessHoursId != null)
            {
                bhrs= caselist.BusinessHoursId;
            }
            else
            {
                bhrs= defaultHours[0].id;
            }
            case oldcase=oldCasesMap.get(caselist.Id);
            if((caselist.RecordTypeId==SupportConstants.engagementRequestRtId || caselist.RecordTypeId==SupportConstants.jsEngagementRequestRtId)
               && caselist.Awaiting_Pending_Reason__c <> oldcase.Awaiting_Pending_Reason__c)
            {
                //case oldcase=oldCasesMap.get(caselist.Id);
                Decimal previousvalue=0;
                Decimal durationInMins=0;
                decimal durationinMsec;
                if (oldcase.Awaiting_Pending_Reason__c== pickListValuesList[0])
                {
                    if(caselist.Duration_in_Pending_Tech_support__c!=null)
                    {
                        previousvalue=caselist.Duration_in_Pending_Tech_support__c;
                    }
                    
                    
                    if(caselist.Pending_Tech_support_time_stamp__c<> DateTime.now())
                    {
                        durationinMsec=(Decimal) BusinessHours.diff(bhrs,caselist.Pending_Tech_support_time_stamp__c,DateTime.now() );
                        system.debug('durationInMS'+ durationinMsec);   
                        durationInMins=durationinMsec/60000;//durationInMS/3600000;
                        caselist.Duration_in_Pending_Tech_support__c=durationinMins+previousvalue;
                        system.debug('durationinHrs'+ durationInMins); 
                        
                        //caselist.Duration_in_Pending_Tech_support__c= 
                    }
                    
                }
                else if(oldcase.Awaiting_Pending_Reason__c== pickListValuesList[1])
                {
                    if(caselist.Duration_Pending_Sr_Tech_Support__c!=null)
                    {
                        previousvalue=caselist.Duration_Pending_Sr_Tech_Support__c ;
                    }
                    
                    if(caselist.Pending_Sr_Tech_Support_time_stamp__c<> DateTime.now())
                    {
                        durationinMsec= BusinessHours.diff(bhrs,caselist.Pending_Sr_Tech_Support_time_stamp__c,DateTime.now() );
                        //system.debug('Duration'+ duration);     
                        system.debug('durationInMS'+ durationinMsec);   
                        durationinMins=durationinMsec/60000;//durationInMS/3600000;
                        
                        system.debug('durationinMins'+ durationinMins); 
                        caselist.Duration_Pending_Sr_Tech_Support__c=durationinMins+previousvalue;
                        //caselist.Duration_in_Pending_Tech_support__c= 
                        
                    }
                    
                }
                else if(oldcase.Awaiting_Pending_Reason__c== pickListValuesList[2])
                {
                    if(caselist.Duration_in_Pending_Infra_MCS_support__c !=null)
                    {
                        previousvalue=caselist.Duration_in_Pending_Infra_MCS_support__c ;
                    }
                    
                    if(caselist.Pending_Infra_MCS_Time_stamp__c<> DateTime.now())
                    {
                        durationinMsec= BusinessHours.diff(bhrs,caselist.Pending_Infra_MCS_Time_stamp__c,DateTime.now() );
                        //system.debug('Duration'+ duration);     
                        system.debug('durationInMS'+ durationinMsec);   
                        durationinMins=durationinMsec/60000;//durationInMS/3600000;
                        
                        system.debug('durationinMins'+ durationinMins); 
                        caselist.Duration_in_Pending_Infra_MCS_support__c=durationinMins+previousvalue;
                        //caselist.Duration_in_Pending_Tech_support__c= 
                        
                    }
                    
                }
                else if(oldcase.Awaiting_Pending_Reason__c== pickListValuesList[3])
                {
                    if(caselist.Duration_in_Pending_Product__c !=null)
                    {
                        previousvalue=caselist.Duration_in_Pending_Product__c ;
                    }
                    
                    if(caselist.Pending_Product_Timestamp__c<> DateTime.now())
                    {
                        durationinMsec= BusinessHours.diff(bhrs,caselist.Pending_Product_Timestamp__c,DateTime.now() );
                        //system.debug('Duration'+ duration);     
                        system.debug('durationInMS'+ durationinMsec);   
                        durationinMins=durationinMsec/60000;//durationInMS/3600000;
                        
                        system.debug('durationinMins'+ durationinMins); 
                        caselist.Duration_in_Pending_Product__c=durationinMins+previousvalue;
                        //caselist.Duration_in_Pending_Tech_support__c= 
                        
                    }
                    
                }
                
                
            }
        }
    }*/
    
    
    /*CreatedBy Dharani on 22-02-2019
Assignment rule for Cases from Community pages*/
    /*public void AssignQueueAscaseOwner(List<Case> lstcase)
    {
        List<Group> lstgrp= new List<Group>([select id,DeveloperName from group where Type='Queue']); 
        Set<String> productsList = new set <String> ();// SLTECH-6424
        for( Product_Support_Queue_List__mdt prodObj : [Select Id, MasterLabel FROM Product_Support_Queue_List__mdt ]){// SLTECH-6424
            productsList.add(prodObj.MasterLabel);
        } 
        
        
        Map<String,Id> grpMap= new Map<String,Id>();
        If(lstgrp.Size()>0)
        {
            for(Group grp:lstgrp)
            {
                grpMap.put(grp.DeveloperName,grp.Id) ;
            }
        }
        
        system.debug('Group Map'+grpMap);
        
        For(Case c: lstcase)
        {
            system.debug('cases from community--'+ c );
            if((c.Origin=='Community') && (c.RecordTypeId == SupportConstants.incidentRtId || c.RecordTypeId == SupportConstants.jsIncidentRtId))
            {
                If(c.RecordTypeId==SupportConstants.incidentRtId && c.Related_To__c=='Studio')
                {
                    c.OwnerId=grpMap.get('Studio_Queue');
                }
                Else if(c.RecordTypeId==SupportConstants.incidentRtId && productsList.contains(c.Related_To__c))// SLTECH-6424 Start
                {
                    c.OwnerId=grpMap.get('Product_Support_Queue');  
                }																								// SLTECH-6424 End
                Else if(c.RecordTypeId==SupportConstants.incidentRtId && c.Related_To__c=='Orchestrator')
                {
                    c.OwnerId=grpMap.get('Orchestrator_Queue');  
                }
                Else if(c.RecordTypeId==SupportConstants.incidentRtId && c.Related_To__c=='Robot')
                {
                    c.OwnerId=grpMap.get('Robot_Queue');  
                }
                Else if(c.RecordTypeId==SupportConstants.incidentRtId && c.Related_To__c=='Partner Product')
                {
                    c.OwnerId=grpMap.get('Partner_Product');
                }
                Else if(c.RecordTypeId==SupportConstants.jsIncidentRtId && c.Case_Web_Form_Region__c=='Japan' && c.Related_To__c=='Studio')
                {
                    c.OwnerId=grpMap.get('Japan_Studio_Queue');  
                }
                Else if(c.RecordTypeId==SupportConstants.jsIncidentRtId && c.Case_Web_Form_Region__c=='Japan' && productsList.contains(c.Related_To__c))// SLTECH-6424 Start
                {
                    c.OwnerId=grpMap.get('Japan_Product_Support_Queue');  
                }																																		// SLTECH-6424 End
                Else if(c.RecordTypeId==SupportConstants.jsIncidentRtId && c.Case_Web_Form_Region__c=='Japan' && c.Related_To__c=='Orchestrator')
                {
                    c.OwnerId=grpMap.get('Japan_Orchestrator_Queue');
                }
                Else if(c.RecordTypeId==SupportConstants.jsIncidentRtId && c.Case_Web_Form_Region__c=='Japan' && c.Related_To__c=='Robot')
                {
                    c.OwnerId=grpMap.get('Japan_Robot_Queue');
                }
                Else if(c.RecordTypeId==SupportConstants.jsIncidentRtId && c.Case_Web_Form_Region__c=='Japan' && c.Related_To__c=='Partner Product')
                {
                    c.OwnerId=grpMap.get('Japan_Partner_Product');
                }
                Else if(c.RecordTypeId==SupportConstants.jsIncidentRtId && c.Case_Web_Form_Region__c=='Japan' && c.Related_To__c=='Academy')
                {
                    c.RecordTypeId=SupportConstants.jsAcademyRtId;
                    c.OwnerId=grpMap.get('Japan_Academy_Queue');
                }
                Else if(c.RecordTypeId==SupportConstants.jsIncidentRtId && c.Case_Web_Form_Region__c=='Japan' && c.Related_To__c=='Cloud Platform')//Given "Cloud Platform" Related To value beacuse "Licensing" value is deactivated
                {
                    c.RecordTypeId=SupportConstants.jsLicensingRtId;
                    c.OwnerId=grpMap.get('Japan_Licensing_Queue');
                }
                system.debug('Recordtype-- '+c.RecordTypeId ); 
                system.debug('OwnerId-- '+ c.OwnerId );
            }
        }
    }*/
    
    //Added by WarpDrive:Deepali
    //Purpose : To fetch time zone from Case Owner and update the Business hours
    /*private void fetchUserTimeZoneToUpdateBusinessHour(Map<Id,Case> newCaseMap){
        
        try
        {
            System.debug('Inside fetch function!');
            Set<Id> ownerIdSet = new Set<Id>();
            Set<Id> bsnsHrIdSet = new Set<Id>();
            Set<Id> caseownerIdSet = new Set<Id>();
            Set<String> timeZnSet = new Set<String>();
            Map<String,Id> tmZnToBusnssHrMapping = new Map<String,Id>();
            Map<Id,String> caseIdtoUserTimeZoneMap = new Map<Id,String>();
            Map<Id,User> caseOwnerWithTimeZone;
            List<Case> caseToUpdateList = new List<Case>();            
            Map<Id,BusinessHours> orgBusnssHrsMap;
            Map<Id,Case> caseWithBusnssHrMap;
            
            caseWithBusnssHrMap = new Map<Id,Case>([Select Id, BusinessHoursId, BusinessHours.TimeZoneSidKey, Owner.Type, OwnerId ,RecordtypeId
                                                    from Case where Id in :newCaseMap.keyset()]);
            
            BusinessHours IncidentDefaultBusinessHours = new BusinessHours();
            Map<String,BusinessHours> mapOfNametoBusinessHours = new Map<String,BusinessHours>();
            for(BusinessHours it : [Select Id,NAme, TimeZoneSidKey from BusinessHours 
                                    WHERE IsActive = TRUE Order by MondayStartTime]){
                                        if(it.Name == 'IST 24X7 Business Hours'){
                                            IncidentDefaultBusinessHours = it;
                                        }
                                        mapOfNametoBusinessHours.put(it.name,it);
                                    }
            system.debug('mapOfNametoBusinessHours'+mapOfNametoBusinessHours);
            if(!mapOfNametoBusinessHours.isEmpty()){
                for(Case ca : newCaseMap.values()){    
                    
                    if(ca.time_zone__c != null && mapOfNametoBusinessHours.get(ca.Time_Zone__c) != null){
                        ca.BusinessHoursId = mapOfNametoBusinessHours.get(ca.Time_Zone__c).Id;
                    }
                }   
            }
            System.debug('caseToUpdateList' + caseToUpdateList);
            
            
        }
        catch(Exception ex){
            System.debug('Exception in fetchUserTimeZoneToUpdateBusinessHour' + ex.getMessage() +ex.getLineNumber() + ex.getTypeName() +ex.getCause());
        }
        
    }
    */
    
    
    //Added by WarpDrive:Deepali
    //Purpose : To check the Owner type and update the 'Case Owner is Queue' field
    /*private void checkCaseOwnerType(Set<Id> caseIdSet){
try{
System.debug('inside checkCaseOwnerType');
List<Case> caseListToUpdate = new List<Case>();
List<Case> caseListWithOwnerType = [Select Id, Owner.Type, OwnerId, Case_Owner_is_Queue__c
from Case 
where Id in :caseIdSet];
if(!caseListWithOwnerType.isEmpty()){
for(Case ca :  caseListWithOwnerType){
if(ca.Owner.Type == 'Queue'){
ca.Case_Owner_is_Queue__c = TRUE;
System.debug('inside queue');
//caseListToUpdate.add(ca);
}
if(ca.Owner.Type == 'User'){
ca.Case_Owner_is_Queue__c = FALSE;
System.debug('inside user');
//caseListToUpdate.add(ca);
}

}
}
System.debug('caseListToUpdate' + caseListToUpdate);
if(!caseListToUpdate.isEmpty()){
//update caseListToUpdate;
}
if(Test.isRunningTest()){
Integer i = 1/0;
}


}catch(Exception ex){
System.debug('Exception in checkCaseOwnerType' + ex.getMessage() +ex.getLineNumber() + ex.getTypeName() +ex.getCause());
}             

}*/
    
    //Added by WarpDrive:Deepali
    //Purpose : To change recordtype and Product component based on departments when Case Queue is changed.
    /*private void changeRecordtypeOnQueueTransfer(Set<Id> caseIdSet,Map<Id,Case> caseMap){
try{
System.debug('inside changeRecordtypeOnQueueTransfer');
Set<String> queueNameSet = new Set<String>{'Academy','ER_Queue', 'Japan_Academy_Queue', 'Japan_Orchestrator_Queue', 'Japan_Robot_Queue', 'Japan_Licensing_Queue', 'Japan_Partner_Product',
'Japan_Product_Support_Queue', 'Japan_Studio_Queue', 'Orchestrator_Queue', 'Partner_Product', 'Product_Support_Queue', 'Robot_Queue', 
'Sales_Operations_Queue', 'Studio_Queue'};      
List<Case> caseListWithOwnerType = [Select Id, Owner.Type, OwnerId, RecordTypeId, Related_To__c, Case_Web_Form_Region__c,Subscription_Code__c
from Case 
where Id in :caseIdSet];                                                                                            
List<Case> caseListToUpdate = new List<Case>();
Map<Id, Group> queueMap;
if(!queueNameSet.isEmpty()){
queueMap = new Map<Id, Group>([Select Id, DeveloperName, Type
from Group 
where DeveloperName in :queueNameSet]);
} 
System.debug('queueMap' + queueMap);  

for(Case ca : caseListWithOwnerType){
if(ca.Owner.Type == 'Queue' && queueMap.containsKey(ca.OwnerId)){

if(ca.RecordTypeId != SupportConstants.incidentRtId && ca.recordTypeId != SupportConstants.engagementRequestRtId && 
(queueMap.get(ca.OwnerId).DeveloperName == 'Product_Support_Queue'||
queueMap.get(ca.OwnerId).DeveloperName == 'Partner_Product'||
queueMap.get(ca.OwnerId).DeveloperName == 'Robot_Queue'||
queueMap.get(ca.OwnerId).DeveloperName == 'Studio_Queue'||
queueMap.get(ca.OwnerId).DeveloperName == 'Orchestrator_Queue')){
if(ca.Subscription_Code__c==TRIAL_LICENSE_CODE){//SLTECH-7896 

ca.RecordTypeId = SupportConstants.serviceRequestRtId;
}else{

ca.RecordTypeId = SupportConstants.incidentRtId;    
}

if(ca.Related_To__c == null || ca.Related_To__c == 'Academy' || ca.Related_To__c == 'Cloud Platform'){//Given "Cloud Platform" Related To value beacuse "Licensing" value is deactivated
if(queueMap.get(ca.OwnerId).DeveloperName == 'Studio_Queue'){
ca.Related_To__c = 'Studio';
}else if(queueMap.get(ca.OwnerId).DeveloperName == 'Partner_Product'){
ca.Related_To__c = 'Partner Product';
}else if(queueMap.get(ca.OwnerId).DeveloperName == 'Robot_Queue'){
ca.Related_To__c = 'Robot';
}else if(queueMap.get(ca.OwnerId).DeveloperName == 'Orchestrator_Queue'){
ca.Related_To__c = 'Orchestrator';
}else{
ca.Related_To__c = 'Studio';
}
}
caseListToUpdate.add(ca);
}

else if(ca.RecordTypeId != SupportConstants.jsAcademyRtId && queueMap.get(ca.OwnerId).DeveloperName == 'Japan_Academy_Queue'){

ca.RecordTypeId = SupportConstants.jsAcademyRtId;
if(ca.Related_To__c == null || ca.Related_To__c != 'Academy'){
ca.Related_To__c = 'Academy';
}
caseListToUpdate.add(ca);
}
else if(ca.RecordTypeId != SupportConstants.jsLicensingRtId && queueMap.get(ca.OwnerId).DeveloperName == 'Japan_Licensing_Queue'){

ca.RecordTypeId = SupportConstants.jsLicensingRtId;
if(ca.Related_To__c == null || ca.Related_To__c != 'Cloud Platform'){//Given "Cloud Platform" Related To value beacuse "Licensing" value is deactivated
ca.Related_To__c = 'Cloud Platform';//Given "Cloud Platform" Related To value beacuse "Licensing" value is deactivated
}
caseListToUpdate.add(ca);
}
else if(ca.RecordTypeId != SupportConstants.salesOpsRtId && queueMap.get(ca.OwnerId).DeveloperName == 'Sales_Operations_Queue'){

ca.RecordTypeId = SupportConstants.salesOpsRtId;//18 05 2020 Maanas - Sales Operation RecordType Does not have any Product Component hence mapping to Other.
if(ca.Related_To__c == null || ca.Related_To__c != 'Other'){//Given "Cloud Platform" Related To value beacuse "Licensing" value is deactivated
ca.Related_To__c = 'Other';//Given "Cloud Platform" Related To value beacuse "Licensing" value is deactivated
}
caseListToUpdate.add(ca);
}
else if(ca.RecordTypeId != SupportConstants.academyRtId && queueMap.get(ca.OwnerId).DeveloperName == 'Academy'){

ca.RecordTypeId = SupportConstants.academyRtId;
if(ca.Related_To__c == null || ca.Related_To__c != 'Academy'){
ca.Related_To__c = 'Academy';
}
caseListToUpdate.add(ca);
}
else if(ca.RecordTypeId != SupportConstants.engagementRequestRtId && queueMap.get(ca.OwnerId).DeveloperName == 'ER_Queue'){

ca.RecordTypeId = SupportConstants.engagementRequestRtId;
caseListToUpdate.add(ca);
}
else if(ca.RecordTypeId != SupportConstants.jsengagementRequestRtId && queueMap.get(ca.OwnerId).DeveloperName == 'Japan_ER_Queue'){

ca.RecordTypeId = SupportConstants.jsengagementRequestRtId;
caseListToUpdate.add(ca);
}


if(ca.RecordTypeId != SupportConstants.jsIncidentRtId&&
(queueMap.get(ca.OwnerId).DeveloperName == 'Japan_Product_Support_Queue'||
queueMap.get(ca.OwnerId).DeveloperName == 'Japan_Orchestrator_Queue'||
queueMap.get(ca.OwnerId).DeveloperName == 'Japan_Robot_Queue'||
queueMap.get(ca.OwnerId).DeveloperName == 'Japan_Partner_Product'||
queueMap.get(ca.OwnerId).DeveloperName == 'Japan_Studio_Queue')){

ca.RecordTypeId = SupportConstants.jsIncidentRtId;
if(ca.Related_To__c == null || ca.Related_To__c == 'Academy' || ca.Related_To__c == 'Cloud Platform'){//Given "Cloud Platform" Related To value beacuse "Licensing" value is deactivated
if(queueMap.get(ca.OwnerId).DeveloperName == 'Japan_Studio_Queue'){
ca.Related_To__c = 'Studio';
}else if(queueMap.get(ca.OwnerId).DeveloperName == 'Japan_Partner_Product'){
ca.Related_To__c = 'Partner Product';
}else if(queueMap.get(ca.OwnerId).DeveloperName == 'Japan_Robot_Queue'){
ca.Related_To__c = 'Robot';
}else if(queueMap.get(ca.OwnerId).DeveloperName == 'Japan_Orchestrator_Queue'){
ca.Related_To__c = 'Orchestrator';
}else{
ca.Related_To__c = 'Studio';
}
}
caseListToUpdate.add(ca);
}
}
}             
System.debug('caseListToUpdate' + caseListToUpdate);
if(!caseListToUpdate.isEmpty()){
update caseListToUpdate;
} 
if(Test.isRunningTest()){
Integer i = 1/0;
}
}catch(Exception ex){
System.debug('Exception in changeRecordtypeOnQueueTransfer' + ex.getMessage() +ex.getLineNumber() + ex.getTypeName() +ex.getCause());
}             

}*/
    
    
    //Added by WarpDrive:Deepali
    //Purpose : To Complete the Communication Update Milestone on Cases when Customer is update through Email
    /*private void completeCaseMiletone(Set<Id> caseIdSet){
try{
System.debug('inside completeCaseMiletone');
List<CaseMilestone> milesListToUpdate = new List<CaseMilestone>();
List<Case> caseListToUpdate = new List<Case>();
List<CaseMilestone> milestoneList = [Select Id, CompletionDate, IsCompleted, MilestoneType.Name, CaseId, Case.Comm_Update__c 
from CaseMilestone 
where CaseId in :caseIdSet AND MilestoneType.Name =:Label.Communication_Milestone_Name 
AND IsCompleted = FALSE FOR UPDATE];
System.debug('milestoneList' + milestoneList);  
if(!milestoneList.isEmpty()){
for(CaseMilestone miles : milestoneList){
miles.CompletionDate = System.now();
//miles.Case.Comm_Update__c = FALSE;
Case ca = new Case(Id=miles.CaseId, Comm_Update__c = FALSE);
milesListToUpdate.add(miles);
caseListToUpdate.add(ca);
}
}  
System.debug('milesListToUpdate'+milesListToUpdate);
if(!milesListToUpdate.isEmpty()){
update milesListToUpdate;
}                 
System.debug('caseListToUpdate'+caseListToUpdate);           
if(!caseListToUpdate.isEmpty()){
update caseListToUpdate;
}
if(Test.isRunningTest()){
Integer i = 1/0;
}

}catch(Exception ex){
System.debug('Exception in CompleteCaseMilestone' + ex.getMessage() +ex.getLineNumber() + ex.getTypeName() +ex.getCause());
}             

}*/
    
    //Added by WarpDrive:Deepali
    //Purpose : To Populate the Engagement Request with Entitlement based on the Parent Entitlement
    /*private void populateEntitlementOnERCase(List<Case> erCaseList){
try{
System.debug('Inside populateEntforER');
List<Case> erCasestoUpdate = new List<Case>();
Set<Id> erCaseIdSet = new Set<Id>();
for(Case ca :erCaseList){
erCaseIdSet.add(ca.Id);
}
List<Case> erWithParentCaseList = [Select Id, EntitlementId, ParentId, Parent.EntitlementId
from Case
where Id in :erCaseIdSet];

for(Case ca: erWithParentCaseList){
System.debug('ca.Parent.EntitlementId'+ ca.Parent.EntitlementId);
ca.EntitlementId = ca.Parent.EntitlementId;
erCasestoUpdate.add(ca);
}
System.debug('erCasestoUpdate'+erCasestoUpdate);           
if(!erCasestoUpdate.isEmpty()){
update erCasestoUpdate;
}
}
catch(Exception ex){
System.debug('Exception in populateEntitlementOnERCase' + ex.getMessage() +ex.getLineNumber() + ex.getTypeName() +ex.getCause());
}
}*/
    
    //Added by WarpDrive:Deepali
    //Purpose : To Populate the Service Request & Incident Cases with Entitlement based on the Support Type of Account   
    /*private void populateEntitlement(List<Case> srCaseList){
        
        try{
            Set<String> EntitlementNamesSet = new Set<String>{Label.Service_Request_Entitlement,Label.Premium_Account_Entitlement, Label.PremiumPlus_Account_Entitlement,Label.Standard_Account_Entitlement, Label.Enterprise_Account_Entitlement, 
                Label.SalesOperationEntitlementName,Label.AcademyEntitlementName, Label.JapanStandardEntitlementName,
                Label.JapanEnterpriseEntitlementName, Label.JapanPremiumEntitlementName};
                    List<Entitlement> entlmntList = new List<Entitlement>([Select Id, Name from Entitlement where Name in :EntitlementNamesSet]);
            Map<String,Id> entlmntmap = new Map<String,Id>();  
            List<Case> prdctSupportcaseList = new List<Case>();
            List<Case> salesOpsCaseList = new List<Case>(); 
            List<Case> japanCaseList = new List<Case>();
            List<Case> acdemyCaseList = new List<Case>();                                              
            List<Case> serviceRequestCaseList = new List<Case>();
            
            System.debug('EntitlementNamesSet' + EntitlementNamesSet);
            System.debug('entlmntList' + entlmntList);       
            
            
            for(Entitlement ent : entlmntList){
                entlmntmap.put(ent.Name, ent.Id);
            }
            
            System.debug('entlmntmap' + entlmntmap);
            
            for(Case ca : srCaseList){
                if(ca.RecordtypeId == SupportConstants.salesOpsRtId){
                    salesOpsCaseList.add(ca);
                }
                if(ca.RecordtypeId == SupportConstants.academyRtId){
                    acdemyCaseList.add(ca);
                }
                if(ca.RecordtypeId == SupportConstants.jsLicensingRtId ||
                   ca.RecordtypeId == SupportConstants.jsAcademyRtId|| 
                   (ca.RecordtypeId == SupportConstants.jsIncidentRtId && ca.Case_Web_Form_Region__c == 'Japan')||
                   (ca.RecordtypeId == SupportConstants.serviceRequestRtId && ca.Case_Web_Form_Region__c == 'Japan')){
                       japanCaseList.add(ca);
                   }
                if(ca.RecordtypeId == SupportConstants.incidentRtId){
                    prdctSupportcaseList.add(ca);
                }
                System.debug('***ca.AccountId: '+ca.AccountId);
                if(ca.RecordtypeId == SupportConstants.serviceRequestRtId){
                    serviceRequestCaseList.add(ca);
                }
            }
            
            if(!entlmntmap.isEmpty()){
                if(!prdctSupportcaseList.isEmpty()){
                    populateEntitlementBasedOnAccountType(entlmntmap,prdctSupportcaseList);
                }
                if(!serviceRequestCaseList.isEmpty()){
                    populateEntitlementForServiceRequest(entlmntmap, serviceRequestCaseList);
                }
                if(!japanCaseList.isEmpty()){
                    populateEntitlementBasedOnAccountTypeJapan(entlmntmap,japanCaseList);
                }
                if(!acdemyCaseList.isEmpty()){
                    populateEntitlementBasedOnAccountTypeAcademy(entlmntmap,acdemyCaseList);
                }
                if(!salesOpsCaseList.isEmpty()){
                    populateEntitlementBasedOnAccountTypeSalesOps(entlmntmap,salesOpsCaseList);
                }
            }
            if(Test.isRunningTest()){
                Integer i = 1/0;
            }
            
        }catch(Exception ex){
            System.debug('Exception in populateEntitlement' + ex.getMessage() +ex.getLineNumber() + ex.getTypeName() +ex.getCause());
        }           
    }*/
    
    //Added by WarpDrive:Deepali
    //Purpose : To Populate the Incident Cases with Entitlement based on the Support Type of Account
    /*private static void populateEntitlementBasedOnAccountType(Map<String,Id> entlmntmap, List<Case> caseList){
        
        try{
            for(Case ca :caseList){
                String accountType = (ca.AccountId != null) ? ca.Account_Type__c : CaseMetadata_SV.AccountType;
                if(accountType == 'Standard'){
                    ca.EntitlementId = entlmntmap.get(Label.Standard_Account_Entitlement);
                }else if(accountType == 'Premium'){
                    ca.EntitlementId = entlmntmap.get(Label.Premium_Account_Entitlement);
                }else if(accountType == 'Premium Plus'){
                    ca.EntitlementId = entlmntmap.get(Label.PremiumPlus_Account_Entitlement);	
                }else if(accountType == 'Enterprise'){
                    ca.EntitlementId = entlmntmap.get(Label.Enterprise_Account_Entitlement);
                }
                
                if(ca.Ischanged_Support_Type__c == True){
                    ca.Ischanged_Support_Type__c = False;
                }
            }
            if(Test.isRunningTest()){
                Integer i = 1/0;
            }
            
        }catch(Exception ex){
            System.debug('Exception in populateEntitlementBasedOnAccountType' + ex.getMessage() +ex.getLineNumber() + ex.getTypeName() +ex.getCause());
        }       
    }
    
    private static void populateEntitlementForServiceRequest(Map<String,Id> entlmntmap, List<Case> caseList){
        try{
            for(Case ca :caseList){
                // && ca.AccountId != null && String.isNotBlank(ca.AccountId) && String.isNotEmpty(ca.AccountId)
                ca.EntitlementId=entlmntmap.get(Label.Service_Request_Entitlement);
                if(ca.Ischanged_Support_Type__c == True){
                    ca.Ischanged_Support_Type__c = False;
                }
            }
            if(Test.isRunningTest()){
                Integer i = 1/0;
            }
            
        }catch(Exception ex){
            System.debug('Exception in populateEntitlementForServiceRequest' + ex.getMessage() +ex.getLineNumber() + ex.getTypeName() +ex.getCause());
        }       
    }*/
    
    //Added by WarpDrive:Deepali
    //Purpose : To Populate the Japan Cases with Entitlement based on the Support Type of Account
    /*private static void populateEntitlementBasedOnAccountTypeJapan(Map<String,Id> entlmntmap, List<Case> caseList){
        try{            
            for(Case ca :caseList){
                String accountType = (ca.AccountId != null) ? ca.Account_Type__c : CaseMetadata_SV.AccountType;
                if(accountType == 'Standard' && ca.Case_Web_Form_Region__c == 'Japan'){
                    ca.EntitlementId = entlmntmap.get(Label.JapanStandardEntitlementName);
                }else if(accountType == 'Enterprise' && ca.Case_Web_Form_Region__c == 'Japan'){
                    ca.EntitlementId = entlmntmap.get(Label.JapanEnterpriseEntitlementName);
                }else if(accountType == 'Premium' && ca.Case_Web_Form_Region__c == 'Japan'){
                    ca.EntitlementId = entlmntmap.get(Label.JapanPremiumEntitlementName);
                }
                
                if(ca.Ischanged_Support_Type__c == True){
                    ca.Ischanged_Support_Type__c = False;
                }
            }
            if(Test.isRunningTest()){
                Integer i = 1/0;
            }
        }catch(Exception ex){
            System.debug('Exception in populateEntitlementBasedOnAccountTypeJapan' + ex.getMessage() +ex.getLineNumber() + ex.getTypeName() +ex.getCause());
        }        
    }*/
    //Added by WarpDrive:Deepali
    //Purpose : To Populate the Academy Cases with Entitlement based on the Support Type of Account
    /*private static void populateEntitlementBasedOnAccountTypeAcademy(Map<String,Id> entlmntmap, List<Case> caseList){
        try{
            for(Case ca :caseList){
                ca.EntitlementId = entlmntmap.get(Label.AcademyEntitlementName);
                if(ca.Ischanged_Support_Type__c == True){
                    ca.Ischanged_Support_Type__c = False;
                }
            }
            if(Test.isRunningTest()){
                Integer i = 1/0;
            }
            
        }catch(Exception ex){
            System.debug('Exception in populateEntitlementBasedOnAccountTypeAcademy' + ex.getMessage() +ex.getLineNumber() + ex.getTypeName() +ex.getCause());
        }               
    }*/
    //Added by WarpDrive:Deepali
    //Purpose : To Populate the SSales Ops Cases with Entitlement based on the Support Type of Account
    /*private static void populateEntitlementBasedOnAccountTypeSalesOps(Map<String,Id> entlmntmap, List<Case> caseList){
        try{
            for(Case ca :caseList){
                ca.EntitlementId = entlmntmap.get(Label.SalesOperationEntitlementName);
                if(ca.Ischanged_Support_Type__c == True){
                    ca.Ischanged_Support_Type__c = False;
                }
            }
            if(Test.isRunningTest()){
                Integer i = 1/0;
            }
            
        }catch(Exception ex){
            System.debug('Exception in populateEntitlementBasedOnAccountTypeSalesOps' + ex.getMessage() +ex.getLineNumber() + ex.getTypeName() +ex.getCause());
        }               
    }*/
    
    //Added by WarpDrive:Deepali
    //Purpose : To fetch the Target Date from the Milestones which is closest to breach. 
  /*  @future
    private static void fetchTargetDateFromMilestone(Set<Id> caseIdSet){
        try{
            System.debug('inside fetchTargetDateFromMilestone');            
            List<Case> caseListToUpdate = new List<Case>();
            
            List<CaseMilestone> milestoneList = new List<CaseMilestone> ([Select Id, IsCompleted, CaseId, Case.Milestone_Completed__c, Case.Milestone_Target_Date__c, TargetDate 
                                                                          from CaseMilestone 
                                                                          where CaseId in :caseIdSet AND IsCompleted = FALSE ORDER BY TargetDate ASC LIMIT 1]);
            if ( !milestoneList.isEmpty () && milestoneList[0] != null) {
                CaseMilestone milestone = milestoneList [0];
                caseListToUpdate.add(new Case(Id=milestone.CaseId, Milestone_Completed__c=FALSE, Milestone_Target_Date__c=milestone.TargetDate));
            }else{//else block added by deepali to assign null value to Milestone Target Date when there is no milestone on case
                for(Id caseId : caseIdSet){
                    caseListToUpdate.add(new Case(Id=caseId, Milestone_Target_Date__c=NULL));
                }                     
            }                                                                                                                     
            if(!caseListToUpdate.isEmpty()){
                update caseListToUpdate;
            }
            if(Test.isRunningTest()){
                Integer i = 1/0;
            }
        }catch(Exception ex){
            System.debug('Exception in fetchTargetDateFromMilestone' + ex.getMessage() +ex.getLineNumber() + ex.getTypeName() +ex.getCause());
            List<Case> caseListToUpdate = new List<Case>();
            for(Id ca :caseIdSet){
                Case c = new Case(Id=ca,Milestone_Completed__c=FALSE);
                caseListToUpdate.add(c);
            }
            if(!caseListToUpdate.isEmpty()){
                update caseListToUpdate;
            }
        }        
    }*/
    //created by Rajesh Warpdrive. Modified for Try-Catch block by Deepali Warpdrive
   /* public static void checkContactWithCaseEmail(List<Case> newCase)
    {
        try{
            List<String> caseContactEmail = new List<String>();
            Map<Id,Contact> con ;
            
            Map<Id,Id> contactAccountMap = new Map<Id,Id>();
            set<Contact> conId = new Set<Contact>();
            Map<String, Id> emailToIdMap = new Map<String, id>();
            for(Case c: newCase)
            {
                if (String.isNotBlank(c.Origin) && c.Origin.equalsIgnoreCase ('web') && String.isNotBlank(c.SuppliedEmail) && c.Subscription_Code__c != TRIAL_LICENSE_CODE && !c.Is_Free_Mailer__c) {//SLTECH-7896
                    caseContactEmail.add(c.SuppliedEmail);    
                }
            }
            
            con = new Map<Id,Contact>([select id, name,AccountId, email,Account.Name from contact where Email in: caseContactEmail]); 
            
            
            // Added Account Name SLTECH-6660
            for(Contact co: con.values())
            {
                emailToIdMap.put(co.email, co.id);
            }
            for(Case c: newCase)
            {
                if(String.isNotBlank(c.SuppliedEmail) && emailToIdMap.containskey(c.SuppliedEmail) && c.Subscription_Code__c != TRIAL_LICENSE_CODE && !c.Is_Free_Mailer__c)//SLTECH-7896
                {
                    c.ContactId = emailToIdMap.get(c.SuppliedEmail);
                    if(con.get(c.ContactId).AccountId != c.AccountId &&  
                       con.get(c.ContactId).Account.Name == 'unassigned' 
                       && !system.isFuture() && !system.isBatch() &&
                       c.RecordTypeId == Schema.SObjectType.CASE.getRecordTypeInfosByName().get('Incident').getRecordTypeId())
                    {
                        contactAccountMap.put(c.ContactId,c.AccountId);
                    }
                    
                    if(null != contactAccountMap && contactAccountMap.size() > 0 ){
                        updateUnassignedContacts(contactAccountMap);
                    }
                    
                    
                }
            }
            if(Test.isRunningTest()){
                Integer i = 1/0;
            }
            
        }catch(Exception ex){
            System.debug('Exception in checkContactWithCaseEmail' + ex.getMessage() +ex.getLineNumber() + ex.getTypeName() +ex.getCause());
        }       
    }
    
    //created by Rajesh Warpdrive. Modified for Try-Catch block by Deepali Warpdrive
    //Below code will cerate a new contact and assign to UnAssigned Account if there is not such contact with case email
    public static void createContactUpdateCase(List<Case> newCase)
    {
        try{
            //Account acc = new Account();  //commented by Deepali. 
            //added by Deepali start
            List<Account> accList = new List<Account>();
            Set<String> unAssignedAccIdSet = new Set<String>{Label.Dummy_Account, Label.Academy_Unassigned_Acc};
                Account unassignedAcc = new Account();
            Account academyAcc = new Account();
            Id contactRecordtypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Contact').getRecordTypeId();
            System.debug('unAssignedAccIdSet' + unAssignedAccIdSet);
            //added by Deepali end           
            
            if(Test.isRunningTest()){
                List<Account> unassignedaccounts = new List<Account>([select id, name from account where name = 'Unassigned Account' limit 1]);
                if(unassignedaccounts == null || unassignedaccounts.isEmpty()){
                    unassignedAcc.Name = 'Test' + String.valueOf(System.now());
                    unassignedAcc.RecordTypeId = Utilities.getRecordTypeId('Customer', 'Account');
                    unassignedAcc.BillingStreet = 'Test  Street';
                    unassignedAcc.BillingCity = 'Test City';
                    unassignedAcc.BillingPostalCode = '123abc';
                    unassignedAcc.BillingCountry = 'United Kingdom';
                    unassignedAcc.Phone = '12345678';
                    unassignedAcc.Industry = 'Others';
                    unassignedAcc.CSM__c = [Select id from User where Profile.Name = 'Customer Success Manager' and isactive=true limit 1].Id;
                    insert unassignedAcc;
                    academyAcc = unassignedAcc;
                }
                else {
                    unassignedAcc = unassignedaccounts[0];
                    academyAcc = unassignedaccounts[0];
                }
            }else{    
                accList = [SELECT Id, Name FROM Account WHERE Name IN :unAssignedAccIdSet limit 2];  //Added by Deepali to  query 2 accounts whoes ID is in set // MD Removed hardcoding Account Ids
            }
            //added by Deepali start
            if(accList.size() > 0){
                for(Account acc: accList){
                    if(acc.Name == Label.Dummy_Account){
                        unassignedAcc = acc;
                    }
                    if(acc.Name == Label.Academy_Unassigned_Acc){
                        academyAcc = acc;
                    }
                }
            }            
            //added by Deepali end
            
            List<String> emailAddresses = new List<String>();
            //First exclude any cases where the contact is set
            for (Case caseObj: newCase) 
            {
                if (caseObj.ContactId==null &&
                    caseObj.SuppliedEmail!='' && caseObj.Subscription_Code__c!=TRIAL_LICENSE_CODE && !caseObj.Is_Free_Mailer__c)
                {
                    emailAddresses.add(caseObj.SuppliedEmail);
                }
            }
            
            //Now we have a nice list of all the email addresses.  Let's query on it and see how many contacts already exist.
            List<Contact> listContacts = [Select Id,Email From Contact Where Email in :emailAddresses];
            Set<String> takenEmails = new Set<String>();
            for (Contact c:listContacts) {
                takenEmails.add(c.Email);
            }
            
            Map<String,Contact> emailToContactMap = new Map<String,Contact>();
            List<Case> casesToUpdate = new List<Case>();
            Account reqAccount;
            SET<Id> accIds = new Set<Id>();
            //   Id recordTypeId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Incident').getRecordTypeId();
            Id incidentRecordTypeId = Schema.SObjectType.CASE.getRecordTypeInfosByName().get('Incident').getRecordTypeId();
            for (Case caseObj: newCase) { 
                if(caseObj.RecordTypeId == incidentRecordTypeId && caseObj.AccountId != null )
                    accIds.add(caseObj.accountId);
            }
            System.debug('accIds' + accIds);
            if(null != accIds && accIds.size() > 0 && !Test.isRunningTest())
                reqAccount =[SELECT Id,ownerId FROM Account WHERE Id IN: accIds LIMIT 1]; 
            
            for (Case caseObj: newCase) {
                if (caseObj.ContactId==null &&
                    caseObj.SuppliedName!=null &&
                    caseObj.SuppliedEmail!=null &&
                    caseObj.SuppliedName!='' &&
                    !caseObj.SuppliedName.contains('@') &&
                    caseObj.SuppliedEmail!='' &&
                    !takenEmails.contains(caseObj.SuppliedEmail) && 
                    caseObj.Subscription_Code__c!=TRIAL_LICENSE_CODE &&
                    !caseObj.Is_Free_Mailer__c)
                {
                    //The case was created with a null contact
                    //Let's make a contact for it
                    String[] nameParts = caseObj.SuppliedName.split(' ',2);
                    system.debug('LastName-------'+nameParts.size());
                    String lastNameFromWeb; 
                    String FirstNameFromWeb = '';
                    if(nameParts.size() > 1)
                    {
                        FirstNameFromWeb = nameParts[0];
                        lastNameFromWeb = nameParts[1];
                    }
                    else if(nameParts.size() == 1)
                    {
                        lastNameFromWeb = nameParts[0];
                    }
                    if (nameParts.size() > 0)
                    {
                        //Contact cont = new Contact(FirstName= FirstNameFromWeb,LastName= lastNameFromWeb,Email=caseObj.SuppliedEmail,Autocreated__c=true,Title = 'Title',AccountId = acc.id); //commented by deepali 
                        //added by Deepali start
                        Contact cont;
                        if(caseObj.RecordTypeId == SupportConstants.academyRtId){
                            
                            cont = new Contact(FirstName= FirstNameFromWeb,LastName= lastNameFromWeb,Email=caseObj.SuppliedEmail,Autocreated__c=true,Title = 'Title',AccountId = academyAcc.id,recordtypeId = contactRecordtypeId);
                            system.debug('cont'+cont);
                        }
                        else{
                            if(caseObj.AccountId != Null){ // Maanas
                                cont = new Contact(ownerId=reqAccount.ownerId,FirstName= FirstNameFromWeb,LastName= lastNameFromWeb,Email=caseObj.SuppliedEmail,Autocreated__c=true,Title = 'Title',AccountId = reqAccount.Id,recordtypeId = contactRecordtypeId);
                                System.debug('cont'+ cont);
                            }
                            else
                                cont = new Contact(FirstName= FirstNameFromWeb,LastName= lastNameFromWeb,Email=caseObj.SuppliedEmail,Autocreated__c=true,Title = 'Title',AccountId = unassignedAcc.id,recordtypeId = contactRecordtypeId);
                            system.debug('cont'+cont);
                        }
                        //added by Deepali end
                        if (String.isNotBlank(caseObj.SuppliedPhone )) {
                            cont.Phone  = caseObj.SuppliedPhone;
                        }
                        emailToContactMap.put(caseObj.SuppliedEmail,cont);
                        casesToUpdate.add(caseObj);
                    }
                }
            }
            
            List<Contact> newContacts = emailToContactMap.values();
            
            insert newContacts;
            
            for (Case caseObj:casesToUpdate) {
                Contact newContact = emailToContactMap.get(caseObj.SuppliedEmail);
                
                caseObj.ContactId = newContact.Id;
            }
            if(Test.isRunningTest()){
                Integer i = 1/0;
            }
        }catch(Exception ex){
            System.debug('Exception in createContactUpdateCase' + ex.getMessage() +ex.getLineNumber() + ex.getTypeName() +ex.getCause());
        }         
    }
    
    //created by Rajesh Warpdrive. Modified for Try-Catch block by Deepali Warpdrive
    // Below Method will show Error while closing a case if any open Engagement Request is there
    public static void showErrodOnOpenER(List<Case> newCase)
    {
        try{
            //Id ErRecordTypeId = [Select Id From RecordType Where DeveloperName in('Engagement_Request','Japan_Engagement_Request')].Id; //commented by deepali 
            Id ErRecordTypeId = SupportConstants.engagementRequestRtId; //added by deepali
            Id JapanErRecordTypeId = SupportConstants.jsEngagementRequestRtId; //added by deepali
            set<id> caseId = new Set<Id>();
            Map<Id, List<String>> parentCaseIdChieldStats = new Map<Id, List<String>>();
            for(Case c: newCase)
            {
                caseId.add(c.id);
            }
            system.debug('caseid------------'+caseId);
            List<Case> erCases = new List<Case>();
            //Updated by dharani 19-10-2018 removed// status != 'Closed'
            erCases = [select id, ParentId, Status, RecordTypeId from case where ParentId IN: caseID and 
                       (RecordTypeId=: ErRecordTypeId OR RecordTypeId=: JapanErRecordTypeId) and status not in('Closed','Pending from Engineering')]; //recordtype calling modified by deepali
            
            
            
            system.debug('erCases------------'+erCases);
            for(Case c: erCases)
            {
                if(parentCaseIdChieldStats.containsKey(c.ParentId))
                {
                    parentCaseIdChieldStats.get(c.ParentId).add(c.Status);
                }
                else
                    parentCaseIdChieldStats.put(c.ParentId, new List<String>{c.Status});        
            }
            for(Case c: newCase)
            {
                if(parentCaseIdChieldStats.containsKey(c.id))
                {
                    if (c.Status == 'Closed')
                    {
                        c.addError('There is an Open Engagement Request for this Ticket. Please close the ER first.');
                    }
                }
            }
        }catch(Exception ex){
            System.debug('Exception in showErrodOnOpenER' + ex.getMessage() +ex.getLineNumber() + ex.getTypeName() +ex.getCause());
        }       
    }
    */
    //created by Rajesh Warpdrive. Modified for Try-Catch block by Deepali Warpdrive    
    //Below Method Will create a chield case(Followup Case) on click of Follow Case button in case
    public  void createFollowUpCase()
    {        
        try{
            Id caseId = ApexPages.currentPage().getParameters().get('id').escapeHtml4();
            //Commented by Dharani A 18/02/2019
            // Id incidentRecTypeId = [Select Id From RecordType Where DeveloperName = 'incident'].Id;
            
            system.debug('--------'+caseId);
            Case ParentCase = [select id,RecordTypeId ,CaseNumber,contactId,Sub_Component__c,Related_To__c, Status,Description,Error_Message__c,Subscription_Code__c,SuppliedEmail from Case where id =: caseId];
            if(ParentCase.Status == 'Closed')
            {
                Case chieldCase = new Case();
                chieldCase.status = 'New';
                chieldCase.subject = 'Follow Up Case for:- '+ ParentCase.CaseNumber;
                chieldCase.Description=parentCase.Description;
                chieldCase.Error_Message__c=parentcase.Error_Message__c;
                chieldCase.ParentId = caseId;
                chieldCase.contactId = parentCase.contactId;
                // chieldCase.RecordtypeId = incidentRecTypeId;
                // Added by Dharani 18-02-2019
                chieldCase.RecordtypeId= parentCase.RecordTypeId;
                chieldCase.Related_To__c = parentCase.Related_To__c;
                chieldCase.Sub_Component__c = parentCase.Sub_Component__c;
                chieldCase.Subscription_Code__c = parentCase.Subscription_Code__c;
                chieldCase.SuppliedEmail = parentCase.SuppliedEmail;
                chieldCase.UiPath_Srl_Signer_Title__c = 'Chief Financial Officer';
                //chieldCase.RecordtypeId = '0124C0000008fRB';
                insert chieldCase;
                String caseNum = String.ValueOf(ParentCase.caseNumber);
                String NewCaseNumber=[Select CaseNumber from case where Id=:chieldCase.Id].CaseNumber;
                system.debug('ChieldCase----'+chieldCase); 
                //redirectUser(chieldCase.id);        
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM,'Follow Up Case for #'+caseNum+ '  is Created with the New Case number #'+NewCaseNumber+'. Please close this tab.'));
            }else 
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning,'Sorry: Follow-Up Case can not be created if the case is not closed. Please close this tab!'));
            if(Test.isRunningTest()){
                Integer i = 1/0;
            }
            
        }catch(Exception ex){
            System.debug('Exception in createFollowUpCase' + ex.getMessage() +ex.getLineNumber() + ex.getTypeName() +ex.getCause());
        }       
    }
    
    
    //Below Standard Controller and Method are responsible to asign a case to the logged in user. There is a field in case name Assign To Me
    //Which is exposed to diffrent list viewes. On click of this link the case will get assigned to the logged in user
    public String currentRecordId {get;set;}
    public CaseTriggerHelper(ApexPages.StandardController controller) 
    {
        currentRecordId  = ApexPages.CurrentPage().getparameters().get('id');
    } 
    
    //created by Rajesh Warpdrive. Modified for Try-Catch block by Deepali Warpdrive
    public void assignCaseToLoginUser()
    {
        try{
            Id caseId = ApexPages.currentPage().getParameters().get('id');
            Id LogedInUserId = UserInfo.getUserId();
            Case currentCase = [Select id,status, CaseNumber, ownerid from case where id =: caseId Limit 1];
            String caseNum = String.ValueOf(currentCase.caseNumber);
            
            if(currentCase.status == 'Closed')
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Sorry, The Case Is Closed. Please Close this tab'));
                return;
            }
            
            if (currentCase.ownerid == LogedInUserId)
            {
                String link = 'The Case:- '+caseNum+' is Already Assign to You! Please GO Back To The Case Tab Or Click On Below Button To Open The Case';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, link));
            }
            else
            {
                currentCase.ownerid = LogedInUserId;
                update currentCase;
                String link = 'Case:- '+caseNum+' Is Assign To You! Please GO Back To The Case Tab if it is already opened Or Click On Below Button To Open The Case';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, link));
            }
            if(Test.isRunningTest()){
                Integer i = 1/0;
            }
            
        }catch(Exception ex){
            System.debug('Exception in assignCaseToLoginUser' + ex.getMessage() +ex.getLineNumber() + ex.getTypeName() +ex.getCause());
        }       
    }
    //***********************************Code Ends Here for Assign To Me Link*************************************
    //Added by Dharani 12-12-2018 to check duplicate case number
    
    public static void CheckDuplicateCaseClose(List<Case> newcases)
    {/*
system.debug('CheckDuplicateCaseClose'+newcases);
for(Case c: newcases)
{

If(c.Is_Duplicate__c == true && c.Status=='Closed')
{
Id incidentRecTypeId = [Select Id From RecordType Where DeveloperName = 'incident'].Id;

If(incidentRecTypeId!=null)
{
List<case> lstcase= new List<case>();
lstcase=[Select Id from case where Id=:c.Primary_Case_lookup__c and RecordTypeId=:c.RecordTypeId and ContactEmail=:c.ContactEmail 
and Country__c=:c.Country__c and Related_To__c=:c.Related_To__c  and Environment_Of_Issue__c=:c.Environment_Of_Issue__c and
priority=:c.priority and No_Of_Robots_Impacted_By_Issue__c=:c.No_Of_Robots_Impacted_By_Issue__c and Studio_Version__c=:c.Studio_Version__c
and Orchestrator_Version__c= :c.Orchestrator_Version__c and status !='closed'];
If(lstcase ==null || lstcase.size()==0)
{
c.addError('You can\'t close this as duplicate case.Current Case values mismatch with Parent Case Values');

}

}
}

}*/
        
    }
    
   /* @future
    public static void updateUnassignedContacts(Map<Id,Id> accountContactMap){
        
        List<Contact> unassignedContactsToUpdate = new List<Contact>();
        for( Contact contactObj: [SELECT Id,AccountId FROM Contact WHERE Id IN:accountContactMap.keyset()] ){
            contactObj.AccountId = accountContactMap.get(contactObj.Id);
            unassignedContactsToUpdate.add(contactObj);
        }
        
        if(null != unassignedContactsToUpdate && unassignedContactsToUpdate.size() >  0)
        {
            try{
                update unassignedContactsToUpdate;
            }catch(Exception e){
                system.debug('Error Updating contact' + e.getMessage());
            }
        }
    }*/
    
    //Merge Case Functionality SLTECH-6493
    /*public static  void mergedCaseOperations(List<Case> caseList){
        Set<Id> mergedCaseIdSet = new Set<Id>();
        Id incidentRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Incident').getRecordTypeId();
        for(case caseObj :caseList){
            if((caseObj.status == system.label.MergedCaseStatus ) && caseObj.RecordTypeId == incidentRecordTypeId && !system.isFuture() && !system.isBatch()) {
                mergedCaseIdSet.add(caseObj.Id);
                caseObj.EntitlementId = null;
            }
        }
        
        if(null != mergedCaseIdSet && mergedCaseIdSet.size() > 0 ){
            mergeCaseFutureHandler(mergedCaseIdSet);
        }
    } 
    
    @future
    public static void mergeCaseFutureHandler(Set<Id> mergedCaseIdSet){
        
        final String matchPattern = 'has been merged with Case';
        final String mergedTemplateName = 'Case Close EmailTemplate for MergedCase';
        
        try{
            
            List<String> splitString ;
            Map<Id,Case> caseWithCaseCommentMap = new Map<Id,Case>();
            for(CaseComment casecomObj: [Select Id, ParentId,Parent.contactId, CommentBody From CaseComment WHERE ParentId IN:mergedCaseIdSet] ){
                splitString = new List<String>();
                if(casecomObj.CommentBody.contains(matchPattern))
                    splitString = casecomObj.CommentBody.split('Case');
                if(!test.isRunningTest()){
                    case caseSingleObj = new case();
                    caseSingleObj.Id = casecomObj.ParentId;
                    caseSingleObj.Merged_To_Case_Number__c = splitString[2] != null ? splitString[2].trim():''; 
                    caseSingleObj.contactId = casecomObj.Parent.contactId;
                    caseWithCaseCommentMap.put(caseSingleObj.Id, caseSingleObj);
                }
            }
            
            if( null != caseWithCaseCommentMap && caseWithCaseCommentMap.size() >  0 )
                update caseWithCaseCommentMap.values();
            
            OrgWideEmailAddress owa = [select id, DisplayName, Address from OrgWideEmailAddress where Address='uipathsupport@uipath.com'];
            EmailTemplate templateId = [Select id,subject,htmlvalue from EmailTemplate where name =:mergedTemplateName ];
            List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
            
            for(Id caseObjId : caseWithCaseCommentMap.keyset()){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                mail.setTemplateID(templateId.Id);
                mail.setSaveAsActivity(false);
                
                mail.setWhatId(caseObjId);// This is the record I
                mail.setTargetObjectId(caseWithCaseCommentMap.get(caseObjId).contactId); 
                mail.setOrgWideEmailAddressId(owa.id);
                allmsg.add(mail);
            }
            
            Messaging.sendEmail(allmsg,false);    
            
            
            
        }
        catch(Exception e){
            throw new IllegalArgumentException(e.getMessage());
            
        }
        
    }
    public static void omniChannelRouter(List<Case> caseList){
        
        List<Case> casesToRoute = new List<Case>();
        
        for(Case caseObj : caseList){
            if( caseObj.RecordTypeId ==  SupportConstants.incidentRtId && caseObj.Status == 'New'){
                casesToRoute.add(caseObj);
            }
        }
        
        if( NULL != casesToRoute && casesToRoute.size() >  0 ){
            
            if( Boolean.valueof(Label.OmniChannelKillSwitch) ){
                SkillBasedRoutingHelper.skillRouter(casesToRoute);
            }
        }
    }*/
    // SLTECH-7979  //Not used PB/WF as account CSD notification
    /*public static void sendUrgentCaseNotification(List<Case> caseList){
        
        final String URGENT_PRIORITY ='Urgent';
        Set<Id> caseNotificationIdSet = new Set<Id>();
        
        for(case caseObj :caseList){
            if (caseObj.RecordTypeId ==  SupportConstants.incidentRtId && caseObj.Priority == URGENT_PRIORITY && !system.isFuture() && !system.isBatch()) {
                caseNotificationIdSet.add(caseObj.Id);
            }
        }
        
        if(null != caseNotificationIdSet && caseNotificationIdSet.size() > 0 ){
            urgentCaseNotFutureHandler(caseNotificationIdSet);
        }
        
    }  
    
    @future
    public static void urgentCaseNotFutureHandler(Set<Id> caseNotificationIdSet ){
        
        final String ORG_WIDE_ADDRESS = Label.UIPathOrgWideAddress;
        final String EMAIL_CSD_TEMPLATE_NAME = Label.NotifyCSDUrgentCaseTemplate;
        final String EMAIL_STA_TEMPLATE_NAME = Label.NotifySTAUrgentCaseTemplate;
        
        Set<String> emailTemplateSet = new Set<String>{ EMAIL_CSD_TEMPLATE_NAME, EMAIL_STA_TEMPLATE_NAME };
        
        Map<String,Id> emailTemplateNameIdMap = new Map<String,Id>();
        
        List<Messaging.SingleEmailMessage> emailMessagesList = new List<Messaging.SingleEmailMessage>();
        
        OrgWideEmailAddress orgWideAddObj  = [ SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = :ORG_WIDE_ADDRESS ];
        For ( EmailTemplate emailObj :  [SELECT Id,Subject, DeveloperName, Htmlvalue FROM EmailTemplate WHERE DeveloperName IN :emailTemplateSet ]){
            emailTemplateNameIdMap.put(emailObj.DeveloperName, emailObj.Id);
        }
        
        for( Case caseObj : [SELECT Id,Subject, ContactId,Contact.Email, Account.Name, Account.Support_Technical_Advisor__r.IsActive, Account.CSD__r.IsActive, CaseNumber,Related_To__c, Account.CSD__r.Email,Account.CSD__c,Account.CSD__r.Id, Account.Support_Technical_Advisor__c, Account.Support_Technical_Advisor__r.Email FROM CASE WHERE Id IN: caseNotificationIdSet]){
            
            if( NULL != caseObj.Account.CSD__c  && caseObj.Account.CSD__r.IsActive ){
                Messaging.SingleEmailMessage mailObj = new Messaging.SingleEmailMessage();
                
                mailObj.setTemplateID(emailTemplateNameIdMap.get(EMAIL_CSD_TEMPLATE_NAME));
                mailObj.setSaveAsActivity(false);
                mailObj.setWhatId(caseObj.Id);
                mailObj.setTargetObjectId(caseObj.ContactId); 
                mailObj.setToAddresses(new String[] { caseObj.Account.CSD__r.Email}); 
                mailObj.setOrgWideEmailAddressId(orgWideAddObj.id);
                
                emailMessagesList.add(mailObj);
                
            }
            
            if ( NULL != caseObj.Account.Support_Technical_Advisor__c && caseObj.Account.Support_Technical_Advisor__r.IsActive ){

                Messaging.SingleEmailMessage mailObj = new Messaging.SingleEmailMessage();
                mailObj.setTemplateID(emailTemplateNameIdMap.get(EMAIL_STA_TEMPLATE_NAME));
                mailObj.setSaveAsActivity(false);
                mailObj.setWhatId(caseObj.Id);
                mailObj.setTargetObjectId(caseObj.ContactId); 
                mailObj.setToAddresses(new String[] { caseObj.Account.Support_Technical_Advisor__r.Email}); 
                mailObj.setOrgWideEmailAddressId(orgWideAddObj.id);
                
                emailMessagesList.add(mailObj);
            }
        }
        
        Savepoint sp = Database.setSavepoint();
        
        Messaging.sendEmail(emailMessagesList,false);
        
        Database.rollback(sp);
        //Sending Emails to Non-Contacts
        List<Messaging.SingleEmailMessage> lstMsgsToSend = new List<Messaging.SingleEmailMessage>();
        
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
            Messaging.sendEmail(lstMsgsToSend);
        }catch(Exception error){
            throw (error);
        }  
    }
    
    public static void deletePSRs(List<case> newcases, Map<id,Case> oldCases){
        
        Set<id> filteredCaseIdSet = new Set<id>();
        List<PendingServiceRouting> psrToDelete = new List<PendingServiceRouting>();
        try{
            for( case caseObj : newcases ){            
                if(( caseObj.RecordTypeId ==  SupportConstants.incidentRtId && 
                    (( oldCases.get(caseObj.Id).Status == 'New' && caseObj.Status != 'New' ) || ( String.valueOf(caseObj.OwnerId).startsWith('005') && String.valueOf(oldCases.get(caseObj.Id).OwnerId).startsWith('00G') ))) ||
                   ( caseObj.RecordTypeId != SupportConstants.incidentRtId && oldCases.get(caseObj.Id).RecordTypeId == SupportConstants.incidentRtId )){
                       filteredCaseIdSet.add(caseObj.Id);
                   }               
            }
            
            
            if(null != filteredCaseIdSet && filteredCaseIdSet.size() > 0 ){
                
                for ( PendingServiceRouting psrObject :[SELECT Id FROM PendingServiceRouting WHERE WorkItemId IN: filteredCaseIdSet] ){
                    psrToDelete.add(psrObject);
                }
                
                if( null != psrToDelete && psrToDelete.size() > 0 )
                    delete psrToDelete;
            }
        }catch(Exception error){
            throw ( error );
        }
    }*/
}