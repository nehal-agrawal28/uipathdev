/* eslint-disable @lwc/lwc/no-async-operation */
import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { paginate } from "./paginate.js";
import { columnResizerJs } from "./columnResizer";

export default class DealBuilderDataTable extends NavigationMixin(LightningElement) {
  /**
   * columnData : [
   *   {
   *       key  : <unique_key>,
   *       label : <header label>
   *   }
   * ]
   */
  @api columnData;
  /**
   * rowData : [
   *   {
   *       key : <unique_key>,
   *       selected : <true/false>
   *       flag : {
   *           inprogressFlag/successFlag/infoFlag/errorFlag : <true/false>,
   *           message: <data>
   *       }
   *       customRowClass : <text>
   *       cellData : [
   *           {
   *              key : <unique_key>
   *              data : <data>
   *              wideCell : <true/false>
   * 				      isText : <true/false>
   * 				      isDate : <true/false>
   * 				      isCurrency : <true/false>
   * 				      isHtml : <true/false>
   *              isLookup : <true/false>
   *              lookupId : <sObject Id>
   *           }
   *       ],
   *       drawerData : [
   *       	 {
   *      		    key : <unique_key>,
   *              label : <header label>
   *       		    data : <data>
   *              isText : <true/false>
   *       		    isDate : <true/false>
   *       		    isCurrency : <true/false>
   *       		    isHtml : <true/false>
   *              isLookup : <true/false>
   *              lookupId : <sObject Id>
   *       	 }
   *       ],
   *       rowActionData : [
   *       	 {
   *      		    key : <unique_key>,
   *              label : <action label>
   *       		    value : <action value>
   *       	 }
   *       ],
   *
   *       subTableData : {
   *           hasSelection;
   *           hasPagination;
   *           noDataMessage;
   *           singleSelection;
   *           showFlag;
   *
   *           columnData : ...
   *           rowData : ...
   *       }
   *   }
   * ]
   */
  //   @api rowData;
  @api
  set rowData(value) {
    // api data is immutable, creating a local copy
    this._rowData = [...value];

    // preventing calling of onnectedCallback twice on inlial load
    if (this.columnData && this.rowData) {
      this.connectedCallback();
    }
  }
  get rowData() {
    return this._rowData;
  }
  _rowData;

  /**
   * EVENTs Dispatched
   * > onrowaction : detail : {
   *		label: <rowActionData label>,
   *		value: <rowActionData value>,
   *		rowKey: <row Key>
   * }
   */

  @api hasSelection;
  @api hasPagination;
  @api noDataMessage;
  @api singleSelection;
  @api showFlag;

  @track columnDataLocal;
  @track rowDataLocal;
  @track rowDataLocalVisible;

  @track showDrawerColumn;
  @track showRowActionColumn;
  @track fullColspan;
  @track pagination;
  @track pageSize = 10;
  pageSizeOptions = [
    { label: 10, value: 10 },
    { label: 30, value: 30 },
    { label: 50, value: 50 },
    { label: 100, value: 100 }
  ];

  @api
  selectedRowKeys() {
    let selectedRowKeys = [];
    for (let row of this.rowDataLocal) {
      if (row.selected) {
        selectedRowKeys.push(row.key);
      }
    }
    return selectedRowKeys;
  }

  connectedCallback() {
    // create local copy as api properties are readonly
    this.columnDataLocal = JSON.parse(JSON.stringify(this.columnData));
    this.rowDataLocal = JSON.parse(JSON.stringify(this.rowData));
    this.rowDataLocalVisible = [];

    if (this.rowDataLocal && this.rowDataLocal.length > 0) {
      for (let row of this.rowDataLocal) {
        if (row.cellData) {
          for (let cell of row.cellData) {
            if (cell.isLookup) {
              cell.lookupHref = "/" + cell.lookupId;
            }
          }
        }
        if (row.drawerData) {
          for (let drawer of row.drawerData) {
            if (drawer.isLookup) {
              drawer.lookupHref = "/" + drawer.lookupId;
            }
          }
        }

        if (row.subTableData || row.drawerData) {
          if (!this.showDrawerColumn) {
            this.showDrawerColumn = true; //table level property
          }
          row.showDrawer = true; //row level property
        }
        if (row.rowActionData) {
          if (!this.showRowActionColumn) {
            this.showRowActionColumn = true; //table level property
          }
          row.showRowAction = true; //row level property
        }
      }
      // Pagination
      this.paginateInit();

      // bind column resizer
      setTimeout(() => {
        columnResizerJs(this);
      }, 1000);
    }

    // Needed in table UI
    this.fullColspan = this.columnDataLocal.length;
    if (this.hasSelection) {
      this.fullColspan++;
    }
    if (this.showDrawerColumn) {
      this.fullColspan++;
    }
    if (this.showRowActionColumn) {
      this.fullColspan++;
    }
    if (this.showFlag) {
      this.fullColspan++;
    }
  }

  // Pagination handling
  paginateInit() {
    this.pagination = paginate(this.rowDataLocal.length, 1, this.pageSize, 5);
    this.setVisibleData();
  }
  paginateStart() {
    this.pagination = paginate(this.pagination.totalItems, 1, this.pagination.pageSize, this.pagination.maxPages);
    this.setVisibleData();
  }
  paginateEnd() {
    this.pagination = paginate(
      this.pagination.totalItems,
      this.pagination.totalPages,
      this.pagination.pageSize,
      this.pagination.maxPages
    );
    this.setVisibleData();
  }
  paginateSelectedPage(event) {
    let pageNumber = parseInt(event.target.dataset.pageNumber, 10);
    this.pagination = paginate(
      this.pagination.totalItems,
      pageNumber,
      this.pagination.pageSize,
      this.pagination.maxPages
    );
    this.setVisibleData();
  }
  handlePageSize(event) {
    this.pageSize = parseInt(event.detail.value, 10);
    this.paginateInit();
  }
  setVisibleData() {
    if (this.hasPagination) {
      this.rowDataLocalVisible = this.rowDataLocal.slice(this.pagination.startIndex, this.pagination.endIndex + 1);
    } else {
      this.rowDataLocalVisible = this.rowDataLocal;
    }
  }

  // Sort table handling
  handleColumnSort(event) {
    if (this.rowDataLocal && this.rowDataLocal.length > 1) {
      let columnIndex = event.currentTarget.dataset.index;
      let sortDir = event.currentTarget.classList.contains("sort_asc_visible")
        ? "sort_desc_visible"
        : "sort_asc_visible";

      // Reset all caret icons
      for (let th of this.template.querySelectorAll("th.sort")) {
        th.classList = "sort";
      }

      this.rowDataLocal.sort((a, b) => {
        let aVal = a.cellData[columnIndex].data + "";
        let bVal = b.cellData[columnIndex].data + "";

        if (sortDir === "sort_asc_visible") {
          return aVal.localeCompare(bVal, "en", { sensitivity: "case" });
        }
        return bVal.localeCompare(aVal, "en", { sensitivity: "case" });
      });
      if (sortDir === "sort_asc_visible") {
        event.currentTarget.classList = "sort sort_asc_visible";
      } else {
        event.currentTarget.classList = "sort sort_desc_visible";
      }

      this.paginateInit();
    }
  }

  // Row selection handling
  handleSingleSelection(event) {
    let rowIndex = event.target.dataset.index;
    for (let row of this.rowDataLocal) {
      row.selected = false;
    }
    this.rowDataLocalVisible[rowIndex].selected = true;
  }
  handleAllSelection(event) {
    let allSelected = event.target.checked;
    for (let row of this.rowDataLocal) {
      if (allSelected) {
        row.selected = true;
      } else {
        row.selected = false;
      }
    }
  }
  handleSelection(event) {
    let rowIndex = event.target.dataset.index;
    this.rowDataLocalVisible[rowIndex].selected = event.target.checked;
  }

  // Navigation handling
  handleNavigateToRecord(event) {
    event.preventDefault();
    event.stopPropagation();

    let recId = event.currentTarget.dataset.recId;
    // open in new tab
    this[NavigationMixin.GenerateUrl]({
      type: "standard__recordPage",
      attributes: {
        actionName: "view",
        recordId: recId
      }
    }).then((url) => {
      window.open(url, "_blank");
    });
  }

  // Drawer handling
  handleDrawerOpen(event) {
    let rowIndex = event.target.dataset.index;
    this.rowDataLocalVisible[rowIndex].isDrawerOpened = true;
    this.showSpinner = true;
  }
  handleDrawerClose(event) {
    let rowIndex = event.target.dataset.index;
    this.rowDataLocalVisible[rowIndex].isDrawerOpened = false;
  }

  // Row Action handling
  handleRowActionClick(event) {
    this.dispatchEvent(
      new CustomEvent("rowaction", {
        detail: { label: event.target.label, value: event.target.value, rowKey: event.target.dataset.rowKey }
      })
    );
  }
  handleSubtableRowAction(event) {
    // throw event again from parent table
    this.dispatchEvent(new CustomEvent("rowaction", event));
  }
}