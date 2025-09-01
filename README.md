# Power BI / Microsoft Fabric utils

The purpose of this repository is to provide developers with tools and utilities to implement solutions on Power BI / Microsoft Fabric.

## 📦 Contents

### 📁 [doc](https://github.com/javendia/Fabric/blob/main/doc)

Full documentation about the Power BI / Fabric projects.

### 📁 [tabular](https://github.com/javendia/Fabric/blob/main/tabular)

Scripts to automate actions over a tabular model

- 🔗 **[tabular/BimToPBIP.csx](https://github.com/javendia/Fabric/blob/main/tabular/BimToPBIP.csx)**
    - 1️⃣ Description
        --- 
        Script to convert an on-premises Microsoft SQL Server Analysis Services tabular model to a Power BI project (.pbip)
    - 2️⃣ Prerequisites
        ---
        - [Tabular Editor 2.x](https://github.com/TabularEditor/TabularEditor/releases)
        - An empty Power BI project (.pbip). We cau use [this]() one.
        - A dictionary, which assigns the data source (table or view) for each entity model
    - 3️⃣ How it works
        ---
        - The first step is to extract the metadata from the tabular model. We can get it using Tabular Editor as follows:
            - Connect with the desired tabular model
            ![img](./tabular/media/tabular-01.png)
            - Save metadata
            ![img](./tabular/media/tabular-02.png)
            ![img](./tabular/media/tabular-03.png)
        - Secondly, we need to fill a [dictionary CSV](https://github.com/javendia/Fabric/blob/main/tabular/Dictionary.csv), where each key-value represents an entity model and its data source (table or view)
        - Then, we will open the extracted tabular model and finally run the script on Tabular Editor. It prompts three values to the user:
            - The SQL connection string to the lakehouse SQL endpoint, used as destination server
            - Lakehouse name, used as destination database
            - The path to the dictionary
    - 4️⃣ Limitations
        ---
        - The compatibility level must be higher or equal than 1500
        - It is planned to work with a single SQL data source
        - The script transforms default partitions. Custom partitions must be migrated manually

### 📁 [pbi](https://github.com/javendia/Fabric/blob/main/pbi)

Scripts to perform actions over Power BI reports

- 🔗 **[pbi/MigratePBI.ps1](https://github.com/javendia/Fabric/blob/main/pbi/MigratePBI.ps1)**
    - 1️⃣ Description
        --- 
        Script to convert a Power BI report (.pbix) to a Power BI project (.pbip) and publish it to the service.
    - 2️⃣ Prerequisites
        ---
        - [Powershell 7.x](https://learn.microsoft.com/es-es/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5)
        - Permission to execute Powershell scripts

            ```powershell
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
            ```
    - 3️⃣ How it works
        ---
        - Firstly, the script requests some data to the user:
            - The path to Power BI files to convert
            - Destination workspace name
            - In order to bing the report, the corresponding semantic model id
        - During the execution, the script creates a subfolder in the directory passed as argument. After that, the user have to save the report as Power BI project manually. The project must be placed on the subfolder created previously
        - Finally, the report is published to Power BI service and it is linked to the semantic model
