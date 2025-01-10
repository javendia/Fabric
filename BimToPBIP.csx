#r "Microsoft.VisualBasic"
using Microsoft.VisualBasic;
using System.Collections.Generic;

/*

BIM to PBIP

The following script is intended, by performing a series of actions, 
to adapt a .bim file so that it can be included 
in an empty Power BI project (.pbip)

*/

// Variables

// Let the user specify server name
String __ServerName =
    Interaction.InputBox(
    Prompt: "Enter name for the server:",
        Title: "Server",
        DefaultResponse: "noiyvbapiyqenhxnextiasad6e-titpaixmb65uxeagguhr2ocrpm.datawarehouse.fabric.microsoft.com"
    );
if(__ServerName == "") {
    Error("No server name provided");
    return;
}

// Let the user specify database name
String __DatabaseName =
    Interaction.InputBox(
    Prompt: "Enter name for the database:",
    Title: "Database",
        DefaultResponse: "AZDATA_DEV_DLH_02_SILVER_out"
    );
    if(__DatabaseName == "") {
    Error("No database name provided");
    return;
}

// Constants

var __CompatibilityLevel = 1550;
var __DefaultPowerBIDataSourceVersion = PowerBIDataSourceVersion.PowerBI_V3; 

Dictionary<string, string> changes = 
    new Dictionary<string, string>(){
        {"CustomerID", "sk_dim_customer"},
        {"AddressID", "sk_dim_address"},
        {"ProductCategoryID", "sk_dim_productcategory"},
        {"ProductModelID", "sk_dim_productmodel"},
        {"ProductDescriptionID", "sk_dim_productdescription"},
        {"SalesOrderID", "sk_dim_saleorder"},
        {"ProductID", "sk_dim_product"},
        {"ShipToAddressID", "sk_dim_address"}
    };
   
// Set Compatibility Level
Model.Database.CompatibilityLevel = __CompatibilityLevel;
// Default Data Source Version
Model.DefaultPowerBIDataSourceVersion = __DefaultPowerBIDataSourceVersion;
// Disable Time Intelligence
Model.SetAnnotation("__PBI_TimeIntelligenceEnabled", "0");




foreach(var t in Model.Tables)
{
    
    foreach(var c in t.Columns)
    {   
        // Change column name is exists in the dictionary
        if(changes.ContainsKey(c.Name))
        {
            c.Name = changes[c.Name];
        }
    }
    
    foreach (var p in t.Partitions.Where(a => a.Name == "Partition").ToList()) // Default partition is named as Partition
    {
        p.Mode = ModeType.Import;
        p.Expression = string.Format(
                            "let\r\n\tSource = Sql.Databases(\"{0}\"),\r\n\t{1} = Source{{[Name=\"{1}\"]}}[Data],\r\n\t{2}_{3} = {1}{{[Schema=\"{2}\",Item=\"{3}\"]}}[Data]\r\nin\r\n\t{2}_{3}",
                            __ServerName,
                            __DatabaseName,
                            "dbo",
                            t.Name);
    }
}




