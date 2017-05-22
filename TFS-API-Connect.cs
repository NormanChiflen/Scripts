public static void SyncTfsProject(string tfsuri,string sourcelocation,string localworkspace)
        {
            
            using (var tfs = TfsTeamProjectCollectionFactory.GetTeamProjectCollection((new Uri(tfsuri))))
            {
                var versionControlServer = tfs.GetService(typeof(VersionControlServer)) as VersionControlServer;
               
                // Create a new workspace for the currently authenticated user.             
                var workspace = versionControlServer.CreateWorkspace("Temporary Workspace "+Guid.NewGuid());

                try
                {
                    // Check if a mapping already exists.
                    var workingFolder = new WorkingFolder(sourcelocation, localworkspace);
                    // Create the mapping (if it exists already, it just overrides it, that is fine).
                    workspace.CreateMapping(workingFolder);
                    workspace.Get();

                   
                }
                catch (Exception ex)
                {
                    // Log Exception. 
                }
                finally
                {
                    // Cleanup the workspace.
                    workspace.Delete();
                }
            }


        }
