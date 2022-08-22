/**
 * @AUTHOR: UIPath
 * @DATE: 01/10/2021
 * @DESCRIPTION: Account Queueable for ETM project.
 * 1. Populate Territory Postal Code Mapping Lookup on Account.
 */
public with sharing class AccountQueueable_ET extends AbstractQueueable {
  private final List<SObject> accountsLst;
  private final Map<Id, SObject> oldAccountMap;

  public AccountQueueable_ET(List<SObject> accountsLst, Map<Id, SObject> oldAccountMap) {
    super('AccountQueueable_ET');
    this.accountsLst = accountsLst;
    this.oldAccountMap = oldAccountMap;
  }

  public override void work() {
    AccountsService_ET service = (AccountsService_ET) Application_ET.Service.newInstance(AccountsService_ET.class);

    Set<Id> exceptionAccIds = service.populateCSMTerritory(accountsLst);

    AccountsSelector_ET accountSelector = (AccountsSelector_ET) Application_ET.Selector.newInstance(
      Account.SObjectType
    );
    ETMSystemNotificationService etmSystem = new ETMSystemNotificationService();
    etmSystem.accountCSMTerritoryException(accountSelector.selectById(exceptionAccIds));
  }
}