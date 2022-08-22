const processRiplacementData = (result) => {
  let rows = [];
  let columns = [
    { key: "Quote", label: "Quote" },
    { key: "Opportunity", label: "Opportunity" },
    { key: "Stage", label: "Stage" },
    { key: "CloseDate", label: "Close Date" },
    { key: "Amount", label: "Amount" },
    { key: "QuoteStartDate", label: "Quote Start Date" },
    { key: "QuoteEndDate", label: "Quote End Date" }
  ];
  let subColumns = [
    { key: "CancelledContract", label: "Cancelled Contract" },
    { key: "CancellationQuote", label: "Cancellation Quote" },
    { key: "Account", label: "Account" },
    { key: "Opportunity", label: "Opportunity" },
    { key: "Amount", label: "Amount" },
    { key: "QuoteStartDate", label: "Start Date" },
    { key: "QuoteEndDate", label: "End Date" }
  ];

  for (let quote of result.dataList) {
    let row = {
      key: quote.Id,
      selected: false,
      cellData: [
        { key: quote.Id + "Quote", data: quote.Name, isLookup: true, lookupId: quote.Id },
        {
          key: quote.Id + "Opportunity",
          isLookup: true,
          data: quote.SBQQ__Opportunity2__r?.Name,
          lookupId: quote.SBQQ__Opportunity2__c
        },
        { key: quote.Id + "Stage", isText: true, data: quote.SBQQ__Opportunity2__r?.StageName },
        { key: quote.Id + "CloseDate", isDate: true, data: quote.SBQQ__Opportunity2__r?.CloseDate },
        {
          key: quote.Id + "Amount",
          isCurrency: true,
          currencyCode: quote.SBQQ__Opportunity2__r?.CurrencyIsoCode,
          data: quote.SBQQ__Opportunity2__r?.Amount
        },
        { key: quote.Id + "QuoteStartDate", isDate: true, data: quote.SBQQ__StartDate__c },
        { key: quote.Id + "QuoteEndDate", isDate: true, data: quote.SBQQ__EndDate__c }
      ]
    };

    if (
      (quote.Async_Tasks__r && quote.Async_Tasks__r.length > 0) ||
      (quote.CancellationQuotes__r && quote.CancellationQuotes__r.length > 0)
    ) {
      row.subTableData = { showFlag: true, columnData: subColumns, rowData: [] };

      let taskAndQuote = [];
      if (quote.Async_Tasks__r) {
        for (let task of quote.Async_Tasks__r) {
          let flag;
          let rowActionData;
          if (task.Status__c === "Inprogress") {
            flag = {
              infoFlag: true,
              message:
                "Contract cancellation job has been queued for processing. Please check again after a few minutes."
            };
          } else if (task.Status__c === "Completed") {
            flag = { successFlag: true, message: "Contract cancellation job was finished successfully." };
          } else if (task.Status__c === "Error") {
            flag = { errorFlag: true, message: task.Error__c };
            rowActionData = [{ key: "retry", label: "Retry Job", value: "RetryAsyncTask" }];
          }
          let combined = {
            key: task.Id,
            taskObj: task,
            flag: flag,
            rowActionData: rowActionData,
            quoteObj: quote.CancellationQuotes__r
              ? quote.CancellationQuotes__r.find(
                  (q) =>
                    q.SBQQ__Opportunity2__r?.SBQQ__AmendedContract__c &&
                    q.SBQQ__Opportunity2__r?.SBQQ__AmendedContract__c === task.Contract__c
                )
              : null
          };
          if (combined.quoteObj) {
            combined.quoteObj.processed = true;
          }
          taskAndQuote.push(combined);
        }
      }
      if (quote.CancellationQuotes__r) {
        // pushing remaning cancellation quotes
        for (let q of quote.CancellationQuotes__r) {
          if (q.processed !== true) {
            taskAndQuote.push({
              key: q.Id,
              taskObj: null,
              flag: { successFlag: true, message: "Contract cancellation job was finished successfully." },
              rowActionData: null,
              quoteObj: q
            });
          }
        }
      }

      for (let obj of taskAndQuote) {
        row.subTableData.rowData.push({
          key: obj.key,
          selected: false,
          flag: obj.flag,
          rowActionData: obj.rowActionData,
          cellData: [
            {
              key: obj.key + "CancelledContract",
              data: obj.taskObj
                ? obj.taskObj.Contract__r.ContractNumber
                : obj.quoteObj?.SBQQ__Opportunity2__r?.SBQQ__AmendedContract__r?.ContractNumber,
              isLookup: true,
              lookupId: obj.taskObj
                ? obj.taskObj.Contract__c
                : obj.quoteObj?.SBQQ__Opportunity2__r?.SBQQ__AmendedContract__c
            },
            {
              key: obj.key + "CancellationQuote",
              data: obj.quoteObj?.Name,
              isLookup: true,
              lookupId: obj.quoteObj?.Id
            },
            {
              key: obj.key + "Account",
              isLookup: true,
              lookupId: obj.quoteObj?.SBQQ__Account__c,
              data: obj.quoteObj?.SBQQ__Account__r?.Name
            },
            {
              key: obj.key + "Opportunity",
              isLookup: true,
              lookupId: obj.quoteObj?.SBQQ__Opportunity2__c,
              data: obj.quoteObj?.SBQQ__Opportunity2__r?.Name
            },
            {
              key: obj.key + "Amount",
              isCurrency: true,
              currencyCode: obj.quoteObj?.SBQQ__Opportunity2__r?.CurrencyIsoCode,
              data: obj.quoteObj?.SBQQ__Opportunity2__r?.Amount
            },
            { key: obj.key + "QuoteStartDate", isDate: true, data: obj.quoteObj?.SBQQ__StartDate__c },
            { key: obj.key + "QuoteEndDate", isDate: true, data: obj.quoteObj?.SBQQ__EndDate__c }
          ]
        });
      }
    }
    rows.push(row);
  }

  return {
    columns: columns,
    rows: rows
  };
};

export { processRiplacementData };