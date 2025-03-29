Class SQLClass.PaxContainersHistory Extends (%Persistent, %Populate)
{

Property MoveTimestamp As %Library.TimeStamp(MAXVAL = "2025-03-31 23:59:59", MINVAL = "2021-01-01 00:00:00");

Property LocationCode As %String(MAXLEN = 3);

Property Country As %String(MAXLEN = 255);

Property ContainerType As %String(MAXLEN = 100);

Property ContainerGateType As %Boolean;

Property Units As %Integer(MAXVAL = 9000, MINVAL = 1000);

Property YearWeekNo As %String [ Calculated, SqlComputeCode = {Set {*}=##class(SQLClass.PaxUtil).convertWeekYear({MoveTimestamp})}, SqlComputed ];

Index IdxStateTypeYYYWK On (LocationCode, ContainerGateType, YearWeekNo);

ClassMethod anomalyDetection(inpDate As %String, debug As %Integer = 1)
{
    Do ##class(SQLClass.PaxUtil).configureData(.State, .YearWeekNo, inpDate)
   
    Write:debug !!,"ANOMALIES IDENTIFIED IN WEEKLY RUN ON WEEK#"_$P(YearWeekNo,"-",2)_" ("_+YearWeekNo_")",!
    Write:debug "----------------------------------------------------------",!
    
    Set CgiCgo(0)="Container Gate-Out"
    Set CgiCgo(1)="Container Gate-In"
    
    For CgiCgo=0:1:1 {      
        Set State="" For {
            Set State=$ORDER(State(State))
            Quit:State=""
            
            &sql(SELECT SUM(Units) into :Units from SQLClass.PaxContainersHistory WHERE LocationCode=:State and ContainerGateType=:CgiCgo and  YearWeekNo=:YearWeekNo)
            Set:SQLCODE Units=0       
            // w +Units,!
            Set sqlQry = "SELECT SUM(Units) as value,YearWeekNo As yearweekno from SQLClass.PaxContainersHistory WHERE LocationCode='"_State_"' and ContainerGateType="_CgiCgo_" group by YearWeekNo"
            Continue:'##class(SQLClass.PaxUtil).pyFindAnomaly(sqlQry,State,Units,CgiCgo,YearWeekNo,"KNN")
            // w sqlQry,!
            Continue:'##class(SQLClass.PaxUtil).pyFindAnomaly(sqlQry,State,Units,CgiCgo,YearWeekNo,"IFOREST")
            Set sqlQry = "SELECT SUM(Units) as value from SQLClass.PaxContainersHistory WHERE LocationCode='"_State_"' and ContainerGateType="_CgiCgo_" group by YearWeekNo"
            Continue:'##class(SQLClass.PaxUtil).pyFindAnomaly(sqlQry,State,Units,CgiCgo,YearWeekNo,"LOF")

            Write:debug $J(CgiCgo(CgiCgo)_" at "_State(State)_"("_State_")  Units : ",100)_+Units,! 
            If debug {
                Do ##Class(SQLClass.PaxUtil).getPastMoveData(State,CgiCgo,YearWeekNo, .resPast) 
               Write $J("This year's avg   : ",100)_resPast("avgYear"),!
                Write $J("Previous 4 week's Avg : ",100)_resPast("last4Week"),!
                Write $J("Previous Week   : ",100)_resPast("lastWeek"),!
                Write $J("Previous Year's Same week   : ",100)_resPast("lastYear"),!
            }           
        }
}
}

Storage Default
{
<Data name="PaxContainersHistoryDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>MoveTimestamp</Value>
</Value>
<Value name="3">
<Value>LocationCode</Value>
</Value>
<Value name="4">
<Value>Country</Value>
</Value>
<Value name="5">
<Value>ContainerType</Value>
</Value>
<Value name="6">
<Value>ContainerGateType</Value>
</Value>
<Value name="7">
<Value>Units</Value>
</Value>
</Data>
<DataLocation>^SQLClass.PaxContainersHistoryD</DataLocation>
<DefaultData>PaxContainersHistoryDefaultData</DefaultData>
<IdLocation>^SQLClass.PaxContainersHistoryD</IdLocation>
<IndexLocation>^SQLClass.PaxContainersHistoryI</IndexLocation>
<StreamLocation>^SQLClass.PaxContainersHistoryS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
