const processOtherRenewals = result => {
	let rows = [];
	let columns = [
		{ key: "Name", label: "Name" },
		{ key: "ARRContracts", label: "Renewing Contracts" },
		{ key: "Stage", label: "Stage" },
		{ key: "CloseDate", label: "Close Date" },
		{ key: "RenewalExpiry", label: "Renewal Expiry" },
		{ key: "RenewedContract", label: "Generated from Contract" },
		{ key: "Amount", label: "Amount" },
		{ key: "ARRtoRenew", label: "ARR to Renew" },
		{ key: "BookedARR", label: "Booked ARR" }
	];
	let subColumns = [
		{ key: "ProductName", label: "Product Name" },
		{ key: "Quantity", label: "Quantity" },
		{ key: "StartDate", label: "Start Date" },
		{ key: "EndDate", label: "End Date" },
		{ key: "TotalPrice", label: "Total Price" }
	];

	for (let opp of result.dataList) {
		let row = {
			key: opp.Id,
			selected: false,
			cellData: [
				{ key: opp.Id + "Name", data: opp.Name, isLookup: true, lookupId: opp.Id },
				{
					key: opp.Id + "ARRContracts",
					isHtml: true,
					data:
						opp.SBQQ__RenewedContracts__r && opp.SBQQ__RenewedContracts__r.length > 0
							? opp.SBQQ__RenewedContracts__r.map(contract => {
									return `<a href="/${contract.Id}" target="_blank">${contract.ContractNumber}</a>`;
							}).join("<br/>")
							: ""
				},
				{ key: opp.Id + "Stage", isText: true, data: opp.StageName },
				{ key: opp.Id + "CloseDate", isDate: true, data: opp.CloseDate },
				{ key: opp.Id + "RenewalExpiry", isDate: true, data: opp.Renewal_Expiry_Date__c },
				{
					key: opp.Id + "RenewedContract",
					isLookup: true,
					lookupId: opp.SBQQ__RenewedContract__c,
					data: opp.SBQQ__RenewedContract__r ? opp.SBQQ__RenewedContract__r.ContractNumber : null
				},
				{ key: opp.Id + "Amount", isCurrency: true, currencyCode: opp.CurrencyIsoCode, data: opp.Amount },
				{ key: opp.Id + "ARRtoRenew", isCurrency: true, currencyCode: opp.CurrencyIsoCode, data: opp.ARR_to_Renew__c },
				{ key: opp.Id + "BookedARR", isCurrency: true, currencyCode: opp.CurrencyIsoCode, data: opp.CPQ_OpportunityARR__c }
			],
			drawerData: [
				{
					key: opp.Id + "PrimaryQuote",
					label: "Primary Quote",
					data: opp.SBQQ__PrimaryQuote__r ? opp.SBQQ__PrimaryQuote__r.Name : null,
					isLookup: true,
					lookupId: opp.SBQQ__PrimaryQuote__c
				},
				{
					key: opp.Id + "StartDate",
					label: "Start Date",
					isDate: true,
					data: opp.SBQQ__PrimaryQuote__r ? opp.SBQQ__PrimaryQuote__r.SBQQ__StartDate__c : null
				},
				{
					key: opp.Id + "EndDate",
					label: "End Date",
					isDate: true,
					data: opp.SBQQ__PrimaryQuote__r ? opp.SBQQ__PrimaryQuote__r.SBQQ__EndDate__c : null
				},
				{
					key: opp.Id + "OrderNumber",
					label: "Order",
					isLookup: true,
					lookupId: opp.Orders ? opp.Orders[0].Id : null,
					data: opp.Orders ? opp.Orders[0].OrderNumber : null
				},
				{
					key: opp.Id + "Status",
					label: "Status",
					isText: true,
					data: opp.Orders ? opp.Orders[0].Status : null
				},
				{
					key: opp.Id + "NSSalesOrderID",
					label: "Netsuite Order",
					isText: true,
					data: opp.Orders ? opp.Orders[0].NS_Sales_Order_ID__c : null
				},
				{
					key: opp.Id + "CaseNumber",
					label: "Finance Case",
					isLookup: true,
					lookupId: opp.Orders ? opp.Orders[0].Finance_Case__c : null,
					data: opp.Orders
						? opp.Orders[0].Finance_Case__r
							? opp.Orders[0].Finance_Case__r.CaseNumber
							: null
						: null
				},
				{
					key: opp.Id + "InvoiceNumber",
					label: "Invoice",
					isText: true,
					data: opp.Orders
						? opp.Orders[0].Finance_Case__r
							? opp.Orders[0].Finance_Case__r.Invoice_Number__c
							: null
						: null
				},
				{
					key: opp.Id + "Contract",
					label: "Contract",
					isLookup: true,
					lookupId: opp.SBQQ__Contracts__r ? opp.SBQQ__Contracts__r[0].Id : null,
					data: opp.SBQQ__Contracts__r ? opp.SBQQ__Contracts__r[0].ContractNumber : null
				}
			]
		};
		if (opp.OpportunityLineItems && opp.OpportunityLineItems.length > 0) {
			row.subTableData = { columnData: subColumns, rowData: [] };

			for (let oppLine of opp.OpportunityLineItems) {
				row.subTableData.rowData.push({
					key: oppLine.Id,
					selected: false,
					cellData: [
						{
							key: oppLine.Id + "ProductName",
							data: oppLine.Product2.Name,
							isLookup: true,
							lookupId: oppLine.Id
						},
						{ key: oppLine.Id + "Quantity", isText: true, data: oppLine.Quantity },
						{ key: oppLine.Id + "StartDate", isDate: true, data: oppLine.Start_Date_Truncated__c },
						{ key: oppLine.Id + "EndDate", isDate: true, data: oppLine.End_Date__c },
						{ key: oppLine.Id + "TotalPrice", isCurrency: true, currencyCode: opp.CurrencyIsoCode, data: oppLine.TotalPrice }
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

export { processOtherRenewals };