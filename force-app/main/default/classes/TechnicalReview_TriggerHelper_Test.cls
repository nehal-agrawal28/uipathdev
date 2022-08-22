@IsTest(isParallel=false)
public class TechnicalReview_TriggerHelper_Test {
  static testMethod void onafterinsert() {
    String orgId = UserInfo.getOrganizationId();
    List<Knowledge__kav> know_insert = new List<Knowledge__kav>();
    Profile pf = [SELECT Id FROM profile WHERE Name = 'System Administrator'];
    Integer randomInt = Integer.valueOf(math.rint(math.random() * 1000000));
    String uniqueName = orgId + randomInt;

    user user1 = new user(
      LastNAme = 'Test User123',
      Alias = 'TU',
      email = uniqueName + '@test' + orgId + '.org',
      Username = uniqueName + '@test' + orgId + '.org',
      communityNickname = 'TU',
      profileId = pf.Id,
      EmailEncodingKey = 'ISO-8859-1',
      TimeZoneSidKey = 'America/Los_Angeles',
      LocaleSidKey = 'en_US',
      LanguageLocaleKey = 'en_US'
    );
    insert user1;
    for (Integer i = 1; i <= 100; i++) {
      Knowledge__kav testrec = new knowledge__kav(
        Title = 'Test Title' + i,
        URLName = 'Test-Title' + i,
        Summary = 'Test Summary' + i,
        Is_Valid__c = true,
        Product_Component__c = 'All',
        Sub_component__c = 'Studio_Installation',
        Question_Problem__c = 'Test Title',
        Resolution__c = 'Test Resolution'
      ); //Studio_version__c='v2018.1.1',
      know_insert.add(testrec);
    }
    insert know_insert;

    Integer i = 0;
    for (Knowledge__kav techupdate : know_insert) {
      i++;
      if (i > 50)
        break;
      techupdate.Technical_Check_Result__c = 'Fail';
      techupdate.TEchnical_Reviewer__c = user1.id;
      techupdate.Reviewer_Notes__c = 'Test Reviewer Notes';
      techupdate.Review_Date__c = System.today() + 5;
    }
    update know_insert;
  }
}