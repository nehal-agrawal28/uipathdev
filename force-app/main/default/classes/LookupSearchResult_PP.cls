public virtual class LookupSearchResult_PP implements Comparable {
  protected Id id;
  protected String sObjectType;
  protected String icon;
  protected String title;
  protected String subtitle;

  protected LookupSearchResult_PP() {
  }

  public LookupSearchResult_PP(Id id, String sObjectType, String icon, String title, String subtitle) {
    this.id = id;
    this.sObjectType = sObjectType;
    this.icon = icon;
    this.title = title;
    this.subtitle = subtitle;
  }

  @AuraEnabled
  public Id getId() {
    return id;
  }

  @AuraEnabled
  public String getSObjectType() {
    return sObjectType;
  }

  @AuraEnabled
  public String getIcon() {
    return icon;
  }

  @AuraEnabled
  public String getTitle() {
    return title;
  }

  @AuraEnabled
  public String getSubtitle() {
    return subtitle;
  }

  public Integer compareTo(Object compareTo) {
    LookupSearchResult_PP other = (LookupSearchResult_PP) compareTo;

    if (this.getTitle() == null)
      return (other.getTitle() == null) ? 0 : 1;

    if (other.getTitle() == null)
      return -1;

    return this.getTitle().compareTo(other.getTitle());
  }
}