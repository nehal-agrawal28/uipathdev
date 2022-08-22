/**
 * Process contracts to set status
 */
public with sharing class ContractActivationFunction_SL implements SObjectToSObjectFunction {
  private static final String STATUS_DRAFT = 'Draft';
  private static final String STATUS_ACTIVATED = 'Activated';

  public SObject apply(Contract con) {
    con.Status = STATUS_ACTIVATED;
    return con;
  }

  public SObject apply(SObject record) {
    return apply((Contract) record);
  }

  /**
   * @description   Set contract status to Activated
   *                SF does not allow activated status on before insert
   * @param records list of new contracts
   */
  public static void setStatusToActivated(List<SObject> records) {
    Collection.of(records)
      .mapSome(Match.field(Contract.Status).equals(STATUS_DRAFT), new ContractActivationFunction_SL())
      .asList();
  }
}