Below is the CreateTargetEnvironment Jenkins job script that creates a new target environment from a CloudFormation script production.template


if [ $deployToProduction ] == true
then
SSH_KEY=production
else
SSH_KEY=development
fi

# Create Cloudformaton Stack
ruby /usr/share/tomcat6/scripts/aws/create_stack.rb ${STACK_NAME} ${WORKSPACE}/production.template ${HOST} ${JENKINSIP} ${SSH_KEY} ${SGID} ${SNS_TOPIC}

# Load SimpleDB Domain with Key/Value Pairs
ruby /usr/share/tomcat6/scripts/aws/load_domain.rb ${STACK_NAME}

# Pull and store variables from SimpleDB
host=`ruby /usr/share/tomcat6/scripts/aws/showback_domain.rb ${STACK_NAME} InstanceIPAddress`

# Run Acceptance Tests
cucumber features/production.feature host=${host} user=ec2-user key=/usr/share/tomcat6/.ssh/id_rsa

Referenced above in the CreateTargetEnvironment code snippet. This is the load_domain.rb script that iterates over a file and sends key/value pairs to SimpleDB.

require 'rubygems'
require 'aws-sdk'
load File.expand_path('../../config/aws.config', __FILE__)

stackname=ARGV[0]

file = File.open("/tmp/properties", "r")

sdb = AWS::SimpleDB.new

AWS::SimpleDB.consistent_reads do
  domain = sdb.domains["stacks"]
  item = domain.items["#{stackname}"]

  file.each_line do|line|
    key,value = line.split '='
    item.attributes.set(
      "#{key}" => "#{value}")
  end
end

Referenced above in the CreateTargetEnvironment code snippet. This is the showback_domain.rb script which connects to SimpleDB and returns a key/value pair.

load File.expand_path('../../config/aws.config', __FILE__)

item_name=ARGV[0]
key=ARGV[1]

sdb = AWS::SimpleDB.new

AWS::SimpleDB.consistent_reads do
  domain = sdb.domains["stacks"]
  item = domain.items["#{item_name}"]

  item.attributes.each_value do |name, value|
    if name == "#{key}"
      puts "#{value}".chomp
    end
  end
end

In the above in the CreateTargetEnvironment code snippet, we store the outputs of the CloudFormation stack in a temporary file. We then iterate over the file with the load_domain.rb script and store the key/value pairs in SimpleDB.

Following this, we make a call to SimpleDB with the showback_domain.rb script and return the instance IP address (created in the CloudFormation template) and store it in the host variable. host is then used by cucumber to ssh into the target instance and run the acceptance tests.

Using CloudFormation

In our CloudFormation templates we allocate multiple AWS resources. Every time we run the template, a different resource is being used. For example, in our jenkins.template we create a new IAM user. Every time we run the template a different IAM user with different credentials is created. We need a way to reference these resources. This is where CloudFormation comes in. You can reference resources within other resources throughout the script. You can define a reference to another resource using the Ref function in CloudFormation. Using Ref, you can dynamically refer to values of other resources such as an IP Address, domain name, etc.

In the script we are creating an IAM user, referencing the IAM user to create AWS Access keys and then storing them in an environment variable.


"CfnUser" : {
  "Type" : "AWS::IAM::User",
  "Properties" : {
    "Path": "/",
    "Policies": [{
      "PolicyName": "root",
      "PolicyDocument": {
        "Statement":[{
          "Effect":"Allow",
          "Action":"*",
          "Resource":"*"
        }
      ]}
    }]
  }
},

"HostKeys" : {
  "Type" : "AWS::IAM::AccessKey",
  "Properties" : {
    "UserName" : { "Ref": "CfnUser" }
  }
},

"# Add AWS Credentials to Tomcat\n",
"echo \"AWS_ACCESS_KEY=", { "Ref" : "HostKeys" }, "\" >> /etc/sysconfig/tomcat6\n",
"echo \"AWS_SECRET_ACCESS_KEY=", {"Fn::GetAtt": ["HostKeys", "SecretAccessKey"]}, "\" >> /etc/sysconfig/tomcat6\n",