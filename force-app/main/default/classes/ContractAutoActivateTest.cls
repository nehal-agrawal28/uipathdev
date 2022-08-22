/**
 * Created by paul.bircham on 2019-05-14.
 */

@IsTest
private class ContractAutoActivateTest {

    @TestSetup
    static void testSetup(){
        Account acc = DataFactory_CM.createAccount('Customer', true);
        Opportunity opp = DataFactory_SL.createOpportunity(acc.id, true);



    }

    /**
    * No Opp
    */
    // @IsTest
    // static void testNegative1() {

    //     Account acc = [SELECT Id FROM Account LIMIT 1];

    //     Contract contract = new Contract(
    //             AccountId = acc.Id
    //     );

    //     insert contract;

    //     Contract contractResult = [SELECT Id, Status, SBQQ__RenewalForecast__c, SBQQ__RenewalOpportunityStage__c FROM Contract LIMIT 1];

    //     System.assertNotEquals('Activated', contractResult.Status);
    //     System.assertNotEquals(True, contractResult.SBQQ__RenewalForecast__c);
    //     System.assertNotEquals('Negotiation', contractResult.SBQQ__RenewalOpportunityStage__c);

    // }

    /**
     * Non-CPQ Opp
     */
    // @IsTest
    // static void testNegative2() {

    //     Account acc = [SELECT Id FROM Account LIMIT 1];
    //     Opportunity opp = [SELECT Id, RecordType.Name FROM Opportunity LIMIT 1];

    //     System.debug(opp.RecordType.Name);

    //     Contract contract = new Contract(
    //             AccountId = acc.Id,
    //             SBQQ__Opportunity__c = null
    //     );


    //     insert contract;

    //     Contract contractResult = [SELECT Id, Status, SBQQ__RenewalForecast__c, SBQQ__RenewalOpportunityStage__c FROM Contract LIMIT 1];

    //     System.assertNotEquals('Activated', contractResult.Status);
    //     System.assertNotEquals(True, contractResult.SBQQ__RenewalForecast__c);
    //     System.assertNotEquals('Negotiation', contractResult.SBQQ__RenewalOpportunityStage__c);


    // }

    /**
     * Non-CPQ Opp
    */
    @IsTest
    static void testPositive() {

        Id cpqRtId = null;
        CPQ_Controls__mdt cpqControls = null;
        try {
            cpqControls = [SELECT Id, Opp_CPQ_Record_Type_Developer_Name__c FROM CPQ_Controls__mdt LIMIT 1];

            if (Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c).getRecordTypeId() != null) {
                cpqRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c).getRecordTypeId();
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Metadata and system have not been correctly configured for CPQ operation');
        }

        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id, RecordType.Name FROM Opportunity LIMIT 1];

        opp.RecordTypeId = cpqRtId;

        update opp;

        opp = [SELECT Id, RecordType.Name FROM Opportunity LIMIT 1];

        System.debug(opp.RecordType.Name);

        Contract contract = new Contract(
                AccountId = acc.Id,
                SBQQ__Opportunity__c = opp.Id,
                StartDate = Date.today(),
                ContractTerm = 12
        );

        Test.startTest();
        insert contract;
        Test.stopTest();

        Contract contractResult = [SELECT Id, Status, SBQQ__RenewalForecast__c, SBQQ__RenewalOpportunityStage__c, SBQQ__RenewalOpportunityRecordTypeId__c FROM Contract LIMIT 1];

        System.assertEquals('Activated', contractResult.Status);
        System.assertNotEquals(NULL, contractResult.SBQQ__RenewalOpportunityRecordTypeId__c);
        System.assertEquals('Negotiation', contractResult.SBQQ__RenewalOpportunityStage__c);

        /**
         * this update is performed by async process builder - it should be uncommented
         * when Test.startTest() and Test.stopTest()'s scope includes async process builder actions
         */
        //System.assertEquals(True, contractResult.SBQQ__RenewalForecast__c);
    }
}