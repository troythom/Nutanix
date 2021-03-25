Clone MSSQL Database to a new VM managed by Nutanix Era

 Credit to Michael Haigh for the starting point for this blueprint
 https://github.com/MichaelHaigh/calm-blueprints/tree/master/EraDatabaseClone

 This Calm blueprint allows for cloning of a Microsoft SQL database to a new Database Server VM that is managed by Nutanix Era. For now this is blueprint is strictly focused on cloning of existing MS SQL databases that are managed by Era to new Era provisioned VMs.

 Developed with the following Nutanix products and versions
    Nutanix AOS 5.18
    Prism Central pc.2020.11 
    Nutanix Calm 3.1.1
    Nutanix Era 2.1.0

To use this blueprint, import into a Prism Central runnin Calm 3.0 or later, modify the variables and credentials as mentioned below.


*****NEEDS UPDATED DOCUMENTATION*****

 Nutanix Era Environment Configuration - Assumes Nutanix Era is configured and DB Server VMs
    MSSQL Server VMs named MSSQLDEV, MSSQLTEST, MSSQLPROD have been registered and are managed by Nutanix Era

    Private Variables - Currently Makred private and default values used - Define your specific profiles in Nutanix Era and update these variables as appropriate for your environment.
        Compute_Profile - Defaulted to "Small_DB_Compute" - 2vCPU, 1 Core/vCPU, 8GB Memory
        DB_Parameter_Profile - Defaulted to "DEFAULT_SQLSERVER_DATABASE_PARAMS" - Modify as appropriate
        New_DB_Type - Defaulted to "sqlserver" - Currently available are sqlaerver, oracle, postgres, mariadb and mysql
        Network_Profile - Defaulted to "DEFAULT_OOB_SQLSERVER_NETWORK"
        Software_Profile - Defaulted to "MS_SQL_Base_SW_Profile" - Modify as appropriate
            
            **Note** - Future work to pull these profiles from a query of the DB Server VM at runtime.  Using default variables for now.

    Runtime Variables - Details required for execution
        New_DB_Name - Name of the Database that you are deploying - String input
         New_DB_SLA - Service Level Agreement for the Database.  Currently implemented as the ability to choose "None" 
            or "POC157_SLA" - Modify with the available SLA's you wish to offer in your environment as defined in the Era Server
         New_DB_Environment - DEV/Test/Prod - Runtime variable to select Database Server VM - Modify as appropriate
        era_ip - IP Address of the Nutanix Era Server
        new_db_password - Password that you wish to define for the database

    Credentials
        era_creds - ID and Password for your Era Server
        WindowsCredentials - ID and Password for the Database Server
        db_server_creds - ID and Password for the Database (Not Required in this version)
        CENTOS - ID and Private Key for use with Linux VMs (Not Required for this version)

    Custom Actions Available
        CreateSnapshot - Create a point-in-time snapshot and set an automatic expiration time
        GetSnapshotList - Get a list of all snapshots available for the Database
        DeleteSnapshot - Delete shapshots of the database