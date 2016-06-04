GLOBAL class JIRALogin {
	public String baseurl = 'https://jira.proquest.com/';
	//public String baseurl = 'https://lynch22.atlassian.net/';
    
    String oauthToken = null;

    public void checkCreds(){
        http h = new http();
        HttpRequest req = new HttpRequest();
        req.setEndPoint(baseurl + 'rest/api/2/project');
        req.setMethod('GET');
        
        HttpResponse res = h.send(req);
        
        System.debug('Dumping response' + res.getBody());
    }

    public void doLogin(){
        http h = new http();
        HttpRequest req = new HttpRequest();
        req.setEndPoint(baseurl + 'jira/rest/auth/1/session');
        req.setMethod('POST');
         req.setHeader('Accept', 'application/json');    
         req.setHeader('Content-Type', 'application/json');
         req.setHeader('Authorization','Basic a2VuYWx5bmNoOnBhc3MxMjM0');    
        
        req.setBody('username='+JIRA.username+'&password='+JIRA.password);
       
        HttpResponse res = h.send(req);
        
        System.debug('Dumping response' + res.getBody());
//        return res.getBody();
    }

    public void getPermissions(){
        http h = new http();
        HttpRequest req = new HttpRequest();
        req.setEndPoint(baseurl + 'rest/api/2/mypermissions');
        req.setMethod('GET');
         req.setHeader('Accept', 'application/json');    
         req.setHeader('Content-Type', 'application/json');
         req.setHeader('Authorization','Basic a2VuYWx5bmNoOnBhc3MxMjM0');    
        
        HttpResponse res = h.send(req);
        
        System.debug('Dumping response' + res.getBody());
//        return res.getBody();
    }

   public void testAJIRAQuery(String tstQry){
        // - http://localhost:8090/rest/api/2/issue/createmeta?projectKeys=KEY&issuetypeIds=1&expand=project.issuetypes.fields        
        http h = new http();
        HttpRequest req = new HttpRequest();
        req.setEndPoint(baseurl + 'rest/api/2/' + tstQry);
        
         req.setMethod('GET');
         req.setHeader('Accept', 'application/json');    
         req.setHeader('Content-Type', 'application/json');
         
         String useCreds = getEncodedCreds();
         
         req.setHeader('Authorization','Basic ' + useCreds);    

         System.debug('My creds: a2VuYWx5bmNoOnBhc3MxMjM0 and Calced Creds: ' + useCreds);
       
        HttpResponse res = h.send(req);
        System.debug('Dumping response' + res.getBody());
   }

    public void getAllProjects(){
        http h = new http();
        HttpRequest req = new HttpRequest();
        req.setEndPoint(baseurl + 'rest/api/2/project');
        req.setMethod('GET');
         req.setHeader('Accept', 'application/json');    
         req.setHeader('Content-Type', 'application/json');
         
         String useCreds = getEncodedCreds();
         
         req.setHeader('Authorization','Basic ' + useCreds);    

         System.debug('My creds: a2VuYWx5bmNoOnBhc3MxMjM0 and Calced Creds: ' + useCreds);

        HttpResponse res = h.send(req);
        
        System.debug('Dumping response' + res.getBody());
        
        List<JIRA.JIRAProject> projs = (List<JIRA.JIRAProject>) JSON.deserialize(res.getBody(), List<JIRA.JIRAProject>.class);
        if(projs.size() > 0){
            for (JIRA.JIRAProject p : projs){
                System.debug('project name = ' + p.getName());
            }
        }
    }
    
    public DateTime getAllUpdateIssues(integer lastNMinutes){
        DateTime updTime = DateTime.now().addMinutes(lastNMinutes * -1);
		return getAllUpdateIssues(updTime);
    }

    public DateTime getAllUpdateIssues(DateTime lastUpdate){
        String updDateFormatted = lastUpdate.format('yyyy/mm/dd hh:mm');
        DateTime newLastUpdate=DateTime.now();
        JIRACXIssue__c[] ji = null;
        http h = new http();
        HttpRequest req = new HttpRequest();
        req.setEndPoint(baseurl + 'rest/api/2/search?jql=update>='+updDateFormatted+'&fields=id,self,key,assignee,resolution,summary,description,updated,status,project');
        
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');    
        req.setHeader('Content-Type', 'application/json');
         
        String useCreds = getEncodedCreds();
         
        req.setHeader('Authorization','Basic ' + useCreds);    

        System.debug('My creds: a2VuYWx5bmNoOnBhc3MxMjM0 and Calced Creds: ' + useCreds);

        HttpResponse res = h.send(req);
        
        System.debug('Dumping response' + res.getBody());
        String jBody = res.getBody().replace('\n', '');
        
        try{
            JIRA.JIRAIssueResponse jir = (JIRA.JIRAIssueResponse)JSON.deserialize(jBody, JIRA.JIRAIssueResponse.class);
            // what do we have?
            if(jir == null) { system.debug('Failed to parse the Issue Response');}
            else {
                if(jir.issues == null || jir.issues.size() == 0) { system.debug('Parse did not produce issues');}
                else{
                    system.debug('jir issues count = '+ jir.issues.size());
                    if(jir.issues[0].fields == null){
                        system.debug('parse did not find fields in the issue');
                    }else{
                        if(jir.issues[0].fields.assignee != null){ 	
	                        system.debug('assignee: ' + jir.issues[0].fields.assignee.displayName);
                        }
                    }
                }
            }
            if(jir != null){
                system.debug('expand: ' + jir.expand);
                for(JIRA.JIRAIssue i: jir.issues){
                    System.debug('Issue: ' + i.key);
                }
                ji = createCXIssues(jir,'','');
                
                updateJIRACXIssues(ji);
            }
        }
        catch(Exception ex) {
            system.debug(ex.getMessage());
            newLastUpdate = lastUpdate;
        }
        return newLastUpdate;
    }
    
    public boolean updateJIRACXIssues(JIRACXIssue__c[] upds) {
        boolean updStatus = false;
        if(upds.size() > 0){
            upsert upds JIRACXIssue__c.Fields.JIRAKey__c;
			updStatus = true;
        }else{
            updstatus = true;
        }
        return updStatus;
    }
    
    public void getAllSerSolProjects(){
        http h = new http();
        HttpRequest req = new HttpRequest();
        req.setEndPoint('https://jira.sersol.lib/rest/api/2/project');
        req.setMethod('GET');
         req.setHeader('Accept', 'application/json');    
         req.setHeader('Content-Type', 'application/json');
         
         String useCreds = getSerSolEncodedCreds();
         
         req.setHeader('Authorization','Basic ' + useCreds);    

         System.debug('My creds: a2VuYWx5bmNoOnBhc3MxMjM0 and Calced Creds: ' + useCreds);
       
        HttpResponse res = h.send(req);
        
        System.debug('Dumping response' + res.getBody());
        
        List<JIRA.JIRAProject> projs = (List<JIRA.JIRAProject>) JSON.deserialize(res.getBody(), List<JIRA.JIRAProject>.class);
        if(projs.size() > 0){
            for (JIRA.JIRAProject p : projs){
                System.debug('project name = ' + p.getName());
            }
        }
        
//        return res.getBody();
    }

     public void getAllPQProjects(){
        http h = new http();
        HttpRequest req = new HttpRequest();
        req.setEndPoint('https://jira.proquest.com/rest/api/2/project');
        req.setMethod('GET');
         req.setHeader('Accept', 'application/json');    
         req.setHeader('Content-Type', 'application/json');
         
         String useCreds = getPQEncodedCreds();
         
         req.setHeader('Authorization','Basic ' + useCreds);    

         System.debug('My creds: a2VuYWx5bmNoOnBhc3MxMjM0 and Calced Creds: ' + useCreds);
       
        HttpResponse res = h.send(req);
        
        System.debug('Dumping response' + res.getBody());
        
        List<JIRA.JIRAProject> projs = (List<JIRA.JIRAProject>) JSON.deserialize(res.getBody(), List<JIRA.JIRAProject>.class);
        if(projs.size() > 0){
            for (JIRA.JIRAProject p : projs){
                System.debug('project name = ' + p.getName());
            }
        }
        
//        return res.getBody();
    }


    public JIRACXIssue__c[] getJIRAbyCase(String CaseId){
        JIRACXIssue__c[] ji = null;
        JIRACXIssueComment__c[] jiraComments;
        http h = new http();
        HttpRequest req = new HttpRequest();
//        req.setEndPoint(baseurl + 'rest/api/2/search?jql=assignee='+assignee+'&fields=id,self,key,');
//        req.setEndPoint(baseurl + 'rest/api/2/search?jql=key='+'GMS-4606'+'&fields=id,self,key,assignee,Created,updated,status,resolution');
//        req.setEndPoint(baseurl + 'rest/api/2/search?jql=description~'+'50056000002FVUu'+'&fields=id,self,key,assignee,Created,updated,status,resolution');
        req.setEndPoint(baseurl + 'rest/api/2/search?jql=description~'+CaseId+'&fields=id,self,key,assignee,resolution,summary,description,updated,status,project');
//        req.setEndPoint(baseurl + 'rest/api/2/search?jql=description~'+CaseId+'&fields=id,self,key,resolution');
        
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');    
        req.setHeader('Content-Type', 'application/json');
         
        String useCreds = getEncodedCreds();
         
        req.setHeader('Authorization','Basic ' + useCreds);    

         System.debug('My creds: a2VuYWx5bmNoOnBhc3MxMjM0 and Calced Creds: ' + useCreds);

        HttpResponse res = h.send(req);
        
        System.debug('Dumping response' + res.getBody());
        String jBody = res.getBody().replace('\n', '');
        
        try{
     //       JSONObject jobj = new JSONObject(json);
            JIRA.JIRAIssueResponse jir = (JIRA.JIRAIssueResponse)JSON.deserialize(jBody, JIRA.JIRAIssueResponse.class);
            // what do we have?
            if(jir == null) { system.debug('Failed to parse the Issue Response');}
            else {
                if(jir.issues == null || jir.issues.size() == 0) { system.debug('Parse did not produce issues');}
                else{
                    system.debug('jir issues count = '+ jir.issues.size());
                    if(jir.issues[0].fields == null){
                        system.debug('parse did not find fields in the issue');
                    }else{
                        if(jir.issues[0].fields.assignee != null){ 	
	                        system.debug('assignee: ' + jir.issues[0].fields.assignee.displayName);
                        }
                    }
                }
            }
            
            if(jir != null){
                system.debug('expand: ' + jir.expand);
                for(JIRA.JIRAIssue i: jir.issues){
                    System.debug('Issue: ' + i.key);
                }
                ji = createCXIssues(jir, 'CASE', caseId);
				
                system.debug('ji count = ' + ji.size());
                jiraComments = new List<JIRACXIssueComment__c>();
          	    for(JIRACXIssue__c j : ji){
			        // before return, get the comments
                    if (j != null){
                       system.debug('getting comments for ' + j.JIRAKey__c);
                       JIRACXIssueComment__c[] tmpList = getJIRAComments(j);
                        
                       if(tmpList != null && tmpList.size() > 0)
                           jiraComments.addAll(tmpList);
                       else
                           system.debug('getJIRAComments didn\'t produce any records');
                    }else system.debug('j is null');
                }
                System.debug('jiraComments count = ' + jiraComments.size());
                
                updateAllIssues(ji);
                
          	    for(JIRACXIssue__c j : ji){
			        // before return, get the comments
	               updateJIRAIDs(jiraComments, j);
                }
                
                if(jiraComments.size() > 0)	{ 
                    system.debug('doing the comment upsert for ' + jiraComments.size());
                    upsert jiraComments JIRACXIssueComment__c.Fields.JIRAID__c;
                }
            }
        }
        catch(Exception ex) {
            system.debug(ex.getMessage());
        }
        return ji;
    }

    public void updateJIRAIDs(JIRACXIssueComment__c[] jics, JIRACXIssue__c j){
        for(JIRACXIssueComment__c jic : jics ){
            if(jic.JIRAKey__c == j.JIRAKey__c) {
                system.debug('setting JIRAIssue__c -> ' + j.id);
                jic.JIRAIssue__c = j.id;
            }
        }
    
    }
    
    public void updateAllIssues(List<JIRACXIssue__c> updIssues) {
       system.debug('in updateAllIssues method');
        //List<JIRACXIssue__c> updIssues = new List<JIRACXIssue__c>();
        if(updIssues != null ){
            upsert updIssues JIRACXIssue__c.Fields.JIRAKey__c;
        }        
    }

    public JIRACXIssueComment__c[] getJIRAComments(JIRACXIssue__c JIRAIssue){
        JIRACXIssueComment__c[] jiraComments;
        http h = new http();
        HttpRequest req = new HttpRequest();
        req.setEndPoint(baseurl + 'rest/api/2/issue/' + JIRAIssue.JIRAKey__c + '/comment');
        
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');    
        req.setHeader('Content-Type', 'application/json');
         
        String useCreds = getEncodedCreds();
         
        req.setHeader('Authorization','Basic ' + useCreds);    

         System.debug('My creds: a2VuYWx5bmNoOnBhc3MxMjM0 and Calced Creds: ' + useCreds);

        HttpResponse res = h.send(req);
        
        System.debug('Dumping response' + res.getBody());
        String jBody = res.getBody().replace('\n', '');
     
        try{
     		JIRA.IssueCommentResponse icr = (JIRA.IssueCommentResponse)JSON.deserialize(jBody, JIRA.IssueCommentResponse.class);
            // what do we have?
            if(icr == null) { system.debug('Failed to parse the Issue Comments');}
            else {
                if(icr.comments == null || icr.comments.size() == 0) { system.debug('Parse did not produce comments');}
                else{
                    system.debug('icr comment count = '+ icr.Comments.size());
                    for(JIRA.IssueComment ic: icr.comments){
	                    system.debug('comment: ' + ic.body);
                    }
                    // update the comments sobject in Salesforce
                    jiraComments = createCXIssueComments(icr, JIRAIssue);
                }
            }
        }
        
        catch(Exception ex) {
            system.debug(ex.getMessage());
        }
        system.debug('returning jiraComments with ' + jiraComments.size());
        return jiraComments;
    }

    public JIRACXIssue__c getJIRAByKey(String JIRAKey){
        JIRACXIssue__c[] ji = null;
        http h = new http();
        HttpRequest req = new HttpRequest();
        req.setEndPoint(baseurl + 'rest/api/2/search?jql=key='+JIRAKey+'&fields=id,self,key,assignee,resolution,summary,description,updated,status,project');
//        req.setEndPoint(baseurl + 'rest/api/2/search?jql=description~'+CaseId+'&fields=id,self,key,resolution');
        
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');    
        req.setHeader('Content-Type', 'application/json');
         
        String useCreds = getEncodedCreds();
         
        req.setHeader('Authorization','Basic ' + useCreds);    

         System.debug('My creds: a2VuYWx5bmNoOnBhc3MxMjM0 and Calced Creds: ' + useCreds);

        HttpResponse res = h.send(req);
        
        System.debug('Dumping response' + res.getBody());
        String jBody = res.getBody().replace('\n', '');
        
        try{
            JIRA.JIRAIssueResponse jir = (JIRA.JIRAIssueResponse)JSON.deserialize(jBody, JIRA.JIRAIssueResponse.class);
            // what do we have?
            if(jir == null) { system.debug('Failed to parse the Issue Response');}
            else {
                if(jir.issues == null || jir.issues.size() == 0) { system.debug('Parse did not produce issues');}
                else{
                    system.debug('jir issues count = '+ jir.issues.size());
                    if(jir.issues[0].fields == null){
                        system.debug('parse did not find fields in the issue');
                    }else{
                        if(jir.issues[0].fields.assignee != null){ 	
	                        system.debug('assignee: ' + jir.issues[0].fields.assignee.displayName);
                        }
                    }
                }
            }
            if(jir != null){
                ji = createCXIssues(jir,'','');
            }
        }
        catch(Exception ex) {
            system.debug(ex.getMessage());
        }
        if(ji.size() > 0){
            return ji[0];
        }
        else
        	return null;
    }
    
    
    
    public JIRACXField.JIRAField[] getJIRAFields(){
        JIRACXField.JIRAField[] jf = null;
        http h = new http();
        HttpRequest req = new HttpRequest();
        req.setEndPoint(baseurl + 'rest/api/2/field');
        
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');    
        req.setHeader('Content-Type', 'application/json');
         
        String useCreds = getEncodedCreds();
         
        req.setHeader('Authorization','Basic ' + useCreds);    

         System.debug('My creds: a2VuYWx5bmNoOnBhc3MxMjM0 and Calced Creds: ' + useCreds);

        HttpResponse res = h.send(req);
        
        System.debug('Dumping response' + res.getBody());
        String jBody = res.getBody().replace('\n', '');
        
        try{
     //       JSONObject jobj = new JSONObject(json);
            JIRA.JIRAFieldResponse jfr = (JIRA.JIRAFieldResponse)JSON.deserialize(jBody, JIRA.JIRAFieldResponse.class); 
            if(jfr != null){
                //system.debug('expand: ' + jir.expand);
                for(JIRACXField.JIRAField inJF: jfr.fields){
                    System.debug('field: ' + inJF.name);
                    jf.add(inJF);
                }
            }
        }
        catch(Exception ex) {
            system.debug(ex.getMessage());
        }
        return jf;
    }
  
    
    private JIRACXIssue__c[] createCXIssues(JIRA.JIRAIssueResponse jir,String qryType, String qryValue) {
        List<JIRACXIssue__c> retList = new List<JIRACXIssue__c>();
        for(JIRA.JIRAIssue ji : jir.issues) {
            system.debug('ji [key] - ' + ji.key);
            system.debug('ji [self] - ' + ji.self);
            system.debug('ji [id] - ' + ji.id);
            
            JIRACXIssue__c newJi = new JIRACXIssue__c();
            newJi.name = ji.key;
            newJi.JIRAKey__c = ji.key;
            newJi.JIRAId__c = ji.id;
            if(qryType == 'CASE'){
                system.debug('processing a Case qry');
                newji.Case_Numbers__c = qryValue;            
            }
            
        /*-----------------
         * SAMPLE DATA 
         */            
                newJi.Account_Info__c = 'fld1';
                newJi.Actual_Behavior__c = 'fld2';
                newJi.Actual_Result__c = 'fld3'   ;
                newJi.Affected_Customers__c = 'fld4';
                newJi.Affected_UI__c = 'fld5';
                newJi.Priority__c = 'P2-Major';
                newJi.JIRACreated__c = DateTime.newInstance(2015,6,23);
                newJi.description__c = 'This is an enhancement request to add another place for technicians to set themselves as “True” or available for round robin email assignment. Maybe this can be added to the same popup as LiveAgent. Or adding a button next to it on the cases screen.' ;
		/* END OF TEST DATA */
            if(ji != null){
                System.debug('ji key = '+ ji.key);
                System.debug('ji id = '+ ji.id);
                System.debug('ji self = '+ ji.self);
                if(ji.fields != null) {
                    
            		newJi.Resolution__c = ji.fields.resolution != null && ji.fields.resolution.name != null ? ji.fields.resolution.name : 'unknown';
            		newJi.Summary__c = ji.fields.summary;
                    
                    if(ji.fields.status != null && ji.fields.status.name != null) {
		                newJi.JIRAStatus__c = ji.fields.status.name;
                    }else{
                        newJi.JIRAStatus__c = 'unknown';
                    }

                    if(ji.fields.project != null && ji.fields.project.getName() != null) {
		                newJi.JIRAProject__c = ji.fields.project.getName();
                    }else{
                        newJi.JIRAProject__c = 'unknown';
                    }
                    
                    //                newJi.Priority__c = 'P2-Major';
//                newJi.JIRACreated__c = DateTime.newInstance(2015,6,23);
                    if(ji.fields.updated != null){
                        system.debug('Appying ' + ji.fields.updated + ' for updated datetime');
		                newJi.JIRAUpdated__c = convertJIRADate(ji.fields.updated);
                    }
                    if(ji.fields.assignee != null ){
                        if(ji.fields.assignee.displayName != null){
		                	newJi.Assignee__c = ji.fields.assignee.displayName;
                        }}else {
                        newJi.Assignee__c= 'unassigned';
                    }
                	newJi.description__c = ji.fields.description ;
                }
            }
               
            retList.add(newJi);
        }
        return retList;
    }
    
    private JIRACXIssueComment__c[] createCXIssueComments(JIRA.IssueCommentResponse icr, JIRACXIssue__c JIRAOwner) {
        JIRACXIssueComment__c[] retList = new List<JIRACXIssueComment__c>();
        for(JIRA.IssueComment ic : icr.comments) {
            system.debug('JIRA [key] - ' + JIRAOwner.JIRAkey__c);
            system.debug('ic [self] - ' + ic.self);
            system.debug('ic [id] - ' + ic.id);
            
            JIRACXIssueComment__c newIC = new JIRACXIssueComment__c();
            //newIC.JIRAIssue__c = JIRAOwner.id;
            system.debug('setting JIRAKey__c');
            newIC.JIRAKey__c = JIRAOwner.JIRAkey__c;
            system.debug('setting JIRAIssueID__c');
            newIC.JIRAIssueID__c = JIRAOwner.JIRAID__c;
                        
            system.debug('setting Author__c');
            newIC.Author__c = ic.author.getDisplayName();
            system.debug('setting UpdateAuthor__c');
            newIC.UpdateAuthor__c = ic.updateAuthor.getDisplayName();
            system.debug('setting body__c');
            newIC.body__c = ic.body;
            system.debug('setting JIRACreatedDate__c');
            newIC.JIRACreatedDate__c = convertJIRADate(ic.created);
            system.debug('setting JIRAUpdateDate__c');
            newIC.JIRAUpdateDate__c = convertJIRADate(ic.updated);
            system.debug('setting JIRAID__c');
            newIC.JIRAID__c = ic.id;
               
            retList.add(newIC);
        }
        return retList;
    }

    public DateTime convertJIRADate(string inDateTime){
        Integer year, month, day, hour, minute,second,offset;
		DateTime retVal = Datetime.now();
        if(inDateTime.length() > 25){
            year = integer.valueof(inDateTime.substring(0, 4));
	       	month = integer.valueof(inDateTime.substring(5, 7));
	       	day = integer.valueof(inDateTime.substring(8, 10));
	       	hour = integer.valueof(inDateTime.substring(11, 13));
	       	minute = integer.valueof(inDateTime.substring(14, 16));
	       	second = integer.valueof(inDateTime.substring(17, 19));
	       	offset = integer.valueof(inDateTime.substring(23, 26));
			
            DateTime tmpDT = DateTime.newInstance(year, month, day, hour, minute, second);
            tmpDt = tmpDT.addHours(offset*-1);
            retVal = DateTime.newInstanceGMT(tmpDT.year(), tmpDT.Month(),tmpDT.day(),tmpDT.hour(),tmpDT.minute(),tmpDT.day());
        }
		return retVal;                         
    }
    
    public JIRAIssueWatcher[] getJIRAIssueWatchers(String JIRAIssueKey) {
        JIRAIssueWatcher[] jiw = null;
        http h = new http();
        HttpRequest req = new HttpRequest();
        req.setEndPoint(baseurl + 'rest/api/2/issue/' + JIRAIssueKey + '/watchers');
        
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');    
        req.setHeader('Content-Type', 'application/json');
         
        String useCreds = getEncodedCreds();
         
        req.setHeader('Authorization','Basic ' + useCreds);    

        System.debug('My creds: a2VuYWx5bmNoOnBhc3MxMjM0 and Calced Creds: ' + useCreds);
        HttpResponse res = h.send(req);
        
        System.debug('Dumping response' + res.getBody());
        String jBody = res.getBody().replace('\n', '');
        
        try{
            JIRA.IssueWatcherResponse iwr = (JIRA.IssueWatcherResponse)JSON.deserialize(jBody, JIRA.IssueWatcherResponse.class);
            if(iwr != null){
                system.debug('self: ' + iwr.self);
                for(JIRA.IssueUser w: iwr.watchers){
                    System.debug('Name: ' + w.name);
                }
                jiw = createCXIssueWatchers(iwr);
            }
        }
        catch(Exception ex) {
            system.debug(ex.getMessage());
        }
        return jiw;
    }
    
    private JIRAIssueWatcher[] createCXIssueWatchers(JIRA.IssueWatcherResponse iwr) {
        List<JIRAIssueWatcher> retList = new List<JIRAIssueWatcher>();
        for(JIRA.IssueUser iw : iwr.watchers) {
            JIRAIssueWatcher newJIW = new JIRAIssueWatcher();
            newJIW.setName(iw.name);
            newJIW.setDisplayName(iw.getDisplayName());
            retList.add(newJIW);
        }
        return retList;
    }
    
    public String getCalloutResponseContents(String url) {
        http h = new http();
        HttpRequest req = new HttpRequest();
        req.setEndPoint(url);
        req.setMethod('GET');
        
        HttpResponse res = h.send(req);
        return res.getBody();
    }
    
    public String getEncodedCreds(){
        String str = JIRA.username + ':' + JIRA.password;
        Blob blb = Blob.valueOf(str);
        
        return EncodingUtil.base64Encode(blb);
    }

    public String getSerSolEncodedCreds(){
        String str = JIRA.username_sersol + ':' + JIRA.password_sersol;
        Blob blb = Blob.valueOf(str);
        
        return EncodingUtil.base64Encode(blb);
    }

   public String getPQEncodedCreds(){
        String str = JIRA.username_pq + ':' + JIRA.password_pq;
        Blob blb = Blob.valueOf(str);
        return EncodingUtil.base64Encode(blb);
    }
}