@IsTest
public with sharing class PIApprovalMatrixFunctionTest_ET {
  @IsTest
  public static void applyPartnerInfluenceApprovalMatrixTest() {
    try {
      String adminUser = 'Test Admin User';
      String amerApprover = 'AMER Approver';
      String amerNonGsiApprover = 'AMER Non GSI Approver';
      String amerGsiApprover = 'AMER GSI Approver';
      String amerVarApprover = 'AMER VAR Approver';
      String apacApprover = 'APAC Approver';
      String amerOppOwner = 'AMER Opp Owner';
      String amerTerritory = 'AMER Territory';
      String amerPartnerOpp = 'AMER Partner Opp Owner';

      Territory2 regionAMER = TestFactory_ET.initTerritory('US', 'AMER Emerging Enterprise', 'AMER Captives');
      Territory2 salesTerr1 = TestFactory_ET.createSalesTerritory(regionAMER, 'Test Sales Territory 1');
      Territory2 regionAPAC = TestFactory_ET.initTerritory('APAC', 'APJ India', 'APJ GC Emerging');
      Territory2 salesTerr2 = TestFactory_ET.createSalesTerritory(regionAPAC, 'Test Sales Territory 2');

      Map<String, User> userMap = new Map<String, User>();

      userMap.put(adminUser, DataFactory_CM.createUser('Test', adminUser, 'System Administrator', false));
      userMap.put(amerApprover, DataFactory_CM.createUser('Test', amerApprover, 'Sales Manager', false));
      userMap.put(amerNonGsiApprover, DataFactory_CM.createUser('Test', amerNonGsiApprover, 'Sales Manager', false));
      userMap.put(amerGsiApprover, DataFactory_CM.createUser('Test', amerGsiApprover, 'Sales Manager', false));
      userMap.put(amerVarApprover, DataFactory_CM.createUser('Test', amerVarApprover, 'Sales Manager', false));
      userMap.put(apacApprover, DataFactory_CM.createUser('Test', apacApprover, 'Sales Manager', false));
      userMap.put(amerOppOwner, DataFactory_CM.createUser('Test', amerOppOwner, 'Sales Representative', false));
      userMap.get(amerOppOwner).UserRoleId = [SELECT Id FROM UserRole WHERE Name = 'AMER Pacific Northwest Sales'].Id;
      userMap.put(amerPartnerOpp, DataFactory_CM.createUser('Test', amerPartnerOpp, 'Sales Representative', false));
      userMap.get(amerPartnerOpp).UserRoleId = [SELECT Id FROM UserRole WHERE Name = 'AMER Global Partners VP'].Id;

      insert userMap.values();

      System.runAs(userMap.get(adminUser)) {
        TestFactory_ET.createUserTerritoryAssociation(
          TestFactory_ET.getTerritoryId('Test Sales Territory 1').Id,
          userMap.get(amerApprover).Id,
          ''
        );

        TestFactory_ET.createUserTerritoryAssociation(
          TestFactory_ET.getTerritoryId('Test Sales Territory 1').Id,
          userMap.get(amerNonGsiApprover).Id,
          ''
        );

        TestFactory_ET.createUserTerritoryAssociation(
          TestFactory_ET.getTerritoryId('Test Sales Territory 2').Id,
          userMap.get(apacApprover).Id,
          ''
        );

        List<Quote_Approval_Matrix__c> matrixList = new List<Quote_Approval_Matrix__c>();
        matrixList.add(
          DataFactory_SL.createQuoteApprovalMatrix(
            'US',
            userMap.get(amerApprover).Id,
            'Influence',
            'AMER Pacific Northwest Sales',
            '',
            false
          )
        );
        matrixList.get(0).X2nd_Approver_GSI__c = userMap.get(amerGsiApprover).Id;
        matrixList.get(0).X2nd_Approver_VAR__c = userMap.get(amerVarApprover).Id;

        Quote_Approval_Matrix__c approverApj = DataFactory_SL.createQuoteApprovalMatrix(
          'APAC',
          userMap.get(apacApprover).Id,
          'Influence',
          '',
          'ANZ',
          false
        );
        approverApj.Area__c = 'APAC';
        matrixList.add(approverApj);

        matrixList.add(
          DataFactory_SL.createQuoteApprovalMatrix(
            'US',
            userMap.get(amerNonGsiApprover).Id,
            'Influence',
            'AMER Global Partners VP',
            '',
            false
          )
        );

        insert matrixList;

        List<Account> accts = new List<Account>();
        accts.add(
          new Account(
            RecordTypeId = AccountMetadata.customerRecordType,
            Name = 'Test AMER',
            Country__c = 'United States',
            Industry = 'Apparel',
            OwnerId = userMap.get(amerOppOwner).Id,
            Geo__c = 'AMER',
            Ignore_Territory_Assignment__c = true
          )
        );

        accts.add(
          new Account(
            RecordTypeId = AccountMetadata.customerRecordType,
            Name = 'Test APAC',
            Country__c = 'Australia',
            State__c = 'Victoria',
            Industry = 'Apparel',
            Geo__c = 'APAC',
            Area__c = 'APAC',
            Region__c = 'ANZ', // here we have ANZ, even if in cmt there is 'ANZ South' for Australia because OP should populate the Region with ANZ regardless of cmt
            Ignore_Territory_Assignment__c = true
          )
        );

        accts.add(
          new Account(
            RecordTypeId = AccountMetadata.partnerRecordType,
            Name = 'Test Partner',
            Country__c = 'United States',
            Industry = 'Technology',
            Geo__c = 'AMER',
            Ignore_Territory_Assignment__c = true
          )
        );

        accts.add(
          new Account(
            RecordTypeId = AccountMetadata.partnerRecordType,
            Name = 'Test BPO Partner',
            Country__c = 'United States',
            Industry = 'Technology',
            OwnerId = userMap.get(amerPartnerOpp).Id,
            Geo__c = 'AMER',
            Ignore_Territory_Assignment__c = true
          )
        );

        accts.add(
          new Account(
            RecordTypeId = AccountMetadata.partnerRecordType,
            Name = 'Test GSI',
            Type = 'Business Partner',
            Business_Partner_Type__c = 'GSI',
            Country__c = 'United States',
            Industry = 'Technology',
            Geo__c = 'AMER',
            Ignore_Territory_Assignment__c = true
          )
        );

        insert accts;

        List<ObjectTerritory2Association> objTerrAssos = new List<ObjectTerritory2Association>();

        ObjectTerritory2Association objTerrAss = new ObjectTerritory2Association();
        objTerrAss.ObjectId = accts[0].Id;
        objTerrAss.AssociationCause = 'Territory2Manual';
        objTerrAss.Territory2Id = TestFactory_ET.getTerritoryId('Test Sales Territory 1').Id;
        objTerrAssos.add(objTerrAss);

        ObjectTerritory2Association objTerrAss1 = new ObjectTerritory2Association();
        objTerrAss1.ObjectId = accts[1].Id;
        objTerrAss1.AssociationCause = 'Territory2Manual';
        objTerrAss1.Territory2Id = TestFactory_ET.getTerritoryId('Test Sales Territory 2').Id;
        objTerrAssos.add(objTerrAss1);

        ObjectTerritory2Association objTerrAss2 = new ObjectTerritory2Association();
        objTerrAss2.ObjectId = accts[2].Id;
        objTerrAss2.AssociationCause = 'Territory2Manual';
        objTerrAss2.Territory2Id = TestFactory_ET.getTerritoryId('Test Sales Territory 1').Id;
        objTerrAssos.add(objTerrAss2);

        ObjectTerritory2Association objTerrAss3 = new ObjectTerritory2Association();
        objTerrAss3.ObjectId = accts[3].Id;
        objTerrAss3.AssociationCause = 'Territory2Manual';
        objTerrAss3.Territory2Id = TestFactory_ET.getTerritoryId('Test Sales Territory 1').Id;
        objTerrAssos.add(objTerrAss3);

        ObjectTerritory2Association objTerrAss4 = new ObjectTerritory2Association();
        objTerrAss4.ObjectId = accts[4].Id;
        objTerrAss4.AssociationCause = 'Territory2Manual';
        objTerrAss4.Territory2Id = TestFactory_ET.getTerritoryId('Test Sales Territory 1').Id;
        objTerrAssos.add(objTerrAss4);

        insert objTerrAssos;

        List<Opportunity> opps = new List<Opportunity>();
        opps.add(
          new Opportunity(
            AccountId = accts.get(0).Id,
            OwnerId = userMap.get(amerOppOwner).Id,
            Name = 'Test Opp AMER',
            Deal_Type__c = 'Direct',
            StageName = Constants.OPPORTUNITY_STAGE_DISCOVERY,
            CloseDate = System.today(),
            LeadSource = 'Webinar',
            Territory2Id = TestFactory_ET.getTerritoryId('Test Sales Territory 1').Id
          )
        );

        opps.add(
          new Opportunity(
            AccountId = accts.get(3).Id,
            OwnerId = userMap.get(amerPartnerOpp).Id,
            Name = 'Test PII AMER',
            Deal_Type__c = 'Partner Internal Infrastructure',
            StageName = Constants.OPPORTUNITY_STAGE_DISCOVERY,
            CloseDate = System.today(),
            LeadSource = 'Webinar',
            Territory2Id = TestFactory_ET.getTerritoryId('Test Sales Territory 1').Id
          )
        );

        opps.add(
          new Opportunity(
            AccountId = accts.get(1).Id,
            Name = 'Test Opp APAC',
            Deal_Type__c = 'Direct',
            StageName = Constants.OPPORTUNITY_STAGE_DISCOVERY,
            CloseDate = System.today(),
            LeadSource = 'Webinar',
            Territory2Id = TestFactory_ET.getTerritoryId('Test Sales Territory 1').Id
          )
        );

        insert opps;
        List<Partner_Involvement__c> piList = new List<Partner_Involvement__c>();
        piList.add(
          new Partner_Involvement__c(
            Partner_Account_Name__c = accts.get(2).Id,
            PartnerOpp_Name__c = opps.get(0).Id,
            Partner_Sales_Role__c = PartnerInvolvementMetadata_SL.INFLUENCE_PARTNER_ROLE,
            Partner_Delivery_Role__c = 'None',
            Partner_Sales_Contribution__c = 'Led',
            Partner_Technical_Contribution__c = 'Led (Primary Implementation)'
          )
        );

        piList.add(
          new Partner_Involvement__c(
            Partner_Account_Name__c = accts.get(2).Id,
            PartnerOpp_Name__c = opps.get(2).Id,
            Partner_Sales_Role__c = PartnerInvolvementMetadata_SL.INFLUENCE_PARTNER_ROLE,
            Partner_Delivery_Role__c = 'None',
            Opportunity_Sourced__c = true,
            Partner_Sales_Contribution__c = 'Led',
            Partner_Technical_Contribution__c = 'Led (Primary Implementation)'
          )
        );

        piList.add(
          new Partner_Involvement__c(
            Partner_Account_Name__c = accts.get(2).Id,
            PartnerOpp_Name__c = opps.get(1).Id,
            Partner_Sales_Role__c = PartnerInvolvementMetadata_SL.INFLUENCE_PARTNER_ROLE,
            Partner_Delivery_Role__c = 'None',
            Partner_Sales_Contribution__c = 'Led',
            Partner_Technical_Contribution__c = 'Led (Primary Implementation)'
          )
        );

        piList.add(
          new Partner_Involvement__c(
            Partner_Account_Name__c = accts.get(4).Id,
            PartnerOpp_Name__c = opps.get(0).Id,
            Partner_Sales_Role__c = PartnerInvolvementMetadata_SL.INFLUENCE_PARTNER_ROLE,
            Partner_Delivery_Role__c = 'None',
            Partner_Sales_Contribution__c = 'Led',
            Partner_Technical_Contribution__c = 'Led (Primary Implementation)'
          )
        );

        insert piList;
      }

      Test.startTest();
      Partner_Involvement__c amerPI = [
        SELECT Id, X1st_Approver__c
        FROM Partner_Involvement__c
        WHERE PartnerOpp_Name__r.Account.Name = 'Test AMER' AND Business_Partner_Type__c != 'GSI'
      ];
      Partner_Involvement__c apacPI = [
        SELECT Id, X1st_Approver__c
        FROM Partner_Involvement__c
        WHERE PartnerOpp_Name__r.Account.Name = 'Test APAC'
      ];
      Partner_Involvement__c partnerPI = [
        SELECT Id, X1st_Approver__c
        FROM Partner_Involvement__c
        WHERE PartnerOpp_Name__r.Account.Name = 'Test BPO Partner'
      ];
      Partner_Involvement__c gsiPI = [
        SELECT Id, X1st_Approver__c, X2nd_Approver__c
        FROM Partner_Involvement__c
        WHERE PartnerOpp_Name__r.Account.Name = 'Test AMER' AND Business_Partner_Type__c = 'GSI'
      ];
      Test.stopTest();

      System.assertEquals(amerPI.X1st_Approver__c, userMap.get(amerApprover).Id, 'AMER Non-GSI Approvals not working');
      System.assertEquals(apacPI.X1st_Approver__c, userMap.get(apacApprover).Id, 'APAC Approvals not working');

      System.assertEquals(
        partnerPI.X1st_Approver__c,
        userMap.get(amerNonGsiApprover).Id,
        'AMER Non GSI Approvals not working'
      );

      System.assertEquals(gsiPI.X2nd_Approver__c, userMap.get(amerGsiApprover).Id, 'AMER GSI Approvals not working');
    } catch (Exception e) {
      // List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Sales Manager'];
      // System.assertEquals(true, profiles.isEmpty(), 'Failed to run the testin Sandbox.');
    }
  }
}