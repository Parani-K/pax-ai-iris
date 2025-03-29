Class SQLClass.PaxUtil Extends %RegisteredObject
{

ClassMethod DataSetup(Flag As %Integer = 3)
{
    //Do ##class(SQLClass.PaxUtil).DataSetup()
    Do ..configureLocations(.State)

    If Flag'=1 {
        Write "Data setup - Containers History of 6 Ports from different locations (Logistics): ",!
        Do ..DataSetupForContainersLog(.State)
    }
    If Flag'=2 {
        Write "Data setup - Transactions history of 6 ATMs from different locations (Banking): ",!
        Do ..DataSetupForTransactionLog(.State)
    }
}

ClassMethod configureData(ByRef State As %String, ByRef YearWeekNo As %String, inpDate As %String)
{
    Do ..configureLocations(.State)
    Set:'inpDate inpDate=$ZDATE(+$HOROLOG-1,3)
    Set YearWeekNo=..convertWeekYear(inpDate)
}

ClassMethod configureLocations(ByRef State As %String)
{
    Set:'$GET(^%SYS("sql","sys","week ISO8601")) ^%SYS("sql","sys","week ISO8601")=1
    Set State("CNP")="Cochin Port -Western Coast(Kerala)"
    Set State("NMP")="New Mangalore Port - Western Coast(Karnataka)"
    Set State("CHP")="Chennai Port - Eastern Coast(Tamil Nadu)"
    Set State("ENP")="Ennore Port - Eastern Coast(Tamil Nadu)"
    Set State("TTP")="Tuticorin Port - Eastern Coast(Tamil Nadu)"
    Set State("VPP")="Visakhapatnam Port - Eastern Coast(Andhra Pradesh)"
}

ClassMethod DataSetupForContainersLog(ByRef State)
{
    Try {
        Write $C(9)_"Data Clean up : "
        K ^SQLClass.PaxContainersHistoryD,^SQLClass.PaxContainersHistoryI, ^SQLClass.PaxContainersHistoryS
        W "Done",!
        Write $C(9)_"Loaded DataSet 1 : ",##class(SQLClass.PaxContainersHistory).Populate(500000)," - Records Populated",!
        Write $C(9)_"Loaded DataSet 2 : ",##class(SQLClass.PaxContainersHistory).Populate(500000)," - Records Populated",!

        Set State=""
        Set rs=..getSQLResultSet("select ID,YearWeekNo,Units from SQLClass.PaxContainersHistory")
        While(rs.Next()) {
            Set State = $o(State(State))
            If State="" S State = $o(State(State))
            &SQL(update SQLClass.PaxContainersHistory set LocationCode=:State,country='INDIA' where ID=:rs.GetData(1))
            If rs.GetData(2)="2025-13"&($RANDOM(10)#2) {
                Set Units=8000+$R(1000)
                &SQL(update SQLClass.PaxContainersHistory set Units=:Units where ID=:rs.GetData(1))  
            }
        }
    }
    Catch e {
        Write $classname()_":"_e.DisplayString(),!

    }
}

ClassMethod DataSetupForTransactionLog(ByRef State)
{
    Try {
   
        Write $C(9)_"Data Clean up : "
        K ^SQLClass.PaxTransHistoryD,^SQLClass.PaxTransHistoryI,^SQLClass.PaxTransHistoryS
        W "Done",!
        Write $C(9)_"Loaded DataSet 1 : ",##class(SQLClass.PaxTransHistory).Populate(500000)," - Records Populated",!
        Write $C(9)_"Loaded DataSet 2 : ",##class(SQLClass.PaxTransHistory).Populate(500000)," - Records Populated",!

        Set State=""
        Set rs=..getSQLResultSet("select ID,YearWeekNo from SQLClass.PaxTransHistory")
        While(rs.Next()) {
            Set State = $o(State(State))
            If State="" S State = $o(State(State))
            &SQL(update SQLClass.PaxTransHistory set State=:State,country='INDIA' where ID=:rs.GetData(1))
            If rs.GetData(2)["2025-13"&($RANDOM(10)#2) {
                Set Amount=90000+$R(10000)
                &SQL(update SQLClass.PaxTransHistory set TransAmount=:Amount where ID=:rs.GetData(1))    
            }
        }
    }
    Catch e {
        Write $classname()_":"_e.DisplayString(),!

    }
}

ClassMethod getSQLResultSet(sqlQry As %String)
{
    Set rs=##class(%ResultSet).%New()
    Set sc=rs.Prepare(sqlQry)
    Set sc=rs.Execute()
    Quit rs
}

/// Transforms date to year-weel
ClassMethod convertWeekYear(inpDate As %String = "") As %String
{
    //w ##class(SQLClass.PaxUtil).convertWeekYear("2025-03-20")
    Set WeekNo=$SYSTEM.SQL.Functions.WEEK(inpDate),Year=$SYSTEM.SQL.Functions.YEAR(inpDate)
    Quit Year_"-"_$e(1e2,2,*-$l(WeekNo))_WeekNo
}

ClassMethod pyFindAnomaly(SQLqry As %String, State As %String = "", value As %Integer = 0, Category As %Integer = 1, YearWeekNo As %String = "", Algorithm As %String = "KNN") As %Numeric [ Language = python ]
{
    import iris
    import pandas as pd
    result=0
    
    try:
        if Algorithm == "LOF":
            #prepare sql and get data
            rs = iris.sql.exec(SQLqry)
            df = rs.dataframe()

            #run algorithm to determine if value is an anomaly
            from pyod.models.lof import LOF
            LOF_model = LOF()
            LOF_model.fit(df)
            current_value = [[value]]
            outlier = LOF_model.predict(current_value)
            result=int(outlier)

        if Algorithm == "KNN":
            #prepare sql and get data
            rs = iris.sql.exec(SQLqry)
            df = rs.dataframe()

            #run algorithm and determine if value in week and year is an anomaly
            from pyod.models.knn import KNN
            KNN_model = KNN(method='mean',n_neighbors=1,contamination=0.005,algorithm='auto',n_jobs=-1)
            partial_avg = df[["value"]]
            #print(df)
            
            KNN_model.fit(partial_avg)
            outlier_labels = KNN_model.labels_
            outliers_scores = KNN_model.decision_scores_
            outliers = df.iloc[outlier_labels == 1]
            for index, row in df.iterrows():
                if outlier_labels[index] == 1 and row['yearweekno']==YearWeekNo:
                    result=1

        if Algorithm == "IFOREST":
            #prepare sql and get data 
            rs = iris.sql.exec(SQLqry)
            df = rs.dataframe()

            #run algorithm and determine if value in week and year is an anomaly
            from pyod.models.iforest import IForest
            iso_forest = IForest()
            data_to_predict = df['value'].to_numpy().reshape(-1, 1)
            iso_forest.fit(data_to_predict)
            predictions = iso_forest.labels_
            df['Predictions'] = predictions
            df['result'] = df['value'].map(lambda x: 1 if x==-1 else 0)

            for index, row in df.iterrows():
                if row['Predictions'] == 1 and row['yearweekno']==YearWeekNo:
                    result=1
    
    except Exception as e:
        print(e)
        result=0

    return result
}

ClassMethod getPastMoveData(pState As %String, pEntryType As %Integer, pYearWeekNo As %String, ByRef resultAr As %String) As %String
{
    Set pYear=+pYearWeekNo
    Set pWeekNo=$P(pYearWeekNo,"-",2)
    &SQL(SELECT SUM(Units) into :lastYear from SQLClass.PaxContainersHistory WHERE LocationCode=:pState and ContainerGateType=:pEntryType and  {fn WEEK(MoveTimestamp)}=:pWeekNo and {fn YEAR(MoveTimestamp)}=(:pYear-1))
    Set:SQLCODE lastYear=0       
    &SQL(SELECT SUM(Units) into :avgYear from SQLClass.PaxContainersHistory WHERE LocationCode=:pState and ContainerGateType=:pEntryType and  {fn YEAR(MoveTimestamp)}=:pYear)
    Set:SQLCODE avgYear=0       
    &SQL(SELECT SUM(Units) into :lastWeek from SQLClass.PaxContainersHistory WHERE LocationCode=:pState and ContainerGateType=:pEntryType and  {fn WEEK(MoveTimestamp)}=(:pWeekNo-1) and {fn YEAR(MoveTimestamp)}=:pYear)
    Set:SQLCODE lastWeek=0  
    &SQL(SELECT SUM(Units) into :last4Week from SQLClass.PaxContainersHistory WHERE LocationCode=:pState and ContainerGateType=:pEntryType and  ({fn WEEK(MoveTimestamp)} between (:pWeekNo-4) and (:pWeekNo-1)) AND {fn YEAR(MoveTimestamp)}=:pYear)
    Set:SQLCODE last4Week=0  

    Set resultAr("lastYear")=lastYear
    Set resultAr("avgYear")=$J(avgYear/pWeekNo,"",0)
    Set resultAr("lastWeek")=lastWeek
    Set resultAr("last4Week")=$J(last4Week/4,"",0)

    Quit
}

ClassMethod getPastTransData(pState As %String, pTransType As %Integer, pYearWeekNo As %String, ByRef resultAr As %String) As %String
{
    Set pYear=+pYearWeekNo
    Set pWeekNo=$P(pYearWeekNo,"-",2)
    &SQL(SELECT SUM(TransAmount) into :lastYear from SQLClass.PaxTransHistory WHERE STATE=:pState and TransType=:pTransType and  {fn WEEK(TransTimestamp)}=:pWeekNo and {fn YEAR(TransTimestamp)}=(:pYear-1))
    Set:SQLCODE lastYear=0       
    &SQL(SELECT SUM(TransAmount) into :avgYear from SQLClass.PaxTransHistory WHERE STATE=:pState and TransType=:pTransType and  {fn YEAR(TransTimestamp)}=:pYear)
    Set:SQLCODE avgYear=0       
    &SQL(SELECT SUM(TransAmount) into :lastWeek from SQLClass.PaxTransHistory WHERE STATE=:pState and TransType=:pTransType and  {fn WEEK(TransTimestamp)}=(:pWeekNo-1) and {fn YEAR(TransTimestamp)}=:pYear)
    Set:SQLCODE lastWeek=0  
    &SQL(SELECT SUM(TransAmount) into :last4Week from SQLClass.PaxTransHistory WHERE STATE=:pState and TransType=:pTransType and  ({fn WEEK(TransTimestamp)} between (:pWeekNo-4) and (:pWeekNo-1)) AND {fn YEAR(TransTimestamp)}=:pYear)
    Set:SQLCODE last4Week=0

    Set resultAr("lastYear")=lastYear
    Set resultAr("avgYear")=$J(avgYear/pWeekNo,"",0)
    Set resultAr("lastWeek")=lastWeek
    Set resultAr("last4Week")=$J(last4Week/4,"",0)
}

}
