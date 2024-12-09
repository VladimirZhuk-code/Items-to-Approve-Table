import { LightningElement } from 'lwc';
import ApproveModal from 'c/approveModal';
import getData from '@salesforce/apex/GetProcessInstanceData.getData';
import apprProcessing from '@salesforce/apex/ApprovalProcessing.apprProcessing';
import USER_Id from '@salesforce/user/Id';

const actions = [
    { label: 'Approve', value: 'Approve', name: 'approve' },
    { label: 'Reject', value: 'Reject', name: 'reject' },
    { label: 'Reassign', value: 'Reassign', name: 'reassign' }
];

const COLMNS = [
    {
        label: 'Related To', fieldName: 'ObjectName', type: 'url', wrapText: true,
        typeAttributes: {
            label: { fieldName: 'Name' },
            tooltip: { fieldName: 'Tooltip' },
            target: '_blank',
        }
    },
    { label: 'Type', fieldName: 'Type' },
    { label: 'Status', fieldName: 'dvStatus', wrapText: true },
    { label: 'Recent Comment', fieldName: 'Comments', wrapText: true },
    { label: 'Design Engineer', fieldName: 'dvDesignEng' },
    { label: 'Most Recent Approver', fieldName: 'MostRecentApprover' },
    { label: 'Days in Queue', fieldName: 'DaysInQueue' },
    { label: 'Date Submitted', fieldName: 'CreatedDate', type: 'date' },
    { type: 'action', typeAttributes: { rowActions: actions, menuAlignment: 'bottom' } }

];

export default class DatatableWithRowActions extends LightningElement {

    error;
    columns = COLMNS;
    todayDate = new Date();
    options = {};
    todayHTML;
    quantity;
    dataForWrapper = {};
    data = [];
    isLoading;

    connectedCallback() {
        this.getServerData();
    }

    async getServerData() {
        try {
            const d = await getData({ userId: USER_Id });
            let dataAll = [];
            if (d.wrapperWorkItems.length) {
                d.wrapperProcIninstances.forEach(row => {
                    let dataAllObj = {};
                    dataAllObj.Id = row.Id;
                    dataAllObj.Name = row.TargetObject?.Name;
                    dataAllObj.TargetObjectId = row.TargetObjectId;
                    dataAllObj.ObjectName = '/' + row.TargetObjectId;
                    const currDv = d.wrapperWorkingDvs.find(
                        currDv => currDv.Id === row.TargetObjectId
                    );

                    if (currDv) {
                        dataAllObj.dvDesignEng = currDv.Design_Engineer__r?.Name;
                        dataAllObj.dvStatus = currDv.Status__c;
                    };

                    const sortForLatestActor = (d.wrapperProcInstStep).filter(
                        x => x.ProcessInstanceId == row.Id && (x.StepStatus == 'Approved' || 'Rejected' || 'Reassigned')
                    );

                    dataAllObj.MostRecentApprover = ((sortForLatestActor.sort((a, b) => (
                        new Date(b.CreatedDate) - new Date(a.CreatedDate))))[0]
                    )?.Actor?.Name;

                    dataAllObj.Comments = ((sortForLatestActor.sort((a, b) => (
                        new Date(b.CreatedDate) - new Date(a.CreatedDate))))[0]
                    )?.Comments;

                    const daysIn = d.wrapperWorkItems.find(daysIn => daysIn.ProcessInstanceId === row.Id);
                    dataAllObj.DaysInQueue = Math.round(daysIn.ElapsedTimeInDays);
                    const labelsResult = Object.entries(d.wrapperGetLabels).map(([key, value]) => ({
                        Id: key,
                        value: value
                    }));

                    const currLabel = labelsResult.find(currLabel => currLabel.Id === row.TargetObjectId);
                    dataAllObj.Type = currLabel.value;
                    dataAllObj.ObjectId = row.TargetObject?.Id;
                    dataAllObj.CreatedDate = row.CreatedDate;
                    dataAllObj.Tooltip = row.TargetObject?.Name;
                    dataAll.push(dataAllObj);
                })
            }
            this.data = dataAll;
            this.quantity = dataAll.length;
            this.error = undefined;
        }
        catch (error) {
            this.error = error;
        };
        this.options = {
            weekday: "long",
            year: "numeric",
            month: "long",
            day: "numeric",
            hour: "2-digit",
            minute: "2-digit",
            hour12: "true",
            timeZoneName: "longGeneric"
        };
        this.todayHTML = this.todayDate.toLocaleString("en-US", this.options);
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        switch (action.name) {
            case 'approve':
                ApproveModal.open({
                    size: 'small',
                    headerLabel: `Approve ${row.Type}`,
                    contentId: row.Id,
                    buttonAction: "Approve",
                    reassign: false
                }).then((result) => {
                    if (result) {
                        result.objId = row.TargetObjectId;
                        this.createDataForWarpper(result);
                        this.handleModalClose();
                    }
                });
                break;
            case 'reject':
                ApproveModal.open({
                    size: 'small',
                    headerLabel: `Reject ${row.Type}`,
                    contentId: row.Id,
                    buttonAction: "Reject",
                    reassign: false
                }).then((result) => {
                    if (result) {
                        result.objId = row.TargetObjectId;
                        this.createDataForWarpper(result);
                        this.handleModalClose();
                    }
                });
                break;
            case 'reassign':
                ApproveModal.open({
                    size: 'small',
                    headerLabel: `Reassign Approval Request`,
                    contentId: row.Id,
                    buttonAction: "Reassign",
                    reassign: true
                }).then((result) => {
                    if (result) {
                        result.objId = row.TargetObjectId;
                        this.createDataForWarpper(result);
                        this.handleModalClose();
                    }
                });
                break;
        }
    }

    createDataForWarpper(result) {
        this.dataForWrapper = {
            buttonAction: result.objButtonAction,
            comments: result.objComment,
            reassignId: result.objReassId,
            objectId: result.objId
        }
    }

    async handleModalClose() {
        try {
            this.isLoading = true;
            await apprProcessing({ wrapper: this.dataForWrapper });
            await this.getServerData();
            this.isLoading = false;
        }
        catch (error) {
            this.error = error;
        };
    }

    async handleRefresh() {
        try {
            this.isLoading = true;
            await this.getServerData();
            const buttonName = this.template.querySelector('[data-id="refreshId"]');
            buttonName.blur();
            this.isLoading = false;
        }
        catch (error) {
            this.error = error;
        };
    }
}