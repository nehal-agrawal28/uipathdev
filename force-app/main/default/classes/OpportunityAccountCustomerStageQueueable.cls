/**
* Partial refactor might be needed -- Vali Coteanu
*/
public with sharing class OpportunityAccountCustomerStageQueueable extends AbstractQueueable {
    private final List<SObject> opportunities;
    
    public OpportunityAccountCustomerStageQueueable(List<SObject> opportunities) {
    	super('OpportunityAccountCustomerStageQueueable');
    	this.opportunities = opportunities;
        //to allow for logging against record. only used in non-bulk contexts
        if (opportunities !=null && opportunities.size() == 1) {
            this.setPrimaryRecordId(opportunities.get(0).Id);
        }
  	}
    
    public override void work() {
    	this.updateOpps(this.opportunities);
  	}
    
    private void updateOpps(List<Opportunity> opportunities) {
        
        Set<Id> accountIds = new Set<Id>(Collection.of(opportunities).pluckIds(Opportunity.AccountId));
        
        List<Opportunity> allOpps = [SELECT Id, AccountId, CloseDate, 
                                     (SELECT Id, Name, Quantity, OpportunityId, Opportunity.AccountId, Opportunity.Type 
                                      FROM OpportunityLineItems 
                                      WHERE Name LIKE: '%Attended Robot%' OR Name LIKE: '%Unattended Robot%')
                                     FROM Opportunity 
                                     WHERE AccountId IN: accountIds AND StageName = 'Closed Won Booked'];
                
        Map<Id, List<Opportunity>> allOppsMap = new Map<Id, List<Opportunity>>();
        Map<Id, List<OpportunityLineItem>> allOliMap = new Map<Id, List<OpportunityLineItem >>();
        
        for(Opportunity opp: allOpps) {
            
            if(!allOppsMap.containsKey(opp.AccountId)) {
                List<Opportunity> newOppList = new List<Opportunity>();
                newOppList.add(opp);
                allOppsMap.put(opp.AccountId, newOppList);
            } 
            else {
                List<Opportunity> exOppList = allOppsMap.get(opp.AccountId);
                exOppList.add(opp);
                allOppsMap.put(opp.AccountId, exOppList);
            }
            
            for(OpportunityLineItem oli: opp.OpportunityLineItems) {
                if(!allOliMap.containsKey(oli.Opportunity.AccountId)) {
                    List<OpportunityLineItem> newOliList = new List<OpportunityLineItem>();
                    newOliList.add(oli);
                    allOliMap.put(oli.Opportunity.AccountId, newOliList);
                }
                else {
                    List<OpportunityLineItem> exliList = allOliMap.get(oli.Opportunity.AccountId); 
                    exliList.add(oli);
                    allOliMap.put(oli.Opportunity.AccountId, exliList);
                }
            }
        }
        
        List<Account> accounts = [SELECT Id, Customer_Stage__c, Overwrite_Customer_Stage__c, recordTypeId FROM Account WHERE Id in: accountIds];
        Id customerProspectRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer_Prospect').getRecordTypeId();
        Id customerRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        
        for(Account acc: accounts) {
            
            if (acc.Overwrite_Customer_Stage__c ==  false) {

                if(allOppsMap.containsKey(acc.Id)) {
                
                    // get total no. of Robots (both attended & unattended)
                    Integer noOfRobots = 0;
                    if(allOliMap.containsKey(acc.Id)) {
                        List<OpportunityLineItem> oliRobots = allOliMap.get(acc.Id);
                        for(OpportunityLineItem orobot: oliRobots){
                            if (orobot.Opportunity.Type != 'Renewal'){
                                noOfRobots += Integer.valueOf(orobot.Quantity);
                            }
                        }          
                    }               
                           
                    if(noOfRobots == 0)
                        acc.Customer_Stage__c = 'Prove';
                    
                    if(noOfRobots > 0 && noOfRobots <= 5)
                        acc.Customer_Stage__c = 'Establish';
                    
                    if(noOfRobots > 5 && noOfRobots <= 20)
                        acc.Customer_Stage__c = 'Expand';
                    
                    if(noOfRobots > 20)
                        acc.Customer_Stage__c = 'Scale'; 
                                     
                    } else {
                    acc.Customer_Stage__c = 'Prove';
                }

             }
            
            if (acc.recordTypeId == customerProspectRT){
                acc.recordTypeId = customerRT;
            }
        }
        
        if (!accounts.isEmpty()) {
          update accounts;
        }
    }
}