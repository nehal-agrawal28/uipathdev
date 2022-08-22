/**
 * @AUTHOR: UIPath
 * @DATE: 07/09/2021
 * @DESCRIPTION: This class has constants for ETM Project
 */
public with sharing class ETMConstant {
  // Territory Role
  public static final String PRIMARY_ACCOUNT_MANAGER = 'Primary Account Manager';
  public static final String INTERIM_ACCOUNT_MANAGER = 'Interim Account Manager';
  public static final String INTERIM_ACCOUNT_MANAGERS = 'Interim Account Manager,Interim - Sales Manager';
  public static final String INTERIM_SALES_MANAGER = 'Interim - Sales Manager';
  public static final String CUSTOMER_SUCCESS_MANAGER = 'Customer Success Manager';
  public static final String CUSTOMER_SUCCESS_DIRECTOR = 'Customer Success Director';
  public static final String ENTERPRISE_DEVELOPMENT_REP = 'Enterprise Development Rep';
  public static final String PRIMARY_TEMPORARY_ABSENCE = 'Primary - Temporary Absence';
  public static final String SALES_DEVELOPMENT_REP = 'Sales Development Rep';
  public static final String GSI_PARTNER_MANAGER = 'GSI Partner Manager';
  public static final String GEO_LEADER = 'Geo Leader';
  public static final String AREA_VP = 'Area VP';
  public static final String REGION_VP = 'Region VP';
  public static final String VACANT_TERRITORY_COMP_USER = 'Vacant Territory Compensation User';
  public static final String ULTIMATE_PRIMARY_PARENT = 'Ultimate Parent Primary';
  public static final String REGION_PARTNER_MANAGER = 'Region Partner Manager';
  public static final String JAPAN_REGION_PARTNER_MANAGER = 'Japan Region Partner Manager';
  public static final String STRATEGIC_PARTNER_MANAGER = 'Strategic Partner Manager';
  public static final String GLOBAL_GSI_ALLI_PART_MANAGER = 'Global GSI Alliances Partner Manager';
  public static final String DISTRIBUTION_PARTNER_MANAGER = 'Distribution Partner Manager';
  public static final String SEC_GSI_PARTNER_MANAGER = 'Secondary GSI Partner Manager';
  public static final String GLOBAL_GSI_PARTNER_MANAGER = 'Global GSI Partner Manager';
  public static final String GSI_WITH_SECONDARY_MANAGER = 'GSI Partner Manager With Secondary';
  public static final String VACANT_TERR_COMP_PART_MANAGER = 'Vacant Territory Compensation Partner Mgr';
  public static final String GEO_PARTNER_MANAGER = 'Geo Partner Manager';
  public static final String SALES_ENGINEER = 'Sales Engineer';
  public static final String RENEWAL = 'Renewal';
  public static final String PARTNER_LEADER = 'Partner Leader';
  public static final String DEAL_REGISTRATION = 'Deal Registration';

  //Territory Type
  public static final String KEY_ACCOUNTS_PROGRAM = 'Key Accounts Program';
  public static final String CUSTOMER_SUCCESS = 'Customer Success';
  public static final String PARTNER_MANAGEMENT = 'Partner Management';

  //Territory geo
  public static final String GEO_APJ = 'APJ';
  public static final String GEO_AMER = 'AMER';

  // Association Cause
  public static final String TERRITORY_ASSIGNMENT_RULE = 'Territory2AssignmentRule';

  public static final String TERRITORY2MANUAL = 'Territory2Manual';

  // Territory State
  public static final String ACTIVE_STATE = 'Active';

  // DEAL TYPE
  public static final String DEAL_TYPE_BPO = 'BPO';
  public static final String DEAL_TYPE_MANAGED_SERVICES = 'Managed Services';
  public static final String DEAL_TYPE_NFR = 'NFR';
  public static final String DEAL_TYPE_PARTNER_INTERNAL_INFRA = 'Partner Internal Infrastructure';

  // Owner Sync Status
  public static final String OWNER_STATUS_SYNCHED = 'Synched';
  public static final String OPP_OWNER_STATUS_SYNCHED_SOURCE_OPP = 'Synched: Opportunity Territory Update / New';
  public static final String OWNER_STATUS_OUT_OF_SYNC = 'Out of Sync';
  public static final String OWNER_STATUS_EXCEPTION = 'Exception';
  public static final String OWNER_STATUS_OUT_OF_SYNC_OPP_REALIGN = 'Out of Sync - Opp realigned';
  public static final String UNABLE_TO_DEFAULT_NAMED_LIST_ASSIGNMENT = 'Unable to Default Assignment';

  //Country Code
  public static final String COUNTRY_CODE_US = 'US';

  // Opportunity Stage Values
  public static final String CLOSED_WON_BOOKED = 'Closed Won Booked';

  //ETM Setting
  public static final String TERRITORY_AREA = 'Territory_Area';
  public static final String SKIP_OPP_REALIGNMENT_SETTING = 'Skip_Opp_Realignment';
  public static final String NFR_OPP_ROLE = 'NFR_Opp_Role';

  //SOBJECT LABELS
  public static final String ACCOUNT_OBJECT = 'Account';
  public static final String OPPORTUNITY_OBJECT = 'Opporunity';

  //RECORDTYPE LABELS
  public static final String CUSTOMER = 'Customer';
}