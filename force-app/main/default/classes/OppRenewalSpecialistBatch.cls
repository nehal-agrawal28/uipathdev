/* run batch =============================================================
   OppRenewalSpecialistBatch  oppBatchObject = new OppRenewalSpecialistBatch(); 
   Id batchId = Database.executeBatch(oppBatchObject);
==========================================================================*/

global class OppRenewalSpecialistBatch implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
        String query = 'SELECT Id, Renewal_Specialist__c, AccountId FROM Opportunity WHERE Renewal_Specialist__c != null';
        return Database.getQueryLocator(query);
    }
     
    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        system.debug('scope =====> ' + scope);
        Set<Id> accountIds = new Set<Id>();
        for(Opportunity opp: scope) {        
            accountIds.add(opp.AccountId);
        }
        
        List<OpportunityTeamMember> relatedOTM = [SELECT Id, OpportunityId, UserId, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId IN: scope];
        Set<Id> resultOppSet = new Set<Id>();
        Map<Id, Set<Id>> resultOTMUsers = new Map<Id, Set<Id>>();
        for(OpportunityTeamMember otm: relatedOTM) {
            if(otm.TeamMemberRole == 'Renewal Specialist')
                resultOppSet.add(otm.OpportunityId);
            if(!resultOTMUsers.containsKey(otm.OpportunityId)) {
                Set<Id> userSet = new Set<Id>();
                userSet.add(otm.UserId);
                resultOTMUsers.put(otm.OpportunityId, userSet);
            } else {
                Set<Id> userSet = resultOTMUsers.get(otm.OpportunityId);
                userSet.add(otm.UserId);
                resultOTMUsers.put(otm.OpportunityId, userSet);
            }
        }
        
        List<AccountTeamMember> relatedATM = [SELECT AccountId, UserId FROM AccountTeamMember WHERE AccountId IN: accountIds AND TeamMemberRole = 'Renewal Specialist'];
        Set<String> resultAccSet = new Set<String>(); 
        for(AccountTeamMember atm: relatedATM) {
            resultAccSet.add(String.valueOf(atm.AccountId) + '-' + String.valueOf(atm.UserId));
        }
        
        system.debug('resultOppSet =====> ' + resultOppSet);
        system.debug('resultOTMUsers =====> ' + resultOTMUsers);
        system.debug('resultAccSet =====> ' + resultAccSet);

        List<OpportunityTeamMember> OTMtoInsert = new List<OpportunityTeamMember>();
        List<AccountTeamMember> ATMtoInsert = new List<AccountTeamMember>();
        for(Opportunity opp: scope) { 
            Set<Id> currentUserSet = new Set<Id>(); 
            if(resultOTMUsers.containsKey(opp.Id))
                currentUserSet = resultOTMUsers.get(opp.Id);   
            system.debug('currentUserSet =====> ' + currentUserSet);
            if(!resultOppSet.contains(opp.Id) && !currentUserSet.contains(opp.Renewal_Specialist__c)) {
                OpportunityTeamMember newOTM = new OpportunityTeamMember();
                newOTM.OpportunityId = opp.Id;
                newOTM.UserId = opp.Renewal_Specialist__c;
                newOTM.TeamMemberRole = 'Renewal Specialist';
                newOTM.OpportunityAccessLevel = 'Edit';
                
                OTMtoInsert.add(newOTM);
            }
            if(!resultAccSet.contains(String.valueOf(opp.AccountId) + '-' + String.valueOf(opp.Renewal_Specialist__c))) {
                AccountTeamMember newATM = new AccountTeamMember();
                newATM.AccountId = opp.AccountId;
                newATM.AccountAccessLevel = 'Read';
                newATM.UserId = opp.Renewal_Specialist__c;
                newATM.TeamMemberRole = 'Renewal Specialist';
                newATM.OpportunityAccessLevel = 'Edit';
                
                ATMtoInsert.add(newATM);
            }
        }
        system.debug('OTMtoInsert =====> ' + OTMtoInsert);
        system.debug('ATMtoInsert =====> ' + ATMtoInsert);

        if(OTMtoInsert.size() > 0) {
            try {
                insert OTMtoInsert;
            } catch(Exception e) {
                System.debug(e);
            }
        }
            
        if(ATMtoInsert.size() > 0) {
            try {
                insert ATMtoInsert;
            } catch(Exception e) {
                System.debug(e);
            }
        }
               
         
    }
    
  
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
    }
}