@isTest
public class UpvoteDownvoteIdeasAuraControllerTest {
  @TestSetup
  private static void setupTestData() {
    Sales_Technology_Idea__c techIdea = new Sales_Technology_Idea__c(
      Name = 'Test Idea',
      Application_Area__c = 'Other',
      Other_Area__c = 'testArea',
      Description__c = 'This is a description that meets the minimmum 20 char requirements',
      Benefit__c = 'This is a benefit that meets the minimmum 20 char requirements'
    );
    insert techIdea;
  }

  @isTest
  private static void testVoteIdeaCreation() {
    List<Sales_Technology_Idea__c> testIdea = [SELECT id FROM Sales_Technology_Idea__c LIMIT 1];

    Test.startTest();
    UpvoteDownvoteIdeasAuraController.upvoteDownVoteIdeas('Upvote', testIdea[0].id);
    Test.stopTest();

    List<Sales_Technology_Idea_Vote__c> ideaVote = [SELECT id, Vote_Type__c FROM Sales_Technology_Idea_Vote__c LIMIT 1];
    System.assertEquals('Upvote', ideaVote[0].Vote_Type__c);
  }

  @isTest
  private static void testVoteIdeaUpdate() {
    List<Sales_Technology_Idea__c> testIdea = [SELECT id FROM Sales_Technology_Idea__c LIMIT 1];
    Sales_Technology_Idea_Vote__c testIdeaVote = new Sales_Technology_Idea_Vote__c(
      Vote_Type__c = 'Upvote',
      User__c = Userinfo.getUserId(),
      Sales_Technology_Idea__c = testIdea[0].id
    );
    insert testIdeaVote;
    Test.startTest();
    UpvoteDownvoteIdeasAuraController.upvoteDownVoteIdeas('Downvote', testIdea[0].id);
    Test.stopTest();

    List<Sales_Technology_Idea_Vote__c> downVoteIdea = [
      SELECT id, Vote_Type__c
      FROM Sales_Technology_Idea_Vote__c
      LIMIT 1
    ];
    System.assertEquals('Downvote', downVoteIdea[0].Vote_Type__c);
  }
}