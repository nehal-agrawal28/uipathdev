@IsTest(isParallel=true)
public class WrikeServiceTest {
    @isTest static void testOpportunity() {
        Test.setMock(HttpCalloutMock.class, new WrikeServiceMock());
        
        Test.startTest();
        WrikeService.requestAddOpportunityTask('{}');
        Test.stopTest();
    }
    
    @isTest static void testAccount() {
        Test.setMock(HttpCalloutMock.class, new WrikeServiceMock());
        
        Test.startTest();
        WrikeService.requestAddAccountTask('{}');
        Test.stopTest();
    }
    
    @isTest static void testCSM() {
        Test.setMock(HttpCalloutMock.class, new WrikeServiceMock());
        
        Test.startTest();
        WrikeService.requestAddCSMTask('{}');
        Test.stopTest();
    }
    
    @isTest static void testAddTM() {
        Test.setMock(HttpCalloutMock.class, new WrikeServiceMock());
        
        Test.startTest();
        WrikeService.requestAddTeamMember('{}');
        Test.stopTest();
    }
    
    @isTest static void testDeleteTM() {
        Test.setMock(HttpCalloutMock.class, new WrikeServiceMock());
        
        Test.startTest();
        WrikeService.requestDeleteTeamMember('{}');
        Test.stopTest();
    }
    
    @isTest static void testAddMilestone() {
        Test.setMock(HttpCalloutMock.class, new WrikeServiceMock());
        
        Test.startTest();
        WrikeService.requestAddMilestone('{}');
        Test.stopTest();
    }
}