/**
 * Created on 2/26/2020.
 * Used to cover the code for BillingCategorySubtotalsBatch class
 */

@IsTest
public with sharing class BillingCategorySubtotalsBatchTest {
    @TestSetup
    static void makeData(){
        Account acc = new Account (
                    Name = 'newAcc1',
                    BillingCountry ='United Kingdom',
                    Industry = 'Others'
            );
            insert acc;
    
            Opportunity o = new Opportunity(
                accountId = acc.id,
                StageName = 'Discovery',
                CloseDate = system.today(),
                Name = 'Test Op',
                Type = 'Upsell',
                CurrencyIsoCode = 'EUR',
                Deal_Type__c = 'Direct',
                Won_Reasons__c = 'Product Roadmap',
                LeadSource = 'Partner'
            );
            insert o;
    
            pse__Billing_Event__c billingEvent = new pse__Billing_Event__c(
                BE_Friendly_Name__c = 'Testing Billing Event',
                Customer_Response__c = 'Awaiting Customer Approval',
                PO_Number_Current__c = '1234567',
                pse__Date__c = System.today()
            );
            insert billingEvent;

            pse__Billing_Event_Item__c billingEventItem1 = new pse__Billing_Event_Item__c(
                pse__Billing_Event__c = billingEvent.Id,
                pse__Category__c = 'Expense',
                pse__Rounded_Amount__c = 10,
                pse__Object_Id__c = '123'
            );
            pse__Billing_Event_Item__c billingEventItem2 = new pse__Billing_Event_Item__c(
                pse__Billing_Event__c = billingEvent.Id,
                pse__Category__c = 'Milestone',
                pse__Rounded_Amount__c = 10,
                pse__Object_Id__c = '124'
            );
            pse__Billing_Event_Item__c billingEventItem3 = new pse__Billing_Event_Item__c(
                pse__Billing_Event__c = billingEvent.Id,
                pse__Category__c = 'Timecard',
                pse__Rounded_Amount__c = 10,
                pse__Object_Id__c = '125'
            );

            List<pse__Billing_Event_Item__c> billingEventItems = new List<pse__Billing_Event_Item__c>();
            billingEventItems.add(billingEventItem1);
            billingEventItems.add(billingEventItem2);
            billingEventItems.add(billingEventItem3);
            insert billingEventItems;
            
            pse__Proj__c project = new pse__Proj__c(pse__Allow_Timecards_Without_Assignment__c = true,
                                                   pse__Is_Active__c = true,
                                                   Require_Milestone_on_Timecards__c = false);
            insert project;
            contact con = new Contact(LastName = 'Test contact 101',Email = 'test.contact01@testemail.com', Department__c = 'IT');
            insert con;
            pse__Timecard_Header__c header = new pse__Timecard_Header__c(pse__Project__c = project.Id,
                                                                        pse__Resource__c = con.Id,
                                                                         pse__End_Date__c = system.today() ,
                                                                         pse__Start_Date__c = system.today() - 6,
                                                                         pse__Billable__c = false
                                                                        );
            //insert header;
        
            pse__Timecard__c timecard = new pse__Timecard__c(
                pse__Billing_Event_Item__c = billingEventItem3.Id,
                pse__Total_Hours__c = 20,
                pse__Project__c = project.Id,
                pse__Resource__c = con.Id,
                pse__Timecard_Header__c = header.Id
            );
            //insert timecard;

            pse__Milestone__c milestone = new pse__Milestone__c(
                pse__Billing_Event_Item__c = billingEventItem2.Id,
                pse__Milestone_Cost__c = 20
            );
            //insert milestone;
    }

    @IsTest
    public static void  testBillingEventBatch() {
        System.schedule('test', '0 00 01 ? * * *', new BillingCategorySubtotalsBatchSchedule());
    BillingCategorySubtotalsBatch billingCategoryBatch = new BillingCategorySubtotalsBatch ();
        Database.executeBatch(billingCategoryBatch );
    }
}