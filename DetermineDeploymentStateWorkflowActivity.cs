     

//DetermineDeploymentState Workflow Activity

using System;

using System.Collections.Generic;

using System.Data.SqlClient;

using System.Text;

using System.Activities;

using System.Threading;

using Microsoft.TeamFoundation.Build.Client;

using Microsoft.TeamFoundation.Build.Workflow.Activities;

 

namespace SST.BuildTasks.Activities

{

 

       public sealed class DetermineDeploymentState : CodeActivity

       {

              // Define an activity input argument of type string

              public InArgument<int> PingInterval { get; set; }

              public InArgument<string> ConnectionString { get; set; }

              public InArgument<int> TimeOut { get; set; }

              public InOutArgument<bool> Succeeded { get; set; }

              public InArgument<string> OctopusProject { get; set; }

 

              private const string Sql =

                    @”SELECT [State]

       FROM 

       [Octopus].[Octopus].Project P

       INNER JOIN 

       [Octopus].[Octopus].[Release] R

       ON P.Id = R.Project_Id 

       INNER JOIN 

       [Octopus].[Octopus].Deployment D

       ON R.Id = D.Release_Id

       INNER JOIN 

       [Octopus].[Octopus].Task T

       ON D.Task_Id = T.Id

       WHERE Version = @Version

       AND P.Name = @ProjectName”;

 

              private const string ErrorSql =

                    @”SELECT [ErrorMessage]

       FROM 

       [Octopus].[Octopus].Project P

       INNER JOIN 

       [Octopus].[Octopus].[Release] R

       ON P.Id = R.Project_Id 

       INNER JOIN 

       [Octopus].[Octopus].Deployment D

       ON R.Id = D.Release_Id

       INNER JOIN 

       [Octopus].[Octopus].Task T

       ON D.Task_Id = T.Id

       WHERE Version = @Version

       AND P.Name = @ProjectName”;

 

              // If your activity returns a value, derive from CodeActivity<TResult>

              // and return the value from the Execute method.

              protected override void Execute(CodeActivityContext context)

              {

 

                    var buildDetail = context.GetExtension<IBuildDetail>();

                    string buildNumber = buildDetail.BuildNumber;

                    int pingInterval = context.GetValue(PingInterval);

                    string connectionString = context.GetValue(ConnectionString);

                    int timeOut = context.GetValue(TimeOut);

                    string project = context.GetValue(OctopusProject);

 

                    try

                    {

                           using (var cnnc = new SqlConnection(connectionString))

                           {

                                  cnnc.Open();

                                  using (var cmd = new SqlCommand(Sql, cnnc))

                                  {

                                         cmd.Parameters.AddWithValue(“@Version”, buildNumber);

                                         cmd.Parameters.AddWithValue(“@ProjectName”, project);

                                         int count = 0;

                                         bool keepPinging = true;

                                        while (keepPinging & count < timeOut)

                                         {

                                                object result = cmd.ExecuteScalar();

                                               if (result != null)

                                               {

                                                      string state = result.ToString();

                                                      switch (state)

                                                      {

                                                             case “Success” :

                                                                    context.SetValue(Succeeded, true);

                                                                    keepPinging = false;

                                                                    context.TrackBuildMessage(string.Format(“Octopus deploy {0} for {1} successful.”, buildNumber, project));

                                                                    break;

                                                             case “Failed” :

                                                                    context.SetValue(Succeeded, false);

                                                                    keepPinging = false;

                                                                    cmd.CommandText = ErrorSql;

                                                                    result = cmd.ExecuteScalar();

                                                                    context.TrackBuildError(result.ToString());

                                                                    break;

                                                      }

                                               }

                                               // Wait one interval

                                               Thread.Sleep(pingInterval);

                                               count += pingInterval;

                                         }

                                  }

                           }

                    }

                    catch (Exception ex)

                    {

                           context.SetValue(Succeeded, false);

                           context.TrackBuildError(ex.ToString());

                    }

 

              }

       }

}

 
