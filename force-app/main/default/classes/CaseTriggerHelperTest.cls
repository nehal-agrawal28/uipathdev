@IsTest(isParallel=true)
public class CaseTriggerHelperTest {
  public static testMethod void checkContactWithCaseEmailTest() {
    List<Case> casenewList = new List<Case>();
    Id RecordTypeID1 = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('Japan_Academy')
      .getRecordTypeId();
    Id RecordTypeID2 = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Academy').getRecordTypeId();
    Id RecordTypeID3 = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('Sales_Operation')
      .getRecordTypeId();
    Test.StartTest();
    Account ac1 = new Account();
    ac1.Name = 'Unassigned Account';
    ac1.RecordTypeId = Utilities.getRecordTypeId('Customer', 'Account');
    ac1.BillingStreet = 'Test  Street';
    ac1.BillingCity = 'Test City';
    ac1.BillingPostalCode = '123abc';
    ac1.BillingCountry = 'Uganda';
    ac1.Country__c = 'Uganda';
    ac1.Phone = '12345678';
    ac1.Industry = 'Others';
    insert ac1;

    //Inserting Contact
    Contact con = new Contact();
    con.AccountId = ac1.id;
    con.FirstName = 'Test';
    con.LastName = String.valueOf(System.now());
    con.Email = 'test123123asd@asdawe.com';
    con.Title = 'Title';
    con.Department__c = 'IT';
    insert con;

    //Inserting Entitlement
    Entitlement e = new Entitlement();
    e.Name = Label.Premium_Account_Entitlement;
    e.AccountId = ac1.id;
    insert e;

    //Inserting Case0
    Case case0 = new Case(
      AccountId = ac1.Id,
      ContactId = con.Id,
      Status = 'New',
      Origin = 'Web',
      Priority = 'Medium',
      Country__c = 'United States',
      Related_To__c = 'Orchestrator',
      Time_Zone__c = 'GMT-06:00  Central Standard Time'
    );
    casenewList.add(case0);
    //Inserting Closed Case1
    Case case1 = new case(
      AccountId = ac1.Id,
      ContactId = con.Id,
      Status = 'Closed',
      Closure_Classification__c = 'Enhancement Request',
      Steps_Performed__c = 'Step performed',
      Resolution_Summary__c = 'Step performed',
      Resolution_Provided__c = 'Res',
      Solution__c = 'Res',
      Related_To__c = 'Studio',
      Sub_Component__c = 'Others',
      Priority = 'Medium',
      Country__c = 'United States',
      Time_Zone__c = 'GMT-06:00  Central Standard Time',
      Resolution_from_L2__c = '1'
    );
    casenewList.add(case1);

    //Inserting Case2 Without Contact
    Case case2 = new Case(
      AccountId = ac1.Id,
      ParentId = case0.id,
      suppliedEmail = 'test@test.com',
      suppliedName = 'Testing name',
      Priority = 'Medium',
      Country__c = 'United States',
      Time_Zone__c = 'GMT-06:00  Central Standard Time'
    );
    casenewList.add(case2);
    //Inserting Case3
    Case case3 = new case(
      Case_Web_Form_Region__c = 'Japan',
      RecordTypeId = RecordTypeID1,
      Status = 'New',
      Origin = 'Web',
      Priority = 'Medium',
      Country__c = 'United States',
      Time_Zone__c = 'GMT-06:00  Central Standard Time',
      Resolution_from_L2__c = 'test',
      Total_Case_In_Process_Duration__c = 1
    );
    casenewList.add(case3);
    //Inserting Case4
    Case case4 = new case(
      Case_Web_Form_Region__c = 'Japan',
      Related_To__c = 'Integration Services',
      RecordTypeId = RecordTypeID2,
      Status = 'Escalated',
      Origin = 'Web',
      Priority = 'Medium',
      Country__c = 'United States',
      Time_Zone__c = 'GMT-06:00  Central Standard Time',
      Resolution_from_L2__c = 'test',
      Total_Case_New_Duration__c = 1,
      Is_Free_Mailer__c = true,
      SuppliedEmail = 'test@outlook.com'
    );
    casenewList.add(case4);
    //Inserting Case5
    Case case5 = new case(
      RecordTypeId = RecordTypeID3,
      Status = 'New',
      Origin = 'Web',
      Priority = 'Medium',
      Subscription_Code__c = 'TRIAL',
      SuppliedEmail = 'test@test.com',
      Country__c = 'United States',
      Time_Zone__c = 'GMT-06:00  Central Standard Time',
      Resolution_from_L2__c = 'test',
      Total_Case_In_Process_Duration__c = 1
    );
    casenewList.add(case5);
    insert casenewList;

    // Below Code will Cover the standart controller constructor
    ApexPages.StandardController sc = new ApexPages.StandardController(casenewList[0]);
    CaseTriggerHelper assignToMe = new CaseTriggerHelper(sc);

    PageReference pageRef = Page.AssignedTo_Me;
    pageRef.getParameters().put('id', String.valueOf(casenewList[0].id));
    Test.setCurrentPage(pageRef);
    assignToMe.createFollowUpCase();
    assignToMe.assignCaseToLoginUser();
    ApexPages.StandardController sc1 = new ApexPages.StandardController(casenewList[1]);
    assignToMe = new CaseTriggerHelper(sc1);
    pageRef = Page.AssignedTo_Me;
    pageRef.getParameters().put('id', String.valueOf(casenewList[1].id));
    Test.setCurrentPage(pageRef);
    assignToMe.createFollowUpCase();
    assignToMe.assignCaseToLoginUser();
    Test.StopTest();
  }
}