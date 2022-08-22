public without sharing class CPQModel_Product_SL {
  /**
   * The record that this product model represents.
   */
  public Product2 record { get; private set; }
  /**
   * Provides a source for SBQQ__QuoteLine__c.SBQQ__UpgradedAsset__c
   */
  public Id upgradedAssetId { get; set; }
  /**
   * The symbol for the currency in use
   */
  public String currencySymbol { get; private set; }
  /**
   * The ISO code for the currency in use
   */
  public String currencyCode { get; private set; }
  /**
   * Allows for Product Features to be sorted by category
   */
  public String[] featureCategories { get; private set; }
  /**
   * A list of all available options on this product
   */
  public CPQModel_Option_SL[] options { get; private set; }
  /**
   * All features present on this product
   */
  public CPQModel_Feature_SL[] features { get; private set; }
  /**
   * An object representing this product's current configuration
   */
  public CPQModel_Configuration_SL configuration { get; private set; }
  /**
   * A list of all configuration attributes available on this product
   */
  public CPQModel_ConfigAttribute_SL[] configurationAttributes { get; private set; }
  /**
   * A list of all configuration attributes this product inherits from ancestor products
   */
  public CPQModel_ConfigAttribute_SL[] inheritedConfigurationAttributes { get; private set; }
  /**
   * Constraints on this product
   */
  public CPQModel_Constraint_SL[] constraints;
}