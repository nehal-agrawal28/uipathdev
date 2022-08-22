@isTest
class PrepareSandboxTest {
    
    static String SANDBOX_NAME = 'test';

    @isTest
    static void testMySandboxPrep() {
        
       
        SandboxUsers__mdt sandboxUsers = [SELECT Id, Users__c FROM SandboxUsers__mdt LIMIT 1];

        List<User> users = [SELECT Id FROM User];

        System.debug('Metadata: '+ sandboxUsers.Users__c);
        System.debug('users.size(): '+ users.size());


        Test.startTest();

        Test.testSandboxPostCopyScript(
                new PrepareSandbox(), UserInfo.getOrganizationId(),
                UserInfo.getOrganizationId(), SANDBOX_NAME);

        Test.stopTest();
    }
    
    //if we supply a rediculously long email address, the process shouldn't fall over
    @isTest
    static void testMySandboxPrep_LongName() {

        SandboxUsers__mdt sandboxUsers = [SELECT Id, Users__c FROM SandboxUsers__mdt LIMIT 1];
        
        sandboxUsers.Users__c = sandboxUsers.Users__c + 'Hubert.Blaine.Wolfeschlegelsteinhausenbergerdorff@slalom.com';

        List<User> users = [SELECT Id FROM User];

        System.debug('Metadata: '+ sandboxUsers.Users__c);
        System.debug('users.size(): '+ users.size());


        Test.startTest();

        Test.testSandboxPostCopyScript(
                new PrepareSandbox(), UserInfo.getOrganizationId(),
                UserInfo.getOrganizationId(), SANDBOX_NAME);

        Test.stopTest();
    }
}