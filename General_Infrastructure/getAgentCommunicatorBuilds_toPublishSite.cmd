::Copy build results from \\karmalab.net\builds\... locations to a consolidated share so Test can install
for %%i in (ContinuousIntegration DirectedBuilds ReleaseCandidate Release) do (
  robocopy \\karmalab.net\builds\%%i\sait\VCI\AgentCommunicator\publish\ D:\AgentCommunicator_ClickOnce\publish\%%i\ *.* /E /NP /NDL  /LOG+:d:\logroot\getAgentCommunicatorBuilds_toPublishSite.log /TEE
)