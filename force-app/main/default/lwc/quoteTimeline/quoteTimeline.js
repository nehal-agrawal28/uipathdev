/* eslint-disable no-undef */
/* eslint-disable guard-for-in */
import { LightningElement, api, track, wire } from "lwc";
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import { loadStyle, loadScript } from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import DHTMLX_LIB from "@salesforce/resourceUrl/dhtmlxgantt713"; // DHTMLX library
import ganttConfigsInit from "./ganttConfigsInit"; // Gantt configurations
import { processGanttData, processDataForLinkMode, sortGanttFunction } from "./processGanttData"; // Fetch gantt data from Salesforce
import saveGanttData from "./saveGanttData"; // Save gantt data to Salesforce
import overlayARR from "./overlayARR";
import { setCookies, getCookie } from "./util";

export default class QuoteTimeline extends NavigationMixin(LightningElement) {
  static delegatesFocus = true;

  @api height;

  @track currentPageReference;
  @track quoteId; // url parameter
  @track theme; // url parameter
  _themes = ["default", "material", "meadow", "contrast_white"];

  @track ganttInitialized = false;
  @track showSpinner = false;
  @track showARRChart = false;
  @track ganttData; // hold salesforce data
  @track isQuoteCalculating = false;
  @track linkMode = false;
  _ganttMarkers = new Map(); // hold gantt markers
  _overlayARRId; // hold overlay Id
  _overlayARRChart; // hold overlay Chart obj

  /**
   * PageReference callback to get url parameters
   */
  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference) {
    this.currentPageReference = currentPageReference;
    this.quoteId = currentPageReference.state.c__quoteId;
    this.theme = currentPageReference.state.c__theme;

    // Reload page if previour gantt data cache is present
    if (typeof gantt !== "undefined") {
      window.location.reload();
    }

    this.loadGanttLib();
  }

  connectedCallback() {
    // component is attached to the DOM
  }

  /**
   * Load DHTMLX gantt library from static resource
   */
  loadGanttLib() {
    this.ganttInitialized = true;

    let stylesheet = this.getThemeStylesheet();
    Promise.all([
      loadScript(this, DHTMLX_LIB + "/dhtmlxgantt.js"),
      loadScript(this, DHTMLX_LIB + "/chartjs/moment.js"),
      loadScript(this, DHTMLX_LIB + "/chartjs/chart7.1.9.min.js"),
      loadStyle(this, DHTMLX_LIB + stylesheet)
    ])
      .then(() => {
        this.initializeGantt();
      })
      .catch((error) => {
        console.error("Error " + JSON.stringify(error));
        this.showToast("Error loading Timeline", error.message, "error");
      });
  }

  /**
   * Initialize gantt configurations and load data from Apex
   */
  initializeGantt() {
    const root = this.template.querySelector(".thegantt");
    root.style.height = "90vh"; // this.height ? this.height + "px" : "90vh";

    ganttConfigsInit(gantt);
    gantt.init(root); // Initialze gantt

    processGanttData(gantt, this); // Fetch gantt data from Salesforce
  }

  toggleLinkMode(e) {
    let checked = e.target.checked;
    const root = this.template.querySelector(".thegantt");
    if (checked) {
      this.linkMode = true;
      root.classList.replace("normal-mode", "link-mode");
      processDataForLinkMode(gantt, this, this.ganttData); // redraw gantt
      gantt.sort(sortGanttFunction); // sort by ARR value
    } else {
      this.linkMode = false;
      root.classList.replace("link-mode", "normal-mode");
      processDataForLinkMode(gantt, this, this.ganttData); // redraw gantt
    }
    gantt.showDate(new Date(this.ganttData.quote.SBQQ__StartDate__c)); // drag to quote start
  }

  /**
   * UI Buttons
   */
  undo() {
    gantt.undo();
  }
  redo() {
    gantt.redo();
  }
  zoomIn() {
    gantt.ext.zoom.zoomIn();
  }
  zoomOut() {
    gantt.ext.zoom.zoomOut();
  }
  toggleTheme() {
    this.theme = getCookie(document, "QuoteTimelineTheme");
    let index = this._themes.findIndex((t) => t === this.theme);
    if (index === -1 || index + 1 >= this._themes.length) {
      this.theme = this._themes[0];
    } else {
      this.theme = this._themes[index + 1];
    }
    setCookies(document, "QuoteTimelineTheme", this.theme);
    window.location.reload();
  }
  openQuoteLineEditor() {
    this[NavigationMixin.Navigate]({
      type: "standard__webPage",
      attributes: {
        url: this.ganttData.editLineUrl
      }
    });
  }
  toggleARROverlay() {
    let overlayControl = gantt.ext.overlay;
    if (overlayControl.isOverlayVisible(this._overlayARRId)) {
      overlayControl.hideOverlay(this._overlayARRId);
      this.template.querySelector(".thegantt").classList.remove("overlay_visible");
      this.showARRChart = false;
    } else {
      if (this._overlayARRId) {
        overlayControl.deleteOverlay(this._overlayARRId);
      }
      overlayARR(gantt, this, this.ganttData);
      overlayControl.showOverlay(this._overlayARRId);
      this.template.querySelector(".thegantt").classList.add("overlay_visible");
      this.showARRChart = true;
    }
    gantt.showDate(new Date(this.ganttData.quote.SBQQ__StartDate__c)); // drag to quote start
    gantt.render(); // forcing gantt to rerender
  }
  saveData() {
    if (this.linkMode) {
      this.showToast("Linking Mode", "Please turn OFF Linking Mode and then save", "error");
    } else {
      saveGanttData(gantt, this.ganttData, this);
    }
  }

  getThemeStylesheet() {
    let stylesheet = "/dhtmlxgantt.css"; // default theme;
    // if (!this.theme) {
    //   this.theme = getCookie(document, "QuoteTimelineTheme");
    // }
    // if (this.theme === "material") {
    //   stylesheet = "/skins/dhtmlxgantt_material.css";
    // } else if (this.theme === "meadow") {
    //   stylesheet = "/skins/dhtmlxgantt_meadow.css";
    // } else if (this.theme === "contrast_white") {
    //   stylesheet = "/skins/dhtmlxgantt_contrast_white.css";
    // }
    return stylesheet;
  }

  showToast(title, message, variant) {
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(evt);
  }
}