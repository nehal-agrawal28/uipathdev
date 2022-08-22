@isTest(isParallel=false)
public with sharing class LeadFunnelQueueableTest_MK {
  private static final String Suspect = LeadMetadata_MK.FUNNEL_SUSPECT_STAGE;
  private static final String MQL = LeadMetadata_MK.FUNNEL_MQL_STAGE;
  private static final String MarketingQualified = LeadMetadata_MK.FUNNEL_MQL_TYPE;
  private static final String Accepted = LeadMetadata_MK.ACCEPTED_STATUS;
  private static final String Disqualified = LeadMetadata_MK.DISQUALIFIED_STATUS;
  private static final String Declined = LeadMetadata_MK.DECLINED_STATUS;
  private static final String SalesProgressed = LeadMetadata_MK.FUNNEL_SALES_PROGRESSED_TYPE;
  private static final String SalesGenerated = LeadMetadata_MK.FUNNEL_SALES_GENERATED_TYPE;
  private static final String CompanyName = 'Company';
  private static final String LeadCountry = 'France';
  private static final String LastName = 'LeadName';
  private static final String LeadEmail = 'testconvert@email.com';
  private static final String LeadDepartment = 'IT';

  @isTest
  public static void LeadStatusSuspectMQLAcceptedTest() {
    Lead oldLead = new Lead(
      LastName = LastName,
      Country = LeadCountry,
      Email = LeadEmail,
      Company = CompanyName,
      Status = Suspect,
      Department1__c = LeadDepartment
    );
    insert oldLead;

    Lead updatedLead = oldLead.clone();
    updatedLead.Id = oldLead.Id;
    updatedLead.Status = MQL;
    update updatedLead;

    LeadFunnelQueueable_MK funnelQueueable = new LeadFunnelQueueable_MK(
      new List<Lead>{ updatedLead },
      new Map<Id, sObject>{ oldLead.Id => oldLead }
    );
    funnelQueueable.execute(null);

    List<Funnel__c> funnel = [
      SELECT Id, Lead__c, Stage__c, Funnel_Type__c
      FROM Funnel__c
      WHERE Lead__c = :updatedLead.Id
      LIMIT 1
    ];

    System.assertEquals(MQL, funnel[0].Stage__c);
    System.assertEquals(MarketingQualified, funnel[0].Funnel_Type__c);

    Lead sgUpdatedLead = oldLead.clone();
    sgUpdatedLead.Id = oldLead.Id;
    sgUpdatedLead.Status = SalesGenerated;
    update sgUpdatedLead;

    LeadFunnelQueueable_MK funnelQueueableSG = new LeadFunnelQueueable_MK(
      new List<Lead>{ sgUpdatedLead },
      new Map<Id, sObject>{ updatedLead.Id => updatedLead }
    );
    funnelQueueableSG.execute(null);

    List<Funnel__c> funnelSG = [
      SELECT Id, Lead__c, Stage__c, Funnel_Type__c
      FROM Funnel__c
      WHERE Lead__c = :sgUpdatedLead.Id
      LIMIT 1
    ];

    System.assertEquals(LeadMetadata_MK.FUNNEL_SGL_STAGE, funnelSG[0].Stage__c);
    System.assertEquals(MarketingQualified, funnelSG[0].Funnel_Type__c);

    Lead acceptedUpdatedLead = oldLead.clone();
    acceptedUpdatedLead.Id = oldLead.Id;
    acceptedUpdatedLead.Status = Accepted;
    update acceptedUpdatedLead;

    LeadFunnelQueueable_MK funnelQueueableAccepted = new LeadFunnelQueueable_MK(
      new List<Lead>{ acceptedUpdatedLead },
      new Map<Id, sObject>{ updatedLead.Id => updatedLead }
    );
    funnelQueueableAccepted.execute(null);

    List<Funnel__c> funnelTAL = [
      SELECT Id, Lead__c, Stage__c, Funnel_Type__c
      FROM Funnel__c
      WHERE Lead__c = :acceptedUpdatedLead.Id
      LIMIT 1
    ];

    System.assertEquals(LeadMetadata_MK.FUNNEL_TAL_STAGE, funnelTAL[0].Stage__c);
    System.assertEquals(MarketingQualified, funnelTAL[0].Funnel_Type__c);

    Lead disqualifiedUpdatedLead = oldLead.clone();
    disqualifiedUpdatedLead.Id = oldLead.Id;
    disqualifiedUpdatedLead.Status = Disqualified;
    disqualifiedUpdatedLead.Disqualified_Reason__c = 'Student';
    update disqualifiedUpdatedLead;

    LeadFunnelQueueable_MK funnelQueueableDisqualified = new LeadFunnelQueueable_MK(
      new List<Lead>{ disqualifiedUpdatedLead },
      new Map<Id, sObject>{ acceptedUpdatedLead.Id => acceptedUpdatedLead }
    );
    funnelQueueableDisqualified.execute(null);

    List<Funnel__c> funnelDis = [
      SELECT Id, Lead__c, Stage__c, Funnel_Type__c
      FROM Funnel__c
      WHERE Lead__c = :disqualifiedUpdatedLead.Id
      LIMIT 1
    ];

    System.assertEquals(Disqualified, funnelDis[0].Stage__c);
    System.assertEquals(MarketingQualified, funnelDis[0].Funnel_Type__c);
  }

  @isTest
  public static void leadStatusSuspectSGDeclinedTest() {
    Lead oldLead = new Lead(
      LastName = LastName,
      Country = LeadCountry,
      Email = LeadEmail,
      Company = CompanyName,
      Status = Suspect,
      Department1__c = LeadDepartment
    );
    insert oldLead;

    Lead updatedLead = oldLead.clone();
    updatedLead.Id = oldLead.Id;
    updatedLead.Status = SalesGenerated;
    update updatedLead;

    LeadFunnelQueueable_MK funnelQueueable = new LeadFunnelQueueable_MK(
      new List<Lead>{ updatedLead },
      new Map<Id, sObject>{ oldLead.Id => oldLead }
    );
    funnelQueueable.execute(null);

    List<Funnel__c> funnel = [
      SELECT Id, Lead__c, Stage__c, Funnel_Type__c
      FROM Funnel__c
      WHERE Lead__c = :updatedLead.Id
      LIMIT 1
    ];

    System.assertEquals(LeadMetadata_MK.FUNNEL_SPL_STAGE, funnel[0].Stage__c);
    System.assertEquals(SalesProgressed, funnel[0].Funnel_Type__c);

    Lead declinedUpdatedLead = oldLead.clone();
    declinedUpdatedLead.Id = oldLead.Id;
    declinedUpdatedLead.Status = Declined;
    declinedUpdatedLead.Declined_Reason__c = 'Student';
    update declinedUpdatedLead;

    LeadFunnelQueueable_MK funnelQueueableSG = new LeadFunnelQueueable_MK(
      new List<Lead>{ declinedUpdatedLead },
      new Map<Id, sObject>{ updatedLead.Id => updatedLead }
    );
    funnelQueueableSG.execute(null);

    List<Funnel__c> funnelSG = [
      SELECT Id, Lead__c, Stage__c, Funnel_Type__c
      FROM Funnel__c
      WHERE Lead__c = :declinedUpdatedLead.Id
      LIMIT 1
    ];

    System.assertEquals(Declined, funnelSG[0].Stage__c);
    System.assertEquals(SalesProgressed, funnelSG[0].Funnel_Type__c);
  }

  @isTest
  public static void leadStatusConvertedTest() {
    Lead oldLead = new Lead(
      LastName = LastName,
      Country = LeadCountry,
      Email = LeadEmail,
      Company = CompanyName,
      Industry = 'Education',
      Status = Suspect,
      Department1__c = LeadDepartment
    );
    insert oldLead;

    Lead updatedLead = oldLead.clone();
    updatedLead.Id = oldLead.Id;
    updatedLead.Status = SalesGenerated;
    update updatedLead;

    LeadFunnelQueueable_MK funnelQueueable = new LeadFunnelQueueable_MK(
      new List<Lead>{ updatedLead },
      new Map<Id, sObject>{ oldLead.Id => oldLead }
    );
    funnelQueueable.execute(null);

    List<Funnel__c> funnel = [
      SELECT Id, Lead__c, Stage__c, Funnel_Type__c
      FROM Funnel__c
      WHERE Lead__c = :updatedLead.Id
      LIMIT 1
    ];

    System.assertEquals(LeadMetadata_MK.FUNNEL_SPL_STAGE, funnel[0].Stage__c);
    System.assertEquals(SalesProgressed, funnel[0].Funnel_Type__c);

    Lead disqualifiedUpdatedLead = oldLead.clone();
    disqualifiedUpdatedLead.Id = oldLead.Id;
    disqualifiedUpdatedLead.Status = Disqualified;
    disqualifiedUpdatedLead.Disqualified_Reason__c = 'Student';
    update disqualifiedUpdatedLead;

    LeadFunnelQueueable_MK funnelQueueableDisqualified = new LeadFunnelQueueable_MK(
      new List<Lead>{ disqualifiedUpdatedLead },
      new Map<Id, sObject>{ updatedLead.Id => updatedLead }
    );
    funnelQueueableDisqualified.execute(null);

    Lead updatedSGLead = oldLead.clone();
    updatedSGLead.Id = oldLead.Id;
    updatedSGLead.Status = SalesGenerated;
    update updatedSGLead;

    LeadFunnelQueueable_MK funnelQueueableSales = new LeadFunnelQueueable_MK(
      new List<Lead>{ updatedSGLead },
      new Map<Id, sObject>{ disqualifiedUpdatedLead.Id => disqualifiedUpdatedLead }
    );
    funnelQueueableSales.execute(null);

    Lead acceptedUpdatedLead = updatedSGLead.clone();
    acceptedUpdatedLead.Id = updatedSGLead.Id;
    acceptedUpdatedLead.Status = Accepted;
    acceptedUpdatedLead.OwnerId = UserInfo.getUserId();
    acceptedUpdatedLead.Industry = 'Education';
    update acceptedUpdatedLead;

    LeadFunnelQueueable_MK funnelQueueableAccepted = new LeadFunnelQueueable_MK(
      new List<Lead>{ acceptedUpdatedLead },
      new Map<Id, sObject>{ updatedSGLead.Id => updatedSGLead }
    );
    funnelQueueableAccepted.execute(null);

    List<Funnel__c> funnelTAL = [
      SELECT Id, Lead__c, Stage__c, Funnel_Type__c
      FROM Funnel__c
      WHERE Lead__c = :acceptedUpdatedLead.Id AND Closed__c = FALSE
      LIMIT 1
    ];

    System.assertEquals(LeadMetadata_MK.FUNNEL_TAL_STAGE, funnelTAL[0].Stage__c);
    System.assertEquals(SalesProgressed, funnelTAL[0].Funnel_Type__c);

    /*Database.LeadConvert lc = new Database.LeadConvert();
    lc.setLeadId(acceptedUpdatedLead.Id);

    LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
    lc.setConvertedStatus(convertStatus.MasterLabel);
    lc.setDoNotCreateOpportunity(true);

    Database.LeadConvertResult lcr = Database.convertLead(lc);
    System.assert(lcr.isSuccess());

    List<Lead> convertedLead = [SELECT Id FROM Lead WHERE Id = :acceptedUpdatedLead.Id LIMIT 1];

    LeadFunnelQueueable_MK funnelQueueableConverted = new LeadFunnelQueueable_MK(
      new List<Lead>{ convertedLead[0] },
      new Map<Id, sObject>{ acceptedUpdatedLead.Id => acceptedUpdatedLead }
    );
    funnelQueueableConverted.execute(null);*/
  }

  @isTest
  public static void leadStatusInsertLeadTest() {
    Lead newLead = new Lead(
      LastName = LastName,
      Country = LeadCountry,
      Email = LeadEmail,
      Company = CompanyName,
      Industry = 'Education',
      Status = Suspect,
      Department1__c = LeadDepartment
    );

    LeadFunnelQueueable_MK funnelQueueableNewLead = new LeadFunnelQueueable_MK(new List<Lead>{ newLead }, null);
    funnelQueueableNewLead.execute(null);
  }
}