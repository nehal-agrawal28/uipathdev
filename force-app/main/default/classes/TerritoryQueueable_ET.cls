/**
 * @AUTHOR: UIPath
 * @DATE: 03/24/2022
 * @DESCRIPTION: Territory Queueable for ETM project.
 * This queueable class reset the Territory2.Recalculate_Compensation__c flag which is executed after TerritoryAccountOwnerSyncBatch finishes.
 */
public with sharing class TerritoryQueueable_ET extends AbstractQueueable {
  private final Set<Id> setOfTerritory2Ids;
  private final Boolean recalculateCompensationFlag;

  public TerritoryQueueable_ET(Set<Id> setOfTerritory2Ids, Boolean recalculateCompensationFlag) {
    super('TerritoryQueueable_ET');
    this.setOfTerritory2Ids = setOfTerritory2Ids;
    this.recalculateCompensationFlag = recalculateCompensationFlag;
  }

  public override void work() {
    List<Territory2> listOfTerritoryToUpdate = new List<Territory2>();
    Territory2sSelector_ET territorySelector = (Territory2sSelector_ET) Application_ET.Selector.newInstance(
      Territory2.SObjectType
    );
    try {
      for (Territory2 terr : territorySelector.selectById(setOfTerritory2Ids)) {
        if (terr.Recalculate_Compensation__c != recalculateCompensationFlag) {
          listOfTerritoryToUpdate.add(
            new Territory2(Id = terr.Id, Recalculate_Compensation__c = recalculateCompensationFlag)
          );
        }
      }
      List<Database.SaveResult> result = Database.update(listOfTerritoryToUpdate, false);
      Logger.debug(new LogMessage('Updated Territory2 Result', ''), result);
    } catch (Exception ex) {
      Logger.debug(new LogMessage('Territory:resetFlag Update failed', ex.getLineNumber() + ex.getMessage()));
    } finally {
      logger.saveLog();
    }
  }
}