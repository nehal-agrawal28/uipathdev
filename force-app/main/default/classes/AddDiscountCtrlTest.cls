@IsTest
public class AddDiscountCtrlTest 
{
	@isTest
    public static void testLightningDiscountAll()
    {
        // Data setup
        PriceBook2 pb = new PriceBook2();
        pb.Name = 'Test PriceBook';        
        insert pb;
        
        Product2 p = new Product2();
        p.Name = 'Test Product';
        p.Ext_Id__c='testProductName100';
        p.ProductCode='testProductName100';
        p.Family='Other';
        insert p;
        
        PricebookEntry pbe1 = new PricebookEntry();
        pbe1.UnitPrice = 5000;
        pbe1.UseStandardPrice = false;
        pbe1.Pricebook2Id = Test.getStandardPricebookId();
        pbe1.Product2Id = p.Id;
        insert pbe1;
        
        
        PricebookEntry pbe = new PricebookEntry();
        pbe.UnitPrice = 5000;
        pbe.UseStandardPrice = false;
        pbe.Pricebook2Id = pb.Id;
        pbe.Product2Id = p.Id;
        pbe.isActive = true;
        insert pbe;
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Industry = 'Chemicals';
        acc.BillingCountry = 'Kiribati';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.Id;
        opp.Type = 'New Business';
        opp.CloseDate = date.newInstance(2160, 2, 17);
        opp.StageName = 'Discovery';
        opp.Pricebook2Id = pb.id;
        opp.LeadSource = 'Partner';
        insert opp;
        
        OpportunityLineItem oli = new OpportunityLineItem();        
        oli.OpportunityId = opp.id;        
        oli.Quantity = 1;        
        oli.TotalPrice = 5000;
        oli.PricebookEntryId = pbe.id;
        insert oli;
        
        OpportunityLineItem oli1 = new OpportunityLineItem();        
        oli1.OpportunityId = opp.id;        
        oli1.Quantity = 1;
        oli1.TotalPrice = 5000;
        oli1.PricebookEntryId = pbe.id;
        insert oli1;
        // Run the code
        Test.startTest();
        
		addDiscountCtrl.getInfo(opp.Id);       
        addDiscountCtrl.getOptions();
        addDiscountCtrl.calculateDiscount('Apply to all products', '', opp.Id, '15');        
        Test.stopTest();
        
        // Verify Results
     	list<OpportunityLineItem> oliList = [select id, discount from OpportunityLineItem where OpportunityId = :opp.Id];
       
        System.assertEquals(15,oliList[0].discount);
        System.assertEquals(15,oliList[1].discount);
        System.assertEquals(2, oliList.size());
    }
    
    @isTest
    public static void testLightningDiscountEach()
    {
        // Data setup
        PriceBook2 pb = new PriceBook2();
        pb.Name = 'Test PriceBook';        
        insert pb;
        
        Product2 p = new Product2();
        p.Name = 'Test Product';
        p.Ext_Id__c='testProductName003';
        p.ProductCode='testProductName003';
        p.Family='Other';
        insert p;
        
        PricebookEntry pbe1 = new PricebookEntry();
        pbe1.UnitPrice = 5000;
        pbe1.UseStandardPrice = false;
        pbe1.Pricebook2Id = Test.getStandardPricebookId();
        pbe1.Product2Id = p.Id;
        insert pbe1;
        
        
        PricebookEntry pbe = new PricebookEntry();
        pbe.UnitPrice = 5000;
        pbe.UseStandardPrice = false;
        pbe.Pricebook2Id = pb.Id;
        pbe.Product2Id = p.Id;
        pbe.isActive = true;
        insert pbe;
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Industry = 'Chemicals';
        acc.BillingCountry = 'Kiribati';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.Id;
        opp.Type = 'New Business';
        opp.CloseDate = date.newInstance(2160, 2, 17);
        opp.StageName = 'Discovery';
        opp.Pricebook2Id = pb.id;
        opp.LeadSource = 'Partner';
        insert opp;
        
        OpportunityLineItem oli = new OpportunityLineItem();        
        oli.OpportunityId = opp.id;        
        oli.Quantity = 1;        
        oli.TotalPrice = 5000;
        oli.PricebookEntryId = pbe.id;
        insert oli;
        
        OpportunityLineItem oli1 = new OpportunityLineItem();        
        oli1.OpportunityId = opp.id;        
        oli1.Quantity = 1;
        oli1.TotalPrice = 5000;
        oli1.PricebookEntryId = pbe.id;
        insert oli1;
        
        list<OpportunityLineItem> nameList = [select Id, Name from OpportunityLineItem where OpportunityId = :opp.Id];
        
        string oppProd = '[{"theId":"' + nameList[0].Id + '","discount":"5.00","label":"' + nameList[0].Name + '","quantity":"1.00","total":"4750.00","value":"5000.00"},{"theId":"' + nameList[1].Id + '","discount":"10.00","label":"' + nameList[1].Name + '","quantity":"1.00","total":"4500.00","value":"5000.00"}]';
		
        // Run the code
        Test.startTest();     
		
        addDiscountCtrl.calculateDiscount('Apply to each product indvidually', oppProd, opp.Id, '');        
        Test.stopTest();
        
        // Verify Results
     	list<OpportunityLineItem> oliList = [select id, discount from OpportunityLineItem where OpportunityId = :opp.Id];
       
        System.assertEquals(15,oliList[0].discount + oliList[1].discount);        
        System.assertEquals(2, oliList.size());
    }
}