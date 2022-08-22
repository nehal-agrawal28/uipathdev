public with sharing class OppAccCustomerStageQueueable_SL extends AbstractQueueable {
  List<Opportunity> records;
  public OppAccCustomerStageQueueable_SL(List<SObject> records) {
    super('OppAccCustomerStageQueueable_SL');
    this.records = records;
  }

  public override void work() {
    this.processOpportunityUpdates(Collection.of(this.records).pluckIds(Opportunity.AccountId));
  }

  public static void processOpportunities(List<Opportunity> Records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.StageName },
      Records,
      existingRecords
    );

    List<Opportunity> eligibleRecords = Collection.of(Records)
      .filter(hasChanged)
      .filter(
        Match.field(Opportunity.AccountId)
          .hasValue()
          .also(Opportunity.StageName)
          .equals(OpportunityMetadata_SL.CLOSED_WON_BOOKED)
      )
      .asList();

    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new OppAccCustomerStageQueueable_SL(eligibleRecords));
    }
  }

  private void processOpportunityUpdates(List<Id> accountIds) {
    List<Opportunity> allOpportunities = [
      SELECT
        Id,
        AccountId,
        CloseDate,
        (
          SELECT Id, Name, Quantity, OpportunityId, Opportunity.AccountId, Opportunity.Type
          FROM OpportunityLineItems
          WHERE Name LIKE :'%Attended Robot%' OR Name LIKE :'%Unattended Robot%'
        )
      FROM Opportunity
      WHERE AccountId IN :accountIds AND StageName = :OpportunityMetadata_SL.CLOSED_WON_BOOKED
    ];

    Map<Id, List<Opportunity>> opportunitesByAccountId = (Map<Id, List<Opportunity>>) Collection.of(allOpportunities)
      .groupByIds(Opportunity.AccountId);
    Map<Id, List<OpportunityLineItem>> allOliMap = new Map<Id, List<OpportunityLineItem>>();

    for (Opportunity opp : allOpportunities) {
      for (OpportunityLineItem oli : opp.OpportunityLineItems) {
        if (!allOliMap.containsKey(oli.Opportunity.AccountId)) {
          List<OpportunityLineItem> newOliList = new List<OpportunityLineItem>();
          newOliList.add(oli);
          allOliMap.put(oli.Opportunity.AccountId, newOliList);
        } else {
          List<OpportunityLineItem> exliList = allOliMap.get(oli.Opportunity.AccountId);
          exliList.add(oli);
          allOliMap.put(oli.Opportunity.AccountId, exliList);
        }
      }
    }

    List<Account> accounts = [
      SELECT Id, Customer_Stage__c, Overwrite_Customer_Stage__c, RecordTypeId
      FROM Account
      WHERE Id IN :accountIds
    ];

    for (Account acc : accounts) {
      if (acc.Overwrite_Customer_Stage__c == false) {
        if (opportunitesByAccountId.containsKey(acc.Id)) {
          // get total no. of Robots (both attended & unattended)
          Integer noOfRobots = 0;
          if (allOliMap.containsKey(acc.Id)) {
            List<OpportunityLineItem> oliRobots = allOliMap.get(acc.Id);
            for (OpportunityLineItem orobot : oliRobots) {
              if (orobot.Opportunity.Type != 'Renewal') {
                noOfRobots += Integer.valueOf(orobot.Quantity);
              }
            }
          }

          if (noOfRobots == 0) {
            acc.Customer_Stage__c = 'Prove';
          }

          if (noOfRobots > 0 && noOfRobots <= 5) {
            acc.Customer_Stage__c = 'Establish';
          }

          if (noOfRobots > 5 && noOfRobots <= 20) {
            acc.Customer_Stage__c = 'Expand';
          }

          if (noOfRobots > 20) {
            acc.Customer_Stage__c = 'Scale';
          }
        } else {
          acc.Customer_Stage__c = 'Prove';
        }
      }

      if (acc.RecordTypeId == AccountMetadata.customerProspectRecordType) {
        acc.RecordTypeId = AccountMetadata.customerRecordType;
      }
    }

    update accounts;
  }
}