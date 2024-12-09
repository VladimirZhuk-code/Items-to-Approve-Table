public with sharing class GetProcessInstanceData {

    @AuraEnabled
    public static WrapperFromApexToLWC getData(Id userId) {
        
        List<ProcessInstanceWorkitem> curWorkItems = [
            SELECT ActorId, ElapsedTimeInDays, ProcessInstanceId   
            FROM ProcessInstanceWorkItem 
            WHERE ActorId = :userId
            WITH USER_MODE
        ];

        Set<String> targetProcessInstanceIds = getSObjectSet(curWorkItems, 'ProcessInstanceId');
        List<ProcessInstance> myProcIninstances = [
            SELECT Id, CreatedDate, TargetObjectId, TargetObject.Name
            FROM ProcessInstance
            WHERE Id IN :targetProcessInstanceIds
            WITH USER_MODE
        ];

        List<ProcessInstanceStep> myProcInstStep = [
            SELECT Id, Comments, ActorId, CreatedDate, Actor.Name, StepStatus, ProcessInstanceId
            FROM ProcessInstanceStep
            WHERE ProcessInstanceId IN :targetProcessInstanceIds
            WITH USER_MODE
        ];

        Set<String> dVIds = getSObjectSet(myProcIninstances, 'TargetObjectId');
        List<Deliverable__c> workingDvs = [
            SELECT Id, Name, Status__c, Design_Engineer__r.Name
            FROM Deliverable__c WHERE Id IN :dVIds
            WITH USER_MODE
        ];

        Map<Id, String> getLabels = getLabelsMap(myProcIninstances);

        WrapperFromApexToLWC dataToLWC = new WrapperFromApexToLWC();
            dataToLWC.wrapperWorkItems = curWorkItems;
            dataToLWC.wrapperProcIninstances = myProcIninstances;
            dataToLWC.wrapperProcInstStep = myProcInstStep;
            dataToLWC.wrapperWorkingDvs = workingDvs;
            dataToLWC.wrapperGetLabels = getLabels;
        return dataToLWC;
    }

    public static Set<String> getSObjectSet(List<SObject> sObjects, String keyFieldName) {
        Set<String> results = new Set<String>();
        for (SObject so : sObjects) {
            results.add((String) so.get(keyFieldName));
        }
        return results;
    }

    public static Map<Id, String> getLabelsMap(List<ProcessInstance> sObjects) {
        Map<Id, String> results = new Map<Id, String>();
        for (ProcessInstance pi : sObjects) {
            Id sampleid = pi.TargetObjectId;
            String label = sampleid.getSObjectType().getDescribe().getLabel();
            results.put(sampleid, label);
        }
        return results;
    }
}