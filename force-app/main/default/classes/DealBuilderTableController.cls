public with sharing class DealBuilderTableController {
  public class DataWrapper {
    @AuraEnabled
    public List<SObject> dataList { get; set; }
  }

  @AuraEnabled
  public static DataWrapper getData(String accountId, String type) {
    DataWrapper wrapper = new DataWrapper();

    if (type == 'Renewals_of_Contracts') {
      wrapper.dataList = getCurrentFiscalYearRenewalOpportunities(accountId);
    } else if (type == 'Other_Renewals_NotMerged') {
      wrapper.dataList = getAllOtherRenewalsNotMerged(accountId);
    } else if (type == 'Other_Renewals_Merged') {
      wrapper.dataList = getAllOtherRenewalsMerged(accountId);
    } else if (type == 'New_Business_Upsell') {
      wrapper.dataList = getNewContractOpportunities(accountId);
    } else if (type == 'Open_Amendments') {
      wrapper.dataList = getAmendmentOpportunities(accountId);
    } else if (type == 'Active_Contracts') {
      wrapper.dataList = getActiveContracts(accountId);
    } else if (type == 'Active_Contracts_Within_Hierarchy') {
      wrapper.dataList = getActiveContractsWithinHierarchy(accountId);
    } else if (type == 'Rip_Replace_Transactions') {
      wrapper.dataList = getRipReplacements(accountId);
    } else {
      wrapper.dataList = new List<SObject>();
    }

    return wrapper;
  }

  private static List<Opportunity> getCurrentFiscalYearRenewalOpportunities(String accId) {
    Set<Id> opps = new Set<Id>();
    for (Contract c : [
      SELECT Id, SBQQ__RenewalOpportunity__c
      FROM Contract
      WHERE AccountId = :accId AND SBQQ__RenewalOpportunity__c != NULL AND EndDate = THIS_FISCAL_YEAR
      ORDER BY EndDate ASC
    ]) {
      opps.add(c.SBQQ__RenewalOpportunity__c);
    }
    return [
      SELECT
        Id,
        Name,
        StageName,
        CloseDate,
        SBQQ__RenewedContract__r.ContractNumber,
        Amount,
        ARR_to_Renew__c,
        CPQ_OpportunityARR__c,
        SBQQ__PrimaryQuote__r.Name,
        SBQQ__PrimaryQuote__r.SBQQ__StartDate__c,
        SBQQ__PrimaryQuote__r.SBQQ__EndDate__c,
        Renewal_Expiry_Date__c,
        CurrencyIsoCode,
        (
          SELECT Id, ContractNumber
          // ,
          // SBQQ__RenewalOpportunity__c,
          // SBQQ__RenewalOpportunity__r.Name,
          // EndDate,
          // SBQQ__RenewalOpportunity__r.StageName,
          // SBQQ__RenewalOpportunity__r.CloseDate,
          // SBQQ__RenewalOpportunity__r.ARR_to_Renew__c,
          // SBQQ__RenewalOpportunity__r.CPQ_OpportunityARR__c
          FROM SBQQ__RenewedContracts__r
          WHERE AccountId = :accId AND SBQQ__RenewalOpportunity__c != NULL AND EndDate = THIS_FISCAL_YEAR
          ORDER BY EndDate ASC
        ),
        (
          SELECT
            Id,
            OrderNumber,
            Status,
            NS_Sales_Order_ID__c,
            Finance_Case__r.CaseNumber,
            Finance_Case__r.Invoice_Number__c
          FROM Orders
          LIMIT 1
        ),
        (SELECT Id, ContractNumber FROM SBQQ__Contracts__r LIMIT 1),
        (SELECT Id, Product2.Name, quantity, start_date_truncated__c, end_date__c, totalprice FROM OpportunityLineItems)
      FROM Opportunity
      WHERE Id IN :opps
    ];
  }

  private static List<Opportunity> getAllOtherRenewalsNotMerged(String accId) {
    List<Opportunity> oppList = new List<Opportunity>();
    for (Opportunity opp : getAllOtherRenewals(accId)) {
      if (opp.Id == opp.SBQQ__RenewedContract__r.SBQQ__RenewalOpportunity__c) {
        oppList.add(opp);
      }
    }
    return oppList;
  }
  private static List<Opportunity> getAllOtherRenewalsMerged(String accId) {
    List<Opportunity> oppList = new List<Opportunity>();
    for (Opportunity opp : getAllOtherRenewals(accId)) {
      if (opp.Id != opp.SBQQ__RenewedContract__r.SBQQ__RenewalOpportunity__c) {
        oppList.add(opp);
      }
    }
    return oppList;
  }
  private static List<Opportunity> getAllOtherRenewals(String accId) {
    Set<Id> opps = new Set<Id>();
    for (Contract c : [
      SELECT Id, SBQQ__RenewalOpportunity__c
      FROM Contract
      WHERE AccountId = :accId AND SBQQ__RenewalOpportunity__c != NULL AND EndDate = THIS_FISCAL_YEAR
      ORDER BY EndDate ASC
    ]) {
      opps.add(c.SBQQ__RenewalOpportunity__c);
    }

    return [
      SELECT
        Id,
        Name,
        StageName,
        CloseDate,
        SBQQ__RenewedContract__r.ContractNumber,
        SBQQ__RenewedContract__r.SBQQ__RenewalOpportunity__c,
        Amount,
        ARR_to_Renew__c,
        CPQ_OpportunityARR__c,
        SBQQ__PrimaryQuote__r.Name,
        SBQQ__PrimaryQuote__r.SBQQ__StartDate__c,
        SBQQ__PrimaryQuote__r.SBQQ__EndDate__c,
        CurrencyIsoCode,
        Renewal_Expiry_Date__c,
        (
          SELECT Id, ContractNumber
          FROM SBQQ__RenewedContracts__r
          WHERE AccountId = :accId AND SBQQ__RenewalOpportunity__c != NULL
          ORDER BY EndDate ASC
        ),
        (
          SELECT
            Id,
            OrderNumber,
            Status,
            NS_Sales_Order_ID__c,
            Finance_Case__r.CaseNumber,
            Finance_Case__r.Invoice_Number__c
          FROM Orders
          LIMIT 1
        ),
        (SELECT Id, ContractNumber FROM SBQQ__Contracts__r LIMIT 1),
        (SELECT Id, Product2.Name, quantity, start_date_truncated__c, end_date__c, totalprice FROM OpportunityLineItems)
      FROM Opportunity
      WHERE AccountId = :accId AND SBQQ__RenewedContract__c != NULL AND Id NOT IN :opps
      ORDER BY CloseDate DESC
    ];
  }

  private static List<Opportunity> getNewContractOpportunities(String accId) {
    return [
      SELECT
        Id,
        Name,
        StageName,
        CloseDate,
        Amount,
        SBQQ__PrimaryQuote__r.Name,
        SBQQ__PrimaryQuote__r.SBQQ__StartDate__c,
        SBQQ__PrimaryQuote__r.SBQQ__EndDate__c,
        CurrencyIsoCode,
        (
          SELECT
            Id,
            OrderNumber,
            Status,
            NS_Sales_Order_ID__c,
            Finance_Case__r.CaseNumber,
            Finance_Case__r.Invoice_Number__c
          FROM Orders
          LIMIT 1
        ),
        (SELECT Id, ContractNumber FROM SBQQ__Contracts__r LIMIT 1),
        (SELECT Id, Product2.Name, quantity, start_date_truncated__c, end_date__c, totalprice FROM OpportunityLineItems)
      FROM Opportunity
      WHERE
        AccountId = :accId
        AND SBQQ__RenewedContract__c = NULL
        AND SBQQ__AmendedContract__c = NULL
        AND (IsWon = TRUE
        OR IsClosed = FALSE)
        AND CloseDate >= LAST_N_YEARS:3
      ORDER BY CloseDate DESC
    ];
  }

  private static List<Opportunity> getAmendmentOpportunities(String accId) {
    return [
      SELECT
        Id,
        Name,
        StageName,
        CloseDate,
        SBQQ__AmendedContract__r.ContractNumber,
        Amount,
        SBQQ__PrimaryQuote__r.Name,
        SBQQ__PrimaryQuote__r.SBQQ__StartDate__c,
        SBQQ__PrimaryQuote__r.SBQQ__EndDate__c,
        CurrencyIsoCode,
        (
          SELECT
            Id,
            OrderNumber,
            Status,
            NS_Sales_Order_ID__c,
            Finance_Case__r.CaseNumber,
            Finance_Case__r.Invoice_Number__c
          FROM Orders
          LIMIT 1
        ),
        (SELECT Id, ContractNumber FROM SBQQ__Contracts__r LIMIT 1),
        (SELECT Id, Product2.Name, quantity, start_date_truncated__c, end_date__c, totalprice FROM OpportunityLineItems)
      FROM Opportunity
      WHERE AccountId = :accId AND SBQQ__AmendedContract__c != NULL AND (IsWon = TRUE OR IsClosed = FALSE)
      ORDER BY CloseDate DESC
    ];
  }

  private static List<Contract> getActiveContractsWithinHierarchy(String accId) {
    List<Id> accIds = allAccountsInHierarchy(accId);
    return getActiveContracts(accIds);
  }
  private static List<Contract> getActiveContracts(String accId) {
    return getActiveContracts(new List<String>{ accId });
  }
  private static List<Contract> getActiveContracts(List<String> accIds) {
    return [
      SELECT
        Id,
        ContractNumber,
        AccountId,
        Account.Name,
        Bill_To__c,
        Bill_To__r.Name,
        Deal_Type__c,
        SBQQ__Opportunity__c,
        SBQQ__Opportunity__r.Name,
        SBQQ__Opportunity__r.Amount,
        SBQQ__Opportunity__r.Pricebook2Id,
        SBQQ__Opportunity__r.Pricebook2.Name,
        SBQQ__RenewalOpportunity__c,
        SBQQ__RenewalOpportunity__r.Name,
        StartDate,
        EndDate,
        Status,
        SBQQ__Quote__c,
        SBQQ__Quote__r.Name,
        SBQQ__Order__c,
        SBQQ__Order__r.Name,
        OwnerId,
        Owner.Name,
        SBQQ__RenewalOwner__c,
        SBQQ__RenewalOwner__r.Name,
        Pricebook2Id,
        Pricebook2.Name,
        SBQQ__OpportunityPricebookId__c,
        Sold_to_Partner__c,
        Sold_to_Partner__r.Name,
        CurrencyIsoCode,
        SBQQ__RenewalUpliftRate__c,
        Uplift_Exception_Reason__c,
        Contract_Uplift_Enabled__c,
        Account.Primary_Subsidiary__c,
        (
          SELECT
            Id,
            Name,
            SBQQ__Product__c,
            SBQQ__Product__r.Name,
            SBQQ__NetPrice__c,
            SBQQ__Quantity__c,
            SBQQ__StartDate__c,
            SBQQ__EndDate__c,
            SBQQ__RenewalUpliftRate__c,
            Uplift_Exception_Reason__c
          FROM SBQQ__Subscriptions__r
        )
      FROM Contract
      WHERE AccountId IN :accIds
      ORDER BY EndDate DESC
    ];
  }

  private static List<Id> allAccountsInHierarchy(String accountId) {
    Id topLevelAccountId = getTopLevelAccount(accountId);
    List<Id> accountIds = getChildrenAccount(topLevelAccountId);
    return accountIds;
  }
  private static Id getTopLevelAccount(String currentAccountId) {
    Id topLevelAccountId;
    Boolean topLevelAccountFetched = false;

    while (!topLevelAccountFetched) {
      Account currentAccount = [
        SELECT
          Id,
          ParentId,
          Parent.ParentId,
          Parent.Parent.ParentId,
          Parent.Parent.Parent.ParentId,
          Parent.Parent.Parent.Parent.ParentId
        FROM Account
        WHERE Id = :currentAccountId
      ];
      if (currentAccount.ParentId == null) {
        topLevelAccountId = currentAccount.Id;
        topLevelAccountFetched = true;
      } else if (currentAccount.Parent.ParentId == null) {
        topLevelAccountId = currentAccount.ParentId;
        topLevelAccountFetched = true;
      } else if (currentAccount.Parent.Parent.ParentId == null) {
        topLevelAccountId = currentAccount.Parent.ParentId;
        topLevelAccountFetched = true;
      } else if (currentAccount.Parent.Parent.Parent.ParentId == null) {
        topLevelAccountId = currentAccount.Parent.Parent.ParentId;
        topLevelAccountFetched = true;
      } else if (currentAccount.Parent.Parent.Parent.Parent.ParentId == null) {
        topLevelAccountId = currentAccount.Parent.Parent.Parent.ParentId;
        topLevelAccountFetched = true;
      } else {
        currentAccountId = currentAccount.Parent.Parent.Parent.Parent.ParentId;
      }
    }
    return topLevelAccountId;
  }
  private static List<Id> getChildrenAccount(Id topLevelAccountId) {
    List<Id> accountIds = new List<Id>{ topLevelAccountId };
    for (Account acc : [
      SELECT Id
      FROM Account
      WHERE
        Id NOT IN :accountIds
        AND (ParentId IN :accountIds
        OR Parent.ParentId IN :accountIds
        OR Parent.Parent.ParentId IN :accountIds
        OR Parent.Parent.Parent.ParentId IN :accountIds
        OR Parent.Parent.Parent.Parent.ParentId IN :accountIds)
    ]) {
      accountIds.add(acc.Id);
    }
    return accountIds;
  }

  private static List<SBQQ__Quote__c> getRipReplacements(String accountId) {
    return [
      SELECT
        Id,
        Name,
        SBQQ__StartDate__c,
        SBQQ__EndDate__c,
        SBQQ__Opportunity2__c,
        SBQQ__Opportunity2__r.Name,
        SBQQ__Opportunity2__r.StageName,
        SBQQ__Opportunity2__r.CloseDate,
        SBQQ__Opportunity2__r.Amount,
        SBQQ__Opportunity2__r.CurrencyIsoCode,
        (
          SELECT
            Id,
            Name,
            SBQQ__StartDate__c,
            SBQQ__EndDate__c,
            SBQQ__Account__c,
            SBQQ__Account__r.Name,
            SBQQ__Opportunity2__c,
            SBQQ__Opportunity2__r.Name,
            SBQQ__Opportunity2__r.Amount,
            SBQQ__Opportunity2__r.CurrencyIsoCode,
            SBQQ__Opportunity2__r.SBQQ__AmendedContract__c,
            SBQQ__Opportunity2__r.SBQQ__AmendedContract__r.ContractNumber
          FROM CancellationQuotes__r
        ),
        (
          SELECT
            Id,
            Status__c,
            Type__c,
            Account__c,
            Contract__c,
            Contract__r.ContractNumber,
            Opportunity__c,
            Quote__c,
            UIMessage__c,
            Error__c
          FROM Async_Tasks__r
        )
      FROM SBQQ__Quote__c
      WHERE SBQQ__Primary__c = TRUE AND Replacement_Transaction__c = TRUE AND SBQQ__Account__c = :accountId
      ORDER BY CreatedDate DESC
    ];
  }
}