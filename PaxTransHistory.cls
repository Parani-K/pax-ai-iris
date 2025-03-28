Class SQLClass.PaxTransHistory Extends (%Persistent, %Populate)
{

Property AccountID As %String;

Property TransAmount As %Integer(MAXVAL = 100000, MINVAL = 10000);

Property TransType As %Integer(MAXVAL = 2, MINVAL = 0);

Property TransTimestamp As %Library.TimeStamp(MAXVAL = "2025-04-30 23:59:59", MINVAL = "2021-01-01 00:00:00");

Property TransID As %String(MAXLEN = 32);

Property City As %String(MAXLEN = 25);

Property State As %String(MAXLEN = 25);

Property Country As %String(MAXLEN = 25);

Property LocationCode As %String(MAXLEN = 3);

Property YearWeekNo As %String [ Calculated, SqlComputeCode = {Set {*}=##class(SQLClass.PaxUtil).convertWeekYear({TransTimestamp})}, SqlComputed ];

Index IdxStateTypeYYYWK On (State, TransType, YearWeekNo);

ClassMethod anomalyDetection(inpDate As %String, debug As %Integer = 1)
{
    Do ##class(SQLClass.PaxUtil).configureData(.State, .YearWeekNo, inpDate)

    Write:debug !!,"ANOMALIES IDENTIFIED IN WEEKLY RUN ON WK#"_$P(YearWeekNo,"-",2)_" ("_+YearWeekNo_")",!
    Write:debug "---------------------------------------------------",!
    
    Set transTypes(0)="Withdrawal",transTypes(1)="Deposit",transTypes(2)="Transfer"
    
    For transType=0:1:2 {
        Set State="" For {
            Set State=$o(State(State))
            Quit:State=""

            &SQL(SELECT SUM(TransAmount) into :Amounts from SQLClass.PaxTransHistory WHERE STATE=:State and TransType=:transType and YearWeekNo=:YearWeekNo)
            Set:SQLCODE Amounts=0       

            Set sqlQry = "SELECT SUM(transAmount) as value,YearWeekNo as yearweekno from SQLClass.PaxTransHistory WHERE STATE='"_State_"' and TransType="_transType_" group by YearWeekNo"
            Continue:'##class(SQLClass.PaxUtil).pyFindAnomaly(sqlQry,State,Amounts,transType,YearWeekNo,"KNN")
            Continue:'##class(SQLClass.PaxUtil).pyFindAnomaly(sqlQry,State,Amounts,transType,YearWeekNo,"IFOREST")       //combine both 
            Set sqlQry = "SELECT SUM(transAmount) as value from SQLClass.PaxTransHistory WHERE STATE='"_State_"' and TransType="_transType_" group by YearWeekNo"
            Continue:'##class(SQLClass.PaxUtil).pyFindAnomaly(sqlQry,State,Amounts,transType,YearWeekNo,"LOF")       //combine both 
           
            Write:debug $J(transTypes(transType)_" at "_State(State)_"(ATM-Code:"_State_$a(State)_$a(State,2)_$a(State,3)_")  Amount : ",100)_+Amounts,!
            If debug 
            {
                Do ##Class(SQLClass.PaxUtil).getPastTransData(State,transType,YearWeekNo,.resPast) 
                Write $J("This year's avg   : ",100)_resPast("avgYear"),!
                Write $J("Last 4 week's Avg : ",100)_resPast("last4Week"),!
                Write $J("Last Week   : ",100)_resPast("lastWeek"),!
                Write $J("Last Year's Same week   : ",100)_resPast("lastYear"),!
            }
            
        }
    }
}

Storage Default
{
<Data name="PaxTransHistoryDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>AccountID</Value>
</Value>
<Value name="3">
<Value>TransAmount</Value>
</Value>
<Value name="4">
<Value>TransType</Value>
</Value>
<Value name="5">
<Value>TransTimestamp</Value>
</Value>
<Value name="6">
<Value>TransID</Value>
</Value>
<Value name="7">
<Value>City</Value>
</Value>
<Value name="8">
<Value>State</Value>
</Value>
<Value name="9">
<Value>Country</Value>
</Value>
<Value name="10">
<Value>LocationCode</Value>
</Value>
</Data>
<DataLocation>^SQLClass.PaxTransHistoryD</DataLocation>
<DefaultData>PaxTransHistoryDefaultData</DefaultData>
<IdLocation>^SQLClass.PaxTransHistoryD</IdLocation>
<IndexLocation>^SQLClass.PaxTransHistoryI</IndexLocation>
<StreamLocation>^SQLClass.PaxTransHistoryS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
