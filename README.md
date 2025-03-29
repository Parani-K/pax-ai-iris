# pax-ai-iris
# Hybrid Framework for Anomaly Detection - IRIS, Embedded Python, AI algorithms 

## InterSystems IRIS Version
IRIS for Windows (x86-64) 2024.1.3 (Build 456U)  Thu Jan 9 2025 12:47:03 EST  

---

## Python Installation and Configuration

### Steps to Install Python and Execute Embedded Python Code in InterSystems IRIS:
1. **Install Python**:
   - Ensure Python 3.6 or later is installed on your system. You can download it from the [official Python website](https://www.python.org/downloads/).

2. **Install InterSystems IRIS**:
   - Download and install InterSystems IRIS from the [InterSystems website](https://www.intersystems.com/).

3. **Configure Python in IRIS**:
   - Open the InterSystems IRIS terminal and set the Python executable path using:
     ```objectscript
     Set ^%SYS("Python","Path") = "/path/to/python3"
     ```

4. **Install Python Packages**:
   - Use `pip` to install any required Python packages:
     ```bash
     python3 -m pip install --target /path/to/iris/mgr/python <package_name>
     ```

5. **Enable Embedded Python**:
   - Enable embedded Python in the IRIS terminal:
     ```objectscript
     Set ^%SYS("Python","Enabled") = 1
     ```

6. **Write and Execute Embedded Python Code**:
   - Create an InterSystems IRIS class and include Python code:
     ```objectscript
     ClassMethod RunPython() As %Status
     {
         &python
         print("Hello from Python!")
         &endpython
         Quit $$$OK
     }
     ```

7. **Run Your Code**:
   - Execute your method from the IRIS terminal:
     ```objectscript
     Do ##class(YourNamespace.YourClass).RunPython()
     ```
     
## Installing Python Libraries include that specific to This Application

### Locate the Path to `irispip.exe`:
- Open the command prompt and navigate to the InterSystems IRIS installation folder, typically: C:\InterSystems\iris\bin\

### Install Required Libraries:
1. **Pandas**:
   ```bash
   irispip install --target C:\InterSystems\iris\mgr\python pandas
   ```
2. **Numpy**: 
    ```bash
    irispip install --target C:\InterSystems\iris\mgr\python numpy==1.21
    ```
3. **PyOD**:
   ```bash
     irispip install --target C:\InterSystems\iris\mgr\python pyod
   ```
---
### Package Import, Deployment, and Compilation
- **Move IRIS Class Files:** Transfer the following class files to the appropriate namespace:

  1. PaxUtil.cls
  2. PaxTransHistory.cls
  3. PaxContainersHistory.cls
     
- **Compile the Class Files:** Ensure the files are compiled and ready for execution.
---
## Data Setup Command
### Populate Sample Data: Run the following command to generate test data:
```objectscript
Do ##class(SQLClass.PaxUtil).DataSetup()
```
This method generates 1 million testing records spanning a total duration of 4 years and 4 months, starting from January 1, 2021, at 00:00:00 and continuing until March 31, 2025, at 23:59:59.

**Sample Execution Output:** Upon running the command, the system will execute the data setup process for the following logs:
```bash
      USER>Do ##class(SQLClass.PaxUtil).DataSetup()
      Data setup - Containers History of 6 Ports from different locations (Logistics):
              Data Clean up : Done
              Loaded DataSet 1 : 500000 - Records Populated
              Loaded DataSet 2 : 500000 - Records Populated
              Outlier Data Injected for WeekNo 13 - 2025
      
      Data setup - Transactions history of 6 ATMs from different locations (Banking):
              Data Clean up : Done
              Loaded DataSet 1 : 500000 - Records Populated
              Loaded DataSet 2 : 500000 - Records Populated
              Outlier Data Injected for WeekNo 13 - 2025
```
---
## Anomaly Detection Methodology
### Algorithms Used:
1. **K-Nearest Neighbors (KNN):** KNN is a supervised learning algorithm that classifies data points based on their similarity to the "k" nearest neighbors. In the context of anomaly detection, it identifies outliers by comparing a data point to its closest neighbors and detecting deviations.
2. **Isolation Forest (IFOREST):** This unsupervised algorithm isolates anomalies by randomly partitioning the dataset. Anomalies are easier to isolate because they differ significantly from the rest of the data.
3. **Local Outlier Factor (LOF):** LOF identifies outliers by comparing the local density of data points. Points with lower density compared to their neighbors are flagged as anomalies.

### Workflow:
- Algorithms executed sequentially to comparative Study of KNN, LOF, and Isolation Forest:
  **KNN → IFOREST → LOF**
- Trained on the same dataset for consistency.
- Validates data based on week number and year derived from input dates -or- date of day back in case no input date.
  
### Automation and Scheduling
- The method is triggered automatically at the start of each week to analyze the previous week's data.
- Results are categorized by locations and categories.
  
--- 

## Purpose of the below sample runs
This application is designed to identify anomaly activities in the following domains:
1. **Banking**: Detecting suspicious or irregular transaction patterns within the Banking dataset.
2. **Logistics**: Identifying anomalies in container gate-in (CGI) and container gate-out (CGO) operations across specific port locations.


## Instructions
### General Data Population : 
- Once the data population is completed, follow the below

### Banking Domain
1. **Command Execution**:
   - Navigate to the namespace where the data population was performed.
   - Execute the following command:
     ``` objectscript
     Do ##class(SQLClass.PaxTransHistory).anomalyDetection("2025-03-25")
     ```
     
   - **Input Parameter**:
     - `"2025-03-25"` specifies the week for anomaly detection.
     - If no date is provided, the system defaults to the previous day's date and calculates the corresponding week number of the year.
   - Ensure the namespace matches the one used during test data setup.

2. **Output and Variability**:
   - The command analyzes the dataset and identifies anomaly activities based on the input date.
   - Results are displayed in a predefined format and may vary for the same input date, as the `%POPULATE` class introduces randomness during the data generation phase.
     
3. **Sample Execution Output:**

   ``` bash
         USER>Do ##class(SQLClass.PaxTransHistory).anomalyDetection("2025-03-25")
         
         ANOMALIES IDENTIFIED IN WEEKLY RUN ON WK#13 (2025)
         ---------------------------------------------------
                   Withdrawal at New Mangalore Port - Western Coast(Karnataka)(ATM-Code:NMP787780)  Amount : 20556730
                                                                                         This year's avg   : 14348216
                                                                                     Previous 4 week's Avg : 13683931
                                                                                           Previous Week   : 13315884
                                                                               Previous Year's Same week   : 13130318
              Withdrawal at Visakhapatnam Port - Eastern Coast(Andhra Pradesh)(ATM-Code:VPP868080)  Amount : 19955652
                                                                                         This year's avg   : 14369368
                                                                                     Previous 4 week's Avg : 14553030
                                                                                           Previous Week   : 13348459
                                                                               Previous Year's Same week   : 14003942
                           Transfer at Ennore Port - Eastern Coast(Tamil Nadu)(ATM-Code:ENP697880)  Amount : 21084254
                                                                                         This year's avg   : 14023015
                                                                                     Previous 4 week's Avg : 13283452
                                                                                           Previous Week   : 12864380
                                                                               Previous Year's Same week   : 13429192
    ```

### Logistics Domain
1. **Command Execution**:
   - Navigate to the namespace where the data population was performed.
   - Execute the following command:
     ```objectscript
     Do ##class(SQLClass.PaxContainersHistory).anomalyDetection("2025-03-25")
     ```
   - **Input Parameter**:
     - `"2025-03-25"` specifies the date for anomaly detection.
     - If no date is provided, the system defaults to the previous day's date and calculates the corresponding week number of the year.
   - Ensure the namespace corresponds to the one used during test data setup.

2. **Output and Variability**:
   - The command analyzes the dataset and identifies anomalies related to container gate-in (CGI) and container gate-out (CGO) activities across different port locations.
   - Results are displayed in a predefined format and may vary for the same input date due to the randomness introduced during the data generation phase.

3. **Sample Execution Output:**
   ``` bash
         USER>Do ##class(SQLClass.PaxContainersHistory).anomalyDetection("2025-03-25")
         
         
         ANOMALIES IDENTIFIED IN WEEKLY RUN ON WEEK#13 (2025)
         ----------------------------------------------------------
                                Container Gate-Out at Chennai Port - Eastern Coast(Tamil Nadu)(CHP)  Units : 3036621
                                                                                         This year's avg   : 1969605
                                                                                     Previous 4 week's Avg : 1946684
                                                                                           Previous Week   : 1897887
                                                                               Previous Year's Same week   : 1836667
                                      Container Gate-Out at Cochin Port -Western Coast(Kerala)(CNP)  Units : 3209278
                                                                                         This year's avg   : 1926549
                                                                                     Previous 4 week's Avg : 1892441
                                                                                           Previous Week   : 1936414
                                                                               Previous Year's Same week   : 1744798
                                 Container Gate-Out at Ennore Port - Eastern Coast(Tamil Nadu)(ENP)  Units : 3037720
                                                                                         This year's avg   : 1923845
                                                                                     Previous 4 week's Avg : 1901025
                                                                                           Previous Week   : 1992539
                                                                               Previous Year's Same week   : 1854914
                           Container Gate-Out at New Mangalore Port - Western Coast(Karnataka)(NMP)  Units : 3139142
                                                                                         This year's avg   : 1961736
                                                                                     Previous 4 week's Avg : 1907479
                                                                                           Previous Week   : 1975264
                                                                               Previous Year's Same week   : 1853297
                              Container Gate-Out at Tuticorin Port - Eastern Coast(Tamil Nadu)(TTP)  Units : 3328492
                                                                                         This year's avg   : 1951659
                                                                                     Previous 4 week's Avg : 1835133
                                                                                           Previous Week   : 1883748
                                                                               Previous Year's Same week   : 1902192
                      Container Gate-Out at Visakhapatnam Port - Eastern Coast(Andhra Pradesh)(VPP)  Units : 3446854
                                                                                         This year's avg   : 1989926
                                                                                     Previous 4 week's Avg : 1884473
                                                                                           Previous Week   : 1827341
                                                                               Previous Year's Same week   : 1840329
                                 Container Gate-In at Chennai Port - Eastern Coast(Tamil Nadu)(CHP)  Units : 3131779
                                                                                         This year's avg   : 2007539
                                                                                     Previous 4 week's Avg : 1933595
                                                                                           Previous Week   : 1964282
                                                                               Previous Year's Same week   : 2107174
                                  Container Gate-In at Ennore Port - Eastern Coast(Tamil Nadu)(ENP)  Units : 3148797
                                                                                         This year's avg   : 1999663
                                                                                     Previous 4 week's Avg : 1867842
                                                                                           Previous Week   : 1886003
                                                                               Previous Year's Same week   : 2023913
                            Container Gate-In at New Mangalore Port - Western Coast(Karnataka)(NMP)  Units : 3363762
                                                                                         This year's avg   : 1941400
                                                                                     Previous 4 week's Avg : 1862354
                                                                                           Previous Week   : 2004584
                                                                               Previous Year's Same week   : 1991292
                               Container Gate-In at Tuticorin Port - Eastern Coast(Tamil Nadu)(TTP)  Units : 2960126
                                                                                         This year's avg   : 1947936
                                                                                     Previous 4 week's Avg : 1918125
                                                                                           Previous Week   : 1950421
                                                                               Previous Year's Same week   : 2003365
                       Container Gate-In at Visakhapatnam Port - Eastern Coast(Andhra Pradesh)(VPP)  Units : 3221396
                                                                                         This year's avg   : 1961220
                                                                                     Previous 4 week's Avg : 1915614
                                                                                           Previous Week   : 1852360
                                                                               Previous Year's Same week   : 1685215
    ```

## Summary of the Workflow

1. Data is first generated using InterSystems IRIS’s `%POPULATE` class.
2. Anomaly detection is executed for both Banking and Logistics domains using specific commands.
3. Results are validated based on the week number and year derived from the input date.
4. Detected anomalies provide actionable insights for addressing irregularities in both domains.

## Key Notes
- The randomness introduced during test data generation using means results may vary for the same input parameters.
- These methods provide valuable insights, enhancing anomaly detection accuracy and operational efficiency in both Banking and Logistics domains.

## References 
1.	[Introduction to Embedded Python | InterSystems IRIS Data Platform 2025.1](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=AFL_epython).
2.	[Introduction and Prerequisites | Using Embedded Python | InterSystems IRIS Data Platform 2025.1](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GEPYTHON_prereqs).
3.	[Install and Import Python Packages | Using Embedded Python | InterSystems IRIS Data Platform 2025.1](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GEPYTHON_loadlib).

