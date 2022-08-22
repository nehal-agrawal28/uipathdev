@isTest
public class KnowledgeArticleTriggerTest {
  public static Integer count = 0;

  @testsetup
  static void createTestData() {
    Account newAccount = new Account(Name = 'Raj');
    newAccount.RecordTypeId = Utilities.getRecordTypeId('Customer', 'Account');
    newAccount.BillingStreet = 'Test  Street';
    newAccount.BillingCity = 'Test City';
    newAccount.BillingPostalCode = '123abc';
    newAccount.BillingCountry = 'United Kingdom';
    newAccount.Phone = '12345678';
    newAccount.Industry = 'Others';
    insert newAccount;
    Contact c = new Contact(LastName = 'Tesr', AccountId = newAccount.Id, Email = 'test@mail.com', Department__c = 'IT');
    insert c;
    Case ca = new Case(AccountId = newAccount.Id, ContactId = c.Id, Origin = 'Web');
    insert ca;

    Knowledge__kav kaObj = new Knowledge__kav();
    kaObj.Is_Valid__c = true;
    kaObj.Product_Component__c = 'All';
    kaObj.Sub_Component__c = 'All';
    kaObj.Question_Problem__c = 'Test Question';
    kaObj.Resolution__c = 'Test Resolution';
    kaObj.Title = 'Test Title 1';
    kaObj.UrlName = 'TestTitle';
    kaObj.Studio_Version__c = 'All';
    kaObj.Orchestrator_Version__c = 'All';
    kaObj.Error__c = 'Test Error';
    kaObj.Technical_content__c = true;
    kaObj.Case_Id__c = ca.Id;
    KnowledgeArticleController.createKnowledgeArticle(kaObj);
  }

  public static Knowledge__kav createArticle() {
    Knowledge__kav kaObj = new Knowledge__kav();
    kaObj.Is_Valid__c = true;
    kaObj.Product_Component__c = 'All';
    kaObj.Sub_Component__c = 'All';
    kaObj.Question_Problem__c = 'Test Question';
    kaObj.Resolution__c = 'Test Resolution';
    kaObj.Title = 'Test Title 1';
    kaObj.UrlName = 'TestTitle' + (count++);
    kaObj.Studio_Version__c = 'All';
    kaObj.Orchestrator_Version__c = 'All';
    kaObj.Error__c = 'Test Error';
    kaObj.Technical_content__c = true;
    KnowledgeArticleController.createKnowledgeArticle(kaObj);
    return kaObj;
  }

  public static testMethod void testApprovedByTechnicalReviewerNegative1() {
    try {
      Knowledge__kav kaObj = createArticle();
      //Knowledge__kav kaObj = [Select Id,Product_Component__c,Sub_Component__c, Question_Problem__c, Resolution__c, Title, UrlName, Studio_Version__c, Orchestrator_Version__c, Error__c from Knowledge__kav];
      kaObj.Technical_Reviewer__c = UserInfo.getUserId();
      //kaObj.Review_Date__c =System.today();
      //kaObj.Reviewer_Notes__c = 'test';

      KnowledgeArticleController.updateKnowledgeArticle(kaObj);
      kaObj.ValidationStatus = 'Approved By Technical Reviewer';
      KnowledgeArticleController.updateKnowledgeArticle(kaObj);
    } catch (Exception e) {
      Boolean expectedExceptionThrown = e.getMessage().contains('Please fill all Technical Review fields')
        ? true
        : false;
      System.AssertEquals(expectedExceptionThrown, true);
    }
  }
  public static testMethod void testApprovedByTechnicalReviewerNegative2() {
    try {
      Knowledge__kav kaObj = createArticle();
      //Knowledge__kav kaObj = [Select Id,Product_Component__c,Sub_Component__c, Question_Problem__c, Resolution__c, Title, UrlName, Studio_Version__c, Orchestrator_Version__c, Error__c from Knowledge__kav];
      kaObj.ValidationStatus = 'Approved By Technical Reviewer';
      KnowledgeArticleController.updateKnowledgeArticle(kaObj);
    } catch (Exception e) {
      Boolean expectedExceptionThrown = e.getMessage().contains('Please start the Technical Review') ? true : false;
      System.AssertEquals(expectedExceptionThrown, true);
    }
  }
  public static testMethod void testApprovedByTechnicalReviewerNegative3() {
    try {
      Knowledge__kav kaObj = createArticle();
      //Knowledge__kav kaObj = [Select Id,Product_Component__c,Sub_Component__c, Question_Problem__c, Resolution__c, Title, UrlName, Studio_Version__c, Orchestrator_Version__c, Error__c from Knowledge__kav];
      kaObj.Technical_Reviewer__c = UserInfo.getUserId();
      kaObj.Technical_Check_Result__c = 'Pass';
      kaObj.Review_Date__c = System.today();
      kaObj.Reviewer_Notes__c = 'test';
      kaObj.ValidationStatus = 'Approved By Technical Reviewer';
      List<Technical_Review__c> existingTqs = [
        SELECT Id
        FROM Technical_Review__c
        WHERE Knowledge_Article__c = :kaObj.Id
      ];
      if (existingTqs.size() > 0) {
        delete existingTqs;
      }
      KnowledgeArticleController.updateKnowledgeArticle(kaObj);
    } catch (Exception e) {
      Boolean expectedExceptionThrown = e.getMessage().contains('Please add at least one Technical Review')
        ? true
        : false;
      System.AssertEquals(expectedExceptionThrown, true);
    }
  }

  public static testMethod void testRejectedByTechnicalReviewerNegative1() {
    try {
      Knowledge__kav kaObj = createArticle();
      //Knowledge__kav kaObj = [Select Id,Product_Component__c,Sub_Component__c, Question_Problem__c, Resolution__c, Title, UrlName, Studio_Version__c, Orchestrator_Version__c, Error__c from Knowledge__kav];
      kaObj.Technical_Reviewer__c = UserInfo.getUserId();
      kaObj.ValidationStatus = 'Rejected By Technical Reviewer';
      KnowledgeArticleController.updateKnowledgeArticle(kaObj);
    } catch (Exception e) {
      Boolean expectedExceptionThrown = e.getMessage().contains('Please fill all Technical Review fields')
        ? true
        : false;
      System.AssertEquals(expectedExceptionThrown, true);
    }
  }

  public static testMethod void testRejectedByTechnicalReviewerNegative2() {
    try {
      Knowledge__kav kaObj = createArticle();
      //Knowledge__kav kaObj = [Select Id,Product_Component__c,Sub_Component__c, Question_Problem__c, Resolution__c, Title, UrlName, Studio_Version__c, Orchestrator_Version__c, Error__c from Knowledge__kav];
      kaObj.ValidationStatus = 'Rejected By Technical Reviewer';
      KnowledgeArticleController.updateKnowledgeArticle(kaObj);
    } catch (Exception e) {
      Boolean expectedExceptionThrown = e.getMessage().contains('Please start the Technical Review') ? true : false;
      System.AssertEquals(expectedExceptionThrown, true);
    }
  }

  public static testMethod void testApprovedByTechnicalReviewer() {
    Knowledge__kav kaObj = createArticle();
    //Knowledge__kav kaObj = [Select Id,Product_Component__c,Sub_Component__c, Question_Problem__c, Resolution__c, Title, UrlName, Studio_Version__c, Orchestrator_Version__c, Error__c from Knowledge__kav];
    kaObj.Technical_Reviewer__c = UserInfo.getUserId();
    kaObj.Technical_Check_Result__c = 'Pass';
    kaObj.Review_Date__c = System.today();
    kaObj.Reviewer_Notes__c = 'test';

    insert new Technical_Review__c(Knowledge_Article__c = kaObj.Id);

    KnowledgeArticleController.updateKnowledgeArticle(kaObj);
    kaObj.ValidationStatus = 'Approved By Technical Reviewer';
    KnowledgeArticleController.updateKnowledgeArticle(kaObj);
  }
  public static testMethod void testRejectedByTechnicalReviewer() {
    Knowledge__kav kaObj = createArticle();
    //Knowledge__kav kaObj = [Select Id,Product_Component__c,Sub_Component__c, Question_Problem__c, Resolution__c, Title, UrlName, Studio_Version__c, Orchestrator_Version__c, Error__c from Knowledge__kav];
    kaObj.Technical_Reviewer__c = UserInfo.getUserId();
    kaObj.Technical_Check_Result__c = 'Fail';
    kaObj.Review_Date__c = System.today();
    kaObj.Reviewer_Notes__c = 'test';
    kaObj.ValidationStatus = 'Rejected By Technical Reviewer';
    KnowledgeArticleController.updateKnowledgeArticle(kaObj);
  }

  public static testMethod void testApprovedByQualityReviewerNegative1() {
    try {
      Knowledge__kav kaObj = createArticle();
      //Knowledge__kav kaObj = [Select Id,Product_Component__c,Sub_Component__c, Question_Problem__c, Resolution__c, Title, UrlName, Studio_Version__c, Orchestrator_Version__c, Error__c from Knowledge__kav];
      //kaObj.Quality_Reviewer__c = '';
      kaObj.ValidationStatus = 'Approved By Quality Reviewer';
      Article_Quality_Index__c aqi = new Article_Quality_Index__c();
      aqi.Unique_Article_English__c = 'Yes';
      aqi.Knowledge__c = kaObj.Id;
      insert aqi;
      KnowledgeArticleController.updateKnowledgeArticle(kaObj);
    } catch (Exception e) {
      Boolean expectedExceptionThrown = e.getMessage().contains('Please start the Quality Review') ? true : false;
      System.AssertEquals(expectedExceptionThrown, true);
    }
  }

  public static testMethod void testApprovedByQualityReviewerNegative2() {
    try {
      Knowledge__kav kaObj = createArticle();
      //Knowledge__kav kaObj = [Select Id,Product_Component__c,Sub_Component__c, Question_Problem__c, Resolution__c, Title, UrlName, Studio_Version__c, Orchestrator_Version__c, Error__c from Knowledge__kav];
      kaObj.Quality_Reviewer__c = UserInfo.getUserId();
      kaObj.ValidationStatus = 'Approved By Quality Reviewer';
      List<Article_Quality_Index__c> existingAqis = [
        SELECT Id
        FROM Article_Quality_Index__c
        WHERE Knowledge__c = :kaObj.Id
      ];
      if (existingAqis.size() > 0) {
        delete existingAqis;
      }
      KnowledgeArticleController.updateKnowledgeArticle(kaObj);
    } catch (Exception e) {
      Boolean expectedExceptionThrown = e.getMessage().contains('Please add at least one Article Quality Index')
        ? true
        : false;
      System.AssertEquals(expectedExceptionThrown, true);
    }
  }

  public static testMethod void testApprovedByQualityReviewer() {
    Knowledge__kav kaObj = createArticle();
    //Knowledge__kav kaObj = [Select Id,Product_Component__c,Sub_Component__c, Question_Problem__c, Resolution__c, Title, UrlName, Studio_Version__c, Orchestrator_Version__c, Error__c from Knowledge__kav];
    kaObj.Quality_Reviewer__c = UserInfo.getUserId();
    kaObj.ValidationStatus = 'Approved By Quality Reviewer';
    Article_Quality_Index__c aqi = new Article_Quality_Index__c();
    aqi.Unique_Article_English__c = 'Yes';
    aqi.Knowledge__c = kaObj.Id;
    insert aqi;
    KnowledgeArticleController.updateKnowledgeArticle(kaObj);
  }

  public static testMethod void testgetFieldMetadata() {
    KnowledgeArticleController.getFieldMetadata('');
  }
  public static testMethod void testgetReviewerData() {
    KnowledgeArticleController.getReviewerData([SELECT Id FROM Knowledge__kav][0].Id);
  }
  public static testMethod void testgetReviewerData1() {
    KnowledgeArticleController.getReviewerData([SELECT Id FROM Knowledge__kav][0].Id);
  }
}