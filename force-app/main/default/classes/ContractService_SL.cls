public with sharing class ContractService_SL implements IContractsService_SL {
  private ContractsSelector_SL contractsSelectorSL {
    get {
      return (ContractsSelector_SL) Application_SL.Selector.newInstance(Contract.SObjectType);
    }
    set;
  }

  /**
   * Takes an account Id and queries contracts that are linked to them. Then converts the data to a message class to pass back
   *
   * @param  accountIds  the accounts that the contracts are related to
   * @param  amountOfRecords  String that could say 'All' or be a numeric value. if it's numeric it will return only that amount
   * @return List<AmendmentContractMsg> a list of all amendment contracts linked to an account
   */
  public List<CPQContractMsg_SL> getActiveContractsByAccount(List<String> accountIds, String amountOfRecords) {
    List<Contract> contracts = contractsSelectorSL.getActiveContractsByAccount(accountIds, amountOfRecords);

    List<CPQContractMsg_SL> contractMsgs = new List<CPQContractMsg_SL>();

    for (Contract contract : contracts) {
      CPQContractMsg_SL contractMsg = new CPQContractMsg_SL();
      contractMsg.id = contract.Id;
      contractMsg.accountName = contract.Account.Name;
      contractMsg.contractNumber = contract.ContractNumber;
      contractMsg.startDate = contract.StartDate;
      contractMsg.endDate = contract.EndDate;
      contractMsg.terminationDate = Date.today();
      contractMsg.terminate = false;
      contractMsg.contractTerm = contract.contractTerm;
      contractMsgs.add(contractMsg);
    }
    return contractMsgs;
  }
}