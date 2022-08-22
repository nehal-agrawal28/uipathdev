public interface IContractRenewalService_SL {
  void performUpliftCalculations(Set<Id> contractIds);
  IContractRenewalService_SL optInToUplift();
  IContractRenewalService_SL optOutToUplift();
  IContractRenewalService_SL bypassThresholdValidation();
}