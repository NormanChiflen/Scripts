SELECT 
       WI.System_Id AS [ID],
       WI.System_WorkItemType as [Work Item Type],
       WI.AirComp_POS AS [Point of Sale],
       WI.System_CreatedDate AS [Created Date],
       WI.AirComp_TeamAssignedTo AS [Team Assigned To], 
       WI.AirComp_Team AS [Team], 
       WI.AirComp_CaseType,
       P.Name AS [Assigned To],
       WI.System_State AS [State],
       WI.System_Reason AS [Reason],
       CASE WHEN WI.AirComp_Team IS NULL THEN 'Not Investigated'
            ELSE 'Investigated' END AS CaseInvestigated,
       DATEPART(YEAR,WI.System_CreatedDate) AS [Created Year],
       DATEPART(MONTH,WI.System_CreatedDate) AS [Created Month],
       DATEPART(WEEK,WI.System_CreatedDate) AS [Created Week]       
  FROM dbo.DimWorkItem WI
  LEFT JOIN dbo.DimPerson P
    ON WI.System_AssignedTo__PersonSK = P.PersonSK
WHERE ISNULL(WI.AirComp_AdditionalComments,'') <> 'Crazy Eddie'
   AND (ISNULL(WI.AirComp_Team,'') ='AirCPR' OR ISNULL(WI.AirComp_TeamAssignedTo,'') = 'AirCPR')
   AND  WI.System_CreatedDate >= '1/1/2013'
