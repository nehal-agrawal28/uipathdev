/**
 *  @author Girish Lakshmanan
 * @description CPQ search plugin to allow for more flexible CPQ QLE Prod search based on Quote context
 */
global without sharing class CPQSearchPluginUniPrice implements SBQQ.ProductSearchPlugin {
  final static String DEAL_HUB_USER_PERM_NAME = 'Deal_Hub_User';
  final static String OPP_TYPE_NEW_BUSINESS = 'New Business';
  @TestVisible
  final static Map<String, String> GTM_STRUCTURES = new Map<String, String>{
    'Flex' => 'Flex',
    'GPS' => 'GPS',
    'NPS' => 'NPS',
    'OPS' => 'OPS'
  };
  final static Map<String, List<String>> GTM_STRUCTURE_BY_OPP_TYPE_AND_USER = new Map<String, List<String>>{
    'Standard-NewBusiness' => new List<String>{ GTM_STRUCTURES.get('Flex'), GTM_STRUCTURES.get('GPS') },
    'Standard-UpsellRenewal' => new List<String>{ GTM_STRUCTURES.get('Flex'), GTM_STRUCTURES.get('GPS') },
    'Enhanced-NewBusiness' => new List<String>{
      GTM_STRUCTURES.get('Flex'),
      GTM_STRUCTURES.get('GPS'),
      GTM_STRUCTURES.get('NPS')
    },
    'Enhanced-UpsellRenewal' => new List<String>{
      GTM_STRUCTURES.get('Flex'),
      GTM_STRUCTURES.get('GPS'),
      GTM_STRUCTURES.get('NPS'),
      GTM_STRUCTURES.get('OPS')
    }
  };
  final static Set<String> GMT_STRUCTURES_ENABLED_FOR_NEW_BUSINESS = new Set<String>{
    GTM_STRUCTURES.get('Flex'),
    GTM_STRUCTURES.get('GPS'),
    GTM_STRUCTURES.get('NPS')
  };
  final static Set<String> GMT_STRUCTURES_DISABLED_FOR_NEW_BUSINESS = new Set<String>{ GTM_STRUCTURES.get('OPS') };

  final static List<Schema.SObjectField> REGISTER_FIELD_REFS = new List<Schema.SObjectField>{
    Product2.GTM_Structure__c,
    //Product2.Visibility_Permission__c, - not packaged
    Product2.Zones__c,
    Product2.Countries__c
  };
  private static QuotesSelector_SL selector {
    get {
      return (QuotesSelector_SL) Application_SL.Selector.newInstance(SBQQ__Quote__c.SObjectType);
    }
    set;
  }

  global CPQSearchPluginUniPrice() {
  }

  /**
   *
   *
   * @param quote model of current Quote
   * @param fieldValuesMap search Criteria name value pairs
   *
   * @return WHERE clause with additional search criteria - please be careful with the brackets!!!
   */
  global String getAdditionalSearchFilters(SObject quote, Map<String, Object> fieldValuesMap) {
    String whereClause = '';
    String countryFilter = null;
    String zonalFilter = null;
    String permissionFilter = null;
    Set<Id> customPermissionIds = new Set<Id>();
    Set<String> customPermissions = new Set<String>();
    Boolean enhancedUser = false;
    Boolean oppNewBusinessContext = true;

    //Query the quote
    SBQQ__Quote__c quoteModel = selector.getQuotesWithBillToAccount(new Set<Id>{ quote.Id }).get(0);

    // Custom permission filter
    for (SetupEntityAccess entity : [
      SELECT SetupEntityId
      FROM SetupEntityAccess
      WHERE
        SetupEntityType = 'CustomPermission'
        AND ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId())
    ]) {
      // SetupEntityId is a polymorphic lookup
      customPermissionIds.add(entity.SetupEntityId);
    }
    for (CustomPermission cp : [SELECT DeveloperName FROM CustomPermission WHERE Id IN :customPermissionIds]) {
      customPermissions.add(cp.DeveloperName);
    }

    //Determine user context
    enhancedUser = getEnhancedUserContext(customPermissions);

    //Determine opp context
    oppNewBusinessContext = getOppNewBusinessContext(quoteModel.SBQQ__Opportunity2__r.Type);

    // prettier-ignore
    permissionFilter = 
            '(Product2.Visibility_Permission__c IN ( \'' +  String.join(new List<String>(customPermissions), '\',\'') + '\' )';
    //remove any specifcally disabled GTM Structures for enhanced users in a new biz context
    if (enhancedUser && oppNewBusinessContext) {
      permissionFilter +=
        ' AND Product2.GTM_Structure__c NOT IN ( \'' +
        String.join(new List<String>(GMT_STRUCTURES_DISABLED_FOR_NEW_BUSINESS), '\',\'') +
        '\' )';
    }
    permissionFilter += ' )';

    //Build product sub-catalog for given context (user + quote + account active products)
    Set<String> productSubCatalog = getProductSubCatalog(
      oppNewBusinessContext,
      enhancedUser,
      quoteModel.SBQQ__Account__c
    );

    //Build filter string
    String subCatalogFilter =
      ' (Product2.GTM_Structure__c IN ( \'' +
      String.join(new List<String>(productSubCatalog), '\',\'') +
      '\' ) AND Product2.Visibility_Permission__c = NULL)';
    //

    // Zone and Country filter
    String country = quoteModel.Bill_To_Account__r.BillingCountry;
    List<Country__c> countries = [SELECT zone__c FROM Country__c WHERE Country_Name__c = :country LIMIT 1];

    //Use Country to Query Custom metadata and pull the zone out
    if (countries.isEmpty() || countries.get(0).zone__c == null) {
      whereClause = ' (' + permissionFilter + ' OR ' + subCatalogFilter + ' )';
      return whereClause;
    }

    String currentZone = countries.get(0).zone__c;
    zonalFilter = ' ((Product2.Zones__c = \'' + currentZone + '\') OR (Product2.Zones__c = null))';
    countryFilter = ' ((Product2.Countries__c includes ( \'' + country + '\')) OR (Product2.Countries__c = null))';

    whereClause =
      ' (' +
      ' (' +
      permissionFilter +
      ' OR ' +
      subCatalogFilter +
      ' ) AND ' +
      '( ' +
      zonalFilter +
      ' AND ' +
      countryFilter +
      ' ) ) ';

    return whereClause;
  }

  global String getAdditionalSuggestFilters(SObject so, Map<String, Object> ma) {
    return null;
  }

  global String getFilterDefaultValue(SObject so, String st) {
    return null;
  }

  global String getInputDefaultValue(SObject so, String st) {
    return null;
  }

  global Boolean isFilterHidden(SObject so, String st) {
    return false;
  }

  global Boolean isInputHidden(SObject so, String st) {
    return false;
  }

  global Boolean isSearchCustom(SObject so, Map<String, Object> ma) {
    return false;
  }

  global Boolean isSuggestCustom(SObject so, Map<String, Object> ma) {
    return false;
  }

  global List<PricebookEntry> search(SObject quote, Map<String, Object> ma) {
    return null;
  }

  global List<PricebookEntry> suggest(SObject so, Map<String, Object> ma) {
    return null;
  }

  /**
   * For a given context, determine the default Product GTM Structures to offer
   *
   * @param oppNewBusinessContext the new business context of the quote/account
   * @param enhancedUser the running user context
   *
   * @return default product catalog
   */
  @TestVisible
  private static Set<String> getEnabledProductCatalog(Boolean newBusinessContext, Boolean enhancedUser) {
    Set<String> enabledProductCatalog = new Set<String>();

    if (enhancedUser) {
      if (newBusinessContext) {
        enabledProductCatalog.addAll(GTM_STRUCTURE_BY_OPP_TYPE_AND_USER.get('Enhanced-NewBusiness'));
      } else {
        enabledProductCatalog.addAll(GTM_STRUCTURE_BY_OPP_TYPE_AND_USER.get('Enhanced-UpsellRenewal'));
      }
    } else {
      if (newBusinessContext) {
        enabledProductCatalog.addAll(GTM_STRUCTURE_BY_OPP_TYPE_AND_USER.get('Standard-NewBusiness'));
      } else {
        enabledProductCatalog.addAll(GTM_STRUCTURE_BY_OPP_TYPE_AND_USER.get('Standard-UpsellRenewal'));
      }
    }

    return enabledProductCatalog;
  }

  /**
   * For a given context, determine if the running user has enhanced access
   *
   * @param customPermissions assigned permissions for the running user
   *
   * @return whether running user context is enhanced
   */
  @TestVisible
  private static Boolean getEnhancedUserContext(Set<String> customPermissions) {
    return customPermissions.contains(DEAL_HUB_USER_PERM_NAME);
  }

  /**
   * For a given context, determine if the hnadling should be new business
   *
   * @param oppType SBQQ__Quote__c.SBQQ__Opportunity2__r.Type
   *
   * @return whether opp context is new business
   */
  @TestVisible
  private static Boolean getOppNewBusinessContext(String oppType) {
    //default into new business
    Boolean isNewBusiness = true;
    if (
      !String.isEmpty(oppType) &&
      (oppType.equals(Constants_SL.OPPORTUNITY_TYPE_UPSELL) || oppType.equals(Constants_SL.OPPORTUNITY_TYPE_RENEWAL))
    ) {
      isNewBusiness = false;
    }
    return isNewBusiness;
  }

  /**
   * For a given context, determine the Product GTM Structures to offer
   *
   * @param oppNewBusinessContext the new business context of the quote/account
   * @param enhancedUser the running user context
   * @param accId quote.SBQQ__Account__c
   *
   * @return default product GTM Structures
   */
  @TestVisible
  private static Set<String> getProductSubCatalog(Boolean oppNewBusinessContext, Boolean enhancedUser, Id accId) {
    //base catalog - user and quote context
    Set<String> productSubCatalog = new Set<String>(getEnabledProductCatalog(oppNewBusinessContext, enhancedUser));
    //additional catalog - user, quote, and account context
    if (!oppNewBusinessContext && !enhancedUser) {
      productSubCatalog.addAll(getAdditionalGtms(accId));
    }
    return productSubCatalog;
  }

  /**
   *
   * Add additional relevant GMT Structures to the default product catalog for a given quote/account context
   *
   * @param accId SBQQ__Quote__c.SBQQ__Account__c
   *
   * @return additional GTM to be added to the default product catalog
   */
  @TestVisible
  private static Set<String> getAdditionalGtms(Id accId) {
    //Get current product GTM Enablement from active contracts
    Set<String> activeProductGtms = getGtmProductEnablement(accId);

    //add additional GTMs that need to be enabled for the given context
    Set<String> additionalGtmsToEnable = new Set<String>();
    if (activeProductGtms.contains(GTM_STRUCTURES.get('NPS'))) {
      additionalGtmsToEnable.add(GTM_STRUCTURES.get('NPS'));
    }

    return additionalGtmsToEnable;
  }

  /**
   * For a given Account returns the active Product GTM Stuctures
   *
   * @param accId SBQQ__Quote__c.SBQQ__Account__c
   *
   * @return active GTM Structures under this account
   */
  @TestVisible
  private static Set<String> getGtmProductEnablement(Id accId) {
    List<AggregateResult> agr = [
      SELECT GTM_Structure__c, COUNT(Id)
      FROM Product2
      WHERE
        Id IN (
          SELECT SBQQ__Product__c
          FROM SBQQ__Subscription__c
          WHERE SBQQ__Account__c = :accId AND SBQQ__Contract__r.Status = 'Activated'
        )
      GROUP BY GTM_Structure__c
    ];
    Set<String> activeProductGtms = new Set<String>();
    for (AggregateResult ar : agr) {
      activeProductGtms.add((String) ar.get(String.valueOf(Product2.GTM_Structure__c)));
    }

    return activeProductGtms;
  }
}