global class JIRACaseExtension {
    private ApexPages.StandardController cont;
//    private final JIRAClientClouds__c jcc;
    public JIRAIssues jIssues {get;set;}
    public JIRACXField.JIRAField[] jfields;
    public ID caseId {get;set;}
    private Case sfCase {get; set;}

    public ID getCaseId(){ return this.caseId;}
    public void setCaseId(String inId) {this.caseId = inId;}
    
//    public JIRAIssues getJIssues(){ return this.jIssues;}
//    public void setJIssues(JIRAIssues ji) { this.jIssues = ji;}
    
    @RemoteAction
    global static PageReference refresh() {
       system.debug('in the refresh method');
       return null;
    }
    
    public PageReference returnURL {
        get;
        // *** setter is NOT being called ***
        set {
            returnURL = value;
            System.debug('value: '+value);
        }
    }
    
    
     // Constructor of this class. Note that a request will be sent to JIRA when this class is constructed.
    global JIRACaseExtension(ApexPages.StandardController stdController) {
        cont = stdController;
        sfCase = (Case)stdController.getRecord();
        System.debug('case is ' + sfCase.id);

    }

  //  global JIRACaseExtension(JIRACXIssueController caseController) {
   // }
    
    public PageReference loadCaseIssues() {
        String theCaseId;
        if(cont != null){
            theCaseId = ((Case)cont.getRecord()).id;
            theCaseId = theCaseId.Left(15);
        }else
            theCaseId = ApexPages.currentPage().getParameters().get('id');
        
       system.debug('the case is ' + theCaseId);
       sfCase = [SELECT id from Case where id = :theCaseId];
       
        if(sfCase != null){
            // do the remote login to JIRA
            JIRALogin jl = new JIRALogin();
            //jl.getAllProjects();
            
            system.debug('get the case JIRAs for ' + sfCase.Id);
            JIRACXIssue__c[] Objissues = jl.getJIRAbyCase(theCaseId);  // using the 15 character Id for ease of using the URL
            //updateAllIssues(Objissues);
            jIssues = new JIRAIssues();

            system.debug('Case referenced in ' + Objissues.size() + ' JIRAs');
            system.debug('Case Id is ' + theCaseId);
//            List<JIRACXIssue__c> sfIssues = [SELECT id, Account_Info__c, Actual_Behavior__c,Actual_Result__c,Affected_Customers__c,Affected_UI__c,Priority__c,
//                                            JIRACreated__c,description__c,Resolution__c,Summary__c,JIRAStatus__c,JIRAProject__c,JIRAUpdated__c,Assignee__c FROM JIRACXIssue__c WHERE Case_Numbers__c  like '%:theCaseId%'];
            List<JIRACXIssue__c> sfIssues = Database.query('SELECT id, name, JIRAKey__c, Case_numbers__c, Account_Info__c, Actual_Behavior__c,Actual_Result__c,Affected_Customers__c,Affected_UI__c,Priority__c, JIRACreated__c,description__c,Resolution__c,Summary__c,JIRAStatus__c,JIRAProject__c,JIRAUpdated__c,Assignee__c, Root_Cause_Analysis_Requested__c, (SELECT Author__c,JIRACreatedDate__c,body__c FROM JIRACXIssueComments__r ),(SELECT id,useChatter__c, useEmail__c, SFUsers__r.name, createddate FROM JIRA_Watchers__r) FROM JIRACXIssue__c WHERE Case_Numbers__c = :theCaseId');

			

			system.debug('sfIssues contains ' + sfIssues.size() + ' issues');
            for(JIRACXIssue__c ji : sfIssues) {
                if(ji != null){
                    jIssues.issues.add(new JIRACXIssueWrapper(ji, true));
                    
                    //system.debug('adding item to issues list');
                }
            }
            system.debug('SF has ' + jIssues.issues.size() + ' JIRAs related');
            //jfields = jl.getJIRAFields();
            
            try{
                //updateAllIssues();
    //            jl.getAllSerSolProjects();
           //     jl.getAllPQProjects();
            }
            catch(Exception ex) {
                System.Debug('Failed SerSol Test');
                System.debug(ex.getMessage());
            }    
        //jl.testAJIRAQuery('issue/createmeta?projectKeys=PUB&issuetypeIds=10102&expand=project.issuetypes.fields');
        }
		return null;
    }
      
    public  PageReference updateAllIssues(List<JIRACXIssue__c> updIssues) {
       system.debug('in updateAllIssues method');
        //List<JIRACXIssue__c> updIssues = new List<JIRACXIssue__c>();
        if(updIssues != null ){
//            for(JIRACXIssueWrapper jw : jIssues.issues){
//                if(jw != null){
/*            for(JIRACXIssue__c issue : updIssa)
                    JIRACXIssue__c ji = jw.getIssue();
                    system.debug('saving JIRA ' + ji.JIRAKey__c);
                    updIssues.add(ji);
                }
            }
*/            
            upsert updIssues JIRACXIssue__c.Fields.JIRAKey__c;
        }        
        return null;
    }

          
    // this doesn't belong here, just using for dev testing
    @RemoteAction
    global static boolean updateCaseJiras(){
       system.debug('in updateAllIssues method - ');
        JIRAIntegration__c jInt = JIRAIntegration__c.getInstance();
		DateTime lastUpdate = jInt.lastIssueRefreshAll__c;
        
        if(lastUpdate == null || lastUpdate > DateTime.now())
            lastUpdate = DateTime.now().addMinutes(-10);
        // do the remote login to JIRA
        JIRALogin jl = new JIRALogin();
        if(jl != null){
	        system.debug('updating all the JIRAs');
	        jl.getAllUpdateIssues(lastUpdate);
   
            // if updating the last update time:
            system.debug('saving lastUpdate - '+ lastUpdate);
            List<JIRAIntegration__c> updJInt = [Select Id, lastIssueRefreshAll__c From JIRAIntegration__c ]; 
            if(updJint.size() == 0){
                JIRAIntegration__c newJInt = new JIRAIntegration__c();
                newJInt.lastIssueRefreshAll__c = lastUpdate;
                insert newJInt;
            }else if (updJint.size() == 1) {
                updJInt[0].lastIssueRefreshAll__c = lastUpdate;
                update updJInt;
            }else{
                for(integer i=0; i<updJInt.size();i++)
                    updJInt[i].lastIssueRefreshAll__c = lastUpdate;
                update updJInt;                
            }
        }
        
        return true;
    }
}