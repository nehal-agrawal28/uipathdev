public with sharing class DealBuilderContractsController_DB {
  final static IContractsService_SL contractsService = (IContractsService_SL) Application_SL.Service.newInstance(
    IContractsService_SL.class
  );

  final static IAccountsService_SL accountsService = (IAccountsService_SL) Application_SL.Service.newInstance(
    IAccountsService_SL.class
  );

  final static IOpportunitiesService_SL opportunitiesService = (IOpportunitiesService_SL) Application_SL.Service.newInstance(
    IOpportunitiesService_SL.class
  );

  final static IQuoteService_SL quotesService = (IQuoteService_SL) Application_SL.Service.newInstance(
    IQuoteService_SL.class
  );

  private static QuotesSelector_SL quoteSelector {
    get {
      return (QuotesSelector_SL) Application_SL.Selector.newInstance(SBQQ__Quote__c.SObjectType);
    }
    set;
  }

  /**
   * Returns a list of contracts that are linked to the accounts that have been passed in
   *
   * @param  recordIds  account Ids that we are using to get the related contract
   * @param amountOfRecords Can pass a specific amount of records to get, or pass 'All'.
   * @return List<AmendmentContractMsg> a list of amendment contracts linked to an account
   */
  @AuraEnabled
  public static List<CPQContractMsg_SL> getContracts(List<String> recordIds, String amountOfRecords) {
    try {
      return contractsService.getActiveContractsByAccount(recordIds, amountOfRecords);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * Returns a list of accounts in the the accounts hierarchy with the passed in account id. It will also
   * return the account id that was passed in. It has a limit of 10,000 records
   *

   * @param  recordId  account Id that we are using to get related accounts
   * @return List<String> a list of account Ids
   */
  @AuraEnabled
  public static List<String> getAccounts(String recordId) {
    try {
      return accountsService.getRelatedAccounts(recordId);
    } catch (Exception e) {
      System.debug('Error Getting Accounts: ' + e.getCause().getMessage());
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * Returns a list of accounts in the the accounts hierarchy with the passed in account id. It will also
   * return the account id that was passed in. It has a limit of 10,000 records
   *
   * @param  amendContracts  contract message the data needed to amend contracts and create a new opportunity and quote
   * @return AmendContractJobMsg contains the new opportunity that was created, the new quote and a list of contracts and job ids
   */
  @AuraEnabled
  public static CancelContractJobMsg_SL amendContracts(CancelContractsMsg_SL amendContracts) {
    try {
      // GUARD CLAUSE: We only want to create a new contract and quote if we have passed in contracts
      if (amendContracts.contractIds == null || amendContracts.contractIds.size() < 1) {
        return null;
      }

      Opportunity opportunity = getReplacementOpportunity(amendContracts);
      SBQQ__Quote__c quote = getReplacementQuote(amendContracts, opportunity);

      // Querying the quote to get the name field for display
      quote = (quoteSelector.selectById(new Set<Id>{ quote.Id }, false))[0];
      CancelContractJobMsg_SL amendContractJob = new CancelContractJobMsg_SL();
      amendContractJob.opportunityId = opportunity.Id;
      amendContractJob.quoteId = quote.Id;
      amendContractJob.quoteName = quote.Name;

      Set<String> jobIds = new Set<String>();
      // we are not going to iterate over the last record.
      // We will do it independently so we can pass all of the job ids to the last job to check if all of the jobs
      // are complete and create quote line items
      Integer lastContractPosition = amendContracts.contractIds.size() - 1;
      for (Integer i = 0; i < lastContractPosition; i++) {
        String contractId = amendContracts.contractIds[i];
        Id jobId = System.enqueueJob(new CPQCreateCancellationQuote_SL(contractId, amendContracts.startDate, quote.Id));
        jobIds.add(jobId);
        amendContractJob.jobs.add(new CancelContractJobMsg_SL.JobStatus(contractId, jobId));
      }

      String contractId = amendContracts.contractIds[lastContractPosition];
      CPQCreateCancellationQuote_SL lastContract = new CPQCreateCancellationQuote_SL(
        contractId,
        amendContracts.startDate,
        quote.Id,
        true,
        jobIds
      );
      Id jobId = System.enqueueJob(lastContract);
      amendContractJob.jobs.add(new CancelContractJobMsg_SL.JobStatus(contractId, jobId));

      return amendContractJob;
    } catch (Exception e) {
      String error = e.getMessage() + ' ' + e.getStackTraceString();
      if (amendContracts.existingOpportunityId != null) {
        error = e.getMessage();
      }
      AuraHandledException ae = new AuraHandledException(error);
      ae.setMessage(error);
      throw ae;
    }
  }

  @AuraEnabled
  public static CancelContractJobMsg_SL amendContractsSerialise(CancelContractsMsg_SL amendContracts) {
    try {
      // GUARD CLAUSE: We only want to create a new contract and quote if we have passed in contracts
      if (amendContracts.contractIds == null || amendContracts.contractIds.size() < 1) {
        return null;
      }

      Opportunity opportunity = getReplacementOpportunity(amendContracts);
      SBQQ__Quote__c quote = getReplacementQuote(amendContracts, opportunity);

      // Querying the quote to get the name field for display
      quote = (quoteSelector.selectById(new Set<Id>{ quote.Id }, false))[0];
      CancelContractJobMsg_SL amendContractJob = new CancelContractJobMsg_SL();
      amendContractJob.opportunityId = opportunity.Id;
      amendContractJob.quoteId = quote.Id;
      amendContractJob.quoteName = quote.Name;

      createAsyncTasks(amendContracts, opportunity, quote);

      String contractId = amendContracts.contractIds.remove(0);
      List<String> queueContracts = new List<String>();
      if (amendContracts.contractIds.size() > 0) {
        queueContracts = amendContracts.contractIds;
      }
      Id jobId = System.enqueueJob(
        new CPQCreateCancellationQuoteSerial_SL(contractId, amendContracts.startDate, quote.Id, queueContracts)
      );

      return amendContractJob;
    } catch (Exception e) {
      String error = e.getMessage() + ' ' + e.getStackTraceString();
      if (amendContracts.existingOpportunityId != null) {
        error = e.getMessage();
      }
      AuraHandledException ae = new AuraHandledException(error);
      ae.setMessage(error);
      throw ae;
    }
  }

  private static Opportunity getReplacementOpportunity(CancelContractsMsg_SL amendContracts) {
    Opportunity opportunity;
    if (amendContracts.existingOpportunityId != null) {
      opportunity = [
        SELECT Id, CurrencyIsoCode, Name
        FROM Opportunity
        WHERE Id = :amendContracts.existingOpportunityId
        LIMIT 1
      ];
      existingReplacementOppValidation(amendContracts, opportunity);
      //mark selected existing replacement opp as a replacement record
      opportunity.Replacement_Transaction__c = true;
      //add RR prefix to name
      opportunity.Name = Constants_SL.OPPORTUNITY_NAME_RIP_REPLACE_PREFIX + opportunity.Name;
      update opportunity;
    } else {
      //Create The Replacement Opportunity
      opportunity = opportunitiesService.createOpportunity(
        amendContracts.accountId,
        amendContracts.opportunityName,
        amendContracts.opportunityStage,
        amendContracts.opportunityDealType,
        Date.valueOf(amendContracts.startDate),
        amendContracts.opportunityCurrency,
        amendContracts.soldToPartnerId,
        true
      );
      System.assert(opportunity.Pricebook2Id != null);
    }
    return opportunity;
  }

  private static SBQQ__Quote__c getReplacementQuote(CancelContractsMsg_SL amendContracts, Opportunity opportunity) {
    SBQQ__Quote__c quote;
    if (amendContracts.existingQuoteId != null) {
      quote = [
        SELECT Id, Name, SBQQ__StartDate__c, SBQQ__EndDate__c
        FROM SBQQ__Quote__c
        WHERE Id = :amendContracts.existingQuoteId
        LIMIT 1
      ];
      existingReplacementQuoteValidation(amendContracts, quote);

      // Cancellation quote job requires startDate
      amendContracts.startDate = quote.SBQQ__StartDate__c + '';
      amendContracts.endDate = quote.SBQQ__EndDate__c + '';
      update quote;
    } else {
      //Create The Replacement Quote
      quote = quotesService.createQuoteForOpportunity(
        Date.valueOf(amendContracts.startDate),
        Date.valueOf(amendContracts.endDate),
        opportunity.Id,
        true
      );
    }
    return quote;
  }

  private static void existingReplacementOppValidation(CancelContractsMsg_SL amendContracts, Opportunity opportunity) {
    List<Contract> contracts = [SELECT Id, CurrencyIsoCode FROM Contract WHERE Id = :amendContracts.contractIds];
    if (opportunity.CurrencyIsoCode != contracts[0].CurrencyIsoCode) {
      String error = 'Opportunity currency must match selected contracts currency';
      AuraHandledException ae = new AuraHandledException(error);
      ae.setMessage(error);
      throw ae;
    }
  }

  private static void existingReplacementQuoteValidation(CancelContractsMsg_SL amendContracts, SBQQ__Quote__c quote) {
    List<Contract> contracts = [SELECT Id, EndDate FROM Contract WHERE Id = :amendContracts.contractIds];
    for (Contract con : contracts) {
      if (quote.SBQQ__StartDate__c > con.EndDate) {
        String error = 'Replacement Start Date must be before all Cancellation Contract End Dates';
        AuraHandledException ae = new AuraHandledException(error);
        ae.setMessage(error);
        throw ae;
      }
      if (quote.SBQQ__EndDate__c < con.EndDate) {
        String error = 'Replacement End Date must be after all Cancelled Contract End Dates';
        AuraHandledException ae = new AuraHandledException(error);
        ae.setMessage(error);
        throw ae;
      }
    }
  }

  private static void createAsyncTasks(
    CancelContractsMsg_SL amendContracts,
    Opportunity replacementOpp,
    SBQQ__Quote__c replacementQuote
  ) {
    List<AsyncTask__c> taskList = new List<AsyncTask__c>();
    for (String conId : amendContracts.contractIds) {
      CPQCreateCancellationQuoteSerial_SL.TaskInputWrapper inputs = new CPQCreateCancellationQuoteSerial_SL.TaskInputWrapper(
        conId,
        amendContracts.startDate,
        replacementQuote.Id
      );
      AsyncTask__c prefilledTask = new AsyncTask__c(
        Account__c = amendContracts.accountId, // Account id
        Contract__c = conId, // Cancelling contract id
        Opportunity__c = replacementOpp.Id, // Replacement opp id
        Quote__c = replacementQuote.Id, // Replacement quote id
        Status__c = 'Inprogress'
      );
      AsyncTask__c newTask = AsyncTaskManager_TS.createTask(
        'RipReplace_Cancellation',
        JSON.serialize(inputs),
        prefilledTask,
        false
      );
      taskList.add(newTask);
    }
    insert taskList;
  }

  @AuraEnabled
  public static void retryJob(String asyncTaskId) {
    try {
      AsyncTaskManager_TS.startTask(asyncTaskId);
    } catch (Exception e) {
      String error = e.getMessage() + ' ' + e.getStackTraceString();
      AuraHandledException ae = new AuraHandledException(error);
      ae.setMessage(error);
      throw ae;
    }
  }

  /**
   * Initial data needed in Rip & Replace Modal
   */
  @AuraEnabled
  public static RipReplaceDataWrapper getRipReplaceData(List<String> contractIds) {
    RipReplaceDataWrapper wrapper = new RipReplaceDataWrapper();
    wrapper.stagePicklist = getOpportunityStageValues();
    wrapper.dealTypePicklist = getOpportunityDealTypeValues();
    wrapper.currencyPicklist = getOpportunityCurrencyValues();
    wrapper.warnings = new List<String>();
    wrapper.validations = new List<String>();

    Set<Id> accountIds = new Set<Id>();
    Set<String> primarySubsidiarySet = new Set<String>();

    List<Contract> contacts = [
      SELECT
        Id,
        AccountId,
        Deal_Type__c,
        Sold_to_Partner__c,
        SBQQ__OpportunityPricebookId__c,
        CurrencyIsoCode,
        Status,
        StartDate,
        EndDate,
        Account.Primary_Subsidiary__c
      FROM Contract
      WHERE Id IN :contractIds
    ];

    wrapper.contractRecords = contacts;
    wrapper.contractCurrency = contacts[0].CurrencyIsoCode;

    for (Contract con : contacts) {
      accountIds.add(con.AccountId);

      if (con.Account != null && con.Account.Primary_Subsidiary__c != null) {
        primarySubsidiarySet.add(con.Account.Primary_Subsidiary__c);
      }
    }

    // Expired validation
    for (Contract con : contacts) {
      if (con.Status == 'Expired') {
        wrapper.validations.add('Expired contracts can not be included');
        break;
      }
    }
    // Deal Type validation
    for (Contract con : contacts) {
      if (con.Deal_Type__c != contacts[0].Deal_Type__c) {
        wrapper.validations.add('Deal Type must match for all selected contracts');
        break;
      }
    }
    // Currency validation
    for (Contract con : contacts) {
      if (con.CurrencyIsoCode != contacts[0].CurrencyIsoCode) {
        wrapper.validations.add('Contract Currency must match for all selected contracts');
        break;
      }
    }
    // Sold to Partner warning
    for (Contract con : contacts) {
      if (con.Sold_to_Partner__c != contacts[0].Sold_to_Partner__c) {
        wrapper.warnings.add('End Customer / Sold to Partner must match for all selected contracts');
        break;
      }
    }
    // Pricebook warning
    for (Contract con : contacts) {
      if (con.SBQQ__OpportunityPricebookId__c != contacts[0].SBQQ__OpportunityPricebookId__c) {
        wrapper.warnings.add('Pricebook should match for all selected contracts');
        break;
      }
    }
    // Contracted Price warning
    List<SBQQ__ContractedPrice__c> cpList = [
      SELECT Id
      FROM SBQQ__ContractedPrice__c
      WHERE SBQQ__Account__c IN :accountIds AND (SBQQ__ExpirationDate__c >= TODAY OR SBQQ__ExpirationDate__c = NULL)
    ];
    if (cpList.size() > 0) {
      wrapper.warnings.add('Accounts related to selected contracts have active Contracted Prices');
    }

    if (!primarySubsidiarySet.isEmpty() && primarySubsidiarySet.size() > 1) {
      wrapper.validations.add(
        'The Contracting UiPath Legal Entity for all Customers must be the same for a Rip & Replace transaction. To proceed you must unselect any Contracts owned by Customers that are not aligned to the same UiPath Legal Entity.'
      );
    }

    // Premium Support Plus Products warning
    for (SBQQ__Subscription__c subscription : [
      SELECT Id, Name, SBQQ__Product__r.Family
      FROM SBQQ__Subscription__c
      WHERE SBQQ__Contract__c IN :contractIds AND SBQQ__Product__r.Family = 'Support'
    ]) {
      wrapper.warnings.add(
        'One or more of the selected Contracts includes Premium Support.You should check and update the pricing on both Cancellation & Replacement Quote Lines as required.'
      );
      break;
    }

    return wrapper;
  }

  @AuraEnabled(Cacheable=true)
  public static List<LookupSearchResult_SL> searchSoldToPartner(String searchTerm, List<String> selectedIds) {
    searchTerm += '*';

    List<List<SObject>> searchResults = [
      FIND :searchTerm
      IN ALL FIELDS
      RETURNING Account(Id, Name, BillingCountry WHERE id NOT IN :selectedIds)
      LIMIT 5
    ];

    List<LookupSearchResult_SL> results = new List<LookupSearchResult_SL>();
    String accountIcon = 'standard:account';
    Account[] accounts = (List<Account>) searchResults[0];
    for (Account account : accounts) {
      String subtitle = 'Account' + account.BillingCountry == null ? '' : ' • ' + account.BillingCountry;
      results.add(new LookupSearchResult_SL(account.Id, 'Account', accountIcon, account.Name, subtitle));
    }
    results.sort();
    return results;
  }

  @AuraEnabled
  public static List<LookupSearchResult_SL> searchOpportunity(
    String searchTerm,
    List<String> selectedIds,
    String accountId
  ) {
    if (searchTerm != null) {
      searchTerm += '*';
      List<List<SObject>> searchResults = [
        FIND :searchTerm
        IN ALL FIELDS
        RETURNING
          Opportunity(
            Id,
            Name,
            Account.Name
            WHERE
              SBQQ__RenewedContract__c = NULL
              AND SBQQ__AmendedContract__c = NULL
              AND IsClosed = FALSE
              AND Id NOT IN :selectedIds
              AND AccountId = :accountId)
        LIMIT 10
      ];

      List<LookupSearchResult_SL> results = new List<LookupSearchResult_SL>();
      String icon = 'standard:opportunity';
      Opportunity[] opps = (List<Opportunity>) searchResults[0];
      for (Opportunity opp : opps) {
        String subtitle = 'Account' + ' • ' + opp.Account.Name;
        results.add(new LookupSearchResult_SL(opp.Id, 'Opportunity', icon, opp.Name, subtitle));
      }
      results.sort();
      return results;
    } else {
      List<LookupSearchResult_SL> results = new List<LookupSearchResult_SL>();
      String icon = 'standard:opportunity';
      for (Opportunity opp : [
        SELECT Id, Name, Account.Name
        FROM Opportunity
        WHERE
          SBQQ__RenewedContract__c = NULL
          AND SBQQ__AmendedContract__c = NULL
          AND IsClosed = FALSE
          AND Id NOT IN :selectedIds
          AND AccountId = :accountId
        LIMIT 10
      ]) {
        String subtitle = 'Account' + ' • ' + opp.Account.Name;
        results.add(new LookupSearchResult_SL(opp.Id, 'Opportunity', icon, opp.Name, subtitle));
      }
      results.sort();
      return results;
    }
  }

  @AuraEnabled
  public static List<LookupSearchResult_SL> searchQuote(String searchTerm, List<String> selectedIds, String oppId) {
    if (searchTerm != null) {
      searchTerm += '*';
      List<List<SObject>> searchResults = [
        FIND :searchTerm
        IN ALL FIELDS
        RETURNING
          SBQQ__Quote__c(
            Id,
            Name,
            SBQQ__NetAmount__c,
            CurrencyIsoCode
            WHERE Id NOT IN :selectedIds AND SBQQ__Opportunity2__c != NULL AND SBQQ__Opportunity2__c = :oppId)
        LIMIT 10
      ];

      List<LookupSearchResult_SL> results = new List<LookupSearchResult_SL>();
      String icon = 'custom:custom93';
      SBQQ__Quote__c[] quotes = (List<SBQQ__Quote__c>) searchResults[0];
      for (SBQQ__Quote__c quote : quotes) {
        String subtitle = 'Net Amount' + ' • ' + quote.CurrencyIsoCode + ' ' + quote.SBQQ__NetAmount__c;
        results.add(new LookupSearchResult_SL(quote.Id, 'Quote', icon, quote.Name, subtitle));
      }
      results.sort();
      return results;
    } else {
      List<LookupSearchResult_SL> results = new List<LookupSearchResult_SL>();
      String icon = 'custom:custom93';
      for (SBQQ__Quote__c quote : [
        SELECT Id, Name, SBQQ__NetAmount__c, CurrencyIsoCode
        FROM SBQQ__Quote__c
        WHERE Id NOT IN :selectedIds AND SBQQ__Opportunity2__c != NULL AND SBQQ__Opportunity2__c = :oppId
        LIMIT 10
      ]) {
        String subtitle = 'Net Amount' + ' • ' + quote.CurrencyIsoCode + ' ' + quote.SBQQ__NetAmount__c;
        results.add(new LookupSearchResult_SL(quote.Id, 'Quote', icon, quote.Name, subtitle));
      }
      results.sort();
      return results;
    }
  }

  public static List<PicklistMsg_CM> getOpportunityStageValues() {
    try {
      return opportunitiesService.getStageNamePicklistValues();
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static List<PicklistMsg_CM> getOpportunityDealTypeValues() {
    try {
      return opportunitiesService.getDealTypePicklistValues();
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static List<PicklistMsg_CM> getOpportunityCurrencyValues() {
    try {
      return opportunitiesService.getCurrencyPicklistValues();
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static List<ApexJobStatusMsg_CM> getJobStatus(List<String> jobIds) {
    try {
      return ApexJobSelector_CM.getJobStatusById(jobIds);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static Id getAccountOwnerId(Id accountId) {
    return [SELECT OwnerId FROM Account WHERE Id = :accountId].OwnerId;
  }

  public class RipReplaceDataWrapper {
    @AuraEnabled
    public List<PicklistMsg_CM> stagePicklist { get; set; }
    @AuraEnabled
    public List<PicklistMsg_CM> dealTypePicklist { get; set; }
    @AuraEnabled
    public List<PicklistMsg_CM> currencyPicklist { get; set; }
    @AuraEnabled
    public List<String> warnings { get; set; }
    @AuraEnabled
    public List<String> validations { get; set; }
    @AuraEnabled
    public String contractCurrency { get; set; }
    @AuraEnabled
    public List<Contract> contractRecords { get; set; }
  }
}