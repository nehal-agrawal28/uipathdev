/* run batch =============================================================
   AccountCompanyTierBatch  accBatchObject = new AccountCompanyTierBatch(); 
   Id batchId = Database.executeBatch(accBatchObject);
==========================================================================*/

global class AccountCompanyTierBatch implements Database.Batchable<sObject> {
    /*private final List<SObject> accountsLst;
    private final List<SObject> topAccountsLst;
    private final Map<Id, SObject> oldAccountsMap;
    
    // Region Specific Sets
    private static Set<String> AMERRegionSpecEnterprise = new Set<String>{
    'Enterprise Tier 1',
    'Enterprise Tier 2',
    'Enterprise Tier 3'
    };
    private static Set<String> AMERRegionSpecVelocity = new Set<String>{
    'Velocity Tier 1',
    'Velocity Tier 2',
    'Velocity Tier 3'
    };
    private static Set<String> IndiaRegionSpecEnterprise = new Set<String>{ 'BPO Accounts', 'India Business', 'India Business - Top Strategic Accounts', 'India Business - Next Large Enterprise Accounts', 'India Business - Mid Market'};
    
    // Ultimate Parent Classification
    private static Set<String> ClassificationAMERIndiaJapan = new Set<String>{ 'KAP', 'Enterprise', 'Growth' };
    private static Set<String> ClassificationAPACEMEA = new Set<String>{ 'KAP', 'Enterprise' };
    private static Set<String> ClassificationAMER = new Set<String>{ 'Velocity', 'Commercial', 'SMB' };
    private static Set<String> ClassificationAPACEMEAINDIA = new Set<String>{ 'Velocity', 'Commercial' };
    private static Set<String> ClassificationJapan = new Set<String>{ 'Velocity', 'Commercial', 'Inside Sales' };
    
    // Classificatin Sets
    private static Set<String> ClassificationEnterprise = new Set<String>{ 'KAP', 'Enterprise' };
    private static Set<String> ClassificationVelocity = new Set<String>{ 'Velocity' };
    private static Set<String> ClassificationCommercial = new Set<String>{ 'Commercial' };
    private static Set<String> ClassificationSMB = new Set<String>{ 'SMB' };
    
    // UIPath Sets
    private static Set<String> AMERUiPathProgram = new Set<String>{ 'Strategic AMER', 'GOV' };
    private static Set<String> APACUiPathProgram = new Set<String>{ 'Strategic APAC' };
    
    // Industry Sets
    private static Set<String> AccountIndustries = new Set<String>{ 'Public Sector', 'Government' };
    private static Set<String> APACEmailDomains = new Set<String>{ 'gov.sg', 'edu.sg', 'gov.au', 'edu.au' };*/
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
         
        String query = ''; // 'SELECT Id, Top_Account__c, Has_Open_Opportunities__c, ParentId, Geo__c, Classification__c, UiPath_Program__c, Region_Specific__c, Industry, Company_Tier__c, Email_Domain__c, Ultimate_Parent_Classification__c FROM Account';
        return Database.getQueryLocator(query);
    }
     
    global void execute(Database.BatchableContext BC, List<Account> accList) {
        
        /*for(Account acc : accList) {        
            if ((acc.Has_Open_Opportunities__c != null && acc.Has_Open_Opportunities__c > 0) || acc.Top_Account__c == true) {
              acc.Company_Tier__c = 'A';
            } else {
              processAccountGeo(acc);
            }
        }
        try {
            // Update the Account Record
            update accList;
         
        } catch(Exception e) {
            System.debug(e);
        }*/
         
    }
    
   /* private static void processAccountGeo(Account acc) {
    acc.Company_Tier__c = '';
    if (acc.Geo__c == 'AMER')
      processAMERAccount(acc);
    if (acc.Geo__c == 'India')
      processIndiaAccount(acc);
    if (acc.Geo__c == 'APAC')
      processAPACAccount(acc);
    if (acc.Geo__c == 'EMEA')
      processEMEAAccount(acc);
    if (acc.Geo__c == 'Japan')
      processJapanAccount(acc);
  }

  private static void processAMERAccount(Account acc) {
    // Enterprise
    if (
      AMERRegionSpecEnterprise.contains(acc.Region_Specific__c) ||
      ClassificationEnterprise.contains(acc.Classification__c) ||
      AMERUiPathProgram.contains(acc.UiPath_Program__c) ||
      ClassificationAMERIndiaJapan.contains(acc.Ultimate_Parent_Classification__c)
    ) {
      acc.Company_Tier__c = 'A';
    } else {
      // Velocity
      if (
        AMERRegionSpecVelocity.contains(acc.Region_Specific__c) ||
        ClassificationVelocity.contains(acc.Classification__c) ||
        ClassificationAMER.contains(acc.Ultimate_Parent_Classification__c)
      ) {
        acc.Company_Tier__c = 'B';
      }
    }
  }

  private static void processIndiaAccount(Account acc) {
    if (IndiaRegionSpecEnterprise.contains(acc.Region_Specific__c)) {
      // Enterprise
      if (
        ClassificationEnterprise.contains(acc.Classification__c) ||
        ClassificationAMERIndiaJapan.contains(acc.Ultimate_Parent_Classification__c)
      ) {
        acc.Company_Tier__c = 'A';
      } else {
        // Velocity
        if (
          ClassificationCommercial.contains(acc.Classification__c) ||
          ClassificationAPACEMEAINDIA.contains(acc.Ultimate_Parent_Classification__c)
        ) {
          acc.Company_Tier__c = 'B';
        } else {
          if (ClassificationSMB.contains(acc.Ultimate_Parent_Classification__c)) {
            acc.Company_Tier__c = 'C';
          }
        }
      }
    }
  }

  private static void processAPACAccount(Account acc) {
    // Enterprise
    if (
      ClassificationEnterprise.contains(acc.Classification__c) ||
      APACUiPathProgram.contains(acc.UiPath_Program__c) ||
      AccountIndustries.contains(acc.Industry) ||
      APACEmailDomains.contains(acc.Email_Domain__c) ||
      ClassificationAPACEMEA.contains(acc.Ultimate_Parent_Classification__c)
    ) {
      acc.Company_Tier__c = 'A';
    } else {
      // Velocity
      if (
        ClassificationCommercial.contains(acc.Classification__c) ||
        ClassificationAPACEMEAINDIA.contains(acc.Ultimate_Parent_Classification__c)
      ) {
        acc.Company_Tier__c = 'B';
      } else {
        if (
          ClassificationSMB.contains(acc.Classification__c) ||
          ClassificationSMB.contains(acc.Ultimate_Parent_Classification__c)
        ) {
          acc.Company_Tier__c = 'C';
        }
      }
    }
  }

  private static void processEMEAAccount(Account acc) {
    // Enterprise
    if (
      ClassificationEnterprise.contains(acc.Classification__c) ||
      AccountIndustries.contains(acc.Industry) ||
      ClassificationAPACEMEA.contains(acc.Ultimate_Parent_Classification__c)
    ) {
      acc.Company_Tier__c = 'A';
    } else {
      // Velocity
      if (
        ClassificationCommercial.contains(acc.Classification__c) ||
        ClassificationAPACEMEAINDIA.contains(acc.Ultimate_Parent_Classification__c)
      ) {
        acc.Company_Tier__c = 'B';
      } else {
        if (
          ClassificationSMB.contains(acc.Classification__c) ||
          ClassificationSMB.contains(acc.Ultimate_Parent_Classification__c)
        ) {
          acc.Company_Tier__c = 'C';
        }
      }
    }
  }

  private static void processJapanAccount(Account acc) {
    // Enterprise
    if (
      ClassificationEnterprise.contains(acc.Classification__c) ||
      ClassificationAMERIndiaJapan.contains(acc.Ultimate_Parent_Classification__c)
    ) {
      acc.Company_Tier__c = 'A';
    } else {
      // Velocity
      if (
        ClassificationCommercial.contains(acc.Classification__c) ||
        ClassificationJapan.contains(acc.Ultimate_Parent_Classification__c)
      ) {
        acc.Company_Tier__c = 'B';
      } else {
        if (
          ClassificationSMB.contains(acc.Classification__c) ||
          ClassificationSMB.contains(acc.Ultimate_Parent_Classification__c)
        ) {
          acc.Company_Tier__c = 'C';
        }
      }
    }
  }*/
    
       
     
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
    }
}