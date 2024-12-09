@isTest
private class TestGetProcessInstanceData {
    static void myGetInstDataTest() {

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
            // Approve the submitted request
            // First, get the ID of the newly created item
            List<Id> newWorkItemIds = result.getNewWorkitemIds();

            // Instantiate the new ProcessWorkitemRequest object and populate it
            Approval.ProcessWorkitemRequest req2 = 
            new Approval.ProcessWorkitemRequest();
            req2.setComments('Approving request.');
            req2.setAction('Approve');
        
            // Use the ID from the newly created item to specify the item to be worked
            req2.setWorkitemId(newWorkItemIds.get(0));
        
            // Submit the request for approval
            Approval.ProcessResult result2 =  Approval.process(req2);
            
            //Call method to test
            WrapperFromApexToLWC dataResult = GetProcessInstanceData.getData(testUser.Id);

            //Verify results
            System.Assert.isNotNull(dataResult, 'Approval Data Exist');

            //Test getSObjectSet Method
            List<ProcessInstanceWorkitem> testWorkItems = [
                SELECT ActorId, ElapsedTimeInDays, ProcessInstanceId   
                FROM ProcessInstanceWorkItem 
                WHERE ActorId = :testUser.Id
                WITH USER_MODE
            ];

            Set<String> testSet = GetProcessInstanceData.getSObjectSet(testWorkItems, 'ProcessInstanceId');
            System.Assert.isNotNull(testSet, 'getSObjectSet Data Exist');

            Test.stopTest();
    }
}