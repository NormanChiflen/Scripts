using System;

using System.Diagnostics;

using System.Activities;

using Microsoft.TeamFoundation.Build.Client;

using Microsoft.TeamFoundation.Build.Workflow.Activities;

 

namespace SST.BuildTasks.Activities

{

 

       public sealed class CreateOctopusRelease : CodeActivity

       {

              public InOutArgument<bool> DeployFailed { get; set; }

              public InArgument<int> TimeoutMilliseconds { get; set; }

              public InArgument<string> OctopusServerUrl { get; set; }

              public InArgument<string> Project { get; set; }

              public InArgument<string> DeployEnvironment { get; set; }

 

              protected override void Execute(CodeActivityContext context)

              {

                    string octopusServerUrl = context.GetValue(OctopusServerUrl);

                    string project = context.GetValue(Project);

                     string deployEnvironment = context.GetValue(DeployEnvironment);

 

                    var buildDetail = context.GetExtension<IBuildDetail>();

                    string buildNumber = buildDetail.BuildNumber;

                    string args = string.Format(“create-release –server={0} –project={1} –version={2} –deployto={3}“

                                                 , octopusServerUrl, project, buildNumber, deployEnvironment);

 

 

                    try

                    {

                           using (Process nugetProcess = new Process())

                           {

                                  nugetProcess.StartInfo.FileName = “octo”;

                                  nugetProcess.StartInfo.Arguments = args;

                                  nugetProcess.StartInfo.RedirectStandardError = true;

                                  nugetProcess.StartInfo.RedirectStandardOutput = true;

                                  nugetProcess.StartInfo.UseShellExecute = false;

                                  nugetProcess.StartInfo.CreateNoWindow = true;

                                  nugetProcess.Start();

                                  nugetProcess.WaitForExit(context.GetValue(TimeoutMilliseconds));

                                  context.TrackBuildMessage(nugetProcess.StandardOutput.ReadToEnd());

                                  if (!nugetProcess.HasExited)

                                  {

                                         throw new Exception(string.Format(“Octopuse deploy for {0} timed out.”, project));

                                  }

                                  if (nugetProcess.ExitCode != 0)

                                  {

                                         throw new Exception(nugetProcess.StandardError.ReadToEnd());

                                  }

                           }

                    }

                    catch (Exception ex)

                    {

                           context.SetValue(DeployFailed, true);

                           context.TrackBuildMessage(string.Format(“Nuget args: {0}“, args));

                           context.TrackBuildError(ex.ToString());

                    }

              }

       }

}