/**
 * File Name: QuotePartnerDiscountWebService_PP
 *
 * @author : architect ir. Wilhelmus G.J. Velzeboer
 *
 *
 * POST Request
 * url: /Quote/PartnerDiscount/v1.0/a550x0000003azlAAA
 *
 * body:
 * {
 *   "products" :
 *   [
 *     {
 *       "productId" : "01t000000000001AAA",
 *       "amount" : 1
 *     },
 *     {
 *       "productId" : "01t000000000002AAA",
 *       "amount" : 1
 *     }
 *   ]
 * }
 *
 * POST Response 200 body:
 * {
 *   "quoteId" : "a550x0000003azlAAA",
 *   "products":
 *   [
 *     {
 *       "productId" : "01t000000000001AAA",
 *       "discountPercentage" : 10.0
 *       "upliftPercentage" : 15.0
 *       "discountReason" :
 *       {
 *           "schedules" :
 *           [
 *               {
 *                  "id" : "aBm000000000001CAA",
 *                  "name" : "April Promotion",
 *                  "percentage" : 5.0
 *               }
 *           ],
 *           "uplifts" :
 *           [
 *               {
 *                  "id" : "aBp000000000001CAA",
 *                  "name" : "Special offer",
 *                  "percentage" : 15.0
 *               },
 *               {
 *                  "id" : "aBp000000000002CAA",
 *                  "name" : "VIP Partner",
 *                  "percentage" : 5.0
 *               }
 *           ]
 *       }
 *     }
 *   ]
 * }
 *
 *
 */
@RestResource(UrlMapping='/Quote/PartnerDiscount/v1.0/*')
global without sharing class QuotePartnerDiscountWebService_PP {
  /**
   * Request for getting the discount percentage values for the provided quote Id and products
   */
  @HttpPost
  global static void doPost() {
    try {
      fflib_SecurityUtils.checkObjectIsReadable(Schema.SBQQ__Quote__c.SObjectType);

      // retrieve data from request
      Id quoteId = getQuoteIdFromRequestURI();
      IQuotes_PP quotes = Quotes_PP.newInstance(new Set<Id>{ quoteId });
      IQuoteLineItems_PP lineItems = getQuoteLineItemsFromBody(quoteId);

      // invoke service
      ProductDiscountInfos_PP result = PartnerDiscountsService_PP.calculateProductDiscount(quotes, lineItems);

      // return result
      RestContext.response.statusCode = 200;
      RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new PostResponse(quoteId, lineItems, result)));
    } catch (fflib_SecurityUtils.CrudException e) {
      // Unauthorised
      RestContext.response.statusCode = 401;
      RestContext.response.responseBody = generateFailureResponse(e);
    } catch (System.JSONException e) {
      // JSON formatting error
      RestContext.response.statusCode = 400;
      RestContext.response.responseBody = generateFailureResponse('JSON format error');
    } catch (Exception e) {
      // General exception
      RestContext.response.statusCode = 400;
      RestContext.response.responseBody = generateFailureResponse(e);
      System.debug(e.getStackTraceString());
    }
  }

  private static Blob generateFailureResponse(Exception e) {
    return generateFailureResponse(e.getMessage());
  }

  private static Blob generateFailureResponse(String message) {
    return Blob.valueOf(JSON.serialize(new FailureResponse(message)));
  }

  private static QuoteLineItems_PP getQuoteLineItemsFromBody(Id quoteId) {
    QuotePartnerDiscountWebService_PP.GetRequest requestBody = (QuotePartnerDiscountWebService_PP.GetRequest) JSON.deserializeStrict(
      RestContext.request.requestBody.toString(),
      QuotePartnerDiscountWebService_PP.GetRequest.class
    );

    List<SBQQ__QuoteLine__c> result = new List<SBQQ__QuoteLine__c>();
    for (QuoteProducts quoteProduct : requestBody.products) {
      result.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quoteId,
          SBQQ__Product__c = quoteProduct.productId,
          SBQQ__Quantity__c = quoteProduct.amount
        )
      );
    }
    return QuoteLineItems_PP.newInstance(result);
  }

  private static Id getQuoteIdFromRequestURI() {
    String quoteId = RestContext.request.requestURI.substring(RestContext.request.requestURI.lastIndexOf('/') + 1);
    if (String.isBlank(quoteId))
      throw new DeveloperException('Missing Quote Id in request url'); // todo - convert to label

    try {
      return Id.valueOf(quoteId);
    } catch (System.StringException e) {
      throw new DeveloperException('Incorrect formatted Quote Id'); // todo - convert to label
    }
  }

  global class GetRequest {
    public List<QuoteProducts> products { get; set; }
  }

  global class QuoteProducts {
    public Id productId { get; set; }
    public Integer amount { get; set; }

    public QuoteProducts(Id productId, Integer amount) {
      this.productId = productId;
      this.amount = amount;
    }
  }

  global class PostResponse {
    public Id quoteId { get; set; }
    public List<QuoteProductDiscount> products { get; set; }

    public PostResponse(Id quoteId, IQuoteLineItems_PP lineItems, ProductDiscountInfos_PP discountInfo) {
      this.quoteId = quoteId;
      this.products = new List<QuoteProductDiscount>();
      for (SBQQ__QuoteLine__c lineItem : lineItems.getQuoteLineItems()) {
        this.products.add(new QuoteProductDiscount(lineItem, discountInfo));
      }
    }
  }

  global class QuoteProductDiscount {
    public Id productId { get; set; }
    public Decimal discountPercentage { get; set; }
    public Decimal upliftPercentage { get; set; }
    public DiscountReasons discountReason { get; set; }

    public QuoteProductDiscount(SBQQ__QuoteLine__c lineItem, ProductDiscountInfos_PP discountInfo) {
      this.productId = lineItem.SBQQ__Product__c;
      this.discountPercentage = lineItem.Partner_Tier_Level_Discount__c;
      this.upliftPercentage = lineItem.Business_Partner_Type_Discount__c;
      this.discountReason = new DiscountReasons(discountInfo.selectByProductId(this.productId));
    }
  }

  global class DiscountReasons {
    public List<DiscountReason> schedules = new List<DiscountReason>();
    public List<DiscountReason> uplifts = new List<DiscountReason>();

    public DiscountReasons(ProductDiscountInfos_PP discountInfos) {
      for (ProductDiscountInfos_PP.DiscountInfo discountInfo : discountInfos.selectSchedules().getDiscountInfos()) {
        schedules.add(new DiscountReason(discountInfo));
      }
      for (ProductDiscountInfos_PP.DiscountInfo discountInfo : discountInfos.selectUplifts().getDiscountInfos()) {
        uplifts.add(new DiscountReason(discountInfo));
      }
    }
  }

  global class DiscountReason {
    public String id { get; set; }
    public String name { get; set; }
    public Decimal percentage { get; set; }

    public DiscountReason(ProductDiscountInfos_PP.DiscountInfo discountInfo) {
      this.id = String.valueOf(discountInfo.getReasonId());
      this.name = discountInfo.getReasonName();
      this.percentage = discountInfo.getDiscount();
    }
  }

  global class FailureResponse {
    public String message { get; set; }

    public FailureResponse(String message) {
      this.message = message;
    }
  }

  global class DeveloperException extends Exception {
  }
}