/**
 * Created by Mirela Chituc on 12/10/2020.
 * Insert or update opp related team members - opp owner, sales rep, KAP, PAM
 */

public without sharing class OpportunityTeamMemberQueueable extends AbstractQueueable {
    public final List<SObject> oppList;
    public final Map<Id, SObject> oppOldMap;
    
    public OpportunityTeamMemberQueueable(List<SObject> oppList, Map<Id, SObject> oppOldMap) {
        super('OpportunityTeamMemberQueueable');
        this.oppList= oppList;
        this.oppOldMap = oppOldMap;
        //to allow for logging against record. only used in non-bulk contexts
    if (oppList.size() == 1) {
      this.setPrimaryRecordId(oppList.get(0).Id);
    }
    }

    public override void work() {
        if (this.oppOldMap == null) {
            this.upsertOpportunityTeamMembers(this.oppList, null);
        } else {
            this.upsertOpportunityTeamMembers(this.oppList, this.oppOldMap);
        }
    }
    
    /*public static void createOTM(List<Opportunity> opps) {
        if (!opps.isEmpty()) {
            AbstractQueueable.enqueue(new OpportunityTeamMemberQueueable(opps, null));
        } 
    }
    
    public static void updateOTM(List<Opportunity> opps, Map<Id, SObject> existingOpps) {
        SObjectPredicate hasChanged = new HasRecordChanged(
            new Set<SObjectField>{
                Opportunity.OwnerId, Opportunity.AccountId, Opportunity.Sold_to_Partner__c, Opportunity.Tier_2_Partner__c, Opportunity.Influencers__c
            },
            opps,
            existingOpps
        );

        List<Opportunity> eligibleOpps = (List<Opportunity>) Collection.of(opps)
        .filter(hasChanged)
        .filter(
          Match.field(Opportunity.RecordTypeId)
          .isNotIn(
            new Set<Id>{
              OpportunityMetadata_SL.CPQLockedRecordType,
              OpportunityMetadata_SL.UipathStandardLockedRecordType
            }
          )
        )
        .asList();

        if (!eligibleOpps.isEmpty()) {
            AbstractQueueable.enqueue(new OpportunityTeamMemberQueueable(eligibleOpps, existingOpps));
        }
    }*/

    private void upsertOpportunityTeamMembers(List<Opportunity> opps, Map<Id, SObject> oldMap) {    
      //Set<Id> oppIds = (new Map<Id, SObject>(opps)).keySet();
              if (oldMap == null) {
            createOppTeamMemberOnInsert(opps);
        } else {
            Set<Id> oppIds = new Set<Id>();
            Map<Id, String> accIds = new Map<Id, String>();
            Map<Id, String> oldAccIds = new Map<Id, String>();
            Set<String> newTMSet = new Set<String>();
            Set<String> oldTMSet = new Set<String>();
            
            Set<Id> PAMIds = new Set<Id>();
            Set<String> ExcludePAMGeoSet = new Set<String>{'AMER', 'EMEA', 'APJ'};
            
            for (Opportunity opp : [SELECT Id, OwnerId, AccountId, Account.Geo__c, Account.Area__c, 
                    Influencers__c, Sold_to_Partner__c, Tier_2_Partner__c, Account.KAM_Id__c, Account.KAM_GSI__c
                          FROM Opportunity WHERE Id IN: opps]) {
                Opportunity oldOpp = (Opportunity)oldMap.get(opp.Id);
                String accString = '';
                String oldAccountString = '';
                Boolean changeOwner = false;
                if(opp.OwnerId != oldOpp.OwnerId) {
                    newTMSet.add(String.valueOf(opp.Id) + '-' + String.valueOf(opp.OwnerId) + '-' + 'Opportunity Owner');   
                    oldTMSet.add(String.valueOf(opp.Id) + '-' + String.valueOf(oldOpp.OwnerId));    
                    
                    if(opp.Account.KAM_Id__c != null) {
                        if(oldOpp.OwnerId == opp.Account.KAM_Id__c) {
                            newTMSet.add(String.valueOf(opp.Id) + '-' + String.valueOf(opp.Account.KAM_Id__c) + '-' + 'Key Account Manager');
                        }
                        if(opp.OwnerId == opp.Account.KAM_Id__c) {
                            oldTMSet.add(String.valueOf(opp.Id) + '-' + String.valueOf(opp.Account.KAM_Id__c));
                        }
                    }
                    if(opp.Account.KAM_GSI__c != null) {
                        if(oldOpp.OwnerId == opp.Account.KAM_GSI__c){
                            newTMSet.add(String.valueOf(opp.Id) + '-' + String.valueOf(opp.Account.KAM_GSI__c) + '-' + 'Key Account Manager');
                        }
                        if(opp.OwnerId == opp.Account.KAM_GSI__c) {
                            oldTMSet.add(String.valueOf(opp.Id) + '-' + String.valueOf(opp.Account.KAM_GSI__c));
                        }
                    }
                   
                    changeOwner = true;
                } else {
                    if (opp.AccountId != oldOpp.AccountId) {
                        if (
                          (!ExcludePAMGeoSet.contains(opp.Account.Geo__c) && ExcludePAMGeoSet.contains(oldOpp.Account.Geo__c)) ||
                          (ExcludePAMGeoSet.contains(opp.Account.Geo__c) && !ExcludePAMGeoSet.contains(oldOpp.Account.Geo__c))
                        ) {
                          PAMIds.add(opp.Id);
                        }
                    }
                    if(opp.Sold_to_Partner__c != oldOpp.Sold_to_Partner__c) {
                        if (opp.Sold_to_Partner__c != null) {
                            accString += opp.Sold_to_Partner__c + ';';
                        }
                        if (oldOpp.Sold_to_Partner__c != null) {
                            oldAccountString += oldOpp.Sold_to_Partner__c + ';';
                        }
                    } 
                    if(opp.Tier_2_Partner__c != oldOpp.Tier_2_Partner__c) {
                        if (opp.Tier_2_Partner__c != null) {
                            accString += opp.Tier_2_Partner__c + ';';
                        }
                        if (oldOpp.Tier_2_Partner__c != null) {
                            oldAccountString += oldOpp.Tier_2_Partner__c + ';';
                        }
                    } 
                    if(opp.Influencers__c != oldOpp.Influencers__c) {
                        Set<String> resultA = setDifference(opp.Influencers__c, oldOpp.Influencers__c);
                        Set<String> resultB = setDifference(oldOpp.Influencers__c, opp.Influencers__c);
                        
                        // account ids to insert
                        for (String inflId : resultA) {
                            if (!String.isEmpty(inflId)) {
                                accString += inflId.trim() + ';';
                            }
                        }
                        
                        // account ids to delete
                        for (String inflId : resultB) {
                            oldAccountString += inflId + ';';
                        }
                    }
                    if (!String.isEmpty(accString)) {
                        accIds.put(opp.Id, accString);
                    }
                    if (!String.isEmpty(oldAccountString)) {
                        oldAccIds.put(opp.Id, oldAccountString.deleteWhitespace());
                    }
                }   
                
                //if(newTMSet.size() > 0 || accIds.size() > 0) 
                if (changeOwner == true) {
                    oppIds.add(opp.Id);
                }
                
            }
            
             // Add / Delete PAMs if the account is changed ( PAM Exceptions : 'AMER', 'EMEA', 'Japan' )
            if(PAMIds.size() > 0) {
                PAMOnAccountChange(PAMIds);
            }

            if (newTMSet.size() > 0 || accIds.size() > 0 || oldAccIds.size() > 0  /* && !Test.isRunningTest() */) {
                createOppTeamMemberOnUpdate(oppIds, accIds, oldAccIds, newTMSet, oldTMSet);
            }
        }
    }
    
     private void PAMOnAccountChange(Set<Id> oppIds) {
        
        Set<String> ExcludePAMGeoSet = new Set<String>{'AMER', 'EMEA'};
        
        List<OpportunityTeamMember> otmAll = [SELECT Id, UserId, OpportunityId, Opportunity.AccountId, Opportunity.Account.Geo__c, 
                                    Opportunity.Account.Area__c, Created_on_opportunity_insert__c 
                                    FROM OpportunityTeamMember 
                                    WHERE OpportunityId IN: oppIds AND TeamMemberRole = 'Partner Account Manager' 
                                    ORDER BY CreatedDate ASC];
        List<Opportunity_Split__c> osAll = [SELECT Id, User__c, Opportunity__c 
                                    FROM Opportunity_Split__c 
                                    WHERE Opportunity__c IN: oppIds AND TeamMemberRole__c = 'Partner Account Manager'];    
        Map<String, Opportunity_Split__c> existingPAM = new Map<String, Opportunity_Split__c>(); 
        for(Opportunity_Split__c os: osAll)  {
            existingPAM.put(os.Opportunity__c + '-' + os.User__c, os);
        }
        
        List<Opportunity_Split__c> oppSplitListToCreate = new List<Opportunity_Split__c>();
        List<Opportunity_Split__c> oppSplitToDel = new List<Opportunity_Split__c>();
        for(OpportunityTeamMember otm: otmAll) {
            
            if(!existingPAM.containsKey(otm.OpportunityId + '-' + otm.UserId)) {
               if (
                  !(ExcludePAMGeoSet.contains(otm.Opportunity.Account.Geo__c) &&
                  otm.Created_on_opportunity_insert__c == true) &&
                  otm.Opportunity.Account.Area__c != 'Japan' 
                )
                {
                
                    Opportunity_Split__c oppSplit = new Opportunity_Split__c();
                    oppSplit.User__c = otm.UserId;
                    oppSplit.Opportunity__c = otm.OpportunityId;
                    oppSplit.TeamMemberRole__c = 'Partner Account Manager';
                    oppSplit.Percentage__c = 0;
                    oppSplitListToCreate.add(oppSplit);
                } 
            } else {
                if ((ExcludePAMGeoSet.contains(otm.Opportunity.Account.Geo__c) && otm.Created_on_opportunity_insert__c == true) ||
                otm.Opportunity.Account.Area__c == 'Japan') 
                {
                    Opportunity_Split__c oppSplit = existingPAM.get(otm.OpportunityId + '-' + otm.UserId);
                    oppSplitToDel.add(oppSplit);
                }
            }
        }   
        
        if(oppSplitToDel.size() > 0)  {
            delete oppSplitToDel;
        }  
        if(oppSplitListToCreate.size() > 0)  {
            insert oppSplitListToCreate;
        }                                              
    }
    
    private void createOppTeamMemberOnUpdate(Set<Id> newList, Map<Id, String> accIds, Map<Id, String> oldAccIds, Set<String> newTMSet, Set<String> oldTMSet) {
        
        if(newTMSet.size() > 0 || accIds.size() > 0 || oldAccIds.size() > 0) {
            if(accIds.size() > 0) {
                Map<Id, Set<Id>> oppAccounts = new Map<Id, Set<Id>>();
                Set<Id> accountIdSet = new Set<Id>();
                for(Id oppId : accIds.keySet()) {
                    String accString = accIds.get(oppId);
                    Set<Id> allAccIds = new Set<Id>();
                    for(String s: accString.split(';')) {
                        allAccIds.add(Id.valueOf(s));
                        accountIdSet.add(Id.valueOf(s));
                    }
                    oppAccounts.put(oppId, allAccIds);
                }
                Map<Id, Account> allAccsMap = new Map<Id, Account>([SELECT Id, OwnerId FROM Account WHERE Id IN: accountIdSet]);

                for(Id oppId: oppAccounts.keySet()) {
                    Set<Id> accSet = oppAccounts.get(oppId);
                    for(Id aId: accSet) {
                        Id userId = allAccsMap.get(aId).OwnerId;
                        newTMSet.add(String.valueOf(oppId) + '-' + String.valueOf(userId) + '-' + 'Partner Account Manager');
                    }
                }
            }
            
            
            if(oldAccIds.size() > 0) {
                Set<String> accoIDs = new Set<String>();
                for(Id oppId: oldAccIds.keySet()) {
                    String accIDString = oldAccIds.get(oppId);
                    for(String str: accIDString.split(';')){
                        if (!String.isEmpty(str) && str.length() >= 15) {
                            accoIDs.add(str.substring(0, 15));
                        }
                    }
                }
                
                Map<Id, Account> allAccsMap = new Map<Id, Account>([SELECT Id, OwnerId FROM Account WHERE Id IN: accoIDs]);
                System.debug('allAccsMap =====> ' + allAccsMap );
                
                for(Id oppId: oldAccIds.keySet()) {
                    String accIDString = oldAccIds.get(oppId);
                    for(String str: accIDString.split(';')) {
                        if(!String.isEmpty(str) && str.length() >= 15) {
                            Id accId = Id.valueOf(str);
                            Id userId = allAccsMap.get(accId).OwnerId;
                            oldTMSet.add(String.valueOf(oppId) + '-' + String.valueOf(userId));
                        }
                    }   
                }
            }
            
            for(String s: oldTMSet) {
                List<String> oldTMs = s.split('-');
                Id currentOppId = Id.valueOf(oldTMs[0]);
                if (!oldAccIds.containsKey(currentOppId)) {
                    oldAccIds.put(currentOppId, oldTMs[1]);
                }
            }

            List<OpportunityTeamMember> tmems = [SELECT Id, OpportunityId, UserId FROM OpportunityTeamMember 
                WHERE OpportunityId IN: oldAccIds.keySet() AND Created_on_opportunity_insert__c = TRUE AND TeamMemberRole != 'Opportunity Owner'];
            
            List<OpportunityTeamMember> toDeleteTM = new List<OpportunityTeamMember>();
            // here
            Set<Id> exOwnerUserIds = new Set<Id>();
            //exOwnerUserIds.add(otm.UserId);
            for(OpportunityTeamMember otm: tmems) {
                String oppUser = String.valueOf(otm.OpportunityId) + '-' + String.valueOf(otm.UserId);
                if(oldTMSet.contains(oppUser)) {
                    toDeleteTM.add(otm);
                }
            }

            if (toDeleteTM.size() > 0) {
                delete toDeleteTM;
            }

            // here - delete opp split if opp owner is added with another role
            List<Opportunity_Split__c> oppSplits = [SELECT Id, Opportunity__c, User__c FROM Opportunity_Split__c
                WHERE Opportunity__c IN: newList AND (TeamMemberRole__c = 'Opportunity Owner' OR TeamMemberRole__c = 'Partner Account Manager')];

            List<Opportunity_Split__c> toDeleteOS = new List<Opportunity_Split__c>();
            for(Opportunity_Split__c os: oppSplits) {
                String oppUser = String.valueOf(os.Opportunity__c) + '-' + String.valueOf(os.User__c);
                if (oldTMSet.contains(oppUser)) {
                    toDeleteOS.add(os);
                }
            }

            List<OpportunityTeamMember> toInsertTM = new List<OpportunityTeamMember>();
            List<Opportunity_Split__c> toInsertOS = new List<Opportunity_Split__c>();
            for(String s: newTMSet) {
                List<String> splS = s.split('-');
                
                OpportunityTeamMember otmSales = new OpportunityTeamMember();
                otmSales.OpportunityId = Id.valueOf(splS[0]);
                otmSales.UserId = Id.valueOf(splS[1]);
                otmSales.TeamMemberRole = splS[2];
                otmSales.OpportunityAccessLevel = 'Edit';
                otmSales.Created_on_opportunity_insert__c = true;
                toInsertTM.add(otmSales);
            }
            system.debug('UPDATE toDeleteTM =====> ' + toDeleteTM);
            system.debug('UPDATE toDeleteOS =====> ' + toDeleteOS);
            system.debug('UPDATE toInsertTM =====> ' + toInsertTM);


            if (toDeleteOS.size() > 0) {
                delete toDeleteOS;
            }

            if (toInsertTM.size() > 0) {
                insert toInsertTM;
            }
           
        }
    }
    
    private Set<String> setDifference(String setA, String setB) {
        Set<String> currentSetA = new Set<String>();
        if(setA != null) {
            List<String> currentListA = (setA.deleteWhitespace()).split(';');
            currentSetA = new Set<String>(currentListA);
        }
        
        Set<String> currentSetB = new Set<String>();
        if(setB != null) {
            List<String> currentListB = (setB.deleteWhitespace()).split(';');
            currentSetB = new Set<String>(currentListB);
        }
        
        Set<String> result = currentSetA.clone();
        result.removeAll(currentSetB);
       
        return result;
    }
    
    private void createOppTeamMemberOnInsert(List<Opportunity> opps) {
        // insert  
        Map<Id, Set<Id>> accIds = new Map<Id, Set<Id>>();
        Set<String> newTMSet = new Set<String>();
        Set<Id> allAccIds = new Set<Id>();
        
        List<Opportunity> allOpps = [SELECT Id, OwnerId, Owner.GIC_Sales__c, AccountId, Account.OwnerId, 
            Account.KAM_Id__c, Account.KAM_GSI__c, Influencer__c, Influencer__r.OwnerId, Influencers__c, CurrencyIsoCode,
            Sold_to_Partner__c, Sold_to_Partner__r.OwnerId, Tier_2_Partner__c, Tier_2_Partner__r.OwnerId 
            FROM Opportunity WHERE Id IN: opps];
        
        for (Opportunity opp : allOpps) {
            newTMSet.add(String.valueOf(opp.Id) + '-' + String.valueOf(opp.OwnerId) + '-' + 'Opportunity Owner');
            if (opp.Owner.GIC_Sales__c == true && opp.OwnerId != opp.Account.OwnerId) {
                newTMSet.add(String.valueOf(opp.Id) + '-' + String.valueOf(opp.Account.OwnerId) + '-' + 'Sales Representative');
            }
            if (opp.Account.KAM_Id__c != null && opp.Account.KAM_Id__c != opp.OwnerId) {
                newTMSet.add(String.valueOf(opp.Id) + '-' + String.valueOf(opp.Account.KAM_Id__c) + '-' + 'Key Account Manager');
            }
            if (opp.Account.KAM_GSI__c != null && opp.Account.KAM_GSI__c != opp.OwnerId) {
                newTMSet.add(String.valueOf(opp.Id) + '-' + String.valueOf(opp.Account.KAM_GSI__c) + '-' + 'Key Account Manager');
            }
            if (opp.AccountId != null && opp.Owner.GIC_Sales__c == false && opp.OwnerId != opp.Account.OwnerId) {
                newTMSet.add(String.valueOf(opp.Id) + '-' + String.valueOf(opp.Account.OwnerId) + '-' + 'Partner Account Manager');
            }
            if (opp.Sold_to_Partner__c != null) {
                newTMSet.add(String.valueOf(opp.Id) + '-' + String.valueOf(opp.Sold_to_Partner__r.OwnerId) + '-' + 'Partner Account Manager');
            }
            if (opp.Tier_2_Partner__c != null) {
                newTMSet.add(String.valueOf(opp.Id) + '-' + String.valueOf(opp.Tier_2_Partner__r.OwnerId) + '-' + 'Partner Account Manager');
            }
            
            if(opp.Influencers__c != null) {
                Set<Id> accIdSet = new Set<Id>();
                for (String inflId : opp.Influencers__c.split(';')) {
                     if(!String.isEmpty(inflId)) {
                         Id aId = Id.valueOf(inflId.trim());
                         accIdSet.add(aId);
                         allAccIds.add(aId);
                     }
                }
                accIds.put(opp.Id, accIdSet);
            }
        } 
        
        if(newTMSet.size() > 0 || accIds.size() > 0) {
            if(accIds.size() > 0) {
                Map<Id, Account> allAccsMap = new Map<Id, Account>([SELECT Id, OwnerId FROM Account WHERE Id IN: allAccIds]);
                for(Id oppId: accIds.keySet()) {
                    Set<Id> accIdSet = accIds.get(oppId);
                    for(Id aId: accIdSet) {
                        Id userId = allAccsMap.get(aId).OwnerId;
                        newTMSet.add(String.valueOf(oppId) + '-' + String.valueOf(userId) + '-' + 'Partner Account Manager');
                    }
                }
            }
            
            
            List<OpportunityTeamMember> toInsertTM = new List<OpportunityTeamMember>();
            for(String s: newTMSet) {
                List<String> splS = s.split('-');
                
                OpportunityTeamMember otmSales = new OpportunityTeamMember();
                otmSales.OpportunityId = Id.valueOf(splS[0]);
                otmSales.UserId = Id.valueOf(splS[1]);
                otmSales.TeamMemberRole = splS[2];
                otmSales.OpportunityAccessLevel = 'Edit';
                otmSales.Created_on_opportunity_insert__c = true;
                toInsertTM.add(otmSales);
            }
            if (toInsertTM.size() > 0) {
                insert toInsertTM;
            }
           
        }   
    }

}