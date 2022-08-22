/**
 * Created by girish.lakshmanan on 2019-04-01.
 * Tests for Controller class EditRevenueScheduleTiersController
 */

@IsTest(isParallel=true)
public with sharing class EditRevenueScheduleTiersControllerTest {


    private static final String SCHEDULE_NAME = 'TestRevSchedule';

    @testSetup static void setup() {

        Revenue_Discount_Schedule__c revenueDiscountSchedule = new Revenue_Discount_Schedule__c(Name = SCHEDULE_NAME,
                Type__c = 'Standard',
                Discount_Unit__c = 'Percent',
                CurrencyIsoCode = 'USD');

        insert revenueDiscountSchedule;

    }


    @IsTest
    public static void hasBlankTierWhenUserFirstVisitsPageOnNewSchedule() {

        EditRevenueScheduleTiersController editRevenueScheduleTiersController = getControllerInstance();

        System.assertEquals(1,
                editRevenueScheduleTiersController.scheduleModel.tiersModel.combinedTiers.size(),
                'Expected exactly 1 blank Tier initialized when there are no existing Tiers');

    }


    @IsTest
    public static void canSaveNewTierSuccessfully() {

        EditRevenueScheduleTiersController editRevenueScheduleTiersController = getControllerInstance();

        editRevenueScheduleTiersController.getActiveTier().LowerBound__c = 0;
        editRevenueScheduleTiersController.getActiveTier().UpperBound__c = 101;
        editRevenueScheduleTiersController.getActiveTier().Discount__c = 5;
        editRevenueScheduleTiersController.onSave();

        System.debug('Id is ' + editRevenueScheduleTiersController.getActiveTier().Id);
        System.assert(editRevenueScheduleTiersController.getActiveTier().Id <> NULL &&
                !String.ValueOf(editRevenueScheduleTiersController.getActiveTier().Id).startsWith('NEW'),
                'For a successfully saved record, Id cannot be blank and cannot begin with word NEW');

    }


    @IsTest
    public static void canCancelTierChangesWithoutSaving() {

        EditRevenueScheduleTiersController editRevenueScheduleTiersController = getControllerInstance();
        editRevenueScheduleTiersController.getActiveTier().LowerBound__c = 0;
        editRevenueScheduleTiersController.getActiveTier().UpperBound__c = 101;
        editRevenueScheduleTiersController.getActiveTier().Discount__c = 5;
        editRevenueScheduleTiersController.onCancel();

        List<Revenue_DiscountTier__c> revenueDiscountTiers = getRevenueDiscountTiers(editRevenueScheduleTiersController);
        System.assertEquals(0, revenueDiscountTiers.size(), 'Tiers should not be saved when Cancel button is clicked');


    }


    @IsTest
    public static void canAddNewTier() {


        insertTestTier(getDiscountSchedule().Id, 0, 101, 'TestTier1ExternId');
        insertTestTier(getDiscountSchedule().Id, 101, 201, 'TestTier2ExternId');


        EditRevenueScheduleTiersController editRevenueScheduleTiersController = getControllerInstance();

        //Add a new Tier after clicking the Plus button
        editRevenueScheduleTiersController.newTierIdx = 1;
        editRevenueScheduleTiersController.targetExtId = 'TestTier2ExternId';

        //Simulate user clicking Plus button
        editRevenueScheduleTiersController.onAddTier();
        editRevenueScheduleTiersController.getActiveTier().LowerBound__c = 201;
        editRevenueScheduleTiersController.getActiveTier().UpperBound__c = 201;
        editRevenueScheduleTiersController.getActiveTier().Discount__c = 15;
        editRevenueScheduleTiersController.onSave();

        List<Revenue_DiscountTier__c> revenueDiscountTiers = getRevenueDiscountTiers(editRevenueScheduleTiersController);
        System.assertEquals(3, revenueDiscountTiers.size(), 'There should be 3 Tiers after adding 1');

    }

    @IsTest
    public static void canRemoveExistingTier() {


        insertTestTier(getDiscountSchedule().Id, 0, 101, 'TestTier1ExternId');
        insertTestTier(getDiscountSchedule().Id, 101, 201, 'TestTier2ExternId');


        EditRevenueScheduleTiersController editRevenueScheduleTiersController = getControllerInstance();

        editRevenueScheduleTiersController.newTierIdx = 1;
        editRevenueScheduleTiersController.targetExtId = 'TestTier2ExternId';
        editRevenueScheduleTiersController.onRemoveTier();
        editRevenueScheduleTiersController.onSave();

        List<Revenue_DiscountTier__c> revenueDiscountTiers = getRevenueDiscountTiers(editRevenueScheduleTiersController);
        System.assertEquals(1, revenueDiscountTiers.size(), 'Only 1 Tier should remain after deleting 1');

    }


    @IsTest
    public static void defaultsSetAsExpected() {

        EditRevenueScheduleTiersController editRevenueScheduleTiersController = getControllerInstance();

        System.assert(editRevenueScheduleTiersController.scheduleModel.discountUnitAmount == false);
        System.assert(editRevenueScheduleTiersController.scheduleModel.discountUnitPercent == true);
        System.assert(editRevenueScheduleTiersController.scheduleModel.tiersModel.getColumnHeadings() <> null);

        System.assert(editRevenueScheduleTiersController.scheduleModel.tiersModel.getEmptyTiers() == true);
        System.assert(editRevenueScheduleTiersController.scheduleModel.tiersModel.getTierCount() == 0);


    }


    private static void insertTestTier(Id scheduleId, Integer lower, Integer upper, String externalId) {
        Revenue_DiscountTier__c revenueDiscountTier = new Revenue_DiscountTier__c(Number__c = 1,
                Ext_Id__c = externalId,
                UpperBound__c = upper,
                LowerBound__c = lower,
                CurrencyIsoCode = 'USD',
                Discount__c = 5,
                Revenue_Discount_Schedule__c = scheduleId);
        insert revenueDiscountTier;
    }


    private static List<Revenue_DiscountTier__c> getRevenueDiscountTiers(EditRevenueScheduleTiersController editRevenueScheduleTiersController) {

        List<Revenue_DiscountTier__c> revenueDiscountTiers = [
                SELECT Id,
                        Name,Discount__c,
                        UpperBound__c,
                        LowerBound__c,
                        DiscountAmount__c,
                        Number__c,
                        Ext_Id__c,
                        CurrencyIsoCode
                FROM Revenue_DiscountTier__c
                where Revenue_Discount_Schedule__c = :editRevenueScheduleTiersController.scheduleModel.schedule.Id
        ];
        return revenueDiscountTiers;


    }


    private static Revenue_Discount_Schedule__c getDiscountSchedule() {

        Revenue_Discount_Schedule__c revenueDiscountSchedule = [
                SELECT Id
                FROM Revenue_Discount_Schedule__c
                where Name = :SCHEDULE_NAME
        ];
        return revenueDiscountSchedule;


    }

    private static EditRevenueScheduleTiersController getControllerInstance() {
        ApexPages.StandardController standardController = getStandardController();
        return new EditRevenueScheduleTiersController(standardController);
    }

    private static ApexPages.StandardController getStandardController() {
        Revenue_Discount_Schedule__c revenueDiscountSchedule = [
                SELECT Id, Name, CurrencyIsoCode,Discount_Unit__c
                FROM Revenue_Discount_Schedule__c
                where Name = :SCHEDULE_NAME
        ];

        ApexPages.standardController standardController = new ApexPages.StandardController(revenueDiscountSchedule);
        return standardController;
    }


}