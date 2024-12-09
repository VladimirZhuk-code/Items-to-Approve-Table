public with sharing class WrapperFromApexToLWC {
    @AuraEnabled 
    public List<ProcessInstanceWorkitem> wrapperWorkItems;
    @AuraEnabled 
    public List<ProcessInstance> wrapperProcIninstances;
    @AuraEnabled 
    public List<ProcessInstanceStep> wrapperProcInstStep;
    @AuraEnabled 
    public List<Deliverable__c> wrapperWorkingDvs;
    @AuraEnabled 
    public Map<Id, String> wrapperGetLabels; 
}