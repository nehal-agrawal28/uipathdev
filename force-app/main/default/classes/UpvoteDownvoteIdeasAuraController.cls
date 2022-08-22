public with sharing class UpvoteDownvoteIdeasAuraController {
  @AuraEnabled
  public static void upvoteDownVoteIdeas(String actionType, String recordId) {
    try {
      List<Sales_Technology_Idea_Vote__c> ideaVotes = [
        SELECT id
        FROM Sales_Technology_Idea_Vote__c
        WHERE user__c = :userinfo.getuserid() AND Sales_Technology_Idea__c = :recordId
      ];

      if (ideaVotes.isEmpty()) {
        createVoteRecord(actionType, recordId);
      } else {
        updateVoteRecord(actionType, ideaVotes[0]);
      }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static void createVoteRecord(String actionType, String recordId) {
    Sales_Technology_Idea_Vote__c voteRecord = new Sales_Technology_Idea_Vote__c(
      Sales_Technology_Idea__c = recordId,
      User__c = UserInfo.getuserid()
    );
    if (actionType == 'Upvote') {
      voteRecord.Vote_Type__c = 'Upvote';
    } else {
      voteRecord.Vote_Type__c = 'Downvote';
    }

    insert voteRecord;
  }

  private static void updateVoteRecord(String actionType, Sales_Technology_Idea_Vote__c voteRecord) {
    if (actionType == 'Upvote') {
      voteRecord.Vote_Type__c = 'Upvote';
    } else {
      voteRecord.Vote_Type__c = 'Downvote';
    }

    update voteRecord;
  }
}