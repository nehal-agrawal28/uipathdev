public without sharing class PartnerInvolvementMetadata_SL {
  //Sales Roles
  public static final String INFLUENCE_PARTNER_ROLE = 'Influence (No Financial Comp from UiPath)';
  public static final String SOLD_TO_PARTNER_ROLE = 'Sold to Partner (Buying Directly from UiPath)';
  public static final String TIER_2_PARTNER_ROLE = 'Tier 2 Partner (Buying from Sold to Partner)';
  public static final String TIER_3_PARTNER_ROLE = 'Tier 3 Partner (Buying from Tier 2 Partner)';
  public static final String CO_SELL_PARTNER_ROLE = 'Co-sell (Tech Alliance Partners)';

  //Partner Names
  public static final String MICROSOFT_CORP_TECH_ALLIANCE = 'Microsoft Corporation (Technology Alliance)';

  //Delivery Roles
  public static final String PRIMARY_IMPLEMENTATION = 'Primary Implementation';

  public static final String INFLUENCE_APPROVAL_STATUS = 'approve';

  //Error Messages
  public static final String DUPLICATE_SOURCE_MESSAGE = 'There is another sourced partner involvement for this opportunity.';
  public static final String DUPLICATE_SOLD_TO_MESSAGE = 'You cannot have more than one Sold To Partners.';
  public static final String DUPLICATE_PRIMARY_INFLUENCE = 'There is already another primary influence partner for this opportunity';
  public static final String CANNOT_DELETE_MESSAGE = 'You cannot delete a partner involvement record for a locked opportunity. Please reach out to Compensation.';

  public static List<Id> ProfilesAllowedToDelete {
    get {
      if (ProfilesAllowedToDelete == null) {
        ProfilesAllowedToDelete = Collection.of(
            [
              SELECT Id
              FROM Profile
              WHERE
                Name IN (
                  :CommonsConstants.SYS_ADMIN_PROFILE,
                  :CommonsConstants.SUPER_ADMIN_PROFILE,
                  :CommonsConstants.DATA_STEWARD_PROFILE
                )
            ]
          )
          .pluckIds();
      }
      return ProfilesAllowedToDelete;
    }
    set;
  }
}