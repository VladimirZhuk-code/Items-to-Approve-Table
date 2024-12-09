public with sharing class WrapperForApprovalProcessing {
    @AuraEnabled
    public String buttonAction {get; set;}
    @AuraEnabled
    public String comments {get; set;}
    @AuraEnabled
    public String reassignId {get; set;}
    @AuraEnabled
    public String objectId {get; set;}
}