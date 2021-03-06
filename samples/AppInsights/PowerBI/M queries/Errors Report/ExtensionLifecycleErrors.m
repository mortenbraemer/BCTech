let AnalyticsQuery =
let 
NullToBlank = (input) => if (input = null) then "" else input,
// Kustos result set limit is 500000 rows
Limit = (input) => if (input = null) then "500000" else input,
Source = Json.Document(Web.Contents("https://api.applicationinsights.io/v1/apps/" & #"App id" & "/query", 
// here you can see how PowerBI parameters can be passed on to the KQL query
[Query=[#"query"="traces
| where 1==1 
    and ('" & NullToBlank( #"AAD Tenant Id" ) & "'=='' or customDimensions.aadTenantId == '" & NullToBlank( #"AAD Tenant Id" ) & "')
    and ('" & NullToBlank( #"Environment Name" ) & "'=='' or customDimensions.environmentName == '" & NullToBlank( #"Environment Name" ) & "')
    and timestamp >= todatetime('" & Date.ToText( #"Start Date", "yyyy-MM-dd" ) & "')
    and timestamp <= todatetime('"& Date.ToText( #"End Date", "yyyy-MM-dd" ) &"') + totimespan(24h) - totimespan(1ms)
| where customDimensions.eventId in ( 'LC0011', 'LC0013', 'LC0015', 'LC0017', 'LC0019', 'LC0021', 'LC0023' )
| limit " & Limit( #"Top" ) & "
| extend 
  aadTenantId = tostring( customDimensions.aadTenantId )
, environmentName = tostring( customDimensions.environmentName )
, environmentType = tostring( customDimensions.environmentType )
, platformVersion = tostring( customDimensions.componentVersion )
, extensionName = customDimensions.extensionName
, extensionId = customDimensions.extensionId
, extensionPublisher = customDimensions.extensionPublisher
, extensionVersion = customDimensions.extensionVersion
, result = customDimensions.result
, failureType = case(
  customDimensions.eventId == 'LC0011', 'Extension failed to install'  
, customDimensions.eventId == 'LC0013', 'Extension synchronized failed'
, customDimensions.eventId == 'LC0015', 'Extension failed to publish'  
, customDimensions.eventId == 'LC0017', 'Extension failed to un-install'
, customDimensions.eventId == 'LC0019', 'Extension failed to un-publish'
, customDimensions.eventId == 'LC0021', 'Extension failed to compile'
, customDimensions.eventId == 'LC0023', 'Extension failed to update'
, 'Unknown'
)
| project 
  timestamp
, AadTenantId=aadTenantId
, EnvironmentName=environmentName
, EnvironmentType=environmentType
, PlatformVersion = platformVersion
, ExtensionName = extensionName
, ExtensionId = extensionId
, ExtensionPublisher = extensionPublisher
, ExtensionVersion = extensionVersion
, FailureType = failureType
",#"x-ms-app"="AAPBI",#"prefer"="ai.response-thinning=true"],Timeout=#duration(0,0,4,0)])),
TypeMap = #table(
{ "AnalyticsTypes", "Type" }, 
{ 
{ "string",   Text.Type },
{ "int",      Int32.Type },
{ "long",     Int64.Type },
{ "real",     Double.Type },
{ "timespan", Duration.Type },
{ "datetime", DateTimeZone.Type },
{ "bool",     Logical.Type },
{ "guid",     Text.Type },
{ "dynamic",  Text.Type }
}),
DataTable = Source[tables]{0},
Columns = Table.FromRecords(DataTable[columns]),
ColumnsWithType = Table.Join(Columns, {"type"}, TypeMap , {"AnalyticsTypes"}),
Rows = Table.FromRows(DataTable[rows], Columns[name]), 
Table = Table.TransformColumnTypes(Rows, Table.ToList(ColumnsWithType, (c) => { c{0}, c{3}}))
in
Table
in 
AnalyticsQuery