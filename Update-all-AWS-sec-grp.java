//in order for me to access the AWS EC2 instances I’ve written a small application that allows me to quickly update the Security Groups so I don’t have to work through them all manually.

package aws;

import com.amazonaws.auth.AWSCredentials;
import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.AmazonEC2Client;
import com.amazonaws.services.ec2.model.AuthorizeSecurityGroupIngressRequest;
import com.amazonaws.services.ec2.model.IpPermission;
import com.amazonaws.services.ec2.model.RevokeSecurityGroupIngressRequest;
import java.util.ArrayList;
import java.util.List;

/**
 *
 * @author mark
 */
public class UpdateSecurityGroups {
    
    private AmazonEC2 ec2;
    
    private String[] securityGroupsWithHttps = new String[] { "sg-xxxxxxxx"};
    private String[] securityGroupsWithoutHttps = new String[] { "sg-xxxxxxxx" };
    
    public UpdateSecurityGroups() {
        
        AWSCredentials credentials = new BasicAWSCredentials("XXX", "XXX");
	ec2 = new AmazonEC2Client(credentials);
        ec2.setEndpoint("ec2.eu-west-1.amazonaws.com");
        
        List oldIp = new ArrayList();
        oldIp.add("xxx.xxx.xxx.xxx/32");
        
        List newIp = new ArrayList();
        newIp.add("xxx.xxx.xxx.xxx/32");
        
        /**
         * Port 22
         */
        for (String securityGroup : securityGroupsWithoutHttps) {
            
            removeOld(oldIp, securityGroup, false);
            addNew(newIp, securityGroup, false);
        }
        
        /**
         * Ports 22 and 443
         */
        for (String securityGroup : securityGroupsWithHttps) {
            
            removeOld(oldIp, securityGroup, true);
            addNew(newIp, securityGroup, true);
        }
    }
    
    private void addNew(List ips, String securityGroup, boolean includeHttps) {
        
        List permissions = new ArrayList();
        permissions.add( sshPermission(ips) );
        
        if (includeHttps) {
            permissions.add( httpsPermission(ips) );
        }
        
        AuthorizeSecurityGroupIngressRequest request = new AuthorizeSecurityGroupIngressRequest();
        request.setGroupId(securityGroup);
        request.setIpPermissions(permissions);

        try {
            
            this.ec2.authorizeSecurityGroupIngress(request);
            
        } catch (Exception e) {
            
            System.out.println(e.getMessage());
        }
    }
    
    private void removeOld(List ips, String securityGroup, boolean includeHttps) {
       
        List permissions = new ArrayList();
        permissions.add( sshPermission(ips) );
        
        if (includeHttps) {
            permissions.add( httpsPermission(ips) );
        }
        
        RevokeSecurityGroupIngressRequest request = new RevokeSecurityGroupIngressRequest();
        request.setGroupId(securityGroup);
        request.setIpPermissions(permissions);

        try {
            
            this.ec2.revokeSecurityGroupIngress(request);
            
        } catch (Exception e) {
            
            System.out.println(e.getMessage());
        }
    }
    
    private IpPermission sshPermission(List ips) {
        
        IpPermission permission = new IpPermission();
        permission.setIpProtocol("tcp");
        permission.setFromPort(22);
        permission.setToPort(22);
        permission.setIpRanges(ips);
        
        return permission;
    }
    
    private IpPermission httpsPermission(List ips) {
        
        IpPermission permission = new IpPermission();
        permission.setIpProtocol("tcp");
        permission.setFromPort(443);
        permission.setToPort(443);
        permission.setIpRanges(ips);
        
        return permission;
    }
    
    public static void main(String[] args) {
        new UpdateSecurityGroups();
    }
}
