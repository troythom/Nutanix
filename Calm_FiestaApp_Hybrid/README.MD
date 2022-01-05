Creation of an application utilizing a MySQL DB and Webapp with Nodereact and NGINX.  This is a simple application developed by Nutanix to show what is possible.

Assumption:  You have configured and verified Nutanix Calm accounts for AHV and Azure.  Nutanix Calm project(s) have been created along with proper credentials.  An Azure Compute Gallery Image with CentOS 7.9 is available

 This Calm blueprint creates two VMs and installs/configures the application software to each.
 
 There are three possible environments to choose from:
    AHV - Deploys both VMs to a Nutanix Cluster running AHV Hypervisor on-prem
    Azure - Deploys both VMs to Microsoft Azure
    Hybrid - Deploys the MySQL DB VM to Azure and the WebApp to Nutanix AHV on-prem

 Developed with the following Nutanix products and versions
    Nutanix AOS 6.0.4
    Prism Central pc.2021.9.0.3 
    Nutanix Calm 3.3.1
    An Azure Compute Gallery Image with CentOS 7.9 is used - You can choose a marketplace image if you wish to do so.

To use this blueprint, import into a Prism Central running Calm 3.0 or later, modify the variables and credentials as mentioned below.

    Enviornmnet Variables - Availble across all three environments  
        db_username - Defaulted to root
        db_domain_name - Blank and not required - In place if needed and for future MSSQL
        db_dialect - Defaulted to mysql - No need to change this - In place for future MSSQL
        db_name - Defaulted fiestadb - Used in the sample application - Can change but will need to modify db setup scripts
        db_password - Assign any password
            
            
    Runtime Variables - None
        
    Credentials
        CENTOS - ID and Private Key for use with Linux VMs - You will need to supply your own Private Key - Modify cloudinit script section if using a different credential
    