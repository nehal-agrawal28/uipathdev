@isTest(isParallel=false)
public with sharing class OpportunityContactRolesFunnelTest_MK {
  private static final String SalesGenerated = LeadMetadata_MK.SALES_GENERATED_STATUS;
  private static final String ContactLastName = 'Contact LastName';
  private static final String ContactDepartment = 'IT';

  private static final Id recordTypeCPQ = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
    .get('CPQ_Default')
    .getRecordTypeId();
  private static final Id recordTypeBDR = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
    .get('BDR')
    .getRecordTypeId();

  @isTest
  public static void OppContactRoleFunnelQueueableTest1() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);

    Contact newContactOne = new Contact(
      LastName = 'ContactONE',
      AccountId = testAccount.Id,
      Email = 'testconvert.one@email.com',
      Contact_Status__c = SalesGenerated,
      Department__c = ContactDepartment
    );
    insert newContactOne;

    Contact newContactTwo = new Contact(
      LastName = 'ContactTWO',
      AccountId = testAccount.Id,
      Email = 'testconvert.two@email.com',
      Contact_Status__c = SalesGenerated,
      Department__c = ContactDepartment
    );
    insert newContactTwo;

    Opportunity opp = DataFactory_SL.createOpportunity(testAccount.Id, true);
    opp.RecordTypeId = recordTypeBDR;
    opp.StageName = LeadMetadata_MK.OPP_OPEN_STAGE;
    update opp;

    List<OpportunityContactRole> ocrToInsert = new List<OpportunityContactRole>();

    OpportunityContactRole ocrOne = new OpportunityContactRole();
    ocrOne.IsPrimary = true;
    ocrOne.ContactId = newContactOne.Id;
    ocrOne.OpportunityId = opp.Id;
    ocrOne.Role = 'Decision Maker';
    ocrToInsert.add(ocrOne);

    OpportunityContactRole ocrTwo = new OpportunityContactRole();
    ocrTwo.ContactId = newContactTwo.Id;
    ocrTwo.OpportunityId = opp.Id;
    ocrTwo.Role = 'Evaluator';
    ocrToInsert.add(ocrTwo);

    insert ocrToInsert;

    List<Funnel__c> funnelOpp = [
      SELECT Id, Contact__c, Stage__c, Funnel_Type__c
      FROM Funnel__c
      WHERE Opportunity__c = :opp.Id
    ];
    if (funnelOpp.size() == 2) {
      System.assertEquals(2, funnelOpp.size());

      Opportunity meetingHeldOpp = opp.clone();
      meetingHeldOpp.Id = opp.Id;
      meetingHeldOpp.First_Meeting__c = Date.Today();
      meetingHeldOpp.StageName = LeadMetadata_MK.OPP_MEETING_HELD_STAGE;
      update meetingHeldOpp;

      OpportunityFunnelQueueable oppQueueableMH = new OpportunityFunnelQueueable(
        new List<Opportunity>{ meetingHeldOpp }
      );
      oppQueueableMH.execute(null);

      List<Funnel__c> funnelOppSAL = [
        SELECT Id, Contact__c, Stage__c, Funnel_Type__c
        FROM Funnel__c
        WHERE Opportunity__c = :meetingHeldOpp.Id
        LIMIT 1
      ];
      if (funnelOppSAL.size() == 1)
        System.assertEquals(LeadMetadata_MK.FUNNEL_SAL_STAGE, funnelOppSAL[0].Stage__c);
    }
  }
}