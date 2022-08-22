public without sharing class LeadMetadata_MK {
  // Lead Statuses
  public static final String SUSPECT_STATUS = 'Suspect';
  public static final String PARTNER_SUSPECT_STATUS = 'Partner Suspect';
  public static final String NEW_STATUS = 'New';
  public static final String MQL_STATUS = 'MQL';
  public static final String SALES_GENERATED_STATUS = 'Sales Generated';
  public static final String WORKING_STATUS = 'Working';
  public static final String ACCEPTED_STATUS = 'Accepted';
  public static final String DECLINED_STATUS = 'Declined';
  public static final String RECYCLE_STATUS = 'Recycle';
  public static final String DISQUALIFIED_STATUS = 'Disqualified';
  public static final String QUALIFIED_STATUS = 'Qualified';
  public static final String PARTNER_CONTACT_STATUS = 'Partner Contact';

  // Opportunity Stages
  public static final String OPP_OPEN_STAGE = 'Open';
  public static final String OPP_MEETING_CANCELLED_STAGE = 'Meeting Cancelled';
  public static final String OPP_MEETING_HELD_STAGE = 'Meeting Held';
  public static final String OPP_DECLINED_STAGE = 'Declined';
  public static final String OPP_ACCEPTED_STAGE = 'Accepted';
  public static final String OPP_DISCOVERY_STAGE = 'Discovery';
  public static final String OPP_CLOSED_WON_BOOKED_STAGE = 'Closed Won Booked';
  public static final String OPP_CLOSED_LOST_STAGE = 'Closed Lost';
  public static final String OPP_CLOSED_MERGED_STAGE = 'Closed Merged';

  // Funnel Stages
  public static final String FUNNEL_SUSPECT_STAGE = 'Suspect';
  public static final String FUNNEL_SGL_STAGE = 'SGL';
  public static final String FUNNEL_SPL_STAGE = 'SPL';
  public static final String FUNNEL_MQL_STAGE = 'MQL';
  public static final String FUNNEL_TAL_STAGE = 'TAL';
  public static final String FUNNEL_TQL_STAGE = 'TQL';
  public static final String FUNNEL_CONVERTED_STAGE = 'Converted';
  public static final String FUNNEL_EXISTING_OPPORTUNITY_STAGE = 'Existing Opportunity';
  public static final String FUNNEL_MEETING_CANCELLED_STAGE = 'Meeting Cancelled';
  public static final String FUNNEL_MEETING_HELD_STAGE = 'Meeting Held';
  public static final String FUNNEL_BDR_OPP_DECLINED_STAGE = 'BDR Opp Declined';
  public static final String FUNNEL_SAL_STAGE = 'SAL';
  public static final String FUNNEL_SQL_STAGE = 'SQL';
  public static final String FUNNEL_CLOSED_WON_STAGE = 'Closed Won';
  public static final String FUNNEL_CLOSED_LOST_STAGE = 'Closed Lost';
  public static final String FUNNEL_DECLINED_STAGE = 'Declined';
  public static final String FUNNEL_DISQUALIFIED_STAGE = 'Disqualified';

  // Funnel Types
  public static final String FUNNEL_MQL_TYPE = 'MQL';
  public static final String FUNNEL_SALES_GENERATED_TYPE = 'Sales Generated';
  public static final String FUNNEL_SALES_PROGRESSED_TYPE = 'Sales Progressed';

  //Lead Record Types
  private static final String BUSINESS_PARTNER = 'Business_Partner_Onboarding';
  private static final String LEARNING_ALLIANCE = 'Academic_Alliance';
  private static final String STANDARD = 'Standard';
  private static final String TECHNOLOGY_ALLIANCE = 'Technology_Alliance';
  private static final String JAPAN_PARTNER_STANDARD = 'UiPath_Japan_Partner_standard';

  public static Id getRecordTypeId(String developerName) {
    Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId();
    return recordTypeId;
  }

  public static Set<String> currencyEURCountryCodes {
    get {
      if (currencyEURCountryCodes == null) {
        currencyEURCountryCodes = new Set<String>{ 'DE', 'AT', 'CHEF', 'CH' };
      }
      return currencyEURCountryCodes;
    }
    set;
  }

  public static Id BusinessPartnerRecordType {
    get {
      return getRecordTypeId(BUSINESS_PARTNER);
    }
    set;
  }

  public static Id LearningAllianceRecordType {
    get {
      return getRecordTypeId(LEARNING_ALLIANCE);
    }
    set;
  }

  public static Id StandardRecordType {
    get {
      return getRecordTypeId(STANDARD);
    }
    set;
  }

  public static Id TechnologyAllianceRecordType {
    get {
      return getRecordTypeId(TECHNOLOGY_ALLIANCE);
    }
    set;
  }

  public static Id JapanPartnerStandardRecordType {
    get {
      return getRecordTypeId(JAPAN_PARTNER_STANDARD);
    }
    set;
  }

  public static Id marketoIntegrationUser {
    get {
      if (marketoIntegrationUser == null) {
        marketoIntegrationUser = [
          SELECT Id
          FROM User
          WHERE Name = 'Marketo Integration' OR Name = 'Integration Marketo'
          LIMIT 1
        ]
        .Id;
      }
      return marketoIntegrationUser;
    }
    set;
  }

  public static List<LeadStatus> leadStatus {
    get {
      if (leadStatus == null) {
        leadStatus = [
          SELECT Id, MasterLabel
          FROM LeadStatus
          WHERE IsConverted = TRUE AND (MasterLabel = 'Partner Contact' OR MasterLabel = 'Qualified')
          ORDER BY MasterLabel ASC
        ];
      }
      return leadStatus;
    }
    set;
  }

  public static List<USA_States__mdt> States {
    get {
      if (States == null) {
        States = [
          SELECT Label, DeveloperName, Region__c, Billing_State_Code__c, Area__c, Territory__c, Country__c
          FROM USA_States__mdt
        ];
      }
      return States;
    }
    set;
  }

  public static Map<String, USA_Industry__mdt> mapByIndustry {
    get {
      if (mapByIndustry == null) {
        mapByIndustry = new Map<String, USA_Industry__mdt>();
        list<USA_Industry__mdt> uimList = [SELECT Region__c, Industry__c, Area__c, Territory__c FROM USA_Industry__mdt];
        for (USA_Industry__mdt usaIndustry : uimList) {
          mapByIndustry.put(usaIndustry.Industry__c, usaIndustry);
        }
      }
      return mapByIndustry;
    }
    set;
  }

  public static Map<String, USA_States__mdt> mapByBillingStateCode {
    get {
      if (mapByBillingStateCode == null) {
        mapByBillingStateCode = new Map<String, USA_States__mdt>();

        List<USA_States__mdt> States = [
          SELECT Label, DeveloperName, Region__c, Billing_State_Code__c, Area__c, Territory__c, Country__c
          FROM USA_States__mdt
        ];
        for (USA_States__mdt usaStates : States) {
          mapByBillingStateCode.put(usaStates.Billing_State_Code__c + '-' + usaStates.Country__c, usaStates);
        }
      }
      return mapByBillingStateCode;
    }
    set;
  }

  public static Map<String, ROW_Country__mdt> mapROWCountry {
    get {
      if (mapROWCountry == null) {
        mapROWCountry = new Map<String, ROW_Country__mdt>();

        List<ROW_Country__mdt> RowCountry = [
          SELECT Country_Code__c, Region__c, Area__c, Territory__c
          FROM ROW_Country__mdt
        ];
        for (ROW_Country__mdt country : RowCountry) {
          mapROWCountry.put(country.Country_Code__c, country);
        }
      }
      return mapROWCountry;
    }
    set;
  }

  public static List<ROW_Country__mdt> Countries {
    get {
      if (Countries == null) {
        Countries = [SELECT Country_Code__c, Region__c, Area__c, Territory__c FROM ROW_Country__mdt];
      }
      return Countries;
    }
    set;
  }

  public static Map<String, String> CountryCodes {
    get {
      if (CountryCodes == null) {
        CountryCodes = new Map<String, String>();

        //Retrieve Country Codes
        Schema.DescribeFieldResult countryCodeResult = User.Countrycode.getDescribe();
        List<Schema.PicklistEntry> countryPLE = countryCodeResult.getPicklistValues();
        for (Schema.PicklistEntry entry : countryPLE) {
          CountryCodes.put(entry.getValue(), entry.getLabel());
        }
      }
      return CountryCodes;
    }
    set;
  }

  public static Map<String, String> CountryNameAndCodes {
    get {
      if (CountryNameAndCodes == null) {
        CountryNameAndCodes = new Map<String, String>();

        //Retrieve Country Codes
        Schema.DescribeFieldResult countryCodeResult = User.Countrycode.getDescribe();
        List<Schema.PicklistEntry> countryPLE = countryCodeResult.getPicklistValues();
        for (Schema.PicklistEntry entry : countryPLE) {
          CountryNameAndCodes.put(entry.getLabel(), entry.getValue());
        }
      }
      return CountryNameAndCodes;
    }
    set;
  }

  public static Map<String, String> StateNameAndCodes {
    get {
      if (StateNameAndCodes == null) {
        StateNameAndCodes = new Map<String, String>();

        //Retrieve State Codes
        Schema.DescribeFieldResult stateCodeResult = User.statecode.getDescribe();
        List<Schema.PicklistEntry> statePLE = stateCodeResult.getPicklistValues();
        for (Schema.PicklistEntry entry : statePLE) {
          StateNameAndCodes.put(entry.getLabel(), entry.getValue());
        }
      }
      return StateNameAndCodes;
    }
    set;
  }

  public static Map<String, String> getOppFunnelStagesMap() {
    Map<String, String> oppFunnelStages = new Map<String, String>();
    oppFunnelStages.put('Open', 'TQL');
    oppFunnelStages.put('Discovery', 'SQL');
    oppFunnelStages.put('Meeting Cancelled', 'Meeting Cancelled');
    oppFunnelStages.put('Meeting Held', 'SAL');
    oppFunnelStages.put('Declined', 'BDR Opp Declined');
    oppFunnelStages.put('Accepted', 'SQL');
    oppFunnelStages.put('Closed Won Booked', 'Closed Won');
    oppFunnelStages.put('Closed Lost', 'Closed Lost');
    oppFunnelStages.put('Closed Merged', 'Closed Lost');
    return oppFunnelStages;
  }

  public static Map<String, String> getLeadFunnelStagesMap() {
    Map<String, String> leadFunnelStages = new Map<String, String>();
    leadFunnelStages.put('Suspect', 'Suspect');
    leadFunnelStages.put('MQL', 'MQL');
    leadFunnelStages.put('Sales Generated (Progressed)', 'SPL');
    leadFunnelStages.put('Sales Generated', 'SGL');
    leadFunnelStages.put('Accepted', 'TAL');
    leadFunnelStages.put('Disqualified', 'Disqualified');
    leadFunnelStages.put('Declined', 'Declined');
    leadFunnelStages.put('Qualified', 'Qualified');

    return leadFunnelStages;
  }

  public static Map<String, String> getContactFunnelStagesMap() {
    Map<String, String> contactFunnelStages = new Map<String, String>();
    contactFunnelStages.put('MQL', 'MQL');
    contactFunnelStages.put('Sales Generated', 'SGL');
    contactFunnelStages.put('Accepted', 'TAL');
    contactFunnelStages.put('Disqualified', 'Disqualified');
    contactFunnelStages.put('Declined', 'Declined');
    contactFunnelStages.put('Qualified', 'Qualified');

    return contactFunnelStages;
  }
}