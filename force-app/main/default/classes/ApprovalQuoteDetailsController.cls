public with sharing class ApprovalQuoteDetailsController {
  public Id qId {
    get;
    set {
      qId = value;
      fetchDetails();
    }
  }

  public SBQQ__Quote__c quote { get; set; }
  public List<ProductWrapper> products { get; set; }
  public List<sbaa__Approval__c> approvalRequests { get; set; }
  public Boolean showAdditionalInfo { get; set; }
  public Boolean onlyQuoteSummary { get; set; }

  private void fetchDetails() {
    if (String.isNotBlank(qId)) {
      // quote details
      quote = [
        SELECT
          Id,
          Name,
          Quote_Total_Discount__c,
          SBQQ__StartDate__c,
          SBQQ__EndDate__c,
          SBQQ__ListAmount__c,
          SBQQ__NetAmount__c,
          Opportunity_Type__c,
          SBQQ__Opportunity2__c,
          SBQQ__Opportunity2__r.Name,
          SBQQ__Opportunity2__r.Competition__c,
          SBQQ__Opportunity2__r.Economic_Buyer__c,
          SBQQ__Opportunity2__r.Economic_Buyer__r.Name,
          SBQQ__Account__c,
          SBQQ__Account__r.Name,
          SBQQ__Partner__c,
          SBQQ__Partner__r.Name,
          SBQQ__Distributor__c,
          SBQQ__Distributor__r.Name,
          SBQQ__BillingFrequency__c,
          Payment_Terms__c,
          Default_Payment_Terms__c,
          Partner_Discount_Custom__c,
          X5_Bot_Minimum_Approval_Required__c,
          Deal_Type__c,
          Estimated_iARR__c,
          Number_of_Swapped_Lines__c,
          Discount_Reasons__c,
          CurrencyIsoCode,
          Quote_Duration__c,
          Bill_To_Geo_New__c,
          Bill_To_Region__c,
          Has_Exceptions__c,
          Exception_Types__c
        FROM SBQQ__Quote__c
        WHERE Id = :qId
      ];

      // product details
      Integer max = 10;
      Integer count = 0;
      products = new List<ProductWrapper>();
      for (SBQQ__QuoteLine__c line : [
        SELECT
          Id,
          Name,
          SBQQ__ProductName__c,
          SBQQ__Quantity__c,
          SBQQ__ListPrice__c,
          SBQQ__PartnerDiscount__c,
          Total_Discount__c,
          SBQQ__NetPrice__c,
          SBQQ__NetTotal__c,
          CurrencyIsoCode
        FROM SBQQ__QuoteLine__c
        WHERE SBQQ__Quote__c = :qId
        LIMIT 15
      ]) {
        count++;
        if (count > max) {
          ProductWrapper p = new ProductWrapper();
          p.showMoreLink = true;
          products.add(p);
          break;
        }

        ProductWrapper p = new ProductWrapper();
        p.productName = line.SBQQ__ProductName__c;
        p.quantity = line.SBQQ__Quantity__c;
        p.listPrice = line.SBQQ__ListPrice__c;
        p.partnerDiscount = line.SBQQ__PartnerDiscount__c == null ? 0 : line.SBQQ__PartnerDiscount__c;
        p.discount = line.Total_Discount__c;
        p.netPrice = line.SBQQ__NetPrice__c;
        p.netTotal = line.SBQQ__NetTotal__c;
        p.currencyCode = line.CurrencyIsoCode;
        products.add(p);
      }

      // June 6 2022 - Commented
      // additional information
      // if (
      //   quote.X5_Bot_Minimum_Approval_Required__c == true ||
      //   (quote.Opportunity_Type__c == 'Renewal' &&
      //   quote.Opportunity_iARR__c < 0 &&
      //   quote.Deal_Type__c == 'Direct') ||
      //   quote.Number_of_Swapped_Lines__c > 0
      // ) {
      //   showAdditionalInfo = true;
      // }

      approvalRequests = [
        SELECT
          Id,
          sbaa__Rule__r.Name,
          sbaa__Status__c,
          sbaa__CommentsLong__c,
          sbaa__Approver__r.Name,
          sbaa__ApprovalStep__c
        FROM sbaa__Approval__c
        WHERE Quote__c = :qId
        ORDER BY sbaa__ApprovalStep__c ASC
      ];
    } else {
      quote = new SBQQ__Quote__c();
      products = new List<ProductWrapper>();
    }
  }

  public class ProductWrapper {
    public String productName { get; set; }
    public Decimal quantity { get; set; }
    public Decimal listPrice { get; set; }
    public Decimal partnerDiscount { get; set; }
    public Decimal discount { get; set; }
    public Decimal netPrice { get; set; }
    public Decimal netTotal { get; set; }
    public String currencyCode { get; set; }
    public Boolean showMoreLink { get; set; }
  }
}