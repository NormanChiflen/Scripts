#!/usr/bin/env ruby
require 'rubygems'
require 'open-uri'

# Configuration.
DEPLOYMENT_TIME_NOT_AVAILABLE = "N/A";
NODE1 = "chelpsfsmlx003.karmalab.net";
NODE2 = "chelpsfsmlx004.karmalab.net";
SLEEP_TIME_IN_MS = 60;
    
# Retrieve the deplyoment time from the isWorking page.
#
# Return value: the deployment time.
def getDeploymentTime(nodeName)
    deploymentTime = DEPLOYMENT_TIME_NOT_AVAILABLE;
    deploymentTimeInNextLine = false;
    url = "http://#{nodeName}:56788/isWorking";
    file = open(url);
  
    file.each do |line|
        if deploymentTimeInNextLine 
            # Removing spaces from the beginning of the text and the html tags.
            deploymentTime = "#{line}".gsub(/ *<\/?[^>]+>/, '');
            break;
        end
        if line.include? "deploymentTime"
            deploymentTimeInNextLine = true;
        end 
    end
    
    rescue OpenURI::HTTPError => errorMessage 
        puts "****** The #{url} could not be opened.";
        puts "****** The exception message: ";
        puts errorMessage;
    ensure
        file.close unless file.nil?;
        return  deploymentTime;
end

# Deploy the nodName node.
def deploy(nodeName)
    command = %Q{knife ssh -x v-rfarkas -m #{nodeName} "sudo -H chef-client"};
    system(command);
end

# Sleep until the given time.
def waitForTomcat
    puts "****** Waiting #{SLEEP_TIME_IN_MS} milliseconds after deployment.";
    sleep(SLEEP_TIME_IN_MS);
end

# Performing the following steps:
# 1. Retrieving the deployment time from isWorking page before the deploymnent.
# 2. Deploy nodeName node.
# 3. Sleep.
# 4. Retrieving the deployment time from isWorking page after the deploymnent.
#
# Return value: boolean whether the deployment was success or not.
def process(nodeName)
    isDeploymentSuccess = false;
    puts "****** START deploying #{nodeName}.";
    deploymentTimeOld = getDeploymentTime(nodeName);
                
    deploy(nodeName);
    waitForTomcat;
        
    deploymentTimeNew = getDeploymentTime(nodeName);
    puts "****** The old deployment time: #{deploymentTimeOld}";
    puts "****** The new deployment time: #{deploymentTimeNew}";

    if DEPLOYMENT_TIME_NOT_AVAILABLE.eql?(deploymentTimeNew)
        puts "****** The deployment FAILED becuase the isWorking page could not be reached.";
        isDeploymentSuccess = false;
    elsif !DEPLOYMENT_TIME_NOT_AVAILABLE.eql?(deploymentTimeNew) && !DEPLOYMENT_TIME_NOT_AVAILABLE.eql?(deploymentTimeOld) && deploymentTimeOld == deploymentTimeNew
        puts "****** The deployment FAILED on #{nodeName} because the deployment times were the same.";
        isDeploymentSuccess = false;
    else
        puts "****** The deployment was SUCCESS on #{nodeName}.";
        isDeploymentSuccess = true;
    end
    
    puts "****** FINISHING the deployment on #{nodeName}.";
    return isDeploymentSuccess;
end


# Process the deployment on the given nodes and 
# exit with the appropriate exit code to notify Jenkins about the result of the build.
isDeploymentSuccessOnNode1 = process(NODE1);
if !isDeploymentSuccessOnNode1 
    # The exit 1; causes Jenkins build failure.
    exit 1;
end
    
isDeploymentSuccessOnNode2 = process(NODE2);
if !isDeploymentSuccessOnNode2
    # The exit 1; causes Jenkins build failure.
    exit 1;
end

# The exit 0; causes Jenkins build success.
exit 0;
