@IsTest(isParallel=true)
public class LeadSetStatusRecycledTest {
    
    @isTest
    public static void Test1(){
        
        List<Lead> leadList = new List<Lead>();
        
        Lead l1 = new Lead();
        l1.LastName = 'ColoradoAmer-Recycle1';
        l1.Country = 'United States';
        l1.State = 'Colorado';
        l1.Geo__c = 'AMER';
        l1.Company = 'Test293731';
        l1.Status = 'New';
        l1.Email = 'joe.test@test.com';
        leadList.add(l1);
        
        Lead l2 = new Lead();
        l2.LastName = 'CaliforniaAmer-Recycle2';
        l2.Country = 'United States';
        l2.State = 'California';
        l2.Geo__c = 'AMER';
        l2.Company = 'Test293732';
        l2.Last_Change_Status_Date__c = Date.Today().addDays(-95);
        l2.Status = 'Working';
        l2.Email = 'joe.test2@test.com';
        leadList.add(l2);
        
        Lead l3 = new Lead();
        l3.LastName = 'CONewAmer1';
        l3.Country = 'United States';
        l3.State = 'California';
        l3.Geo__c = 'AMER';
        l3.Company = 'Test293733';
        l3.Last_Change_Status_Date__c  = Date.Today().addDays(-40);
        l3.Status = 'Working';
        l3.Email = 'joe.test3@test.com';
        leadList.add(l3);
        
        Lead l4 = new Lead();
        l4.LastName = 'CANewAmer2';
        l4.Country = 'United States';
        l4.State = 'California';
        l4.Geo__c = 'AMER';
        l4.Company = 'Test293734';
        l4.Last_Change_Status_Date__c = Date.Today().addDays(-179);
        l4.Status = 'New';
        l4.Email = 'joe.test4@test.com';
        leadList.add(l4);
        
        insert leadList;
         List<Lead> ltoupdate = [SELECT Id, Name, Status, No_of_days_in_current_status__c   FROM Lead];
        for(lead l: ltoupdate) {
            if(l.Name == 'ColoradoAmer-Recycle1')
                l.Last_Change_Status_Date__c = Date.Today().addDays(-181);
            if(l.Name == 'CaliforniaAmer-Recycle2')
                l.Last_Change_Status_Date__c = Date.Today().addDays(-95);
            if(l.Name == 'CONewAmer1')
                l.Last_Change_Status_Date__c = Date.Today().addDays(-40);
            if(l.Name == 'CANewAmer2')
                l.Last_Change_Status_Date__c = Date.Today().addDays(-179);
        }
        update ltoupdate;

        // Run the code
        Test.startTest();
           (new LeadSetStatusRecycledBatch()).execute(null);
        Test.stopTest();
        
        // Verify Results
        List<Lead> lRecycled = [SELECT Id, Name FROM Lead WHERE Status = 'Recycle'];
        System.assertEquals(2, lRecycled.size());
    }
}