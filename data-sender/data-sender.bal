import ballerina/config;
import ballerina/log;
import wso2/gsheets4;
import wso2/gmail;
import ballerina/http;
import ballerina/io;
import wso2/twitter;
import  ballerina/time;
import ballerina/task;
import ballerina/math;
import ballerina/runtime;
import ballerina/mysql;
import wso2/twilio;


documentation{A valid access token with gmail and google sheets access.}
string accessToken = config:getAsString("ACCESS_TOKEN");

documentation{The client ID for your application.}
string clientId = config:getAsString("CLIENT_ID");

documentation{The client secret for your application.}
string clientSecret = config:getAsString("CLIENT_SECRET");

documentation{A valid refreshToken with gmail and google sheets access.}
string refreshToken = config:getAsString("REFRESH_TOKEN");

documentation{Spreadsheet id of the reference google sheet.}
string spreadsheetId = config:getAsString("SPREADSHEET_ID");

documentation{Sheet name of the reference googlle sheet.}
string sheetName = config:getAsString("SHEET_NAME");

documentation{Sender email address.}
string senderEmail = config:getAsString("SENDER");

documentation{The user's email address.}
string userId = config:getAsString("USER_ID");

task:Timer? timer;

documentation{
    Google Sheets client endpoint declaration with http client configurations.
}

endpoint gsheets4:Client spreadsheetClient {
    clientConfig: {
        auth: {
            accessToken: accessToken,
            refreshToken: refreshToken,
            clientId: clientId,
            clientSecret: clientSecret
        }
    }
};


documentation{
    GMail client endpoint declaration with oAuth2 client configurations.
}


endpoint gmail:Client gmailClient {
    clientConfig: {
        auth: {
            accessToken: accessToken,
            refreshToken: refreshToken,
            clientId: clientId,
            clientSecret: clientSecret
        }
    }
};


endpoint twilio:Client twilioClient {
    accountSId:"ACb7d09bb826d549983830c8f108fb2ec3",
    authToken:"fae6a25d574c9b9b3f99c41a09910c4f",
    xAuthyKey:""
};

function main(string... args) {
    sendAcknowledgement();


    (function() returns error?) onTriggerFunction = scheduler;
    function(error) onErrorFunction = cleanupError;
    timer = new task:Timer(onTriggerFunction, onErrorFunction,
        1000, delay = 500);
    timer.start();

    runtime:sleep(3000);

}
boolean flag_secondmail=false;

function scheduler() returns error? {
    secondScheduledMessage();

    if (flag_secondmail) {

        io:println("timer is stopping");
        timer.stop();
    }
    return ();
}


function cleanupError(error e) {
    io:print("[ERROR] sending notification");
    io:println(e);
}



documentation{
    Send notification to the customers.
}




function sendAcknowledgement() {

        //Retrieve the customer details from spreadsheet.
        string[][] values = getCustomerDetailsFromGSheet();
        int i = 0;
        //Iterate through each customer details and send customized email.
        foreach value in values {


            var spreadsheetRes3 = spreadsheetClient->getCellData(spreadsheetId,"","E",i+3);


            if (i > -1) {

                if (spreadsheetRes3==""){

                    var spreadsheetRes4 = spreadsheetClient->setCellData(spreadsheetId,"","E",i+3,"Acknowledgement mail");
                    match spreadsheetRes4 {
                        boolean isUpdated => io:println(isUpdated);
                        gsheets4:SpreadsheetError e => io:println(e);
                    }

                    time:Time time = time:currentTime();

                    var spreadsheetRes5 = spreadsheetClient->setCellData(spreadsheetId,"","F",i+3,time.toString());
                    match spreadsheetRes5 {
                        boolean isUpdated => io:println(isUpdated);
                        gsheets4:SpreadsheetError e => io:println(e);
                    }




                    string EmployeeName = value[0];
                    string Post = value[1];
                    string EmailAddress = value[2];
                    string ExpectedSkillSet = value[3];

                    string subject = "Thank You for applying for the position of  " + Post+ " and accepting our offer.";

                    sendMail(EmailAddress, subject, getCustomEmailTemplate(EmployeeName,Post,ExpectedSkillSet));
                    var details = twilioClient->sendSms("+15023531035","+94767882078","message sent");
                    match details {
                        twilio:SmsResponse smsResponse => io:println(smsResponse);

                        twilio:TwilioError twilioError => io:println(twilioError);
                    }

                    io:println("First scheduled mail for the user "+ EmployeeName+ " was sent");
                }



            }
            i = i + 1;
        }
}

int j=0;

function sendSecondMail() {



    string[][] values = getCustomerDetailsFromGSheet();
    int i = 0;
    foreach value in values {

        var spreadsheetRes_mailType = spreadsheetClient->getCellData(spreadsheetId,"","E",i+3);
        if (i > -1) {

            if (spreadsheetRes_mailType=="Acknowledgement mail"){

                string EmployeeName = value[0];
                string Post = value[1];
                string EmailAddress = value[2];
                string ExpectedSkillSet = value[3];
                string time_secon=value[5];

                string s=time_secon.substring(17,19);
                io:println(" fetched time of "+ EmployeeName +" is" +s);


                var intResult = <int>s;
                match intResult {
                    int val => {
                        int l = val;
                        l=l+30;       //sending the second mail after 30 seconds.For demo time schdule is limited to 30 s.We can extend the time to days and months

                        if (l>59){

                            l=l-60;
                        }
                        time:Time time1 = time:currentTime();
                        int sec = time1.second();  //As the time delay is 30 seconds we get seconds for the comparision
                        io:println(" current time is "+sec);
                        if(sec>l){

                            var spreadsheetRes_mailtype2 = spreadsheetClient->setCellData(spreadsheetId, "", "E", i + 3,
                                "TechnicalInstructionmail");
                            match spreadsheetRes_mailtype2 {
                                boolean isUpdated => io:println(isUpdated);
                                gsheets4:SpreadsheetError e => io:println(e);
                            }

                            time:Time time = time:currentTime();

                            var spreadsheetRes9 = spreadsheetClient->setCellData(spreadsheetId, "", "F", i + 3, time.toString());
                            match spreadsheetRes9 {
                                boolean isUpdated => io:println(isUpdated);
                                gsheets4:SpreadsheetError e => io:println(e);
                            }
                            log:printInfo("Time updated at spreadsheet");


                            string subject = "It has been a quite a bit that you are started to workout for the post of  " + Post +
                                " and accepting our offer.";
                            sendMail(EmailAddress, subject, getCustomEmailTemplate(EmployeeName, Post, ExpectedSkillSet));
                            io:println("Second scheduled mail for the user "+ EmployeeName+ " was sent");
                            flag_secondmail=true;
                            j=j+1;

                            var details = twilioClient->sendSms("+15023531035","+94767882078","message sent");
                            match details {
                                twilio:SmsResponse smsResponse => io:println(smsResponse);

                                twilio:TwilioError twilioError => io:println(twilioError);
                            }




                        }

                    }
                    error err => {
                        io:println("error: " + err.message);
                    }
                }











            }
        }
        i = i + 1;
    }





}



function secondScheduledMessage(){

    string[][] values = getCustomerDetailsFromGSheet();
    var spreadsheetRes_employee = spreadsheetClient->getColumnData(spreadsheetId,"","A");



    io:println(spreadsheetRes_employee);


    while(j<4){                          //to rn the prograamme continuosly untill all the scheduled messages are sent.

        sendSecondMail();
    }

}


function getCustomerDetailsFromGSheet() returns (string[][]) {
    //Read all the values from the sheet.
    string[][] values = check spreadsheetClient->getSheetValues(spreadsheetId,"", "A3", "F6");

    return values;
}


function getCustomEmailTemplate(string EmployeeName, string Post,string ExpectedSkillSet) returns (string) {
    string emailTemplate = "<h2> Hi " + EmployeeName + " </h2>";
    emailTemplate = emailTemplate + "<h3> Thank you for applying for the post of  " + Post + " ! </h3>";
    emailTemplate = emailTemplate + "<p> If you still have questions regarding this position of " + Post +
        ", please contact us and we will get in touch with you right away ! </p> ";
    emailTemplate = emailTemplate + "<p> You are required to have these skills of  " + ExpectedSkillSet +
        ". Hope you all work on it ! </p> ";


    return emailTemplate;
}


function sendMail(string EmailAddress, string subject, string messageBody) {
    //Create html message
    gmail:MessageRequest messageRequest;
    messageRequest.recipient = EmailAddress;
    messageRequest.sender = senderEmail;
    messageRequest.subject = subject;
    messageRequest.messageBody = messageBody;
    messageRequest.contentType = gmail:TEXT_HTML;

    //Send mail
    var sendMessageResponse = gmailClient->sendMessage(userId, untaint messageRequest);
    string messageId;
    string threadId;
    match sendMessageResponse {
        (string, string) sendStatus => {
            (messageId, threadId) = sendStatus;
            log:printInfo("Sent email to " + EmailAddress + " with message Id: " + messageId + " and thread Id:"
                    + threadId);
        }
        gmail:GmailError e => log:printInfo(e.message);
    }

}




