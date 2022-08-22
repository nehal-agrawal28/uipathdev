public interface IContractsService_SL {
  List<CPQContractMsg_SL> getActiveContractsByAccount(List<String> accountIds, String amountOfRecords);
}