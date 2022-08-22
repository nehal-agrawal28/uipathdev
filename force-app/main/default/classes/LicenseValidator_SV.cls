public without sharing class LicenseValidator_SV {
  public LicenseValidator_SV() {
  }

  @AuraEnabled
  public static Response validateLicenseCode(String licenseCode) {
    List<Grid> gridData = new List<Grid>();
    Response response = new Response();
    try {
      String result = (Test.isRunningTest())
        ? BoonLicenseTest.mockJson()
        : Ui_PathValidateLicenseCode.validateLicenseCode(licenseCode);
      BoonLicense license = BoonLicense.parse(result);
      response.name = license.accountName;
      response.accountId = license.accountId;
      response.gridData = getProducts();
    } catch (Exception e) {
      System.debug('$$$ exception ' + e);
      throw new AuraHandledException(e.getMessage());
    }
    return response;
  }

  public static List<Grid> getProducts() {
    List<Grid> gridData = new List<Grid>();
    for (ProductSetting__mdt product : ProductSetting__mdt.getAll().values()) {
      Grid grid = new Grid(product.Label, 0);
      grid.name = product.Product__c;
      gridData.add(grid);
    }
    gridData.sort();
    return gridData;
  }

  public class Response {
    @AuraEnabled
    public List<Grid> gridData;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String accountId;
    @AuraEnabled
    public String currentDeployment;

    public Response() {
    }
  }

  public class Grid implements Comparable {
    @AuraEnabled
    public String licenseCode;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public Integer quantity;
    @AuraEnabled
    public Integer requestedQuantity = 0;

    public Grid(String licenseCode, Integer quantity) {
      this.licenseCode = licenseCode;
      this.quantity = quantity;
    }

    public List<Grid> parse(String json) {
      return (List<Grid>) System.JSON.deserialize(json, List<Grid>.class);
    }

    public Integer compareTo(Object compareTo) {
      Grid compareToGrid = (Grid) compareTo;
      if (licenseCode == compareToGrid.licenseCode)
        return 0;
      if (licenseCode > compareToGrid.licenseCode)
        return 1;
      return -1;
    }
  }
}