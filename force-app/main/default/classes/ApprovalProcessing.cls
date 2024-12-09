public with sharing class ApprovalProcessing {
    @AuraEnabled
    public static void apprProcessing (WrapperForApprovalProcessing wrapper) {
        if (String.isNotEmpty(wrapper.reassignId) ) {
            ProcessInstanceWorkItem piwi = getProcInst(wrapper.objectId);
            piwi.ActorId = wrapper.reassignId;  // Reassign //No commnets (read only - C'mon Salesforce!)
            database.update (piwi, AccessLevel.USER_MODE);
    } else if (wrapper.buttonAction == 'Approve') {
        approvalSubProcess  ('Approve', wrapper.objectId, wrapper.comments);
    } else {
        approvalSubProcess  ('Reject', wrapper.objectId, wrapper.comments);
        }
    }
    public static ProcessInstanceWorkitem getProcInst(String currId) {
        ProcessInstanceWorkitem result = [
            SELECT Id, ProcessInstanceId 
            FROM ProcessInstanceWorkitem 
            WHERE ProcessInstance.TargetObjectId = :currId
            AND ProcessInstance.Status = 'Pending'
            WITH USER_MODE
            LIMIT 1
            ];
        return result;
    } 
    public static void approvalSubProcess (String buttonAction, String objectId, String comments ) {
        ProcessInstanceWorkitem piwi = getProcInst(objectId);
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkitemId(piwi.Id);
            req.setAction(buttonAction);
            req.setComments(comments);
        Approval.process(req);
    }
}