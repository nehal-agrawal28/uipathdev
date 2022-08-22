public class ProductDiscountInfos_PP implements fflib_IDomain {
  List<DiscountInfo> objects;

  public ProductDiscountInfos_PP() {
    this.objects = new List<DiscountInfo>();
  }
  public ProductDiscountInfos_PP(List<DiscountInfo> objects) {
    this.objects = objects;
  }

  public ProductDiscountInfos_PP add(ProductDiscountInfos_PP discountInfos) {
    this.objects.addAll(discountInfos.getDiscountInfos());
    return this;
  }

  public Object getType() {
    return DiscountInfo.class;
  }

  public List<Object> getObjects() {
    return this.objects;
  }

  public ProductDiscountInfos_PP addDiscount(Id quoteId, Id productId, Decimal discount, SObject reason) {
    this.objects.add(new DiscountInfo(quoteId, productId).setDiscount(discount).setReason(reason));
    return this;
  }

  public Decimal getDiscount(Id productId) {
    Decimal result = 0;
    for (DiscountInfo discountInfo : getDiscountInfos()) {
      if (discountInfo.productId != productId)
        continue;

      result += discountInfo.getDiscount();
    }
    return result;
  }

  public ProductDiscountInfos_PP selectByProductId(Id productId) {
    List<DiscountInfo> result = new List<DiscountInfo>();
    for (DiscountInfo discountInfo : getDiscountInfos()) {
      if (discountInfo.getProductId() != productId)
        continue;

      result.add(discountInfo);
    }
    return new ProductDiscountInfos_PP(result);
  }

  public ProductDiscountInfos_PP selectByQuoteId(Id quoteId) {
    List<DiscountInfo> result = new List<DiscountInfo>();
    for (DiscountInfo discountInfo : getDiscountInfos()) {
      if (discountInfo.getQuoteId() != quoteId)
        continue;

      result.add(discountInfo);
    }
    return new ProductDiscountInfos_PP(result);
  }

  public ProductDiscountInfos_PP selectSchedules() {
    return selectByReason(Schema.DiscountSchedule__c.SObjectType);
  }

  public ProductDiscountInfos_PP selectUplifts() {
    return selectByReason(Schema.DiscountUplift__c.SObjectType);
  }

  public Map<Id, Decimal> getDiscountByProductId() {
    Map<Id, Decimal> result = new Map<Id, Decimal>();
    for (DiscountInfo discountInfo : (List<DiscountInfo>) getObjects()) {
      Id productId = discountInfo.getProductId();
      if (result.containsKey(productId)) {
        result.put(productId, result.get(productId) + discountInfo.getDiscount());
      } else {
        result.put(discountInfo.getProductId(), discountInfo.getDiscount());
      }
    }
    return result;
  }

  public List<DiscountInfo> getDiscountInfos() {
    return (List<DiscountInfo>) getObjects();
  }

  private ProductDiscountInfos_PP selectByReason(Schema.SObjectType sObjectType) {
    List<DiscountInfo> result = new List<DiscountInfo>();

    for (DiscountInfo discountInfo : getDiscountInfos()) {
      if (discountInfo.isReason(sObjectType)) {
        result.add(discountInfo);
      }
    }
    return new ProductDiscountInfos_PP(result);
  }

  public class DiscountInfo {
    private Decimal discount { get; set; }
    private Id productId { get; private set; }
    private Id quoteId { get; private set; }
    private SObject reason { get; set; }

    public DiscountInfo(Id quoteId, Id productId) {
      this.productId = productId;
      this.quoteId = quoteId;
    }

    public DiscountInfo setDiscount(Decimal percentage) {
      this.discount = percentage;
      return this;
    }

    public DiscountInfo setReason(SObject reason) {
      this.reason = reason;
      return this;
    }

    public Decimal getDiscount() {
      return hasDiscount() ? this.discount : 0;
    }

    private Id getProductId() {
      return this.productId;
    }

    private Id getQuoteId() {
      return this.quoteId;
    }

    public SObject getReason() {
      return this.reason;
    }

    public Id getReasonId() {
      return this.reason.Id;
    }

    public String getReasonName() {
      return (String) this.reason.get('Name');
    }

    public Boolean hasDiscount() {
      return this.discount != null;
    }

    public Boolean isReason(Schema.SObjectType sObjectType) {
      return this.reason.getSObjectType() == sObjectType;
    }
  }
}