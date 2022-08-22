@IsTest
public class PartnerInvolvementTriggerAllTest 
{
    // @isTest
    // public static void testOpportunityUpdate()
    // {
    //     Account acc = new Account (Name = 'newAcc1',
    //                                BillingCountry ='United Kingdom',
    //                                Industry = 'Others',
    //                                RecordTypeId = '01236000000OGv1'
    //                               );        
    //     insert acc;
        
    //     Account acc1 = new Account (Name = 'newAcc2',
    //                                BillingCountry ='Uganda',
    //                                Industry = 'Others',
    //                                RecordTypeId = '01236000001UOmp'
    //                               );        
    //     insert acc1;
        
    //     Opportunity o = new Opportunity(Accountid = acc.id,
    //                                     StageName = 'Discovery',
    //                                     CloseDate = system.today(),
    //                                     Name = 'Test Op',
    //                                     Type = 'Upsell',
    //                                     Deal_Type__c = 'Resale',
    //                                     CurrencyIsoCode = 'EUR',
    //                                     Led_by__c = 'Direct Led',
    //                                     LeadSource = 'Partner'                                                                             
    //                                    );        
    //     insert o;
        
    //     Partner_Involvement__c pic = new Partner_Involvement__c(Partner_Delivery_Role__c = 'Primary Implementation',
    //                                                             Partner_Sales_Role__c = 'Sold to Partner (Buying Directly from UiPath)',
    //                                                             Partner_Account_Name__c = acc1.Id,                                                                
    //                                                             CurrencyIsoCode = 'USD',
    //                                                             PartnerOpp_Name__c = o.Id,
                                                                
    //                                                             Partner_Sales_Contribution__c = 'Led',
    //                                                             Partner_Technical_Contribution__c = 'Led (Primary Implementation)'
    //                                                            );
        
    //     test.startTest();
        
    //     insert pic; 
        
    //     //pic.Partner_Account_Name__c = acc1.Id;
    //     //pic.Partner_Role__c = 'VAR/Reseller';
        
    //     //update pic;
        
    //     test.stopTest();
        
    //     Opportunity oppTest = [select Id, Sold_to_Partner__c, Implementation_Partner__c from Opportunity where Id = :pic.PartnerOpp_Name__c];
        
    //     System.assertEquals(oppTest.Sold_to_Partner__c, acc1.Id);
    //     System.assertEquals(oppTest.Implementation_Partner__c, acc1.Id);
        
    //     delete pic;
    // }
    
//    @isTest
//            public static void testCreateByJPCommunity() {
//                //user
//                String nowStr1 = String.valueOf(Datetime.now()).remove(':').remove(' ').remove('-') + '1';
//                Account u_acc = new Account(
//                    Name = 'u_hogeAccount' + nowStr1,
//                    Country__c = 'Japan',
//                    Industry = 'Chemicals'
//                );
//                insert u_acc;
         
//                u_acc.IsPartner = true;
//                update u_acc;
                
//                Contact u_con = new Contact(
//                    LastName = 'u_hogeContact' + nowStr1,
//                    AccountId = u_acc.id,
//                    Email = 'testcontact544628@emailtest.com'
//                );
//                insert u_con;
         
//                Profile u_prf = [SELECT Id, Name FROM Profile WHERE Name = 'UiPath Japan Partner Community' LIMIT 1];
         
//                User u = new User(
//                    Email = 'testCreByJP' + nowStr1 + '@example.com',
//                    ProfileId = u_prf.Id,
//                    UserName = 'testCreByJP' + nowStr1 + '@example.com',
//                    Alias = 'testJP',
//                    TimeZoneSidKey='Asia/Tokyo',
//                    EmailEncodingKey='UTF-8',
//                    LocaleSidKey='ja_JP',
//                    LanguageLocaleKey='ja',
//                    ContactId = u_con.Id,
//                    PortalRole = 'Manager',
//                    FirstName = 'FirstName',
//                    LastName = 'LastName'
//                );
//                insert u;
                
//                System.runAs(u) {
//                    List<Partner_Involvement__c> newList = new List<Partner_Involvement__c>();
//                    newList.add(new Partner_Involvement__c());
                    
//                    PartnerInvolvementTriggerAllHandler handler = new PartnerInvolvementTriggerAllHandler();
                    
//                    handler.setDefaultValue4JP(newList);
//                }
//            }

//     @IsTest
//     public static void applyPartnerInfluenceApprovalMatrixTest(){
//         //setup test data
//         Map<String, User> userMap = new Map<String, User>();

//         userMap.put(
//                 'Test Admin User',
//                 DataFactory_CM.createUser(
//                         'Test',
//                         'User 1',
//                         'System Administrator',
//                         false
//                 )
//         );

//         userMap.put(
//                 'AMER Approver',
//                 DataFactory_CM.createUser(
//                         'Test',
//                         'AMER Approver',
//                         'Sales Manager',
//                         false
//                 )
//         );

//         userMap.put(
//                 'AMER Non GSI Approver',
//                 DataFactory_CM.createUser(
//                         'Test AMER',
//                         'Non GSI Approver',
//                         'Sales Manager',
//                         false
//                 )
//         );

//         userMap.put(
//                 'AMER GSI Approver',
//                 DataFactory_CM.createUser(
//                         'Test',
//                         'AMER GSI Approver',
//                         'Sales Manager',
//                         false
//                 )
//         );

//         userMap.put(
//                 'AMER VAR Approver',
//                 DataFactory_CM.createUser(
//                         'Test',
//                         'AMER VAR Approver',
//                         'Sales Manager',
//                         false
//                 )
//         );

//         userMap.put(
//                 'APAC Approver',
//                 DataFactory_CM.createUser(
//                         'Test',
//                         'APAC Approver',
//                         'Sales Manager',
//                         false
//                 )
//         );

//         userMap.put(
//                 'AMER Opp Owner',
//                 DataFactory_CM.createUser(
//                         'Test',
//                         'AMER Opp Owner',
//                         'Sales Representative',
//                         false
//                 )
//         );

//         userMap.get('AMER Opp Owner').UserRoleId = [SELECT Id FROM UserRole
//         WHERE Name = 'AMER Pacific Northwest Sales'].Id;

//         userMap.put(
//                 'AMER Partner Opp Owner',
//                 DataFactory_CM.createUser(
//                         'Test',
//                         'AMER Partner Opp Owner',
//                         'Sales Representative',
//                         false
//                 )
//         );

//         userMap.get('AMER Partner Opp Owner').UserRoleId = [SELECT Id FROM UserRole
//         WHERE Name = 'AMER Global Partners VP'].Id;

//         insert userMap.values();

//         System.runAs(userMap.get('Test Admin User')) {
//             List<Quote_Approval_Matrix__c> matrixList = new List<Quote_Approval_Matrix__c>();
//             matrixList.add(
//                     DataFactory.createQuoteApprovalMatrix(
//                             'AMER',
//                             userMap.get('AMER Approver').Id,
//                             'Influence',
//                             'AMER Pacific Northwest Sales',
//                             '',
//                             '',
//                             false
//                     )
//             );
//             matrixList.get(0).X2nd_Approver_GSI__c = userMap.get('AMER GSI Approver').Id;
//             matrixList.get(0).X2nd_Approver_VAR__c = userMap.get('AMER VAR Approver').Id;

//             matrixList.add(
//                     DataFactory.createQuoteApprovalMatrix(
//                             'APJ',
//                             userMap.get('APAC Approver').Id,
//                             'Influence',
//                             '',
//                             'ANZ',
//                             'APAC',
//                             false
//                     )
//             );

//             matrixList.add(
//                     DataFactory.createQuoteApprovalMatrix(
//                             'AMER',
//                             userMap.get('AMER Non GSI Approver').Id,
//                             'Influence',
//                             'AMER Global Partners VP',
//                             '',
//                             '',
//                             false
//                     )
//             );

//             insert matrixList;


//             List<Account> accts = new List<Account>();
//             accts.add(
//                     new Account(
//                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Constants.ACCOUNT_RECORD_TYPE_1).getRecordTypeId(),
//                             Name = 'Test AMER',
//                             Country__c = 'United States',
//                             Industry = 'Apparel',
//                             OwnerId = userMap.get('AMER Opp Owner').Id,
//                             Geo__c = 'AMER',
//                             Ignore_Territory_Assignment__c = true
//                     )
//             );

//             accts.add(
//                     new Account(
//                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Constants.ACCOUNT_RECORD_TYPE_1).getRecordTypeId(),
//                             Name = 'Test APAC',
//                             Country__c = 'Australia',
//                             State__c = 'Victoria',
//                             Industry = 'Apparel',
//                             Geo__c = 'APJ',
//                             Area__c='APAC',
//                             Region__c = 'ANZ', // here we have ANZ, even if in cmt there is 'ANZ South' for Australia because OP should populate the Region with ANZ regardless of cmt
//                             Ignore_Territory_Assignment__c = true)
//             );

//             accts.add(
//                     new Account(
//                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Constants.ACCOUNT_RECORD_TYPE_2).getRecordTypeId(),
//                             Name = 'Test Partner',
//                             Country__c = 'United States',
//                             Industry = 'Technology',
//                             Geo__c = 'AMER',
//                             Ignore_Territory_Assignment__c = true
//                     )
//             );

//             accts.add(
//                     new Account(
//                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Constants.ACCOUNT_RECORD_TYPE_2).getRecordTypeId(),
//                             Name = 'Test BPO Partner',
//                             Country__c = 'United States',
//                             Industry = 'Technology',
//                             OwnerId = userMap.get('AMER Partner Opp Owner').Id,
//                             Geo__c = 'AMER',
//                             Ignore_Territory_Assignment__c = true
//                     )
//             );

//             accts.add(
//                     new Account(
//                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Constants.ACCOUNT_RECORD_TYPE_2).getRecordTypeId(),
//                             Name = 'Test GSI',
//                             Type = 'Business Partner',
//                             Business_Partner_Type__c = 'GSI',
//                             Country__c = 'United States',
//                             Industry = 'Technology',
//                             Geo__c = 'AMER',
//                             Ignore_Territory_Assignment__c = true
//                     )
//             );

//             insert accts;


//             List<Opportunity> opps = new List<Opportunity>();
//             opps.add(new Opportunity(
//                     AccountId = accts.get(0).Id,
//                     OwnerId = userMap.get('AMER Opp Owner').Id,
//                     Name = 'Test Opp AMER',
//                     Deal_Type__c = 'Direct',
//                     StageName = Constants.OPPORTUNITY_STAGE_DISCOVERY,
//                     CloseDate = System.today(),
//                     LeadSource =  'Webinar'
//             ));

//             opps.add(new Opportunity(
//                     AccountId = accts.get(3).Id,
//                     OwnerId = userMap.get('AMER Partner Opp Owner').Id,
//                     Name = 'Test PII AMER',
//                     Deal_Type__c = 'Partner Internal Infrastructure',
//                     StageName = Constants.OPPORTUNITY_STAGE_DISCOVERY,
//                     CloseDate = System.today(),
//                     LeadSource =  'Webinar'
//             ));

//             opps.add(new Opportunity(
//                     AccountId = accts.get(1).Id,
//                     Name = 'Test Opp APAC',
//                     Deal_Type__c = 'Direct',
//                     StageName = Constants.OPPORTUNITY_STAGE_DISCOVERY,
//                     CloseDate = System.today(),
//                     LeadSource =  'Webinar'
//             ));

//             insert opps;
//             List<Partner_Involvement__c> piList = new List<Partner_Involvement__c>();
//             piList.add(new Partner_Involvement__c(
//                     Partner_Account_Name__c = accts.get(2).Id,
//                     PartnerOpp_Name__c = opps.get(0).Id,
//                     Partner_Sales_Role__c = 'Influence (No Financial Comp from UiPath)',
//                     Partner_Delivery_Role__c = 'None',
                    
//                     Partner_Sales_Contribution__c = 'Led',
//                     Partner_Technical_Contribution__c = 'Led (Primary Implementation)'
//             ));

//             piList.add(new Partner_Involvement__c(
//                     Partner_Account_Name__c = accts.get(2).Id,
//                     PartnerOpp_Name__c = opps.get(2).Id,
//                     Partner_Sales_Role__c = 'Influence (No Financial Comp from UiPath)',
//                     Partner_Delivery_Role__c = 'None',
//                     Opportunity_Sourced__c = true,
//                     Partner_Sales_Contribution__c = 'Led',
//                     Partner_Technical_Contribution__c = 'Led (Primary Implementation)'
//             ));

//             piList.add(new Partner_Involvement__c(
//                     Partner_Account_Name__c = accts.get(2).Id,
//                     PartnerOpp_Name__c = opps.get(1).Id,
//                     Partner_Sales_Role__c = 'Influence (No Financial Comp from UiPath)',
//                     Partner_Delivery_Role__c = 'None',
                    
//                     Partner_Sales_Contribution__c = 'Led',
//                     Partner_Technical_Contribution__c = 'Led (Primary Implementation)'
//             ));

//             piList.add(new Partner_Involvement__c(
//                     Partner_Account_Name__c = accts.get(4).Id,
//                     PartnerOpp_Name__c = opps.get(0).Id,
//                     Partner_Sales_Role__c = 'Influence (No Financial Comp from UiPath)',
//                     Partner_Delivery_Role__c = 'None',
                    
//                     Partner_Sales_Contribution__c = 'Led',
//                     Partner_Technical_Contribution__c = 'Led (Primary Implementation)'
//             ));

//             insert piList;
//         }

//         Test.startTest();
//         Partner_Involvement__c amerPI = [SELECT Id, X1st_Approver__c FROM Partner_Involvement__c WHERE PartnerOpp_Name__r.Account.Name = 'Test AMER' AND Business_Partner_Type__c != 'GSI'];
//         Partner_Involvement__c apacPI = [SELECT Id, X1st_Approver__c FROM Partner_Involvement__c WHERE PartnerOpp_Name__r.Account.Name = 'Test APAC'];
//         Partner_Involvement__c partnerPI = [SELECT Id, X1st_Approver__c FROM Partner_Involvement__c WHERE PartnerOpp_Name__r.Account.Name = 'Test BPO Partner'];
//         Partner_Involvement__c gsiPI = [SELECT Id, X1st_Approver__c, X2nd_Approver__c FROM Partner_Involvement__c WHERE PartnerOpp_Name__r.Account.Name = 'Test AMER' AND Business_Partner_Type__c = 'GSI'];
//         Test.stopTest();

//         System.assertEquals(amerPI.X1st_Approver__c,userMap.get('AMER Approver').Id, 'AMER Non-GSI Approvals not working');

//         System.assertEquals(apacPI.X1st_Approver__c,userMap.get('APAC Approver').Id, 'APAC Approvals not working');

//         System.assertEquals(partnerPI.X1st_Approver__c,userMap.get('AMER Non GSI Approver').Id, 'AMER Non GSI Approvals not working');

//         System.assertEquals(gsiPI.X2nd_Approver__c,userMap.get('AMER GSI Approver').Id, 'AMER GSI Approvals not working');

//     }
}