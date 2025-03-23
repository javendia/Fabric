#r "Microsoft.VisualBasic"
using Microsoft.VisualBasic;
using System.Collections.Generic;
using System.IO;

/*

    Author: Javier Buendia
    Created: 2025-03-01
    Description: The following script is intended, 
                by performing a series of actions, to adapt a .bim file 
                so that it can be included in an empty Power BI project (.pbip)

*/

// Variables

// Let the user specify server name
String __ServerName =
    Interaction.InputBox(
    Prompt: "Enter name for the server:",
        Title: "Server",
        DefaultResponse: "37hwelarpobuviffdsfohvhvyy-qavlxrizl4zelclxrc4gltrt3e.datawarehouse.fabric.microsoft.com"
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
        DefaultResponse: "DEV_DLH_03_GOLD_out"
    );
if(__DatabaseName == "") {
    Error("No database name provided");
    return;
}

// Let the user specify the path to the dictionary
String __Path =
    Interaction.InputBox(
    Prompt: "Enter the path to CSV file:",
    Title: "Path",
    DefaultResponse: "C:\\Users\\user\\Desktop\\dictionary.csv"
    );
if(__Path == "") {
    Error("No path provided");
    return;
}

// Constants

var __CompatibilityLevel = 1550;
var __DefaultPowerBIDataSourceVersion = PowerBIDataSourceVersion.PowerBI_V3;

Dictionary<string, string> changes = new Dictionary<string, string>();
StreamReader reader = new StreamReader(__Path, System.Text.Encoding.UTF8, true);
reader.ReadLine(); // Delete headers

// Read dictionary from file
string line;
while ((line = reader.ReadLine()) != null)
{
    string[] parts = line.Split(';');
    changes.Add(parts[0], parts[1]);
}

reader.Close();

// Set Compatibility Level
Model.Database.CompatibilityLevel = __CompatibilityLevel;
// Default Data Source Version
Model.DefaultPowerBIDataSourceVersion = __DefaultPowerBIDataSourceVersion;
// Disable Time Intelligence
Model.SetAnnotation("__PBI_TimeIntelligenceEnabled", "0");

// For each table, build the new default Power Query partition
foreach(var t in Model.Tables)
{
    foreach(var p in t.Partitions.Where(a => a.Name == "Partition").ToList())
    {
        p.Mode = ModeType.Import;
        
        if (changes.ContainsKey(t.Name))
        {
           
            string parts = changes[t.Name];
            string schema = parts.Split('.')[0];
            string viewName = parts.Split('.')[1];

            p.Expression = string.Format(
                "let\r\n\tSource = Sql.Databases(\"{0}\"),\r\n\t{1} = Source{{[Name=\"{1}\"]}}[Data],\r\n\t{2}_{3} = {1}{{[Schema=\"{2}\",Item=\"{3}\"]}}[Data]\r\nin\r\n\t{2}_{3}",
                __ServerName,
                __DatabaseName,
                schema,
                viewName
            );
        }
    }
}

// Delete existing data sources
for(int i=0; i < Model.DataSources.Count(); i++)
{
    Model.DataSources[i].Delete();
}