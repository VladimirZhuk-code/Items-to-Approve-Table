@isTest
private class TestApprovalProcessing {
    static void myApprProcTest() {
        // Setup test data

        //create test User
        User testUser = new User(
        ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
        LastName = 'last',
        Email = 'testUser@test.com',
        UserName = 'Test.User' + DateTime.now().getTime() + '@test.com',
        Alias = 'alias',
        TimeZoneSidKey = 'America/Los_Angeles',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US'
        );
        insert testUser;

        User testUser1 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last1',
            Email = 'testUser1@test.com',
            UserName = 'Test.User1' + DateTime.now().getTime() + '@test.com',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            );
            insert testUser1;
        
        //create test Account
        Account a = new Account();
        a.Name = 'Test Account';
        a.OwnerId = testUser.Id;
        
        insert a;
        
        //create test Opportunity
        Opportunity tOpp = new Opportunity();
        tOpp.Name = 'Test Opp';
        tOpp.AccountId = a.Id;
        tOpp.StageName = 'Qualified';
        tOpp.CloseDate = Date.today();
        tOpp.OwnerId = testUser.Id;
        
        insert tOpp;
        
        // Create a Test Deliverable
        Deliverable__c newTestDV = new Deliverable__c();
        newTestDV.Name = 'TestDV';
        newTestDV.Design_Type__c = 'Custom Design';
        newTestDV.Opportunity__c = tOpp.Id;
        newTestDV.Status__c = 'New';
        newTestDV.Notes__c = 'Test Notes';
        newTestDV.Deliverable_Owner__c = testUser.Id;
        newTestDV.Design_Engineer__c = testUser.Id;

        insert newTestDV;

        Test.startTest();

            // Set parameters for approval submition
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setObjectId(newTestDV.id);
            req1.setComments('Submitting Request for Approval.');
            req1.setProcessDefinitionNameOrId('EO_NO_Sizing9');
            req1.setSkipEntryCriteria(true);
                
            // Submit the approval request for the Deliverable
            Approval.ProcessResult result = Approval.process(req1);

            // Test the results
                        
            WrapperForApprovalProcessing wrapper = new WrapperForApprovalProcessing();
            wrapper.buttonAction = 'Approve';
            wrapper.comments = 'Comment Test';
            wrapper.reassignId ='';
            wrapper.objectId = newTestDV.Id;
            
            ApprovalProcessing.apprProcessing (wrapper);
            List<Deliverable__c> newDV = [SELECT Id, Status__c FROM Deliverable__c WHERE Id =:newTestDV.Id];
            String status = newDV[0].Status__c;
            System.Assert.areNotEqual(status, newTestDV.Status__c);
            
            WrapperForApprovalProcessing wrapper2 = new WrapperForApprovalProcessing();
            wrapper2.buttonAction = 'Reject';
            wrapper2.comments = 'Comment Test';
            wrapper2.reassignId ='';
            wrapper2.objectId = newTestDV.Id;
            
            ApprovalProcessing.apprProcessing (wrapper2);
            List<Deliverable__c> newDV2 = [SELECT Id, Status__c FROM Deliverable__c WHERE Id =:newTestDV.Id];
            String status2 = newDV2[0].Status__c;
            System.Assert.areNotEqual(status, status2);
            ProcessInstanceWorkItem piwi1 = [
                SELECT Id, ProcessInstanceId, ActorId 
                FROM ProcessInstanceWorkitem 
                WHERE ProcessInstance.TargetObjectId = :newTestDV.Id
                ];
            
            WrapperForApprovalProcessing wrapper3 = new WrapperForApprovalProcessing();
            wrapper3.buttonAction = 'Reassign';
            wrapper3.comments = 'Comment Test';
            wrapper3.reassignId = testUser1.Id;
            wrapper3.objectId = newTestDV.Id;
            
            ApprovalProcessing.apprProcessing (wrapper3);

            ProcessInstanceWorkItem piwi2 = [
                SELECT Id, ProcessInstanceId, ActorId 
                FROM ProcessInstanceWorkitem 
                WHERE ProcessInstance.TargetObjectId = :newTestDV.Id
                ];
            piwi2.ActorId = testUser1.Id;  // Reassign //No commnets (read only - C'mon Salesforce!)
            database.update (piwi2, AccessLevel.USER_MODE);

            System.Assert.areNotEqual(piwi1, piwi2);
            
            Test.stopTest();
    }
}