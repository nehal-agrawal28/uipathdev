public with sharing class OppOnboardingPlaybookQueueable_SL extends AbstractQueueable {
  private final List<SObject> opps;

  public OppOnboardingPlaybookQueueable_SL(List<SObject> opps) {
    super('OppOnboardingPlaybookQueueable_SL');
    this.opps = opps;
    //to allow for logging against record. only used in non-bulk contexts
    if (opps != null && opps.size() == 1) {
      this.setPrimaryRecordId(opps.get(0).Id);
    }
  }

  public override void work() {
    this.updateTypeOnOpties(this.opps);
  }

  private void updateTypeOnOpties(List<Opportunity> opps) {
    List<Task> tasks = new List<Task>();
    for (Opportunity opp : opps) {
      //Create the default 7 Tasks
      for (Integer i = 0; i < 7; i++) {
        Task tsk = new Task();
        tsk.OwnerId = opp.OwnerId;
        tsk.RecordTypeId = TaskMetadata_CM.OnboardingPlaybookRecordType;
        tsk.Status = 'Open';
        tsk.WhatId = opp.Id;
        tasks.add(tsk);
      }

      //Customise the Task #1
      tasks.get(0).Action_Point__c = 'Internal Sales Handoff';
      tasks.get(0).ActivityDate = System.Today();
      tasks.get(0)
        .Documentation_URL__c = 'https://uipath.sharepoint.com/:f:/s/CustomerSuccessEMEA/EieoErvHk39OgT28Dwfg-m8BW56I78WhcGaCmKYOtIkB_A?e=76dfWs';
      tasks.get(0).Onboarding_Task_Description__c =
        '-Inform the customer about the Onboarding 100 program.' +
        '\n' +
        '-Confirm customer interest and suitability for the program.';
      tasks.get(0).Priority = 'Normal';
      tasks.get(0).Subject = 'Deal Closed';

      //Customise the Task #2
      tasks.get(1).Action_Point__c = 'Agree on Key onboarding goals';
      tasks.get(1).ActivityDate = System.Today().addDays(10);
      tasks.get(1)
        .Documentation_URL__c = 'https://uipath.sharepoint.com/:f:/s/CustomerSuccessEMEA/EieoErvHk39OgT28Dwfg-m8BW56I78WhcGaCmKYOtIkB_A?e=SKnEhq';
      tasks.get(1).Onboarding_Task_Description__c =
        '-Arrange and hold Sponsor Meeting' +
        '\n' +
        '-Audience: Customer RPA sponsor' +
        '\n' +
        '  Structure of Onboarding 100' +
        '\n' +
        '  Establish customer’s goals' +
        '\n' +
        ' High level overview of UiPath products & services';
      tasks.get(1).Priority = 'High';
      tasks.get(1).Subject = 'Meeting with Customer Sponsor';

      //Customise the Task #3
      tasks.get(2).Action_Point__c = 'Introduction and 30 days plan';
      tasks.get(2).ActivityDate = System.Today().addDays(10);
      tasks.get(2)
        .Documentation_URL__c = 'https://uipath.sharepoint.com/:f:/s/CustomerSuccessEMEA/EieoErvHk39OgT28Dwfg-m8BW56I78WhcGaCmKYOtIkB_A?e=SKnEhq';
      tasks.get(2).Onboarding_Task_Description__c =
        '-Arrange and hold Intro Meeting' +
        '\n' +
        '-Audience: All customer CoE members' +
        '\n' +
        'Content:' +
        '\n' +
        '  Technology Readiness' +
        '\n' +
        '  License Activation' +
        '\n' +
        '  Onboarding Goals' +
        '\n' +
        '  COE Enablement' +
        '\n' +
        '  Training Requirements' +
        '\n' +
        '  Commitment & plan for next 20 days';
      tasks.get(2).Priority = 'High';
      tasks.get(2).Subject = 'COE Introductory Meeting';

      //Customise the Task #4
      tasks.get(3).Action_Point__c = 'Progress Update and Enablement topic';
      tasks.get(3).ActivityDate = System.Today().addDays(40);
      tasks.get(3)
        .Documentation_URL__c = 'https://uipath.sharepoint.com/:f:/s/CustomerSuccessEMEA/EieoErvHk39OgT28Dwfg-m8BW56I78WhcGaCmKYOtIkB_A?e=SKnEhq';
      tasks.get(3).Onboarding_Task_Description__c =
        '-Arrange and hold 30-day progress meeting' +
        '\n' +
        '-Audience: Customer RPA Sponsor, CoE Lead, other onboarding stakeholders' +
        '\n' +
        'Content:' +
        '\n' +
        '  Goal status check-in' +
        '\n' +
        '  Process Discovery & Pipeline Management' +
        '\n' +
        '  Plan for next 30 days';
      tasks.get(3).Priority = 'Normal';
      tasks.get(3).Subject = 'Progress Meeting - 30 Days';

      //Customise the Task #5
      tasks.get(4).Action_Point__c = 'Progress Update and Enablement topic';
      tasks.get(4).ActivityDate = System.Today().addDays(70);
      tasks.get(4)
        .Documentation_URL__c = 'https://uipath.sharepoint.com/:f:/s/CustomerSuccessEMEA/EieoErvHk39OgT28Dwfg-m8BW56I78WhcGaCmKYOtIkB_A?e=SKnEhq';
      tasks.get(4).Onboarding_Task_Description__c =
        '-Arrange and hold 60-day progress meeting' +
        '\n' +
        '-Audience: Customer RPA Sponsor, CoE Lead, other onboarding stakeholders' +
        '\n' +
        'Content:' +
        '\n' +
        '  Goal status check-in' +
        '\n' +
        '  Plan for next 30 days';
      tasks.get(4).Priority = 'Normal';
      tasks.get(4).Subject = 'Progress Meeting - 60 Days';

      //Customise the Task #6
      tasks.get(5).Action_Point__c = 'Progress Update and Enablement topic';
      tasks.get(5).ActivityDate = System.Today().addDays(100);
      tasks.get(5)
        .Documentation_URL__c = 'https://uipath.sharepoint.com/:f:/s/CustomerSuccessEMEA/EieoErvHk39OgT28Dwfg-m8BW56I78WhcGaCmKYOtIkB_A?e=SKnEhq';
      tasks.get(5).Onboarding_Task_Description__c =
        '-Arrange and hold 90-day progress meeting' +
        '\n' +
        '-Audience: Customer RPA Sponsor, CoE Lead, other onboarding stakeholders' +
        '\n' +
        'Content:' +
        '\n' +
        '  Goal status check-in' +
        '\n' +
        '  Go-forward plan for success after Onboarding is concluded';
      tasks.get(5).Priority = 'Normal';
      tasks.get(5).Subject = 'Progress Meeting - 90 Days';

      //Customise the Task #7
      tasks.get(6).Action_Point__c = 'Progress Update and Enablement topic';
      tasks.get(6).ActivityDate = System.Today().addDays(110);
      tasks.get(6)
        .Documentation_URL__c = 'https://uipath.sharepoint.com/:f:/s/CustomerSuccessEMEA/EieoErvHk39OgT28Dwfg-m8BW56I78WhcGaCmKYOtIkB_A?e=SKnEhq';
      tasks.get(6).Last_Onboarding_Task__c = true;
      tasks.get(6).Onboarding_Task_Description__c =
        '-Send Onboarding survey to customer' +
        '\n' +
        '-Audience: Customer RPA Sponsor, CoE Lead, other onboarding stakeholders';
      tasks.get(6).Priority = 'High';
      tasks.get(6).Subject = 'Onboarding 100 - Survey';
    }
    insert tasks;
  }

  /**
   * Create series of Tasks on update
   */
  public static void setTypeOnUpdate(List<Opportunity> opps, Map<Id, SObject> existingOpps) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.Customer_Onboarding__c },
      opps,
      existingOpps
    );
    List<Opportunity> changedOpps = Collection.of(opps)
      .filter(hasChanged)
      .filter(Match.field(Opportunity.Customer_Onboarding__c).equals(true))
      .asList();

    if (!changedOpps.isEmpty()) {
      AbstractQueueable.enqueue(new OppOnboardingPlaybookQueueable_SL(changedOpps));
    }
  }
}