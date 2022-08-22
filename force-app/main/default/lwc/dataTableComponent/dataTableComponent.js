import { LightningElement, api, track } from 'lwc';

export default class DataTableComponent extends LightningElement
{
    @api columns;
    @api tableData;
    // TODO: Implement logic to determine if Row change Handling should be used or not

    processSelection(event)
    {
        const selectedRows = event.detail.selectedRows;
        
        this.dispatchEvent(
            new CustomEvent('updateselectedrows', { detail: selectedRows })
        );
    }
}