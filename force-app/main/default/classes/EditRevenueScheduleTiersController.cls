/**
 * --
 * @date 23/03/2019
 * @description Controller class for the EditRevenueScheduleTiers visualforce page. Used to add validated Revenue Tiers in a user friendly way
 */

public class EditRevenueScheduleTiersController {
  public Integer newTierIdx { get; set; }
  public ScheduleModel scheduleModel { get; set; }
  public Boolean initialized { get; set; }

  // A external Id field is used on the Tier object to provide a consistent mechanism to allow using hashmaps for both saved and new records.
  // This pointer to the External Id is sent by the page to tell the controller
  // which Tier the user intends to delete or insert a Tier after(Plus minus buttons on page).
  public String targetExtId { get; set; }

  public EditRevenueScheduleTiersController(ApexPages.standardController std) {
    //This Index var points to the currently Active Tier the user is currently adding but not yet saved.
    //Tracking this is necessary because new Tiers can also be inserted arbitrarily between 2 existing Tiers
    newTierIdx = 0;

    scheduleModel = new ScheduleModel(
      [
        SELECT
          Id,
          Name,
          CurrencyIsoCode,
          (
            SELECT
              Id,
              Name,
              Discount__c,
              UpperBound__c,
              LowerBound__c,
              DiscountAmount__c,
              Number__c,
              Ext_Id__c,
              CurrencyIsoCode
            FROM RevenueTiers__r
            ORDER BY Number__c, LowerBound__c ASC
          )
        FROM Revenue_Discount_Schedule__c
        WHERE Id = :std.getRecord().Id
      ]
    );

    addBlankFirstTier();

    initialized = true;
  }

  /**
   * Adds a blank first Tier when there are no Tiers in the schedule and the user visits the Tiers VF page for adding Tiers.
   */
  private void addBlankFirstTier() {
    if (scheduleModel.tiersModel.combinedTiers.size() == 0) {
      targetExtId = 'NEW-' + generateRandomString(14);
      onAddTier();
    }
  }

  /**
   *
   * Handler method when the user Saves the Page
   * @return PageReference to the Revenue Schedule page
   */
  public PageReference onSave() {
    update scheduleModel.tiersModel.existingTiers;
    delete scheduleModel.tiersModel.deletedTiers;
    removeNewKeyPrefix();
    insert scheduleModel.tiersModel.newTiers;

    return new PageReference('/' + scheduleModel.schedule.Id);
  }

  private void removeNewKeyPrefix() {
    for (Revenue_DiscountTier__c tier : scheduleModel.tiersModel.newTiers) {
      tier.Ext_Id__c = tier.Ext_Id__c.replace('NEW-', '');
    }
  }

  /**
   *
   * Handler method when the user clicks the Cancel button on the Page
   * @return PageReference to the Revenue Schedule page
   */
  public PageReference onCancel() {
    return new PageReference('/' + scheduleModel.schedule.Id);
  }

  /**
   * rudimentary Unique String generator. Given the low number of Tiers under a Schedule, collisions are unlikely
   */
  private static String generateRandomString(Integer len) {
    final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
    String randStr = '';
    while (randStr.length() < len) {
      Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
      randStr += chars.substring(idx, idx + 1);
    }
    return randStr;
  }

  /**
   * Handler method when the Add button is clicked on the Tier grid
   */
  public void onAddTier() {
    Revenue_DiscountTier__c tier = createBlankDiscountTier();

    tier.Ext_Id__c = 'NEW-' + generateRandomString(14);
    scheduleModel.tiersModel.newTiers.add(tier);

    newTierIdx = findIndexFromExtId(targetExtId);
    tier.Number__c = newTierIdx + 1;

    //If last Tier dont insert, append instead
    if (newTierIdx < getCombinedTiers().size()) {
      getCombinedTiers().add(newTierIdx, tier);
    } else {
      getCombinedTiers().add(tier);
    }
    reOrderSequenceNumber();
  }

  private Revenue_DiscountTier__c createBlankDiscountTier() {
    return new Revenue_DiscountTier__c(
      Name = '',
      Revenue_Discount_Schedule__c = scheduleModel.schedule.Id,
      CurrencyIsoCode = scheduleModel.schedule.CurrencyIsoCode
    );
  }

  private Integer findIndexFromExtId(String extId) {
    Map<String, Revenue_DiscountTier__c> tierMap = getMapofCombinedTiers();

    return getCombinedTiers().indexOf(tierMap.get(extId)) + 1;
  }

  private List<Revenue_DiscountTier__c> getCombinedTiers() {
    return scheduleModel.tiersModel.combinedTiers;
  }

  private Map<String, Revenue_DiscountTier__c> getMapofCombinedTiers() {
    Map<String, Revenue_DiscountTier__c> tierMap = new Map<String, Revenue_DiscountTier__c>();
    for (Revenue_DiscountTier__c tier : getCombinedTiers()) {
      tierMap.put(tier.Ext_Id__c, tier);
    }
    return tierMap;
  }

  /**
   *
   *
   * @return Currently Active Tier where the Cursor is placed
   */
  public Revenue_DiscountTier__c getActiveTier() {
    return scheduleModel.tiersModel.combinedTiers[newTierIdx];
  }

  /**
   * Handler method when the Add button is clicked on the Tier grid
   */
  public void onRemoveTier() {
    Map<String, Revenue_DiscountTier__c> tierMap = getMapofCombinedTiers();
    removeTierFromCombinedTiersCollection(tierMap);

    if ((String.valueOf(targetExtId).startsWith('NEW'))) {
      addTierToNewTiersCollection(tierMap);
    } else {
      removeTierFromExistinTiersCollection(tierMap);
      addTierToDeletedTiersCollection(tierMap);
    }
    reOrderSequenceNumber();
  }

  private void removeTierFromCombinedTiersCollection(Map<String, Revenue_DiscountTier__c> tierMap) {
    getCombinedTiers().remove(getCombinedTiers().indexOf(tierMap.get(targetExtId)));
  }

  private void addTierToNewTiersCollection(Map<String, Revenue_DiscountTier__c> tierMap) {
    scheduleModel.tiersModel.newTiers.remove(scheduleModel.tiersModel.newTiers.indexOf(tierMap.get(targetExtId)));
  }

  private void addTierToDeletedTiersCollection(Map<String, Revenue_DiscountTier__c> tierMap) {
    scheduleModel.tiersModel.deletedTiers.add(tierMap.get(targetExtId));
  }

  private void removeTierFromExistinTiersCollection(Map<String, Revenue_DiscountTier__c> tierMap) {
    scheduleModel.tiersModel.existingTiers.remove(
      scheduleModel.tiersModel.existingTiers.indexOf(tierMap.get(targetExtId))
    );
  }

  //Reorder sequence numbers on the Tier collection
  private void reOrderSequenceNumber() {
    Integer index = 1;
    for (Revenue_DiscountTier__c tier : getCombinedTiers()) {
      tier.Number__c = index++;
    }
  }

  /**
   * Represents a Revenue Discount Schedule Model
   */
  public class ScheduleModel {
    public Revenue_Discount_Schedule__c schedule { get; set; }
    public Boolean discountUnitAmount {
      get {
        return false;
      }
      set;
    }

    /**
     * Only support Percentage Discounts for now. Discounts as amounts need to support Pivoting by Currencies and is more complex to implement
     */
    public Boolean discountUnitPercent {
      get {
        return true;
      }
      set;
    }

    public TiersModel tiersModel { get; set; }

    public ScheduleModel(Revenue_Discount_Schedule__c sch) {
      schedule = sch;
      tiersModel = new TiersModel(schedule);
    }
  }

  /**
   * Represents a collection of Tiers under a given schedule
   */
  public class TiersModel {
    public List<Revenue_DiscountTier__c> existingTiers { get; set; }
    public List<Revenue_DiscountTier__c> newTiers { get; set; }
    public List<Revenue_DiscountTier__c> deletedTiers { get; set; }
    public List<Revenue_DiscountTier__c> combinedTiers { get; set; }

    public List<String> columnHeadings { get; set; }
    public Boolean emptyTiers { set; }
    public Integer tierCount { set; }

    public TiersModel(Revenue_Discount_Schedule__c schedule) {
      existingTiers = schedule.RevenueTiers__r;
      newTiers = new List<Revenue_DiscountTier__c>();
      deletedTiers = new List<Revenue_DiscountTier__c>();

      combinedTiers = new List<Revenue_DiscountTier__c>();
      combinedTiers.addAll(existingTiers);
      combinedTiers.addAll(newTiers);
    }

    public Boolean getEmptyTiers() {
      return existingTiers.size() < 1;
    }

    public Integer getTierCount() {
      return existingTiers.size();
    }

    /**
     * Currently unused - to be used for Pivoting Discount amounts by currency
     *
     * @return
     */
    public List<String> getColumnHeadings() {
      return new List<String>{ 'USD', 'GBP', 'EUR' };
    }
  }
}