public class KnowledgeArticleTriggerHandler {
  public static void beforeInsertOperations(List<Knowledge__kav> newRecords) {
    for (Knowledge__kav newRecord : newRecords) {
      newRecord.ValidationStatus = 'Not Validated';
      if (String.isBlank(newRecord.KnowledgeArticleId) && !newRecord.Is_Valid__c) {
        String error = 'Please create the article from the New Article page.';
        newRecord.addError(error);
      }
    }
  }

  public static void beforeUpdateOperations(List<Knowledge__kav> newRecords, Map<Id, Knowledge__kav> oldRecords) {
    String userId = UserInfo.getUserId();
    String adminUserId = Label.Knowledge_Super_Admin;
    Map<Id, Knowledge__kav> technicalApprovedArticles = new Map<Id, Knowledge__kav>();
    Map<Id, Knowledge__kav> qualityApprovedArticles = new Map<Id, Knowledge__kav>();

    for (Knowledge__kav newObj : newRecords) {
      Knowledge__kav oldObj = oldRecords.get(newObj.Id);
      if (oldObj.Is_Not_External__c != newObj.Is_Not_External__c && !newObj.Is_Not_External__c) {
        newObj.Reason_for_Not_External__c = '';
      }
      if (oldObj.Is_confidential__c != newObj.Is_confidential__c && !newObj.Is_confidential__c) {
        newObj.Reason_for_Confidential__c = '';
      }
      if (
        oldObj.Reason_for_Not_External__c != newObj.Reason_for_Not_External__c &&
        (String.isBlank(newObj.Reason_for_Not_External__c) || String.isEmpty(newObj.Reason_for_Not_External__c))
      ) {
        newObj.Is_Not_External__c = false;
      }
      if (
        oldObj.Reason_for_Not_External__c != newObj.Reason_for_Not_External__c &&
        String.isNotBlank(newObj.Reason_for_Not_External__c) &&
        String.isNotEmpty(newObj.Reason_for_Not_External__c)
      ) {
        newObj.Is_Not_External__c = true;
      }
      if (
        oldObj.Reason_for_Confidential__c != newObj.Reason_for_Confidential__c &&
        String.isNotBlank(newObj.Reason_for_Confidential__c) &&
        String.isNotEmpty(newObj.Reason_for_Confidential__c)
      ) {
        newObj.Is_confidential__c = true;
      }
      if (
        adminUserId!= userId &&
        oldObj.ValidationStatus != newObj.ValidationStatus && newObj.ValidationStatus == 'Submitted') {
        newObj.Submission_Date__c = System.now();
      }
      if (
        adminUserId!= userId &&
        oldObj.ValidationStatus != newObj.ValidationStatus &&
        newObj.ValidationStatus == 'Rejected By Quality Reviewer'
      ) {
        if (newObj.Quality_Reviewer__c == null) {
          String error = 'Please start the Quality Review before rejecting it.';
          newObj.addError(error);
        } else if (newObj.Quality_Reviewer__c != UserInfo.getUserId()) {
          String error = 'You cannot reject this article since it is being reviewed by someone else.';
          newObj.addError(error);
        }
        //String error = 'Please note that this will again trigger the entire approval process where it goes to Creator, Technical review and then again to Quality. \nSince it is Technically qualified, please correct and approve which will reduce the TAT.';
      }
      if (
        adminUserId!= userId &&
        oldObj.ValidationStatus != newObj.ValidationStatus &&
        newObj.ValidationStatus == 'Approved By Technical Reviewer'
      ) {
        if (newObj.Technical_Reviewer__c == null) {
          String error = 'Please start the Technical Review before approving it.';
          newObj.addError(error);
        } else if (newObj.Technical_Reviewer__c != UserInfo.getUserId()) {
          String error = 'You cannot approve this article since it is being reviewed by someone else.';
          newObj.addError(error);
        } else if (
          newObj.Technical_Check_Result__c == '' ||
          newObj.Review_Date__c == null ||
          newObj.Reviewer_Notes__c == ''
        ) {
          String error = 'Please fill all Technical Review fields(Technical Check Result, Technical Review Date, Reviewer Notes).';
          newObj.addError(error);
        } else {
          technicalApprovedArticles.put(newObj.Id, newObj);
        }
      }
      if (
        adminUserId!= userId && 
        oldObj.ValidationStatus != newObj.ValidationStatus &&
        newObj.ValidationStatus == 'Rejected By Technical Reviewer'
      ) {
        if (newObj.Technical_Reviewer__c == null) {
          String error = 'Please start the Technical Review before rejecting it.';
          newObj.addError(error);
        } else if (newObj.Technical_Reviewer__c != UserInfo.getUserId()) {
          String error = 'You cannot reject this article since it is being reviewed by someone else.';
          newObj.addError(error);
        } else if (
          newObj.Technical_Check_Result__c == '' ||
          newObj.Review_Date__c == null ||
          newObj.Reviewer_Notes__c == ''
        ) {
          String error = 'Please fill all Technical Review fields(Technical Check Result, Technical Review Date, Reviewer Notes).';
          newObj.addError(error);
        }
      }

      if (
        oldObj.ValidationStatus != newObj.ValidationStatus &&
        newObj.ValidationStatus == 'Approved By Quality Reviewer'
      ) {
        if(adminUserId!= userId){
          if (newObj.Quality_Reviewer__c == null) {
            String error = 'Please start the Quality Review before approving it.';
            newObj.addError(error);
          } else if (newObj.Quality_Reviewer__c != UserInfo.getUserId()) {
            String error = 'You cannot approve this article since it is being reviewed by someone else.';
            newObj.addError(error);
          } else {
            qualityApprovedArticles.put(newObj.Id, newObj);
          }
        }
        newObj.Skip_Technical_Review__c = false;
        if (newObj.Is_Not_External__c || newObj.Is_confidential__c) {
          newObj.IsVisibleInPkb = false;
          newObj.IsVisibleInCsp = false;
          newObj.IsVisibleInPrm = false;
        } else {
          newObj.IsVisibleInPkb = true;
          newObj.IsVisibleInCsp = true;
          newObj.IsVisibleInPrm = true;
        }
      }
      if (oldObj.ValidationStatus != newObj.ValidationStatus && newObj.ValidationStatus == 'Submitted') {
        if (newObj.Skip_Technical_Review__c) {
          newObj.ValidationStatus = 'Approved By Technical Reviewer';
        }
      }
    }

    if (technicalApprovedArticles.size() > 0) {
      technicalApprovalValidations(technicalApprovedArticles);
    }
    if (qualityApprovedArticles.size() > 0) {
      qualityApprovalValidations(qualityApprovedArticles);
    }
  }

  public static void afterInsertOperations(List<Knowledge__kav> newRecords, Map<Id, Knowledge__kav> oldRecords) {
    List<String> knowledgeArticleIds = new List<String>();
    for (Knowledge__kav newRecord : newRecords) {
      knowledgeArticleIds.add(newRecord.KnowledgeArticleId);
    }
    List<Article_Quality_Index__c> AQIsToBeUpdated = new List<Article_Quality_Index__c>();
    List<Article_Quality_Index__c> existingAQIs = [
      SELECT Id, Knowledge__c, Knowledge__r.KnowledgeArticleId
      FROM Article_Quality_Index__c
      WHERE Knowledge__r.KnowledgeArticleId IN :knowledgeArticleIds
    ];

    Map<Id, String> kaCaseIds = new Map<Id, Id>();
    List<CaseArticle> caseArticlesToBeInserted = new List<CaseArticle>();
    for (Knowledge__kav newObj : newRecords) {
      for (Article_Quality_Index__c existingAQI : existingAQIs) {
        existingAQI.Knowledge__c = newObj.Id;
        AQIsToBeUpdated.add(existingAQI);
      }
      if (newObj.Case_Id__c != null && String.isNotBlank(newObj.Case_Id__c) && String.isNotEmpty(newObj.Case_Id__c)) {
        kaCaseIds.put(newObj.Id, newObj.Case_Id__c);
      }
    }
    for (KnowledgeArticleVersion kav : [
      SELECT Id, KnowledgeArticleId
      FROM KnowledgeArticleVersion
      WHERE Id IN :kaCaseIds.keySet()
    ]) {
      CaseArticle ca = new CaseArticle();
      ca.caseId = kaCaseIds.get(kav.Id);
      ca.KnowledgeArticleId = kav.KnowledgeArticleId;
      caseArticlesToBeInserted.add(ca);
    }
    if (caseArticlesToBeInserted != null && caseArticlesToBeInserted.size() > 0) {
      insert caseArticlesToBeInserted;
    }
    if (AQIsToBeUpdated != null && AQIsToBeUpdated.size() > 0) {
      update AQIsToBeUpdated;
    }
    DataCategoryMappingHelper.mapDataCategories(newRecords);
  }

  public static void technicalApprovalValidations(Map<Id, Knowledge__kav> newArticles) {
    List<Knowledge__kav> articlesToBeValidated = [
      SELECT Id, (SELECT Id FROM Technical_Reviews__r)
      FROM Knowledge__kav
      WHERE Id IN :newArticles.keySet()
    ];
    for (Knowledge__kav article : articlesToBeValidated) {
      if (article.Technical_Reviews__r.size() < 1) {
        Trigger.newMap
          .get(article.Id)
          .addError('Please add at least one Technical Review before approving this article.');
      }
    }
  }

  public static void qualityApprovalValidations(Map<Id, Knowledge__kav> newArticles) {
    List<Knowledge__kav> articlesToBeValidated = [
      SELECT Id, (SELECT Id FROM Article_Quality_Indexes__r)
      FROM Knowledge__kav
      WHERE Id IN :newArticles.keySet()
    ];
    for (Knowledge__kav article : articlesToBeValidated) {
      if (article.Article_Quality_Indexes__r.size() < 1) {
        Trigger.newMap
          .get(article.Id)
          .addError('Please add at least one Article Quality Index before approving this article.');
      }
    }
  }
}